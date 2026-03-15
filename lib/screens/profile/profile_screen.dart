import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:soilsocial/providers/auth_provider.dart';
import 'package:soilsocial/providers/language_provider.dart';
import 'package:soilsocial/models/post_model.dart';
import 'package:soilsocial/models/user_model.dart';
import 'package:soilsocial/services/post_service.dart';
import 'package:soilsocial/services/user_service.dart';
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
  final UserService _userService = UserService();
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

  void _showConnectionsSheet() {
    final user = context.read<AuthProvider>().userModel;
    if (user == null || user.connections.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _PeopleListSheet(
        title: AppLocalizations.of(context).translate('connections'),
        fetchUsers: () => _userService.getConnections(user.uid),
      ),
    );
  }

  void _showFollowersSheet() {
    final user = context.read<AuthProvider>().userModel;
    if (user == null || user.followers.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _PeopleListSheet(
        title: AppLocalizations.of(context).translate('followers'),
        fetchUsers: () => _userService.getFollowers(user.uid),
      ),
    );
  }

  void _showFollowingSheet() {
    final user = context.read<AuthProvider>().userModel;
    if (user == null || user.following.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _PeopleListSheet(
        title: AppLocalizations.of(context).translate('following'),
        fetchUsers: () => _userService.getFollowing(user.uid),
      ),
    );
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
            _buildProfileHeader(context, l, authProvider, user),

            // About section
            if (user?.bio != null && user!.bio!.isNotEmpty)
              _buildAboutSection(l, user),

            // Farm Details section
            if (user != null &&
                (user.farmSize != null ||
                    user.farmingExperience != null ||
                    user.farmingType != null))
              _buildFarmDetailsSection(l, user),

            // Farming Techniques section
            if (user != null && user.farmingTechniques.isNotEmpty)
              _buildTechniquesSection(l, user),

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
    UserModel? user,
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
                if (user?.location != null && user!.location!.isNotEmpty)
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
                          user.location!,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Farming identity tags in header
                if (user != null)
                  _buildFarmingTags(l, user),

                const SizedBox(height: 16),
                // Stats row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _StatItem(
                        value: '${user?.connections.length ?? 0}',
                        label: l.translate('connections'),
                        onTap: _showConnectionsSheet,
                      ),
                      Container(
                        height: 32,
                        width: 1,
                        color: AppTheme.dividerColor,
                      ),
                      _StatItem(
                        value: '${user?.followers.length ?? 0}',
                        label: l.translate('followers'),
                        onTap: _showFollowersSheet,
                      ),
                      Container(
                        height: 32,
                        width: 1,
                        color: AppTheme.dividerColor,
                      ),
                      _StatItem(
                        value: '${user?.following.length ?? 0}',
                        label: l.translate('following'),
                        onTap: _showFollowingSheet,
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
                      OutlinedButton(
                        onPressed: () => context.push('/settings/language'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
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

  /// Crops + Farm Size + Farming Type shown as tags right in the header
  Widget _buildFarmingTags(AppLocalizations l, UserModel user) {
    final tags = <_TagInfo>[];

    if (user.farmingType != null && user.farmingType!.isNotEmpty) {
      tags.add(_TagInfo(Icons.agriculture, user.farmingType!));
    }
    if (user.farmSize != null && user.farmSize!.isNotEmpty) {
      tags.add(_TagInfo(Icons.landscape, user.farmSize!));
    }
    for (final crop in user.cropsGrown) {
      tags.add(_TagInfo(Icons.grass, crop));
    }

    if (tags.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        alignment: WrapAlignment.center,
        children: tags
            .map(
              (tag) => Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(tag.icon, size: 14, color: AppTheme.primaryGreen),
                    const SizedBox(width: 4),
                    Text(
                      tag.label,
                      style: const TextStyle(
                        color: AppTheme.primaryGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildAboutSection(AppLocalizations l, UserModel user) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline,
                  size: 18, color: AppTheme.primaryGreen),
              const SizedBox(width: 8),
              Text(
                l.translate('about'),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            user.bio!,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFarmDetailsSection(AppLocalizations l, UserModel user) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.landscape_outlined,
                  size: 18, color: AppTheme.primaryGreen),
              const SizedBox(width: 8),
              Text(
                l.translate('farmDetails'),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (user.farmSize != null && user.farmSize!.isNotEmpty)
            _buildDetailRow(
              Icons.crop_square,
              l.translate('farmSize'),
              user.farmSize!,
            ),
          if (user.farmingType != null && user.farmingType!.isNotEmpty)
            _buildDetailRow(
              Icons.agriculture,
              l.translate('farmingType'),
              user.farmingType!,
            ),
          if (user.farmingExperience != null &&
              user.farmingExperience!.isNotEmpty)
            _buildDetailRow(
              Icons.access_time,
              l.translate('farmingExperience'),
              user.farmingExperience!,
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.textSecondary),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechniquesSection(AppLocalizations l, UserModel user) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.build_outlined,
                  size: 18, color: AppTheme.primaryGreen),
              const SizedBox(width: 8),
              Text(
                l.translate('farmingTechniques'),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: user.farmingTechniques
                .map<Widget>(
                  (t) => Chip(label: Text(t)),
                )
                .toList(),
          ),
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

class _TagInfo {
  final IconData icon;
  final String label;
  const _TagInfo(this.icon, this.label);
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final VoidCallback? onTap;
  const _StatItem({required this.value, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final content = Column(
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

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: content);
    }
    return content;
  }
}

class _PeopleListSheet extends StatelessWidget {
  final String title;
  final Future<List<UserModel>> Function() fetchUsers;

  const _PeopleListSheet({
    required this.title,
    required this.fetchUsers,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: FutureBuilder<List<UserModel>>(
                future: fetchUsers(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.primaryGreen),
                    );
                  }

                  final users = snapshot.data ?? [];
                  if (users.isEmpty) {
                    return const Center(child: Text('No users'));
                  }

                  return ListView.builder(
                    controller: scrollController,
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final u = users[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              AppTheme.primaryGreen.withValues(alpha: 0.1),
                          backgroundImage: u.profilePicture != null
                              ? NetworkImage(u.profilePicture!)
                              : null,
                          child: u.profilePicture == null
                              ? Text(
                                  u.name.isNotEmpty
                                      ? u.name[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                      color: AppTheme.primaryGreen),
                                )
                              : null,
                        ),
                        title: Text(
                          u.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: u.location != null
                            ? Text(u.location!,
                                style: const TextStyle(fontSize: 12))
                            : null,
                        onTap: () {
                          Navigator.pop(context);
                          context.push('/user/${u.uid}');
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
