import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_providers.dart';
import '../models/game_models.dart';
import '../utils/theme.dart';
import '../widgets/common_widgets.dart';

// ── World Data Model ──
class WorldData {
  final String id;
  final String name;
  final String subtitle;
  final String emoji;
  final Color primaryColor;
  final Color secondaryColor;
  final bool isPremium;
  final GameMode mode;
  final int totalLevels;

  WorldData({
    required this.id, required this.name, required this.subtitle,
    required this.emoji, required this.primaryColor, required this.secondaryColor,
    this.isPremium = false, required this.mode, this.totalLevels = 10,
  });
}

class AdventureScreen extends ConsumerStatefulWidget {
  const AdventureScreen({super.key});

  @override
  ConsumerState<AdventureScreen> createState() => _AdventureScreenState();
}

class _AdventureScreenState extends ConsumerState<AdventureScreen> with SingleTickerProviderStateMixin {
  late AnimationController _bgAnimController;

  final List<WorldData> _worlds = [
    WorldData(id: 'w1', name: 'Forest of Addition', subtitle: 'Year 1 • Single Digit', emoji: '🌲', primaryColor: const Color(0xFF22C55E), secondaryColor: const Color(0xFF166534), mode: GameMode.additionOnly),
    WorldData(id: 'w2', name: 'Subtraction Swamp', subtitle: 'Year 2 • Double Digit', emoji: '🐊', primaryColor: const Color(0xFF8B5CF6), secondaryColor: const Color(0xFF4C1D95), mode: GameMode.subtractionOnly),
    WorldData(id: 'w3', name: 'Multiplication Mountain', subtitle: 'Year 3 • Times Tables', emoji: '⛰️', primaryColor: const Color(0xFF94A3B8), secondaryColor: const Color(0xFF334155), mode: GameMode.multiplicationOnly),
    WorldData(id: 'w4', name: 'Division Desert', subtitle: 'Year 4 • Sharing', emoji: '🐪', primaryColor: const Color(0xFFEAB308), secondaryColor: const Color(0xFF854D0E), isPremium: true, mode: GameMode.divisionOnly),
    WorldData(id: 'w5', name: 'Mixed Space Station', subtitle: 'Year 5-6 • All Operations', emoji: '🚀', primaryColor: const Color(0xFF0F172A), secondaryColor: const Color(0xFF020617), isPremium: true, mode: GameMode.mixed),
  ];

  @override
  void initState() {
    super.initState();
    _bgAnimController = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();
  }

  @override
  void dispose() {
    _bgAnimController.dispose();
    super.dispose();
  }

  void _openLevelSelector(WorldData world) {
    if (world.isPremium) {
      _showPremiumModal();
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _LevelSelectorSheet(world: world),
    );
  }

  void _showPremiumModal() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: AppTheme.bg2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('👑', style: TextStyle(fontSize: 60)),
              const SizedBox(height: 16),
              Text('Premium World', style: AppTheme.display(28, color: AppTheme.yellow)),
              const SizedBox(height: 8),
              Text('Unlock the Division Desert and Space Station by joining Brain Champions Premium!', 
                textAlign: TextAlign.center, style: AppTheme.body(16, color: AppTheme.textSecondary)),
              const SizedBox(height: 24),
              BigButton(label: 'Unlock Now', onTap: () => Navigator.pop(context), color: AppTheme.yellow, shadowColor: const Color(0xFFD97706)),
              const SizedBox(height: 12),
              GhostButton(label: 'Maybe Later', onTap: () => Navigator.pop(context)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(progressProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF87CEEB), 
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _bgAnimController,
            builder: (context, child) {
              return Stack(
                children: [
                  Positioned(left: -200 + (_bgAnimController.value * 400), top: 100, child: const Text('☁️', style: TextStyle(fontSize: 100, color: Colors.white54))),
                  Positioned(right: -100 + (_bgAnimController.value * 300), top: 250, child: const Text('☁️', style: TextStyle(fontSize: 80, color: Colors.white54))),
                  Positioned(left: -50 + (_bgAnimController.value * 200), top: 500, child: const Text('☁️', style: TextStyle(fontSize: 120, color: Colors.white54))),
                ],
              );
            },
          ),

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
                        onPressed: () => context.go('/home'),
                      ),
                      const Spacer(),
                      _StatBadge(icon: '⭐', value: '${progress.totalWins * 3}', color: AppTheme.yellow),
                      const SizedBox(width: 8),
                      _StatBadge(icon: '🪙', value: '${progress.coins}', color: AppTheme.yellowLight),
                    ],
                  ),
                ),

                const SizedBox(height: 10),
                Text('Adventure Map', style: AppTheme.display(42, color: Colors.white).copyWith(
                  shadows: const [Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 3))]
                )),
                const SizedBox(height: 20),

                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    itemCount: _worlds.length,
                    itemBuilder: (context, index) {
                      final world = _worlds[index];
                      final isLeft = index % 2 == 0; 
                      
                      // 🚨 FIX: Calculate real progress bar completion!
                      int worldStars = 0;
                      for(int i = 1; i <= world.totalLevels; i++) {
                        worldStars += progress.adventureStars['${world.mode.name}_$i'] ?? 0;
                      }
                      double progressFactor = worldStars / (world.totalLevels * 3);
                      
                      return Align(
                        alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () => _openLevelSelector(world),
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.75,
                            margin: const EdgeInsets.only(bottom: 40),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [world.primaryColor, world.secondaryColor], begin: Alignment.topLeft, end: Alignment.bottomRight),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.white.withOpacity(0.3), width: 3),
                              boxShadow: [BoxShadow(color: world.secondaryColor.withOpacity(0.5), blurRadius: 15, offset: const Offset(0, 8))]
                            ),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('WORLD ${index + 1}', style: AppTheme.body(14, color: Colors.white70, weight: FontWeight.w900).copyWith(letterSpacing: 2)),
                                      const SizedBox(height: 4),
                                      Text(world.name, style: AppTheme.display(24, color: Colors.white)),
                                      const SizedBox(height: 4),
                                      Text(world.subtitle, style: AppTheme.body(14, color: Colors.white)),
                                      const SizedBox(height: 16),
                                      
                                      // Real Progress Bar
                                      Container(
                                        height: 8, width: double.infinity,
                                        decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(4)),
                                        child: FractionallySizedBox(
                                          alignment: Alignment.centerLeft,
                                          widthFactor: progressFactor, // Real dynamic width
                                          child: Container(decoration: BoxDecoration(color: AppTheme.yellow, borderRadius: BorderRadius.circular(4))),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                                Positioned(
                                  top: -20, right: isLeft ? -10 : null, left: isLeft ? null : -10,
                                  child: Text(world.emoji, style: const TextStyle(fontSize: 60, shadows: [Shadow(color: Colors.black38, blurRadius: 10, offset: Offset(0, 5))])),
                                ),
                                if (world.isPremium)
                                  Positioned(
                                    bottom: -15, right: 20,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(color: AppTheme.red, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white, width: 2)),
                                      child: Row(children: [
                                        const Icon(Icons.lock, color: Colors.white, size: 14),
                                        const SizedBox(width: 4),
                                        Text('PREMIUM', style: AppTheme.body(12, color: Colors.white, weight: FontWeight.w900)),
                                      ]),
                                    ),
                                  )
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelSelectorSheet extends ConsumerWidget {
  final WorldData world;
  const _LevelSelectorSheet({required this.world});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider); // Get the real saved data

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: AppTheme.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: AppTheme.bg3, width: 2),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(width: 50, height: 6, decoration: BoxDecoration(color: AppTheme.bg3, borderRadius: BorderRadius.circular(10))),
          const SizedBox(height: 20),
          Text(world.name, style: AppTheme.display(32, color: world.primaryColor)),
          Text('Select a Level', style: AppTheme.body(16, color: AppTheme.textSecondary)),
          const SizedBox(height: 20),
          
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, crossAxisSpacing: 20, mainAxisSpacing: 20, childAspectRatio: 0.8
              ),
              itemCount: world.totalLevels,
              itemBuilder: (context, index) {
                final levelNum = index + 1;
                final isBoss = levelNum == world.totalLevels;

                // 🚨 FIX: Fetch the actual stars from Riverpod Memory
                final currentKey = '${world.mode.name}_$levelNum';
                final prevKey = '${world.mode.name}_${levelNum - 1}';
                
                final currentStars = progress.adventureStars[currentKey] ?? 0;
                final prevStars = progress.adventureStars[prevKey] ?? 0;
                
                // Unlocked if it is Level 1, OR if you earned at least 1 star on the previous level
                final isUnlocked = levelNum == 1 || prevStars > 0;

                return GestureDetector(
                  onTap: () {
                    if (!isUnlocked) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: const Text('Complete the previous level to unlock this one! ⭐'),
                        backgroundColor: AppTheme.red,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ));
                      return;
                    }

                    Navigator.pop(context);
                    ref.read(settingsProvider.notifier).setGameMode(world.mode);
                    ref.read(matchConfigProvider.notifier).state = {
                      'isAdventure': true,
                      'level': levelNum,
                      'isBoss': isBoss
                    };
                    context.go('/countdown');
                  },
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isUnlocked ? (isBoss ? AppTheme.red : world.primaryColor) : AppTheme.bg2,
                            border: Border.all(color: isUnlocked ? Colors.white : AppTheme.bg3, width: 3),
                            boxShadow: isUnlocked ? [BoxShadow(color: world.primaryColor.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 4))] : [],
                          ),
                          child: Center(
                            child: isUnlocked 
                              ? Text(isBoss ? '👹' : '$levelNum', style: AppTheme.display(28, color: Colors.white))
                              : const Icon(Icons.lock, color: Colors.white38, size: 28),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // 🚨 FIX: Draw real earned stars!
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.star, size: 16, color: currentStars >= 1 ? AppTheme.yellow : AppTheme.bg3),
                          Icon(Icons.star, size: 16, color: currentStars >= 2 ? AppTheme.yellow : AppTheme.bg3),
                          Icon(Icons.star, size: 16, color: currentStars >= 3 ? AppTheme.yellow : AppTheme.bg3),
                        ],
                      )
                    ],
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String icon; final String value; final Color color;
  const _StatBadge({required this.icon, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(20)),
      child: Row(children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 6),
        Text(value, style: AppTheme.display(18, color: color)),
      ]),
    );
  }
}