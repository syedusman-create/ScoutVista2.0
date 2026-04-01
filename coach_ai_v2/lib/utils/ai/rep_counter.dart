import '../exercise.dart';

class RepCounter {
  int _repCount = 0;
  bool _isUpPosition = false;
  double _midpoint = 0.0;
  double _quartile = 0.0;
  List<double> _altitudes = [];

  /// Count repetitions from pose landmarks
  int countReps(List<List<Map<String, dynamic>>> landmarksList, ExerciseType exerciseType) {
    _repCount = 0;
    _isUpPosition = false;
    _altitudes.clear();

    // Extract altitudes from landmarks
    for (final landmarks in landmarksList) {
      if (landmarks.length >= 11) { // Need at least 11 landmarks for chest/hip
        // Use chest position (landmark 11 - left hip) for push-ups
        // This gives better tracking for up/down movement
        final chestAltitude = landmarks[11]['y'] as double; // Left hip landmark
        _altitudes.add(chestAltitude);
      } else if (landmarks.isNotEmpty) {
        // Fallback to first landmark if not enough landmarks
        final altitude = landmarks.first['y'] as double;
        _altitudes.add(altitude);
      }
    }

    if (_altitudes.isEmpty) return 0;

    // Calculate midpoint and quartile for threshold detection
    _calculateThresholds();

    // Count reps based on exercise type
    switch (exerciseType) {
      case ExerciseType.pushUp:
        return _countPushUps();
      case ExerciseType.pullUp:
        return _countPullUps();
      case ExerciseType.squat:
        return _countSquats();
      default:
        return _countGenericReps();
    }
  }

  void _calculateThresholds() {
    if (_altitudes.isEmpty) return;

    final minAltitude = _altitudes.reduce((a, b) => a < b ? a : b);
    final maxAltitude = _altitudes.reduce((a, b) => a > b ? a : b);
    
    _midpoint = (maxAltitude - minAltitude) / 2 + minAltitude;
    _quartile = (maxAltitude - minAltitude) / 4;
  }

  int _countPushUps() {
    // For push-ups, we track the chest/hip position going down and up
    // Start in up position (high altitude)
    _isUpPosition = true;
    
    for (int i = 1; i < _altitudes.length; i++) {
      final currentAltitude = _altitudes[i];
      final previousAltitude = _altitudes[i - 1];
      
      if (_isUpPosition) {
        // Looking for downward movement (going down from up position)
        if (currentAltitude > _midpoint + _quartile) {
          _isUpPosition = false; // Now in down position
        }
      } else {
        // Looking for upward movement (coming back up from down position)
        if (currentAltitude < _midpoint) {
          _repCount++; // Complete rep!
          _isUpPosition = true; // Back to up position
        }
      }
    }
    
    return _repCount;
  }

  int _countPullUps() {
    // For pull-ups, we track the shoulder/elbow position
    for (int i = 0; i < _altitudes.length; i++) {
      final altitude = _altitudes[i];
      
      if (!_isUpPosition) {
        // Looking for upward movement (pulling up)
        if (altitude < _midpoint - _quartile) {
          _repCount++;
          _isUpPosition = true;
        }
      } else {
        // Looking for downward movement (coming back down)
        if (altitude > _midpoint) {
          _isUpPosition = false;
        }
      }
    }
    
    return _repCount;
  }

  int _countSquats() {
    // For squats, we track the hip position going down and up
    for (int i = 0; i < _altitudes.length; i++) {
      final altitude = _altitudes[i];
      
      if (!_isUpPosition) {
        // Looking for downward movement (squatting down)
        if (altitude > _midpoint + _quartile) {
          _repCount++;
          _isUpPosition = true;
        }
      } else {
        // Looking for upward movement (standing up)
        if (altitude < _midpoint) {
          _isUpPosition = false;
        }
      }
    }
    
    return _repCount;
  }

  int _countGenericReps() {
    // Generic rep counting for unknown exercises
    for (int i = 0; i < _altitudes.length; i++) {
      final altitude = _altitudes[i];
      
      if (!_isUpPosition) {
        if (altitude > _midpoint + _quartile) {
          _repCount++;
          _isUpPosition = true;
        }
      } else {
        if (altitude < _midpoint) {
          _isUpPosition = false;
        }
      }
    }
    
    return _repCount;
  }

  /// Reset the counter
  void reset() {
    _repCount = 0;
    _isUpPosition = false;
    _altitudes.clear();
  }

  /// Get current rep count
  int get currentRepCount => _repCount;

  /// Get altitude data for debugging
  List<double> get altitudes => List.from(_altitudes);
}
