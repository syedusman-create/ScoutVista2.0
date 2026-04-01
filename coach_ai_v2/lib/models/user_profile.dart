import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String displayName;
  final String? profileImageUrl;
  final String? bio;
  final DateTime joinDate;
  final UserStats stats;
  final List<String> achievements;
  final List<String> following;
  final List<String> followers;
  final PrivacySettings privacy;
  final UserGoals goals;
  
  // Additional profile details
  final int? age;
  final double? height; // in cm
  final double? weight; // in kg
  final String? gender;
  final String? fitnessLevel;
  final String? primaryGoal;
  final List<String> sportPreferences;
  final String units; // 'metric' or 'imperial'

  const UserProfile({
    required this.uid,
    required this.displayName,
    this.profileImageUrl,
    this.bio,
    required this.joinDate,
    required this.stats,
    required this.achievements,
    required this.following,
    required this.followers,
    required this.privacy,
    required this.goals,
    this.age,
    this.height,
    this.weight,
    this.gender,
    this.fitnessLevel,
    this.primaryGoal,
    this.sportPreferences = const [],
    this.units = 'metric',
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      uid: doc.id,
      displayName: data['displayName'] ?? '',
      profileImageUrl: data['profileImageUrl'],
      bio: data['bio'],
      joinDate: (data['joinDate'] as Timestamp).toDate(),
      stats: UserStats.fromMap(data['stats'] ?? {}),
      achievements: List<String>.from(data['achievements'] ?? []),
      following: List<String>.from(data['following'] ?? []),
      followers: List<String>.from(data['followers'] ?? []),
      privacy: PrivacySettings.fromMap(data['privacy'] ?? {}),
      goals: UserGoals.fromMap(data['goals'] ?? {}),
      age: data['age'],
      height: data['height']?.toDouble(),
      weight: data['weight']?.toDouble(),
      gender: data['gender'],
      fitnessLevel: data['fitnessLevel'],
      primaryGoal: data['primaryGoal'],
      sportPreferences: List<String>.from(data['sportPreferences'] ?? []),
      units: data['units'] ?? 'metric',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'displayName': displayName,
      'profileImageUrl': profileImageUrl,
      'bio': bio,
      'joinDate': Timestamp.fromDate(joinDate),
      'stats': stats.toMap(),
      'achievements': achievements,
      'following': following,
      'followers': followers,
      'privacy': privacy.toMap(),
      'goals': goals.toMap(),
      'age': age,
      'height': height,
      'weight': weight,
      'gender': gender,
      'fitnessLevel': fitnessLevel,
      'primaryGoal': primaryGoal,
      'sportPreferences': sportPreferences,
      'units': units,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'profileImageUrl': profileImageUrl,
      'bio': bio,
      'joinDate': joinDate.toIso8601String(),
      'stats': stats.toMap(),
      'achievements': achievements,
      'following': following,
      'followers': followers,
      'privacy': privacy.toMap(),
      'goals': goals.toMap(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> data) {
    return UserProfile(
      uid: data['uid'] ?? '',
      displayName: data['displayName'] ?? '',
      profileImageUrl: data['profileImageUrl'],
      bio: data['bio'],
      joinDate: DateTime.parse(data['joinDate'] ?? DateTime.now().toIso8601String()),
      stats: UserStats.fromMap(data['stats'] ?? {}),
      achievements: List<String>.from(data['achievements'] ?? []),
      following: List<String>.from(data['following'] ?? []),
      followers: List<String>.from(data['followers'] ?? []),
      privacy: PrivacySettings.fromMap(data['privacy'] ?? {}),
      goals: UserGoals.fromMap(data['goals'] ?? {}),
    );
  }
}

class UserStats {
  final int totalWorkouts;
  final int totalReps;
  final double totalDistanceKm;
  final Duration totalWorkoutTime;
  final int currentStreak;
  final int longestStreak;
  final Map<String, int> exerciseCounts;
  final Map<String, double> personalRecords;

  const UserStats({
    required this.totalWorkouts,
    required this.totalReps,
    required this.totalDistanceKm,
    required this.totalWorkoutTime,
    required this.currentStreak,
    required this.longestStreak,
    required this.exerciseCounts,
    required this.personalRecords,
  });

  factory UserStats.fromMap(Map<String, dynamic> data) {
    return UserStats(
      totalWorkouts: data['totalWorkouts'] ?? 0,
      totalReps: data['totalReps'] ?? 0,
      totalDistanceKm: (data['totalDistanceKm'] ?? 0.0).toDouble(),
      totalWorkoutTime: Duration(seconds: data['totalWorkoutTimeSeconds'] ?? 0),
      currentStreak: data['currentStreak'] ?? 0,
      longestStreak: data['longestStreak'] ?? 0,
      exerciseCounts: Map<String, int>.from(data['exerciseCounts'] ?? {}),
      personalRecords: Map<String, double>.from(data['personalRecords'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalWorkouts': totalWorkouts,
      'totalReps': totalReps,
      'totalDistanceKm': totalDistanceKm,
      'totalWorkoutTimeSeconds': totalWorkoutTime.inSeconds,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'exerciseCounts': exerciseCounts,
      'personalRecords': personalRecords,
    };
  }
}

class PrivacySettings {
  final bool profilePublic;
  final bool workoutHistoryPublic;
  final bool achievementsPublic;
  final bool allowFriendRequests;
  final bool showInLeaderboards;

  const PrivacySettings({
    required this.profilePublic,
    required this.workoutHistoryPublic,
    required this.achievementsPublic,
    required this.allowFriendRequests,
    required this.showInLeaderboards,
  });

  factory PrivacySettings.fromMap(Map<String, dynamic> data) {
    return PrivacySettings(
      profilePublic: data['profilePublic'] ?? true,
      workoutHistoryPublic: data['workoutHistoryPublic'] ?? true,
      achievementsPublic: data['achievementsPublic'] ?? true,
      allowFriendRequests: data['allowFriendRequests'] ?? true,
      showInLeaderboards: data['showInLeaderboards'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'profilePublic': profilePublic,
      'workoutHistoryPublic': workoutHistoryPublic,
      'achievementsPublic': achievementsPublic,
      'allowFriendRequests': allowFriendRequests,
      'showInLeaderboards': showInLeaderboards,
    };
  }
}

class UserGoals {
  final int weeklyWorkouts;
  final int monthlyReps;
  final double monthlyDistanceKm;
  final List<String> targetExercises;
  final DateTime? targetDate;

  const UserGoals({
    required this.weeklyWorkouts,
    required this.monthlyReps,
    required this.monthlyDistanceKm,
    required this.targetExercises,
    this.targetDate,
  });

  factory UserGoals.fromMap(Map<String, dynamic> data) {
    return UserGoals(
      weeklyWorkouts: data['weeklyWorkouts'] ?? 3,
      monthlyReps: data['monthlyReps'] ?? 1000,
      monthlyDistanceKm: (data['monthlyDistanceKm'] ?? 50.0).toDouble(),
      targetExercises: List<String>.from(data['targetExercises'] ?? []),
      targetDate: data['targetDate'] != null 
          ? (data['targetDate'] as Timestamp).toDate() 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'weeklyWorkouts': weeklyWorkouts,
      'monthlyReps': monthlyReps,
      'monthlyDistanceKm': monthlyDistanceKm,
      'targetExercises': targetExercises,
      'targetDate': targetDate != null 
          ? Timestamp.fromDate(targetDate!) 
          : null,
    };
  }
}
