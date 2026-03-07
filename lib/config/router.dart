import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:soilsocial/providers/auth_provider.dart';
import 'package:soilsocial/screens/auth/sign_in_screen.dart';
import 'package:soilsocial/screens/auth/sign_up_screen.dart';
import 'package:soilsocial/screens/auth/verify_email_screen.dart';
import 'package:soilsocial/screens/main_shell.dart';
import 'package:soilsocial/screens/dashboard/dashboard_screen.dart';
import 'package:soilsocial/screens/profile/profile_screen.dart';
import 'package:soilsocial/screens/profile/edit_profile_screen.dart';
import 'package:soilsocial/screens/profile/user_profile_screen.dart';
import 'package:soilsocial/screens/posts/create_post_screen.dart';
import 'package:soilsocial/screens/network/network_screen.dart';
import 'package:soilsocial/screens/messages/conversations_screen.dart';
import 'package:soilsocial/screens/messages/chat_screen.dart';
import 'package:soilsocial/screens/marketplace/marketplace_screen.dart';
import 'package:soilsocial/screens/marketplace/create_product_screen.dart';
import 'package:soilsocial/screens/marketplace/product_detail_screen.dart';
import 'package:soilsocial/screens/events/events_screen.dart';
import 'package:soilsocial/screens/events/create_event_screen.dart';
import 'package:soilsocial/screens/events/event_detail_screen.dart';
import 'package:soilsocial/screens/groups/groups_screen.dart';
import 'package:soilsocial/screens/notifications/notifications_screen.dart';
import 'package:soilsocial/screens/search/search_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createRouter(AuthProvider authProvider) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/dashboard',
    refreshListenable: authProvider,
    redirect: (context, state) {
      final isLoggedIn = authProvider.isLoggedIn;
      final isAuthRoute =
          state.matchedLocation == '/sign-in' ||
          state.matchedLocation == '/sign-up' ||
          state.matchedLocation == '/verify-email';

      if (!isLoggedIn && !isAuthRoute) return '/sign-in';
      if (isLoggedIn && isAuthRoute) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/sign-in',
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: '/sign-up',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/verify-email',
        builder: (context, state) => const VerifyEmailScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/network',
            builder: (context, state) => const NetworkScreen(),
          ),
          GoRoute(
            path: '/messages',
            builder: (context, state) => const ConversationsScreen(),
          ),
          GoRoute(
            path: '/marketplace',
            builder: (context, state) => const MarketplaceScreen(),
          ),
          GoRoute(
            path: '/events',
            builder: (context, state) => const EventsScreen(),
          ),
          GoRoute(
            path: '/groups',
            builder: (context, state) => const GroupsScreen(),
          ),
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '/search',
            builder: (context, state) => const SearchScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/profile/edit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/profile/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            UserProfileScreen(userId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/post/create',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CreatePostScreen(),
      ),
      GoRoute(
        path: '/messages/:userId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return ChatScreen(
            otherUserId: state.pathParameters['userId']!,
            otherUserName: extra?['name'] ?? 'User',
          );
        },
      ),
      GoRoute(
        path: '/marketplace/new',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CreateProductScreen(),
      ),
      GoRoute(
        path: '/marketplace/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            ProductDetailScreen(productId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/events/create',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CreateEventScreen(),
      ),
      GoRoute(
        path: '/events/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            EventDetailScreen(eventId: state.pathParameters['id']!),
      ),
    ],
  );
}
