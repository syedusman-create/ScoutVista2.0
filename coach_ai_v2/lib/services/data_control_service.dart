import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/privacy_settings.dart';
import '../utils/logger.dart';

class DataControlService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get data usage summary
  static Future<Map<String, dynamic>> getDataUsageSummary() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final userId = user.uid;
      final summary = <String, dynamic>{
        'userId': userId,
        'generatedAt': DateTime.now().toIso8601String(),
      };

      // Count user profile data
      final profileDoc = await _firestore
          .collection('assessments')
          .doc('${userId}_profile')
          .get();
      summary['hasProfile'] = profileDoc.exists;
      summary['profileSize'] = profileDoc.exists ? profileDoc.data()!.toString().length : 0;

      // Count workout sessions
      final workoutSessions = await _firestore
          .collection('assessments')
          .where('type', isEqualTo: 'workout_session')
          .where('userId', isEqualTo: userId)
          .get();
      summary['workoutSessionsCount'] = workoutSessions.docs.length;
      summary['workoutSessionsSize'] = workoutSessions.docs.fold<int>(
        0,
        (sum, doc) => sum + doc.data().toString().length,
      );

      // Count calendar events
      final calendarEvents = await _firestore
          .collection('assessments')
          .where('type', isEqualTo: 'calendar_event')
          .where('userId', isEqualTo: userId)
          .get();
      summary['calendarEventsCount'] = calendarEvents.docs.length;
      summary['calendarEventsSize'] = calendarEvents.docs.fold<int>(
        0,
        (sum, doc) => sum + doc.data().toString().length,
      );

      // Count social posts
      final socialPosts = await _firestore
          .collection('social_posts')
          .where('userId', isEqualTo: userId)
          .get();
      summary['socialPostsCount'] = socialPosts.docs.length;
      summary['socialPostsSize'] = socialPosts.docs.fold<int>(
        0,
        (sum, doc) => sum + doc.data().toString().length,
      );

      // Count notifications
      final notifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();
      summary['notificationsCount'] = notifications.docs.length;
      summary['notificationsSize'] = notifications.docs.fold<int>(
        0,
        (sum, doc) => sum + doc.data().toString().length,
      );

      // Calculate total data size
      summary['totalDataSize'] = (summary['profileSize'] as int) +
          (summary['workoutSessionsSize'] as int) +
          (summary['calendarEventsSize'] as int) +
          (summary['socialPostsSize'] as int) +
          (summary['notificationsSize'] as int);

      // Calculate data age
      final oldestWorkout = workoutSessions.docs.isNotEmpty
          ? workoutSessions.docs
              .map((doc) => (doc.data()['createdAt'] as Timestamp).toDate())
              .reduce((a, b) => a.isBefore(b) ? a : b)
          : null;
      summary['oldestDataDate'] = oldestWorkout?.toIso8601String();
      summary['dataAgeDays'] = oldestWorkout != null
          ? DateTime.now().difference(oldestWorkout).inDays
          : 0;

      Logger.info('Data usage summary generated for user $userId', tag: 'DATA_CONTROL_SERVICE');
      return summary;
    } catch (e) {
      Logger.error('Failed to get data usage summary', tag: 'DATA_CONTROL_SERVICE', error: e);
      rethrow;
    }
  }

  // Anonymize user data
  static Future<void> anonymizeUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final userId = user.uid;
      final batch = _firestore.batch();

      // Anonymize user profile
      final profileRef = _firestore.collection('assessments').doc('${userId}_profile');
      batch.update(profileRef, {
        'displayName': 'Anonymous User',
        'bio': 'This user has chosen to remain anonymous',
        'profileImageUrl': null,
        'anonymizedAt': DateTime.now().toIso8601String(),
      });

      // Anonymize social posts
      final socialPosts = await _firestore
          .collection('social_posts')
          .where('userId', isEqualTo: userId)
          .get();
      for (final doc in socialPosts.docs) {
        batch.update(doc.reference, {
          'displayName': 'Anonymous User',
          'profileImageUrl': null,
          'anonymizedAt': DateTime.now().toIso8601String(),
        });
      }

      await batch.commit();

      Logger.info('User data anonymized for user $userId', tag: 'DATA_CONTROL_SERVICE');
    } catch (e) {
      Logger.error('Failed to anonymize user data', tag: 'DATA_CONTROL_SERVICE', error: e);
      rethrow;
    }
  }

  // Clear specific data type
  static Future<void> clearDataType(String dataType) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final userId = user.uid;
      final batch = _firestore.batch();

      switch (dataType) {
        case 'workout_sessions':
          final workoutSessions = await _firestore
              .collection('assessments')
              .where('type', isEqualTo: 'workout_session')
              .where('userId', isEqualTo: userId)
              .get();
          for (final doc in workoutSessions.docs) {
            batch.delete(doc.reference);
          }
          break;

        case 'calendar_events':
          final calendarEvents = await _firestore
              .collection('assessments')
              .where('type', isEqualTo: 'calendar_event')
              .where('userId', isEqualTo: userId)
              .get();
          for (final doc in calendarEvents.docs) {
            batch.delete(doc.reference);
          }
          break;

        case 'social_posts':
          final socialPosts = await _firestore
              .collection('social_posts')
              .where('userId', isEqualTo: userId)
              .get();
          for (final doc in socialPosts.docs) {
            batch.delete(doc.reference);
          }
          break;

        case 'notifications':
          final notifications = await _firestore
              .collection('notifications')
              .where('userId', isEqualTo: userId)
              .get();
          for (final doc in notifications.docs) {
            batch.delete(doc.reference);
          }
          break;

        default:
          throw Exception('Unknown data type: $dataType');
      }

      await batch.commit();

      Logger.info('Data type $dataType cleared for user $userId', tag: 'DATA_CONTROL_SERVICE');
    } catch (e) {
      Logger.error('Failed to clear data type $dataType', tag: 'DATA_CONTROL_SERVICE', error: e);
      rethrow;
    }
  }

  // Get data retention policy
  static Map<String, dynamic> getDataRetentionPolicy() {
    return {
      'profileData': {
        'retentionPeriod': 'Indefinite',
        'description': 'Profile data is kept until account deletion',
        'canBeDeleted': true,
      },
      'workoutSessions': {
        'retentionPeriod': '2 years',
        'description': 'Workout sessions are kept for 2 years for analytics',
        'canBeDeleted': true,
      },
      'calendarEvents': {
        'retentionPeriod': '1 year',
        'description': 'Calendar events are kept for 1 year',
        'canBeDeleted': true,
      },
      'socialPosts': {
        'retentionPeriod': 'Indefinite',
        'description': 'Social posts are kept until manually deleted',
        'canBeDeleted': true,
      },
      'notifications': {
        'retentionPeriod': '90 days',
        'description': 'Notifications are automatically deleted after 90 days',
        'canBeDeleted': true,
      },
      'analyticsData': {
        'retentionPeriod': '1 year',
        'description': 'Analytics data is anonymized after 1 year',
        'canBeDeleted': false,
      },
    };
  }

  // Generate data export file
  static Future<String> generateDataExport() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final userId = user.uid;
      final exportData = <String, dynamic>{
        'exportInfo': {
          'userId': userId,
          'exportDate': DateTime.now().toIso8601String(),
          'appVersion': '2.0.0',
          'dataFormat': 'JSON',
        },
        'privacyNotice': {
          'purpose': 'This export contains your personal data from Coach.ai',
          'retention': 'Please store this data securely',
          'deletion': 'You can request data deletion at any time',
        },
      };

      // Get all user data
      final allData = await _getAllUserData(userId);
      exportData['userData'] = allData;

      // Convert to JSON string
      final jsonString = jsonEncode(exportData);
      
      Logger.info('Data export generated for user $userId', tag: 'DATA_CONTROL_SERVICE');
      return jsonString;
    } catch (e) {
      Logger.error('Failed to generate data export', tag: 'DATA_CONTROL_SERVICE', error: e);
      rethrow;
    }
  }

  // Get all user data for export
  static Future<Map<String, dynamic>> _getAllUserData(String userId) async {
    final userData = <String, dynamic>{};

    // Get user profile
    final profileDoc = await _firestore
        .collection('assessments')
        .doc('${userId}_profile')
        .get();
    if (profileDoc.exists) {
      userData['profile'] = profileDoc.data();
    }

    // Get workout sessions
    final workoutSessions = await _firestore
        .collection('assessments')
        .where('type', isEqualTo: 'workout_session')
        .where('userId', isEqualTo: userId)
        .get();
    userData['workoutSessions'] = workoutSessions.docs.map((doc) => doc.data()).toList();

    // Get calendar events
    final calendarEvents = await _firestore
        .collection('assessments')
        .where('type', isEqualTo: 'calendar_event')
        .where('userId', isEqualTo: userId)
        .get();
    userData['calendarEvents'] = calendarEvents.docs.map((doc) => doc.data()).toList();

    // Get social posts
    final socialPosts = await _firestore
        .collection('social_posts')
        .where('userId', isEqualTo: userId)
        .get();
    userData['socialPosts'] = socialPosts.docs.map((doc) => doc.data()).toList();

    // Get notifications
    final notifications = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .get();
    userData['notifications'] = notifications.docs.map((doc) => doc.data()).toList();

    // Get privacy settings
    final privacyDoc = await _firestore
        .collection('privacy_settings')
        .doc(userId)
        .get();
    if (privacyDoc.exists) {
      userData['privacySettings'] = privacyDoc.data();
    }

    return userData;
  }

  // Check data compliance
  static Future<Map<String, dynamic>> checkDataCompliance() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final userId = user.uid;
      final compliance = <String, dynamic>{
        'userId': userId,
        'checkedAt': DateTime.now().toIso8601String(),
        'complianceStatus': 'Compliant',
        'issues': <String>[],
        'recommendations': <String>[],
      };

      // Check if user has privacy settings
      final privacyDoc = await _firestore
          .collection('privacy_settings')
          .doc(userId)
          .get();
      
      if (!privacyDoc.exists) {
        compliance['issues'].add('No privacy settings configured');
        compliance['recommendations'].add('Configure your privacy settings');
      }

      // Check data retention
      final workoutSessions = await _firestore
          .collection('assessments')
          .where('type', isEqualTo: 'workout_session')
          .where('userId', isEqualTo: userId)
          .get();

      final now = DateTime.now();
      final oldSessions = workoutSessions.docs.where((doc) {
        final createdAt = (doc.data()['createdAt'] as Timestamp).toDate();
        return now.difference(createdAt).inDays > 730; // 2 years
      }).length;

      if (oldSessions > 0) {
        compliance['issues'].add('$oldSessions workout sessions older than 2 years');
        compliance['recommendations'].add('Consider cleaning up old workout data');
      }

      // Check for sensitive data
      final socialPosts = await _firestore
          .collection('social_posts')
          .where('userId', isEqualTo: userId)
          .get();

      final postsWithLocation = socialPosts.docs.where((doc) {
        final data = doc.data();
        return data['workoutData'] != null && 
               data['workoutData']['location'] != null;
      }).length;

      if (postsWithLocation > 0) {
        compliance['recommendations'].add('Consider reviewing posts with location data');
      }

      // Overall compliance status
      if (compliance['issues'].length > 0) {
        compliance['complianceStatus'] = 'Needs Attention';
      }

      Logger.info('Data compliance checked for user $userId', tag: 'DATA_CONTROL_SERVICE');
      return compliance;
    } catch (e) {
      Logger.error('Failed to check data compliance', tag: 'DATA_CONTROL_SERVICE', error: e);
      rethrow;
    }
  }
}
