import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_providers.dart';
import '../models/game_models.dart';
import '../utils/theme.dart';
import '../widgets/common_widgets.dart';
import '../services/audio_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AudioService().setBgmState(BgmState.menu);
    });
  }

  Future<void> _showQuitConfirmation(BuildContext context) async {
    final bool? shouldQuit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.bg2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: AppTheme.bg3)),
        title: Text('Leaving so soon?', style: AppTheme.display(22, color: AppTheme.yellowLight), textAlign: TextAlign.center),
        content: Text('Are you sure you want to quit the game?', style: AppTheme.body(14, color: AppTheme.textSecondary), textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text('Cancel', style: AppTheme.body(15, color: AppTheme.blueLight, weight: FontWeight.bold))),
          const SizedBox(width: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.red.withOpacity(0.8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Quit', style: AppTheme.body(15, color: Colors.white, weight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (shouldQuit == true) SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final profile  = ref.watch(profileProvider);
    final progress = ref.watch(progressProvider);

    final char = kCharacters.firstWhere((c) => c.id == progress.selectedCharacter, orElse: () => kCharacters.first);
    final accuracy = progress.totalAnswered > 0 ? '${(progress.totalCorrect / progress.totalAnswered * 100).round()}%' : '-';

    return PopScope(
      canPop: false, 
      onPopInvoked: (bool didPop) {
        if (didPop) return;
        _showQuitConfirmation(context);
      },
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    const Text('🪢', style: TextStyle(fontSize: 28)),
                    const SizedBox(width: 8),
                    Text('Tug of War', style: AppTheme.display(22, color: AppTheme.yellowLight)),
                    const Spacer(),
                    CoinBadge(coins: progress.coins),
                  ],
                ),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.yellow.withOpacity(0.1), borderRadius: BorderRadius.circular(AppTheme.radius),
                    border: Border.all(color: AppTheme.yellow.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 28)),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('DAY STREAK', style: AppTheme.body(11, color: AppTheme.textSecondary)),
                          Text('${progress.streakDays} day${progress.streakDays != 1 ? 's' : ''}', style: AppTheme.display(22, color: AppTheme.yellowLight)),
                        ],
                      ),
                      const Spacer(),
                      Text('Age ${profile.ageGroup == 'A' ? '5–7' : '8–11'}', style: AppTheme.body(13, color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                AppCard(
                  child: Column(
                    children: [
                      Text(char.emoji, style: const TextStyle(fontSize: 80)),
                      const SizedBox(height: 8),
                      Text(char.name, style: AppTheme.display(18, color: AppTheme.textSecondary)),
                      Text('Your Champion', style: AppTheme.body(12, color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                GridView.count(
                  crossAxisCount: 2, shrinkWrap: true, crossAxisSpacing: 12, mainAxisSpacing: 12,
                  childAspectRatio: 1.4, physics: const NeverScrollableScrollPhysics(),
                  children: [
                    StatCard(value: '${progress.totalWins}', label: 'Wins'),
                    StatCard(value: '${progress.totalGames}', label: 'Matches'),
                    StatCard(value: '${progress.bestStreak}', label: 'Best Streak'),
                    StatCard(value: accuracy, label: 'Accuracy'),
                  ],
                ),
                const SizedBox(height: 20),

                BigButton(
                  label: '🗺️ Adventure Mode',
                  onTap: () => context.push('/adventure'),
                  color: AppTheme.blue,
                  shadowColor: const Color(0xFF1D4ED8), 
                  fontSize: 24,
                ),
                const SizedBox(height: 10),
                GhostButton(
                  label: '⚡ Quick Play',
                  onTap: () {
                    // Turn off Boss mode for Quick Play
                    ref.read(matchConfigProvider.notifier).state = {
                      'isAdventure': false,
                      'level': 0,
                      'isBoss': false
                    };
                    context.push('/countdown');
                  }
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    _NavBtn(emoji: '📊', label: 'Progress', onTap: () => context.push('/progress')),
                    const SizedBox(width: 10),
                    _NavBtn(emoji: '🛒', label: 'Shop', onTap: () => context.push('/shop')),
                    const SizedBox(width: 10),
                    _NavBtn(emoji: '🏆', label: 'Leaderboard', onTap: () => context.push('/leaderboard')),
                    const SizedBox(width: 10),
                    _NavBtn(emoji: '⚙️', label: 'Settings', onTap: () => context.push('/settings')),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final String emoji, label;
  final VoidCallback onTap;
  const _NavBtn({required this.emoji, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(color: AppTheme.bg2, borderRadius: BorderRadius.circular(AppTheme.radius), border: Border.all(color: AppTheme.bg3)),
          child: Column(children: [Text(emoji, style: const TextStyle(fontSize: 26)), const SizedBox(height: 4), Text(label, style: AppTheme.body(12, color: AppTheme.textSecondary))]),
        ),
      ),
    );
  }
}