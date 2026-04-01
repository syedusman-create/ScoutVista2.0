import 'package:flutter/foundation.dart';

@immutable
class PrivacySettings {
  final String userId;
  final bool profilePublic;
  final bool showWorkoutHistory;
  final bool showStats;
  final bool showAchievements;
  final bool showCalendar;
  final bool allowFollowRequests;
  final bool allowMessages;
  final bool showOnlineStatus;
  final bool allowDataSharing;
  final bool allowAnalytics;
  final bool allowNotifications;
  final bool allowLocationTracking;
  final bool allowCameraAccess;
  final bool allowMicrophoneAccess;
  final bool allowPhotoLibraryAccess;
  final bool allowContactsAccess;
  final bool allowHealthDataAccess;
  final bool allowWorkoutSharing;
  final bool allowChallengeParticipation;
  final bool allowLeaderboardParticipation;
  final bool allowSocialFeatures;
  final bool allowDataExport;
  final bool allowDataDeletion;
  final DateTime lastUpdated;

  const PrivacySettings({
    required this.userId,
    this.profilePublic = true,
    this.showWorkoutHistory = true,
    this.showStats = true,
    this.showAchievements = true,
    this.showCalendar = true,
    this.allowFollowRequests = true,
    this.allowMessages = true,
    this.showOnlineStatus = true,
    this.allowDataSharing = false,
    this.allowAnalytics = true,
    this.allowNotifications = true,
    this.allowLocationTracking = false,
    this.allowCameraAccess = true,
    this.allowMicrophoneAccess = false,
    this.allowPhotoLibraryAccess = true,
    this.allowContactsAccess = false,
    this.allowHealthDataAccess = false,
    this.allowWorkoutSharing = true,
    this.allowChallengeParticipation = true,
    this.allowLeaderboardParticipation = true,
    this.allowSocialFeatures = true,
    this.allowDataExport = true,
    this.allowDataDeletion = true,
    required this.lastUpdated,
  });

  PrivacySettings copyWith({
    String? userId,
    bool? profilePublic,
    bool? showWorkoutHistory,
    bool? showStats,
    bool? showAchievements,
    bool? showCalendar,
    bool? allowFollowRequests,
    bool? allowMessages,
    bool? showOnlineStatus,
    bool? allowDataSharing,
    bool? allowAnalytics,
    bool? allowNotifications,
    bool? allowLocationTracking,
    bool? allowCameraAccess,
    bool? allowMicrophoneAccess,
    bool? allowPhotoLibraryAccess,
    bool? allowContactsAccess,
    bool? allowHealthDataAccess,
    bool? allowWorkoutSharing,
    bool? allowChallengeParticipation,
    bool? allowLeaderboardParticipation,
    bool? allowSocialFeatures,
    bool? allowDataExport,
    bool? allowDataDeletion,
    DateTime? lastUpdated,
  }) {
    return PrivacySettings(
      userId: userId ?? this.userId,
      profilePublic: profilePublic ?? this.profilePublic,
      showWorkoutHistory: showWorkoutHistory ?? this.showWorkoutHistory,
      showStats: showStats ?? this.showStats,
      showAchievements: showAchievements ?? this.showAchievements,
      showCalendar: showCalendar ?? this.showCalendar,
      allowFollowRequests: allowFollowRequests ?? this.allowFollowRequests,
      allowMessages: allowMessages ?? this.allowMessages,
      showOnlineStatus: showOnlineStatus ?? this.showOnlineStatus,
      allowDataSharing: allowDataSharing ?? this.allowDataSharing,
      allowAnalytics: allowAnalytics ?? this.allowAnalytics,
      allowNotifications: allowNotifications ?? this.allowNotifications,
      allowLocationTracking: allowLocationTracking ?? this.allowLocationTracking,
      allowCameraAccess: allowCameraAccess ?? this.allowCameraAccess,
      allowMicrophoneAccess: allowMicrophoneAccess ?? this.allowMicrophoneAccess,
      allowPhotoLibraryAccess: allowPhotoLibraryAccess ?? this.allowPhotoLibraryAccess,
      allowContactsAccess: allowContactsAccess ?? this.allowContactsAccess,
      allowHealthDataAccess: allowHealthDataAccess ?? this.allowHealthDataAccess,
      allowWorkoutSharing: allowWorkoutSharing ?? this.allowWorkoutSharing,
      allowChallengeParticipation: allowChallengeParticipation ?? this.allowChallengeParticipation,
      allowLeaderboardParticipation: allowLeaderboardParticipation ?? this.allowLeaderboardParticipation,
      allowSocialFeatures: allowSocialFeatures ?? this.allowSocialFeatures,
      allowDataExport: allowDataExport ?? this.allowDataExport,
      allowDataDeletion: allowDataDeletion ?? this.allowDataDeletion,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  factory PrivacySettings.fromMap(Map<String, dynamic> map) {
    return PrivacySettings(
      userId: map['userId'] as String,
      profilePublic: map['profilePublic'] as bool? ?? true,
      showWorkoutHistory: map['showWorkoutHistory'] as bool? ?? true,
      showStats: map['showStats'] as bool? ?? true,
      showAchievements: map['showAchievements'] as bool? ?? true,
      showCalendar: map['showCalendar'] as bool? ?? true,
      allowFollowRequests: map['allowFollowRequests'] as bool? ?? true,
      allowMessages: map['allowMessages'] as bool? ?? true,
      showOnlineStatus: map['showOnlineStatus'] as bool? ?? true,
      allowDataSharing: map['allowDataSharing'] as bool? ?? false,
      allowAnalytics: map['allowAnalytics'] as bool? ?? true,
      allowNotifications: map['allowNotifications'] as bool? ?? true,
      allowLocationTracking: map['allowLocationTracking'] as bool? ?? false,
      allowCameraAccess: map['allowCameraAccess'] as bool? ?? true,
      allowMicrophoneAccess: map['allowMicrophoneAccess'] as bool? ?? false,
      allowPhotoLibraryAccess: map['allowPhotoLibraryAccess'] as bool? ?? true,
      allowContactsAccess: map['allowContactsAccess'] as bool? ?? false,
      allowHealthDataAccess: map['allowHealthDataAccess'] as bool? ?? false,
      allowWorkoutSharing: map['allowWorkoutSharing'] as bool? ?? true,
      allowChallengeParticipation: map['allowChallengeParticipation'] as bool? ?? true,
      allowLeaderboardParticipation: map['allowLeaderboardParticipation'] as bool? ?? true,
      allowSocialFeatures: map['allowSocialFeatures'] as bool? ?? true,
      allowDataExport: map['allowDataExport'] as bool? ?? true,
      allowDataDeletion: map['allowDataDeletion'] as bool? ?? true,
      lastUpdated: DateTime.parse(map['lastUpdated'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'profilePublic': profilePublic,
      'showWorkoutHistory': showWorkoutHistory,
      'showStats': showStats,
      'showAchievements': showAchievements,
      'showCalendar': showCalendar,
      'allowFollowRequests': allowFollowRequests,
      'allowMessages': allowMessages,
      'showOnlineStatus': showOnlineStatus,
      'allowDataSharing': allowDataSharing,
      'allowAnalytics': allowAnalytics,
      'allowNotifications': allowNotifications,
      'allowLocationTracking': allowLocationTracking,
      'allowCameraAccess': allowCameraAccess,
      'allowMicrophoneAccess': allowMicrophoneAccess,
      'allowPhotoLibraryAccess': allowPhotoLibraryAccess,
      'allowContactsAccess': allowContactsAccess,
      'allowHealthDataAccess': allowHealthDataAccess,
      'allowWorkoutSharing': allowWorkoutSharing,
      'allowChallengeParticipation': allowChallengeParticipation,
      'allowLeaderboardParticipation': allowLeaderboardParticipation,
      'allowSocialFeatures': allowSocialFeatures,
      'allowDataExport': allowDataExport,
      'allowDataDeletion': allowDataDeletion,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}
