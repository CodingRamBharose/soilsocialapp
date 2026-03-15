import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:soilsocial/providers/auth_provider.dart';
import 'package:soilsocial/providers/language_provider.dart';
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

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final PostService _postService = PostService();
  List<PostModel> _posts = [];
  List<PostModel> _likedPosts = [];
  bool _isLoading = true;
  bool _isLikedLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1 && _isLikedLoading) {
        _loadLikedPosts();
      }
    });
    _loadPosts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

  Future<void> _loadLikedPosts() async {
    final authProvider = context.read<AuthProvider>();
    final uid = authProvider.firebaseUser?.uid;
    if (uid == null) return;
    setState(() => _isLikedLoading = true);
    try {
      _likedPosts = await _postService.getLikedPosts(uid);
    } catch (_) {}
    if (mounted) setState(() => _isLikedLoading = false);
  }

  Future<void> _refreshAll() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.refreshUserProfile();
    await Future.wait([_loadPosts(), _loadLikedPosts()]);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.userModel;

    return RefreshIndicator(
      color: AppTheme.primaryGreen,
      onRefresh: _refreshAll,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // LinkedIn-style profile header card
            _buildProfileHeader(context, l, authProvider, user),

            // Crops & Techniques section
            if (user != null &&
                (user.cropsGrown.isNotEmpty ||
                    user.farmingTechniques.isNotEmpty))
              _buildCropsSection(l, user),

            // Activity section with tabs
            const SizedBox(height: 8),
            _buildActivitySection(l, authProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    AppLocalizations l,
    AuthProvider authProvider,
    dynamic user,
  ) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Green banner
          Container(
            height: 80,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryGreen, AppTheme.lightGreen],
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
                    backgroundColor:
                        AppTheme.primaryGreen.withValues(alpha: 0.1),
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
                        const Icon(
                          Icons.location_on,
                          size: 14,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          user!.location!,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                          ),
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
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
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
                      Container(
                        height: 32,
                        width: 1,
                        color: AppTheme.dividerColor,
                      ),
                      _StatItem(
                        value: '${_posts.length}',
                        label: l.translate('posts'),
                      ),
                      Container(
                        height: 32,
                        width: 1,
                        color: AppTheme.dividerColor,
                      ),
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
                      const SizedBox(width: 8),
                      // Language change button
                      OutlinedButton(
                        onPressed: () => context.push('/settings/language'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.language, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              context
                                          .watch<LanguageProvider>()
                                          .locale
                                          .languageCode ==
                                      'pa'
                                  ? 'ਪੰ'
                                  : 'EN',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
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
        ],
      ),
    );
  }

  Widget _buildCropsSection(AppLocalizations l, dynamic user) {
    return Container(
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
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children:
                  user.cropsGrown.map<Widget>((c) => Chip(label: Text(c))).toList(),
            ),
          ],
          if (user.farmingTechniques.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              l.translate('farmingTechniques'),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: user.farmingTechniques
                  .map<Widget>((t) => Chip(label: Text(t)))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActivitySection(AppLocalizations l, AuthProvider authProvider) {
    final currentUserId = authProvider.firebaseUser?.uid ?? '';

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(
              l.translate('activity'),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppTheme.textPrimary,
              ),
            ),
          ),

          // Tab bar
          TabBar(
            controller: _tabController,
            labelColor: AppTheme.primaryGreen,
            unselectedLabelColor: AppTheme.textSecondary,
            indicatorColor: AppTheme.primaryGreen,
            indicatorWeight: 2,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            unselectedLabelStyle: const TextStyle(fontSize: 14),
            tabs: [
              Tab(text: l.translate('posts')),
              Tab(text: l.translate('likedPosts')),
            ],
          ),

          // Tab content
          AnimatedBuilder(
            animation: _tabController,
            builder: (context, _) {
              if (_tabController.index == 0) {
                return _buildPostsTab(l, currentUserId);
              } else {
                return _buildLikedPostsTab(l, currentUserId);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPostsTab(AppLocalizations l, String currentUserId) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryGreen),
        ),
      );
    }

    if (_posts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.post_add, size: 48, color: Colors.grey[300]),
              const SizedBox(height: 12),
              Text(
                l.translate('noPosts'),
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => context.push('/post/create'),
                icon: const Icon(Icons.add, size: 18),
                label: Text(l.translate('createPost')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryGreen,
                  side: const BorderSide(color: AppTheme.primaryGreen),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _posts
          .map(
            (post) => Column(
              children: [
                PostCard(
                  post: post,
                  currentUserId: currentUserId,
                  showDeleteOption: true,
                  onRefresh: _loadPosts,
                ),
                const SizedBox(height: 8),
              ],
            ),
          )
          .toList(),
    );
  }

  Widget _buildLikedPostsTab(AppLocalizations l, String currentUserId) {
    if (_isLikedLoading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryGreen),
        ),
      );
    }

    if (_likedPosts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.thumb_up_outlined, size: 48, color: Colors.grey[300]),
              const SizedBox(height: 12),
              Text(
                l.translate('noLikedPosts'),
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _likedPosts
          .map(
            (post) => Column(
              children: [
                PostCard(
                  post: post,
                  currentUserId: currentUserId,
                  onRefresh: _loadLikedPosts,
                ),
                const SizedBox(height: 8),
              ],
            ),
          )
          .toList(),
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
