import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/social_post.dart';
import '../models/workout_session.dart';
import '../services/notification_service.dart';
import '../utils/logger.dart';

class SocialService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create a social post
  static Future<String> createPost(SocialPost post) async {
    try {
      final docRef = await _firestore.collection('social_posts').add(post.toFirestore());
      
      Logger.info('Social post created successfully', tag: 'SOCIAL_SERVICE', data: {
        'postId': docRef.id,
        'userId': post.userId,
        'postType': post.postType,
      });
      
      return docRef.id;
    } catch (e) {
      Logger.error('Failed to create social post', tag: 'SOCIAL_SERVICE', error: e);
      rethrow;
    }
  }

  // Share a workout session
  static Future<String> shareWorkout(WorkoutSession session, String caption, {String? imageUrl, String? videoUrl}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final workoutShare = WorkoutShare(
        id: '',
        userId: user.uid,
        workoutSessionId: session.id,
        exerciseType: session.exerciseType,
        workoutResults: session.results,
        caption: caption,
        imageUrl: imageUrl,
        videoUrl: videoUrl,
        createdAt: DateTime.now(),
        tags: _generateWorkoutTags(session),
      );

      final docRef = await _firestore.collection('workout_shares').add(workoutShare.toFirestore());
      
      // Also create a social post for the feed
      final socialPost = SocialPost(
        id: '',
        userId: user.uid,
        displayName: user.displayName ?? 'Fitness Enthusiast',
        profileImageUrl: user.photoURL,
        content: caption,
        imageUrl: imageUrl,
        videoUrl: videoUrl,
        postType: 'workout',
        workoutData: {
          'workoutSessionId': session.id,
          'exerciseType': session.exerciseType,
          'results': session.results,
          'metrics': session.metrics.map((m) => m.toMap()).toList(),
        },
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        timeAgo: 'Just now',
        tags: _generateWorkoutTags(session),
      );

      await createPost(socialPost);

      Logger.info('Workout shared successfully', tag: 'SOCIAL_SERVICE', data: {
        'workoutSessionId': session.id,
        'exerciseType': session.exerciseType,
      });
      
      return docRef.id;
    } catch (e) {
      Logger.error('Failed to share workout', tag: 'SOCIAL_SERVICE', error: e);
      rethrow;
    }
  }

  // Get social feed posts
  static Future<List<SocialPost>> getFeedPosts({int limit = 20, DocumentSnapshot? lastDoc}) async {
    try {
      Query query = _firestore
          .collection('social_posts')
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      final querySnapshot = await query.get();
      return querySnapshot.docs.map((doc) => SocialPost.fromFirestore(doc)).toList();
    } catch (e) {
      Logger.error('Failed to get feed posts', tag: 'SOCIAL_SERVICE', error: e);
      return [];
    }
  }

  // Get user's posts
  static Future<List<SocialPost>> getUserPosts(String userId, {int limit = 20}) async {
    try {
      final query = await _firestore
          .collection('social_posts')
          .where('userId', isEqualTo: userId)
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return query.docs.map((doc) => SocialPost.fromFirestore(doc)).toList();
    } catch (e) {
      Logger.error('Failed to get user posts', tag: 'SOCIAL_SERVICE', error: e);
      return [];
    }
  }

  // Like a post
  static Future<void> likePost(String postId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Get post details first
      final postDoc = await _firestore.collection('social_posts').doc(postId).get();
      if (!postDoc.exists) return;

      final post = SocialPost.fromFirestore(postDoc);
      
      await _firestore.collection('social_posts').doc(postId).update({
        'likes': FieldValue.arrayUnion([user.uid]),
      });

      // Create notification for post owner
      await NotificationService.createLikeNotification(
        postId: postId,
        postOwnerId: post.userId,
        likerId: user.uid,
        likerName: user.displayName ?? 'Fitness Enthusiast',
        likerImageUrl: user.photoURL,
      );

      Logger.info('Post liked successfully', tag: 'SOCIAL_SERVICE', data: {
        'postId': postId,
        'userId': user.uid,
      });
    } catch (e) {
      Logger.error('Failed to like post', tag: 'SOCIAL_SERVICE', error: e);
      rethrow;
    }
  }

  // Unlike a post
  static Future<void> unlikePost(String postId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('social_posts').doc(postId).update({
        'likes': FieldValue.arrayRemove([user.uid]),
      });

      Logger.info('Post unliked successfully', tag: 'SOCIAL_SERVICE', data: {
        'postId': postId,
        'userId': user.uid,
      });
    } catch (e) {
      Logger.error('Failed to unlike post', tag: 'SOCIAL_SERVICE', error: e);
      rethrow;
    }
  }

  // Add comment to post
  static Future<void> addComment(String postId, String content) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Get post details first
      final postDoc = await _firestore.collection('social_posts').doc(postId).get();
      if (!postDoc.exists) return;

      final post = SocialPost.fromFirestore(postDoc);

      final comment = Comment(
        id: _firestore.collection('comments').doc().id,
        userId: user.uid,
        displayName: user.displayName ?? 'Fitness Enthusiast',
        profileImageUrl: user.photoURL,
        content: content,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('social_posts').doc(postId).update({
        'comments': FieldValue.arrayUnion([comment.toMap()]),
      });

      // Create notification for post owner
      await NotificationService.createCommentNotification(
        postId: postId,
        postOwnerId: post.userId,
        commenterId: user.uid,
        commenterName: user.displayName ?? 'Fitness Enthusiast',
        commenterImageUrl: user.photoURL,
        comment: content,
      );

      Logger.info('Comment added successfully', tag: 'SOCIAL_SERVICE', data: {
        'postId': postId,
        'userId': user.uid,
      });
    } catch (e) {
      Logger.error('Failed to add comment', tag: 'SOCIAL_SERVICE', error: e);
      rethrow;
    }
  }

  // Share a post
  static Future<void> sharePost(String postId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('social_posts').doc(postId).update({
        'shares': FieldValue.arrayUnion([user.uid]),
      });

      Logger.info('Post shared successfully', tag: 'SOCIAL_SERVICE', data: {
        'postId': postId,
        'userId': user.uid,
      });
    } catch (e) {
      Logger.error('Failed to share post', tag: 'SOCIAL_SERVICE', error: e);
      rethrow;
    }
  }

  // Get workout shares
  static Future<List<WorkoutShare>> getWorkoutShares({int limit = 20}) async {
    try {
      final query = await _firestore
          .collection('workout_shares')
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return query.docs.map((doc) => WorkoutShare.fromFirestore(doc)).toList();
    } catch (e) {
      Logger.error('Failed to get workout shares', tag: 'SOCIAL_SERVICE', error: e);
      return [];
    }
  }

  // Get workout shares by exercise type
  static Future<List<WorkoutShare>> getWorkoutSharesByType(String exerciseType, {int limit = 20}) async {
    try {
      final query = await _firestore
          .collection('workout_shares')
          .where('exerciseType', isEqualTo: exerciseType)
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return query.docs.map((doc) => WorkoutShare.fromFirestore(doc)).toList();
    } catch (e) {
      Logger.error('Failed to get workout shares by type', tag: 'SOCIAL_SERVICE', error: e);
      return [];
    }
  }

  // Get trending workout shares
  static Future<List<WorkoutShare>> getTrendingWorkoutShares({int limit = 10}) async {
    try {
      final query = await _firestore
          .collection('workout_shares')
          .where('isPublic', isEqualTo: true)
          .orderBy('likes', descending: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return query.docs.map((doc) => WorkoutShare.fromFirestore(doc)).toList();
    } catch (e) {
      Logger.error('Failed to get trending workout shares', tag: 'SOCIAL_SERVICE', error: e);
      return [];
    }
  }

  // Create group challenge
  static Future<String> createGroupChallenge({
    required String title,
    required String description,
    required String exerciseType,
    required Map<String, dynamic> target,
    required DateTime endDate,
    required List<String> participantIds,
    String? imageUrl,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final challenge = {
        'title': title,
        'description': description,
        'exerciseType': exerciseType,
        'target': target,
        'type': 'group',
        'startDate': Timestamp.fromDate(DateTime.now()),
        'endDate': Timestamp.fromDate(endDate),
        'participants': participantIds,
        'createdBy': user.uid,
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'isActive': true,
        'imageUrl': imageUrl,
        'rewards': {
          'winner': 'Custom trophy badge',
          'top3': 'Achievement badges',
          'participants': 'Completion certificate',
        },
      };

      final docRef = await _firestore.collection('group_challenges').add(challenge);
      
      // Create social post for the challenge
      final socialPost = SocialPost(
        id: '',
        userId: user.uid,
        displayName: user.displayName ?? 'Fitness Enthusiast',
        profileImageUrl: user.photoURL,
        content: 'Created a new group challenge: $title',
        imageUrl: imageUrl,
        postType: 'challenge',
        challengeId: docRef.id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        timeAgo: 'Just now',
        tags: ['challenge', 'group', exerciseType],
      );

      await createPost(socialPost);

      Logger.info('Group challenge created successfully', tag: 'SOCIAL_SERVICE', data: {
        'challengeId': docRef.id,
        'title': title,
        'participantCount': participantIds.length,
      });
      
      return docRef.id;
    } catch (e) {
      Logger.error('Failed to create group challenge', tag: 'SOCIAL_SERVICE', error: e);
      rethrow;
    }
  }

  // Join group challenge
  static Future<void> joinGroupChallenge(String challengeId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('group_challenges').doc(challengeId).update({
        'participants': FieldValue.arrayUnion([user.uid]),
      });

      Logger.info('Joined group challenge', tag: 'SOCIAL_SERVICE', data: {
        'challengeId': challengeId,
        'userId': user.uid,
      });
    } catch (e) {
      Logger.error('Failed to join group challenge', tag: 'SOCIAL_SERVICE', error: e);
      rethrow;
    }
  }

  // Get group challenges
  static Future<List<Map<String, dynamic>>> getGroupChallenges({int limit = 20}) async {
    try {
      final query = await _firestore
          .collection('group_challenges')
          .where('isActive', isEqualTo: true)
          .orderBy('endDate')
          .limit(limit)
          .get();

      return query.docs.map((doc) => {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      }).toList();
    } catch (e) {
      Logger.error('Failed to get group challenges', tag: 'SOCIAL_SERVICE', error: e);
      return [];
    }
  }

  // Generate workout tags based on results
  static List<String> _generateWorkoutTags(WorkoutSession session) {
    final tags = <String>[];
    
    // Add exercise type tag
    tags.add(session.exerciseType);
    
    // Add performance-based tags
    if (session.results.containsKey('totalReps')) {
      final reps = session.results['totalReps'] as int;
      if (reps >= 50) tags.add('high_reps');
      if (reps >= 100) tags.add('elite');
    }
    
    if (session.results.containsKey('totalDistanceKm')) {
      final distance = session.results['totalDistanceKm'] as double;
      if (distance >= 5.0) tags.add('long_distance');
      if (distance >= 10.0) tags.add('marathon');
    }
    
    if (session.results.containsKey('averageFormScore')) {
      final formScore = session.results['averageFormScore'] as double;
      if (formScore >= 90) tags.add('perfect_form');
      if (formScore >= 95) tags.add('flawless');
    }
    
    // Add time-based tags
    final duration = session.duration.inMinutes;
    if (duration >= 30) tags.add('endurance');
    if (duration >= 60) tags.add('marathon_session');
    
    return tags;
  }
}
