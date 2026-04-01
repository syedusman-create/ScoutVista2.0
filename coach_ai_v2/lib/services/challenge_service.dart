import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/challenge.dart';
import '../models/leaderboard.dart';
import '../utils/logger.dart';

class ChallengeService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create a new challenge
  static Future<String> createChallenge(Challenge challenge) async {
    try {
      final docRef = await _firestore.collection('challenges').add(challenge.toFirestore());
      
      Logger.info('Challenge created successfully', tag: 'CHALLENGE_SERVICE', data: {
        'challengeId': docRef.id,
        'title': challenge.title,
        'type': challenge.type,
      });
      
      return docRef.id;
    } catch (e) {
      Logger.error('Failed to create challenge', tag: 'CHALLENGE_SERVICE', error: e);
      rethrow;
    }
  }

  // Get active challenges
  static Future<List<Challenge>> getActiveChallenges() async {
    try {
      final query = await _firestore
          .collection('challenges')
          .where('isActive', isEqualTo: true)
          .where('endDate', isGreaterThan: Timestamp.fromDate(DateTime.now()))
          .orderBy('endDate')
          .get();

      return query.docs.map((doc) => Challenge.fromFirestore(doc)).toList();
    } catch (e) {
      Logger.error('Failed to get active challenges', tag: 'CHALLENGE_SERVICE', error: e);
      return [];
    }
  }

  // Get challenges by type
  static Future<List<Challenge>> getChallengesByType(String type) async {
    try {
      final query = await _firestore
          .collection('challenges')
          .where('type', isEqualTo: type)
          .where('isActive', isEqualTo: true)
          .orderBy('endDate')
          .get();

      return query.docs.map((doc) => Challenge.fromFirestore(doc)).toList();
    } catch (e) {
      Logger.error('Failed to get challenges by type', tag: 'CHALLENGE_SERVICE', error: e);
      return [];
    }
  }

  // Join a challenge
  static Future<void> joinChallenge(String challengeId, String userId) async {
    try {
      await _firestore.collection('challenges').doc(challengeId).update({
        'participants': FieldValue.arrayUnion([userId]),
      });

      // Create challenge progress entry
      await _firestore.collection('challenge_progress').add({
        'challengeId': challengeId,
        'userId': userId,
        'currentProgress': {},
        'completionPercentage': 0.0,
        'lastUpdated': Timestamp.fromDate(DateTime.now()),
        'isCompleted': false,
      });

      Logger.info('User joined challenge', tag: 'CHALLENGE_SERVICE', data: {
        'challengeId': challengeId,
        'userId': userId,
      });
    } catch (e) {
      Logger.error('Failed to join challenge', tag: 'CHALLENGE_SERVICE', error: e);
      rethrow;
    }
  }

  // Leave a challenge
  static Future<void> leaveChallenge(String challengeId, String userId) async {
    try {
      await _firestore.collection('challenges').doc(challengeId).update({
        'participants': FieldValue.arrayRemove([userId]),
      });

      // Remove challenge progress
      final progressQuery = await _firestore
          .collection('challenge_progress')
          .where('challengeId', isEqualTo: challengeId)
          .where('userId', isEqualTo: userId)
          .get();

      for (final doc in progressQuery.docs) {
        await doc.reference.delete();
      }

      Logger.info('User left challenge', tag: 'CHALLENGE_SERVICE', data: {
        'challengeId': challengeId,
        'userId': userId,
      });
    } catch (e) {
      Logger.error('Failed to leave challenge', tag: 'CHALLENGE_SERVICE', error: e);
      rethrow;
    }
  }

  // Get user's challenge progress
  static Future<ChallengeProgress?> getChallengeProgress(String challengeId, String userId) async {
    try {
      final query = await _firestore
          .collection('challenge_progress')
          .where('challengeId', isEqualTo: challengeId)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return ChallengeProgress.fromFirestore(query.docs.first);
      }
      return null;
    } catch (e) {
      Logger.error('Failed to get challenge progress', tag: 'CHALLENGE_SERVICE', error: e);
      return null;
    }
  }

  // Update challenge progress
  static Future<void> updateChallengeProgress(
    String challengeId,
    String userId,
    Map<String, dynamic> newProgress,
  ) async {
    try {
      final challenge = await _firestore.collection('challenges').doc(challengeId).get();
      if (!challenge.exists) return;

      final challengeData = Challenge.fromFirestore(challenge);
      final target = challengeData.target;
      
      // Calculate completion percentage
      double completionPercentage = 0.0;
      for (final key in target.keys) {
        if (newProgress.containsKey(key)) {
          final targetValue = (target[key] as num).toDouble();
          final currentValue = (newProgress[key] as num).toDouble();
          final keyCompletion = (currentValue / targetValue).clamp(0.0, 1.0);
          completionPercentage = math.max(completionPercentage, keyCompletion);
        }
      }

      final isCompleted = completionPercentage >= 1.0;

      // Update progress
      final progressQuery = await _firestore
          .collection('challenge_progress')
          .where('challengeId', isEqualTo: challengeId)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (progressQuery.docs.isNotEmpty) {
        await progressQuery.docs.first.reference.update({
          'currentProgress': newProgress,
          'completionPercentage': completionPercentage,
          'lastUpdated': Timestamp.fromDate(DateTime.now()),
          'isCompleted': isCompleted,
          if (isCompleted) 'completedAt': Timestamp.fromDate(DateTime.now()),
        });
      }

      Logger.info('Challenge progress updated', tag: 'CHALLENGE_SERVICE', data: {
        'challengeId': challengeId,
        'userId': userId,
        'completionPercentage': completionPercentage,
        'isCompleted': isCompleted,
      });
    } catch (e) {
      Logger.error('Failed to update challenge progress', tag: 'CHALLENGE_SERVICE', error: e);
      rethrow;
    }
  }

  // Get leaderboards
  static Future<List<Leaderboard>> getLeaderboards() async {
    try {
      final query = await _firestore
          .collection('leaderboards')
          .where('isActive', isEqualTo: true)
          .orderBy('endDate')
          .get();

      return query.docs.map((doc) => Leaderboard.fromFirestore(doc)).toList();
    } catch (e) {
      Logger.error('Failed to get leaderboards', tag: 'CHALLENGE_SERVICE', error: e);
      return [];
    }
  }

  // Get leaderboard by type
  static Future<Leaderboard?> getLeaderboardByType(String type, String exerciseType) async {
    try {
      final query = await _firestore
          .collection('leaderboards')
          .where('type', isEqualTo: type)
          .where('exerciseType', isEqualTo: exerciseType)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return Leaderboard.fromFirestore(query.docs.first);
      }
      return null;
    } catch (e) {
      Logger.error('Failed to get leaderboard by type', tag: 'CHALLENGE_SERVICE', error: e);
      return null;
    }
  }

  // Update leaderboard entry
  static Future<void> updateLeaderboardEntry(
    String leaderboardId,
    String userId,
    String displayName,
    String? profileImageUrl,
    double value,
    String unit,
    Map<String, dynamic> metadata,
  ) async {
    try {
      final leaderboardRef = _firestore.collection('leaderboards').doc(leaderboardId);
      final leaderboard = await leaderboardRef.get();
      
      if (!leaderboard.exists) return;

      final leaderboardData = Leaderboard.fromFirestore(leaderboard);
      final entries = List<LeaderboardEntry>.from(leaderboardData.entries);
      
      // Remove existing entry for this user
      entries.removeWhere((entry) => entry.userId == userId);
      
      // Add new entry
      final newEntry = LeaderboardEntry(
        userId: userId,
        displayName: displayName,
        profileImageUrl: profileImageUrl,
        value: value,
        unit: unit,
        rank: 0, // Will be calculated below
        lastUpdated: DateTime.now(),
        metadata: metadata,
      );
      
      entries.add(newEntry);
      
      // Sort by value (descending for most metrics)
      entries.sort((a, b) => b.value.compareTo(a.value));
      
      // Update ranks
      for (int i = 0; i < entries.length; i++) {
        entries[i] = entries[i].copyWith(rank: i + 1);
      }
      
      // Update leaderboard
      await leaderboardRef.update({
        'entries': entries.map((e) => e.toMap()).toList(),
      });

      Logger.info('Leaderboard entry updated', tag: 'CHALLENGE_SERVICE', data: {
        'leaderboardId': leaderboardId,
        'userId': userId,
        'value': value,
        'rank': entries.firstWhere((e) => e.userId == userId).rank,
      });
    } catch (e) {
      Logger.error('Failed to update leaderboard entry', tag: 'CHALLENGE_SERVICE', error: e);
      rethrow;
    }
  }

  // Get user's achievements
  static Future<List<Achievement>> getUserAchievements(String userId) async {
    try {
      final query = await _firestore
          .collection('user_achievements')
          .where('userId', isEqualTo: userId)
          .get();

      final achievementIds = query.docs.map((doc) => doc.data()['achievementId'] as String).toList();
      
      if (achievementIds.isEmpty) return [];

      final achievementsQuery = await _firestore
          .collection('achievements')
          .where(FieldPath.documentId, whereIn: achievementIds)
          .get();

      return achievementsQuery.docs.map((doc) => Achievement.fromFirestore(doc)).toList();
    } catch (e) {
      Logger.error('Failed to get user achievements', tag: 'CHALLENGE_SERVICE', error: e);
      return [];
    }
  }

  // Check and unlock achievements
  static Future<List<Achievement>> checkAndUnlockAchievements(String userId, Map<String, dynamic> workoutData) async {
    try {
      final unlockedAchievements = <Achievement>[];
      
      // Get all available achievements
      final achievementsQuery = await _firestore
          .collection('achievements')
          .get();

      final allAchievements = achievementsQuery.docs.map((doc) => Achievement.fromFirestore(doc)).toList();
      
      // Get user's current achievements
      final userAchievements = await getUserAchievements(userId);
      final unlockedAchievementIds = userAchievements.map((a) => a.id).toSet();
      
      // Check each achievement
      for (final achievement in allAchievements) {
        if (unlockedAchievementIds.contains(achievement.id)) continue;
        
        if (_checkAchievementCriteria(achievement, workoutData)) {
          // Unlock achievement
          await _firestore.collection('user_achievements').add({
            'userId': userId,
            'achievementId': achievement.id,
            'unlockedAt': Timestamp.fromDate(DateTime.now()),
          });
          
          unlockedAchievements.add(achievement);
        }
      }

      if (unlockedAchievements.isNotEmpty) {
        Logger.info('Achievements unlocked', tag: 'CHALLENGE_SERVICE', data: {
          'userId': userId,
          'achievementCount': unlockedAchievements.length,
          'achievements': unlockedAchievements.map((a) => a.title).toList(),
        });
      }

      return unlockedAchievements;
    } catch (e) {
      Logger.error('Failed to check achievements', tag: 'CHALLENGE_SERVICE', error: e);
      return [];
    }
  }

  // Check if achievement criteria is met
  static bool _checkAchievementCriteria(Achievement achievement, Map<String, dynamic> workoutData) {
    final criteria = achievement.criteria;
    
    switch (achievement.type) {
      case 'streak':
        final requiredStreak = criteria['streak'] as int? ?? 0;
        final currentStreak = workoutData['currentStreak'] as int? ?? 0;
        return currentStreak >= requiredStreak;
        
      case 'total':
        final requiredTotal = criteria['total'] as int? ?? 0;
        final currentTotal = workoutData['totalReps'] as int? ?? 0;
        return currentTotal >= requiredTotal;
        
      case 'personal_record':
        final exerciseType = achievement.exerciseType;
        if (exerciseType == null) return false;
        
        final requiredValue = criteria['value'] as num? ?? 0;
        final currentValue = workoutData['totalReps'] as int? ?? 0;
        return currentValue >= requiredValue;
        
      case 'challenge':
        final challengeId = criteria['challengeId'] as String?;
        if (challengeId == null) return false;
        
        final isCompleted = workoutData['challengeCompleted'] as bool? ?? false;
        return isCompleted;
        
      default:
        return false;
    }
  }
}
