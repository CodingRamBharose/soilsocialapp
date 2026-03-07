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
        _connectionStatus = _userService.getConnectionStatus(
          currentUser,
          widget.userId,
        );
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
    final currentUserId = context.read<AuthProvider>().firebaseUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(title: Text(_user?.name ?? 'Profile')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
          ? const Center(child: Text('User not found'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundImage: _user!.profilePicture != null
                                ? NetworkImage(_user!.profilePicture!)
                                : null,
                            child: _user!.profilePicture == null
                                ? Text(
                                    _user!.name.isNotEmpty
                                        ? _user!.name[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(fontSize: 36),
                                  )
                                : null,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _user!.name,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          if (_user!.location != null)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                Text(
                                  _user!.location!,
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          if (_user!.bio != null && _user!.bio!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                _user!.bio!,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _StatItem(
                                value: '${_user!.connections.length}',
                                label: 'Connections',
                              ),
                              _StatItem(
                                value: '${_posts.length}',
                                label: 'Posts',
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (widget.userId != currentUserId)
                            Row(
                              children: [
                                Expanded(child: _buildConnectionButton()),
                                const SizedBox(width: 8),
                                if (_connectionStatus == 'connected')
                                  OutlinedButton.icon(
                                    onPressed: () => context.push(
                                      '/messages/${widget.userId}',
                                      extra: {'name': _user!.name},
                                    ),
                                    icon: const Icon(Icons.message),
                                    label: const Text('Message'),
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (_user!.cropsGrown.isNotEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Crops Grown',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: _user!.cropsGrown
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
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  if (_posts.isNotEmpty)
                    ..._posts.map(
                      (post) =>
                          PostCard(post: post, currentUserId: currentUserId),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildConnectionButton() {
    switch (_connectionStatus) {
      case 'connected':
        return ElevatedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.check),
          label: const Text('Connected'),
        );
      case 'pending':
        return OutlinedButton(
          onPressed: null,
          child: const Text('Request Sent'),
        );
      case 'received':
        return ElevatedButton(
          onPressed: _handleConnection,
          child: const Text('Accept Request'),
        );
      default:
        return ElevatedButton.icon(
          onPressed: _handleConnection,
          icon: const Icon(Icons.person_add),
          label: const Text('Connect'),
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
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }
}
