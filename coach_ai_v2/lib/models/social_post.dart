import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

@immutable
class SocialPost {
  final String id;
  final String userId;
  final String displayName;
  final String? profileImageUrl;
  final String content;
  final String? imageUrl;
  final String? videoUrl;
  final String postType; // 'workout', 'achievement', 'general', 'challenge'
  final Map<String, dynamic>? workoutData; // For workout posts
  final Map<String, dynamic>? achievementData; // For achievement posts
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> likes; // User IDs who liked
  final List<Comment> comments;
  final List<String> shares; // User IDs who shared
  final bool isPublic;
  final List<String> tags;
  final String? challengeId; // If post is related to a challenge
  final String timeAgo;

  const SocialPost({
    required this.id,
    required this.userId,
    required this.displayName,
    this.profileImageUrl,
    required this.content,
    this.imageUrl,
    this.videoUrl,
    required this.postType,
    this.workoutData,
    this.achievementData,
    required this.createdAt,
    required this.updatedAt,
    this.likes = const [],
    this.comments = const [],
    this.shares = const [],
    this.isPublic = true,
    this.tags = const [],
    this.challengeId,
    required this.timeAgo,
  });

  SocialPost copyWith({
    String? id,
    String? userId,
    String? displayName,
    String? profileImageUrl,
    String? content,
    String? imageUrl,
    String? videoUrl,
    String? postType,
    Map<String, dynamic>? workoutData,
    Map<String, dynamic>? achievementData,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? likes,
    List<Comment>? comments,
    List<String>? shares,
    bool? isPublic,
    List<String>? tags,
    String? challengeId,
    String? timeAgo,
  }) {
    return SocialPost(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      postType: postType ?? this.postType,
      workoutData: workoutData ?? this.workoutData,
      achievementData: achievementData ?? this.achievementData,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      shares: shares ?? this.shares,
      isPublic: isPublic ?? this.isPublic,
      tags: tags ?? this.tags,
      challengeId: challengeId ?? this.challengeId,
      timeAgo: timeAgo ?? this.timeAgo,
    );
  }

  factory SocialPost.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SocialPost(
      id: doc.id,
      userId: data['userId'] as String,
      displayName: data['displayName'] as String,
      profileImageUrl: data['profileImageUrl'] as String?,
      content: data['content'] as String,
      imageUrl: data['imageUrl'] as String?,
      videoUrl: data['videoUrl'] as String?,
      postType: data['postType'] as String,
      workoutData: data['workoutData'] as Map<String, dynamic>?,
      achievementData: data['achievementData'] as Map<String, dynamic>?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      likes: List<String>.from(data['likes'] ?? []),
      comments: (data['comments'] as List<dynamic>?)
          ?.map((c) => Comment.fromMap(c as Map<String, dynamic>))
          .toList() ?? [],
      shares: List<String>.from(data['shares'] ?? []),
      isPublic: data['isPublic'] as bool? ?? true,
      tags: List<String>.from(data['tags'] ?? []),
      challengeId: data['challengeId'] as String?,
      timeAgo: _formatTimeAgo((data['createdAt'] as Timestamp).toDate()),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'displayName': displayName,
      'profileImageUrl': profileImageUrl,
      'content': content,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'postType': postType,
      'workoutData': workoutData,
      'achievementData': achievementData,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'likes': likes,
      'comments': comments.map((c) => c.toMap()).toList(),
      'shares': shares,
      'isPublic': isPublic,
      'tags': tags,
      'challengeId': challengeId,
    };
  }

  int get likeCount => likes.length;
  int get commentCount => comments.length;
  int get shareCount => shares.length;

  static String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

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
class Comment {
  final String id;
  final String userId;
  final String displayName;
  final String? profileImageUrl;
  final String content;
  final DateTime createdAt;
  final List<String> likes;
  final String? parentCommentId; // For replies

  const Comment({
    required this.id,
    required this.userId,
    required this.displayName,
    this.profileImageUrl,
    required this.content,
    required this.createdAt,
    this.likes = const [],
    this.parentCommentId,
  });

  Comment copyWith({
    String? id,
    String? userId,
    String? displayName,
    String? profileImageUrl,
    String? content,
    DateTime? createdAt,
    List<String>? likes,
    String? parentCommentId,
  }) {
    return Comment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      likes: likes ?? this.likes,
      parentCommentId: parentCommentId ?? this.parentCommentId,
    );
  }

  factory Comment.fromMap(Map<String, dynamic> map) {
    return Comment(
      id: map['id'] as String,
      userId: map['userId'] as String,
      displayName: map['displayName'] as String,
      profileImageUrl: map['profileImageUrl'] as String?,
      content: map['content'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      likes: List<String>.from(map['likes'] ?? []),
      parentCommentId: map['parentCommentId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'displayName': displayName,
      'profileImageUrl': profileImageUrl,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'likes': likes,
      'parentCommentId': parentCommentId,
    };
  }

  int get likeCount => likes.length;
}

@immutable
class WorkoutShare {
  final String id;
  final String userId;
  final String workoutSessionId;
  final String exerciseType;
  final Map<String, dynamic> workoutResults;
  final String? caption;
  final String? imageUrl;
  final String? videoUrl;
  final DateTime createdAt;
  final List<String> likes;
  final List<Comment> comments;
  final List<String> shares;
  final bool isPublic;
  final List<String> tags;

  const WorkoutShare({
    required this.id,
    required this.userId,
    required this.workoutSessionId,
    required this.exerciseType,
    required this.workoutResults,
    this.caption,
    this.imageUrl,
    this.videoUrl,
    required this.createdAt,
    this.likes = const [],
    this.comments = const [],
    this.shares = const [],
    this.isPublic = true,
    this.tags = const [],
  });

  WorkoutShare copyWith({
    String? id,
    String? userId,
    String? workoutSessionId,
    String? exerciseType,
    Map<String, dynamic>? workoutResults,
    String? caption,
    String? imageUrl,
    String? videoUrl,
    DateTime? createdAt,
    List<String>? likes,
    List<Comment>? comments,
    List<String>? shares,
    bool? isPublic,
    List<String>? tags,
  }) {
    return WorkoutShare(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      workoutSessionId: workoutSessionId ?? this.workoutSessionId,
      exerciseType: exerciseType ?? this.exerciseType,
      workoutResults: workoutResults ?? this.workoutResults,
      caption: caption ?? this.caption,
      imageUrl: imageUrl ?? this.imageUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      createdAt: createdAt ?? this.createdAt,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      shares: shares ?? this.shares,
      isPublic: isPublic ?? this.isPublic,
      tags: tags ?? this.tags,
    );
  }

  factory WorkoutShare.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WorkoutShare(
      id: doc.id,
      userId: data['userId'] as String,
      workoutSessionId: data['workoutSessionId'] as String,
      exerciseType: data['exerciseType'] as String,
      workoutResults: data['workoutResults'] as Map<String, dynamic>,
      caption: data['caption'] as String?,
      imageUrl: data['imageUrl'] as String?,
      videoUrl: data['videoUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      likes: List<String>.from(data['likes'] ?? []),
      comments: (data['comments'] as List<dynamic>?)
          ?.map((c) => Comment.fromMap(c as Map<String, dynamic>))
          .toList() ?? [],
      shares: List<String>.from(data['shares'] ?? []),
      isPublic: data['isPublic'] as bool? ?? true,
      tags: List<String>.from(data['tags'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'workoutSessionId': workoutSessionId,
      'exerciseType': exerciseType,
      'workoutResults': workoutResults,
      'caption': caption,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'likes': likes,
      'comments': comments.map((c) => c.toMap()).toList(),
      'shares': shares,
      'isPublic': isPublic,
      'tags': tags,
    };
  }

  int get likeCount => likes.length;
  int get commentCount => comments.length;
  int get shareCount => shares.length;
}
