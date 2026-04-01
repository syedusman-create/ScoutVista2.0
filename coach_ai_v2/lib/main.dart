import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'screens/intro_page.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/auth_service.dart';
import 'services/profile_service.dart';
import 'utils/workout_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Firebase already initialized, continue
    print('Firebase already initialized: $e');
  }
  
  runApp(const CoachAIApp());
}

Future<bool> _checkIfUserHasProfile(String userId) async {
  try {
    final profile = await ProfileService.getProfile(userId);
    if (profile != null) {
      // If profile exists, check if it has the new onboarding fields
      // If it has new fields, user completed onboarding -> go to main app
      // If it doesn't have new fields, it's an old profile -> go to main app too
      final hasNewFields = profile.age != null || profile.height != null || profile.weight != null;
      return true; // Always go to main app if profile exists
    }
    return false; // No profile -> go to onboarding
  } catch (e) {
    print('Error checking profile: $e');
    return false;
  }
}

class CoachAIApp extends StatelessWidget {
  const CoachAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => WorkoutService()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'ScoutVista',
        theme: ThemeData(
          useMaterial3: true,
          textTheme: GoogleFonts.urbanistTextTheme(),
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
        ),
        home: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }
            
            if (snapshot.hasData) {
              return FutureBuilder<bool>(
                future: _checkIfUserHasProfile(snapshot.data!.uid),
                builder: (context, profileSnapshot) {
                  if (profileSnapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  
                  if (profileSnapshot.hasData && profileSnapshot.data == true) {
                    return const MainNavigationScreen();
                  } else {
                    return const OnboardingScreen();
                  }
                },
              );
            } else {
              return const IntroPage();
            }
          },
        ),
      ),
    );
  }
}