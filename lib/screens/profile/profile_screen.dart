import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:soilsocial/providers/auth_provider.dart';
import 'package:soilsocial/models/post_model.dart';
import 'package:soilsocial/services/post_service.dart';
import 'package:soilsocial/widgets/post_card.dart';
import 'package:soilsocial/config/theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final PostService _postService = PostService();
  List<PostModel> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    final authProvider = context.read<AuthProvider>();
    final uid = authProvider.firebaseUser?.uid;
    if (uid == null) return;
    setState(() => _isLoading = true);
    try {
      _posts = await _postService.getUserPosts(uid);
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.userModel;

    return RefreshIndicator(
      onRefresh: () async {
        await authProvider.refreshUserProfile();
        await _loadPosts();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: user?.profilePicture != null
                          ? NetworkImage(user!.profilePicture!)
                          : null,
                      child: user?.profilePicture == null
                          ? Text(
                              user?.name.isNotEmpty == true
                                  ? user!.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(fontSize: 36),
                            )
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user?.name ?? '',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (user?.location != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 16,
                              color: Colors.grey,
                            ),
                            Text(
                              user!.location!,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    if (user?.bio != null && user!.bio!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          user.bio!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _StatItem(
                          value: '${user?.connections.length ?? 0}',
                          label: 'Connections',
                        ),
                        _StatItem(value: '${_posts.length}', label: 'Posts'),
                        _StatItem(
                          value: '${user?.groups.length ?? 0}',
                          label: 'Groups',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => context.push('/profile/edit'),
                            child: const Text('Edit Profile'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () => authProvider.signOut(),
                          child: const Text('Sign Out'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Crops & Techniques
            if (user != null &&
                (user.cropsGrown.isNotEmpty ||
                    user.farmingTechniques.isNotEmpty))
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (user.cropsGrown.isNotEmpty) ...[
                        const Text(
                          'Crops Grown',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: user.cropsGrown
                              .map(
                                (c) => Chip(
                                  label: Text(c),
                                  backgroundColor: AppTheme.primaryGreen
                                      .withValues(alpha: 0.1),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                      if (user.farmingTechniques.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Farming Techniques',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: user.farmingTechniques
                              .map((t) => Chip(label: Text(t)))
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            // User Posts
            Text(
              'My Posts',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_isLoading)
              const CircularProgressIndicator()
            else if (_posts.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'No posts yet',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              )
            else
              ..._posts.map(
                (post) => PostCard(
                  post: post,
                  currentUserId: authProvider.firebaseUser?.uid ?? '',
                  showDeleteOption: true,
                  onRefresh: _loadPosts,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }
}
