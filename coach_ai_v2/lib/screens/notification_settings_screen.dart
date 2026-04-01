import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification.dart';
import '../services/notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  NotificationSettings? _settings;
  bool _isLoading = true;
  String _selectedQuietStart = "22:00";
  String _selectedQuietEnd = "08:00";

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final settings = await NotificationService.getNotificationSettings(user.uid);
        setState(() {
          _settings = settings;
          _selectedQuietStart = settings.quietHoursStart;
          _selectedQuietEnd = settings.quietHoursEnd;
        });
      }
    } catch (e) {
      print('Error loading notification settings: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateSettings() async {
    if (_settings == null) return;

    try {
      await NotificationService.updateNotificationSettings(_settings!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save settings: $e')),
      );
    }
  }

  void _updateSetting(String key, bool value) {
    setState(() {
      _settings = _settings!.copyWith(
        pushNotificationsEnabled: key == 'pushNotificationsEnabled' ? value : _settings!.pushNotificationsEnabled,
        emailNotificationsEnabled: key == 'emailNotificationsEnabled' ? value : _settings!.emailNotificationsEnabled,
        likeNotifications: key == 'likeNotifications' ? value : _settings!.likeNotifications,
        commentNotifications: key == 'commentNotifications' ? value : _settings!.commentNotifications,
        followNotifications: key == 'followNotifications' ? value : _settings!.followNotifications,
        achievementNotifications: key == 'achievementNotifications' ? value : _settings!.achievementNotifications,
        challengeNotifications: key == 'challengeNotifications' ? value : _settings!.challengeNotifications,
        workoutSharedNotifications: key == 'workoutSharedNotifications' ? value : _settings!.workoutSharedNotifications,
        weeklyDigest: key == 'weeklyDigest' ? value : _settings!.weeklyDigest,
        dailyReminders: key == 'dailyReminders' ? value : _settings!.dailyReminders,
      );
    });
    _updateSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notification Settings',
          style: GoogleFonts.urbanist(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _settings == null
              ? const Center(child: Text('Failed to load settings'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('General'),
                      _buildSwitchTile(
                        'Push Notifications',
                        'Receive push notifications on your device',
                        'pushNotificationsEnabled',
                        _settings!.pushNotificationsEnabled,
                        Icons.notifications,
                      ),
                      _buildSwitchTile(
                        'Email Notifications',
                        'Receive notifications via email',
                        'emailNotificationsEnabled',
                        _settings!.emailNotificationsEnabled,
                        Icons.email,
                      ),
                      
                      const SizedBox(height: 24),
                      _buildSectionHeader('Social Interactions'),
                      _buildSwitchTile(
                        'Likes',
                        'When someone likes your posts',
                        'likeNotifications',
                        _settings!.likeNotifications,
                        Icons.favorite,
                      ),
                      _buildSwitchTile(
                        'Comments',
                        'When someone comments on your posts',
                        'commentNotifications',
                        _settings!.commentNotifications,
                        Icons.comment,
                      ),
                      _buildSwitchTile(
                        'New Followers',
                        'When someone starts following you',
                        'followNotifications',
                        _settings!.followNotifications,
                        Icons.person_add,
                      ),
                      _buildSwitchTile(
                        'Workout Shares',
                        'When someone shares a workout',
                        'workoutSharedNotifications',
                        _settings!.workoutSharedNotifications,
                        Icons.share,
                      ),
                      
                      const SizedBox(height: 24),
                      _buildSectionHeader('App Updates'),
                      _buildSwitchTile(
                        'Achievements',
                        'When you unlock new achievements',
                        'achievementNotifications',
                        _settings!.achievementNotifications,
                        Icons.emoji_events,
                      ),
                      _buildSwitchTile(
                        'Challenges',
                        'When new challenges are available',
                        'challengeNotifications',
                        _settings!.challengeNotifications,
                        Icons.flag,
                      ),
                      _buildSwitchTile(
                        'Weekly Digest',
                        'Weekly summary of your activity',
                        'weeklyDigest',
                        _settings!.weeklyDigest,
                        Icons.analytics,
                      ),
                      _buildSwitchTile(
                        'Daily Reminders',
                        'Daily workout reminders',
                        'dailyReminders',
                        _settings!.dailyReminders,
                        Icons.schedule,
                      ),
                      
                      const SizedBox(height: 24),
                      _buildSectionHeader('Quiet Hours'),
                      _buildQuietHoursSection(),
                      
                      const SizedBox(height: 32),
                      _buildTestNotificationButton(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: GoogleFonts.urbanist(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade800,
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    String key,
    bool value,
    IconData icon,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        title: Text(
          title,
          style: GoogleFonts.urbanist(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.urbanist(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        value: value,
        onChanged: (newValue) => _updateSetting(key, newValue),
        secondary: Icon(
          icon,
          color: value ? Theme.of(context).colorScheme.primary : Colors.grey.shade400,
        ),
        activeColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildQuietHoursSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bedtime,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 12),
                Text(
                  'Quiet Hours',
                  style: GoogleFonts.urbanist(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Choose when you don\'t want to receive notifications',
              style: GoogleFonts.urbanist(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Start Time',
                        style: GoogleFonts.urbanist(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _selectQuietStartTime,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _selectedQuietStart,
                                style: GoogleFonts.urbanist(fontSize: 16),
                              ),
                              Icon(Icons.access_time, color: Colors.grey.shade600),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'End Time',
                        style: GoogleFonts.urbanist(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _selectQuietEndTime,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _selectedQuietEnd,
                                style: GoogleFonts.urbanist(fontSize: 16),
                              ),
                              Icon(Icons.access_time, color: Colors.grey.shade600),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestNotificationButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _sendTestNotification,
        icon: const Icon(Icons.send),
        label: const Text('Send Test Notification'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Future<void> _selectQuietStartTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        DateTime(2024, 1, 1, int.parse(_selectedQuietStart.split(':')[0]), int.parse(_selectedQuietStart.split(':')[1])),
      ),
    );
    
    if (time != null) {
      setState(() {
        _selectedQuietStart = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
        _settings = _settings!.copyWith(quietHoursStart: _selectedQuietStart);
      });
      _updateSettings();
    }
  }

  Future<void> _selectQuietEndTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        DateTime(2024, 1, 1, int.parse(_selectedQuietEnd.split(':')[0]), int.parse(_selectedQuietEnd.split(':')[1])),
      ),
    );
    
    if (time != null) {
      setState(() {
        _selectedQuietEnd = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
        _settings = _settings!.copyWith(quietHoursEnd: _selectedQuietEnd);
      });
      _updateSettings();
    }
  }

  Future<void> _sendTestNotification() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await NotificationService.createAchievementNotification(
        userId: user.uid,
        achievementTitle: 'Test Achievement',
        achievementDescription: 'This is a test notification to verify your settings are working correctly.',
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Test notification sent!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send test notification: $e')),
      );
    }
  }
}
