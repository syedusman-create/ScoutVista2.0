import 'dart:math' as math;
import '../../core/pose_types.dart';
import 'pushup_rules.dart';

class PushUpFormScorer {
  // Returns per-frame scores 0..100
  List<double> score(List<FrameLandmarks> frames) {
    final scores = <double>[];
    for (final f in frames) {
      scores.add(_scoreFrame(f));
    }
    return scores;
  }

  double _scoreFrame(FrameLandmarks f) {
    final ls = _get(f.landmarks, 5);
    final rs = _get(f.landmarks, 6);
    final lh = _get(f.landmarks, 11);
    final rh = _get(f.landmarks, 12);
    if (ls == null || rs == null || lh == null || rh == null) return 50.0;

    final shoulderY = (ls.y + rs.y) / 2;
    final hipY = (lh.y + rh.y) / 2;
    final torsoLen = (hipY - shoulderY).abs() + 1e-6;

    // Depth component (down is positive)
    final depth = (shoulderY - hipY) / torsoLen;
    final depthScore = _toScore(depth, PushUpRules.minDepth, PushUpRules.minDepth * 1.8);

    // Trunk alignment (approx: vertical difference between shoulders and hips)
    final trunkAngle = (depth * 90.0).abs();
    final trunkScore = _angleScore(trunkAngle, PushUpRules.maxHipSagDegrees, PushUpRules.maxHipPikeDegrees);

    // Symmetry (shoulder horizontal spread)
    final shoulderSym = (ls.x - rs.x).abs();
    final symScore = _symmetryScore(shoulderSym, PushUpRules.maxShoulderSway);

    // Control proxy (clamped depth change)
    final controlScore = 80.0; // placeholder; refined when temporal smoothing added

    final total =
        depthScore * PushUpRules.wDepth +
        controlScore * PushUpRules.wControl +
        trunkScore * PushUpRules.wTrunk +
        symScore * PushUpRules.wSymmetry;

    return total.clamp(0.0, 100.0);
  }

  double _toScore(double v, double minGood, double ideal) {
    if (v <= 0) return 10.0;
    if (v >= ideal) return 100.0;
    if (v >= minGood) {
      final t = (v - minGood) / (ideal - minGood);
      return 60.0 + 40.0 * t;
    }
    final t = (v / minGood).clamp(0.0, 1.0);
    return 20.0 + 40.0 * t;
  }

  double _angleScore(double ang, double maxSag, double maxPike) {
    final limit = math.max(maxSag, maxPike);
    if (ang <= 5.0) return 100.0;
    if (ang >= limit) return 20.0;
    final t = (limit - ang) / (limit - 5.0);
    return 20.0 + 80.0 * t;
  }

  double _symmetryScore(double sway, double maxSway) {
    if (sway <= maxSway * 0.3) return 100.0;
    if (sway >= maxSway) return 30.0;
    final t = (maxSway - sway) / (maxSway * 0.7);
    return 30.0 + 70.0 * t;
  }

  PoseLandmarkLite? _get(List<PoseLandmarkLite> lms, int id) {
    for (final l in lms) {
      if (l.id == id) return l;
    }
    return null;
  }
}


