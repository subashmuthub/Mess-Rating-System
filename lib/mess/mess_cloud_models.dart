import 'package:intl/intl.dart';

enum AdditionalRequestStatus { pending, approved, rejected, expired }

enum BillPaymentStatus { unpaid, partiallyPaid, paid }

class AdditionalFoodRequest {
  const AdditionalFoodRequest({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.dishName,
    required this.reason,
    required this.quantity,
    required this.estimatedFee,
    required this.status,
    required this.createdAt,
    this.studentEmail,
    this.adminId,
    this.adminNote,
    this.approvedAt,
    this.targetDateKey,
  });

  final String id;
  final String studentId;
  final String studentName;
  final String? studentEmail;
  final String dishName;
  final String reason;
  final int quantity;
  final double estimatedFee;
  final AdditionalRequestStatus status;
  final DateTime createdAt;
  final String? adminId;
  final String? adminNote;
  final DateTime? approvedAt;
  final String? targetDateKey;

  Map<String, dynamic> toJson() => {
    'id': id,
    'studentId': studentId,
    'studentName': studentName,
    'studentEmail': studentEmail,
    'dishName': dishName,
    'reason': reason,
    'quantity': quantity,
    'estimatedFee': estimatedFee,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    'adminId': adminId,
    'adminNote': adminNote,
    'approvedAt': approvedAt?.toIso8601String(),
    'targetDateKey': targetDateKey,
  };

  factory AdditionalFoodRequest.fromJson(Map<String, dynamic> json) {
    return AdditionalFoodRequest(
      id: json['id'] as String,
      studentId: json['studentId'] as String,
      studentName: json['studentName'] as String,
      studentEmail: json['studentEmail'] as String?,
      dishName: json['dishName'] as String,
      reason: json['reason'] as String,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      estimatedFee: (json['estimatedFee'] as num?)?.toDouble() ?? 0,
      status: AdditionalRequestStatus.values.firstWhere(
        (s) => s.name == (json['status'] as String? ?? 'pending'),
        orElse: () => AdditionalRequestStatus.pending,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      adminId: json['adminId'] as String?,
      adminNote: json['adminNote'] as String?,
      approvedAt: json['approvedAt'] == null
          ? null
          : DateTime.parse(json['approvedAt'] as String),
      targetDateKey: json['targetDateKey'] as String?,
    );
  }
}

class MonthlyMessBill {
  const MonthlyMessBill({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.monthKey,
    required this.baseAmount,
    required this.additionalAmount,
    required this.penaltyAmount,
    required this.totalPaid,
    required this.status,
    required this.generatedAt,
    required this.dueDate,
    this.lastUpdatedAt,
  });

  final String id;
  final String studentId;
  final String studentName;
  final String monthKey;
  final double baseAmount;
  final double additionalAmount;
  final double penaltyAmount;
  final double totalPaid;
  final BillPaymentStatus status;
  final DateTime generatedAt;
  final DateTime dueDate;
  final DateTime? lastUpdatedAt;

  double get netAmount => baseAmount + additionalAmount + penaltyAmount;
  double get balance => (netAmount - totalPaid).clamp(0, double.infinity);

  Map<String, dynamic> toJson() => {
    'id': id,
    'studentId': studentId,
    'studentName': studentName,
    'monthKey': monthKey,
    'baseAmount': baseAmount,
    'additionalAmount': additionalAmount,
    'penaltyAmount': penaltyAmount,
    'totalPaid': totalPaid,
    'status': status.name,
    'generatedAt': generatedAt.toIso8601String(),
    'dueDate': dueDate.toIso8601String(),
    'lastUpdatedAt': lastUpdatedAt?.toIso8601String(),
  };

  factory MonthlyMessBill.fromJson(Map<String, dynamic> json) {
    return MonthlyMessBill(
      id: json['id'] as String,
      studentId: json['studentId'] as String,
      studentName: json['studentName'] as String,
      monthKey: json['monthKey'] as String,
      baseAmount: (json['baseAmount'] as num?)?.toDouble() ?? 0,
      additionalAmount: (json['additionalAmount'] as num?)?.toDouble() ?? 0,
      penaltyAmount: (json['penaltyAmount'] as num?)?.toDouble() ?? 0,
      totalPaid: (json['totalPaid'] as num?)?.toDouble() ?? 0,
      status: BillPaymentStatus.values.firstWhere(
        (s) => s.name == (json['status'] as String? ?? 'unpaid'),
        orElse: () => BillPaymentStatus.unpaid,
      ),
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      dueDate: DateTime.parse(json['dueDate'] as String),
      lastUpdatedAt: json['lastUpdatedAt'] == null
          ? null
          : DateTime.parse(json['lastUpdatedAt'] as String),
    );
  }

  MonthlyMessBill copyWith({
    double? baseAmount,
    double? additionalAmount,
    double? penaltyAmount,
    double? totalPaid,
    BillPaymentStatus? status,
    DateTime? lastUpdatedAt,
  }) {
    return MonthlyMessBill(
      id: id,
      studentId: studentId,
      studentName: studentName,
      monthKey: monthKey,
      baseAmount: baseAmount ?? this.baseAmount,
      additionalAmount: additionalAmount ?? this.additionalAmount,
      penaltyAmount: penaltyAmount ?? this.penaltyAmount,
      totalPaid: totalPaid ?? this.totalPaid,
      status: status ?? this.status,
      generatedAt: generatedAt,
      dueDate: dueDate,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }
}

class FoodWindowConfig {
  const FoodWindowConfig({
    required this.studentRequestCutoffHour,
    required this.adminMenuCutoffHour,
    required this.studentRequestEnabled,
    required this.adminMenuEnabled,
  });

  final int studentRequestCutoffHour;
  final int adminMenuCutoffHour;
  final bool studentRequestEnabled;
  final bool adminMenuEnabled;

  Map<String, dynamic> toJson() => {
    'studentRequestCutoffHour': studentRequestCutoffHour,
    'adminMenuCutoffHour': adminMenuCutoffHour,
    'studentRequestEnabled': studentRequestEnabled,
    'adminMenuEnabled': adminMenuEnabled,
  };

  factory FoodWindowConfig.fromJson(Map<String, dynamic> json) {
    return FoodWindowConfig(
      studentRequestCutoffHour: (json['studentRequestCutoffHour'] as num?)?.toInt() ?? 17,
      adminMenuCutoffHour: (json['adminMenuCutoffHour'] as num?)?.toInt() ?? 20,
      studentRequestEnabled: json['studentRequestEnabled'] as bool? ?? true,
      adminMenuEnabled: json['adminMenuEnabled'] as bool? ?? true,
    );
  }

  static const defaultValue = FoodWindowConfig(
    studentRequestCutoffHour: 17,
    adminMenuCutoffHour: 20,
    studentRequestEnabled: true,
    adminMenuEnabled: true,
  );
}

class MessAnnouncement {
  const MessAnnouncement({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.senderId,
    required this.target,
  });

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final String senderId;
  final String target;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'createdAt': createdAt.toIso8601String(),
    'senderId': senderId,
    'target': target,
  };

  factory MessAnnouncement.fromJson(Map<String, dynamic> json) {
    return MessAnnouncement(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      senderId: json['senderId'] as String,
      target: json['target'] as String? ?? 'all',
    );
  }
}

String monthKey(DateTime date) => DateFormat('yyyy-MM').format(date);

int progressivePenaltyForWeeks(int overdueWeeks) {
  if (overdueWeeks <= 0) return 0;
  var total = 0;
  for (var i = 0; i < overdueWeeks; i++) {
    total += 100 + (50 * i);
  }
  return total;
}
