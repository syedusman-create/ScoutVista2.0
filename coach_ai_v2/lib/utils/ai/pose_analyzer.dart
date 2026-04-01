import 'dart:typed_data';
// Removed TensorFlow Lite

import '../exercise.dart';
import '../logger.dart';

class PoseDetector {
  Future<void> initialize() async {}
  Future<List<PoseLandmark>> detectPose(Uint8List imageBytes) async {
    throw UnimplementedError('Pose detection removed with TFLite.');
  }
  void dispose() {}
}

// Helpers removed with TFLite

class FormAnalyzer {
  bool _isInitialized = false;
  String? _currentModelPath;

  Future<void> initialize(String modelPath) async {
    if (_isInitialized && _currentModelPath == modelPath) return;

    try {
      _currentModelPath = modelPath;
      _isInitialized = true;
    } catch (e) {
      throw Exception('Failed to initialize form analyzer: $e');
    }
  }

  Future<FormAnalysisResult> analyzeForm(
    List<PoseLandmark> landmarks,
    ExerciseType exerciseType,
  ) async {
    if (!_isInitialized) {
      throw Exception('Form analyzer not initialized');
    }

    try {
      // TFLite removed: fallback to basic score heuristic using visibility
      final visible = landmarks.where((l) => l.visibility > 0.5).length;
      final ratio = landmarks.isEmpty ? 0.0 : (visible / landmarks.length);
      final formScore = ratio; // 0..1
      final result = _processOutput(formScore, exerciseType);
      result.repCount = 0;
      return result;
    } catch (e) {
      // Do not return mock analysis in production path
      Logger.error('Form analysis failed', tag: 'FORM_ANALYZER', error: e);
      rethrow;
    }
  }

  List _prepareInputForShape(List<PoseLandmark> landmarks, List<int> inputShape, bool isQuantized) {
    // If model expects [1,17,3], provide MoveNet keypoints as (y,x,score)
    if (inputShape.length == 3 && inputShape[0] == 1 && inputShape[1] == 17 && inputShape[2] == 3) {
      final points = List.generate(17, (i) => [0.0, 0.0, 0.0]);
      final count = landmarks.length < 17 ? landmarks.length : 17;
      for (int i = 0; i < count; i++) {
        // Landmarks y,x already in 0..1 from MoveNet output; visibility used as score
        points[i][0] = landmarks[i].y;
        points[i][1] = landmarks[i].x;
        points[i][2] = landmarks[i].visibility;
      }
      if (isQuantized) {
        final q = points.map((row) => row.map((e) => (e * 255).round()).toList()).toList();
        return [ q ];
      }
      return [ points ];
    }

    // Generic fallback: flatten normalized landmarks [x,y,visibility,presence] to expected shape
    final normalized = _normalizeLandmarks(landmarks);
    final flat = <double>[];
    for (final l in normalized) {
      flat.addAll([l.x, l.y, l.visibility, l.presence]);
    }

    // Determine expected length from shape
    int expectedLength;
    if (inputShape.length == 2) {
      expectedLength = inputShape[1];
    } else if (inputShape.length == 3) {
      // Treat as [1,1,N]
      expectedLength = inputShape[2];
    } else if (inputShape.length == 1) {
      expectedLength = inputShape[0];
    } else {
      expectedLength = flat.length;
    }

    final adjusted = List<double>.filled(expectedLength, 0.0);
    final copyLen = flat.length < expectedLength ? flat.length : expectedLength;
    for (int i = 0; i < copyLen; i++) {
      adjusted[i] = flat[i];
    }

    if (inputShape.length == 2) {
      return [isQuantized ? adjusted.map((e) => (e * 255).round()).toList() : adjusted];
    } else if (inputShape.length == 3) {
      final vec = isQuantized ? adjusted.map((e) => (e * 255).round()).toList() : adjusted;
      return [ [ vec ] ];
    } else if (inputShape.length == 1) {
      return isQuantized ? adjusted.map((e) => (e * 255).round()).toList() : adjusted;
    } else {
      return [adjusted];
    }
  }

  List<PoseLandmark> _normalizeLandmarks(List<PoseLandmark> landmarks) {
    if (landmarks.isEmpty) return landmarks;
    
    // Find bounding box
    double minX = landmarks.map((l) => l.x).reduce((a, b) => a < b ? a : b);
    double maxX = landmarks.map((l) => l.x).reduce((a, b) => a > b ? a : b);
    double minY = landmarks.map((l) => l.y).reduce((a, b) => a < b ? a : b);
    double maxY = landmarks.map((l) => l.y).reduce((a, b) => a > b ? a : b);
    
    // Avoid division by zero
    double rangeX = maxX - minX;
    double rangeY = maxY - minY;
    if (rangeX == 0) rangeX = 1.0;
    if (rangeY == 0) rangeY = 1.0;
    
    // Normalize to [0, 1] range
    return landmarks.map((landmark) => PoseLandmark(
      id: landmark.id,
      x: (landmark.x - minX) / rangeX,
      y: (landmark.y - minY) / rangeY,
      z: landmark.z,
      visibility: landmark.visibility,
      presence: landmark.presence,
    )).toList();
  }

  FormAnalysisResult _processOutput(double score, ExerciseType exerciseType) {
    final normalizedScore = (score * 100).clamp(0, 100);
    final isGoodForm = normalizedScore >= 70;
    
    String feedback;
    List<String> corrections = [];

    switch (exerciseType) {
      case ExerciseType.pushUp:
        if (normalizedScore < 70) {
          feedback = "Keep your body straight and maintain proper form";
          corrections.addAll([
            "Keep your core tight",
            "Maintain straight line from head to heels",
            "Lower chest to ground level",
            "Push up with full arm extension"
          ]);
        } else {
          feedback = "Excellent form! Keep it up!";
        }
        break;
        
      case ExerciseType.pullUp:
        if (normalizedScore < 70) {
          feedback = "Focus on controlled movement and full range of motion";
          corrections.addAll([
            "Start from full hang position",
            "Pull until chin clears the bar",
            "Lower with control",
            "Avoid swinging or kipping"
          ]);
        } else {
          feedback = "Perfect pull-up form!";
        }
        break;
        
      case ExerciseType.squat:
        if (normalizedScore < 70) {
          feedback = "Maintain proper squat depth and posture";
          corrections.addAll([
            "Keep chest up and core engaged",
            "Go down until thighs parallel to floor",
            "Keep knees behind toes",
            "Push through heels to stand up"
          ]);
        } else {
          feedback = "Great squat technique!";
        }
        break;
      case ExerciseType.shuttleProAgility:
      case ExerciseType.run5k:
        feedback = "Timing-based test. Form scoring not applicable";
        corrections.addAll([
          "Follow on-screen instructions",
          "Ensure accurate distance setup",
        ]);
        break;
    }

    return FormAnalysisResult(
      score: normalizedScore.toDouble(),
      feedback: feedback,
      corrections: corrections,
      isGoodForm: isGoodForm,
      repCount: 0, // Will be set by caller
    );
  }

  // Removed _estimateRepCountFromLandmarks - the TFLite model should handle rep counting

  // Mock form analysis removed

  void dispose() {
    _isInitialized = false;
    _currentModelPath = null;
  }
}

class RepCounter {
  final ExerciseType exerciseType;
  List<PoseLandmark> _previousLandmarks = [];
  int _currentReps = 0;
  bool _isInDownPosition = false;

  RepCounter({required this.exerciseType});

  RepCountResult countReps(List<PoseLandmark> landmarks, double formScore) {
    if (landmarks.isEmpty) {
      return RepCountResult(
        currentReps: _currentReps,
        isNewRep: false,
        phase: RepPhase.unknown,
        confidence: 0.0,
      );
    }

    final phase = _detectPhase(landmarks);
    final isNewRep = _detectNewRep(phase);
    
    if (isNewRep) {
      _currentReps++;
    }

    _previousLandmarks = landmarks;

    return RepCountResult(
      currentReps: _currentReps,
      isNewRep: isNewRep,
      phase: phase,
      confidence: _calculateConfidence(landmarks),
    );
  }

  RepPhase _detectPhase(List<PoseLandmark> landmarks) {
    switch (exerciseType) {
      case ExerciseType.pushUp:
        return _detectPushUpPhase(landmarks);
      case ExerciseType.pullUp:
        return _detectPullUpPhase(landmarks);
      case ExerciseType.squat:
        return _detectSquatPhase(landmarks);
      case ExerciseType.shuttleProAgility:
      case ExerciseType.run5k:
        return RepPhase.unknown;
    }
  }

  RepPhase _detectPushUpPhase(List<PoseLandmark> landmarks) {
    // Simplified phase detection based on shoulder and hip positions
    if (landmarks.length < 11) return RepPhase.unknown;
    
    final leftShoulder = landmarks[5];
    final rightShoulder = landmarks[6];
    final leftHip = landmarks[11];
    final rightHip = landmarks[12];
    
    final shoulderY = (leftShoulder.y + rightShoulder.y) / 2;
    final hipY = (leftHip.y + rightHip.y) / 2;
    
    if (shoulderY > hipY + 0.1) {
      return RepPhase.down;
    } else if (shoulderY < hipY - 0.1) {
      return RepPhase.up;
    } else {
      return RepPhase.middle;
    }
  }

  RepPhase _detectPullUpPhase(List<PoseLandmark> landmarks) {
    // Simplified phase detection based on wrist and shoulder positions
    if (landmarks.length < 9) return RepPhase.unknown;
    
    final leftWrist = landmarks[9];
    final rightWrist = landmarks[10];
    final leftShoulder = landmarks[5];
    final rightShoulder = landmarks[6];
    
    final wristY = (leftWrist.y + rightWrist.y) / 2;
    final shoulderY = (leftShoulder.y + rightShoulder.y) / 2;
    
    if (wristY < shoulderY - 0.1) {
      return RepPhase.up;
    } else if (wristY > shoulderY + 0.1) {
      return RepPhase.down;
    } else {
      return RepPhase.middle;
    }
  }

  RepPhase _detectSquatPhase(List<PoseLandmark> landmarks) {
    // Simplified phase detection based on hip and knee positions
    if (landmarks.length < 13) return RepPhase.unknown;
    
    final leftHip = landmarks[11];
    final rightHip = landmarks[12];
    final leftKnee = landmarks[13];
    final rightKnee = landmarks[14];
    
    final hipY = (leftHip.y + rightHip.y) / 2;
    final kneeY = (leftKnee.y + rightKnee.y) / 2;
    
    if (hipY > kneeY + 0.1) {
      return RepPhase.down;
    } else if (hipY < kneeY - 0.1) {
      return RepPhase.up;
    } else {
      return RepPhase.middle;
    }
  }

  bool _detectNewRep(RepPhase currentPhase) {
    if (_previousLandmarks.isEmpty) return false;
    
    // Detect transition from down to up as a new rep
    if (_isInDownPosition && currentPhase == RepPhase.up) {
      _isInDownPosition = false;
      return true;
    }
    
    if (currentPhase == RepPhase.down) {
      _isInDownPosition = true;
    }
    
    return false;
  }

  double _calculateConfidence(List<PoseLandmark> landmarks) {
    // Calculate confidence based on landmark visibility
    double totalVisibility = 0.0;
    int validLandmarks = 0;
    
    for (final landmark in landmarks) {
      if (landmark.visibility > 0.5) {
        totalVisibility += landmark.visibility;
        validLandmarks++;
      }
    }
    
    return validLandmarks > 0 ? totalVisibility / validLandmarks : 0.0;
  }

  void reset() {
    _currentReps = 0;
    _isInDownPosition = false;
    _previousLandmarks.clear();
  }
}

class RepCountResult {
  final int currentReps;
  final bool isNewRep;
  final RepPhase phase;
  final double confidence;

  RepCountResult({
    required this.currentReps,
    required this.isNewRep,
    required this.phase,
    required this.confidence,
  });
}

enum RepPhase {
  up,
  down,
  middle,
  unknown,
}
