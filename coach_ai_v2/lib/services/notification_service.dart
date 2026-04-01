import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../models/notification.dart';
import '../utils/logger.dart';

class NotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create a notification
  static Future<String> createNotification(AppNotification notification) async {
    try {
      final docRef = await _firestore.collection('notifications').add(notification.toFirestore());
      
      Logger.info('Notification created successfully', tag: 'NOTIFICATION_SERVICE', data: {
        'notificationId': docRef.id,
        'userId': notification.userId,
        'type': notification.type,
      });
      
      return docRef.id;
    } catch (e) {
      Logger.error('Failed to create notification', tag: 'NOTIFICATION_SERVICE', error: e);
      rethrow;
    }
  }

  // Get user notifications
  static Future<List<AppNotification>> getUserNotifications(String userId, {int limit = 50}) async {
    try {
      final query = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return query.docs.map((doc) => AppNotification.fromFirestore(doc)).toList();
    } catch (e) {
      Logger.error('Failed to get user notifications', tag: 'NOTIFICATION_SERVICE', error: e);
      return [];
    }
  }

  // Get unread notification count
  static Future<int> getUnreadCount(String userId) async {
    try {
      final query = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      return query.docs.length;
    } catch (e) {
      Logger.error('Failed to get unread count', tag: 'NOTIFICATION_SERVICE', error: e);
      return 0;
    }
  }

  // Mark notification as read
  static Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });

      Logger.info('Notification marked as read', tag: 'NOTIFICATION_SERVICE', data: {
        'notificationId': notificationId,
      });
    } catch (e) {
      Logger.error('Failed to mark notification as read', tag: 'NOTIFICATION_SERVICE', error: e);
      rethrow;
    }
  }

  // Mark all notifications as read
  static Future<void> markAllAsRead(String userId) async {
    try {
      final query = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in query.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();

      Logger.info('All notifications marked as read', tag: 'NOTIFICATION_SERVICE', data: {
        'userId': userId,
        'count': query.docs.length,
      });
    } catch (e) {
      Logger.error('Failed to mark all notifications as read', tag: 'NOTIFICATION_SERVICE', error: e);
      rethrow;
    }
  }

  // Delete notification
  static Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();

      Logger.info('Notification deleted', tag: 'NOTIFICATION_SERVICE', data: {
        'notificationId': notificationId,
      });
    } catch (e) {
      Logger.error('Failed to delete notification', tag: 'NOTIFICATION_SERVICE', error: e);
      rethrow;
    }
  }

  // Get notification settings
  static Future<NotificationSettings> getNotificationSettings(String userId) async {
    try {
      final doc = await _firestore.collection('notification_settings').doc(userId).get();
      
      if (doc.exists) {
        return NotificationSettings.fromMap(doc.data()!);
      } else {
        // Create default settings
        final defaultSettings = NotificationSettings(userId: userId);
        await _firestore.collection('notification_settings').doc(userId).set(defaultSettings.toMap());
        return defaultSettings;
      }
    } catch (e) {
      Logger.error('Failed to get notification settings', tag: 'NOTIFICATION_SERVICE', error: e);
      return NotificationSettings(userId: userId);
    }
  }

  // Update notification settings
  static Future<void> updateNotificationSettings(NotificationSettings settings) async {
    try {
      await _firestore.collection('notification_settings').doc(settings.userId).set(settings.toMap());

      Logger.info('Notification settings updated', tag: 'NOTIFICATION_SERVICE', data: {
        'userId': settings.userId,
      });
    } catch (e) {
      Logger.error('Failed to update notification settings', tag: 'NOTIFICATION_SERVICE', error: e);
      rethrow;
    }
  }

  // Notification creation helpers
  static Future<void> createLikeNotification({
    required String postId,
    required String postOwnerId,
    required String likerId,
    required String likerName,
    String? likerImageUrl,
  }) async {
    if (postOwnerId == likerId) return; // Don't notify self

    final settings = await getNotificationSettings(postOwnerId);
    if (!settings.likeNotifications) return;

    final notification = AppNotification(
      id: '',
      userId: postOwnerId,
      fromUserId: likerId,
      fromUserName: likerName,
      fromUserImageUrl: likerImageUrl,
      type: 'like',
      title: 'New Like',
      message: '$likerName liked your post',
      data: {'postId': postId},
      createdAt: DateTime.now(),
      actionUrl: '/post/$postId',
    );

    await createNotification(notification);
    await _sendPushNotification(notification);
  }

  static Future<void> createCommentNotification({
    required String postId,
    required String postOwnerId,
    required String commenterId,
    required String commenterName,
    String? commenterImageUrl,
    required String comment,
  }) async {
    if (postOwnerId == commenterId) return; // Don't notify self

    final settings = await getNotificationSettings(postOwnerId);
    if (!settings.commentNotifications) return;

    final notification = AppNotification(
      id: '',
      userId: postOwnerId,
      fromUserId: commenterId,
      fromUserName: commenterName,
      fromUserImageUrl: commenterImageUrl,
      type: 'comment',
      title: 'New Comment',
      message: '$commenterName commented: ${comment.length > 50 ? comment.substring(0, 50) + '...' : comment}',
      data: {'postId': postId, 'comment': comment},
      createdAt: DateTime.now(),
      actionUrl: '/post/$postId',
    );

    await createNotification(notification);
    await _sendPushNotification(notification);
  }

  static Future<void> createFollowNotification({
    required String followedUserId,
    required String followerId,
    required String followerName,
    String? followerImageUrl,
  }) async {
    if (followedUserId == followerId) return; // Don't notify self

    final settings = await getNotificationSettings(followedUserId);
    if (!settings.followNotifications) return;

    final notification = AppNotification(
      id: '',
      userId: followedUserId,
      fromUserId: followerId,
      fromUserName: followerName,
      fromUserImageUrl: followerImageUrl,
      type: 'follow',
      title: 'New Follower',
      message: '$followerName started following you',
      data: {'followerId': followerId},
      createdAt: DateTime.now(),
      actionUrl: '/profile/$followerId',
    );

    await createNotification(notification);
    await _sendPushNotification(notification);
  }

  static Future<void> createAchievementNotification({
    required String userId,
    required String achievementTitle,
    required String achievementDescription,
  }) async {
    final settings = await getNotificationSettings(userId);
    if (!settings.achievementNotifications) return;

    final notification = AppNotification(
      id: '',
      userId: userId,
      fromUserId: 'system',
      fromUserName: 'Coach.ai',
      type: 'achievement',
      title: 'Achievement Unlocked!',
      message: 'You unlocked: $achievementTitle',
      data: {'achievementTitle': achievementTitle, 'achievementDescription': achievementDescription},
      createdAt: DateTime.now(),
      actionUrl: '/achievements',
    );

    await createNotification(notification);
    await _sendPushNotification(notification);
  }

  static Future<void> createChallengeNotification({
    required String userId,
    required String challengeTitle,
    required String challengeDescription,
    required String challengeId,
  }) async {
    final settings = await getNotificationSettings(userId);
    if (!settings.challengeNotifications) return;

    final notification = AppNotification(
      id: '',
      userId: userId,
      fromUserId: 'system',
      fromUserName: 'Coach.ai',
      type: 'challenge',
      title: 'New Challenge Available',
      message: '$challengeTitle - $challengeDescription',
      data: {'challengeId': challengeId, 'challengeTitle': challengeTitle},
      createdAt: DateTime.now(),
      actionUrl: '/challenges/$challengeId',
    );

    await createNotification(notification);
    await _sendPushNotification(notification);
  }

  static Future<void> createWorkoutSharedNotification({
    required String userId,
    required String sharerId,
    required String sharerName,
    required String exerciseType,
    String? sharerImageUrl,
  }) async {
    if (userId == sharerId) return; // Don't notify self

    final settings = await getNotificationSettings(userId);
    if (!settings.workoutSharedNotifications) return;

    final notification = AppNotification(
      id: '',
      userId: userId,
      fromUserId: sharerId,
      fromUserName: sharerName,
      fromUserImageUrl: sharerImageUrl,
      type: 'workout_shared',
      title: 'New Workout Shared',
      message: '$sharerName shared a $exerciseType workout',
      data: {'exerciseType': exerciseType, 'sharerId': sharerId},
      createdAt: DateTime.now(),
      actionUrl: '/profile/$sharerId',
    );

    await createNotification(notification);
    await _sendPushNotification(notification);
  }

  // Send push notification (placeholder - would integrate with FCM)
  static Future<void> _sendPushNotification(AppNotification notification) async {
    try {
      // This would integrate with Firebase Cloud Messaging
      // For now, we'll just log it
      Logger.info('Push notification would be sent', tag: 'NOTIFICATION_SERVICE', data: {
        'userId': notification.userId,
        'title': notification.title,
        'message': notification.message,
      });

      // TODO: Implement actual FCM integration
      // await FirebaseMessaging.instance.sendToTopic(
      //   'user_${notification.userId}',
      //   data: {
      //     'title': notification.title,
      //     'body': notification.message,
      //     'type': notification.type,
      //     'data': jsonEncode(notification.data ?? {}),
      //   },
      // );
    } catch (e) {
      Logger.error('Failed to send push notification', tag: 'NOTIFICATION_SERVICE', error: e);
    }
  }

  // Check if user is in quiet hours
  static bool isInQuietHours(NotificationSettings settings) {
    final now = DateTime.now();
    final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    
    final startTime = settings.quietHoursStart;
    final endTime = settings.quietHoursEnd;
    
    // Simple time comparison (doesn't handle overnight quiet hours)
    return currentTime.compareTo(startTime) >= 0 && currentTime.compareTo(endTime) <= 0;
  }

  // Get notification icon based on type
  static String getNotificationIcon(String type) {
    switch (type) {
      case 'like':
        return '❤️';
      case 'comment':
        return '💬';
      case 'follow':
        return '👥';
      case 'achievement':
        return '🏆';
      case 'challenge':
        return '🎯';
      case 'workout_shared':
        return '🏋️';
      default:
        return '🔔';
    }
  }

  // Get notification color based on type
  static String getNotificationColor(String type) {
    switch (type) {
      case 'like':
        return 'red';
      case 'comment':
        return 'blue';
      case 'follow':
        return 'green';
      case 'achievement':
        return 'amber';
      case 'challenge':
        return 'purple';
      case 'workout_shared':
        return 'orange';
      default:
        return 'grey';
    }
  }
}
