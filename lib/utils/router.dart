import 'package:go_router/go_router.dart';
import '../screens/splash_screen.dart';
import '../screens/home_screen.dart';
import '../screens/game_screen.dart';
import '../screens/shop_screen.dart';
import '../screens/leaderboard_screen.dart';
import '../screens/progress_screen.dart';
import '../screens/countdown_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/', // App now boots directly into the Splash Screen
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        // Fallback to Home temporarily. We will replace this with OnboardingScreen in UC-002.
        builder: (context, state) => const HomeScreen(), 
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
    ],
  );
}