import 'package:cloud_firestore/cloud_firestore.dart';

class WorkoutSession {
  final String id;
  final String userId;
  final String exerciseType;
  final DateTime startTime;
  final DateTime endTime;
  final Duration duration;
  final Map<String, dynamic> results;
  final List<WorkoutMetric> metrics;
  final bool isPublic;
  final List<String> tags;
  final String? notes;
  final List<String> sharedWith;

  const WorkoutSession({
    required this.id,
    required this.userId,
    required this.exerciseType,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.results,
    required this.metrics,
    required this.isPublic,
    required this.tags,
    this.notes,
    required this.sharedWith,
  });

  factory WorkoutSession.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WorkoutSession(
      id: doc.id,
      userId: data['userId'] ?? '',
      exerciseType: data['exerciseType'] ?? '',
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      duration: Duration(seconds: data['durationSeconds'] ?? 0),
      results: Map<String, dynamic>.from(data['results'] ?? {}),
      metrics: (data['metrics'] as List<dynamic>?)
          ?.map((m) => WorkoutMetric.fromMap(m as Map<String, dynamic>))
          .toList() ?? [],
      isPublic: data['isPublic'] ?? false,
      tags: List<String>.from(data['tags'] ?? []),
      notes: data['notes'],
      sharedWith: List<String>.from(data['sharedWith'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'exerciseType': exerciseType,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'durationSeconds': duration.inSeconds,
      'results': results,
      'metrics': metrics.map((m) => m.toMap()).toList(),
      'isPublic': isPublic,
      'tags': tags,
      'notes': notes,
      'sharedWith': sharedWith,
    };
  }
}

class WorkoutMetric {
  final String name;
  final double value;
  final String unit;
  final String category;

  const WorkoutMetric({
    required this.name,
    required this.value,
    required this.unit,
    required this.category,
  });

  factory WorkoutMetric.fromMap(Map<String, dynamic> data) {
    return WorkoutMetric(
      name: data['name'] ?? '',
      value: (data['value'] ?? 0.0).toDouble(),
      unit: data['unit'] ?? '',
      category: data['category'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'value': value,
      'unit': unit,
      'category': category,
    };
  }
}

class CalendarEvent {
  final String id;
  final String userId;
  final String type; // 'workout', 'achievement', 'goal'
  final DateTime date;
  final String title;
  final String description;
  final Map<String, dynamic> data;
  final bool isPublic;

  const CalendarEvent({
    required this.id,
    required this.userId,
    required this.type,
    required this.date,
    required this.title,
    required this.description,
    required this.data,
    required this.isPublic,
  });

  factory CalendarEvent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CalendarEvent(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: data['type'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      data: Map<String, dynamic>.from(data['data'] ?? {}),
      isPublic: data['isPublic'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type,
      'date': Timestamp.fromDate(date),
      'title': title,
      'description': description,
      'data': data,
      'isPublic': isPublic,
    };
  }
}
