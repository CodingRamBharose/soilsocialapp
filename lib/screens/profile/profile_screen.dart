import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:soilsocial/providers/auth_provider.dart';
import 'package:soilsocial/models/post_model.dart';
import 'package:soilsocial/services/post_service.dart';
import 'package:soilsocial/widgets/post_card.dart';
import 'package:soilsocial/config/theme.dart';
import 'package:soilsocial/l10n/app_localizations.dart';

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
    final l = AppLocalizations.of(context);
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.userModel;

    return RefreshIndicator(
      color: AppTheme.primaryGreen,
      onRefresh: () async {
        await authProvider.refreshUserProfile();
        await _loadPosts();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // LinkedIn-style profile header card
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  // Green banner
                  Container(
                    height: 80,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryGreen,
                          AppTheme.lightGreen,
                        ],
                      ),
                    ),
                  ),
                  // Avatar overlapping banner
                  Transform.translate(
                    offset: const Offset(0, -40),
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                          ),
                          child: CircleAvatar(
                            radius: 44,
                            backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
                            backgroundImage: user?.profilePicture != null
                                ? NetworkImage(user!.profilePicture!)
                                : null,
                            child: user?.profilePicture == null
                                ? Text(
                                    user?.name.isNotEmpty == true
                                        ? user!.name[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      fontSize: 32,
                                      color: AppTheme.primaryGreen,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          user?.name ?? '',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        if (user?.location != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.location_on, size: 14, color: AppTheme.textSecondary),
                                const SizedBox(width: 2),
                                Text(
                                  user!.location!,
                                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        if (user?.bio != null && user!.bio!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                            child: Text(
                              user.bio!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                            ),
                          ),
                        const SizedBox(height: 16),
                        // Stats row
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _StatItem(
                                value: '${user?.connections.length ?? 0}',
                                label: l.translate('connections'),
                              ),
                              Container(height: 32, width: 1, color: AppTheme.dividerColor),
                              _StatItem(value: '${_posts.length}', label: l.translate('posts')),
                              Container(height: 32, width: 1, color: AppTheme.dividerColor),
                              _StatItem(
                                value: '${user?.groups.length ?? 0}',
                                label: l.translate('groups'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Action buttons
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => context.push('/profile/edit'),
                                  child: Text(l.translate('editProfile')),
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton(
                                onPressed: () => authProvider.signOut(),
                                child: Text(l.translate('signOut')),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Crops & Techniques section
            if (user != null &&
                (user.cropsGrown.isNotEmpty || user.farmingTechniques.isNotEmpty))
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 8),
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (user.cropsGrown.isNotEmpty) ...[
                      Text(
                        l.translate('cropsGrown'),
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: user.cropsGrown.map((c) => Chip(label: Text(c))).toList(),
                      ),
                    ],
                    if (user.farmingTechniques.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        l.translate('farmingTechniques'),
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: user.farmingTechniques.map((t) => Chip(label: Text(t))).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            // My Posts section
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 8),
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                l.translate('myPosts'),
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppTheme.textPrimary),
              ),
            ),
            const Divider(height: 1),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(color: AppTheme.primaryGreen),
              )
            else if (_posts.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  l.translate('noPosts'),
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
              )
            else
              ..._posts.map(
                (post) => Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: PostCard(
                    post: post,
                    currentUserId: authProvider.firebaseUser?.uid ?? '',
                    showDeleteOption: true,
                    onRefresh: _loadPosts,
                  ),
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
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryGreen,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}
