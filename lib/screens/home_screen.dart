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

  void _showDailyQuests(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _DailyQuestsModal(),
    );
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

                // ── DAILY QUESTS BANNER ──
                _DailyQuestBanner(onTap: () => _showDailyQuests(context)),
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
                    ref.read(matchConfigProvider.notifier).state = {
                      'isAdventure': false, 'level': 0, 'isBoss': false
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

// ── Daily Quests Banner ──────────────────────────────────────────────────────
class _DailyQuestBanner extends ConsumerWidget {
  final VoidCallback onTap;
  const _DailyQuestBanner({required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quests = ref.watch(progressProvider).dailyQuests;
    final unclaimed = quests.where((q) => q.current >= q.target && !q.isClaimed).length;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.bg2,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: unclaimed > 0 ? AppTheme.yellow : AppTheme.bg3, width: 2),
        ),
        child: Row(
          children: [
            const Text('🎯', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Daily Quests', style: AppTheme.body(14, color: AppTheme.textPrimary, weight: FontWeight.w800)),
                Text('Reset in 24 hours', style: AppTheme.body(11, color: AppTheme.textSecondary)),
              ],
            ),
            const Spacer(),
            if (unclaimed > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppTheme.red, borderRadius: BorderRadius.circular(20)),
                child: Text('$unclaimed Ready!', style: AppTheme.body(11, color: Colors.white, weight: FontWeight.w900)),
              )
            else
              Text('View All →', style: AppTheme.body(12, color: AppTheme.blueLight, weight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

// ── Daily Quests Modal ───────────────────────────────────────────────────────
class _DailyQuestsModal extends ConsumerWidget {
  const _DailyQuestsModal();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quests = ref.watch(progressProvider).dailyQuests;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppTheme.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(width: 40, height: 5, decoration: BoxDecoration(color: AppTheme.bg3, borderRadius: BorderRadius.circular(10))),
          ),
          const SizedBox(height: 20),
          Text('🎯 Daily Quests', style: AppTheme.display(28, color: AppTheme.yellowLight)),
          Text('Complete these to earn extra coins!', style: AppTheme.body(13, color: AppTheme.textSecondary)),
          const SizedBox(height: 20),

          ...quests.map((q) {
            final isDone = q.current >= q.target;
            final pct = (q.current / q.target).clamp(0.0, 1.0);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: q.isClaimed ? AppTheme.bg2.withOpacity(0.5) : AppTheme.bg2,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDone && !q.isClaimed ? AppTheme.green : AppTheme.bg3),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(q.title, style: AppTheme.body(14, color: AppTheme.textPrimary, weight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Stack(
                                children: [
                                  Container(height: 8, decoration: BoxDecoration(color: AppTheme.bg3, borderRadius: BorderRadius.circular(4))),
                                  FractionallySizedBox(
                                    widthFactor: pct,
                                    child: Container(height: 8, decoration: BoxDecoration(color: AppTheme.yellow, borderRadius: BorderRadius.circular(4))),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text('${q.current}/${q.target}', style: AppTheme.body(11, color: AppTheme.textSecondary, weight: FontWeight.w800)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Claim Button or Status
                  if (q.isClaimed)
                    const Text('✅', style: TextStyle(fontSize: 24))
                  else if (isDone)
                    GestureDetector(
                      onTap: () => ref.read(progressProvider.notifier).claimQuest(q.id),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(color: AppTheme.green, borderRadius: BorderRadius.circular(50)),
                        child: Text('CLAIM\n🪙 ${q.reward}', textAlign: TextAlign.center, style: AppTheme.body(10, color: Colors.white, weight: FontWeight.w900)),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: AppTheme.bg3.withOpacity(0.5), borderRadius: BorderRadius.circular(50)),
                      child: Text('🪙 ${q.reward}', style: AppTheme.body(11, color: AppTheme.textSecondary, weight: FontWeight.w900)),
                    ),
                ],
              ),
            );
          }).toList(),
          const SizedBox(height: 20),
        ],
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