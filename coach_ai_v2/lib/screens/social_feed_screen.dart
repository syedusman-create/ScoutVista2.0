import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/social_service.dart';
import '../services/notification_service.dart';
import '../models/social_post.dart';
import 'exercise_selection_screen.dart';
import 'notifications_screen.dart';

class SocialFeedScreen extends StatefulWidget {
  const SocialFeedScreen({super.key});

  @override
  State<SocialFeedScreen> createState() => _SocialFeedScreenState();
}

class _SocialFeedScreenState extends State<SocialFeedScreen> {
  List<SocialPost> _posts = [];
  bool _isLoading = true;
  int _unreadNotificationCount = 0;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadPosts();
    _loadUnreadCount();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
      _loadMorePosts();
    }
  }

  Future<void> _loadPosts() async {
    setState(() => _isLoading = true);
    
    try {
      final posts = await SocialService.getFeedPosts();
      setState(() {
        _posts = posts;
      });
    } catch (e) {
      // Handle error
      print('Error loading posts: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMorePosts() async {
    try {
      final morePosts = await SocialService.getFeedPosts(limit: 10);
      setState(() {
        _posts.addAll(morePosts);
      });
    } catch (e) {
      // Handle error
      print('Error loading more posts: $e');
    }
  }

  Future<void> _loadUnreadCount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final count = await NotificationService.getUnreadCount(user.uid);
      if (mounted) {
        setState(() {
          _unreadNotificationCount = count;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'ScoutVista',
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
                  ).then((_) => _loadUnreadCount()); // Refresh count when returning
                },
              ),
              if (_unreadNotificationCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _unreadNotificationCount > 99 ? '99+' : _unreadNotificationCount.toString(),
                      style: GoogleFonts.urbanist(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreatePostDialog,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadPosts,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _posts.length + 1, // +1 for create post card
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildCreatePostCard();
                  }
                  final post = _posts[index - 1];
                  return _buildPostCard(post);
                },
              ),
      ),
    );
  }

  Widget _buildCreatePostCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.blue.shade100,
                  child: Icon(
                    Icons.person,
                    color: Colors.blue.shade600,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Share your workout achievement...',
                    style: GoogleFonts.urbanist(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.camera_alt, color: Colors.grey.shade600),
                  onPressed: _showCreatePostDialog,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ExerciseSelectionScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.fitness_center, size: 18),
                    label: const Text('Start Workout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade50,
                      foregroundColor: Colors.blue.shade700,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showCreatePostDialog,
                    icon: const Icon(Icons.emoji_events, size: 18),
                    label: const Text('Share Achievement'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade50,
                      foregroundColor: Colors.amber.shade700,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostCard(SocialPost post) {
    final user = FirebaseAuth.instance.currentUser;
    final isLiked = user != null && post.likes.contains(user.uid);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.blue.shade100,
                  backgroundImage: post.profileImageUrl != null 
                      ? NetworkImage(post.profileImageUrl!) 
                      : null,
                  child: post.profileImageUrl == null
                      ? Text(
                          post.displayName[0].toUpperCase(),
                          style: GoogleFonts.urbanist(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.displayName,
                        style: GoogleFonts.urbanist(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _formatTimeAgo(post.createdAt),
                        style: GoogleFonts.urbanist(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.more_vert, color: Colors.grey.shade400),
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Post Type Badge
            if (post.postType != 'general') ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getPostTypeColor(post.postType),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getPostTypeLabel(post.postType),
                  style: GoogleFonts.urbanist(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            
            // Content
            Text(
              post.content,
              style: GoogleFonts.urbanist(
                fontSize: 16,
                height: 1.4,
              ),
            ),
            
            // Workout Data
            if (post.workoutData != null) ...[
              const SizedBox(height: 12),
              _buildWorkoutData(post.workoutData!),
            ],
            
            // Image
            if (post.imageUrl != null) ...[
              const SizedBox(height: 12),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    post.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image,
                              size: 48,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Image not available',
                              style: GoogleFonts.urbanist(
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 12),
            
            // Actions
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? Colors.red : Colors.grey.shade600,
                  ),
                  onPressed: () => _toggleLike(post),
                ),
                Text(
                  '${post.likeCount}',
                  style: GoogleFonts.urbanist(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: Icon(
                    Icons.comment_outlined,
                    color: Colors.grey.shade600,
                  ),
                  onPressed: () => _showCommentsDialog(post),
                ),
                Text(
                  '${post.commentCount}',
                  style: GoogleFonts.urbanist(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: Icon(
                    Icons.share_outlined,
                    color: Colors.grey.shade600,
                  ),
                  onPressed: () => _sharePost(post),
                ),
                Text(
                  '${post.shareCount}',
                  style: GoogleFonts.urbanist(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutData(Map<String, dynamic> workoutData) {
    final exerciseType = workoutData['exerciseType'] as String? ?? 'Unknown';
    final results = workoutData['results'] as Map<String, dynamic>? ?? {};
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getExerciseIcon(exerciseType),
                size: 20,
                color: Colors.blue.shade700,
              ),
              const SizedBox(width: 8),
              Text(
                _getExerciseDisplayName(exerciseType),
                style: GoogleFonts.urbanist(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              if (results.containsKey('totalReps'))
                _buildWorkoutMetric('Reps', '${results['totalReps']}'),
              if (results.containsKey('totalDistanceKm'))
                _buildWorkoutMetric('Distance', '${(results['totalDistanceKm'] as double).toStringAsFixed(2)} km'),
              if (results.containsKey('averageFormScore'))
                _buildWorkoutMetric('Form', '${(results['averageFormScore'] as double).toStringAsFixed(1)}%'),
              if (results.containsKey('videoDuration'))
                _buildWorkoutMetric('Duration', '${results['videoDuration']}s'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutMetric(String label, String value) {
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
            color: Colors.blue.shade600,
          ),
        ),
      ],
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Color _getPostTypeColor(String postType) {
    switch (postType) {
      case 'workout':
        return Colors.blue;
      case 'achievement':
        return Colors.amber;
      case 'challenge':
        return Colors.purple;
      case 'general':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getPostTypeLabel(String postType) {
    switch (postType) {
      case 'workout':
        return 'WORKOUT';
      case 'achievement':
        return 'ACHIEVEMENT';
      case 'challenge':
        return 'CHALLENGE';
      case 'general':
        return 'POST';
      default:
        return 'POST';
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

  void _toggleLike(SocialPost post) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      if (post.likes.contains(user.uid)) {
        await SocialService.unlikePost(post.id);
      } else {
        await SocialService.likePost(post.id);
      }
      
      // Refresh the post
      _loadPosts();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update like: $e')),
      );
    }
  }

  void _showCommentsDialog(SocialPost post) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Comments', style: GoogleFonts.urbanist(fontWeight: FontWeight.w600)),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: post.comments.isEmpty
              ? Center(
                  child: Text(
                    'No comments yet',
                    style: GoogleFonts.urbanist(color: Colors.grey.shade600),
                  ),
                )
              : ListView.builder(
                  itemCount: post.comments.length,
                  itemBuilder: (context, index) {
                    final comment = post.comments[index];
                    return ListTile(
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.blue.shade100,
                        child: Text(
                          comment.displayName[0].toUpperCase(),
                          style: GoogleFonts.urbanist(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                      title: Text(
                        comment.displayName,
                        style: GoogleFonts.urbanist(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        comment.content,
                        style: GoogleFonts.urbanist(fontSize: 14),
                      ),
                      trailing: Text(
                        _formatTimeAgo(comment.createdAt),
                        style: GoogleFonts.urbanist(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Add a comment...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                SocialService.addComment(post.id, value.trim());
                Navigator.of(context).pop();
                _loadPosts();
              }
            },
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _sharePost(SocialPost post) async {
    try {
      await SocialService.sharePost(post.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post shared!')),
      );
      _loadPosts();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to share post: $e')),
      );
    }
  }

  void _showCreatePostDialog() {
    final contentController = TextEditingController();
    String selectedPostType = 'general';
    String? imageUrl;
    String? videoUrl;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            'Create Post',
            style: GoogleFonts.urbanist(fontWeight: FontWeight.w600),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Post type selection
                DropdownButtonFormField<String>(
                  value: selectedPostType,
                  decoration: InputDecoration(
                    labelText: 'Post Type',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'general', child: Text('General Post')),
                    DropdownMenuItem(value: 'workout', child: Text('Workout Share')),
                    DropdownMenuItem(value: 'achievement', child: Text('Achievement')),
                    DropdownMenuItem(value: 'challenge', child: Text('Challenge')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedPostType = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                // Content input
                TextField(
                  controller: contentController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'What\'s on your mind?',
                    hintText: 'Share your fitness journey...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Media options
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        // TODO: Implement image picker
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Image picker coming soon!')),
                        );
                      },
                      icon: const Icon(Icons.image),
                      tooltip: 'Add Image',
                    ),
                    IconButton(
                      onPressed: () {
                        // TODO: Implement video picker
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Video picker coming soon!')),
                        );
                      },
                      icon: const Icon(Icons.videocam),
                      tooltip: 'Add Video',
                    ),
                    IconButton(
                      onPressed: () {
                        // TODO: Implement workout sharing
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Workout sharing coming soon!')),
                        );
                      },
                      icon: const Icon(Icons.fitness_center),
                      tooltip: 'Share Workout',
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (contentController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter some content')),
                  );
                  return;
                }

                try {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null) return;

                  final post = SocialPost(
                    id: '',
                    userId: user.uid,
                    displayName: user.displayName ?? 'Fitness Enthusiast',
                    profileImageUrl: user.photoURL,
                    content: contentController.text.trim(),
                    imageUrl: imageUrl,
                    videoUrl: videoUrl,
                    postType: selectedPostType,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                    timeAgo: 'Just now',
                    tags: _extractHashtags(contentController.text.trim()),
                  );

                  await SocialService.createPost(post);
                  
                  Navigator.of(context).pop();
                  _loadPosts();
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Post created successfully!')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to create post: $e')),
                  );
                }
              },
              child: const Text('Post'),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _extractHashtags(String content) {
    final hashtagRegex = RegExp(r'#\w+');
    return hashtagRegex.allMatches(content).map((match) => match.group(0)!.substring(1)).toList();
  }
}
