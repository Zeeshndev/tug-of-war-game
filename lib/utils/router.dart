import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/onboarding_screen.dart';
import '../screens/home_screen.dart';
import '../screens/countdown_screen.dart';
import '../screens/game_screen.dart';
import '../screens/result_screen.dart';
import '../screens/shop_screen.dart';
import '../screens/progress_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/parent_settings_screen.dart';
import '../screens/leaderboard_screen.dart';
import '../screens/adventure_screen.dart'; // ADDED IMPORT
import '../services/storage_service.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', redirect: (_, __) => StorageService.isOnboardingComplete ? '/home' : '/onboarding'),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/home',       builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/countdown',  builder: (_, __) => const CountdownScreen()),
      GoRoute(path: '/game',       builder: (_, __) => const GameScreen()),
      GoRoute(path: '/result',     builder: (_, __) => const ResultScreen()),
      GoRoute(path: '/shop',       builder: (_, __) => const ShopScreen()),
      GoRoute(path: '/progress',   builder: (_, __) => const ProgressScreen()),
      GoRoute(path: '/settings',   builder: (_, __) => const SettingsScreen()),
      GoRoute(path: '/leaderboard',builder: (_, __) => const LeaderboardScreen()),
      GoRoute(path: '/parent-settings', builder: (_, __) => const ParentSettingsScreen()),
      GoRoute(path: '/adventure',  builder: (_, __) => const AdventureScreen()), // ADDED ROUTE
    ],
  );
}