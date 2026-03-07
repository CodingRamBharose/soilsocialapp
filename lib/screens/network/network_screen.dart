import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:soilsocial/providers/auth_provider.dart';
import 'package:soilsocial/models/user_model.dart';
import 'package:soilsocial/services/user_service.dart';
import 'package:soilsocial/config/theme.dart';

class NetworkScreen extends StatefulWidget {
  const NetworkScreen({super.key});

  @override
  State<NetworkScreen> createState() => _NetworkScreenState();
}

class _NetworkScreenState extends State<NetworkScreen>
    with SingleTickerProviderStateMixin {
  final _userService = UserService();
  late TabController _tabController;
  List<UserModel> _connections = [];
  List<UserModel> _suggestions = [];
  List<UserModel> _requests = [];
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
    final uid = context.read<AuthProvider>().firebaseUser?.uid;
    if (uid == null) return;
    setState(() => _isLoading = true);
    try {
      _connections = await _userService.getConnections(uid);
      _suggestions = await _userService.getSuggestedUsers(uid);
      _requests = await _userService.getConnectionRequests(uid);
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _sendRequest(String userId) async {
    final uid = context.read<AuthProvider>().firebaseUser!.uid;
    await _userService.sendConnectionRequest(uid, userId);
    await context.read<AuthProvider>().refreshUserProfile();
    await _loadData();
  }

  Future<void> _acceptRequest(String userId) async {
    final uid = context.read<AuthProvider>().firebaseUser!.uid;
    await _userService.acceptConnectionRequest(uid, userId);
    await context.read<AuthProvider>().refreshUserProfile();
    await _loadData();
  }

  Future<void> _rejectRequest(String userId) async {
    final uid = context.read<AuthProvider>().firebaseUser!.uid;
    await _userService.rejectConnectionRequest(uid, userId);
    await context.read<AuthProvider>().refreshUserProfile();
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryGreen,
          tabs: [
            Tab(text: 'Connections (${_connections.length})'),
            Tab(text: 'Requests (${_requests.length})'),
            const Tab(text: 'Suggested'),
          ],
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildConnectionsList(),
                    _buildRequestsList(),
                    _buildSuggestionsList(),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildConnectionsList() {
    if (_connections.isEmpty) {
      return const Center(child: Text('No connections yet'));
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _connections.length,
        itemBuilder: (context, index) {
          final user = _connections[index];
          return _UserCard(
            user: user,
            trailing: OutlinedButton.icon(
              onPressed: () => context.push(
                '/messages/${user.uid}',
                extra: {'name': user.name},
              ),
              icon: const Icon(Icons.message, size: 18),
              label: const Text('Message'),
            ),
            onTap: () => context.push('/profile/${user.uid}'),
          );
        },
      ),
    );
  }

  Widget _buildRequestsList() {
    if (_requests.isEmpty) {
      return const Center(child: Text('No pending requests'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _requests.length,
      itemBuilder: (context, index) {
        final user = _requests[index];
        return _UserCard(
          user: user,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () => _acceptRequest(user.uid),
                child: const Text('Accept'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () => _rejectRequest(user.uid),
                child: const Text('Reject'),
              ),
            ],
          ),
          onTap: () => context.push('/profile/${user.uid}'),
        );
      },
    );
  }

  Widget _buildSuggestionsList() {
    if (_suggestions.isEmpty) {
      return const Center(child: Text('No suggestions right now'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _suggestions.length,
      itemBuilder: (context, index) {
        final user = _suggestions[index];
        return _UserCard(
          user: user,
          trailing: ElevatedButton.icon(
            onPressed: () => _sendRequest(user.uid),
            icon: const Icon(Icons.person_add, size: 18),
            label: const Text('Connect'),
          ),
          onTap: () => context.push('/profile/${user.uid}'),
        );
      },
    );
  }
}

class _UserCard extends StatelessWidget {
  final UserModel user;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _UserCard({required this.user, this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundImage: user.profilePicture != null
              ? NetworkImage(user.profilePicture!)
              : null,
          child: user.profilePicture == null
              ? Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?')
              : null,
        ),
        title: Text(
          user.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (user.location != null) Text(user.location!),
            if (user.cropsGrown.isNotEmpty)
              Text(
                user.cropsGrown.take(3).join(', '),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
          ],
        ),
        isThreeLine: user.cropsGrown.isNotEmpty,
        trailing: trailing,
      ),
    );
  }
}
