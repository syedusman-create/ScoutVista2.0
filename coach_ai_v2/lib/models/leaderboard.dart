import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

@immutable
class Leaderboard {
  final String id;
  final String title;
  final String description;
  final String type; // 'global', 'friends', 'challenge', 'exercise'
  final String exerciseType; // 'push_up', 'squat', 'run_5k', etc.
  final String metric; // 'reps', 'distance', 'time', 'streak'
  final String period; // 'daily', 'weekly', 'monthly', 'all_time'
  final DateTime startDate;
  final DateTime endDate;
  final List<LeaderboardEntry> entries;
  final bool isActive;
  final String? imageUrl;
  final Map<String, dynamic> rewards; // Top 3 rewards

  const Leaderboard({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.exerciseType,
    required this.metric,
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.entries,
    this.isActive = true,
    this.imageUrl,
    this.rewards = const {},
  });

  Leaderboard copyWith({
    String? id,
    String? title,
    String? description,
    String? type,
    String? exerciseType,
    String? metric,
    String? period,
    DateTime? startDate,
    DateTime? endDate,
    List<LeaderboardEntry>? entries,
    bool? isActive,
    String? imageUrl,
    Map<String, dynamic>? rewards,
  }) {
    return Leaderboard(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      exerciseType: exerciseType ?? this.exerciseType,
      metric: metric ?? this.metric,
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      entries: entries ?? this.entries,
      isActive: isActive ?? this.isActive,
      imageUrl: imageUrl ?? this.imageUrl,
      rewards: rewards ?? this.rewards,
    );
  }

  factory Leaderboard.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Leaderboard(
      id: doc.id,
      title: data['title'] as String,
      description: data['description'] as String,
      type: data['type'] as String,
      exerciseType: data['exerciseType'] as String,
      metric: data['metric'] as String,
      period: data['period'] as String,
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      entries: (data['entries'] as List<dynamic>?)
          ?.map((e) => LeaderboardEntry.fromMap(e as Map<String, dynamic>))
          .toList() ?? [],
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
      'metric': metric,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'entries': entries.map((e) => e.toMap()).toList(),
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
class LeaderboardEntry {
  final String userId;
  final String displayName;
  final String? profileImageUrl;
  final double value;
  final String unit;
  final int rank;
  final DateTime lastUpdated;
  final Map<String, dynamic> metadata; // Additional data like workout count, etc.

  const LeaderboardEntry({
    required this.userId,
    required this.displayName,
    this.profileImageUrl,
    required this.value,
    required this.unit,
    required this.rank,
    required this.lastUpdated,
    this.metadata = const {},
  });

  LeaderboardEntry copyWith({
    String? userId,
    String? displayName,
    String? profileImageUrl,
    double? value,
    String? unit,
    int? rank,
    DateTime? lastUpdated,
    Map<String, dynamic>? metadata,
  }) {
    return LeaderboardEntry(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      value: value ?? this.value,
      unit: unit ?? this.unit,
      rank: rank ?? this.rank,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      metadata: metadata ?? this.metadata,
    );
  }

  factory LeaderboardEntry.fromMap(Map<String, dynamic> map) {
    return LeaderboardEntry(
      userId: map['userId'] as String,
      displayName: map['displayName'] as String,
      profileImageUrl: map['profileImageUrl'] as String?,
      value: (map['value'] as num).toDouble(),
      unit: map['unit'] as String,
      rank: map['rank'] as int,
      lastUpdated: (map['lastUpdated'] as Timestamp).toDate(),
      metadata: map['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'displayName': displayName,
      'profileImageUrl': profileImageUrl,
      'value': value,
      'unit': unit,
      'rank': rank,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'metadata': metadata,
    };
  }
}

@immutable
class Achievement {
  final String id;
  final String title;
  final String description;
  final String type; // 'streak', 'total', 'personal_record', 'challenge', 'social'
  final String category; // 'fitness', 'social', 'exploration', 'mastery'
  final String? exerciseType; // Specific exercise if applicable
  final Map<String, dynamic> criteria; // Conditions to unlock
  final String iconName; // Icon identifier
  final int points; // Points awarded
  final bool isRare; // Rare achievements
  final DateTime? unlockedAt;
  final String? unlockedBy; // User ID who unlocked it

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.category,
    this.exerciseType,
    required this.criteria,
    required this.iconName,
    required this.points,
    this.isRare = false,
    this.unlockedAt,
    this.unlockedBy,
  });

  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    String? type,
    String? category,
    String? exerciseType,
    Map<String, dynamic>? criteria,
    String? iconName,
    int? points,
    bool? isRare,
    DateTime? unlockedAt,
    String? unlockedBy,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      category: category ?? this.category,
      exerciseType: exerciseType ?? this.exerciseType,
      criteria: criteria ?? this.criteria,
      iconName: iconName ?? this.iconName,
      points: points ?? this.points,
      isRare: isRare ?? this.isRare,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      unlockedBy: unlockedBy ?? this.unlockedBy,
    );
  }

  factory Achievement.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Achievement(
      id: doc.id,
      title: data['title'] as String,
      description: data['description'] as String,
      type: data['type'] as String,
      category: data['category'] as String,
      exerciseType: data['exerciseType'] as String?,
      criteria: data['criteria'] as Map<String, dynamic>,
      iconName: data['iconName'] as String,
      points: data['points'] as int,
      isRare: data['isRare'] as bool? ?? false,
      unlockedAt: data['unlockedAt'] != null 
          ? (data['unlockedAt'] as Timestamp).toDate() 
          : null,
      unlockedBy: data['unlockedBy'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'type': type,
      'category': category,
      'exerciseType': exerciseType,
      'criteria': criteria,
      'iconName': iconName,
      'points': points,
      'isRare': isRare,
      'unlockedAt': unlockedAt != null ? Timestamp.fromDate(unlockedAt!) : null,
      'unlockedBy': unlockedBy,
    };
  }

  bool get isUnlocked => unlockedAt != null;
}
