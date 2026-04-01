class PushUpRules {
  // Normalized thresholds (0..1) and angles (degrees)
  static const double minDepth = 0.18; // chest/hips descent relative to torso length
  static const double minLockout = -0.05; // near top relative to neutral
  static const double hysteresis = 0.04; // avoid jitter

  static const double maxHipSagDegrees = 25.0; // trunk angle deviation
  static const double maxHipPikeDegrees = 35.0;
  static const double maxShoulderSway = 0.12; // lateral sway normalized

  // Form scoring weights (sum to 1)
  static const double wDepth = 0.45;
  static const double wControl = 0.20;
  static const double wTrunk = 0.20;
  static const double wSymmetry = 0.15;
}


