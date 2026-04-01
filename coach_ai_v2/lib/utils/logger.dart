import 'dart:developer' as developer;

enum LogLevel {
  debug,
  info,
  warning,
  error,
  critical,
}

class Logger {
  static const String _tag = 'CoachAI';
  
  static void debug(String message, {String? tag, Map<String, dynamic>? data}) {
    _log(LogLevel.debug, message, tag: tag, data: data);
  }
  
  static void info(String message, {String? tag, Map<String, dynamic>? data}) {
    _log(LogLevel.info, message, tag: tag, data: data);
  }
  
  static void warning(String message, {String? tag, Map<String, dynamic>? data}) {
    _log(LogLevel.warning, message, tag: tag, data: data);
  }
  
  static void error(String message, {String? tag, Map<String, dynamic>? data, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.error, message, tag: tag, data: data, error: error, stackTrace: stackTrace);
  }
  
  static void critical(String message, {String? tag, Map<String, dynamic>? data, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.critical, message, tag: tag, data: data, error: error, stackTrace: stackTrace);
  }
  
  static void _log(
    LogLevel level,
    String message, {
    String? tag,
    Map<String, dynamic>? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final timestamp = DateTime.now().toIso8601String();
    final levelStr = level.name.toUpperCase();
    final tagStr = tag != null ? '[$tag]' : '';
    final dataStr = data != null ? ' | Data: $data' : '';
    final errorStr = error != null ? ' | Error: $error' : '';
    
    final logMessage = '[$timestamp] $levelStr $_tag$tagStr: $message$dataStr$errorStr';
    
    // Use developer.log for better debugging
    developer.log(
      logMessage,
      name: _tag,
      level: _getLogLevel(level),
      error: error,
      stackTrace: stackTrace,
    );
    
    // Also print to console for immediate visibility
    print(logMessage);
  }
  
  static int _getLogLevel(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 500;
      case LogLevel.info:
        return 800;
      case LogLevel.warning:
        return 900;
      case LogLevel.error:
        return 1000;
      case LogLevel.critical:
        return 1200;
    }
  }
}

// Specialized loggers for different components
class VideoLogger {
  static void frameExtraction(int frameCount, int totalFrames) {
    Logger.info(
      'Frame extraction progress',
      tag: 'VIDEO',
      data: {
        'current': frameCount,
        'total': totalFrames,
        'percentage': ((frameCount / totalFrames) * 100).toStringAsFixed(1),
      },
    );
  }
  
  static void frameProcessing(int frameIndex, int totalFrames, bool success, {String? error}) {
    if (success) {
      Logger.debug(
        'Frame processed successfully',
        tag: 'VIDEO',
        data: {
          'frame': frameIndex,
          'total': totalFrames,
        },
      );
    } else {
      Logger.error(
        'Frame processing failed',
        tag: 'VIDEO',
        data: {
          'frame': frameIndex,
          'total': totalFrames,
        },
        error: error,
      );
    }
  }
  
  static void videoUpload(String videoPath, bool success, {String? error}) {
    if (success) {
      Logger.info(
        'Video uploaded successfully',
        tag: 'VIDEO',
        data: {'path': videoPath},
      );
    } else {
      Logger.error(
        'Video upload failed',
        tag: 'VIDEO',
        data: {'path': videoPath},
        error: error,
      );
    }
  }
}

class AILogger {
  static void poseDetection(int frameIndex, int landmarksCount, bool success, {String? error}) {
    if (success) {
      Logger.debug(
        'Pose detection completed',
        tag: 'AI',
        data: {
          'frame': frameIndex,
          'landmarks': landmarksCount,
        },
      );
    } else {
      Logger.error(
        'Pose detection failed',
        tag: 'AI',
        data: {'frame': frameIndex},
        error: error,
      );
    }
  }
  
  static void formAnalysis(int frameIndex, double score, bool success, {String? error}) {
    if (success) {
      Logger.debug(
        'Form analysis completed',
        tag: 'AI',
        data: {
          'frame': frameIndex,
          'score': score,
        },
      );
    } else {
      Logger.error(
        'Form analysis failed',
        tag: 'AI',
        data: {'frame': frameIndex},
        error: error,
      );
    }
  }
  
  static void repCounting(int totalReps, String exerciseType) {
    Logger.info(
      'Rep counting completed',
      tag: 'AI',
      data: {
        'reps': totalReps,
        'exercise': exerciseType,
      },
    );
  }
}

class FirebaseLogger {
  static void storageUpload(String path, bool success, {String? error}) {
    if (success) {
      Logger.info(
        'Firebase Storage upload successful',
        tag: 'FIREBASE',
        data: {'path': path},
      );
    } else {
      Logger.error(
        'Firebase Storage upload failed',
        tag: 'FIREBASE',
        data: {'path': path},
        error: error,
      );
    }
  }
  
  static void firestoreWrite(String collection, String document, bool success, {String? error}) {
    if (success) {
      Logger.info(
        'Firestore write successful',
        tag: 'FIREBASE',
        data: {
          'collection': collection,
          'document': document,
        },
      );
    } else {
      Logger.error(
        'Firestore write failed',
        tag: 'FIREBASE',
        data: {
          'collection': collection,
          'document': document,
        },
        error: error,
      );
    }
  }
}
