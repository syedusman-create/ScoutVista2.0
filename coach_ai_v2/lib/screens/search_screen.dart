import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';
import '../models/social_post.dart';
import '../models/challenge.dart';
import '../services/search_service.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;
  
  // Search results
  List<UserProfile> _userResults = [];
  List<SocialPost> _postResults = [];
  List<Challenge> _challengeResults = [];
  List<String> _suggestions = [];
  
  // Discover content
  Map<String, dynamic> _discoverContent = {};
  bool _isLoadingDiscover = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDiscoverContent();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
    
    if (_searchQuery.trim().isNotEmpty) {
      _performSearch();
    } else {
      setState(() {
        _userResults = [];
        _postResults = [];
        _challengeResults = [];
        _suggestions = [];
      });
    }
  }

  Future<void> _performSearch() async {
    if (_searchQuery.trim().isEmpty) return;

    setState(() => _isSearching = true);

    try {
      final results = await Future.wait([
        SearchService.searchUsers(_searchQuery),
        SearchService.searchPosts(_searchQuery),
        SearchService.searchChallenges(_searchQuery),
        SearchService.getSearchSuggestions(_searchQuery),
      ]);

      setState(() {
        _userResults = results[0] as List<UserProfile>;
        _postResults = results[1] as List<SocialPost>;
        _challengeResults = results[2] as List<Challenge>;
        _suggestions = results[3] as List<String>;
      });
    } catch (e) {
      print('Search error: $e');
    } finally {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _loadDiscoverContent() async {
    if (!mounted) return;
    setState(() => _isLoadingDiscover = true);
    
    try {
      final content = await SearchService.getDiscoverContent();
      if (mounted) {
        setState(() {
          _discoverContent = content;
        });
      }
    } catch (e) {
      print('Error loading discover content: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingDiscover = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Search & Discover',
          style: GoogleFonts.urbanist(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelStyle: GoogleFonts.urbanist(fontWeight: FontWeight.w600, fontSize: 16),
          unselectedLabelStyle: GoogleFonts.urbanist(fontWeight: FontWeight.w500, fontSize: 16),
          indicatorColor: Theme.of(context).colorScheme.primary,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.grey.shade600,
          tabs: const [
            Tab(text: 'Search'),
            Tab(text: 'Discover'),
            Tab(text: 'Trending'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSearchTab(),
          _buildDiscoverTab(),
          _buildTrendingTab(),
        ],
      ),
    );
  }

  Widget _buildSearchTab() {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search users, posts, challenges...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
              ),
            ),
          ),
        ),
        
        // Search results or suggestions
        Expanded(
          child: _searchQuery.trim().isEmpty
              ? _buildSuggestions()
              : _buildSearchResults(),
        ),
      ],
    );
  }

  Widget _buildSuggestions() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Popular Searches',
          style: GoogleFonts.urbanist(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildSuggestionChip('Push-ups'),
            _buildSuggestionChip('5K Run'),
            _buildSuggestionChip('Squats'),
            _buildSuggestionChip('Challenges'),
            _buildSuggestionChip('#fitness'),
            _buildSuggestionChip('#workout'),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Exercise Types',
          style: GoogleFonts.urbanist(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        _buildExerciseTypeCard('Push-ups', Icons.fitness_center, Colors.blue),
        _buildExerciseTypeCard('Squats', Icons.accessibility, Colors.green),
        _buildExerciseTypeCard('5K Run', Icons.directions_run, Colors.orange),
        _buildExerciseTypeCard('Shuttle Run', Icons.speed, Colors.purple),
      ],
    );
  }

  Widget _buildSuggestionChip(String text) {
    return ActionChip(
      label: Text(text),
      onPressed: () {
        _searchController.text = text;
      },
      backgroundColor: Colors.grey.shade100,
      labelStyle: GoogleFonts.urbanist(fontSize: 14),
    );
  }

  Widget _buildExerciseTypeCard(String title, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          title,
          style: GoogleFonts.urbanist(fontWeight: FontWeight.w500),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          _searchController.text = title;
        },
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(
            labelStyle: GoogleFonts.urbanist(fontSize: 14, fontWeight: FontWeight.w600),
            unselectedLabelStyle: GoogleFonts.urbanist(fontSize: 14, fontWeight: FontWeight.w500),
            indicatorColor: Theme.of(context).colorScheme.primary,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Colors.grey.shade600,
            tabs: [
              Tab(text: 'Users (${_userResults.length})'),
              Tab(text: 'Posts (${_postResults.length})'),
              Tab(text: 'Challenges (${_challengeResults.length})'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildUserResults(),
                _buildPostResults(),
                _buildChallengeResults(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserResults() {
    if (_userResults.isEmpty) {
      return Center(
        child: Text(
          'No users found',
          style: GoogleFonts.urbanist(color: Colors.grey.shade600),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _userResults.length,
      itemBuilder: (context, index) {
        final user = _userResults[index];
        return _buildUserCard(user);
      },
    );
  }

  Widget _buildUserCard(UserProfile user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          radius: 25,
          backgroundImage: user.profileImageUrl != null 
              ? NetworkImage(user.profileImageUrl!) 
              : null,
          child: user.profileImageUrl == null
              ? Text(
                  user.displayName[0].toUpperCase(),
                  style: GoogleFonts.urbanist(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                )
              : null,
        ),
        title: Text(
          user.displayName,
          style: GoogleFonts.urbanist(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          user.bio ?? 'No bio available',
          style: GoogleFonts.urbanist(color: Colors.grey.shade600),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          '${user.stats.totalWorkouts} workouts',
          style: GoogleFonts.urbanist(
            fontSize: 12,
            color: Colors.grey.shade500,
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProfileScreen(userId: user.uid),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPostResults() {
    if (_postResults.isEmpty) {
      return Center(
        child: Text(
          'No posts found',
          style: GoogleFonts.urbanist(color: Colors.grey.shade600),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _postResults.length,
      itemBuilder: (context, index) {
        final post = _postResults[index];
        return _buildPostCard(post);
      },
    );
  }

  Widget _buildPostCard(SocialPost post) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: post.profileImageUrl != null 
                      ? NetworkImage(post.profileImageUrl!) 
                      : null,
                  child: post.profileImageUrl == null
                      ? Text(post.displayName[0].toUpperCase())
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.displayName,
                        style: GoogleFonts.urbanist(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        post.timeAgo,
                        style: GoogleFonts.urbanist(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              post.content,
              style: GoogleFonts.urbanist(fontSize: 14),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.favorite, size: 16, color: Colors.red),
                const SizedBox(width: 4),
                Text('${post.likeCount}'),
                const SizedBox(width: 16),
                Icon(Icons.comment, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text('${post.commentCount}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengeResults() {
    if (_challengeResults.isEmpty) {
      return Center(
        child: Text(
          'No challenges found',
          style: GoogleFonts.urbanist(color: Colors.grey.shade600),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _challengeResults.length,
      itemBuilder: (context, index) {
        final challenge = _challengeResults[index];
        return _buildChallengeCard(challenge);
      },
    );
  }

  Widget _buildChallengeCard(Challenge challenge) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              challenge.title,
              style: GoogleFonts.urbanist(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              challenge.description,
              style: GoogleFonts.urbanist(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.people, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text('${challenge.participants.length} participants'),
                const Spacer(),
                Text(
                  '${challenge.target.values.first} ${challenge.exerciseType}',
                  style: GoogleFonts.urbanist(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscoverTab() {
    if (_isLoadingDiscover) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDiscoverSection(
            'Recommended Users',
            (_discoverContent['recommendedUsers'] as List<UserProfile>?) ?? [],
            (item) => _buildUserCard(item as UserProfile),
          ),
          const SizedBox(height: 24),
          _buildDiscoverSection(
            'Recent Activity',
            (_discoverContent['recentActivity'] as List<SocialPost>?) ?? [],
            (item) => _buildPostCard(item as SocialPost),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDiscoverSection(
            'Trending Users',
            (_discoverContent['trendingUsers'] as List<UserProfile>?) ?? [],
            (item) => _buildUserCard(item as UserProfile),
          ),
          const SizedBox(height: 24),
          _buildDiscoverSection(
            'Trending Posts',
            (_discoverContent['trendingPosts'] as List<SocialPost>?) ?? [],
            (item) => _buildPostCard(item as SocialPost),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoverSection<T>(
    String title,
    List<T> items,
    Widget Function(dynamic) itemBuilder,
  ) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.urbanist(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        ...items.take(5).map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: itemBuilder(item),
        )),
      ],
    );
  }
}
