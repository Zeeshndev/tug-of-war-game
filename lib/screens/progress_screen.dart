import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_providers.dart';
import '../models/game_models.dart';
import '../utils/theme.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider);
    final accuracy = progress.totalAnswered > 0
        ? '${(progress.totalCorrect / progress.totalAnswered * 100).round()}%'
        : '-';

    final total = progress.additionCorrect + progress.subtractionCorrect
        + progress.multiplicationCorrect + progress.divisionCorrect;
    final skills = [
      (MathSkill.addition, '➕ Addition', progress.additionCorrect),
      (MathSkill.subtraction, '➖ Subtraction', progress.subtractionCorrect),
      (MathSkill.multiplication, '✖️ Multiplication', progress.multiplicationCorrect),
      (MathSkill.division, '➗ Division', progress.divisionCorrect),
    ];

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: const Text('←', style: TextStyle(fontSize: 30, color: AppTheme.textPrimary)),
                  ),
                  const SizedBox(width: 12),
                  Text('📊 My Progress', style: AppTheme.display(26, color: AppTheme.blueLight)),
                ],
              ),
              const SizedBox(height: 20),

              GridView.count(
                crossAxisCount: 2, shrinkWrap: true,
                crossAxisSpacing: 12, mainAxisSpacing: 12,
                childAspectRatio: 1.1,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _BigStat(emoji: '🏆', value: '${progress.totalWins}', label: 'Wins'),
                  _BigStat(emoji: '🎮', value: '${progress.totalGames}', label: 'Matches'),
                  _BigStat(emoji: '🔥', value: '${progress.bestStreak}', label: 'Best Streak'),
                  _BigStat(emoji: '🎯', value: accuracy, label: 'Accuracy'),
                ],
              ),
              const SizedBox(height: 24),

              Text('Skill Breakdown', style: AppTheme.display(20)),
              const SizedBox(height: 12),

              ...skills.map((s) {
                final (_, label, count) = s;
                final pct = total > 0 ? (count / total) : 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _SkillRow(label: label, count: count, pct: pct.clamp(0.0, 1.0)),
                );
              }),

              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.yellow.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                  border: Border.all(color: AppTheme.yellow.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Text('🪙', style: TextStyle(fontSize: 28)),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${progress.coins}',
                            style: AppTheme.display(28, color: AppTheme.yellowLight)),
                        Text('Total Coins', style: AppTheme.body(12, color: AppTheme.textSecondary)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BigStat extends StatelessWidget {
  final String emoji, value, label;
  const _BigStat({required this.emoji, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bg2,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: AppTheme.bg3),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 6),
          Text(value, style: AppTheme.display(32)),
          Text(label.toUpperCase(), style: AppTheme.body(11, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}

class _SkillRow extends StatelessWidget {
  final String label;
  final int count;
  final double pct;

  const _SkillRow({required this.label, required this.count, required this.pct});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bg2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.bg3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: AppTheme.body(14, weight: FontWeight.w800)),
              Text('$count correct', style: AppTheme.body(13, color: AppTheme.blueLight)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 10,
              backgroundColor: AppTheme.bg3,
              valueColor: const AlwaysStoppedAnimation(AppTheme.blueLight),
            ),
          ),
        ],
      ),
    );
  }
}
