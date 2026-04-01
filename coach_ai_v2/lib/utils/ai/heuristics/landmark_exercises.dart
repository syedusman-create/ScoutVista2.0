import 'dart:math' as math;
import '../core/pose_types.dart';
import '../../logger.dart';

// Rep detection event for visualization
class RepDetectionEvent {
  final int frameIndex;
  final double timestamp;
  final String phase; // 'down', 'up', 'rep_completed'
  final double value; // The measured value (depth, height, etc.)
  final double threshold; // The threshold that was crossed
  
  RepDetectionEvent({
    required this.frameIndex,
    required this.timestamp,
    required this.phase,
    required this.value,
    required this.threshold,
  });
  
  Map<String, dynamic> toJson() => {
    'frameIndex': frameIndex,
    'timestamp': timestamp,
    'phase': phase,
    'value': value,
    'threshold': threshold,
  };
}

class AngleUtils {
  static double angle(PoseLandmarkLite a, PoseLandmarkLite b, PoseLandmarkLite c) {
    final abx = a.x - b.x; final aby = a.y - b.y;
    final cbx = c.x - b.x; final cby = c.y - b.y;
    final dot = abx * cbx + aby * cby;
    final mag1 = math.sqrt(abx * abx + aby * aby) + 1e-6;
    final mag2 = math.sqrt(cbx * cbx + cby * cby) + 1e-6;
    double cosang = (dot / (mag1 * mag2)).clamp(-1.0, 1.0);
    return math.acos(cosang) * 180.0 / math.pi;
  }
}

class LandmarkPushUp {
  static List<RepDetectionEvent> _detectionEvents = [];
  
  static int countReps(List<List<PoseLandmarkLite>> frames) {
    _detectionEvents.clear();
    int reps = 0;
    
    Logger.info('PUSHUP COUNTING STARTED - SIMPLE METHOD', tag: 'REP_COUNTER', 
      data: {'totalFrames': frames.length});
    
    if (frames.isEmpty) {
      Logger.error('NO FRAMES PROVIDED', tag: 'REP_COUNTER');
      return 0;
    }
    
    // Simple approach: count every significant angle change
    List<double> angles = [];
    int validFrameCount = 0;
    
    for (int i = 0; i < frames.length; i++) {
      final lms = frames[i];
      final le = _get(lms, 13); final re = _get(lms, 14);  // elbows
      
      if (le == null || re == null) continue;
      
      // Use elbow Y position as a simple proxy for push-up movement
      final elbowY = (le.y + re.y) / 2;
      angles.add(elbowY);
      validFrameCount++;
      
      if (validFrameCount <= 3) {
        Logger.info('ELBOW Y POSITION', tag: 'REP_COUNTER', 
          data: {'frame': i, 'elbowY': elbowY.toStringAsFixed(3)});
      }
    }
    
    Logger.info('ELBOW POSITIONS COLLECTED', tag: 'REP_COUNTER', 
      data: {'validFrames': validFrameCount, 'totalFrames': frames.length});
    
    if (angles.length < 10) {
      Logger.warning('TOO FEW VALID FRAMES', tag: 'REP_COUNTER');
      return 0;
    }
    
    // Count direction changes (up/down movement)
    bool goingDown = false;
    double lastY = angles[0];
    int directionChanges = 0;
    
    for (int i = 1; i < angles.length; i++) {
      final currentY = angles[i];
      final diff = currentY - lastY;
      
      if (diff.abs() > 0.01) { // Significant movement
        if (diff > 0 && !goingDown) {
          // Started going down (elbow Y increasing)
          goingDown = true;
          directionChanges++;
        } else if (diff < 0 && goingDown) {
          // Started going up (elbow Y decreasing)
          goingDown = false;
          directionChanges++;
          
          // Count a rep on up movement
          reps++;
          _detectionEvents.add(RepDetectionEvent(
            frameIndex: i,
            timestamp: (i / frames.length) * 100,
            phase: 'rep_completed',
            value: currentY,
            threshold: 0,
          ));
          
          Logger.info('REP DETECTED - ELBOW UP MOVEMENT', tag: 'REP_COUNTER', 
            data: {'frame': i, 'repCount': reps, 'elbowY': currentY.toStringAsFixed(3)});
        }
        lastY = currentY;
      }
    }
    
    Logger.info('SIMPLE REP COUNTING COMPLETED', tag: 'REP_COUNTER', 
      data: {'totalReps': reps, 'directionChanges': directionChanges, 'detectionEvents': _detectionEvents.length});
    
    return reps;
  }
  
  static List<RepDetectionEvent> getDetectionEvents() => List.from(_detectionEvents);

  static List<double> frameScores(List<List<PoseLandmarkLite>> frames) {
    final scores = <double>[];
    for (final lms in frames) {
      final ls = _get(lms, 11); final rs = _get(lms, 12);  // shoulders
      final le = _get(lms, 13); final re = _get(lms, 14);  // elbows
      final lw = _get(lms, 15); final rw = _get(lms, 16);  // wrists
      final lh = _get(lms, 23); final rh = _get(lms, 24);  // hips
      
      if (ls == null || rs == null || le == null || re == null || 
          lw == null || rw == null || lh == null || rh == null) {
        scores.add(50.0);
        continue;
      }
      
      // Calculate elbow angles
      final leftElbowAngle = AngleUtils.angle(ls, le, lw);
      final rightElbowAngle = AngleUtils.angle(rs, re, rw);
      final avgElbowAngle = (leftElbowAngle + rightElbowAngle) / 2;
      
      // Score based on elbow angle (good range: 90-180 degrees)
      double elbowScore = 100.0;
      if (avgElbowAngle < 90) {
        elbowScore = 60.0; // Too bent
      } else if (avgElbowAngle > 180) {
        elbowScore = 70.0; // Hyperextended
      } else {
        // Best score for angles between 90-180
        elbowScore = 80.0 + (20.0 * (avgElbowAngle - 90) / 90);
      }
      
      scores.add(elbowScore.clamp(40.0, 100.0));
    }
    return scores;
  }

  static PoseLandmarkLite? _get(List<PoseLandmarkLite> lms, int id) {
    for (final l in lms) { if (l.id == id) return l; } return null;
  }
}

class LandmarkPullUp {
  static List<RepDetectionEvent> _detectionEvents = [];
  
  static int countReps(List<List<PoseLandmarkLite>> frames) {
    _detectionEvents.clear();
    int reps = 0;
    
    Logger.info('PULLUP COUNTING STARTED - HEAD-TO-WRIST METHOD', tag: 'REP_COUNTER', 
      data: {'totalFrames': frames.length});
    
    if (frames.isEmpty) {
      Logger.error('NO FRAMES PROVIDED', tag: 'REP_COUNTER');
      return 0;
    }
    
    // Track head position relative to wrists and elbows
    List<double> headToWristRatios = [];
    List<double> headToElbowRatios = [];
    int validFrameCount = 0;
    
    for (int i = 0; i < frames.length; i++) {
      final lms = frames[i];
      final nose = _get(lms, 0);  // NOSE (head reference)
      final lw = _get(lms, 15); final rw = _get(lms, 16);  // wrists
      final le = _get(lms, 13); final re = _get(lms, 14);  // elbows
      
      if (nose == null || lw == null || rw == null || le == null || re == null) {
        if (validFrameCount < 3) {
          Logger.info('PULLUP: Missing landmarks', tag: 'REP_COUNTER', 
            data: {'frame': i, 'nose': nose != null, 'wrists': lw != null && rw != null, 'elbows': le != null && re != null});
        }
        continue;
      }
      
      final headY = nose.y;
      final wristY = (lw.y + rw.y) / 2;
      final elbowY = (le.y + re.y) / 2;
      
      // Calculate relative positions (negative when head is above)
      final headToWrist = headY - wristY;  // negative when head above wrists
      final headToElbow = headY - elbowY;  // negative when head above elbows
      
      headToWristRatios.add(headToWrist);
      headToElbowRatios.add(headToElbow);
      validFrameCount++;
      
      if (validFrameCount <= 3) {
        Logger.info('PULLUP HEAD POSITION', tag: 'REP_COUNTER', 
          data: {
            'frame': i, 
            'headToWrist': headToWrist.toStringAsFixed(3),
            'headToElbow': headToElbow.toStringAsFixed(3),
            'headAboveWrists': headToWrist < 0,
            'headAboveElbows': headToElbow < 0
          });
      }
    }
    
    Logger.info('PULLUP POSITIONS COLLECTED', tag: 'REP_COUNTER', 
      data: {'validFrames': validFrameCount, 'totalFrames': frames.length});
    
    if (headToWristRatios.length < 10) {
      Logger.warning('TOO FEW VALID FRAMES', tag: 'REP_COUNTER');
      return 0;
    }
    
    // Count pull-up cycles: head above wrists → head below elbows
    bool headWasAboveWrists = false;
    
    for (int i = 0; i < headToWristRatios.length; i++) {
      final headToWrist = headToWristRatios[i];
      final headToElbow = headToElbowRatios[i];
      
      // Check if head goes above wrists (up position)
      if (headToWrist < -0.02 && !headWasAboveWrists) { // Head clearly above wrists
        headWasAboveWrists = true;
        _detectionEvents.add(RepDetectionEvent(
          frameIndex: i,
          timestamp: (i / headToWristRatios.length) * 100,
          phase: 'up',
          value: headToWrist,
          threshold: -0.02,
        ));
        Logger.info('PULLUP UP PHASE - HEAD ABOVE WRISTS', tag: 'REP_COUNTER', 
          data: {'frame': i, 'headToWrist': headToWrist.toStringAsFixed(3)});
      }
      
      // Check if head goes below elbows (down position) - complete rep
      if (headToElbow > 0.02 && headWasAboveWrists) { // Head clearly below elbows
        headWasAboveWrists = false;
        reps++;
        _detectionEvents.add(RepDetectionEvent(
          frameIndex: i,
          timestamp: (i / headToWristRatios.length) * 100,
          phase: 'rep_completed',
          value: headToElbow,
          threshold: 0.02,
        ));
        Logger.info('PULLUP REP COMPLETED - HEAD BELOW ELBOWS', tag: 'REP_COUNTER', 
          data: {'frame': i, 'repCount': reps, 'headToElbow': headToElbow.toStringAsFixed(3)});
      }
    }
    
    Logger.info('PULLUP REP COUNTING COMPLETED', tag: 'REP_COUNTER', 
      data: {'totalReps': reps, 'detectionEvents': _detectionEvents.length});
    
    return reps;
  }
  
  static List<RepDetectionEvent> getDetectionEvents() => List.from(_detectionEvents);
  
  static List<double> frameScores(List<List<PoseLandmarkLite>> frames) {
    final out = <double>[];
    for (final lms in frames) {
      final lw = _get(lms, 15); final rw = _get(lms, 16);  // wrists (LEFT_WRIST, RIGHT_WRIST)
      final ls = _get(lms, 11); final rs = _get(lms, 12);  // shoulders (LEFT_SHOULDER, RIGHT_SHOULDER)
      if (lw == null || rw == null || ls == null || rs == null) { out.add(50.0); continue; }
      final wristY = (lw.y + rw.y) / 2; final shoulderY = (ls.y + rs.y) / 2;
      final lift = (shoulderY - wristY).clamp(0.0, 1.0);
      out.add(40.0 + 60.0 * lift);
    }
    return out;
  }
  static PoseLandmarkLite? _get(List<PoseLandmarkLite> lms, int id) { for (final l in lms) { if (l.id == id) return l; } return null; }
}

class LandmarkSquat {
  static List<RepDetectionEvent> _detectionEvents = [];
  
  static int countReps(List<List<PoseLandmarkLite>> frames) {
    _detectionEvents.clear();
    int reps = 0;
    
    Logger.info('🔥 SQUAT COUNTING STARTED - KNEE ANGLE METHOD 🔥', tag: 'REP_COUNTER', 
      data: {'totalFrames': frames.length});
    
    // Debug: Check if we have any frames with landmarks
    int framesWithLandmarks = 0;
    for (final frameData in frames) {
      if (frameData.isNotEmpty) framesWithLandmarks++;
    }
    Logger.info('🔍 SQUAT DEBUG: Frames analysis', tag: 'REP_COUNTER', 
      data: {'totalFrames': frames.length, 'framesWithLandmarks': framesWithLandmarks});
    
    if (frames.isEmpty) {
      Logger.error('NO FRAMES PROVIDED', tag: 'REP_COUNTER');
      return 0;
    }
    
    // Track knee angles throughout the movement
    List<double> kneeAngles = [];
    int validFrameCount = 0;
    
    for (int i = 0; i < frames.length; i++) {
      final lms = frames[i];
      final lh = _get(lms, 23); final rh = _get(lms, 24);  // hips
      final lk = _get(lms, 25); final rk = _get(lms, 26);  // knees
      final la = _get(lms, 29); final ra = _get(lms, 30);  // ankles (LEFT_ANKLE=29, RIGHT_ANKLE=30)
      
      if (lh == null || rh == null || lk == null || rk == null) {
        if (validFrameCount < 3) {
          Logger.info('SQUAT: Missing core landmarks', tag: 'REP_COUNTER', 
            data: {'frame': i, 'hips': lh != null && rh != null, 'knees': lk != null && rk != null});
        }
        continue;
      }
      
      // If ankles are missing, use a simplified hip-knee angle approach
      if (la == null || ra == null) {
        if (validFrameCount < 3) {
          Logger.info('SQUAT: Missing ankles, using hip-knee method', tag: 'REP_COUNTER', 
            data: {'frame': i, 'ankles': la != null && ra != null});
        }
        
        // Use hip-knee vertical distance as proxy for squat depth
        final hipY = (lh.y + rh.y) / 2;
        final kneeY = (lk.y + rk.y) / 2;
        final hipKneeDistance = hipY - kneeY; // positive when hips below knees
        
        // Convert to approximate knee angle (rough estimation)
        final approximateKneeAngle = 180.0 - (hipKneeDistance * 300).clamp(0.0, 90.0);
        kneeAngles.add(approximateKneeAngle);
        validFrameCount++;
        
        if (validFrameCount <= 3) {
          Logger.info('SQUAT APPROX KNEE ANGLE', tag: 'REP_COUNTER', 
            data: {
              'frame': i, 
              'hipKneeDistance': hipKneeDistance.toStringAsFixed(3),
              'approxKneeAngle': approximateKneeAngle.toStringAsFixed(1),
              'isDeepSquat': approximateKneeAngle < 90
            });
        }
        continue;
      }
      
      // Calculate knee angles (hip-knee-ankle)
      final leftKneeAngle = AngleUtils.angle(lh, lk, la);
      final rightKneeAngle = AngleUtils.angle(rh, rk, ra);
      final avgKneeAngle = (leftKneeAngle + rightKneeAngle) / 2;
      
      kneeAngles.add(avgKneeAngle);
      validFrameCount++;
      
      if (validFrameCount <= 3) {
        Logger.info('SQUAT KNEE ANGLE', tag: 'REP_COUNTER', 
          data: {
            'frame': i, 
            'leftKnee': leftKneeAngle.toStringAsFixed(1),
            'rightKnee': rightKneeAngle.toStringAsFixed(1),
            'avgKnee': avgKneeAngle.toStringAsFixed(1),
            'isDeepSquat': avgKneeAngle < 90
          });
      }
    }
    
    Logger.info('SQUAT ANGLES COLLECTED', tag: 'REP_COUNTER', 
      data: {'validFrames': validFrameCount, 'totalFrames': frames.length});
    
    if (kneeAngles.length < 10) {
      Logger.warning('TOO FEW VALID FRAMES', tag: 'REP_COUNTER');
      return 0;
    }
    
    // Count squat cycles: knee angle goes below 90° → back above 160°
    bool inDeepSquat = false;
    
    for (int i = 0; i < kneeAngles.length; i++) {
      final kneeAngle = kneeAngles[i];
      
      // Check if entering deep squat (knee angle < 90°)
      if (kneeAngle < 90.0 && !inDeepSquat) {
        inDeepSquat = true;
        _detectionEvents.add(RepDetectionEvent(
          frameIndex: i,
          timestamp: (i / kneeAngles.length) * 100,
          phase: 'down',
          value: kneeAngle,
          threshold: 90.0,
        ));
        Logger.info('SQUAT DOWN PHASE - KNEE BENT', tag: 'REP_COUNTER', 
          data: {'frame': i, 'kneeAngle': kneeAngle.toStringAsFixed(1)});
      }
      
      // Check if returning to standing (knee angle > 160°) - complete rep
      if (kneeAngle > 160.0 && inDeepSquat) {
        inDeepSquat = false;
        reps++;
        _detectionEvents.add(RepDetectionEvent(
          frameIndex: i,
          timestamp: (i / kneeAngles.length) * 100,
          phase: 'rep_completed',
          value: kneeAngle,
          threshold: 160.0,
        ));
        Logger.info('SQUAT REP COMPLETED - KNEE STRAIGHT', tag: 'REP_COUNTER', 
          data: {'frame': i, 'repCount': reps, 'kneeAngle': kneeAngle.toStringAsFixed(1)});
      }
    }
    
    Logger.info('SQUAT REP COUNTING COMPLETED', tag: 'REP_COUNTER', 
      data: {'totalReps': reps, 'detectionEvents': _detectionEvents.length});
    
    return reps;
  }
  
  static List<RepDetectionEvent> getDetectionEvents() => List.from(_detectionEvents);
  
  static List<double> frameScores(List<List<PoseLandmarkLite>> frames) {
    final out = <double>[];
    for (final lms in frames) {
      final lh = _get(lms, 23); final rh = _get(lms, 24);  // hips
      final lk = _get(lms, 25); final rk = _get(lms, 26);  // knees
      final la = _get(lms, 29); final ra = _get(lms, 30);  // ankles (LEFT_ANKLE=29, RIGHT_ANKLE=30)
      
      if (lh == null || rh == null || lk == null || rk == null || la == null || ra == null) {
        out.add(50.0);
        continue;
      }
      
      // Calculate knee angles for form scoring
      final leftKneeAngle = AngleUtils.angle(lh, lk, la);
      final rightKneeAngle = AngleUtils.angle(rh, rk, ra);
      final avgKneeAngle = (leftKneeAngle + rightKneeAngle) / 2;
      
      // Score based on knee angle (good squat range: 70-180 degrees)
      double kneeScore = 100.0;
      if (avgKneeAngle < 70) {
        kneeScore = 60.0; // Too deep, may indicate poor form
      } else if (avgKneeAngle > 180) {
        kneeScore = 70.0; // Hyperextended
      } else {
        // Best score for angles between 70-180
        kneeScore = 70.0 + (30.0 * (180 - avgKneeAngle) / 110);
      }
      
      out.add(kneeScore.clamp(40.0, 100.0));
    }
    return out;
  }
  static PoseLandmarkLite? _get(List<PoseLandmarkLite> lms, int id) { for (final l in lms) { if (l.id == id) return l; } return null; }
}
