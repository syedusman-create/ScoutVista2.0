import 'dart:math' as math;
class PoseLandmarkLite {
  final int id;
  final double x;
  final double y;
  final double score;

  const PoseLandmarkLite({
    required this.id,
    required this.x,
    required this.y,
    required this.score,
  });
}

class FrameLandmarks {
  final int frameIndex;
  final List<PoseLandmarkLite> landmarks;

  const FrameLandmarks({
    required this.frameIndex,
    required this.landmarks,
  });
}

double distance(double x1, double y1, double x2, double y2) {
  final dx = x2 - x1;
  final dy = y2 - y1;
  return math.sqrt(dx * dx + dy * dy);
}

