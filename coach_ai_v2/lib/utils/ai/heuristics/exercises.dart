import 'dart:math' as math;
import 'package:image/image.dart' as img;
import 'core.dart';

abstract class ExerciseHeuristic {
  HeuristicResult analyze(List<img.Image> frames);
}

class PushUpHeuristic implements ExerciseHeuristic {
  final MotionExtractor motion = MotionExtractor();
  final SignalSmoother smooth = const SignalSmoother(window: 7);
  final PeakCounter peak = PeakCounter();

  @override
  HeuristicResult analyze(List<img.Image> frames) {
    final m = motion.extract(frames);
    final v = smooth.movingAverage(m.verticalActivity);
    final reps = peak.countCycles(v, low: 0.46, high: 0.54);
    final scores = _scoreFrames(v, m.totalActivity);
    return HeuristicResult(reps: reps, perFrameScores: scores);
  }

  List<double> _scoreFrames(List<double> vertical, List<double> total) {
    if (vertical.isEmpty) return const [];
    final out = <double>[];
    final double varV = _variance(vertical);
    final double varT = _variance(total);
    for (int i = 0; i < vertical.length; i++) {
      final control = 100.0 * (1.0 - math.min(1.0, varT * 2.0));
      final range = 100.0 * math.min(1.0, varV * 3.0);
      final score = 0.6 * range + 0.4 * control;
      out.add(score.clamp(20.0, 100.0));
    }
    return out;
  }
}

class PullUpHeuristic implements ExerciseHeuristic {
  final MotionExtractor motion = MotionExtractor();
  final SignalSmoother smooth = const SignalSmoother(window: 9);
  final PeakCounter peak = PeakCounter();

  @override
  HeuristicResult analyze(List<img.Image> frames) {
    final m = motion.extract(frames);
    // Inverse vertical for pull-ups: up is smaller Y
    final inv = m.verticalActivity.map((e) => 1.0 - e).toList();
    final v = smooth.movingAverage(inv);
    final reps = peak.countCycles(v, low: 0.46, high: 0.54);
    final scores = _scoreFrames(v, m.totalActivity);
    return HeuristicResult(reps: reps, perFrameScores: scores);
  }

  List<double> _scoreFrames(List<double> vertical, List<double> total) {
    final out = <double>[];
    final varV = _variance(vertical);
    final varT = _variance(total);
    for (int i = 0; i < vertical.length; i++) {
      final rom = 100.0 * math.min(1.0, varV * 3.0);
      final control = 100.0 * (1.0 - math.min(1.0, varT * 2.0));
      out.add((0.7 * rom + 0.3 * control).clamp(20.0, 100.0));
    }
    return out;
  }
}

class SquatHeuristic implements ExerciseHeuristic {
  final MotionExtractor motion = MotionExtractor();
  final SignalSmoother smooth = const SignalSmoother(window: 9);
  final PeakCounter peak = PeakCounter();

  @override
  HeuristicResult analyze(List<img.Image> frames) {
    final m = motion.extract(frames);
    final v = smooth.movingAverage(m.verticalActivity);
    final reps = peak.countCycles(v, low: 0.47, high: 0.57);
    final scores = _scoreFrames(v, m.totalActivity);
    return HeuristicResult(reps: reps, perFrameScores: scores);
  }

  List<double> _scoreFrames(List<double> vertical, List<double> total) {
    final out = <double>[];
    final varV = _variance(vertical);
    final varT = _variance(total);
    for (int i = 0; i < vertical.length; i++) {
      final depth = 100.0 * math.min(1.0, varV * 2.5);
      final stability = 100.0 * (1.0 - math.min(1.0, varT * 2.0));
      out.add((0.6 * depth + 0.4 * stability).clamp(20.0, 100.0));
    }
    return out;
  }
}

double _variance(List<double> s) {
  if (s.isEmpty) return 0.0;
  final mean = s.reduce((a, b) => a + b) / s.length;
  double acc = 0.0;
  for (final v in s) {
    final d = v - mean;
    acc += d * d;
  }
  return acc / s.length;
}


