import 'dart:io';
import 'dart:typed_data';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:image/image.dart' as img;
import '../core/pose_types.dart';

class MlkitPoseExtractor {
  final PoseDetector _detector;

  MlkitPoseExtractor()
      : _detector = PoseDetector(
          options: PoseDetectorOptions(
            mode: PoseDetectionMode.single,
            model: PoseDetectionModel.base,
          ),
        );

  Future<List<PoseLandmarkLite>> extract(img.Image frame) async {
    final bytes = Uint8List.fromList(img.encodeJpg(frame, quality: 90));
    final dir = Directory.systemTemp.createTempSync('mlkit_frames');
    final file = File('${dir.path}/${DateTime.now().microsecondsSinceEpoch}.jpg');
    await file.writeAsBytes(bytes, flush: true);

    final inputImage = InputImage.fromFilePath(file.path);

    final poses = await _detector.processImage(inputImage);
    if (poses.isEmpty) {
      try { if (await file.exists()) await file.delete(); } catch (_) {}
      return const [];
    }

    final pose = poses.first;
    final out = <PoseLandmarkLite>[];
    for (final lm in PoseLandmarkType.values) {
      final p = pose.landmarks[lm];
      if (p == null) continue;
      out.add(PoseLandmarkLite(
        id: lm.index,
        x: p.x / frame.width,
        y: p.y / frame.height,
        score: p.likelihood ?? 0.0,
      ));
    }
    try { if (await file.exists()) await file.delete(); } catch (_) {}
    return out;
  }

  Future<void> close() async {
    await _detector.close();
  }
}


