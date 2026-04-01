# Coach AI v2

A modern, AI-powered fitness coaching application built with Flutter. Leverages on-device machine learning for real-time pose detection and comprehensive exercise form analysis to deliver personalized training feedback and performance tracking.

## 📋 Table of Contents

- [Features](#features)
- [Project Overview](#project-overview)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Installation & Setup](#installation--setup)
- [Firebase Configuration](#firebase-configuration)
- [Build & Run](#build--run)
- [Architecture](#architecture)
- [Key Technologies](#key-technologies)
- [Development Workflow](#development-workflow)
- [Troubleshooting](#troubleshooting)

## ✨ Features

### Exercise Tracking & Analysis
- **Real-time Pose Detection**: On-device ML model powered by MediaPipe for instant pose recognition
- **Exercise Form Analysis**: Automatic form validation for multiple exercises (Push-ups, Pull-ups, Squats, Shuttle runs, 5K runs)
- **Comprehensive Metrics**: Track reps, duration, form score, and performance trends

### User Management
- **Authentication**: Secure Firebase Authentication with email/password and Google Sign-in
- **User Profiles**: Personalized user data including age, height, weight, and fitness goals
- **Profile Management**: Edit profile information and manage account settings

### Social & Community
- **Social Feed**: Connect with other fitness enthusiasts
- **Challenges**: Participate in fitness challenges and compete with friends
- **Performance Sharing**: Share workout results and achievements

### Advanced Features
- **Workout History Calendar**: Visual calendar tracking all completed workouts
- **Video Upload System**: Upload personal workout videos for review and analysis
- **Notifications**: Real-time push notifications for achievements and reminders
- **Data Privacy Controls**: Comprehensive privacy settings and data management tools
- **Audio Coaching**: Text-to-speech guidance during exercises

### Fitness Programs
- **5K Running Program**: Structured 5K training with pace tracking
- **Shuttle Run & Agility**: Pro agility shuttle drills with timing
- **Challenge Modes**: Various fitness challenges with leaderboards

## 🎯 Project Overview

Coach AI v2 is a sophisticated fitness application designed to:
- Deliver instant, AI-driven form analysis during workouts
- Provide users with detailed performance analytics and progress tracking
- Build a community-driven fitness experience
- Track various exercise types with ML-powered precision
- Store and manage user data securely with Firebase backend

**Target Platforms**: Android, iOS (Flutter cross-platform support)

## 📁 Project Structure

```
coach_ai_v2/
├── lib/                              # Main Flutter application code
│   ├── main.dart                      # Application entry point
│   ├── firebase_options.dart          # Firebase configuration
│   ├── models/                        # Data models
│   │   ├── user_profile.dart
│   │   ├── workout.dart
│   │   ├── exercise.dart
│   │   └── ...
│   ├── screens/                       # UI screens (21+ screens)
│   │   ├── intro_page.dart            # Intro/splash screen
│   │   ├── onboarding_screen.dart     # User onboarding flow
│   │   ├── login_screen.dart          # Authentication
│   │   ├── home_screen.dart           # Dashboard
│   │   ├── exercise_selection_screen.dart
│   │   ├── video_upload_screen.dart   # Video submission
│   │   ├── assessment_screen.dart     # Exercise form assessment
│   │   ├── results_screen.dart        # Performance results
│   │   ├── calendar_screen.dart       # Workout calendar
│   │   ├── challenges_screen.dart     # Challenge participation
│   │   ├── social_feed_screen.dart    # Community feed
│   │   ├── profile_screen.dart        # User profile management
│   │   ├── notification_settings_screen.dart
│   │   ├── privacy_settings_screen.dart
│   │   ├── search_screen.dart
│   │   └── ...
│   ├── services/                      # Business logic & API integration
│   │   ├── auth_service.dart          # Firebase authentication
│   │   ├── profile_service.dart       # User profile management
│   │   ├── challenge_service.dart     # Challenge management
│   │   ├── social_service.dart        # Social features
│   │   ├── notification_service.dart  # Push notifications
│   │   ├── privacy_service.dart       # Data privacy
│   │   ├── search_service.dart        # Search functionality
│   │   ├── data_control_service.dart  # Data control/export
│   │   └── workout_service.dart       # Workout operations
│   ├── utils/                         # Utility functions & helpers
│   ├── widgets/                       # Reusable UI components
│   └── ...
├── assets/
│   ├── icon/                          # App icon assets
│   ├── images/                        # UI images and illustrations
│   └── models/                        # ML Models (TFLite)
│       ├── movenet.tflite             # Pose detection model
│       ├── pullUp.tflite              # Pull-up detection
│       ├── pullUp_v2.tflite           # Pull-up v2 model
│       ├── pushUp.tflite              # Push-up detection
│       ├── pushUp_version2.tflite     # Push-up v2 model
│       └── squat.tflite               # Squat detection
├── android/                           # Android native code
│   ├── app/                           # Android app module
│   │   ├── build.gradle.kts
│   │   └── src/
│   │       └── main/
│   │           └── AndroidManifest.xml
│   ├── build.gradle.kts
│   ├── gradle.properties
│   └── settings.gradle.kts
├── ios/                               # iOS native code
│   ├── Runner/
│   ├── Runner.xcodeproj/
│   └── Runner.xcworkspace/
├── functions/                         # Firebase Cloud Functions
│   ├── index.js                       # Cloud function handlers
│   └── package.json
├── web/                               # Web platform support
├── macos/                             # macOS support
├── windows/                           # Windows support
├── linux/                             # Linux support
├── pubspec.yaml                       # Flutter dependencies
├── analysis_options.yaml              # Dart analysis configuration
├── firebase.json                      # Firebase configuration
├── firestore.rules                    # Firestore security rules
├── storage.rules                      # Cloud Storage security rules
├── firestore.indexes.json             # Firestore composite indexes
└── README.md                          # This file
```

## 📦 Prerequisites

- **Flutter SDK**: ^3.9.2 or higher
- **Dart SDK**: Included with Flutter
- **Android Studio** (for Android development)
  - Android SDK 21 or higher
  - Android NDK (for native compilation)
- **Xcode** (for iOS development)
  - iOS 12.0 or higher
- **Firebase Account**: Set up at [firebase.google.com](https://firebase.google.com)
- **Google Cloud Console**: For API credentials and project setup

## 🚀 Installation & Setup

### Step 1: Clone the Repository

```bash
git clone <repository-url>
cd coach_ai_v2
```

### Step 2: Install Dependencies

```bash
# Get all Flutter packages
flutter pub get

# Update dependencies to latest versions
flutter pub upgrade
```

### Step 3: Generate Code Files

```bash
# Generate necessary code (e.g., for Firebase)
dart run build_runner build
```

### Step 4: Configure Platform-Specific Settings

**Android:**
```bash
cd android
./gradlew build
cd ..
```

**iOS:**
```bash
cd ios
pod install
cd ..
```

## 🔥 Firebase Configuration

### Prerequisites
1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com)
2. Enable the following services:
   - Authentication (Email/Password, Google Sign-in)
   - Cloud Firestore (Database)
   - Cloud Storage (for video uploads)
   - Cloud Functions (for backend logic)

### Android Setup

1. **Google Services Configuration**:
   - Download `google-services.json` from Firebase Console
   - Place it in: `android/app/google-services.json`

2. **Build Configuration**:
   - File: `android/build.gradle.kts`
   - Add Google Services plugin: `id 'com.google.gms.google-services'`

3. **SHA1 Fingerprint** (for Google Sign-in):
   - Generate debug keystore SHA1:
     ```bash
     keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
     ```
   - Add fingerprint to Firebase Console under Authentication > Settings

### iOS Setup

1. **CocoaPods Configuration**:
   ```bash
   cd ios
   pod install --repo-update
   ```

2. **Info.plist Updates**:
   - Modify `ios/Runner/Info.plist` to include Firebase configuration
   - Add URL schemes for Google Sign-in

3. **Build Settings**:
   - Set minimum iOS deployment target to 12.0+
   - Enable push notifications capability

### Firestore Security Rules

Configure database access in `firestore.rules`:
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // User profiles - only owner can access
    match /users/{uid} {
      allow read: if request.auth.uid == uid;
      allow write: if request.auth.uid == uid;
    }
    
    // Workouts - user can read/write their own
    match /workouts/{document=**} {
      allow read: if request.auth.uid == resource.data.userId;
      allow create: if request.auth.uid == request.resource.data.userId;
    }
    
    // ... Additional rules as needed
  }
}
```

### Storage Security Rules

Configure Cloud Storage in `storage.rules`:
```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /videos/{userId}/{document=**} {
      allow read: if request.auth.uid == userId;
      allow write: if request.auth.uid == userId;
    }
  }
}
```

## 🏗️ Build & Run

### Run on Android Device/Emulator

```bash
# List connected devices
flutter devices

# Run the app (debug mode)
flutter run

# Run specific device
flutter run -d <device-id>

# Run in release mode
flutter run --release
```

### Build Android APK

```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# App Bundle (for Play Store)
flutter build appbundle --release
```

### Run on iOS Device/Simulator

```bash
# List available simulators
open -a Simulator

# Run on iOS simulator
flutter run -d all  # or specify device ID

# Run on physical iOS device
flutter run -d <device-id>
```

### Build iOS App

```bash
# Build for iOS
flutter build ios --release

# Create .ipa for App Store
flutter build ipa --release
```

## 🏛️ Architecture

### Architecture Pattern: MVVM + Service Layer

```
UI Layer (Screens)
    ↓
Business Logic Layer (Services)
    ↓
Data Layer (Firestore, Local Storage)
    ↓
External Services (Firebase, ML Kit)
```

### Key Components

1. **Screens**: UI presentation and user interaction
2. **Services**: Business logic encapsulation
   - `AuthService`: Firebase authentication
   - `ProfileService`: User data management
   - `ChallengeService`: Challenge operations
   - `SocialService`: Social features
   - `NotificationService`: Push notifications

3. **Models**: Data structure definitions
4. **Widgets**: Reusable UI components
5. **Utils**: Helper functions and utilities

### Data Flow

1. User interacts with UI (Screen)
2. Screen calls methods from Service layer
3. Services interact with Firebase/ML Kit
4. Data is returned and UI is updated
5. State management via Provider package

### ML Integration

- **Pose Detection**: Google ML Kit Pose Detection
- **Exercise Models**: Custom TFLite models for specific exercises
- **Real-time Analysis**: On-device processing for instant feedback

## 🛠️ Key Technologies

### Frontend Framework
- **Flutter**: Cross-platform UI framework
- **Provider**: State management

### Backend Services
- **Firebase Core**: Base Firebase integration
- **Firebase Auth**: Authentication & authorization
- **Cloud Firestore**: Real-time database
- **Cloud Storage**: Video/media storage
- **Cloud Functions**: Serverless backend logic

### Machine Learning
- **Google ML Kit Pose Detection**: On-device pose estimation
- **TensorFlow Lite**: Custom exercise detection models

### UI/UX Libraries
- **Google Fonts**: Typography
- **Lottie**: Animations
- **Carousel Slider**: Image carousels
- **FL Chart**: Data visualization
- **Table Calendar**: Calendar widget
- **Font Awesome**: Icons

### Media & File Handling
- **Video Player**: Video playback
- **Image Picker**: Photo/video selection
- **File Picker**: File browser
- **Video Thumbnail**: Extract video thumbnails

### Additional Libraries
- **Geolocator**: Location services
- **Flutter Map**: Map display
- **Sensors Plus**: Device sensor access
- **Flutter TTS**: Text-to-speech
- **Fluttertoast**: Toast notifications

### Development Tools
- **Flutter Lints**: Code quality
- **Build Runner**: Code generation
- **Flutter Native Splash**: App splash screen

## 💻 Development Workflow

### Code Organization

1. **Screens**: One file per screen, organized logically
2. **Services**: Singleton services for data operations
3. **Models**: PODO (Plain Old Dart Objects) with serialization
4. **Widgets**: Reusable components in separate files

### Naming Conventions

- **Files**: snake_case.dart (e.g., `home_screen.dart`)
- **Classes**: PascalCase (e.g., `HomeScreen`)
- **Variables/Functions**: camelCase (e.g., `getUserProfile`)
- **Constants**: camelCase or SCREAMING_SNAKE_CASE

### Development Best Practices

1. **Error Handling**: Always wrap Firebase calls in try-catch
2. **Loading States**: Show loading indicators during async operations
3. **Validation**: Validate user input before submission
4. **Security**: Never expose sensitive data in logs
5. **Performance**: Use const constructors and lazy loading

### Running Tests

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage
```

## 🐛 Troubleshooting

### Common Issues & Solutions

#### Firebase Initialization Errors
**Problem**: "Firebase already initialized" error on startup
**Solution**: The main.dart already handles this with a try-catch block. No action needed.

#### Google Sign-in Issues
**Problem**: Google Sign-in fails on Android
**Solution**: 
1. Verify SHA1 fingerprint is added to Firebase Console
2. Run: `keytool -list -v -keystore ~/.android/debug.keystore`
3. Add fingerprint to Authentication > Settings

#### Video Upload Failing
**Problem**: Video upload times out or fails
**Solution**:
1. Check Cloud Storage rules are correctly configured
2. Ensure user UID matches storage path permissions
3. Verify internet connection
4. Check Firebase Storage quota

#### ML Kit/Pose Detection Not Working
**Problem**: Pose detection models fail to load
**Solution**:
1. Verify TFLite models exist in `/assets/models/`
2. Check model file names exactly match code references
3. Ensure pubspec.yaml includes all ML dependencies
4. For Android: Verify GPU delegate setup in build.gradle

#### iOS Build Failures
**Problem**: CocoaPods installation fails
**Solution**:
```bash
cd ios
rm -rf Pods
rm Podfile.lock
pod install --repo-update
cd ..
flutter clean
flutter pub get
flutter run
```

#### Firestore Permissions Denied
**Problem**: Firestore queries fail with permission errors
**Solution**:
1. Check `firestore.rules` for correct user authentication checks
2. Ensure user is authenticated before data access
3. Verify user UID matches data ownership rules
4. Debug with Firebase Console Firestore Rules Simulator

#### App Crashes on Startup
**Problem**: App crashes immediately after launch
**Solution**:
1. Check logcat/Console.app for error details
2. Run: `flutter clean && flutter pub get`
3. Verify Firebase initialization completed successfully
4. Check for any null pointer exceptions in main.dart

### Useful Commands

```bash
# Clean build artifacts
flutter clean

# Verbose output for debugging
flutter run -v

# Check device logs (Android)
adb logcat

# Check device logs (iOS)
log stream --predicate 'process == "Runner"'

# Profile app performance
flutter run --profile

# Enable skia tracing
flutter run --trace-skia

# Run code analyzer
flutter analyze

# Format code
dart format lib/

# Check for style issues
flutter pub outdated
```

### Support & Resources

- **Flutter Docs**: [flutter.dev](https://flutter.dev)
- **Firebase Docs**: [firebase.google.com/docs](https://firebase.google.com/docs)
- **ML Kit Docs**: [ML Kit | Firebase](https://firebase.google.com/docs/ml-kit)
- **Issue Tracker**: Check GitHub issues for known problems

## 📝 Additional Documentation

For detailed setup and configuration guides, refer to:
- [FIREBASE_SETUP_GUIDE.md](FIREBASE_SETUP_GUIDE.md)
- [SHA1_FINGERPRINT_GUIDE.md](SHA1_FINGERPRINT_GUIDE.md)
- [VIDEO_UPLOAD_SYSTEM.md](VIDEO_UPLOAD_SYSTEM.md)
- [LOGGING_IMPROVEMENTS.md](LOGGING_IMPROVEMENTS.md)

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 👥 Contributing

Contributions are welcome! Please follow the code style guidelines and submit pull requests for review.

## 📧 Contact

For questions or support, please reach out to the development team.

---

**Last Updated**: April 2026
**Version**: 1.0.0
