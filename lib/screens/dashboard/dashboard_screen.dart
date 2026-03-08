import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:soilsocial/providers/auth_provider.dart';
import 'package:soilsocial/models/post_model.dart';
import 'package:soilsocial/services/post_service.dart';
import 'package:soilsocial/widgets/post_card.dart';
import 'package:soilsocial/screens/groups/groups_screen.dart';
import 'package:soilsocial/screens/events/events_screen.dart';
import 'package:soilsocial/screens/marketplace/marketplace_screen.dart';
import 'package:soilsocial/config/theme.dart';
import 'package:soilsocial/l10n/app_localizations.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final PostService _postService = PostService();
  List<PostModel> _posts = [];
  bool _isLoading = true;
  // null = feed, 0 = Groups, 1 = Events, 2 = Mandi
  int? _selectedTab;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() => _isLoading = true);
    try {
      _posts = await _postService.getPosts();
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.userModel;

    return Column(
      children: [
        // Top tabs: Groups, Events, Mandi
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
              children: [
                Expanded(
                  child: _TabChip(
                    label: l.translate('groups'),
                    icon: Icons.group,
                    isSelected: _selectedTab == 0,
                    onTap: () => setState(
                      () => _selectedTab = _selectedTab == 0 ? null : 0,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TabChip(
                    label: l.translate('events'),
                    icon: Icons.event,
                    isSelected: _selectedTab == 1,
                    onTap: () => setState(
                      () => _selectedTab = _selectedTab == 1 ? null : 1,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TabChip(
                    label: l.translate('marketplace'),
                    icon: Icons.storefront,
                    isSelected: _selectedTab == 2,
                    onTap: () => setState(
                      () => _selectedTab = _selectedTab == 2 ? null : 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const Divider(height: 1),
        // Content based on selected tab
        Expanded(
          child: _selectedTab == 0
              ? const GroupsScreen()
              : _selectedTab == 1
              ? const EventsScreen()
              : _selectedTab == 2
              ? const MarketplaceScreen()
              : _buildFeed(context, l, authProvider, user),
        ),
      ],
    );
  }

  Widget _buildFeed(
    BuildContext context,
    AppLocalizations l,
    AuthProvider authProvider,
    dynamic user,
  ) {
    return RefreshIndicator(
      color: AppTheme.primaryGreen,
      onRefresh: _loadPosts,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Feed Label
                Container(
                  color: Colors.white,
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Text(
                    l.translate('feed'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                const Divider(height: 1),
              ],
            ),
          ),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppTheme.primaryGreen),
              ),
            )
          else if (_posts.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.post_add, size: 56, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      l.translate('noPostsYet'),
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l.translate('beFirstToShare'),
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => context.push('/post/create'),
                      child: Text(l.translate('createPost')),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: PostCard(
                    post: _posts[index],
                    currentUserId: authProvider.firebaseUser?.uid ?? '',
                    onRefresh: _loadPosts,
                  ),
                ),
                childCount: _posts.length,
              ),
            ),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected ? AppTheme.primaryGreen : AppTheme.cardBorder,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : AppTheme.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
