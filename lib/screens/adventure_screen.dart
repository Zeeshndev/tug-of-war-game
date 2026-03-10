import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_providers.dart';
import '../utils/theme.dart';
import '../services/audio_service.dart';

class AdventureScreen extends ConsumerWidget {
  const AdventureScreen({super.key});

  final int _totalLevels = 20;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider);
    final totalWins = progress.totalWins;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(children: [
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.bg2, borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.bg3)),
                    child: const Center(child: Text('←', style: TextStyle(fontSize: 20, color: AppTheme.textPrimary))),
                  ),
                ),
                const SizedBox(width: 12),
                Text('🗺️ Adventure', style: AppTheme.display(26, color: AppTheme.yellowLight)),
              ]),
            ),

            // ── World Map List ────────────────────────
            Expanded(
              child: ListView.builder(
                reverse: true, // Start at the bottom!
                padding: const EdgeInsets.symmetric(vertical: 40),
                itemCount: _totalLevels,
                itemBuilder: (context, index) {
                  final level = index + 1;
                  final winsNeeded = (level - 1) * 2;
                  final isUnlocked = totalWins >= winsNeeded;
                  final isCurrent = isUnlocked && totalWins < (level * 2);
                  final isBoss = level % 5 == 0; 

                  final alignOffset = (index % 4 == 0) ? 0.0 
                                    : (index % 4 == 1) ? 0.4 
                                    : (index % 4 == 2) ? 0.0 
                                    : -0.4;

                  return _MapNode(
                    level: level,
                    isUnlocked: isUnlocked,
                    isCurrent: isCurrent,
                    isBoss: isBoss,
                    alignOffset: alignOffset,
                    winsNeeded: winsNeeded,
                    onTap: () {
                      if (!isUnlocked) return;
                      // Tell the engine we are playing a map level
                      ref.read(matchConfigProvider.notifier).state = {
                        'isAdventure': true,
                        'level': level,
                        'isBoss': isBoss
                      };
                      AudioService().setBgmState(BgmState.menu);
                      context.push('/countdown');
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapNode extends StatelessWidget {
  final int level, winsNeeded;
  final bool isUnlocked, isCurrent, isBoss;
  final double alignOffset;
  final VoidCallback onTap;

  const _MapNode({
    required this.level, required this.winsNeeded, required this.isUnlocked, 
    required this.isCurrent, required this.isBoss, required this.alignOffset, required this.onTap
  });

  @override
  Widget build(BuildContext context) {
    Color nodeColor = isCurrent ? AppTheme.yellow 
                    : isUnlocked ? AppTheme.green 
                    : AppTheme.bg3;
    Color iconColor = isCurrent ? AppTheme.bg : Colors.white;
    String icon = isBoss ? '👹' : isUnlocked ? '⭐' : '🔒';
    if (isCurrent && !isBoss) icon = '📍';

    return Container(
      height: 110,
      alignment: Alignment(alignOffset, 0),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          if (level < 20)
            Positioned(
              top: -55, 
              child: Container(
                width: 8, height: 60,
                decoration: BoxDecoration(
                  color: isUnlocked && !isCurrent ? AppTheme.green : AppTheme.bg3,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          
          GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isBoss ? 80 : 65,
              height: isBoss ? 80 : 65,
              decoration: BoxDecoration(
                color: nodeColor,
                shape: BoxShape.circle,
                border: Border.all(color: isCurrent ? Colors.white : Colors.transparent, width: 4),
                boxShadow: isCurrent ? [
                  BoxShadow(color: AppTheme.yellow.withOpacity(0.6), blurRadius: 20, spreadRadius: 5)
                ] : [],
              ),
              child: Center(
                child: Text(icon, style: TextStyle(fontSize: isBoss ? 32 : 24, color: iconColor)),
              ),
            ),
          ),

          Positioned(
            bottom: -22,
            child: Text(
              isBoss ? 'BOSS $level' : 'Level $level',
              style: AppTheme.body(12, color: isUnlocked ? AppTheme.textPrimary : AppTheme.textSecondary, weight: FontWeight.w900),
            ),
          ),
          
          if (!isUnlocked)
            Positioned(
              top: -25,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppTheme.bg2, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.bg3)),
                child: Text('Needs $winsNeeded Wins', style: AppTheme.body(9, color: AppTheme.redLight)),
              ),
            ),
        ],
      ),
    );
  }
}