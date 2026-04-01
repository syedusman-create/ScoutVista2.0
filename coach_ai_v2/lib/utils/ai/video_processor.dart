import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import '../logger.dart';

class VideoProcessor {
  /// Extract frames from video at regular intervals
  Future<List<img.Image>> extractFrames(File videoFile) async {
    final List<img.Image> frames = [];
    
    try {
      // Initialize video controller
      final controller = VideoPlayerController.file(videoFile);
      await controller.initialize();
      
      final duration = controller.value.duration;
      final totalFrames = (duration.inSeconds * 2).round(); // Extract 2 frames per second
      
      // Extract frames at regular intervals
      for (int i = 0; i < totalFrames; i++) {
        final ms = ((i / max(1, totalFrames - 1)) * duration.inMilliseconds).round();
        final frame = await _getFrameAtMsAsImage(videoFile.path, ms);
        if (frame != null) {
          frames.add(frame);
        }
      }
      
      await controller.dispose();
    } catch (e) {
      Logger.error('Error extracting frames from video', tag: 'VIDEO_PROCESSOR', error: e);
    }
    
    return frames;
  }

  /// Extract frame at a specific timestamp (ms) using real video decoding
  Future<img.Image?> _getFrameAtMsAsImage(String videoPath, int timeMs) async {
    try {
      // Try multiple formats and quality settings
      List<ImageFormat> formats = [ImageFormat.PNG, ImageFormat.JPEG];
      List<int> qualities = [100, 75, 50];
      
      for (final format in formats) {
        for (final quality in qualities) {
          try {
            final bytes = await VideoThumbnail.thumbnailData(
              video: videoPath,
              timeMs: timeMs,
              imageFormat: format,
              quality: quality,
            );
            
            if (bytes == null || bytes.isEmpty) {
              Logger.warning('VideoThumbnail returned empty bytes', tag: 'VIDEO_PROCESSOR', data: {
                'timeMs': timeMs,
                'format': format.toString(),
                'quality': quality,
              });
              continue;
            }
            
            Logger.info('VideoThumbnail extracted frame', tag: 'VIDEO_PROCESSOR', data: {
              'timeMs': timeMs,
              'format': format.toString(),
              'quality': quality,
              'bytesLength': bytes.length,
            });
            
            final image = img.decodeImage(bytes);
            if (image != null) {
              Logger.info('Successfully decoded frame', tag: 'VIDEO_PROCESSOR', data: {
                'timeMs': timeMs,
                'width': image.width,
                'height': image.height,
              });
              return img.copyResize(image, width: 192, height: 192);
            } else {
              Logger.warning('Failed to decode thumbnail bytes', tag: 'VIDEO_PROCESSOR', data: {
                'timeMs': timeMs,
                'format': format.toString(),
                'quality': quality,
                'bytesLength': bytes.length,
              });
            }
          } catch (e) {
            Logger.warning('VideoThumbnail attempt failed', tag: 'VIDEO_PROCESSOR', data: {
              'timeMs': timeMs,
              'format': format.toString(),
              'quality': quality,
              'error': e.toString(),
            });
            continue;
          }
        }
      }
      
      // If all attempts failed, return null
      Logger.error('All VideoThumbnail attempts failed', tag: 'VIDEO_PROCESSOR', data: {
        'timeMs': timeMs,
        'videoPath': videoPath,
      });
      return null;
    } catch (e) {
      Logger.error('Error extracting frame via VideoThumbnail', tag: 'VIDEO_PROCESSOR', error: e);
      return null;
    }
  }

  /// Compress video for upload (optional)
  Future<File?> compressVideo(File videoFile) async {
    // In a real implementation, you would use FFmpeg or similar
    // to compress the video. For now, return the original file.
    return videoFile;
  }

  /// Get video metadata
  Future<Map<String, dynamic>> getVideoMetadata(File videoFile) async {
    try {
      final controller = VideoPlayerController.file(videoFile);
      await controller.initialize();
      
      final metadata = {
        'duration': controller.value.duration.inSeconds,
        'width': controller.value.size.width,
        'height': controller.value.size.height,
        'aspectRatio': controller.value.aspectRatio,
      };
      
      await controller.dispose();
      return metadata;
    } catch (e) {
      Logger.error('Error getting video metadata', tag: 'VIDEO_PROCESSOR', error: e);
      return {};
    }
  }
}
