import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/challenge.dart';
import '../models/leaderboard.dart';
import '../services/challenge_service.dart';
import '../utils/logger.dart';

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Challenge> _challenges = [];
  List<Leaderboard> _leaderboards = [];
  List<Achievement> _achievements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final challenges = await ChallengeService.getActiveChallenges();
      final leaderboards = await ChallengeService.getLeaderboards();
      final achievements = await ChallengeService.getUserAchievements(userId);

      setState(() {
        _challenges = challenges;
        _leaderboards = leaderboards;
        _achievements = achievements;
      });
    } catch (e) {
      Logger.error('Failed to load challenges data', tag: 'CHALLENGES_SCREEN', error: e);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Challenges & Leaderboards',
          style: GoogleFonts.urbanist(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Challenges'),
            Tab(text: 'Leaderboards'),
            Tab(text: 'Achievements'),
          ],
          labelStyle: GoogleFonts.urbanist(fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.urbanist(fontWeight: FontWeight.w500),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildChallengesTab(),
          _buildLeaderboardsTab(),
          _buildAchievementsTab(),
        ],
      ),
    );
  }

  Widget _buildChallengesTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _challenges.length,
        itemBuilder: (context, index) {
          final challenge = _challenges[index];
          return _buildChallengeCard(challenge);
        },
      ),
    );
  }

  Widget _buildChallengeCard(Challenge challenge) {
    final daysLeft = challenge.endDate.difference(DateTime.now()).inDays;
    final isExpired = daysLeft < 0;
    final isUpcoming = challenge.startDate.isAfter(DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getChallengeTypeColor(challenge.type),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    challenge.type.toUpperCase(),
                    style: GoogleFonts.urbanist(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Spacer(),
                if (isExpired)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'EXPIRED',
                      style: GoogleFonts.urbanist(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade700,
                      ),
                    ),
                  )
                else if (isUpcoming)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'UPCOMING',
                      style: GoogleFonts.urbanist(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$daysLeft days left',
                      style: GoogleFonts.urbanist(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              challenge.title,
              style: GoogleFonts.urbanist(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              challenge.description,
              style: GoogleFonts.urbanist(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  _getExerciseIcon(challenge.exerciseType),
                  size: 20,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 8),
                Text(
                  _getExerciseDisplayName(challenge.exerciseType),
                  style: GoogleFonts.urbanist(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${challenge.participants.length} participants',
                  style: GoogleFonts.urbanist(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildChallengeTarget(challenge),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isExpired ? null : () => _joinChallenge(challenge),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getChallengeTypeColor(challenge.type),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  isExpired ? 'Challenge Expired' : 'Join Challenge',
                  style: GoogleFonts.urbanist(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengeTarget(Challenge challenge) {
    final target = challenge.target;
    final targetItems = <Widget>[];

    target.forEach((key, value) {
      targetItems.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Text(
                value.toString(),
                style: GoogleFonts.urbanist(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _getChallengeTypeColor(challenge.type),
                ),
              ),
              Text(
                _getTargetUnit(key),
                style: GoogleFonts.urbanist(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Target',
          style: GoogleFonts.urbanist(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: targetItems,
        ),
      ],
    );
  }

  Widget _buildLeaderboardsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _leaderboards.length,
        itemBuilder: (context, index) {
          final leaderboard = _leaderboards[index];
          return _buildLeaderboardCard(leaderboard);
        },
      ),
    );
  }

  Widget _buildLeaderboardCard(Leaderboard leaderboard) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getLeaderboardIcon(leaderboard.type),
                  size: 24,
                  color: _getLeaderboardTypeColor(leaderboard.type),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        leaderboard.title,
                        style: GoogleFonts.urbanist(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        leaderboard.description,
                        style: GoogleFonts.urbanist(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Top ${leaderboard.entries.length}',
              style: GoogleFonts.urbanist(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            ...leaderboard.entries.take(5).map((entry) => _buildLeaderboardEntry(entry)),
            if (leaderboard.entries.length > 5)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextButton(
                  onPressed: () => _showFullLeaderboard(leaderboard),
                  child: Text(
                    'View Full Leaderboard',
                    style: GoogleFonts.urbanist(
                      color: _getLeaderboardTypeColor(leaderboard.type),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardEntry(LeaderboardEntry entry) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _getRankColor(entry.rank),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                entry.rank.toString(),
                style: GoogleFonts.urbanist(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey.shade200,
            child: entry.profileImageUrl != null
                ? ClipOval(
                    child: Image.network(
                      entry.profileImageUrl!,
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                    ),
                  )
                : Text(
                    entry.displayName[0].toUpperCase(),
                    style: GoogleFonts.urbanist(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              entry.displayName,
              style: GoogleFonts.urbanist(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            '${entry.value.toStringAsFixed(1)} ${entry.unit}',
            style: GoogleFonts.urbanist(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _getRankColor(entry.rank),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _achievements.length,
        itemBuilder: (context, index) {
          final achievement = _achievements[index];
          return _buildAchievementCard(achievement);
        },
      ),
    );
  }

  Widget _buildAchievementCard(Achievement achievement) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: achievement.isRare ? Colors.amber.shade100 : Colors.blue.shade100,
                shape: BoxShape.circle,
                border: achievement.isRare
                    ? Border.all(color: Colors.amber.shade300, width: 2)
                    : null,
              ),
              child: Icon(
                _getAchievementIcon(achievement.iconName),
                size: 30,
                color: achievement.isRare ? Colors.amber.shade700 : Colors.blue.shade700,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        achievement.title,
                        style: GoogleFonts.urbanist(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (achievement.isRare) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.star,
                          size: 16,
                          color: Colors.amber.shade600,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    achievement.description,
                    style: GoogleFonts.urbanist(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getAchievementCategoryColor(achievement.category),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          achievement.category.toUpperCase(),
                          style: GoogleFonts.urbanist(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.stars,
                        size: 16,
                        color: Colors.amber.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${achievement.points} pts',
                        style: GoogleFonts.urbanist(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  Color _getChallengeTypeColor(String type) {
    switch (type) {
      case 'daily':
        return Colors.green;
      case 'weekly':
        return Colors.blue;
      case 'monthly':
        return Colors.purple;
      case 'custom':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _getLeaderboardTypeColor(String type) {
    switch (type) {
      case 'global':
        return Colors.blue;
      case 'friends':
        return Colors.green;
      case 'challenge':
        return Colors.purple;
      case 'exercise':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey.shade400;
      case 3:
        return Colors.orange.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  Color _getAchievementCategoryColor(String category) {
    switch (category) {
      case 'fitness':
        return Colors.blue;
      case 'social':
        return Colors.green;
      case 'exploration':
        return Colors.purple;
      case 'mastery':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  IconData _getExerciseIcon(String exerciseType) {
    switch (exerciseType) {
      case 'push_up':
        return Icons.fitness_center;
      case 'squat':
        return Icons.accessibility;
      case 'run_5k':
        return Icons.directions_run;
      case 'shuttle_pro_agility':
        return Icons.speed;
      default:
        return Icons.sports;
    }
  }

  String _getExerciseDisplayName(String exerciseType) {
    switch (exerciseType) {
      case 'push_up':
        return 'Push-ups';
      case 'squat':
        return 'Squats';
      case 'run_5k':
        return '5K Run';
      case 'shuttle_pro_agility':
        return 'Shuttle Run';
      default:
        return exerciseType.replaceAll('_', ' ').toUpperCase();
    }
  }

  String _getTargetUnit(String key) {
    switch (key) {
      case 'reps':
        return 'reps';
      case 'distance':
        return 'km';
      case 'time':
        return 'min';
      case 'streak':
        return 'days';
      default:
        return key;
    }
  }

  IconData _getLeaderboardIcon(String type) {
    switch (type) {
      case 'global':
        return Icons.public;
      case 'friends':
        return Icons.people;
      case 'challenge':
        return Icons.emoji_events;
      case 'exercise':
        return Icons.fitness_center;
      default:
        return Icons.leaderboard;
    }
  }

  IconData _getAchievementIcon(String iconName) {
    switch (iconName) {
      case 'first_workout':
        return Icons.play_arrow;
      case 'streak_7':
        return Icons.local_fire_department;
      case 'streak_30':
        return Icons.whatshot;
      case 'personal_record':
        return Icons.trending_up;
      case 'challenge_complete':
        return Icons.emoji_events;
      case 'social_butterfly':
        return Icons.people;
      default:
        return Icons.star;
    }
  }

  void _joinChallenge(Challenge challenge) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      await ChallengeService.joinChallenge(challenge.id, userId);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Joined ${challenge.title}!')),
      );
      
      _loadData(); // Refresh the list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to join challenge: $e')),
      );
    }
  }

  void _showFullLeaderboard(Leaderboard leaderboard) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(leaderboard.title),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: leaderboard.entries.length,
            itemBuilder: (context, index) {
              final entry = leaderboard.entries[index];
              return _buildLeaderboardEntry(entry);
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
