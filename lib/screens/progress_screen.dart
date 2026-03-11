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
    final profile = ref.watch(profileProvider);

    final winRate = progress.totalGames > 0 ? (progress.totalWins / progress.totalGames) : 0.0;
    final accuracy = progress.totalAnswered > 0 ? (progress.totalCorrect / progress.totalAnswered) : 0.0;
    final avgSpeed = progress.totalQuestionsAnswered > 0 
        ? (progress.totalResponseTimeMs / progress.totalQuestionsAnswered / 1000.0) 
        : 0.0;

    final totalSkills = progress.additionCorrect + progress.subtractionCorrect + progress.multiplicationCorrect + progress.divisionCorrect;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                child: Row(children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: AppTheme.bg2, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.bg3)),
                      child: const Center(child: Text('←', style: TextStyle(fontSize: 20, color: AppTheme.textPrimary))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('📊 Player Stats', style: AppTheme.display(26, color: AppTheme.yellowLight)),
                ]),
              ),

              // ── Top Hero Stats ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _HeroStatCard(title: 'WIN RATE', value: '${(winRate * 100).round()}%', color: AppTheme.green, icon: '🏆'),
                    const SizedBox(width: 12),
                    _HeroStatCard(title: 'ACCURACY', value: '${(accuracy * 100).round()}%', color: AppTheme.blue, icon: '🎯'),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── Brain Power Metric ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [AppTheme.purple.withOpacity(0.4), AppTheme.blue.withOpacity(0.4)]),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.purple, width: 2),
                  ),
                  child: Column(
                    children: [
                      Text('🧠 ESTIMATED BRAIN POWER', style: AppTheme.body(12, color: Colors.white, weight: FontWeight.w900).copyWith(letterSpacing: 1.5)),
                      const SizedBox(height: 8),
                      Text(
                        '${calculateBrainPower(
                          correct: progress.totalCorrect, answered: progress.totalAnswered, bestStreak: progress.bestStreak, 
                          matchDuration: 60, totalResponseMs: progress.totalResponseTimeMs, responsesCount: progress.totalQuestionsAnswered
                        )}', 
                        style: AppTheme.display(64, color: Colors.white)
                      ),
                      const SizedBox(height: 4),
                      Text('Based on Speed, Accuracy & Streaks', style: AppTheme.body(11, color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Skill Breakdown ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('SKILL MASTERY', style: AppTheme.body(14, color: AppTheme.textSecondary, weight: FontWeight.w900).copyWith(letterSpacing: 1.2)),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppTheme.bg2, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.bg3)),
                  child: Column(
                    children: [
                      _SkillBar(label: '➕ Addition', count: progress.additionCorrect, total: totalSkills, color: Colors.blue),
                      const SizedBox(height: 12),
                      _SkillBar(label: '➖ Subtraction', count: progress.subtractionCorrect, total: totalSkills, color: Colors.red),
                      const SizedBox(height: 12),
                      _SkillBar(label: '✖️ Multiplication', count: progress.multiplicationCorrect, total: totalSkills, color: Colors.purple),
                      const SizedBox(height: 12),
                      _SkillBar(label: '➗ Division', count: progress.divisionCorrect, total: totalSkills, color: Colors.orange),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Quick Facts ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('QUICK FACTS', style: AppTheme.body(14, color: AppTheme.textSecondary, weight: FontWeight.w900).copyWith(letterSpacing: 1.2)),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(child: _FactBox(label: 'Total Matches', value: '${progress.totalGames}')),
                    const SizedBox(width: 10),
                    Expanded(child: _FactBox(label: 'Best Streak', value: '${progress.bestStreak}')),
                    const SizedBox(width: 10),
                    Expanded(child: _FactBox(label: 'Avg Speed', value: '${avgSpeed.toStringAsFixed(1)}s')),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroStatCard extends StatelessWidget {
  final String title, value, icon;
  final Color color;
  const _HeroStatCard({required this.title, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.5), width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Text(title, style: AppTheme.body(11, color: color, weight: FontWeight.w900)),
              ],
            ),
            const SizedBox(height: 8),
            Text(value, style: AppTheme.display(28, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

class _SkillBar extends StatelessWidget {
  final String label;
  final int count, total;
  final Color color;
  const _SkillBar({required this.label, required this.count, required this.total, required this.color});

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (count / total).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTheme.body(13, color: AppTheme.textPrimary, weight: FontWeight.w800)),
            Text('$count correct', style: AppTheme.body(11, color: AppTheme.textSecondary)),
          ],
        ),
        const SizedBox(height: 6),
        Stack(
          children: [
            Container(height: 10, decoration: BoxDecoration(color: AppTheme.bg3, borderRadius: BorderRadius.circular(5))),
            FractionallySizedBox(
              widthFactor: pct,
              child: Container(height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(5))),
            ),
          ],
        ),
      ],
    );
  }
}

class _FactBox extends StatelessWidget {
  final String label, value;
  const _FactBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(color: AppTheme.bg2, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.bg3)),
      child: Column(
        children: [
          Text(value, style: AppTheme.display(20, color: AppTheme.yellowLight)),
          const SizedBox(height: 4),
          Text(label, style: AppTheme.body(10, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}