import 'package:go_router/go_router.dart';
import '../screens/splash_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/home_screen.dart';
import '../screens/game_screen.dart';
import '../screens/result_screen.dart'; // <-- Added this back!
import '../screens/shop_screen.dart';
import '../screens/leaderboard_screen.dart';
import '../screens/progress_screen.dart';
import '../screens/countdown_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/', 
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/game',
        builder: (context, state) => const GameScreen(),
      ),
      GoRoute(
        path: '/result', // <-- Added the Result route back!
        builder: (context, state) => const ResultScreen(),
      ),
      GoRoute(
        path: '/shop',
        builder: (context, state) => const ShopScreen(),
      ),
      GoRoute(
        path: '/leaderboard',
        builder: (context, state) => const LeaderboardScreen(),
      ),
      GoRoute(
        path: '/progress',
        builder: (context, state) => const ProgressScreen(),
      ),
      GoRoute(
        path: '/countdown',
        builder: (context, state) => const CountdownScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const settings(),
      ),
    ],
  );
}