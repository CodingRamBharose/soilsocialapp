import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:soilsocial/services/notification_service.dart';
import 'package:soilsocial/providers/auth_provider.dart';
import 'package:soilsocial/config/theme.dart';
import 'package:soilsocial/l10n/app_localizations.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  int _getIndex(String location) {
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/network')) return 1;
    if (location.startsWith('/notifications')) return 3;
    if (location.startsWith('/weather')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _getIndex(location);
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.userModel;
    final userId = authProvider.firebaseUser?.uid;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            // Profile avatar (tap to go to profile)
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: GestureDetector(
                onTap: () => context.go('/profile'),
                child: CircleAvatar(
                  radius: 22,
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
                            fontSize: 16,
                            color: AppTheme.primaryGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Full-width search bar
            Expanded(
              child: GestureDetector(
                onTap: () => context.go('/search'),
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF3F8),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.search,
                        size: 20,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l.translate('search'),
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppTheme.dividerColor, height: 1),
        ),
        actions: [
          // Message icon (tap to go to messages)
          if (userId != null)
            IconButton(
              icon: const Icon(
                Icons.chat_bubble_outline,
                color: AppTheme.textSecondary,
              ),
              onPressed: () => context.go('/messages'),
            ),
        ],
      ),
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppTheme.dividerColor, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) {
            switch (index) {
              case 0:
                context.go('/dashboard');
              case 1:
                context.go('/network');
              case 2:
                context.push('/post/create');
              case 3:
                context.go('/notifications');
              case 4:
                context.go('/weather');
            }
          },
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined),
              activeIcon: const Icon(Icons.home),
              label: l.translate('home'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.people_outline),
              activeIcon: const Icon(Icons.people),
              label: l.translate('network'),
            ),
            BottomNavigationBarItem(
              icon: Container(
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(6),
                child: const Icon(Icons.add, color: Colors.white, size: 22),
              ),
              label: l.translate('post'),
            ),
            BottomNavigationBarItem(
              icon: userId != null
                  ? StreamBuilder<int>(
                      stream: NotificationService().getUnreadCount(userId),
                      builder: (context, snapshot) {
                        final count = snapshot.data ?? 0;
                        return Badge(
                          isLabelVisible: count > 0,
                          label: Text('$count'),
                          backgroundColor: AppTheme.primaryGreen,
                          child: const Icon(Icons.notifications_outlined),
                        );
                      },
                    )
                  : const Icon(Icons.notifications_outlined),
              activeIcon: const Icon(Icons.notifications),
              label: l.translate('notifications'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.wb_sunny_outlined),
              activeIcon: const Icon(Icons.wb_sunny),
              label: l.translate('weather'),
            ),
          ],
        ),
      ),
    );
  }
}
