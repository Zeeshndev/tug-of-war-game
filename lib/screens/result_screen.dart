import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_providers.dart';
import '../utils/theme.dart';
import '../widgets/common_widgets.dart';
import '../services/audio_service.dart';

class ResultScreen extends ConsumerStatefulWidget {
  const ResultScreen({super.key});

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> with TickerProviderStateMixin {
  bool _showStar1 = false;
  bool _showStar2 = false;
  bool _showStar3 = false;
  bool _showConfetti = false;

  @override
  void initState() {
    super.initState();
    // Start the UC-009 stagger animation sequence after screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runStarSequence();
    });
  }

  Future<void> _runStarSequence() async {
    final session = ref.read(gameProvider);
    final isAdv = ref.read(matchConfigProvider)['isAdventure'] == true;
    
    if (!isAdv) return; // Quick play doesn't do star animations

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    // Star 1
    if (session.starsEarned >= 1) {
      setState(() => _showStar1 = true);
      AudioService().playKey(); // Star sound
      await Future.delayed(const Duration(milliseconds: 400));
    }
    if (!mounted) return;

    // Star 2
    if (session.starsEarned >= 2) {
      setState(() => _showStar2 = true);
      AudioService().playKey();
      await Future.delayed(const Duration(milliseconds: 400));
    }
    if (!mounted) return;

    // Star 3
    if (session.starsEarned >= 3) {
      setState(() => _showStar3 = true);
      AudioService().playKey();
      await Future.delayed(const Duration(milliseconds: 400));
    }
    
    // New Record Confetti
    if (session.isNewRecord && session.starsEarned > 0) {
      setState(() => _showConfetti = true);
      AudioService().playCorrect(); // Celebratory chime
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(gameProvider);
    final config = ref.watch(matchConfigProvider);
    final isAdventure = config['isAdventure'] == true;
    final levelNum = config['level'] as int? ?? 1;

    final bool won = session.playerWinningByRope || session.playerScore > session.aiScore;
    final String title = isAdventure 
      ? (won ? 'Level $levelNum Complete!' : 'Level $levelNum Failed')
      : (won ? 'You Won!' : 'Good Try!');

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              // Title Banner
              Text(
                title, 
                // FIXED: Using built-in Colors.orange instead of AppTheme.orange
                style: AppTheme.display(36, color: won ? AppTheme.green : Colors.orange),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              
              // ── ADVENTURE MODE STARS (UC-009) ──
              if (isAdventure)
                SizedBox(
                  height: 150,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _AnimatedStar(visible: _showStar1, delayMs: 0),
                          const SizedBox(width: 10),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 40),
                            child: _AnimatedStar(visible: _showStar2, delayMs: 100),
                          ),
                          const SizedBox(width: 10),
                          _AnimatedStar(visible: _showStar3, delayMs: 200),
                        ],
                      ),
                      if (_showConfetti)
                        const Positioned(
                          bottom: 0,
                          child: _ConfettiBurst(),
                        )
                    ],
                  ),
                ),

              // Try again message if 0 stars
              if (isAdventure && !won)
                Padding(
                  padding: const EdgeInsets.only(top: 20, bottom: 20),
                  child: Text(
                    "Try Again? You can do it! 💪", 
                    style: AppTheme.body(18, color: AppTheme.textSecondary)
                  ),
                ),

              const SizedBox(height: 20),

              // Match Stats
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.bg2,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.bg3, width: 2),
                ),
                child: Column(
                  children: [
                    _StatRow(label: 'Accuracy', value: session.accuracy),
                    const Divider(color: AppTheme.bg3, height: 24, thickness: 2),
                    _StatRow(label: 'Best Streak', value: '${session.sessionBestStreak}🔥'),
                    const Divider(color: AppTheme.bg3, height: 24, thickness: 2),
                    _StatRow(
                      label: 'Coins Earned', 
                      value: '+${session.coinsEarned}', 
                      valueColor: AppTheme.yellow,
                    ),
                  ],
                ),
              ),
              const Spacer(),

              // Next Level Preview (UC-009)
              if (isAdventure && won)
                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: AppTheme.blueLight, width: 2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock_open, color: AppTheme.blueLight),
                      const SizedBox(width: 8),
                      Text('Level ${levelNum + 1} Unlocked!', style: AppTheme.body(16, color: AppTheme.blueLight, weight: FontWeight.w800)),
                    ],
                  ),
                ),

              // Buttons
              if (isAdventure) ...[
                if (won)
                  BigButton(
                    label: 'Next Level ▶',
                    onTap: () {
                      ref.read(matchConfigProvider.notifier).state = {
                        ...config,
                        'level': levelNum + 1,
                      };
                      context.go('/countdown');
                    },
                    color: AppTheme.green,
                    shadowColor: const Color(0xFF15803D),
                  ),
                if (!won)
                  BigButton(
                    label: 'Try Again 🔄',
                    onTap: () => context.go('/countdown'),
                    // FIXED: Using built-in Colors.orange instead of AppTheme.orange
                    color: Colors.orange,
                    shadowColor: const Color(0xFFC2410C),
                  ),
                const SizedBox(height: 12),
                BigButton(
                  label: 'World Map 🗺️',
                  onTap: () => context.go('/adventure'),
                  color: AppTheme.blue,
                  shadowColor: const Color(0xFF1E3A8A),
                ),
              ] else ...[
                // Quick Play Buttons
                BigButton(
                  label: 'Play Again 🔄',
                  onTap: () => context.go('/countdown'),
                  color: AppTheme.green,
                  shadowColor: const Color(0xFF15803D),
                ),
                const SizedBox(height: 12),
                GhostButton(label: '🏠 Return Home', onTap: () => context.go('/home')),
              ]
            ],
          ),
        ),
      ),
    );
  }
}

// ── UI Helpers ──

class _AnimatedStar extends StatelessWidget {
  final bool visible;
  final int delayMs;

  const _AnimatedStar({required this.visible, required this.delayMs});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: visible ? 1.0 : 0.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.elasticOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Dark background placeholder slot
              const Icon(Icons.star, size: 70, color: Color(0xFF2C3E50)),
              // The golden star
              if (visible)
                Icon(Icons.star, size: 70, color: AppTheme.yellow, shadows: [
                  Shadow(color: AppTheme.yellowLight.withOpacity(0.5), blurRadius: 15, offset: const Offset(0, 4))
                ]),
            ],
          ),
        );
      },
    );
  }
}

class _ConfettiBurst extends StatelessWidget {
  const _ConfettiBurst();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.5, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.green,
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Text('🎉 NEW RECORD! 🎉', style: AppTheme.body(14, color: Colors.white, weight: FontWeight.w900)),
          ),
        );
      },
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _StatRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTheme.body(18, color: AppTheme.textSecondary)),
        Text(value, style: AppTheme.display(24, color: valueColor ?? AppTheme.textPrimary)),
      ],
    );
  }
}