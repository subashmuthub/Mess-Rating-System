import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';

import 'mess_cloud_models.dart';
import 'mess_models.dart';

class MessCloudService {
  MessCloudService._();

  static final MessCloudService instance = MessCloudService._();

  bool get _firebaseReady => Firebase.apps.isNotEmpty;

  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('mess_users');
  CollectionReference<Map<String, dynamic>> get _requests =>
      _firestore.collection('additional_food_requests');
  CollectionReference<Map<String, dynamic>> get _bills =>
      _firestore.collection('mess_bills');
  CollectionReference<Map<String, dynamic>> get _announcements =>
      _firestore.collection('mess_announcements');
  CollectionReference<Map<String, dynamic>> get _mailQueue =>
      _firestore.collection('mail_queue');

  DocumentReference<Map<String, dynamic>> get _windowConfigRef =>
      _firestore.collection('mess_settings').doc('windows');

  User? get currentAuthUser => _auth.currentUser;

  Future<MessUser?> currentMessUser() async {
    if (!_firebaseReady) return null;
    final authUser = _auth.currentUser;
    if (authUser == null) return null;
    try {
      return await _upsertMessUser(authUser);
    } catch (e) {
      debugPrint('Cloud user restore skipped: $e');
      return MessUser(
        id: authUser.uid,
        name: authUser.displayName ?? 'Student User',
        email: authUser.email ?? 'unknown@college.edu',
        password: 'firebase_google',
        role: UserRole.student,
      );
    }
  }

  Future<MessUser> signInWithGoogle() async {
    if (!_firebaseReady) {
      throw Exception('Firebase is not initialized yet.');
    }
    UserCredential credential;
    if (kIsWeb) {
      final provider = GoogleAuthProvider();
      credential = await _auth.signInWithPopup(provider);
    } else {
      final account = await GoogleSignIn().signIn();
      if (account == null) {
        throw Exception('Google sign-in cancelled');
      }
      final authData = await account.authentication;
      final googleCredential = GoogleAuthProvider.credential(
        accessToken: authData.accessToken,
        idToken: authData.idToken,
      );
      credential = await _auth.signInWithCredential(googleCredential);
    }

    final user = credential.user;
    if (user == null) throw Exception('Google auth failed');
    return _upsertMessUser(user);
  }

  Future<void> signOut() async {
    if (!_firebaseReady) return;
    if (!kIsWeb) {
      await GoogleSignIn().signOut();
    }
    await _auth.signOut();
  }

  Future<MessUser> _upsertMessUser(User user) async {
    try {
      final payload = <String, dynamic>{
        'id': user.uid,
        'name': user.displayName ?? 'Student User',
        'email': user.email ?? 'unknown@college.edu',
        'password': 'firebase_google',
        'role': 'student',
        'department': null,
        'year': null,
        'roomNumber': null,
        'hostelBlock': null,
        'messId': 'main_mess',
        'updatedAt': DateTime.now().toIso8601String(),
      };
      await _users.doc(user.uid).set(payload, SetOptions(merge: true));
      return MessUser.fromJson(payload);
    } catch (e) {
      debugPrint('Cloud user upsert failed, using fallback: $e');
      return MessUser(
        id: user.uid,
        name: user.displayName ?? 'Student User',
        email: user.email ?? 'unknown@college.edu',
        password: 'firebase_google',
        role: UserRole.student,
      );
    }
  }

  Future<FoodWindowConfig> getFoodWindowConfig() async {
    if (!_firebaseReady) return FoodWindowConfig.defaultValue;
    final doc = await _windowConfigRef.get();
    if (!doc.exists || doc.data() == null) {
      await _windowConfigRef.set(FoodWindowConfig.defaultValue.toJson());
      return FoodWindowConfig.defaultValue;
    }
    return FoodWindowConfig.fromJson(doc.data()!);
  }

  Stream<FoodWindowConfig> foodWindowConfigStream() {
    if (!_firebaseReady) {
      return Stream.value(FoodWindowConfig.defaultValue);
    }
    return _windowConfigRef.snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null) return FoodWindowConfig.defaultValue;
      return FoodWindowConfig.fromJson(data);
    });
  }

  Future<void> setFoodWindowConfig(FoodWindowConfig config) async {
    if (!_firebaseReady) return;
    await _windowConfigRef.set(config.toJson(), SetOptions(merge: true));
  }

  Future<bool> canStudentRequestNow() async {
    final config = await getFoodWindowConfig();
    if (!config.studentRequestEnabled) return false;
    final now = DateTime.now();
    return now.hour < config.studentRequestCutoffHour;
  }

  Future<bool> canAdminEditMenuNow() async {
    final config = await getFoodWindowConfig();
    if (!config.adminMenuEnabled) return false;
    final now = DateTime.now();
    return now.hour < config.adminMenuCutoffHour;
  }

  Future<void> submitAdditionalFoodRequest({
    required MessUser student,
    required String dishName,
    required String reason,
    required int quantity,
    required double estimatedFee,
    String? targetDateKey,
  }) async {
    if (!_firebaseReady) {
      throw Exception('Cloud features are unavailable right now.');
    }
    final requestAllowed = await canStudentRequestNow();
    if (!requestAllowed) {
      throw Exception('Student request window is closed.');
    }

    final id = 'req_${DateTime.now().microsecondsSinceEpoch}';
    final request = AdditionalFoodRequest(
      id: id,
      studentId: student.id,
      studentName: student.name,
      studentEmail: student.email,
      dishName: dishName,
      reason: reason,
      quantity: quantity,
      estimatedFee: estimatedFee,
      status: AdditionalRequestStatus.pending,
      createdAt: DateTime.now(),
      targetDateKey: targetDateKey,
    );
    await _requests.doc(id).set(request.toJson());

    await queueEmail(
      to: 'mess-admin@college.edu',
      subject: 'New Additional Food Request',
      body:
          '${student.name} requested $dishName x$quantity. Estimated fee: Rs.${estimatedFee.toStringAsFixed(0)}',
      metadata: {'requestId': id, 'studentId': student.id},
    );
  }

  Stream<List<AdditionalFoodRequest>> studentRequestsStream(String studentId) {
    if (!_firebaseReady) {
      return Stream.value(const <AdditionalFoodRequest>[]);
    }
    return _requests
        .where('studentId', isEqualTo: studentId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AdditionalFoodRequest.fromJson(doc.data()))
              .toList(),
        );
  }

  Stream<List<AdditionalFoodRequest>> pendingRequestsStream() {
    if (!_firebaseReady) {
      return Stream.value(const <AdditionalFoodRequest>[]);
    }
    return _requests
        .where('status', isEqualTo: AdditionalRequestStatus.pending.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AdditionalFoodRequest.fromJson(doc.data()))
              .toList(),
        );
  }

  Future<void> rejectRequest({
    required String requestId,
    required String adminId,
    String? adminNote,
  }) async {
    if (!_firebaseReady) return;
    await _requests.doc(requestId).set({
      'status': AdditionalRequestStatus.rejected.name,
      'adminId': adminId,
      'adminNote': adminNote,
      'approvedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  Future<void> approveRequest({
    required AdditionalFoodRequest request,
    required String adminId,
    required double approvedFee,
    String? adminNote,
  }) async {
    if (!_firebaseReady) return;
    await _requests.doc(request.id).set({
      'status': AdditionalRequestStatus.approved.name,
      'adminId': adminId,
      'adminNote': adminNote,
      'approvedAt': DateTime.now().toIso8601String(),
      'estimatedFee': approvedFee,
    }, SetOptions(merge: true));

    final now = DateTime.now();
    final bill = await _getOrCreateBill(
      studentId: request.studentId,
      studentName: request.studentName,
      targetMonth: monthKey(now),
      defaultBaseAmount: 3000,
    );

    final updated = bill.copyWith(
      additionalAmount: bill.additionalAmount + approvedFee,
      lastUpdatedAt: now,
    );

    await _bills.doc(updated.id).set(updated.toJson(), SetOptions(merge: true));

    await queueEmail(
      to: request.studentEmail ?? 'student@college.edu',
      subject: 'Additional Food Request Approved',
      body:
          'Your request for ${request.dishName} was approved. Rs.${approvedFee.toStringAsFixed(0)} added to your monthly mess bill.',
      metadata: {'requestId': request.id, 'billId': updated.id},
    );
  }

  Future<MonthlyMessBill> _getOrCreateBill({
    required String studentId,
    required String studentName,
    required String targetMonth,
    required double defaultBaseAmount,
  }) async {
    if (!_firebaseReady) {
      final now = DateTime.now();
      final parsedMonth = DateFormat('yyyy-MM').parse(targetMonth);
      return MonthlyMessBill(
        id: '${studentId}_$targetMonth',
        studentId: studentId,
        studentName: studentName,
        monthKey: targetMonth,
        baseAmount: defaultBaseAmount,
        additionalAmount: 0,
        penaltyAmount: 0,
        totalPaid: 0,
        status: BillPaymentStatus.unpaid,
        generatedAt: now,
        dueDate: DateTime(parsedMonth.year, parsedMonth.month + 1, 7),
        lastUpdatedAt: now,
      );
    }
    final id = '${studentId}_$targetMonth';
    final existing = await _bills.doc(id).get();
    if (existing.exists && existing.data() != null) {
      return MonthlyMessBill.fromJson(existing.data()!);
    }

    final parsedMonth = DateFormat('yyyy-MM').parse(targetMonth);
    final dueDate = DateTime(parsedMonth.year, parsedMonth.month + 1, 7);
    final bill = MonthlyMessBill(
      id: id,
      studentId: studentId,
      studentName: studentName,
      monthKey: targetMonth,
      baseAmount: defaultBaseAmount,
      additionalAmount: 0,
      penaltyAmount: 0,
      totalPaid: 0,
      status: BillPaymentStatus.unpaid,
      generatedAt: DateTime.now(),
      dueDate: dueDate,
      lastUpdatedAt: DateTime.now(),
    );
    await _bills.doc(id).set(bill.toJson());
    return bill;
  }

  Future<void> generateMonthlyBills({required double baseAmount}) async {
    if (!_firebaseReady) return;
    final snapshot = await _users.where('role', isEqualTo: UserRole.student.name).get();
    final thisMonth = monthKey(DateTime.now());
    for (final userDoc in snapshot.docs) {
      final data = userDoc.data();
      await _getOrCreateBill(
        studentId: userDoc.id,
        studentName: (data['name'] as String?) ?? 'Student',
        targetMonth: thisMonth,
        defaultBaseAmount: baseAmount,
      );
    }
  }

  int computeDynamicPenalty(MonthlyMessBill bill, DateTime now) {
    if (bill.status == BillPaymentStatus.paid) return bill.penaltyAmount.toInt();
    final graceDate = bill.dueDate.add(const Duration(days: 7));
    if (!now.isAfter(graceDate)) return bill.penaltyAmount.toInt();
    final lateDays = now.difference(graceDate).inDays;
    final lateWeeks = (lateDays / 7).floor() + 1;
    final progressive = progressivePenaltyForWeeks(lateWeeks);
    return bill.penaltyAmount.toInt() > progressive
        ? bill.penaltyAmount.toInt()
        : progressive;
  }

  Stream<List<MonthlyMessBill>> studentBillsStream(String studentId) {
    if (!_firebaseReady) {
      return Stream.value(const <MonthlyMessBill>[]);
    }
    return _bills
        .where('studentId', isEqualTo: studentId)
        .orderBy('monthKey', descending: true)
        .snapshots()
        .map((snapshot) {
      final now = DateTime.now();
      return snapshot.docs.map((doc) {
        final raw = MonthlyMessBill.fromJson(doc.data());
        final penalty = computeDynamicPenalty(raw, now).toDouble();
        final status = (raw.totalPaid >= (raw.baseAmount + raw.additionalAmount + penalty))
            ? BillPaymentStatus.paid
            : (raw.totalPaid > 0 ? BillPaymentStatus.partiallyPaid : BillPaymentStatus.unpaid);
        return raw.copyWith(penaltyAmount: penalty, status: status);
      }).toList();
    });
  }

  Stream<List<MonthlyMessBill>> allBillsStream() {
    if (!_firebaseReady) {
      return Stream.value(const <MonthlyMessBill>[]);
    }
    return _bills.orderBy('monthKey', descending: true).snapshots().map((snapshot) {
      final now = DateTime.now();
      return snapshot.docs.map((doc) {
        final raw = MonthlyMessBill.fromJson(doc.data());
        final penalty = computeDynamicPenalty(raw, now).toDouble();
        final status = (raw.totalPaid >= (raw.baseAmount + raw.additionalAmount + penalty))
            ? BillPaymentStatus.paid
            : (raw.totalPaid > 0 ? BillPaymentStatus.partiallyPaid : BillPaymentStatus.unpaid);
        return raw.copyWith(penaltyAmount: penalty, status: status);
      }).toList();
    });
  }

  Future<void> applyComputedPenalty(MonthlyMessBill bill) async {
    if (!_firebaseReady) return;
    final computed = computeDynamicPenalty(bill, DateTime.now()).toDouble();
    if (computed == bill.penaltyAmount) return;
    await _bills.doc(bill.id).set({
      'penaltyAmount': computed,
      'lastUpdatedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  Future<void> markBillPaid({
    required MonthlyMessBill bill,
    required double amount,
  }) async {
    if (!_firebaseReady) return;
    final now = DateTime.now();
    final penalty = computeDynamicPenalty(bill, now).toDouble();
    final totalDue = bill.baseAmount + bill.additionalAmount + penalty;
    final newPaid = bill.totalPaid + amount;
    final status = newPaid >= totalDue
        ? BillPaymentStatus.paid
        : BillPaymentStatus.partiallyPaid;

    await _bills.doc(bill.id).set({
      'totalPaid': newPaid,
      'penaltyAmount': penalty,
      'status': status.name,
      'lastUpdatedAt': now.toIso8601String(),
    }, SetOptions(merge: true));
  }

  Future<void> postAnnouncement({
    required String senderId,
    required String title,
    required String body,
    String target = 'all',
  }) async {
    if (!_firebaseReady) return;
    final id = 'msg_${DateTime.now().microsecondsSinceEpoch}';
    final message = MessAnnouncement(
      id: id,
      title: title,
      body: body,
      createdAt: DateTime.now(),
      senderId: senderId,
      target: target,
    );
    await _announcements.doc(id).set(message.toJson());
  }

  Stream<List<MessAnnouncement>> announcementsStream({required UserRole role}) {
    if (!_firebaseReady) {
      return Stream.value(const <MessAnnouncement>[]);
    }
    return _announcements
        .orderBy('createdAt', descending: true)
        .limit(80)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MessAnnouncement.fromJson(doc.data()))
          .where((item) => item.target == 'all' || item.target == role.name)
          .toList();
    });
  }

  Future<void> queueEmail({
    required String to,
    required String subject,
    required String body,
    Map<String, dynamic>? metadata,
  }) async {
    if (!_firebaseReady) return;
    final id = 'mail_${DateTime.now().microsecondsSinceEpoch}';
    await _mailQueue.doc(id).set({
      'id': id,
      'to': to,
      'subject': subject,
      'body': body,
      'metadata': metadata ?? <String, dynamic>{},
      'status': 'queued',
      'createdAt': DateTime.now().toIso8601String(),
    });
  }
}
