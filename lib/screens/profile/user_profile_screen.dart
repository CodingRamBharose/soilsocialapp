import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:soilsocial/providers/auth_provider.dart';
import 'package:soilsocial/models/user_model.dart';
import 'package:soilsocial/models/post_model.dart';
import 'package:soilsocial/services/user_service.dart';
import 'package:soilsocial/services/post_service.dart';
import 'package:soilsocial/widgets/post_card.dart';
import 'package:soilsocial/config/theme.dart';
import 'package:soilsocial/l10n/app_localizations.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;
  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _userService = UserService();
  final _postService = PostService();
  UserModel? _user;
  List<PostModel> _posts = [];
  bool _isLoading = true;
  String _connectionStatus = 'none';
  bool _isFollowing = false;
  bool _isFollowLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _user = await _userService.getUser(widget.userId);
      _posts = await _postService.getUserPosts(widget.userId);
      final currentUser = context.read<AuthProvider>().userModel;
      if (currentUser != null) {
        _connectionStatus = _userService.getConnectionStatus(
          currentUser,
          widget.userId,
        );
        _isFollowing = _userService.isFollowing(currentUser, widget.userId);
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _handleConnection() async {
    final currentUserId = context.read<AuthProvider>().firebaseUser?.uid;
    if (currentUserId == null) return;

    if (_connectionStatus == 'none') {
      await _userService.sendConnectionRequest(currentUserId, widget.userId);
      setState(() => _connectionStatus = 'pending');
      await context.read<AuthProvider>().refreshUserProfile();
    } else if (_connectionStatus == 'received') {
      await _userService.acceptConnectionRequest(currentUserId, widget.userId);
      setState(() => _connectionStatus = 'connected');
      await context.read<AuthProvider>().refreshUserProfile();
    }
  }

  Future<void> _handleFollow() async {
    final currentUserId = context.read<AuthProvider>().firebaseUser?.uid;
    if (currentUserId == null) return;

    setState(() => _isFollowLoading = true);
    try {
      if (_isFollowing) {
        await _userService.unfollowUser(currentUserId, widget.userId);
      } else {
        await _userService.followUser(currentUserId, widget.userId);
      }
      _isFollowing = !_isFollowing;
      _user = await _userService.getUser(widget.userId);
      await context.read<AuthProvider>().refreshUserProfile();
    } catch (_) {}
    if (mounted) setState(() => _isFollowLoading = false);
  }

  void _showConnectionsSheet() {
    if (_user == null || _user!.connections.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _PeopleListSheet(
        title: AppLocalizations.of(context).translate('connections'),
        fetchUsers: () => _userService.getConnections(_user!.uid),
      ),
    );
  }

  void _showFollowersSheet() {
    if (_user == null || _user!.followers.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _PeopleListSheet(
        title: AppLocalizations.of(context).translate('followers'),
        fetchUsers: () => _userService.getFollowers(_user!.uid),
      ),
    );
  }

  void _showFollowingSheet() {
    if (_user == null || _user!.following.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _PeopleListSheet(
        title: AppLocalizations.of(context).translate('following'),
        fetchUsers: () => _userService.getFollowing(_user!.uid),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final currentUserId =
        context.read<AuthProvider>().firebaseUser?.uid ?? '';
    final isOwnProfile = widget.userId == currentUserId;

    return Scaffold(
      appBar: AppBar(
        title: Text(_user?.name ?? l.translate('profile')),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppTheme.dividerColor, height: 1),
        ),
      ),
      body: _isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(color: AppTheme.primaryGreen),
            )
          : _user == null
              ? Center(child: Text(l.translate('userNotFound')))
              : RefreshIndicator(
                  color: AppTheme.primaryGreen,
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        _buildProfileHeader(l, currentUserId),

                        // About section
                        if (_user!.bio != null && _user!.bio!.isNotEmpty)
                          _buildAboutSection(l),

                        // Farm Details section
                        if (_user!.farmSize != null ||
                            _user!.farmingExperience != null ||
                            _user!.farmingType != null)
                          _buildFarmDetailsSection(l),

                        // Farming Techniques section
                        if (_user!.farmingTechniques.isNotEmpty)
                          _buildTechniquesSection(l),

                        // Posts section
                        const SizedBox(height: 8),
                        _buildPostsSection(l, currentUserId, isOwnProfile),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildProfileHeader(AppLocalizations l, String currentUserId) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Container(
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryGreen, AppTheme.lightGreen],
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -40),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: CircleAvatar(
                    radius: 45,
                    backgroundColor:
                        AppTheme.primaryGreen.withValues(alpha: 0.1),
                    backgroundImage: _user!.profilePicture != null
                        ? NetworkImage(_user!.profilePicture!)
                        : null,
                    child: _user!.profilePicture == null
                        ? Text(
                            _user!.name.isNotEmpty
                                ? _user!.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 32,
                              color: AppTheme.primaryGreen,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _user!.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                if (_user!.location != null && _user!.location!.isNotEmpty)
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
                        Text(
                          _user!.location!,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Farming identity tags in header
                _buildFarmingTags(l),

                const SizedBox(height: 16),
                // Stats row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _StatItem(
                        value: '${_user!.connections.length}',
                        label: l.translate('connections'),
                        onTap: _showConnectionsSheet,
                      ),
                      Container(
                        width: 1,
                        height: 30,
                        color: AppTheme.dividerColor,
                      ),
                      _StatItem(
                        value: '${_user!.followers.length}',
                        label: l.translate('followers'),
                        onTap: _showFollowersSheet,
                      ),
                      Container(
                        width: 1,
                        height: 30,
                        color: AppTheme.dividerColor,
                      ),
                      _StatItem(
                        value: '${_user!.following.length}',
                        label: l.translate('following'),
                        onTap: _showFollowingSheet,
                      ),
                      Container(
                        width: 1,
                        height: 30,
                        color: AppTheme.dividerColor,
                      ),
                      _StatItem(
                        value: '${_posts.length}',
                        label: l.translate('posts'),
                      ),
                    ],
                  ),
                ),
                // Connection + Follow buttons
                if (widget.userId != currentUserId) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildConnectionButton(l),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildFollowButton(l),
                        ),
                      ],
                    ),
                  ),
                  // Message button — always visible
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => context.push(
                          '/messages/${widget.userId}',
                          extra: {'name': _user!.name},
                        ),
                        icon: const Icon(Icons.message_outlined, size: 18),
                        label: Text(l.translate('message')),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryGreen,
                          side: const BorderSide(
                            color: AppTheme.primaryGreen,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFarmingTags(AppLocalizations l) {
    final tags = <_TagInfo>[];

    if (_user!.farmingType != null && _user!.farmingType!.isNotEmpty) {
      tags.add(_TagInfo(Icons.agriculture, _user!.farmingType!));
    }
    if (_user!.farmSize != null && _user!.farmSize!.isNotEmpty) {
      tags.add(_TagInfo(Icons.landscape, _user!.farmSize!));
    }
    for (final crop in _user!.cropsGrown) {
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

  Widget _buildAboutSection(AppLocalizations l) {
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
            _user!.bio!,
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

  Widget _buildFarmDetailsSection(AppLocalizations l) {
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
          if (_user!.farmSize != null && _user!.farmSize!.isNotEmpty)
            _buildDetailRow(
              Icons.crop_square,
              l.translate('farmSize'),
              _user!.farmSize!,
            ),
          if (_user!.farmingType != null && _user!.farmingType!.isNotEmpty)
            _buildDetailRow(
              Icons.agriculture,
              l.translate('farmingType'),
              _user!.farmingType!,
            ),
          if (_user!.farmingExperience != null &&
              _user!.farmingExperience!.isNotEmpty)
            _buildDetailRow(
              Icons.access_time,
              l.translate('farmingExperience'),
              _user!.farmingExperience!,
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

  Widget _buildTechniquesSection(AppLocalizations l) {
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
            children: _user!.farmingTechniques
                .map<Widget>(
                  (t) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(
                      t,
                      style: const TextStyle(
                        color: AppTheme.primaryGreen,
                        fontSize: 13,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsSection(
      AppLocalizations l, String currentUserId, bool isOwnProfile) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Text(
                  l.translate('activity'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_posts.length} ${l.translate('posts').toLowerCase()}',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          if (_posts.isEmpty)
            Padding(
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
                  ],
                ),
              ),
            )
          else
            ..._posts.map(
              (post) => Column(
                children: [
                  PostCard(
                    post: post,
                    currentUserId: currentUserId,
                    showDeleteOption: isOwnProfile,
                    onRefresh: _loadData,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildConnectionButton(AppLocalizations l) {
    switch (_connectionStatus) {
      case 'connected':
        return OutlinedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.check, size: 18),
          label: Text(l.translate('connected')),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.primaryGreen,
            side: const BorderSide(color: AppTheme.cardBorder),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        );
      case 'pending':
        return OutlinedButton(
          onPressed: null,
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          child: Text(l.translate('requestSent')),
        );
      case 'received':
        return FilledButton(
          onPressed: _handleConnection,
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.primaryGreen,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          child: Text(l.translate('acceptRequest')),
        );
      default:
        return FilledButton.icon(
          onPressed: _handleConnection,
          icon: const Icon(Icons.person_add, size: 18),
          label: Text(l.translate('connect')),
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.primaryGreen,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        );
    }
  }

  Widget _buildFollowButton(AppLocalizations l) {
    if (_isFollowLoading) {
      return OutlinedButton(
        onPressed: null,
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: const SizedBox(
          height: 18,
          width: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppTheme.primaryGreen,
          ),
        ),
      );
    }

    if (_isFollowing) {
      return OutlinedButton.icon(
        onPressed: _handleFollow,
        icon: const Icon(Icons.person_remove, size: 18),
        label: Text(l.translate('unfollow')),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.textSecondary,
          side: const BorderSide(color: AppTheme.cardBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      );
    }

    return FilledButton.icon(
      onPressed: _handleFollow,
      icon: const Icon(Icons.person_add_alt_1, size: 18),
      label: Text(l.translate('follow')),
      style: FilledButton.styleFrom(
        backgroundColor: AppTheme.primaryGreen,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
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
          style:
              const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
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
