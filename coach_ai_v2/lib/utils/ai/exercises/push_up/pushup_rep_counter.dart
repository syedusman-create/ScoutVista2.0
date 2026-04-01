import 'dart:math' as math;
import '../../core/pose_types.dart';
import 'pushup_rules.dart';

class PushUpRepCounter {
  int count(List<FrameLandmarks> frames) {
    if (frames.isEmpty) return 0;

    int reps = 0;
    bool inDown = false;

    // Use hips and shoulders to compute torso length for normalization
    List<double> depths = [];

    for (final f in frames) {
      final ls = _get(f.landmarks, 5); // left shoulder
      final rs = _get(f.landmarks, 6); // right shoulder
      final lh = _get(f.landmarks, 11); // left hip
      final rh = _get(f.landmarks, 12); // right hip
      if (ls == null || rs == null || lh == null || rh == null) {
        depths.add(0.0);
        continue;
      }
      final shoulderY = (ls.y + rs.y) / 2;
      final hipY = (lh.y + rh.y) / 2;
      final torsoLen = (hipY - shoulderY).abs() + 1e-6;

      // Chest proxy: average of shoulders
      final chestY = shoulderY;
      // Depth normalized: how far chest goes down relative to hip line
      final depth = (chestY - hipY) / torsoLen; // positive when chest below hips
      depths.add(depth);
    }

    // Simple hysteresis state machine
    for (final d in depths) {
      if (!inDown) {
        if (d > PushUpRules.minDepth + PushUpRules.hysteresis) {
          inDown = true;
        }
      } else {
        if (d < PushUpRules.minLockout - PushUpRules.hysteresis) {
          reps++;
          inDown = false;
        }
      }
    }

    return reps;
  }

  PoseLandmarkLite? _get(List<PoseLandmarkLite> lms, int id) {
    for (final l in lms) {
      if (l.id == id) return l;
    }
    return null;
  }
}


