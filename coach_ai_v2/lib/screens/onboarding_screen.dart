import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';
import '../services/profile_service.dart';
import '../utils/logger.dart';
import 'main_navigation_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _bioController = TextEditingController();
  
  String _selectedSport = 'General Fitness';
  String _selectedGender = 'Prefer not to say';
  String _selectedFitnessLevel = 'Beginner';
  String _selectedGoal = 'General Health';
  String _selectedUnits = 'Metric';
  
  bool _isLoading = false;

  final List<String> _sports = [
    'General Fitness',
    'Weightlifting',
    'Running',
    'Swimming',
    'Cycling',
    'Yoga',
    'Pilates',
    'CrossFit',
    'Martial Arts',
    'Dancing',
    'Basketball',
    'Football',
    'Tennis',
    'Other',
  ];

  final List<String> _genders = [
    'Male',
    'Female',
    'Non-binary',
    'Prefer not to say',
  ];

  final List<String> _fitnessLevels = [
    'Beginner',
    'Intermediate',
    'Advanced',
    'Professional',
  ];

  final List<String> _goals = [
    'General Health',
    'Weight Loss',
    'Muscle Gain',
    'Endurance',
    'Strength',
    'Flexibility',
    'Competition',
    'Rehabilitation',
  ];

  final List<String> _units = [
    'Metric',
    'Imperial',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Convert height and weight to metric if needed
      double? heightInCm;
      double? weightInKg;
      
      if (_heightController.text.isNotEmpty) {
        final height = double.parse(_heightController.text);
        heightInCm = _selectedUnits == 'Metric' ? height : height * 30.48; // feet to cm
      }
      
      if (_weightController.text.isNotEmpty) {
        final weight = double.parse(_weightController.text);
        weightInKg = _selectedUnits == 'Metric' ? weight : weight * 0.453592; // lbs to kg
      }

      // Create user profile with onboarding data
      final profile = UserProfile(
        uid: user.uid,
        displayName: _nameController.text.trim(),
        bio: _bioController.text.trim().isNotEmpty ? _bioController.text.trim() : 'Fitness enthusiast',
        profileImageUrl: user.photoURL,
        joinDate: DateTime.now(),
        age: _ageController.text.isNotEmpty ? int.parse(_ageController.text) : null,
        height: heightInCm,
        weight: weightInKg,
        gender: _selectedGender,
        fitnessLevel: _selectedFitnessLevel,
        primaryGoal: _selectedGoal,
        sportPreferences: [_selectedSport],
        units: _selectedUnits.toLowerCase(),
        stats: UserStats(
          totalWorkouts: 0,
          totalReps: 0,
          totalDistanceKm: 0.0,
          totalWorkoutTime: Duration.zero,
          currentStreak: 0,
          longestStreak: 0,
          exerciseCounts: {},
          personalRecords: {},
        ),
        achievements: [],
        following: [],
        followers: [],
        privacy: PrivacySettings(
          profilePublic: true,
          workoutHistoryPublic: true,
          achievementsPublic: true,
          allowFriendRequests: true,
          showInLeaderboards: true,
        ),
        goals: UserGoals(
          weeklyWorkouts: 3,
          monthlyReps: 1000,
          monthlyDistanceKm: 50.0,
          targetExercises: [_selectedSport],
          targetDate: null,
        ),
      );

      await ProfileService.createOrUpdateProfile(profile);

      Logger.info('User onboarding completed for ${user.uid}', tag: 'ONBOARDING_SCREEN');

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const MainNavigationScreen(),
          ),
        );
      }
    } catch (e) {
      Logger.error('Failed to complete onboarding', tag: 'ONBOARDING_SCREEN', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to complete setup: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Welcome to ScoutVista',
          style: GoogleFonts.urbanist(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome message
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.fitness_center,
                      size: 80,
                      color: Colors.blue.shade600,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Let\'s get to know you!',
                      style: GoogleFonts.urbanist(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Help us personalize your fitness journey',
                      style: GoogleFonts.urbanist(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Name field
              Text(
                'Full Name',
                style: GoogleFonts.urbanist(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Enter your full name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Age field
              Text(
                'Age',
                style: GoogleFonts.urbanist(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Enter your age',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.cake),
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final age = int.tryParse(value);
                    if (age == null || age < 13 || age > 120) {
                      return 'Please enter a valid age (13-120)';
                    }
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Height field
              Text(
                'Height',
                style: GoogleFonts.urbanist(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _heightController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: _selectedUnits == 'Metric' ? 'Enter height in cm' : 'Enter height in feet',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.height),
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final height = double.tryParse(value);
                    if (height == null || height <= 0) {
                      return 'Please enter a valid height';
                    }
                    if (_selectedUnits == 'Metric' && (height < 100 || height > 250)) {
                      return 'Please enter height between 100-250 cm';
                    }
                    if (_selectedUnits == 'Imperial' && (height < 3 || height > 8)) {
                      return 'Please enter height between 3-8 feet';
                    }
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Weight field
              Text(
                'Weight',
                style: GoogleFonts.urbanist(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _weightController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: _selectedUnits == 'Metric' ? 'Enter weight in kg' : 'Enter weight in lbs',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.monitor_weight),
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final weight = double.tryParse(value);
                    if (weight == null || weight <= 0) {
                      return 'Please enter a valid weight';
                    }
                    if (_selectedUnits == 'Metric' && (weight < 20 || weight > 300)) {
                      return 'Please enter weight between 20-300 kg';
                    }
                    if (_selectedUnits == 'Imperial' && (weight < 44 || weight > 660)) {
                      return 'Please enter weight between 44-660 lbs';
                    }
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Units selection
              Text(
                'Units',
                style: GoogleFonts.urbanist(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedUnits,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.straighten),
                ),
                items: _units.map((unit) {
                  return DropdownMenuItem(
                    value: unit,
                    child: Text(unit),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedUnits = value!;
                  });
                },
              ),

              const SizedBox(height: 20),

              // Gender selection
              Text(
                'Gender',
                style: GoogleFonts.urbanist(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                items: _genders.map((gender) {
                  return DropdownMenuItem(
                    value: gender,
                    child: Text(gender),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedGender = value!;
                  });
                },
              ),

              const SizedBox(height: 20),

              // Sport preference
              Text(
                'Primary Sport/Activity',
                style: GoogleFonts.urbanist(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedSport,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.sports),
                ),
                items: _sports.map((sport) {
                  return DropdownMenuItem(
                    value: sport,
                    child: Text(sport),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSport = value!;
                  });
                },
              ),

              const SizedBox(height: 20),

              // Fitness level
              Text(
                'Fitness Level',
                style: GoogleFonts.urbanist(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedFitnessLevel,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.trending_up),
                ),
                items: _fitnessLevels.map((level) {
                  return DropdownMenuItem(
                    value: level,
                    child: Text(level),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedFitnessLevel = value!;
                  });
                },
              ),

              const SizedBox(height: 20),

              // Primary goal
              Text(
                'Primary Goal',
                style: GoogleFonts.urbanist(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedGoal,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.flag),
                ),
                items: _goals.map((goal) {
                  return DropdownMenuItem(
                    value: goal,
                    child: Text(goal),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedGoal = value!;
                  });
                },
              ),

              const SizedBox(height: 20),

              // Bio field (optional)
              Text(
                'Bio (Optional)',
                style: GoogleFonts.urbanist(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _bioController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Tell us about yourself...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.edit),
                ),
              ),

              const SizedBox(height: 32),

              // Complete button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _completeOnboarding,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Complete Setup',
                          style: GoogleFonts.urbanist(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Skip button
              Center(
                child: TextButton(
                  onPressed: _isLoading ? null : () async {
                    // Create minimal profile and proceed
                    try {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        final profile = UserProfile(
                          uid: user.uid,
                          displayName: user.displayName ?? 'Fitness Enthusiast',
                          bio: 'Fitness enthusiast',
                          profileImageUrl: user.photoURL,
                          joinDate: DateTime.now(),
                          gender: 'Prefer not to say',
                          fitnessLevel: 'Beginner',
                          primaryGoal: 'General Health',
                          sportPreferences: ['General Fitness'],
                          units: 'metric',
                          stats: UserStats(
                            totalWorkouts: 0,
                            totalReps: 0,
                            totalDistanceKm: 0.0,
                            totalWorkoutTime: Duration.zero,
                            currentStreak: 0,
                            longestStreak: 0,
                            exerciseCounts: {},
                            personalRecords: {},
                          ),
                          achievements: [],
                          following: [],
                          followers: [],
                          privacy: PrivacySettings(
                            profilePublic: true,
                            workoutHistoryPublic: true,
                            achievementsPublic: true,
                            allowFriendRequests: true,
                            showInLeaderboards: true,
                          ),
                          goals: UserGoals(
                            weeklyWorkouts: 3,
                            monthlyReps: 1000,
                            monthlyDistanceKm: 50.0,
                            targetExercises: ['General Fitness'],
                            targetDate: null,
                          ),
                        );

                        await ProfileService.createOrUpdateProfile(profile);

                        if (mounted) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MainNavigationScreen(),
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to skip setup: $e')),
                        );
                      }
                    }
                  },
                  child: Text(
                    'Skip for now',
                    style: GoogleFonts.urbanist(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
