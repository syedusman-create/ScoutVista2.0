import 'dart:math' as math;

import '../core/pose_types.dart';
import '../../logger.dart';

class ShuttleCalibration {
  final double leftBoundary;
  final double rightBoundary;
  final double hysteresis;

  const ShuttleCalibration({
    required this.leftBoundary,
    required this.rightBoundary,
    this.hysteresis = 0.05,
  });
}

class ShuttleAnalysisResult {
  final int shuttles;
  final double speedScore;
  final double turnScore;
  final double straightnessScore;
  final double totalScore;

  const ShuttleAnalysisResult({
    required this.shuttles,
    required this.speedScore,
    required this.turnScore,
    required this.straightnessScore,
    required this.totalScore,
  });
}

class LandmarkShuttle {
  static ShuttleCalibration calibrate(List<List<PoseLandmarkLite>> frames) {
    double minX = 1.0;
    double maxX = 0.0;
    for (final lms in frames) {
      final torsoX = _torsoX(lms);
      if (torsoX == null) continue;
      minX = math.min(minX, torsoX);
      maxX = math.max(maxX, torsoX);
    }
    if (minX > maxX) {
      minX = 0.2;
      maxX = 0.8;
    }
    Logger.info('Shuttle calibration', tag: 'SHUTTLE', data: {'left': minX, 'right': maxX});
    return ShuttleCalibration(leftBoundary: minX, rightBoundary: maxX);
  }

  static ShuttleAnalysisResult analyze(
    List<List<PoseLandmarkLite>> frames,
    ShuttleCalibration calib,
    double videoDurationSec,
  ) {
    if (frames.isEmpty) {
      return const ShuttleAnalysisResult(
        shuttles: 0,
        speedScore: 20,
        turnScore: 20,
        straightnessScore: 20,
        totalScore: 20,
      );
    }

    final positions = <double>[];
    for (final lms in frames) {
      final x = _torsoX(lms);
      if (x != null) positions.add(x);
    }
    if (positions.length < 3) {
      return const ShuttleAnalysisResult(
        shuttles: 0,
        speedScore: 20,
        turnScore: 20,
        straightnessScore: 20,
        totalScore: 20,
      );
    }

    bool goingRight = positions.first < (calib.leftBoundary + calib.rightBoundary) / 2;
    int shuttles = 0;
    final rightThresh = calib.rightBoundary - calib.hysteresis;
    final leftThresh = calib.leftBoundary + calib.hysteresis;

    final turnaroundIndices = <int>[];
    for (int i = 1; i < positions.length; i++) {
      final x = positions[i];
      if (!goingRight && x > rightThresh) {
        goingRight = true;
        shuttles++;
        turnaroundIndices.add(i);
      } else if (goingRight && x < leftThresh) {
        goingRight = false;
        shuttles++;
        turnaroundIndices.add(i);
      }
    }

    // Speed: average horizontal speed magnitude
    final dt = videoDurationSec / positions.length;
    final speeds = <double>[];
    for (int i = 1; i < positions.length; i++) {
      speeds.add(((positions[i] - positions[i - 1]).abs()) / dt);
    }
    final avgSpeed = speeds.isEmpty ? 0.0 : speeds.reduce((a, b) => a + b) / speeds.length;
    final speedVar = speeds.isEmpty
        ? 0.0
        : speeds.map((v) => (v - avgSpeed) * (v - avgSpeed)).reduce((a, b) => a + b) / speeds.length;
    // Normalize: higher speed and lower variance → 100; baseline scale factors are heuristic
    double speedScore = 70.0 * _sigmoid(avgSpeed * 2.5) + 30.0 * (1.0 / (1.0 + speedVar * 10.0));
    speedScore = speedScore.clamp(20.0, 100.0);

    // Turn efficiency: time spent near boundaries (index windows around turnarounds)
    double turnPenalty = 0.0;
    for (final idx in turnaroundIndices) {
      final window = 3; // small temporal window
      int linger = 0;
      for (int j = math.max(0, idx - window); j < math.min(positions.length, idx + window + 1); j++) {
        final x = positions[j];
        if (x > rightThresh || x < leftThresh) linger++;
      }
      turnPenalty += linger.toDouble();
    }
    // More lingering → lower score
    double turnScore = 100.0 - (turnPenalty * 3.0);
    turnScore = turnScore.clamp(20.0, 100.0);

    // Straightness: variance away from midline
    final mid = (calib.leftBoundary + calib.rightBoundary) / 2.0;
    final lateralVar = positions.map((x) => (x - mid) * (x - mid)).reduce((a, b) => a + b) / positions.length;
    double straightnessScore = 100.0 * (1.0 / (1.0 + lateralVar * 50.0));
    straightnessScore = straightnessScore.clamp(20.0, 100.0);

    final total = (0.6 * speedScore) + (0.3 * turnScore) + (0.1 * straightnessScore);
    final totalScore = total.clamp(20.0, 100.0);

    Logger.info('Shuttle analysis done', tag: 'SHUTTLE', data: {
      'shuttles': shuttles,
      'speedScore': speedScore,
      'turnScore': turnScore,
      'straightnessScore': straightnessScore,
      'totalScore': totalScore,
    });

    return ShuttleAnalysisResult(
      shuttles: shuttles,
      speedScore: speedScore,
      turnScore: turnScore,
      straightnessScore: straightnessScore,
      totalScore: totalScore,
    );
  }

  static double? _torsoX(List<PoseLandmarkLite> lms) {
    final ls = _get(lms, 11); // LEFT_SHOULDER
    final rs = _get(lms, 12); // RIGHT_SHOULDER
    final lh = _get(lms, 23); // LEFT_HIP
    final rh = _get(lms, 24); // RIGHT_HIP
    if (ls == null || rs == null || lh == null || rh == null) return null;
    final hipX = (lh.x + rh.x) / 2.0;
    final shoulderX = (ls.x + rs.x) / 2.0;
    return (hipX + shoulderX) / 2.0;
  }

  static PoseLandmarkLite? _get(List<PoseLandmarkLite> lms, int id) {
    for (final l in lms) {
      if (l.id == id) return l;
    }
    return null;
  }

  static double _sigmoid(double x) {
    return 1.0 / (1.0 + math.exp(-x));
  }
}


