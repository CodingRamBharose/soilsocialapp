import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:soilsocial/providers/auth_provider.dart';
import 'package:soilsocial/models/user_model.dart';
import 'package:soilsocial/services/user_service.dart';
import 'package:soilsocial/config/theme.dart';
import 'package:soilsocial/l10n/app_localizations.dart';

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
    final l = AppLocalizations.of(context);

    return Column(
      children: [
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            tabs: [
              Tab(
                text: l.translateWithArgs(
                    'connectionsCount', {'count': '${_connections.length}'}),
              ),
              Tab(
                text: l.translateWithArgs(
                    'requestsCount', {'count': '${_requests.length}'}),
              ),
              Tab(text: l.translate('suggested')),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryGreen))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildConnectionsList(l),
                    _buildRequestsList(l),
                    _buildSuggestionsList(l),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildConnectionsList(AppLocalizations l) {
    if (_connections.isEmpty) {
      return Center(
        child: Text(l.translate('noConnections'),
            style: const TextStyle(color: AppTheme.textSecondary)),
      );
    }
    return RefreshIndicator(
      color: AppTheme.primaryGreen,
      onRefresh: _loadData,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _connections.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
        itemBuilder: (context, index) {
          final user = _connections[index];
          return _UserCard(
            user: user,
            trailing: OutlinedButton.icon(
              onPressed: () => context.push(
                '/messages/${user.uid}',
                extra: {'name': user.name},
              ),
              icon: const Icon(Icons.chat_bubble_outline, size: 16),
              label: Text(l.translate('message')),
            ),
            onTap: () => context.push('/profile/${user.uid}'),
          );
        },
      ),
    );
  }

  Widget _buildRequestsList(AppLocalizations l) {
    if (_requests.isEmpty) {
      return Center(
        child: Text(l.translate('noPendingRequests'),
            style: const TextStyle(color: AppTheme.textSecondary)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _requests.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
      itemBuilder: (context, index) {
        final user = _requests[index];
        return _UserCard(
          user: user,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () => _acceptRequest(user.uid),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  minimumSize: const Size(0, 36),
                ),
                child: Text(l.translate('accept')),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () => _rejectRequest(user.uid),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  minimumSize: const Size(0, 36),
                ),
                child: Text(l.translate('reject')),
              ),
            ],
          ),
          onTap: () => context.push('/profile/${user.uid}'),
        );
      },
    );
  }

  Widget _buildSuggestionsList(AppLocalizations l) {
    if (_suggestions.isEmpty) {
      return Center(
        child: Text(l.translate('noSuggestions'),
            style: const TextStyle(color: AppTheme.textSecondary)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _suggestions.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
      itemBuilder: (context, index) {
        final user = _suggestions[index];
        return _UserCard(
          user: user,
          trailing: ElevatedButton.icon(
            onPressed: () => _sendRequest(user.uid),
            icon: const Icon(Icons.person_add, size: 16),
            label: Text(l.translate('connect')),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              minimumSize: const Size(0, 36),
            ),
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
    return Container(
      color: Colors.white,
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
          backgroundImage: user.profilePicture != null
              ? NetworkImage(user.profilePicture!)
              : null,
          child: user.profilePicture == null
              ? Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        title: Text(
          user.name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (user.location != null)
              Text(
                user.location!,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
            if (user.cropsGrown.isNotEmpty)
              Text(
                user.cropsGrown.take(3).join(', '),
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
          ],
        ),
        isThreeLine: user.cropsGrown.isNotEmpty,
        trailing: trailing,
      ),
    );
  }
}
