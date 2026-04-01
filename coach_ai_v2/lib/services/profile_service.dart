import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';
import '../models/workout_session.dart';
import '../utils/logger.dart';

class ProfileService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create or update user profile using assessments collection
  static Future<void> createOrUpdateProfile(UserProfile profile) async {
    try {
      await _firestore
          .collection('assessments')
          .doc('${profile.uid}_profile')
          .set(profile.toFirestore(), SetOptions(merge: true));
      
      Logger.info('Profile updated successfully', tag: 'PROFILE_SERVICE', data: {
        'uid': profile.uid,
        'displayName': profile.displayName,
      });
    } catch (e) {
      Logger.error('Failed to update profile', tag: 'PROFILE_SERVICE', error: e);
      rethrow;
    }
  }

  // Get user profile from assessments collection
  static Future<UserProfile?> getProfile(String uid) async {
    try {
      final doc = await _firestore.collection('assessments').doc('${uid}_profile').get();
      if (doc.exists) {
        return UserProfile.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      Logger.error('Failed to get profile', tag: 'PROFILE_SERVICE', error: e);
      return null;
    }
  }

  // Get current user profile
  static Future<UserProfile?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return getProfile(user.uid);
  }

  // Update user stats after workout
  static Future<void> updateStatsAfterWorkout(String userId, WorkoutSession session) async {
    try {
      final profile = await getProfile(userId);
      if (profile == null) return;

      final newStats = _calculateUpdatedStats(profile.stats, session);
      
      await _firestore.collection('assessments').doc('${userId}_profile').update({
        'stats': newStats.toMap(),
      });

      // Create calendar event
      await _createCalendarEvent(userId, session);

      Logger.info('Stats updated after workout', tag: 'PROFILE_SERVICE', data: {
        'userId': userId,
        'exerciseType': session.exerciseType,
        'totalWorkouts': newStats.totalWorkouts,
      });
    } catch (e) {
      Logger.error('Failed to update stats', tag: 'PROFILE_SERVICE', error: e);
    }
  }

  // Calculate updated stats
  static UserStats _calculateUpdatedStats(UserStats currentStats, WorkoutSession session) {
    final exerciseCounts = Map<String, int>.from(currentStats.exerciseCounts);
    exerciseCounts[session.exerciseType] = (exerciseCounts[session.exerciseType] ?? 0) + 1;

    // Calculate new personal records
    final personalRecords = Map<String, double>.from(currentStats.personalRecords);
    final results = session.results;
    
    if (results.containsKey('totalReps')) {
      final reps = results['totalReps'] as int;
      final currentRecord = personalRecords['${session.exerciseType}_reps'] ?? 0.0;
      if (reps > currentRecord) {
        personalRecords['${session.exerciseType}_reps'] = reps.toDouble();
      }
    }

    if (results.containsKey('totalDistanceKm')) {
      final distance = (results['totalDistanceKm'] as num).toDouble();
      final currentRecord = personalRecords['${session.exerciseType}_distance'] ?? 0.0;
      if (distance > currentRecord) {
        personalRecords['${session.exerciseType}_distance'] = distance;
      }
    }

    return UserStats(
      totalWorkouts: currentStats.totalWorkouts + 1,
      totalReps: currentStats.totalReps + (results['totalReps'] as int? ?? 0),
      totalDistanceKm: currentStats.totalDistanceKm + (results['totalDistanceKm'] as double? ?? 0.0),
      totalWorkoutTime: currentStats.totalWorkoutTime + session.duration,
      currentStreak: _calculateStreak(currentStats.currentStreak, session.startTime),
      longestStreak: math.max(currentStats.longestStreak, _calculateStreak(currentStats.currentStreak, session.startTime)),
      exerciseCounts: exerciseCounts,
      personalRecords: personalRecords,
    );
  }

  // Calculate workout streak
  static int _calculateStreak(int currentStreak, DateTime workoutDate) {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    
    if (workoutDate.isAfter(yesterday) && workoutDate.isBefore(today.add(const Duration(days: 1)))) {
      return currentStreak + 1;
    }
    return 1; // Reset streak
  }

  // Create calendar event for workout
  static Future<void> _createCalendarEvent(String userId, WorkoutSession session) async {
    try {
      final event = CalendarEvent(
        id: '',
        userId: userId,
        type: 'workout',
        date: session.startTime,
        title: '${session.exerciseType.replaceAll('_', ' ').toUpperCase()} Workout',
        description: _generateWorkoutDescription(session),
        data: {
          'workoutId': session.id,
          'exerciseType': session.exerciseType,
          'results': session.results,
        },
        isPublic: session.isPublic,
      );

      await _firestore.collection('assessments').add(event.toFirestore());
    } catch (e) {
      Logger.error('Failed to create calendar event', tag: 'PROFILE_SERVICE', error: e);
    }
  }

  // Generate workout description for calendar
  static String _generateWorkoutDescription(WorkoutSession session) {
    final results = session.results;
    final parts = <String>[];

    if (results.containsKey('totalReps')) {
      parts.add('${results['totalReps']} reps');
    }
    if (results.containsKey('totalDistanceKm')) {
      parts.add('${(results['totalDistanceKm'] as double).toStringAsFixed(2)} km');
    }
    if (results.containsKey('averageFormScore')) {
      parts.add('${(results['averageFormScore'] as double).toStringAsFixed(1)}% form');
    }

    return parts.isNotEmpty ? parts.join(' • ') : 'Workout completed';
  }

  // Get calendar events for user from assessments collection
  static Future<List<CalendarEvent>> getCalendarEvents(String userId, DateTime startDate, DateTime endDate) async {
    try {
      final query = await _firestore
          .collection('assessments')
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: 'calendar_event')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('date')
          .get();

      return query.docs.map((doc) => CalendarEvent.fromFirestore(doc)).toList();
    } catch (e) {
      Logger.error('Failed to get calendar events', tag: 'PROFILE_SERVICE', error: e);
      return [];
    }
  }

  // Follow user
  static Future<void> followUser(String currentUserId, String targetUserId) async {
    try {
      final batch = _firestore.batch();
      
      // Add to current user's following
      batch.update(
        _firestore.collection('assessments').doc('${currentUserId}_profile'),
        {'following': FieldValue.arrayUnion([targetUserId])},
      );
      
      // Add to target user's followers
      batch.update(
        _firestore.collection('assessments').doc('${targetUserId}_profile'),
        {'followers': FieldValue.arrayUnion([currentUserId])},
      );
      
      await batch.commit();
      
      Logger.info('User followed successfully', tag: 'PROFILE_SERVICE', data: {
        'currentUserId': currentUserId,
        'targetUserId': targetUserId,
      });
    } catch (e) {
      Logger.error('Failed to follow user', tag: 'PROFILE_SERVICE', error: e);
      rethrow;
    }
  }

  // Unfollow user
  static Future<void> unfollowUser(String currentUserId, String targetUserId) async {
    try {
      final batch = _firestore.batch();
      
      // Remove from current user's following
      batch.update(
        _firestore.collection('assessments').doc('${currentUserId}_profile'),
        {'following': FieldValue.arrayRemove([targetUserId])},
      );
      
      // Remove from target user's followers
      batch.update(
        _firestore.collection('assessments').doc('${targetUserId}_profile'),
        {'followers': FieldValue.arrayRemove([currentUserId])},
      );
      
      await batch.commit();
    } catch (e) {
      Logger.error('Failed to unfollow user', tag: 'PROFILE_SERVICE', error: e);
      rethrow;
    }
  }
}

