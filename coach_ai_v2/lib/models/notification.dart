import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

@immutable
class AppNotification {
  final String id;
  final String userId; // User who receives the notification
  final String fromUserId; // User who triggered the notification
  final String fromUserName;
  final String? fromUserImageUrl;
  final String type; // 'like', 'comment', 'follow', 'achievement', 'challenge', 'workout_shared'
  final String title;
  final String message;
  final Map<String, dynamic>? data; // Additional data (postId, challengeId, etc.)
  final DateTime createdAt;
  final bool isRead;
  final bool isPushSent; // Whether push notification was sent
  final String? actionUrl; // Deep link or route to navigate to

  const AppNotification({
    required this.id,
    required this.userId,
    required this.fromUserId,
    required this.fromUserName,
    this.fromUserImageUrl,
    required this.type,
    required this.title,
    required this.message,
    this.data,
    required this.createdAt,
    this.isRead = false,
    this.isPushSent = false,
    this.actionUrl,
  });

  AppNotification copyWith({
    String? id,
    String? userId,
    String? fromUserId,
    String? fromUserName,
    String? fromUserImageUrl,
    String? type,
    String? title,
    String? message,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    bool? isRead,
    bool? isPushSent,
    String? actionUrl,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fromUserId: fromUserId ?? this.fromUserId,
      fromUserName: fromUserName ?? this.fromUserName,
      fromUserImageUrl: fromUserImageUrl ?? this.fromUserImageUrl,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      isPushSent: isPushSent ?? this.isPushSent,
      actionUrl: actionUrl ?? this.actionUrl,
    );
  }

  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      userId: data['userId'] as String,
      fromUserId: data['fromUserId'] as String,
      fromUserName: data['fromUserName'] as String,
      fromUserImageUrl: data['fromUserImageUrl'] as String?,
      type: data['type'] as String,
      title: data['title'] as String,
      message: data['message'] as String,
      data: data['data'] as Map<String, dynamic>?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isRead: data['isRead'] as bool? ?? false,
      isPushSent: data['isPushSent'] as bool? ?? false,
      actionUrl: data['actionUrl'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'fromUserId': fromUserId,
      'fromUserName': fromUserName,
      'fromUserImageUrl': fromUserImageUrl,
      'type': type,
      'title': title,
      'message': message,
      'data': data,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
      'isPushSent': isPushSent,
      'actionUrl': actionUrl,
    };
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

@immutable
class NotificationSettings {
  final String userId;
  final bool pushNotificationsEnabled;
  final bool emailNotificationsEnabled;
  final bool likeNotifications;
  final bool commentNotifications;
  final bool followNotifications;
  final bool achievementNotifications;
  final bool challengeNotifications;
  final bool workoutSharedNotifications;
  final bool weeklyDigest;
  final bool dailyReminders;
  final String quietHoursStart; // "22:00"
  final String quietHoursEnd; // "08:00"

  const NotificationSettings({
    required this.userId,
    this.pushNotificationsEnabled = true,
    this.emailNotificationsEnabled = true,
    this.likeNotifications = true,
    this.commentNotifications = true,
    this.followNotifications = true,
    this.achievementNotifications = true,
    this.challengeNotifications = true,
    this.workoutSharedNotifications = true,
    this.weeklyDigest = true,
    this.dailyReminders = true,
    this.quietHoursStart = "22:00",
    this.quietHoursEnd = "08:00",
  });

  NotificationSettings copyWith({
    String? userId,
    bool? pushNotificationsEnabled,
    bool? emailNotificationsEnabled,
    bool? likeNotifications,
    bool? commentNotifications,
    bool? followNotifications,
    bool? achievementNotifications,
    bool? challengeNotifications,
    bool? workoutSharedNotifications,
    bool? weeklyDigest,
    bool? dailyReminders,
    String? quietHoursStart,
    String? quietHoursEnd,
  }) {
    return NotificationSettings(
      userId: userId ?? this.userId,
      pushNotificationsEnabled: pushNotificationsEnabled ?? this.pushNotificationsEnabled,
      emailNotificationsEnabled: emailNotificationsEnabled ?? this.emailNotificationsEnabled,
      likeNotifications: likeNotifications ?? this.likeNotifications,
      commentNotifications: commentNotifications ?? this.commentNotifications,
      followNotifications: followNotifications ?? this.followNotifications,
      achievementNotifications: achievementNotifications ?? this.achievementNotifications,
      challengeNotifications: challengeNotifications ?? this.challengeNotifications,
      workoutSharedNotifications: workoutSharedNotifications ?? this.workoutSharedNotifications,
      weeklyDigest: weeklyDigest ?? this.weeklyDigest,
      dailyReminders: dailyReminders ?? this.dailyReminders,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
    );
  }

  factory NotificationSettings.fromMap(Map<String, dynamic> map) {
    return NotificationSettings(
      userId: map['userId'] as String,
      pushNotificationsEnabled: map['pushNotificationsEnabled'] as bool? ?? true,
      emailNotificationsEnabled: map['emailNotificationsEnabled'] as bool? ?? true,
      likeNotifications: map['likeNotifications'] as bool? ?? true,
      commentNotifications: map['commentNotifications'] as bool? ?? true,
      followNotifications: map['followNotifications'] as bool? ?? true,
      achievementNotifications: map['achievementNotifications'] as bool? ?? true,
      challengeNotifications: map['challengeNotifications'] as bool? ?? true,
      workoutSharedNotifications: map['workoutSharedNotifications'] as bool? ?? true,
      weeklyDigest: map['weeklyDigest'] as bool? ?? true,
      dailyReminders: map['dailyReminders'] as bool? ?? true,
      quietHoursStart: map['quietHoursStart'] as String? ?? "22:00",
      quietHoursEnd: map['quietHoursEnd'] as String? ?? "08:00",
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'pushNotificationsEnabled': pushNotificationsEnabled,
      'emailNotificationsEnabled': emailNotificationsEnabled,
      'likeNotifications': likeNotifications,
      'commentNotifications': commentNotifications,
      'followNotifications': followNotifications,
      'achievementNotifications': achievementNotifications,
      'challengeNotifications': challengeNotifications,
      'workoutSharedNotifications': workoutSharedNotifications,
      'weeklyDigest': weeklyDigest,
      'dailyReminders': dailyReminders,
      'quietHoursStart': quietHoursStart,
      'quietHoursEnd': quietHoursEnd,
    };
  }
}
