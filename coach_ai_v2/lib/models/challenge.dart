import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

@immutable
class Challenge {
  final String id;
  final String title;
  final String description;
  final String type; // 'daily', 'weekly', 'monthly', 'custom'
  final String exerciseType; // 'push_up', 'squat', 'run_5k', etc.
  final Map<String, dynamic> target; // e.g., {'reps': 100, 'distance': 5.0}
  final DateTime startDate;
  final DateTime endDate;
  final List<String> participants; // User IDs
  final String createdBy; // User ID
  final DateTime createdAt;
  final bool isActive;
  final String? imageUrl;
  final Map<String, dynamic> rewards; // e.g., {'points': 100, 'badge': 'challenge_complete'}

  const Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.exerciseType,
    required this.target,
    required this.startDate,
    required this.endDate,
    required this.participants,
    required this.createdBy,
    required this.createdAt,
    this.isActive = true,
    this.imageUrl,
    this.rewards = const {},
  });

  Challenge copyWith({
    String? id,
    String? title,
    String? description,
    String? type,
    String? exerciseType,
    Map<String, dynamic>? target,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? participants,
    String? createdBy,
    DateTime? createdAt,
    bool? isActive,
    String? imageUrl,
    Map<String, dynamic>? rewards,
  }) {
    return Challenge(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      exerciseType: exerciseType ?? this.exerciseType,
      target: target ?? this.target,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      participants: participants ?? this.participants,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      imageUrl: imageUrl ?? this.imageUrl,
      rewards: rewards ?? this.rewards,
    );
  }

  factory Challenge.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Challenge(
      id: doc.id,
      title: data['title'] as String,
      description: data['description'] as String,
      type: data['type'] as String,
      exerciseType: data['exerciseType'] as String,
      target: data['target'] as Map<String, dynamic>,
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      participants: List<String>.from(data['participants'] ?? []),
      createdBy: data['createdBy'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isActive: data['isActive'] as bool? ?? true,
      imageUrl: data['imageUrl'] as String?,
      rewards: data['rewards'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'type': type,
      'exerciseType': exerciseType,
      'target': target,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'participants': participants,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
      'imageUrl': imageUrl,
      'rewards': rewards,
    };
  }

  bool get isExpired => DateTime.now().isAfter(endDate);
  bool get isUpcoming => DateTime.now().isBefore(startDate);
  bool get isOngoing => !isExpired && !isUpcoming;
}

@immutable
class ChallengeProgress {
  final String id;
  final String challengeId;
  final String userId;
  final Map<String, dynamic> currentProgress; // e.g., {'reps': 50, 'distance': 2.5}
  final double completionPercentage;
  final DateTime lastUpdated;
  final bool isCompleted;
  final DateTime? completedAt;

  const ChallengeProgress({
    required this.id,
    required this.challengeId,
    required this.userId,
    required this.currentProgress,
    required this.completionPercentage,
    required this.lastUpdated,
    this.isCompleted = false,
    this.completedAt,
  });

  ChallengeProgress copyWith({
    String? id,
    String? challengeId,
    String? userId,
    Map<String, dynamic>? currentProgress,
    double? completionPercentage,
    DateTime? lastUpdated,
    bool? isCompleted,
    DateTime? completedAt,
  }) {
    return ChallengeProgress(
      id: id ?? this.id,
      challengeId: challengeId ?? this.challengeId,
      userId: userId ?? this.userId,
      currentProgress: currentProgress ?? this.currentProgress,
      completionPercentage: completionPercentage ?? this.completionPercentage,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  factory ChallengeProgress.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChallengeProgress(
      id: doc.id,
      challengeId: data['challengeId'] as String,
      userId: data['userId'] as String,
      currentProgress: data['currentProgress'] as Map<String, dynamic>,
      completionPercentage: (data['completionPercentage'] as num).toDouble(),
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
      isCompleted: data['isCompleted'] as bool? ?? false,
      completedAt: data['completedAt'] != null 
          ? (data['completedAt'] as Timestamp).toDate() 
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'challengeId': challengeId,
      'userId': userId,
      'currentProgress': currentProgress,
      'completionPercentage': completionPercentage,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'isCompleted': isCompleted,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }
}
