import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';
import '../models/social_post.dart';
import '../models/challenge.dart';
import '../utils/logger.dart';

class SearchService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Search users by display name
  static Future<List<UserProfile>> searchUsers(String query, {int limit = 20}) async {
    try {
      if (query.trim().isEmpty) return [];

      final querySnapshot = await _firestore
          .collection('assessments')
          .where('type', isEqualTo: 'user_profile')
          .where('displayName', isGreaterThanOrEqualTo: query.trim())
          .where('displayName', isLessThan: query.trim() + '\uf8ff')
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => UserProfile.fromFirestore(doc))
          .toList();
    } catch (e) {
      Logger.error('Failed to search users', tag: 'SEARCH_SERVICE', error: e);
      return [];
    }
  }

  // Search posts by content
  static Future<List<SocialPost>> searchPosts(String query, {int limit = 20}) async {
    try {
      if (query.trim().isEmpty) return [];

      final querySnapshot = await _firestore
          .collection('social_posts')
          .where('isPublic', isEqualTo: true)
          .where('content', isGreaterThanOrEqualTo: query.trim())
          .where('content', isLessThan: query.trim() + '\uf8ff')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => SocialPost.fromFirestore(doc))
          .toList();
    } catch (e) {
      Logger.error('Failed to search posts', tag: 'SEARCH_SERVICE', error: e);
      return [];
    }
  }

  // Search challenges by title or description
  static Future<List<Challenge>> searchChallenges(String query, {int limit = 20}) async {
    try {
      if (query.trim().isEmpty) return [];

      final querySnapshot = await _firestore
          .collection('challenges')
          .where('isActive', isEqualTo: true)
          .where('title', isGreaterThanOrEqualTo: query.trim())
          .where('title', isLessThan: query.trim() + '\uf8ff')
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => Challenge.fromFirestore(doc))
          .toList();
    } catch (e) {
      Logger.error('Failed to search challenges', tag: 'SEARCH_SERVICE', error: e);
      return [];
    }
  }

  // Search by exercise type
  static Future<List<SocialPost>> searchByExerciseType(String exerciseType, {int limit = 20}) async {
    try {
      final querySnapshot = await _firestore
          .collection('social_posts')
          .where('isPublic', isEqualTo: true)
          .where('postType', isEqualTo: 'workout')
          .where('workoutData.exerciseType', isEqualTo: exerciseType)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => SocialPost.fromFirestore(doc))
          .toList();
    } catch (e) {
      Logger.error('Failed to search by exercise type', tag: 'SEARCH_SERVICE', error: e);
      return [];
    }
  }

  // Get trending users (most followed)
  static Future<List<UserProfile>> getTrendingUsers({int limit = 10}) async {
    try {
      final querySnapshot = await _firestore
          .collection('assessments')
          .where('type', isEqualTo: 'user_profile')
          .orderBy('stats.totalWorkouts', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => UserProfile.fromFirestore(doc))
          .toList();
    } catch (e) {
      Logger.error('Failed to get trending users', tag: 'SEARCH_SERVICE', error: e);
      return [];
    }
  }

  // Get trending posts (most liked)
  static Future<List<SocialPost>> getTrendingPosts({int limit = 10}) async {
    try {
      final querySnapshot = await _firestore
          .collection('social_posts')
          .where('isPublic', isEqualTo: true)
          .orderBy('likes', descending: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => SocialPost.fromFirestore(doc))
          .toList();
    } catch (e) {
      Logger.error('Failed to get trending posts', tag: 'SEARCH_SERVICE', error: e);
      return [];
    }
  }

  // Get recommended users (based on similar interests)
  static Future<List<UserProfile>> getRecommendedUsers({int limit = 10}) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return [];

      // Get current user's profile
      final currentProfileDoc = await _firestore
          .collection('assessments')
          .doc('${currentUser.uid}_profile')
          .get();

      if (!currentProfileDoc.exists) return [];

      final currentProfile = UserProfile.fromFirestore(currentProfileDoc);
      
      // Get users with similar exercise preferences
      final exerciseTypes = currentProfile.stats.exerciseCounts.keys.toList();
      if (exerciseTypes.isEmpty) return [];

      final querySnapshot = await _firestore
          .collection('assessments')
          .where('type', isEqualTo: 'user_profile')
          .where('uid', isNotEqualTo: currentUser.uid)
          .limit(limit)
          .get();

      final profiles = querySnapshot.docs
          .map((doc) => UserProfile.fromFirestore(doc))
          .toList();

      // Sort by similarity (users with similar exercise types)
      profiles.sort((a, b) {
        final aSimilarity = _calculateSimilarity(currentProfile, a);
        final bSimilarity = _calculateSimilarity(currentProfile, b);
        return bSimilarity.compareTo(aSimilarity);
      });

      return profiles.take(limit).toList();
    } catch (e) {
      Logger.error('Failed to get recommended users', tag: 'SEARCH_SERVICE', error: e);
      return [];
    }
  }

  // Get recent activity from followed users
  static Future<List<SocialPost>> getRecentActivity({int limit = 20}) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return [];

      // Get current user's following list
      final profileDoc = await _firestore
          .collection('assessments')
          .doc('${currentUser.uid}_profile')
          .get();

      if (!profileDoc.exists) return [];

      final profile = UserProfile.fromFirestore(profileDoc);
      if (profile.following.isEmpty) return [];

      // Get posts from followed users
      final querySnapshot = await _firestore
          .collection('social_posts')
          .where('isPublic', isEqualTo: true)
          .where('userId', whereIn: profile.following)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => SocialPost.fromFirestore(doc))
          .toList();
    } catch (e) {
      Logger.error('Failed to get recent activity', tag: 'SEARCH_SERVICE', error: e);
      return [];
    }
  }

  // Get discover content (mix of trending and recommended)
  static Future<Map<String, dynamic>> getDiscoverContent() async {
    try {
      final trendingUsers = await getTrendingUsers(limit: 5);
      final trendingPosts = await getTrendingPosts(limit: 5);
      final recommendedUsers = await getRecommendedUsers(limit: 5);
      final recentActivity = await getRecentActivity(limit: 10);

      return {
        'trendingUsers': trendingUsers,
        'trendingPosts': trendingPosts,
        'recommendedUsers': recommendedUsers,
        'recentActivity': recentActivity,
      };
    } catch (e) {
      Logger.error('Failed to get discover content', tag: 'SEARCH_SERVICE', error: e);
      return {
        'trendingUsers': <UserProfile>[],
        'trendingPosts': <SocialPost>[],
        'recommendedUsers': <UserProfile>[],
        'recentActivity': <SocialPost>[],
      };
    }
  }

  // Search by hashtags
  static Future<List<SocialPost>> searchByHashtag(String hashtag, {int limit = 20}) async {
    try {
      if (hashtag.trim().isEmpty) return [];

      final cleanHashtag = hashtag.trim().startsWith('#') 
          ? hashtag.trim().substring(1) 
          : hashtag.trim();

      final querySnapshot = await _firestore
          .collection('social_posts')
          .where('isPublic', isEqualTo: true)
          .where('tags', arrayContains: cleanHashtag)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => SocialPost.fromFirestore(doc))
          .toList();
    } catch (e) {
      Logger.error('Failed to search by hashtag', tag: 'SEARCH_SERVICE', error: e);
      return [];
    }
  }

  // Get popular hashtags
  static Future<List<String>> getPopularHashtags({int limit = 10}) async {
    try {
      final querySnapshot = await _firestore
          .collection('social_posts')
          .where('isPublic', isEqualTo: true)
          .get();

      final hashtagCounts = <String, int>{};
      
      for (final doc in querySnapshot.docs) {
        final post = SocialPost.fromFirestore(doc);
        for (final tag in post.tags) {
          hashtagCounts[tag] = (hashtagCounts[tag] ?? 0) + 1;
        }
      }

      final sortedHashtags = hashtagCounts.entries
          .toList()
          ..sort((a, b) => b.value.compareTo(a.value));

      return sortedHashtags
          .take(limit)
          .map((entry) => '#${entry.key}')
          .toList();
    } catch (e) {
      Logger.error('Failed to get popular hashtags', tag: 'SEARCH_SERVICE', error: e);
      return [];
    }
  }

  // Calculate similarity between two user profiles
  static double _calculateSimilarity(UserProfile user1, UserProfile user2) {
    final exercises1 = user1.stats.exerciseCounts.keys.toSet();
    final exercises2 = user2.stats.exerciseCounts.keys.toSet();
    
    if (exercises1.isEmpty || exercises2.isEmpty) return 0.0;
    
    final intersection = exercises1.intersection(exercises2).length;
    final union = exercises1.union(exercises2).length;
    
    return intersection / union;
  }

  // Get search suggestions based on query
  static Future<List<String>> getSearchSuggestions(String query) async {
    try {
      if (query.trim().isEmpty) return [];

      final suggestions = <String>[];
      
      // Add user suggestions
      final users = await searchUsers(query, limit: 3);
      suggestions.addAll(users.map((user) => user.displayName));
      
      // Add hashtag suggestions
      final hashtags = await getPopularHashtags(limit: 5);
      final matchingHashtags = hashtags
          .where((tag) => tag.toLowerCase().contains(query.toLowerCase()))
          .take(3);
      suggestions.addAll(matchingHashtags);
      
      // Add exercise type suggestions
      final exerciseTypes = ['push_up', 'squat', 'run_5k', 'shuttle_pro_agility'];
      final matchingExercises = exerciseTypes
          .where((type) => type.toLowerCase().contains(query.toLowerCase()))
          .take(2);
      suggestions.addAll(matchingExercises);
      
      return suggestions.take(8).toList();
    } catch (e) {
      Logger.error('Failed to get search suggestions', tag: 'SEARCH_SERVICE', error: e);
      return [];
    }
  }
}
