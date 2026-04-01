import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';
import '../services/profile_service.dart';
import '../utils/logger.dart';
import 'calendar_screen.dart';
import 'notification_settings_screen.dart';
import 'privacy_settings_screen.dart';
import 'onboarding_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId; // null for current user, specific ID for other users
  
  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  UserProfile? _profile;
  bool _isLoading = true;
  bool _isFollowing = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    
    try {
      final userId = widget.userId ?? FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;
      
      final profile = await ProfileService.getProfile(userId);
      if (profile != null) {
        if (mounted) {
          setState(() {
            _profile = profile;
            _isFollowing = _isCurrentUserFollowing(profile);
          });
        }
      } else {
        // Create default profile if none exists
        await _createDefaultProfile(userId);
        if (mounted) {
          await _loadProfile(); // Reload after creating
        }
      }
    } catch (e) {
      Logger.error('Failed to load profile', tag: 'PROFILE_SCREEN', error: e);
      // Create default profile on error
      final userId = widget.userId ?? FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        await _createDefaultProfile(userId);
        if (mounted) {
          await _loadProfile(); // Reload after creating
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _createDefaultProfile(String userId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final defaultProfile = UserProfile(
        uid: userId,
        displayName: user.displayName ?? 'Fitness Enthusiast',
        profileImageUrl: user.photoURL,
        bio: 'Ready to achieve my fitness goals!',
        joinDate: DateTime.now(),
        stats: const UserStats(
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
        privacy: const PrivacySettings(
          profilePublic: true,
          workoutHistoryPublic: true,
          achievementsPublic: true,
          allowFriendRequests: true,
          showInLeaderboards: true,
        ),
        goals: const UserGoals(
          weeklyWorkouts: 3,
          monthlyReps: 1000,
          monthlyDistanceKm: 50.0,
          targetExercises: [],
        ),
      );

      await ProfileService.createOrUpdateProfile(defaultProfile);
      Logger.info('Default profile created', tag: 'PROFILE_SCREEN', data: {'userId': userId});
    } catch (e) {
      Logger.error('Failed to create default profile', tag: 'PROFILE_SCREEN', error: e);
    }
  }

  bool _isCurrentUserFollowing(UserProfile profile) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    return currentUserId != null && profile.followers.contains(currentUserId);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_profile == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Profile',
            style: GoogleFonts.urbanist(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Creating your profile...',
                style: GoogleFonts.urbanist(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Setting up your fitness journey',
                style: GoogleFonts.urbanist(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 300,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: _buildProfileHeader(),
              ),
              actions: [
                if (widget.userId != null) // Not current user
                  IconButton(
                    icon: Icon(_isFollowing ? Icons.person_remove : Icons.person_add),
                    onPressed: _toggleFollow,
                  ),
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: _showSettings,
                ),
              ],
            ),
          ];
        },
        body: Column(
          children: [
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Profile'),
                Tab(text: 'Stats'),
                Tab(text: 'Calendar'),
                Tab(text: 'Achievements'),
                Tab(text: 'Activity'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildProfileDetailsTab(),
                  _buildStatsTab(),
                  _buildCalendarTab(),
                  _buildAchievementsTab(),
                  _buildActivityTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.blue.shade400, Colors.blue.shade600],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Profile Picture
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white,
              backgroundImage: _profile!.profileImageUrl != null
                  ? NetworkImage(_profile!.profileImageUrl!)
                  : null,
              child: _profile!.profileImageUrl == null
                  ? Icon(Icons.person, size: 50, color: Colors.grey.shade400)
                  : null,
            ),
            const SizedBox(height: 16),
            
            // Name and Bio
            Text(
              _profile!.displayName,
              style: GoogleFonts.urbanist(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (_profile!.bio != null) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _profile!.bio!,
                  style: GoogleFonts.urbanist(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            const SizedBox(height: 16),
            
            // Stats Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem('Workouts', _profile!.stats.totalWorkouts.toString()),
                _buildStatItem('Reps', _profile!.stats.totalReps.toString()),
                _buildStatItem('Distance', '${_profile!.stats.totalDistanceKm.toStringAsFixed(1)} km'),
                _buildStatItem('Streak', '${_profile!.stats.currentStreak} days'),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.urbanist(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.urbanist(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsCard(),
          const SizedBox(height: 16),
          _buildExerciseBreakdownCard(),
          const SizedBox(height: 16),
          _buildPersonalRecordsCard(),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overall Stats',
              style: GoogleFonts.urbanist(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatRow('Total Workouts', _profile!.stats.totalWorkouts.toString()),
                ),
                Expanded(
                  child: _buildStatRow('Total Reps', _profile!.stats.totalReps.toString()),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatRow('Distance', '${_profile!.stats.totalDistanceKm.toStringAsFixed(1)} km'),
                ),
                Expanded(
                  child: _buildStatRow('Time', _formatDuration(_profile!.stats.totalWorkoutTime)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatRow('Current Streak', '${_profile!.stats.currentStreak} days'),
                ),
                Expanded(
                  child: _buildStatRow('Best Streak', '${_profile!.stats.longestStreak} days'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: GoogleFonts.urbanist(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade700,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.urbanist(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseBreakdownCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Exercise Breakdown',
              style: GoogleFonts.urbanist(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._profile!.stats.exerciseCounts.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.key.replaceAll('_', ' ').toUpperCase(),
                      style: GoogleFonts.urbanist(fontSize: 14),
                    ),
                    Text(
                      entry.value.toString(),
                      style: GoogleFonts.urbanist(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalRecordsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personal Records',
              style: GoogleFonts.urbanist(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_profile!.stats.personalRecords.isEmpty)
              Text(
                'No personal records yet',
                style: GoogleFonts.urbanist(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              )
            else
              ..._profile!.stats.personalRecords.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key.replaceAll('_', ' ').toUpperCase(),
                        style: GoogleFonts.urbanist(fontSize: 14),
                      ),
                      Text(
                        entry.value.toStringAsFixed(1),
                        style: GoogleFonts.urbanist(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarTab() {
    return const CalendarScreen();
  }

  Widget _buildAchievementsTab() {
    return Center(
      child: Text(
        'Achievements coming soon!',
        style: GoogleFonts.urbanist(
          fontSize: 16,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildActivityTab() {
    return Center(
      child: Text(
        'Activity feed coming soon!',
        style: GoogleFonts.urbanist(
          fontSize: 16,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  void _toggleFollow() async {
    if (_profile == null) return;
    
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) return;
      
      if (_isFollowing) {
        await ProfileService.unfollowUser(currentUserId, _profile!.uid);
      } else {
        await ProfileService.followUser(currentUserId, _profile!.uid);
      }
      
      setState(() {
        _isFollowing = !_isFollowing;
      });
    } catch (e) {
      Logger.error('Failed to toggle follow', tag: 'PROFILE_SCREEN', error: e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to ${_isFollowing ? 'unfollow' : 'follow'} user')),
      );
    }
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Settings',
              style: GoogleFonts.urbanist(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: Text(
                'Notification Settings',
                style: GoogleFonts.urbanist(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                'Manage your notification preferences',
                style: GoogleFonts.urbanist(color: Colors.grey.shade600),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationSettingsScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip),
              title: Text(
                'Privacy Settings',
                style: GoogleFonts.urbanist(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                'Control your privacy and data',
                style: GoogleFonts.urbanist(color: Colors.grey.shade600),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PrivacySettingsScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_add),
              title: Text(
                'Complete Profile',
                style: GoogleFonts.urbanist(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                'Add missing profile information',
                style: GoogleFonts.urbanist(color: Colors.grey.shade600),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OnboardingScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.help),
              title: Text(
                'Help & Support',
                style: GoogleFonts.urbanist(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                'Get help and contact support',
                style: GoogleFonts.urbanist(color: Colors.grey.shade600),
              ),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Help & support coming soon!')),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: Text(
                'Sign Out',
                style: GoogleFonts.urbanist(
                  fontWeight: FontWeight.w500,
                  color: Colors.red,
                ),
              ),
              subtitle: Text(
                'Sign out of your account',
                style: GoogleFonts.urbanist(color: Colors.grey.shade600),
              ),
              onTap: () async {
                Navigator.pop(context);
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(
                      'Sign Out',
                      style: GoogleFonts.urbanist(fontWeight: FontWeight.w600),
                    ),
                    content: Text(
                      'Are you sure you want to sign out?',
                      style: GoogleFonts.urbanist(),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Sign Out'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  try {
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted) {
                      Navigator.pushReplacementNamed(context, '/');
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error signing out: $e')),
                      );
                    }
                  }
                }
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileDetailsTab() {
    if (_profile == null) return const Center(child: CircularProgressIndicator());
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Personal Information Section
          _buildProfileSection(
            'Personal Information',
            Icons.person,
            [
              _buildDetailRow('Name', _profile!.displayName),
              if (_profile!.age != null) _buildDetailRow('Age', '${_profile!.age} years old'),
              if (_profile!.gender != null) _buildDetailRow('Gender', _profile!.gender!),
              if (_profile!.bio != null) _buildDetailRow('Bio', _profile!.bio!),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Physical Information Section
          _buildProfileSection(
            'Physical Information',
            Icons.monitor_weight,
            [
              if (_profile!.height != null) _buildDetailRow('Height', '${_profile!.height!.toStringAsFixed(1)} cm'),
              if (_profile!.weight != null) _buildDetailRow('Weight', '${_profile!.weight!.toStringAsFixed(1)} kg'),
              _buildDetailRow('Units', _profile!.units == 'metric' ? 'Metric' : 'Imperial'),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Fitness Information Section
          _buildProfileSection(
            'Fitness Information',
            Icons.fitness_center,
            [
              if (_profile!.fitnessLevel != null) _buildDetailRow('Fitness Level', _profile!.fitnessLevel!),
              if (_profile!.primaryGoal != null) _buildDetailRow('Primary Goal', _profile!.primaryGoal!),
              if (_profile!.sportPreferences.isNotEmpty) _buildDetailRow('Sport Preferences', _profile!.sportPreferences.join(', ')),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Account Information Section
          _buildProfileSection(
            'Account Information',
            Icons.account_circle,
            [
              _buildDetailRow('Member Since', _formatDate(_profile!.joinDate)),
              _buildDetailRow('User ID', _profile!.uid),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection(String title, IconData icon, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.urbanist(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.urbanist(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.urbanist(
                fontSize: 14,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
