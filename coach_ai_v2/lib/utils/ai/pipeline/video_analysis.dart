import 'package:coach_ai_v2/utils/ai/core/pose_types.dart';

class VideoAnalysisResult {
  final int totalReps;
  final double formScoreAverage;
  final List<Map<String, dynamic>> perFrame;

  const VideoAnalysisResult({
    required this.totalReps,
    required this.formScoreAverage,
    required this.perFrame,
  });
}

typedef RepCounterFn = int Function(List<FrameLandmarks> frames);
typedef FormScorerFn = List<double> Function(List<FrameLandmarks> frames);

class VideoAnalysisPipeline {
  final RepCounterFn repCounter;
  final FormScorerFn formScorer;

  const VideoAnalysisPipeline({
    required this.repCounter,
    required this.formScorer,
  });

  VideoAnalysisResult run(List<FrameLandmarks> frames) {
    final reps = repCounter(frames);
    final scores = formScorer(frames);
    final avg = scores.isEmpty ? 0.0 : (scores.reduce((a, b) => a + b) / scores.length);

    final perFrame = <Map<String, dynamic>>[];
    for (int i = 0; i < frames.length; i++) {
      perFrame.add({
        'frame': frames[i].frameIndex,
        'formScore': i < scores.length ? scores[i] : avg,
      });
    }

    return VideoAnalysisResult(
      totalReps: reps,
      formScoreAverage: avg,
      perFrame: perFrame,
    );
  }
}


