import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:soilsocial/services/notification_service.dart';
import 'package:soilsocial/providers/auth_provider.dart';

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
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _getIndex(location);
    final authProvider = context.watch<AuthProvider>();
    final userId = authProvider.firebaseUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SoilSocial'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
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
                  child: IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () => context.go('/notifications'),
                  ),
                );
              },
            ),
        ],
      ),
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
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
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Network'),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Market'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
