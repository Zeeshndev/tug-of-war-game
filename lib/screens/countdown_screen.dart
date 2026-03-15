import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_providers.dart';
import '../utils/theme.dart';

class CountdownScreen extends ConsumerStatefulWidget {
  const CountdownScreen({super.key});

  @override
  ConsumerState<CountdownScreen> createState() => _CountdownScreenState();
}

class _CountdownScreenState extends ConsumerState<CountdownScreen> with TickerProviderStateMixin {
  // Sequence state variables
  bool _charsSlidIn = false;
  bool _ropeSnapped = false;
  String _countText = "";
  bool _showModeText = false;
  
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    
    // For the "1" red border pulse requirement
    _pulseController = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 400),
    )..repeat(reverse: true);

    // Start the strict sequence (UC-005 Main Flow)
    _runCountdownSequence();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _runCountdownSequence() async {
    // 1. Initial dark background hold
    await Future.delayed(const Duration(milliseconds: 300));
    
    if (!mounted) return;
    
    // 2 & 3. Characters slide in
    setState(() => _charsSlidIn = true);
    await Future.delayed(const Duration(milliseconds: 400));
    
    if (!mounted) return;

    // 4. Rope appears with snap
    setState(() => _ropeSnapped = true);
    HapticFeedback.selectionClick();
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (!mounted) return;

    // 5. "3" appears
    _triggerNumber("3");
    await Future.delayed(const Duration(milliseconds: 1000));
    
    if (!mounted) return;

    // 6. "2" appears
    _triggerNumber("2");
    await Future.delayed(const Duration(milliseconds: 1000));
    
    if (!mounted) return;

    // 7. "1" appears (Pulse starts automatically based on text value in build)
    _triggerNumber("1");
    await Future.delayed(const Duration(milliseconds: 1000));
    
    if (!mounted) return;

    // 8. "GO!" heavy impact
    HapticFeedback.heavyImpact();
    setState(() {
      _countText = "GO!";
      _showModeText = true; // 9. Show game mode
    });
    
    // 10. Start the game engine and transition to GameScreen
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) {
      // 🚨 THIS IS THE FIX: Tell the Riverpod provider to start the match! 🚨
      ref.read(gameProvider.notifier).startMatch(); 
      context.go('/game');
    }
  }

  void _triggerNumber(String num) {
    HapticFeedback.lightImpact(); // Drumroll haptic
    setState(() {
      _countText = num;
    });
  }

  // ── Helper to format the UI text based on settings ──
  String _formatMode(String mode) {
    switch(mode) {
      case 'addition': return 'Addition Mode';
      case 'subtraction': return 'Subtraction Mode';
      case 'multiplication': return 'Multiplication Mode';
      case 'division': return 'Division Mode';
      default: return 'Mixed Mode';
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final progress = ref.watch(progressProvider);
    
    final isOne = _countText == "1";
    final isGo = _countText == "GO!";

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A), // Requirement: Dark background
      body: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          // Requirement: "1" replaces "2"... Red border pulses.
          return Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: isOne 
                  ? Colors.red.withOpacity(0.5 + (_pulseController.value * 0.5)) 
                  : Colors.transparent,
                width: isOne ? 8.0 : 0.0,
              ),
            ),
            child: child,
          );
        },
        child: SafeArea(
          child: Stack(
            alignment: Alignment.center,
            children: [
              
              // ── MATCH INFO (Top) ──
              Positioned(
                top: 60,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 500),
                  opacity: _countText.isNotEmpty ? 1.0 : 0.0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(color: Colors.white24)
                    ),
                    child: Text(
                      '${settings.matchDuration} SECOND MATCH',
                      style: AppTheme.body(16, color: Colors.white70, weight: FontWeight.w800).copyWith(letterSpacing: 2),
                    ),
                  ),
                ),
              ),

              // ── CHARACTER SLIDE-IN (Middle) ──
              Positioned(
                top: MediaQuery.of(context).size.height * 0.4,
                left: 0,
                right: 0,
                height: 120,
                child: Stack(
                  children: [
                    // CPU Team (Slides from Right)
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutBack,
                      right: _charsSlidIn ? 40 : -100,
                      top: 0,
                      child: _buildAvatarBox('🤖', AppTheme.red),
                    ),
                    
                    // Player Team (Slides from Left)
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutBack,
                      left: _charsSlidIn ? 40 : -100,
                      top: 0,
                      child: _buildAvatarBox(_getEmojiForSkin(progress.selectedCharacter), AppTheme.blue),
                    ),

                    // Rope Snap
                    if (_ropeSnapped)
                      Positioned(
                        top: 50,
                        left: 100,
                        right: 100,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 200),
                          builder: (context, scale, child) {
                            return Transform.scale(
                              scale: scale,
                              child: Container(
                                height: 8,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD2B48C),
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 4))]
                                ),
                              ),
                            );
                          },
                        ),
                      )
                  ],
                ),
              ),

              // ── COUNTDOWN TEXT (Center) ──
              if (_countText.isNotEmpty)
                Center(
                  child: TweenAnimationBuilder<double>(
                    // Key forces the animation to re-run every time _countText changes
                    key: ValueKey(_countText),
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.elasticOut,
                    builder: (context, scale, child) {
                      return Transform.scale(
                        scale: scale,
                        child: Text(
                          _countText,
                          style: AppTheme.display(isGo ? 120 : 160, color: isGo ? AppTheme.green : Colors.white).copyWith(
                            shadows: [
                              Shadow(color: isGo ? AppTheme.green.withOpacity(0.5) : Colors.black54, blurRadius: 20, offset: const Offset(0, 10))
                            ]
                          ),
                        ),
                      );
                    },
                  ),
                ),

              // ── GAME MODE FADE IN (Bottom) ──
              if (_showModeText)
                Positioned(
                  bottom: MediaQuery.of(context).size.height * 0.3,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 500),
                    builder: (context, opacity, child) {
                      return Opacity(
                        opacity: opacity,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.yellow,
                            borderRadius: BorderRadius.circular(50),
                            boxShadow: [BoxShadow(color: AppTheme.yellow.withOpacity(0.4), blurRadius: 20, spreadRadius: 5)]
                          ),
                          child: Text(
                            _formatMode(settings.gameMode).toUpperCase(),
                            style: AppTheme.display(24, color: AppTheme.bg),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
            ],
          ),
        ),
      ),
    );
  }

  // Fallback simplified avatar for the countdown screen
  Widget _buildAvatarBox(String emoji, Color color) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 3),
        boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 15, spreadRadius: 2)],
      ),
      child: Center(
        child: Text(emoji, style: const TextStyle(fontSize: 40, shadows: [Shadow(color: Colors.black, blurRadius: 10)])),
      ),
    );
  }

  String _getEmojiForSkin(String skinId) {
    switch (skinId) {
      case 'ninja': return '🥷';
      case 'wizard': return '🧙‍♂️';
      case 'dragon': return '🐉';
      case 'hero':
      default: return '🦸';
    }
  }
}