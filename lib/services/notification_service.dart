import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Handle background messages
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling background message: ${message.messageId}');
}

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Initialize Notifications
  Future<void> initialize() async {
    // Request permission for iOS
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      announcement: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted notification permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('User granted provisional permission');
    } else {
      print('User declined or has not accepted permission');
    }

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
        // The notification will be shown automatically by FCM
      }
    });

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notification opened: ${message.data}');
      // Navigate to appropriate screen based on message.data
    });

    // Handle notification tap when app is terminated
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      print('App opened from notification: ${initialMessage.data}');
    }
  }

  // Get FCM Token
  Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  // Save FCM Token to Firestore
  Future<void> saveTokenToFirestore(String userId, String role) async {
    String? token = await getToken();
    if (token != null) {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': token,
        'tokenUpdatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // ========== NOTIFICATION TYPES ==========

  /// Send Job Request Notification (to worker)
  Future<void> sendJobRequestNotification({
    required String workerId,
    required String userName,
    required String jobTitle,
    required String jobId,
  }) async {
    await _firestore.collection('notifications').add({
      'userId': workerId,
      'type': 'job_request',
      'title': 'New Job Request',
      'body': '$userName has requested your service: $jobTitle',
      'data': {
        'jobId': jobId,
        'type': 'job_request',
      },
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Send FCM notification
    await _sendFCMNotification(
      userId: workerId,
      title: 'New Job Request! 🎉',
      body: '$userName wants to hire you',
      data: {'jobId': jobId, 'type': 'job_request'},
    );
  }

  /// Send Job Accepted Notification (to client)
  Future<void> sendJobAcceptedNotification({
    required String userId,
    required String workerName,
    required String jobTitle,
    required String jobId,
  }) async {
    await _firestore.collection('notifications').add({
      'userId': userId,
      'type': 'job_accepted',
      'title': 'Job Accepted!',
      'body': '$workerName has accepted your job request',
      'data': {
        'jobId': jobId,
        'type': 'job_accepted',
      },
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _sendFCMNotification(
      userId: userId,
      title: 'Job Accepted! ✅',
      body: '$workerName has accepted your request',
      data: {'jobId': jobId, 'type': 'job_accepted'},
    );
  }

  /// Send Job Rejected Notification (to client)
  Future<void> sendJobRejectedNotification({
    required String userId,
    required String workerName,
    required String jobTitle,
    required String jobId,
  }) async {
    await _firestore.collection('notifications').add({
      'userId': userId,
      'type': 'job_rejected',
      'title': 'Job Declined',
      'body': '$workerName declined your job request',
      'data': {
        'jobId': jobId,
        'type': 'job_rejected',
      },
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _sendFCMNotification(
      userId: userId,
      title: 'Job Declined ❌',
      body: '$workerName declined your request',
      data: {'jobId': jobId, 'type': 'job_rejected'},
    );
  }

  /// Send Job Completed Notification
  Future<void> sendJobCompletedNotification({
    required String userId,
    required String workerName,
    required String jobId,
  }) async {
    await _firestore.collection('notifications').add({
      'userId': userId,
      'type': 'job_completed',
      'title': 'Job Completed!',
      'body': '$workerName has completed the job',
      'data': {
        'jobId': jobId,
        'type': 'job_completed',
      },
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _sendFCMNotification(
      userId: userId,
      title: 'Job Completed! 🎉',
      body: '$workerName finished the work. Please review and pay.',
      data: {'jobId': jobId, 'type': 'job_completed'},
    );
  }

  /// Send New Message Notification
  Future<void> sendMessageNotification({
    required String recipientId,
    required String senderName,
    required String message,
    required String chatId,
  }) async {
    await _sendFCMNotification(
      userId: recipientId,
      title: '💬 $senderName',
      body: message,
      data: {'chatId': chatId, 'type': 'message'},
    );
  }

  /// Send Payment Received Notification to Worker
  Future<void> sendPaymentReceivedNotification({
    required String workerId,
    required String userId,
    required String jobId,
  }) async {
    await _firestore.collection('notifications').add({
      'userId': workerId,
      'type': 'payment_received',
      'title': 'Payment Received! 💰',
      'body': 'Payment has been received for your completed job',
      'data': {
        'jobId': jobId,
        'type': 'payment_received',
      },
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _sendFCMNotification(
      userId: workerId,
      title: 'Payment Received! 💰',
      body: 'You received payment for your completed job',
      data: {'jobId': jobId, 'type': 'payment_received'},
    );
  }

  // ========== INTERNAL METHODS ==========

  /// Send FCM Notification using HTTP
  Future<void> _sendFCMNotification({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Get user's FCM token
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists && userDoc.get('fcmToken') != null) {
        String token = userDoc.get('fcmToken');

        // Note: In production, use Cloud Functions to send FCM
        // For now, just save to notifications collection
        print('Would send FCM to token: $token');
      }
    } catch (e) {
      print('Error sending FCM: $e');
    }
  }

  /// Get User Notifications Stream
  Stream<QuerySnapshot> getUserNotifications(String userId) {
    // Note: Removing orderBy to avoid index requirement
    // Will sort client-side by timestamp instead
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .limit(50)
        .snapshots();
  }

  /// Mark Notification as Read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'read': true,
      });
    } catch (e) {
      print('NotificationService.markAsRead error: $e');
    }
  }

  /// Mark all notifications as read for the user (badge updates immediately via stream)
  Future<void> markAllAsRead(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();

      WriteBatch batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null && data['read'] != true) {
          batch.update(doc.reference, {'read': true});
        }
      }
      await batch.commit();
    } catch (e) {
      print('NotificationService.markAllAsRead error: $e');
    }
  }

  /// Get Unread Count (one-off; for backward compat)
  Future<int> getUnreadCount(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();

      int count = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null && data['read'] != true) count++;
      }
      return count;
    } catch (e) {
      return 0;
    }
  }

  /// Stream of unread count for app bar badge (updates when notifications are marked read)
  Stream<int> getUnreadCountStream(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      int count = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null && data['read'] != true) count++;
      }
      return count;
    });
  }

  /// Clear All Notifications (delete)
  Future<void> clearAllNotifications(String userId) async {
    QuerySnapshot snapshot = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .get();

    WriteBatch batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}

