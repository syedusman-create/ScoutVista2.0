import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'exercise.dart';
import 'ai/pose_analyzer.dart';

class WorkoutService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  WorkoutSession? _currentSession;
  PoseDetector? _poseDetector;
  FormAnalyzer? _formAnalyzer;
  RepCounter? _repCounter;
  
  bool _isWorkoutActive = false;
  bool _isProcessing = false;
  String _currentFeedback = '';
  double _currentFormScore = 0.0;
  int _currentReps = 0;
  RepPhase _currentPhase = RepPhase.unknown;
  
  // Getters
  WorkoutSession? get currentSession => _currentSession;
  bool get isWorkoutActive => _isWorkoutActive;
  bool get isProcessing => _isProcessing;
  String get currentFeedback => _currentFeedback;
  double get currentFormScore => _currentFormScore;
  int get currentReps => _currentReps;
  RepPhase get currentPhase => _currentPhase;

  Future<void> initialize() async {
    try {
      _poseDetector = PoseDetector();
      _formAnalyzer = FormAnalyzer();
      
      await _poseDetector!.initialize();
    } catch (e) {
      throw Exception('Failed to initialize workout service: $e');
    }
  }

  Future<void> startWorkout(Exercise exercise) async {
    if (_isWorkoutActive) {
      throw Exception('Workout already in progress');
    }

    try {
      // Initialize form analyzer with exercise-specific model
      await _formAnalyzer!.initialize(exercise.formCorrectnessModelPath);
      
      // Create new workout session
      _currentSession = WorkoutSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: _auth.currentUser?.uid ?? 'anonymous',
        exercise: exercise,
        startTime: DateTime.now(),
        reps: [],
        totalReps: 0,
        averageFormScore: 0.0,
        duration: Duration.zero,
      );

      // Initialize rep counter
      _repCounter = RepCounter(exerciseType: exercise.type);
      
      _isWorkoutActive = true;
      _currentReps = 0;
      _currentFormScore = 0.0;
      _currentFeedback = 'Get ready to start!';
      
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to start workout: $e');
    }
  }

  Future<void> processFrame(Uint8List imageBytes) async {
    if (!_isWorkoutActive || _isProcessing) return;

    _isProcessing = true;
    notifyListeners();

    try {
      // Detect pose
      final landmarks = await _poseDetector!.detectPose(imageBytes);
      
      if (landmarks.isNotEmpty && _currentSession != null) {
        // Analyze form
        final formResult = await _formAnalyzer!.analyzeForm(
          landmarks,
          _currentSession!.exercise.type,
        );
        
        // Count reps
        final repResult = _repCounter!.countReps(landmarks, formResult.score);
        
        // Update current state
        _currentFormScore = formResult.score;
        _currentFeedback = formResult.feedback;
        _currentReps = repResult.currentReps;
        _currentPhase = repResult.phase;
        
        // Add rep data if new rep detected
        if (repResult.isNewRep) {
          final repData = RepData(
            repNumber: _currentReps,
            timestamp: DateTime.now(),
            formScore: formResult.score,
            landmarks: landmarks,
            feedback: formResult.feedback,
          );
          
          _currentSession = _currentSession!.copyWith(
            reps: [..._currentSession!.reps, repData],
            totalReps: _currentReps,
            averageFormScore: _calculateAverageFormScore(),
          );
        }
        
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error processing frame: $e');
      }
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  double _calculateAverageFormScore() {
    if (_currentSession == null || _currentSession!.reps.isEmpty) {
      return 0.0;
    }
    
    final totalScore = _currentSession!.reps.fold<double>(
      0.0,
      (total, rep) => total + rep.formScore,
    );
    
    return totalScore / _currentSession!.reps.length;
  }

  Future<void> pauseWorkout() async {
    if (!_isWorkoutActive) return;
    
    // Camera service removed - video upload system implemented
    notifyListeners();
  }

  Future<void> resumeWorkout() async {
    if (!_isWorkoutActive) return;
    
    // Camera service removed - video upload system implemented
    notifyListeners();
  }

  Future<void> endWorkout() async {
    if (!_isWorkoutActive || _currentSession == null) return;

    try {
      // Finalize session
      final endTime = DateTime.now();
      final duration = endTime.difference(_currentSession!.startTime);
      
      _currentSession = _currentSession!.copyWith(
        endTime: endTime,
        duration: duration,
        isCompleted: true,
        averageFormScore: _calculateAverageFormScore(),
      );

      // Save to Firestore
      await _saveWorkoutSession(_currentSession!);
      
      // Reset state
      _isWorkoutActive = false;
      _currentReps = 0;
      _currentFormScore = 0.0;
      _currentFeedback = '';
      _currentPhase = RepPhase.unknown;
      
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to end workout: $e');
    }
  }

  Future<void> _saveWorkoutSession(WorkoutSession session) async {
    try {
      final sessionData = {
        'id': session.id,
        'userId': session.userId,
        'exerciseId': session.exercise.id,
        'exerciseName': session.exercise.name,
        'startTime': session.startTime,
        'endTime': session.endTime,
        'duration': session.duration.inMilliseconds,
        'totalReps': session.totalReps,
        'averageFormScore': session.averageFormScore,
        'isCompleted': session.isCompleted,
        'reps': session.reps.map((rep) => {
          'repNumber': rep.repNumber,
          'timestamp': rep.timestamp,
          'formScore': rep.formScore,
          'feedback': rep.feedback,
        }).toList(),
      };

      await _firestore
          .collection('workout_sessions')
          .doc(session.id)
          .set(sessionData);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving workout session: $e');
      }
      rethrow;
    }
  }

  Future<List<WorkoutSession>> getWorkoutHistory() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return [];

      final querySnapshot = await _firestore
          .collection('workout_sessions')
          .where('userId', isEqualTo: userId)
          .orderBy('startTime', descending: true)
          .limit(50)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        final exercise = Exercise.getExerciseById(data['exerciseId']);
        if (exercise == null) return null;

        return WorkoutSession(
          id: data['id'],
          userId: data['userId'],
          exercise: exercise,
          startTime: (data['startTime'] as Timestamp).toDate(),
          endTime: data['endTime'] != null 
              ? (data['endTime'] as Timestamp).toDate() 
              : null,
          duration: Duration(milliseconds: data['duration']),
          totalReps: data['totalReps'],
          averageFormScore: data['averageFormScore']?.toDouble() ?? 0.0,
          isCompleted: data['isCompleted'] ?? false,
          reps: (data['reps'] as List<dynamic>?)?.map((repData) => RepData(
            repNumber: repData['repNumber'],
            timestamp: (repData['timestamp'] as Timestamp).toDate(),
            formScore: repData['formScore']?.toDouble() ?? 0.0,
            landmarks: [], // Landmarks not stored for history
            feedback: repData['feedback'] ?? '',
          )).toList() ?? [],
        );
      }).where((session) => session != null).cast<WorkoutSession>().toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching workout history: $e');
      }
      return [];
    }
  }

  @override
  Future<void> dispose() async {
    // Camera service removed - video upload system implemented
    _poseDetector?.dispose();
    _formAnalyzer?.dispose();
    super.dispose();
  }
}
