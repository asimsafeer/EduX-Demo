/// NovaByte Hub — Push Notification Service
library;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Handles Firebase Cloud Messaging for push notifications
class NotificationService {
  final FirebaseMessaging _messaging;

  NotificationService({FirebaseMessaging? messaging})
    : _messaging = messaging ?? FirebaseMessaging.instance;

  /// Initialize the notification service
  ///
  /// Requests permissions and sets up message handlers.
  Future<void> initialize({
    required void Function(String? requestId) onNotificationTap,
  }) async {
    // Request notification permissions
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint('NotificationService: Push notifications authorized');
    } else {
      debugPrint('NotificationService: Push notifications denied');
      return;
    }

    // Get FCM token for this device
    final token = await _messaging.getToken();
    debugPrint('NotificationService: FCM token=$token');

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint(
        'NotificationService: Foreground message → ${message.notification?.title}',
      );
      // Foreground messages are shown as in-app banners by the app
    });

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('NotificationService: Notification tapped → ${message.data}');
      final requestId = message.data['requestId'] as String?;
      onNotificationTap(requestId);
    });

    // Handle notification taps when app was terminated
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      final requestId = initialMessage.data['requestId'] as String?;
      onNotificationTap(requestId);
    }

    // Subscribe to the admin topic for broadcast notifications
    await _messaging.subscribeToTopic('admin_notifications');
  }

  /// Get the current FCM token
  Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  /// Unsubscribe from notifications (on sign out)
  Future<void> dispose() async {
    await _messaging.unsubscribeFromTopic('admin_notifications');
  }
}

/// Top-level handler for background messages (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint(
    'NotificationService: Background message → ${message.notification?.title}',
  );
}
