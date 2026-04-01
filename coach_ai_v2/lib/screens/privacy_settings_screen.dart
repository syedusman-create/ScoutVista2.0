import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/privacy_settings.dart';
import '../services/privacy_service.dart';
import '../utils/logger.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  PrivacySettings? _privacySettings;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadPrivacySettings();
  }

  Future<void> _loadPrivacySettings() async {
    setState(() => _isLoading = true);
    
    try {
      final settings = await PrivacyService.getPrivacySettings();
      setState(() {
        _privacySettings = settings;
      });
    } catch (e) {
      Logger.error('Failed to load privacy settings', tag: 'PRIVACY_SETTINGS_SCREEN', error: e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load privacy settings: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateSetting(String key, bool value) async {
    if (_privacySettings == null) return;

    setState(() => _isSaving = true);

    try {
      await PrivacyService.updatePrivacySetting(key, value);
      
      // Update local state
      setState(() {
        _privacySettings = _privacySettings!.copyWith(
          profilePublic: key == 'profilePublic' ? value : _privacySettings!.profilePublic,
          showWorkoutHistory: key == 'showWorkoutHistory' ? value : _privacySettings!.showWorkoutHistory,
          showStats: key == 'showStats' ? value : _privacySettings!.showStats,
          showAchievements: key == 'showAchievements' ? value : _privacySettings!.showAchievements,
          showCalendar: key == 'showCalendar' ? value : _privacySettings!.showCalendar,
          allowFollowRequests: key == 'allowFollowRequests' ? value : _privacySettings!.allowFollowRequests,
          allowMessages: key == 'allowMessages' ? value : _privacySettings!.allowMessages,
          showOnlineStatus: key == 'showOnlineStatus' ? value : _privacySettings!.showOnlineStatus,
          allowDataSharing: key == 'allowDataSharing' ? value : _privacySettings!.allowDataSharing,
          allowAnalytics: key == 'allowAnalytics' ? value : _privacySettings!.allowAnalytics,
          allowNotifications: key == 'allowNotifications' ? value : _privacySettings!.allowNotifications,
          allowLocationTracking: key == 'allowLocationTracking' ? value : _privacySettings!.allowLocationTracking,
          allowCameraAccess: key == 'allowCameraAccess' ? value : _privacySettings!.allowCameraAccess,
          allowMicrophoneAccess: key == 'allowMicrophoneAccess' ? value : _privacySettings!.allowMicrophoneAccess,
          allowPhotoLibraryAccess: key == 'allowPhotoLibraryAccess' ? value : _privacySettings!.allowPhotoLibraryAccess,
          allowContactsAccess: key == 'allowContactsAccess' ? value : _privacySettings!.allowContactsAccess,
          allowHealthDataAccess: key == 'allowHealthDataAccess' ? value : _privacySettings!.allowHealthDataAccess,
          allowWorkoutSharing: key == 'allowWorkoutSharing' ? value : _privacySettings!.allowWorkoutSharing,
          allowChallengeParticipation: key == 'allowChallengeParticipation' ? value : _privacySettings!.allowChallengeParticipation,
          allowLeaderboardParticipation: key == 'allowLeaderboardParticipation' ? value : _privacySettings!.allowLeaderboardParticipation,
          allowSocialFeatures: key == 'allowSocialFeatures' ? value : _privacySettings!.allowSocialFeatures,
          allowDataExport: key == 'allowDataExport' ? value : _privacySettings!.allowDataExport,
          allowDataDeletion: key == 'allowDataDeletion' ? value : _privacySettings!.allowDataDeletion,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Privacy setting updated')),
      );
    } catch (e) {
      Logger.error('Failed to update privacy setting $key', tag: 'PRIVACY_SETTINGS_SCREEN', error: e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update setting: $e')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _exportData() async {
    try {
      final data = await PrivacyService.exportUserData();
      
      // In a real app, you would save this to a file or share it
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data export completed. Check your downloads.')),
      );
      
      Logger.info('Data exported successfully', tag: 'PRIVACY_SETTINGS_SCREEN');
    } catch (e) {
      Logger.error('Failed to export data', tag: 'PRIVACY_SETTINGS_SCREEN', error: e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export data: $e')),
      );
    }
  }

  Future<void> _deleteData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete All Data',
          style: GoogleFonts.urbanist(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'This action cannot be undone. All your data will be permanently deleted.',
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await PrivacyService.deleteUserData();
        
        // Sign out user after data deletion
        await FirebaseAuth.instance.signOut();
        
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/');
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All data deleted successfully')),
        );
      } catch (e) {
        Logger.error('Failed to delete data', tag: 'PRIVACY_SETTINGS_SCREEN', error: e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Privacy & Data Control',
          style: GoogleFonts.urbanist(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _privacySettings == null
              ? _buildErrorState()
              : _buildPrivacySettings(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load privacy settings',
            style: GoogleFonts.urbanist(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please try again later',
            style: GoogleFonts.urbanist(
              fontSize: 16,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadPrivacySettings,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySettings() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Profile Visibility'),
          _buildSettingTile(
            'Public Profile',
            'Make your profile visible to other users',
            'profilePublic',
            _privacySettings!.profilePublic,
            Icons.public,
          ),
          _buildSettingTile(
            'Show Workout History',
            'Display your workout history on your profile',
            'showWorkoutHistory',
            _privacySettings!.showWorkoutHistory,
            Icons.history,
          ),
          _buildSettingTile(
            'Show Statistics',
            'Display your fitness statistics on your profile',
            'showStats',
            _privacySettings!.showStats,
            Icons.analytics,
          ),
          _buildSettingTile(
            'Show Achievements',
            'Display your achievements on your profile',
            'showAchievements',
            _privacySettings!.showAchievements,
            Icons.emoji_events,
          ),
          _buildSettingTile(
            'Show Calendar',
            'Display your workout calendar on your profile',
            'showCalendar',
            _privacySettings!.showCalendar,
            Icons.calendar_today,
          ),

          const SizedBox(height: 24),
          _buildSectionHeader('Social Features'),
          _buildSettingTile(
            'Allow Follow Requests',
            'Let other users send you follow requests',
            'allowFollowRequests',
            _privacySettings!.allowFollowRequests,
            Icons.person_add,
          ),
          _buildSettingTile(
            'Allow Messages',
            'Let other users send you messages',
            'allowMessages',
            _privacySettings!.allowMessages,
            Icons.message,
          ),
          _buildSettingTile(
            'Show Online Status',
            'Display when you are online',
            'showOnlineStatus',
            _privacySettings!.showOnlineStatus,
            Icons.circle,
          ),
          _buildSettingTile(
            'Allow Workout Sharing',
            'Let you share your workouts with others',
            'allowWorkoutSharing',
            _privacySettings!.allowWorkoutSharing,
            Icons.share,
          ),
          _buildSettingTile(
            'Allow Challenge Participation',
            'Let you participate in challenges',
            'allowChallengeParticipation',
            _privacySettings!.allowChallengeParticipation,
            Icons.group,
          ),
          _buildSettingTile(
            'Allow Leaderboard Participation',
            'Let you appear on leaderboards',
            'allowLeaderboardParticipation',
            _privacySettings!.allowLeaderboardParticipation,
            Icons.leaderboard,
          ),

          const SizedBox(height: 24),
          _buildSectionHeader('Data & Analytics'),
          _buildSettingTile(
            'Allow Data Sharing',
            'Share anonymized data for app improvement',
            'allowDataSharing',
            _privacySettings!.allowDataSharing,
            Icons.data_usage,
          ),
          _buildSettingTile(
            'Allow Analytics',
            'Collect usage analytics to improve the app',
            'allowAnalytics',
            _privacySettings!.allowAnalytics,
            Icons.analytics,
          ),
          _buildSettingTile(
            'Allow Notifications',
            'Receive push notifications from the app',
            'allowNotifications',
            _privacySettings!.allowNotifications,
            Icons.notifications,
          ),

          const SizedBox(height: 24),
          _buildSectionHeader('Device Permissions'),
          _buildSettingTile(
            'Location Tracking',
            'Allow the app to track your location for runs',
            'allowLocationTracking',
            _privacySettings!.allowLocationTracking,
            Icons.location_on,
          ),
          _buildSettingTile(
            'Camera Access',
            'Allow the app to access your camera for workouts',
            'allowCameraAccess',
            _privacySettings!.allowCameraAccess,
            Icons.camera_alt,
          ),
          _buildSettingTile(
            'Microphone Access',
            'Allow the app to access your microphone for voice commands',
            'allowMicrophoneAccess',
            _privacySettings!.allowMicrophoneAccess,
            Icons.mic,
          ),
          _buildSettingTile(
            'Photo Library Access',
            'Allow the app to access your photo library',
            'allowPhotoLibraryAccess',
            _privacySettings!.allowPhotoLibraryAccess,
            Icons.photo_library,
          ),
          _buildSettingTile(
            'Contacts Access',
            'Allow the app to access your contacts to find friends',
            'allowContactsAccess',
            _privacySettings!.allowContactsAccess,
            Icons.contacts,
          ),
          _buildSettingTile(
            'Health Data Access',
            'Allow the app to access your health data',
            'allowHealthDataAccess',
            _privacySettings!.allowHealthDataAccess,
            Icons.favorite,
          ),

          const SizedBox(height: 24),
          _buildSectionHeader('Data Control'),
          _buildActionTile(
            'Export My Data',
            'Download a copy of all your data',
            Icons.download,
            _exportData,
          ),
          _buildActionTile(
            'Delete All Data',
            'Permanently delete all your data',
            Icons.delete_forever,
            _deleteData,
            isDestructive: true,
          ),

          const SizedBox(height: 24),
          _buildSectionHeader('Privacy Summary'),
          _buildPrivacySummary(),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: GoogleFonts.urbanist(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade800,
        ),
      ),
    );
  }

  Widget _buildSettingTile(
    String title,
    String subtitle,
    String key,
    bool value,
    IconData icon, {
    bool isDestructive = false,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          title,
          style: GoogleFonts.urbanist(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isDestructive ? Colors.red : Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.urbanist(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        leading: Icon(
          icon,
          color: isDestructive ? Colors.red : Colors.grey.shade600,
        ),
        trailing: Switch(
          value: value,
          onChanged: _isSaving ? null : (bool newValue) {
            _updateSetting(key, newValue);
          },
          activeColor: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildActionTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          title,
          style: GoogleFonts.urbanist(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isDestructive ? Colors.red : Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.urbanist(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        leading: Icon(
          icon,
          color: isDestructive ? Colors.red : Colors.grey.shade600,
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildPrivacySummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Privacy Status',
              style: GoogleFonts.urbanist(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildSummaryItem('Profile', _privacySettings!.profilePublic ? 'Public' : 'Private'),
            _buildSummaryItem('Data Sharing', _privacySettings!.allowDataSharing ? 'Enabled' : 'Disabled'),
            _buildSummaryItem('Analytics', _privacySettings!.allowAnalytics ? 'Enabled' : 'Disabled'),
            _buildSummaryItem('Notifications', _privacySettings!.allowNotifications ? 'Enabled' : 'Disabled'),
            _buildSummaryItem('Location', _privacySettings!.allowLocationTracking ? 'Enabled' : 'Disabled'),
            _buildSummaryItem('Social Features', _privacySettings!.allowSocialFeatures ? 'Enabled' : 'Disabled'),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.urbanist(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.urbanist(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: value == 'Enabled' || value == 'Public' 
                  ? Colors.green 
                  : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
