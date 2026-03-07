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
        _connectionStatus =
            _userService.getConnectionStatus(currentUser, widget.userId);
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

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final currentUserId = context.read<AuthProvider>().firebaseUser?.uid ?? '';

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
              child: CircularProgressIndicator(color: AppTheme.primaryGreen))
          : _user == null
              ? Center(child: Text(l.translate('userNotFound')))
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      // Banner + avatar
                      Container(
                        color: Colors.white,
                        child: Column(
                          children: [
                            Container(
                              height: 80,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppTheme.primaryGreen,
                                    AppTheme.lightGreen,
                                  ],
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
                                      border: Border.all(
                                          color: Colors.white, width: 3),
                                    ),
                                    child: CircleAvatar(
                                      radius: 45,
                                      backgroundColor: AppTheme.primaryGreen
                                          .withValues(alpha: 0.1),
                                      backgroundImage:
                                          _user!.profilePicture != null
                                              ? NetworkImage(
                                                  _user!.profilePicture!)
                                              : null,
                                      child: _user!.profilePicture == null
                                          ? Text(
                                              _user!.name.isNotEmpty
                                                  ? _user!.name[0]
                                                      .toUpperCase()
                                                  : '?',
                                              style: const TextStyle(
                                                  fontSize: 32,
                                                  color:
                                                      AppTheme.primaryGreen),
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
                                        color: AppTheme.textPrimary),
                                  ),
                                  if (_user!.location != null)
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.location_on,
                                            size: 14,
                                            color: AppTheme.textSecondary),
                                        Text(_user!.location!,
                                            style: const TextStyle(
                                                color: AppTheme.textSecondary,
                                                fontSize: 13)),
                                      ],
                                    ),
                                  if (_user!.bio != null &&
                                      _user!.bio!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          24, 8, 24, 0),
                                      child: Text(
                                        _user!.bio!,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            color: AppTheme.textSecondary),
                                      ),
                                    ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      _StatItem(
                                          value:
                                              '${_user!.connections.length}',
                                          label: l.translate('connections')),
                                      Container(
                                          width: 1,
                                          height: 30,
                                          color: AppTheme.dividerColor,
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 24)),
                                      _StatItem(
                                          value: '${_posts.length}',
                                          label: l.translate('posts')),
                                    ],
                                  ),
                                  if (widget.userId != currentUserId)
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          16, 16, 16, 0),
                                      child: Row(
                                        children: [
                                          Expanded(
                                              child:
                                                  _buildConnectionButton(l)),
                                          if (_connectionStatus ==
                                              'connected') ...[
                                            const SizedBox(width: 8),
                                            OutlinedButton.icon(
                                              onPressed: () => context.push(
                                                '/messages/${widget.userId}',
                                                extra: {
                                                  'name': _user!.name
                                                },
                                              ),
                                              icon: const Icon(
                                                  Icons.message_outlined,
                                                  size: 18),
                                              label: Text(
                                                  l.translate('message')),
                                              style:
                                                  OutlinedButton.styleFrom(
                                                foregroundColor:
                                                    AppTheme.primaryGreen,
                                                side: const BorderSide(
                                                    color: AppTheme
                                                        .primaryGreen),
                                                shape:
                                                    RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(
                                                                    24)),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_user!.cropsGrown.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          color: Colors.white,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l.translate('cropsGrown'),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children: _user!.cropsGrown
                                    .map((c) => Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryGreen
                                                .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(24),
                                          ),
                                          child: Text(c,
                                              style: const TextStyle(
                                                  color:
                                                      AppTheme.primaryGreen,
                                                  fontSize: 13)),
                                        ))
                                    .toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (_posts.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          color: Colors.white,
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Text(l.translate('posts'),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary)),
                        ),
                        ..._posts.map((post) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: PostCard(
                                  post: post,
                                  currentUserId: currentUserId),
                            )),
                      ],
                    ],
                  ),
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
                borderRadius: BorderRadius.circular(24)),
          ),
        );
      case 'pending':
        return OutlinedButton(
          onPressed: null,
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24)),
          ),
          child: Text(l.translate('requestSent')),
        );
      case 'received':
        return FilledButton(
          onPressed: _handleConnection,
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.primaryGreen,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24)),
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
                borderRadius: BorderRadius.circular(24)),
          ),
        );
    }
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
        Text(value,
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryGreen)),
        Text(label,
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 12)),
      ],
    );
  }
}
