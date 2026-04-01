enum ExerciseType {
  pushUp,
  pullUp,
  squat,
  shuttleProAgility,
  run5k,
}

class Exercise {
  final String id;
  final String name;
  final String description;
  final String imagePath;
  final String gifPath;
  final ExerciseType type;
  final String poseModelPath;
  final String formCorrectnessModelPath;
  final List<String> instructions;
  final int targetReps;
  final Duration targetDuration;

  const Exercise({
    required this.id,
    required this.name,
    required this.description,
    required this.imagePath,
    required this.gifPath,
    required this.type,
    required this.poseModelPath,
    required this.formCorrectnessModelPath,
    required this.instructions,
    this.targetReps = 10,
    this.targetDuration = const Duration(minutes: 5),
  });

  static const List<Exercise> exercises = [
    Exercise(
      id: 'pushup',
      name: 'Push Up',
      description: 'Classic upper body exercise targeting chest, shoulders, and triceps',
      imagePath: 'assets/images/push_up.png',
      gifPath: 'assets/images/push_up.gif',
      type: ExerciseType.pushUp,
      poseModelPath: 'assets/models/movenet.tflite',
      formCorrectnessModelPath: 'assets/models/pushUp_version2.tflite',
      instructions: [
        'Start in a plank position with hands shoulder-width apart',
        'Lower your body until chest nearly touches the floor',
        'Push back up to starting position',
        'Keep your body straight throughout the movement',
        'Breathe in on the way down, out on the way up',
      ],
      targetReps: 15,
    ),
    Exercise(
      id: 'pullup',
      name: 'Pull Up',
      description: 'Upper body exercise targeting back, biceps, and shoulders',
      imagePath: 'assets/images/pull_up.png',
      gifPath: 'assets/images/pull_up.gif',
      type: ExerciseType.pullUp,
      poseModelPath: 'assets/models/movenet.tflite',
      formCorrectnessModelPath: 'assets/models/pullUp_v2.tflite',
      instructions: [
        'Hang from a bar with hands slightly wider than shoulder-width',
        'Pull your body up until chin clears the bar',
        'Lower yourself down with control',
        'Keep your core engaged throughout',
        'Avoid swinging or using momentum',
      ],
      targetReps: 8,
    ),
    Exercise(
      id: 'squat',
      name: 'Squat',
      description: 'Lower body exercise targeting quadriceps, glutes, and hamstrings',
      imagePath: 'assets/images/squat.jpg',
      gifPath: 'assets/images/squat.gif',
      type: ExerciseType.squat,
      poseModelPath: 'assets/models/movenet.tflite',
      formCorrectnessModelPath: 'assets/models/squat.tflite',
      instructions: [
        'Stand with feet shoulder-width apart',
        'Lower your body as if sitting back into a chair',
        'Keep your chest up and knees behind toes',
        'Go down until thighs are parallel to floor',
        'Push through heels to return to starting position',
      ],
      targetReps: 20,
    ),
    Exercise(
      id: 'shuttle_5_10_5',
      name: '5-10-5 Pro Agility',
      description: 'Agility shuttle with rapid direction changes (5y-10y-5y).',
      imagePath: 'assets/images/shuttle_run.jpg',
      gifPath: 'assets/images/shuttle_run.jpg',
      type: ExerciseType.shuttleProAgility,
      poseModelPath: '',
      formCorrectnessModelPath: '',
      instructions: [
        'Setup three cones in a straight line, 5 yards (4.57 m) apart.',
        'Start straddling the middle cone, hand on the line.',
        'On start: sprint 5y to one side, touch line; 10y to far side, touch; 5y back to middle.',
        'Keep a low center of mass and plant foot outside the line on turns.',
        'Complete as fast as possible with full line touches.',
      ],
      targetReps: 1,
      targetDuration: Duration(minutes: 1),
    ),
    Exercise(
      id: 'run_5k',
      name: '5 km Run',
      description: 'Endurance run over a fixed distance of 5.00 km.',
      imagePath: 'assets/images/endurance_run.jpg',
      gifPath: 'assets/images/endurance_run.jpg',
      type: ExerciseType.run5k,
      poseModelPath: '',
      formCorrectnessModelPath: '',
      instructions: [
        'Warm up 5–10 minutes before starting.',
        'Run a measured 5.00 km route or 12.5 laps on a 400 m track.',
        'Pace evenly; avoid starting too fast.',
        'Hydrate and ensure safe environment.',
        'Stop the timer immediately at 5.00 km; note splits if possible.',
      ],
      targetReps: 0,
      targetDuration: Duration(minutes: 30),
    ),
  ];

  static Exercise? getExerciseById(String id) {
    try {
      return exercises.firstWhere((exercise) => exercise.id == id);
    } catch (e) {
      return null;
    }
  }

  static Exercise? getExerciseByType(ExerciseType type) {
    try {
      return exercises.firstWhere((exercise) => exercise.type == type);
    } catch (e) {
      return null;
    }
  }
}

class WorkoutSession {
  final String id;
  final String userId;
  final Exercise exercise;
  final DateTime startTime;
  final DateTime? endTime;
  final List<RepData> reps;
  final int totalReps;
  final double averageFormScore;
  final Duration duration;
  final bool isCompleted;

  WorkoutSession({
    required this.id,
    required this.userId,
    required this.exercise,
    required this.startTime,
    this.endTime,
    required this.reps,
    required this.totalReps,
    required this.averageFormScore,
    required this.duration,
    this.isCompleted = false,
  });

  WorkoutSession copyWith({
    String? id,
    String? userId,
    Exercise? exercise,
    DateTime? startTime,
    DateTime? endTime,
    List<RepData>? reps,
    int? totalReps,
    double? averageFormScore,
    Duration? duration,
    bool? isCompleted,
  }) {
    return WorkoutSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      exercise: exercise ?? this.exercise,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      reps: reps ?? this.reps,
      totalReps: totalReps ?? this.totalReps,
      averageFormScore: averageFormScore ?? this.averageFormScore,
      duration: duration ?? this.duration,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class RepData {
  final int repNumber;
  final DateTime timestamp;
  final double formScore;
  final List<PoseLandmark> landmarks;
  final String feedback;

  RepData({
    required this.repNumber,
    required this.timestamp,
    required this.formScore,
    required this.landmarks,
    required this.feedback,
  });
}

class PoseLandmark {
  final int id;
  final double x;
  final double y;
  final double z;
  final double visibility;
  final double presence;

  PoseLandmark({
    required this.id,
    required this.x,
    required this.y,
    required this.z,
    required this.visibility,
    required this.presence,
  });

  factory PoseLandmark.fromList(List<double> data) {
    return PoseLandmark(
      id: data[0].toInt(),
      x: data[1],
      y: data[2],
      z: data[3],
      visibility: data[4],
      presence: data[5],
    );
  }

  List<double> toList() {
    return [id.toDouble(), x, y, z, visibility, presence];
  }
}

class FormAnalysisResult {
  final double score;
  final String feedback;
  final List<String> corrections;
  final bool isGoodForm;
  int repCount;

  FormAnalysisResult({
    required this.score,
    required this.feedback,
    required this.corrections,
    required this.isGoodForm,
    this.repCount = 0,
  });
}
