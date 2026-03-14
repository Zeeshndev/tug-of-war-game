import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_providers.dart';
import '../models/game_models.dart';
import '../utils/theme.dart';
import '../widgets/rope_widget.dart';
import '../widgets/ai_feedback_widget.dart';
import '../widgets/common_widgets.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});
  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen>
    with TickerProviderStateMixin {
  bool _wrongShake = false;
  
  // ── Combo Animation Controllers ──
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  int _lastStreak = 0;
  bool _showComboText = false;
  String _comboMessage = "";

  // ── End Game Animation Controllers (UC-004) ──
  bool _showEndAnimation = false;
  String _endState = ''; // 'win', 'lose', or 'draw'

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKey);

    // Initialize the master screen shake controller
    _shakeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
        
    // A rapid back-and-forth shake sequence
    _shakeAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKey);
    _shakeController.dispose();
    super.dispose();
  }

  bool _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    final label = event.logicalKey.keyLabel;
    if (RegExp(r'^\d$').hasMatch(label)) { ref.read(gameProvider.notifier).appendDigit(label); return true; }
    if (event.logicalKey == LogicalKeyboardKey.backspace) { ref.read(gameProvider.notifier).deleteDigit(); return true; }
    if (event.logicalKey == LogicalKeyboardKey.enter) { _submit(); return true; }
    return false;
  }

  void _submit() {
    final s = ref.read(gameProvider);
    if (s.currentInput.isEmpty) { _shake(); return; }
    ref.read(gameProvider.notifier).submitAnswer();
  }

  void _shake() {
    setState(() => _wrongShake = true);
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _wrongShake = false);
    });
  }

  // ── Trigger Combo Effects ──
  void _triggerComboEffect(int streak) {
    HapticFeedback.heavyImpact(); // Physical punch
    _shakeController.forward(from: 0.0); // Screen shake

    // Determine the hype text
    if (streak == 3) _comboMessage = "COMBO 3!";
    else if (streak == 5) _comboMessage = "SUPER PULL!";
    else if (streak == 10) _comboMessage = "UNSTOPPABLE!";
    else _comboMessage = "BOOM!";

    setState(() => _showComboText = true);

    // Hide text after 1 second
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) setState(() => _showComboText = false);
    });
  }

  // ── Trigger End Game Animation (UC-004) ──
  void _triggerEndAnimation(GameSession session) {
    if (!mounted) return;

    String outcome;
    if (session.ropePosition <= -10.0 || (session.timeLeft == 0 && session.ropePosition < 0)) {
      outcome = 'win';
    } else if (session.ropePosition >= 10.0 || (session.timeLeft == 0 && session.ropePosition > 0)) {
      outcome = 'lose';
    } else {
      outcome = 'draw';
    }

    setState(() {
      _endState = outcome;
      _showEndAnimation = true;
    });

    // Wait 1.5 seconds, then navigate to result screen
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) context.go('/result');
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(gameProvider);
    final progress = ref.watch(progressProvider);

    // Listen for state changes to trigger navigation OR combo animations
    ref.listen(gameProvider, (prev, next) {
      if (prev?.active == true && !next.active) {
        // Trigger end match animation instead of instant navigation
        _triggerEndAnimation(next);
      }

      // Check if a combo milestone was just hit
      if (prev != null) {
        if (next.sessionStreak == 3 && prev.sessionStreak == 2) _triggerComboEffect(3);
        if (next.sessionStreak == 5 && prev.sessionStreak == 4) _triggerComboEffect(5);
        if (next.sessionStreak == 10 && prev.sessionStreak == 9) _triggerComboEffect(10);
      }
    });

    final urgent = session.timeLeft <= 10;

    // We wrap the entire Scaffold body in an AnimatedBuilder connected to the shake controller
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: AnimatedBuilder(
        animation: _shakeAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(_shakeAnimation.value, 0), // Shakes left to right
            child: child,
          );
        },
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  // ── Top header ─────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                    child: Row(
                      children: [
                        _TimerBadge(seconds: session.timeLeft, urgent: urgent),
                        const SizedBox(width: 8),
                        _StreakBadge(streak: session.sessionStreak),
                        const Spacer(),
                        _PauseBtn(onTap: _pauseGame),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),

                  // ── Scores ─────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        _ScoreBadge(label: 'YOU', score: session.playerScore, color: AppTheme.blue),
                        const Spacer(),
                        Text('VS', style: AppTheme.display(16, color: AppTheme.textSecondary)),
                        const Spacer(),
                        _ScoreBadge(label: 'CPU', score: session.aiScore, color: AppTheme.red),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),

                  // ── Rope + Characters ───────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: RopeWidget(
                      ropePosition: session.ropePosition,
                      playerCharId: progress.selectedCharacter,
                      ropeId: progress.selectedRope,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // ── AI panel ────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: AiFeedbackWidget(
                      aiState: session.aiState,
                      aiQuestion: session.aiQuestion,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // ── Player question + 7s timer ──────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: _PlayerQuestionArea(session: session),
                  ),
                  const SizedBox(height: 6),

                  // ── Answer display ──────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: _AnswerBox(
                      input: session.currentInput,
                      shake: _wrongShake,
                      isCorrect: session.playerAnsweredCorrect,
                      isWrong: session.playerAnsweredWrong,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // ── Keypad ──────────────────────────────────
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                      child: _CompactKeypad(
                        onDigit: (d) => ref.read(gameProvider.notifier).appendDigit(d),
                        onDelete: () => ref.read(gameProvider.notifier).deleteDigit(),
                        onSubmit: _submit,
                      ),
                    ),
                  ),
                ],
              ),
              
              // ── DYNAMIC COMBO OVERLAY ──
              if (_showComboText)
                Center(
                  child: TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0.5, end: 1.0),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.elasticOut,
                    builder: (context, scale, child) {
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          decoration: BoxDecoration(
                            color: AppTheme.yellow,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.yellowLight.withOpacity(0.5),
                                blurRadius: 20,
                                spreadRadius: 5,
                              )
                            ]
                          ),
                          child: Text(
                            _comboMessage,
                            style: AppTheme.display(42, color: AppTheme.bg),
                          ),
                        ),
                      );
                    },
                  ),
                ),

              // ── END GAME ANIMATION OVERLAY (UC-004) ──
              _buildEndAnimationOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEndAnimationOverlay() {
    if (!_showEndAnimation) return const SizedBox.shrink();

    String title;
    Color color;
    String emoji;

    switch (_endState) {
      case 'win':
        title = 'YOU WIN!';
        color = AppTheme.green;
        emoji = '🏆 🎉';
        break;
      case 'lose':
        title = 'CPU WINS!';
        color = AppTheme.red;
        emoji = '😢';
        break;
      case 'draw':
      default:
        title = 'IT\'S A DRAW!';
        color = AppTheme.yellow;
        emoji = '🤝';
        break;
    }

    return Container(
      color: Colors.black.withOpacity(0.7), 
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 600),
          curve: Curves.elasticOut,
          tween: Tween<double>(begin: 0.0, end: 1.0),
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 80)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: color.withOpacity(0.5), blurRadius: 20, spreadRadius: 5)
                      ]
                    ),
                    child: Text(
                      title,
                      style: AppTheme.display(42, color: Colors.white).copyWith(
                        letterSpacing: 2,
                        shadows: const [Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 4))]
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _pauseGame() {
    ref.read(gameProvider.notifier).pause();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _PauseDialog(
        onResume: () { Navigator.pop(context); ref.read(gameProvider.notifier).resume(); },
        onRestart: () { Navigator.pop(context); ref.read(gameProvider.notifier).forceEnd(); context.go('/countdown'); },
        onQuit: () { Navigator.pop(context); ref.read(gameProvider.notifier).forceEnd(); context.go('/home'); },
      ),
    );
  }
}

// ── Timer badge ─────────────────────────────────────────
class _TimerBadge extends StatelessWidget {
  final int seconds;
  final bool urgent;
  const _TimerBadge({required this.seconds, required this.urgent});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.bg2,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: urgent ? AppTheme.red : AppTheme.bg3, width: 2),
      ),
      child: Text('${seconds}s', style: AppTheme.display(24,
          color: urgent ? AppTheme.redLight : AppTheme.textPrimary)),
    );
  }
}

class _StreakBadge extends StatelessWidget {
  final int streak;
  const _StreakBadge({required this.streak});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.yellow.withOpacity(0.1),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: AppTheme.yellow.withOpacity(0.3)),
      ),
      child: Row(children: [
        const Text('🔥', style: TextStyle(fontSize: 14)),
        const SizedBox(width: 4),
        Text('$streak', style: AppTheme.display(14, color: AppTheme.yellowLight)),
      ]),
    );
  }
}

class _PauseBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _PauseBtn({required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.bg2,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: AppTheme.bg3),
        ),
        child: Text('⏸ Pause', style: AppTheme.body(12, color: AppTheme.textSecondary)),
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  final String label;
  final int score;
  final Color color;
  const _ScoreBadge({required this.label, required this.score, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.bg2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(children: [
        Text(label, style: AppTheme.body(10, color: AppTheme.textSecondary)),
        Text('$score', style: AppTheme.display(26, color: color)),
      ]),
    );
  }
}

// ── Player question area with 7s countdown ring ─────────
class _PlayerQuestionArea extends StatelessWidget {
  final GameSession session;
  const _PlayerQuestionArea({required this.session});

  @override
  Widget build(BuildContext context) {
    final q = session.playerQuestion;
    final qPct = session.questionTimeLeft / 7.0;
    final qUrgent = session.questionTimeLeft <= 3;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: session.playerAnsweredCorrect
            ? const Color(0xFF065F46)
            : session.playerAnsweredWrong
                ? const Color(0xFF7F1D1D)
                : AppTheme.bg2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: session.playerAnsweredCorrect
              ? AppTheme.green
              : session.playerAnsweredWrong
                  ? AppTheme.red
                  : AppTheme.bg3,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (q != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.blue.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text('${q.skill.emoji} ${q.skill.label}',
                        style: AppTheme.body(10, color: AppTheme.blueLight)),
                  ),
                const SizedBox(height: 4),
                Text(q?.displayText ?? '...', style: AppTheme.display(36)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 44, height: 44,
            child: Stack(alignment: Alignment.center, children: [
              CircularProgressIndicator(
                value: qPct,
                strokeWidth: 5,
                backgroundColor: AppTheme.bg3,
                valueColor: AlwaysStoppedAnimation(
                    qUrgent ? AppTheme.redLight : AppTheme.blueLight),
              ),
              Text('${session.questionTimeLeft}',
                  style: AppTheme.display(16,
                      color: qUrgent ? AppTheme.redLight : AppTheme.textPrimary)),
            ]),
          ),
        ],
      ),
    );
  }
}

// ── Answer display box ───────────────────────────────────
class _AnswerBox extends StatefulWidget {
  final String input;
  final bool shake, isCorrect, isWrong;
  const _AnswerBox({required this.input, required this.shake,
      required this.isCorrect, required this.isWrong});
  @override
  State<_AnswerBox> createState() => _AnswerBoxState();
}
class _AnswerBoxState extends State<_AnswerBox> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _a = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -8.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: 0.0), weight: 1),
    ]).animate(_c);
  }
  @override
  void didUpdateWidget(_AnswerBox old) {
    super.didUpdateWidget(old);
    if (widget.shake && !old.shake) _c.forward(from: 0);
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(animation: _a, builder: (_, __) => Transform.translate(
      offset: Offset(_a.value, 0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(width: 2.5, color:
            widget.isCorrect ? AppTheme.green :
            widget.isWrong ? AppTheme.red :
            widget.input.isNotEmpty ? AppTheme.blue : AppTheme.bg3),
        ),
        child: Center(child: Text(
          widget.input.isEmpty ? '?' : widget.input,
          style: AppTheme.display(32, color: widget.input.isEmpty ? AppTheme.bg3 : AppTheme.textPrimary),
        )),
      ),
    ));
  }
}

// ── Compact keypad that fits in Expanded ─────────────────
class _CompactKeypad extends StatelessWidget {
  final Function(String) onDigit;
  final VoidCallback onDelete, onSubmit;
  const _CompactKeypad({required this.onDigit, required this.onDelete, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        final rowH = (h - 18) / 4; 
        return Column(
          children: [
            _row(['7','8','9'], rowH),
            const SizedBox(height: 6),
            _row(['4','5','6'], rowH),
            const SizedBox(height: 6),
            _row(['1','2','3'], rowH),
            const SizedBox(height: 6),
            _row(['⌫','0','✓'], rowH, last: true),
          ],
        );
      },
    );
  }

  Widget _row(List<String> keys, double h, {bool last = false}) {
    return SizedBox(
      height: h,
      child: Row(
        children: keys.asMap().entries.map((e) {
          final i = e.key; final k = e.value;
          return Expanded(child: Padding(
            padding: EdgeInsets.only(left: i == 0 ? 0 : 6),
            child: _Key(
              label: k,
              onTap: () {
                if (k == '⌫') onDelete();
                else if (k == '✓') onSubmit();
                else onDigit(k);
              },
              isDelete: k == '⌫',
              isSubmit: k == '✓',
            ),
          ));
        }).toList(),
      ),
    );
  }
}

class _Key extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final bool isDelete, isSubmit;
  const _Key({required this.label, required this.onTap, this.isDelete = false, this.isSubmit = false});
  @override
  State<_Key> createState() => _KeyState();
}
class _KeyState extends State<_Key> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    Color bg = widget.isSubmit ? AppTheme.green :
               widget.isDelete ? AppTheme.bg3 : AppTheme.bg2;
    Color border = widget.isSubmit ? AppTheme.green :
                   widget.isDelete ? AppTheme.bg3 : const Color(0xFF3D5270);
    if (_pressed) { bg = AppTheme.blue; border = AppTheme.blue; }

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border, width: 1.5),
          boxShadow: [
            BoxShadow(color: Colors.black38, offset: const Offset(0, 3), blurRadius: 0),
          ],
        ),
        child: Center(
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: widget.isSubmit ? 16 : widget.isDelete ? 18 : 22,
              fontWeight: FontWeight.w800,
              color: widget.isSubmit ? Colors.white :
                     widget.isDelete ? AppTheme.redLight : AppTheme.textPrimary,
              fontFamily: widget.isSubmit || widget.isDelete ? null : 'Fredoka',
            ),
          ),
        ),
      ),
    );
  }
}

// ── Pause dialog ──────────────────────────────────────────
class _PauseDialog extends StatelessWidget {
  final VoidCallback onResume, onRestart, onQuit;
  const _PauseDialog({required this.onResume, required this.onRestart, required this.onQuit});
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.bg2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('⏸ Paused', style: AppTheme.display(36)),
          const SizedBox(height: 24),
          BigButton(label: '▶ Resume', onTap: onResume, color: AppTheme.green, shadowColor: const Color(0xFF15803D)),
          const SizedBox(height: 10),
          BigButton(label: '🔄 Restart', onTap: onRestart, color: AppTheme.yellow, shadowColor: const Color(0xFFD97706)),
          const SizedBox(height: 10),
          GhostButton(label: '🏠 Quit to Home', onTap: onQuit),
        ]),
      ),
    );
  }
}