import 'dart:math' as math;
import 'package:image/image.dart' as img;

class SignalSmoother {
  final int window;
  const SignalSmoother({this.window = 5});

  List<double> movingAverage(List<double> x) {
    if (x.isEmpty || window <= 1) return List<double>.from(x);
    final w = math.max(1, window);
    final out = List<double>.filled(x.length, 0.0);
    double sum = 0.0;
    int left = 0;
    for (int i = 0; i < x.length; i++) {
      sum += x[i];
      if (i - left + 1 > w) {
        sum -= x[left];
        left++;
      }
      out[i] = sum / (i - left + 1);
    }
    return out;
  }
}

class MotionSignal {
  final List<double> verticalActivity; // per-frame activity along vertical axis
  final List<double> totalActivity; // per-frame total activity
  const MotionSignal({required this.verticalActivity, required this.totalActivity});
}

class MotionExtractor {
  // Computes a vertical motion signal using frame differences and vertical projection
  MotionSignal extract(List<img.Image> frames) {
    if (frames.isEmpty) return const MotionSignal(verticalActivity: [], totalActivity: []);
    final int height = frames.first.height;
    final int width = frames.first.width;
    final List<double> perFrameTotal = [];
    final List<double> perFrameVertical = [];

    img.Image? prev;
    for (final f in frames) {
      if (prev == null) {
        perFrameTotal.add(0.0);
        perFrameVertical.add(0.0);
        prev = f;
        continue;
      }

      double total = 0.0;
      // vertical projection of absolute differences
      final List<double> proj = List<double>.filled(height, 0.0);
      for (int y = 0; y < height; y++) {
        double rowSum = 0.0;
        for (int x = 0; x < width; x++) {
          final p1 = prev.getPixel(x, y);
          final p2 = f.getPixel(x, y);
          final dr = (p1.r - p2.r).abs();
          final dg = (p1.g - p2.g).abs();
          final db = (p1.b - p2.b).abs();
          final d = (dr + dg + db) / 3.0;
          rowSum += d;
          total += d;
        }
        proj[y] = rowSum / width;
      }
      // compute center of mass of vertical motion
      double num = 0.0;
      double den = 0.0;
      for (int y = 0; y < height; y++) {
        final v = proj[y];
        num += v * y;
        den += v + 1e-6;
      }
      final centerY = num / den; // 0..height-1
      perFrameTotal.add(total / (width * height));
      perFrameVertical.add(centerY / math.max(1, height - 1)); // normalize 0..1
      prev = f;
    }

    return MotionSignal(verticalActivity: perFrameVertical, totalActivity: perFrameTotal);
  }
}

class PeakCounter {
  // Counts cycles in a 1D signal using hysteresis thresholds
  int countCycles(List<double> s, {double low=0.45, double high=0.55}) {
    if (s.isEmpty) return 0;
    bool inDown = false;
    int reps = 0;
    for (final v in s) {
      if (!inDown) {
        if (v >= high) inDown = true;
      } else {
        if (v <= low) {
          reps++;
          inDown = false;
        }
      }
    }
    return reps;
  }
}

class HeuristicResult {
  final int reps;
  final List<double> perFrameScores; // 0..100
  const HeuristicResult({required this.reps, required this.perFrameScores});
}


