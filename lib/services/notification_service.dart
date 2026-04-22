import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  debugPrint(
    'Background notification: ${message.notification?.title} | ${message.notification?.body}',
  );
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      if (!kIsWeb) {
        await _initializeLocalNotifications();
      }

      await _requestPermission();
      await _configureForegroundPresentation();

      String? token;
      try {
        token = await _messaging.getToken();
      } catch (e) {
        // Web fails here when firebase-messaging-sw.js is not correctly served.
        debugPrint('FCM token acquisition skipped: $e');
      }

      debugPrint('FCM token: $token');
      await _syncTokenForCurrentUser(token);

      _messaging.onTokenRefresh.listen((newToken) async {
        debugPrint('FCM token refreshed: $newToken');
        await _syncTokenForCurrentUser(newToken);
      });

      FirebaseMessaging.onMessage.listen((message) {
        debugPrint(
          'Foreground notification: ${message.notification?.title} | ${message.notification?.body}',
        );
      });

      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        debugPrint(
          'Notification opened app: ${message.notification?.title} | ${message.notification?.body}',
        );
      });

      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint(
          'App opened from terminated state notification: ${initialMessage.notification?.title}',
        );
      }
    } catch (e) {
      debugPrint('Notification initialization skipped: $e');
    }

    _isInitialized = true;
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const settings = InitializationSettings(android: androidSettings);
    await _localNotifications.initialize(settings);
  }

  Future<void> showTestNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'test_mode_channel',
      'Test Mode Notifications',
      channelDescription: 'Quick notification checks from app test mode',
      importance: Importance.max,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'Test Notification',
      'Notification system is working on emulator',
      details,
      payload: 'test-mode',
    );
  }

  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('Notification permission: ${settings.authorizationStatus}');
  }

  Future<void> _configureForegroundPresentation() async {
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> _syncTokenForCurrentUser(String? token) async {
    if (token == null || token.isEmpty) return;

    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('mess_users').doc(user.uid).set({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Unable to sync FCM token to Firestore: $e');
    }
  }
}
