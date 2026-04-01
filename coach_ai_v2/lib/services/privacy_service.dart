import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/privacy_settings.dart';
import '../utils/logger.dart';

class PrivacyService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get privacy settings for current user
  static Future<PrivacySettings?> getPrivacySettings() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore
          .collection('privacy_settings')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        return PrivacySettings.fromMap(doc.data()!);
      } else {
        // Create default privacy settings
        return await createDefaultPrivacySettings(user.uid);
      }
    } catch (e) {
      Logger.error('Failed to get privacy settings', tag: 'PRIVACY_SERVICE', error: e);
      return null;
    }
  }

  // Create default privacy settings
  static Future<PrivacySettings> createDefaultPrivacySettings(String userId) async {
    try {
      final defaultSettings = PrivacySettings(
        userId: userId,
        lastUpdated: DateTime.now(),
      );

      await _firestore
          .collection('privacy_settings')
          .doc(userId)
          .set(defaultSettings.toMap());

      Logger.info('Default privacy settings created for user $userId', tag: 'PRIVACY_SERVICE');
      return defaultSettings;
    } catch (e) {
      Logger.error('Failed to create default privacy settings', tag: 'PRIVACY_SERVICE', error: e);
      rethrow;
    }
  }

  // Update privacy settings
  static Future<void> updatePrivacySettings(PrivacySettings settings) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final updatedSettings = settings.copyWith(
        lastUpdated: DateTime.now(),
      );

      await _firestore
          .collection('privacy_settings')
          .doc(user.uid)
          .set(updatedSettings.toMap());

      Logger.info('Privacy settings updated for user ${user.uid}', tag: 'PRIVACY_SERVICE');
    } catch (e) {
      Logger.error('Failed to update privacy settings', tag: 'PRIVACY_SERVICE', error: e);
      rethrow;
    }
  }

  // Update specific privacy setting
  static Future<void> updatePrivacySetting(String key, bool value) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _firestore
          .collection('privacy_settings')
          .doc(user.uid)
          .update({
        key: value,
        'lastUpdated': DateTime.now().toIso8601String(),
      });

      Logger.info('Privacy setting $key updated to $value for user ${user.uid}', tag: 'PRIVACY_SERVICE');
    } catch (e) {
      Logger.error('Failed to update privacy setting $key', tag: 'PRIVACY_SERVICE', error: e);
      rethrow;
    }
  }

  // Export user data
  static Future<Map<String, dynamic>> exportUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final userId = user.uid;
      final exportData = <String, dynamic>{
        'exportDate': DateTime.now().toIso8601String(),
        'userId': userId,
        'userEmail': user.email,
        'userDisplayName': user.displayName,
        'userPhotoURL': user.photoURL,
      };

      // Get user profile
      final profileDoc = await _firestore
          .collection('assessments')
          .doc('${userId}_profile')
          .get();
      if (profileDoc.exists) {
        exportData['profile'] = profileDoc.data();
      }

      // Get workout sessions
      final workoutSessions = await _firestore
          .collection('assessments')
          .where('type', isEqualTo: 'workout_session')
          .where('userId', isEqualTo: userId)
          .get();
      exportData['workoutSessions'] = workoutSessions.docs.map((doc) => doc.data()).toList();

      // Get calendar events
      final calendarEvents = await _firestore
          .collection('assessments')
          .where('type', isEqualTo: 'calendar_event')
          .where('userId', isEqualTo: userId)
          .get();
      exportData['calendarEvents'] = calendarEvents.docs.map((doc) => doc.data()).toList();

      // Get social posts
      final socialPosts = await _firestore
          .collection('social_posts')
          .where('userId', isEqualTo: userId)
          .get();
      exportData['socialPosts'] = socialPosts.docs.map((doc) => doc.data()).toList();

      // Get privacy settings
      final privacyDoc = await _firestore
          .collection('privacy_settings')
          .doc(userId)
          .get();
      if (privacyDoc.exists) {
        exportData['privacySettings'] = privacyDoc.data();
      }

      Logger.info('User data exported for user $userId', tag: 'PRIVACY_SERVICE');
      return exportData;
    } catch (e) {
      Logger.error('Failed to export user data', tag: 'PRIVACY_SERVICE', error: e);
      rethrow;
    }
  }

  // Delete user data
  static Future<void> deleteUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final userId = user.uid;
      final batch = _firestore.batch();

      // Delete user profile
      final profileRef = _firestore.collection('assessments').doc('${userId}_profile');
      batch.delete(profileRef);

      // Delete workout sessions
      final workoutSessions = await _firestore
          .collection('assessments')
          .where('type', isEqualTo: 'workout_session')
          .where('userId', isEqualTo: userId)
          .get();
      for (final doc in workoutSessions.docs) {
        batch.delete(doc.reference);
      }

      // Delete calendar events
      final calendarEvents = await _firestore
          .collection('assessments')
          .where('type', isEqualTo: 'calendar_event')
          .where('userId', isEqualTo: userId)
          .get();
      for (final doc in calendarEvents.docs) {
        batch.delete(doc.reference);
      }

      // Delete social posts
      final socialPosts = await _firestore
          .collection('social_posts')
          .where('userId', isEqualTo: userId)
          .get();
      for (final doc in socialPosts.docs) {
        batch.delete(doc.reference);
      }

      // Delete privacy settings
      final privacyRef = _firestore.collection('privacy_settings').doc(userId);
      batch.delete(privacyRef);

      // Delete notifications
      final notifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();
      for (final doc in notifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      Logger.info('User data deleted for user $userId', tag: 'PRIVACY_SERVICE');
    } catch (e) {
      Logger.error('Failed to delete user data', tag: 'PRIVACY_SERVICE', error: e);
      rethrow;
    }
  }

  // Check if user has permission for specific action
  static Future<bool> hasPermission(String action) async {
    try {
      final settings = await getPrivacySettings();
      if (settings == null) return false;

      switch (action) {
        case 'profile_public':
          return settings.profilePublic;
        case 'show_workout_history':
          return settings.showWorkoutHistory;
        case 'show_stats':
          return settings.showStats;
        case 'show_achievements':
          return settings.showAchievements;
        case 'show_calendar':
          return settings.showCalendar;
        case 'allow_follow_requests':
          return settings.allowFollowRequests;
        case 'allow_messages':
          return settings.allowMessages;
        case 'show_online_status':
          return settings.showOnlineStatus;
        case 'allow_data_sharing':
          return settings.allowDataSharing;
        case 'allow_analytics':
          return settings.allowAnalytics;
        case 'allow_notifications':
          return settings.allowNotifications;
        case 'allow_location_tracking':
          return settings.allowLocationTracking;
        case 'allow_camera_access':
          return settings.allowCameraAccess;
        case 'allow_microphone_access':
          return settings.allowMicrophoneAccess;
        case 'allow_photo_library_access':
          return settings.allowPhotoLibraryAccess;
        case 'allow_contacts_access':
          return settings.allowContactsAccess;
        case 'allow_health_data_access':
          return settings.allowHealthDataAccess;
        case 'allow_workout_sharing':
          return settings.allowWorkoutSharing;
        case 'allow_challenge_participation':
          return settings.allowChallengeParticipation;
        case 'allow_leaderboard_participation':
          return settings.allowLeaderboardParticipation;
        case 'allow_social_features':
          return settings.allowSocialFeatures;
        case 'allow_data_export':
          return settings.allowDataExport;
        case 'allow_data_deletion':
          return settings.allowDataDeletion;
        default:
          return false;
      }
    } catch (e) {
      Logger.error('Failed to check permission for $action', tag: 'PRIVACY_SERVICE', error: e);
      return false;
    }
  }

  // Get privacy summary
  static Future<Map<String, dynamic>> getPrivacySummary() async {
    try {
      final settings = await getPrivacySettings();
      if (settings == null) return {};

      return {
        'profileVisibility': settings.profilePublic ? 'Public' : 'Private',
        'dataSharing': settings.allowDataSharing ? 'Enabled' : 'Disabled',
        'analytics': settings.allowAnalytics ? 'Enabled' : 'Disabled',
        'notifications': settings.allowNotifications ? 'Enabled' : 'Disabled',
        'locationTracking': settings.allowLocationTracking ? 'Enabled' : 'Disabled',
        'socialFeatures': settings.allowSocialFeatures ? 'Enabled' : 'Disabled',
        'dataExport': settings.allowDataExport ? 'Available' : 'Not Available',
        'dataDeletion': settings.allowDataDeletion ? 'Available' : 'Not Available',
        'lastUpdated': settings.lastUpdated.toIso8601String(),
      };
    } catch (e) {
      Logger.error('Failed to get privacy summary', tag: 'PRIVACY_SERVICE', error: e);
      return {};
    }
  }
}
