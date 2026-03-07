import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:soilsocial/services/notification_service.dart';
import 'package:soilsocial/providers/auth_provider.dart';
import 'package:soilsocial/providers/language_provider.dart';
import 'package:soilsocial/config/theme.dart';
import 'package:soilsocial/l10n/app_localizations.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  int _getIndex(String location) {
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/network')) return 1;
    if (location.startsWith('/marketplace')) return 2;
    if (location.startsWith('/messages')) return 3;
    if (location.startsWith('/profile') && !location.contains('/profile/'))
      return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _getIndex(location);
    final authProvider = context.watch<AuthProvider>();
    final userId = authProvider.firebaseUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.eco, color: AppTheme.primaryGreen, size: 28),
            const SizedBox(width: 8),
            Text(
              l.translate('appName'),
              style: const TextStyle(
                color: AppTheme.primaryGreen,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppTheme.dividerColor, height: 1),
        ),
        actions: [
          // Language toggle
          IconButton(
            icon: Text(
              context.watch<LanguageProvider>().locale.languageCode == 'pa'
                  ? 'EN'
                  : 'ਪੰ',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            tooltip: l.translate('language'),
            onPressed: () => context.read<LanguageProvider>().toggleLanguage(),
          ),
          IconButton(
            icon: const Icon(Icons.search, color: AppTheme.textSecondary),
            onPressed: () => context.go('/search'),
          ),
          if (userId != null)
            StreamBuilder<int>(
              stream: NotificationService().getUnreadCount(userId),
              builder: (context, snapshot) {
                final count = snapshot.data ?? 0;
                return Badge(
                  isLabelVisible: count > 0,
                  label: Text('$count'),
                  backgroundColor: AppTheme.primaryGreen,
                  child: IconButton(
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: AppTheme.textSecondary,
                    ),
                    onPressed: () => context.go('/notifications'),
                  ),
                );
              },
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
                context.go('/marketplace');
              case 3:
                context.go('/messages');
              case 4:
                context.go('/profile');
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
              icon: const Icon(Icons.storefront_outlined),
              activeIcon: const Icon(Icons.storefront),
              label: l.translate('marketplace'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.chat_bubble_outline),
              activeIcon: const Icon(Icons.chat_bubble),
              label: l.translate('messages'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline),
              activeIcon: const Icon(Icons.person),
              label: l.translate('profile'),
            ),
          ],
        ),
      ),
    );
  }
}
