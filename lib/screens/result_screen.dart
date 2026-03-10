import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_providers.dart';
import '../models/game_models.dart';
import '../utils/theme.dart';
import '../widgets/common_widgets.dart';
import '../services/audio_service.dart';

class ResultScreen extends ConsumerStatefulWidget {
  const ResultScreen({super.key});
  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {
  late ConfettiController _confetti;
  int _brainPower = 100;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 4));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final s   = ref.read(gameProvider);
      final dur = ref.read(settingsProvider).matchDuration;
      final prog= ref.read(progressProvider);
      final power  = calculateBrainPower(
        correct:         s.sessionCorrect,
        answered:        s.sessionAnswered,
        bestStreak:      s.sessionBestStreak,
        matchDuration:   dur,
        totalResponseMs: prog.totalResponseTimeMs,
        responsesCount:  prog.totalQuestionsAnswered,
      );
      setState(() => _brainPower = power);
      if (_outcome(s) == MatchOutcome.win) _confetti.play();
    });
  }

  @override
  void dispose() { _confetti.dispose(); super.dispose(); }

  MatchOutcome _outcome(GameSession s) {
    if (s.playerScore > s.aiScore) return MatchOutcome.win;
    if (s.aiScore > s.playerScore) return MatchOutcome.lose;
    return MatchOutcome.draw;
  }

  @override
  Widget build(BuildContext context) {
    final s       = ref.watch(gameProvider);
    final prog    = ref.watch(progressProvider);
    final profile = ref.watch(profileProvider);
    final outcome = _outcome(s);
    final dur     = ref.read(settingsProvider).matchDuration;

    final answered = s.sessionAnswered;
    final accPct   = answered == 0 ? '0%'
        : '${(s.sessionCorrect / answered * 100).round()}%';
    final cpm      = dur == 0 ? 0 : (s.sessionCorrect * 60 / dur).round();

    final cfg = switch (outcome) {
      MatchOutcome.win  => (e: '🏆', title: 'You Win!',    col: AppTheme.yellowLight),
      MatchOutcome.lose => (e: '😅', title: 'CPU Wins!',    col: AppTheme.textSecondary),
      MatchOutcome.draw => (e: '🤝', title: "It's a Draw!", col: AppTheme.blueLight),
    };

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Stack(children: [
        // Confetti
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confetti,
            blastDirectionality: BlastDirectionality.explosive,
            colors: const [AppTheme.yellow, AppTheme.red, AppTheme.blue,
                           AppTheme.green, AppTheme.purple],
            numberOfParticles: 40,
          ),
        ),

        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
            child: Column(children: [

              // ── Outcome ─────────────────────────────────────────────
              Text(cfg.e, style: const TextStyle(fontSize: 80)),
              const SizedBox(height: 4),
              Text(cfg.title, style: AppTheme.display(44, color: cfg.col)),
              Text('${profile.playerName} · ${_flag(profile.countryCode)}',
                  style: AppTheme.body(13, color: AppTheme.textSecondary)),
              const SizedBox(height: 18),

              // ── Brain Power Card ─────────────────────────────────────
              _BrainPowerCard(power: _brainPower),
              const SizedBox(height: 12),

              // ── Score row ────────────────────────────────────────────
              Row(children: [
                Expanded(child: _Stat('${s.playerScore}', 'Your Score', AppTheme.blue)),
                const SizedBox(width: 10),
                Expanded(child: _Stat('${s.aiScore}',     'CPU Score',  AppTheme.red)),
              ]),
              const SizedBox(height: 10),

              // ── Performance stats ─────────────────────────────────────
              Row(children: [
                Expanded(child: _Stat(accPct,  'Accuracy', AppTheme.green)),
                const SizedBox(width: 10),
                Expanded(child: _Stat('${s.sessionBestStreak}🔥', 'Best Streak', AppTheme.yellow)),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _Stat('$cpm/min', 'Speed', AppTheme.purple)),
                const SizedBox(width: 10),
                Expanded(child: _Stat('${s.sessionCorrect}/${s.sessionAnswered}',
                    'Correct / Total', AppTheme.blueLight)),
              ]),
              const SizedBox(height: 10),

              // ── Skill breakdown ────────────────────────────────────────
              _SkillBreakdown(prog: prog),
              const SizedBox(height: 12),

              // ── Coins ─────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.yellow.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.yellow.withOpacity(0.35), width: 2),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text('🪙', style: TextStyle(fontSize: 32)),
                  const SizedBox(width: 10),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('+${s.coinsEarned}',
                        style: AppTheme.display(28, color: AppTheme.yellowLight)),
                    Text('Coins Earned', style: AppTheme.body(11, color: AppTheme.textSecondary)),
                  ]),
                  const SizedBox(width: 24),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${prog.coins}', style: AppTheme.display(22, color: AppTheme.yellowLight)),
                    Text('Total', style: AppTheme.body(11, color: AppTheme.textSecondary)),
                  ]),
                ]),
              ),
              const SizedBox(height: 14),

              // ── Share card ─────────────────────────────────────────────
              _ShareCard(
                outcome: outcome, power: _brainPower, accPct: accPct,
                score: s.playerScore, streak: s.sessionBestStreak, cpm: cpm,
                playerName: profile.playerName, countryCode: profile.countryCode,
              ),
              const SizedBox(height: 18),

              // ── Actions ────────────────────────────────────────────────
              BigButton(
                label: '🔄 Play Again',
                onTap: () {
                  AudioService().setBgmState(BgmState.menu);
                  context.go('/countdown');
                },
                color: AppTheme.green,
                shadowColor: const Color(0xFF15803D),
              ),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: GhostButton(
                    label: '🏆 Leaderboard',
                    onTap: () {
                      AudioService().setBgmState(BgmState.menu);
                      context.push('/leaderboard');
                    })),
                const SizedBox(width: 10),
                Expanded(child: GhostButton(
                    label: '🏠 Home',
                    onTap: () {
                      AudioService().setBgmState(BgmState.menu);
                      context.go('/home');
                    })),
              ]),
            ]),
          ),
        ),
      ]),
    );
  }

  String _flag(String code) {
    if (code.length != 2) return '🌍';
    final b = 0x1F1E6 - 65;
    final c = code.toUpperCase().codeUnits;
    return String.fromCharCode(b + c[0]) + String.fromCharCode(b + c[1]);
  }
}

// ── Brain Power Card ─────────────────────────────────────────────────────────
class _BrainPowerCard extends StatelessWidget {
  final int power;
  const _BrainPowerCard({required this.power});

  @override
  Widget build(BuildContext context) {
    final col = power >= 130 ? AppTheme.yellowLight
              : power >= 110 ? AppTheme.greenLight
              : AppTheme.blueLight;
    final label = _label(power);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [col.withOpacity(0.16), col.withOpacity(0.05)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: col.withOpacity(0.45), width: 2),
      ),
      child: Row(children: [
        const Text('🧠', style: TextStyle(fontSize: 46)),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('BRAIN POWER', style: AppTheme.body(10, color: col, weight: FontWeight.w900)),
          Text('$power', style: AppTheme.display(54, color: col)),
          Text(label, style: AppTheme.body(13, color: col.withOpacity(0.85))),
        ])),
        Column(children: [
          _PowerBar(power: power),
          const SizedBox(height: 4),
          Text('Max: 160', style: AppTheme.body(9, color: AppTheme.textSecondary)),
        ]),
      ]),
    );
  }

  String _label(int pwr) {
    if (pwr >= 145) return 'Legendary 👑';
    if (pwr >= 130) return 'Epic 🌟';
    if (pwr >= 120) return 'Super ⚡';
    if (pwr >= 110) return 'Strong 💪';
    if (pwr >= 90)  return 'Solid 📊';
    return 'Growing 🌱';
  }
}

class _PowerBar extends StatelessWidget {
  final int power;
  const _PowerBar({required this.power});
  @override
  Widget build(BuildContext context) {
    final pct = ((power - 80) / 80.0).clamp(0.0, 1.0);
    return SizedBox(width: 64, height: 10, child: Stack(children: [
      Container(decoration: BoxDecoration(
          color: AppTheme.bg3, borderRadius: BorderRadius.circular(5))),
      FractionallySizedBox(widthFactor: pct, child: Container(
          decoration: BoxDecoration(
              color: AppTheme.yellowLight,
              borderRadius: BorderRadius.circular(5)))),
    ]));
  }
}

// ── Stat tile ─────────────────────────────────────────────────────────────────
class _Stat extends StatelessWidget {
  final String value, label;
  final Color color;
  const _Stat(this.value, this.label, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withOpacity(0.25)),
    ),
    child: Column(children: [
      Text(value, style: AppTheme.display(26, color: color)),
      Text(label.toUpperCase(), style: AppTheme.body(9, color: AppTheme.textSecondary),
          textAlign: TextAlign.center, maxLines: 2),
    ]),
  );
}

// ── Skill breakdown ────────────────────────────────────────────────────────────
class _SkillBreakdown extends StatelessWidget {
  final Progress prog;
  const _SkillBreakdown({required this.prog});

  @override
  Widget build(BuildContext context) {
    final total = prog.additionCorrect + prog.subtractionCorrect +
        prog.multiplicationCorrect + prog.divisionCorrect;
    if (total == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bg2, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.bg3)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('SKILL BREAKDOWN', style: AppTheme.body(10,
            color: AppTheme.textSecondary, weight: FontWeight.w900)),
        const SizedBox(height: 10),
        _Bar('➕ Addition',       prog.additionCorrect,       total, AppTheme.green),
        _Bar('➖ Subtraction',    prog.subtractionCorrect,    total, AppTheme.blue),
        _Bar('✖️ Multiplication', prog.multiplicationCorrect, total, AppTheme.purple),
        _Bar('➗ Division',       prog.divisionCorrect,       total, AppTheme.red),
      ]),
    );
  }
}

class _Bar extends StatelessWidget {
  final String label;
  final int val, total;
  final Color color;
  const _Bar(this.label, this.val, this.total, this.color);
  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : (val / total).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        SizedBox(width: 116, child: Text(label,
            style: AppTheme.body(11, color: AppTheme.textSecondary))),
        Expanded(child: Stack(children: [
          Container(height: 8, decoration: BoxDecoration(
              color: AppTheme.bg3, borderRadius: BorderRadius.circular(4))),
          FractionallySizedBox(widthFactor: pct, child: Container(
              height: 8, decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(4)))),
        ])),
        const SizedBox(width: 8),
        Text('$val', style: AppTheme.body(11, color: color, weight: FontWeight.w800)),
      ]),
    );
  }
}

// ── Share card ────────────────────────────────────────────────────────────────
class _ShareCard extends StatelessWidget {
  final MatchOutcome outcome;
  final int power, score, streak, cpm;
  final String accPct, playerName, countryCode;

  const _ShareCard({
    required this.outcome, required this.power, required this.accPct,
    required this.score, required this.streak, required this.cpm,
    required this.playerName, required this.countryCode,
  });

  String get _text {
    final res = outcome == MatchOutcome.win ? 'WON 🏆'
              : outcome == MatchOutcome.lose ? 'lost 😅' : 'drew 🤝';
    final flag = _flag(countryCode);
    return '''🎯 Tug of War: Mathematics
━━━━━━━━━━━━━━━━
$flag $playerName just $res vs CPU!
🧠 Brain Power: $power (${_powerLabel(power)})
📊 Score:    $score
✅ Accuracy: $accPct
⚡ Speed:    $cpm Q/min
🔥 Streak:   $streak
━━━━━━━━━━━━━━━━
Can you beat me? 👉 tugofwar.math 🎮''';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bg2, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.bg3)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('📤', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text('Share Your Result',
              style: AppTheme.body(14, weight: FontWeight.w800)),
        ]),
        const SizedBox(height: 12),

        // Preview
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.bg, borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.bg3)),
          child: Text(_text,
              style: AppTheme.body(11, color: AppTheme.textSecondary)),
        ),
        const SizedBox(height: 12),

        // Share buttons
        Row(children: [
          Expanded(child: _Btn('📋', 'Copy',     AppTheme.blue,             () => _copy(context))),
          const SizedBox(width: 8),
          Expanded(child: _Btn('💬', 'WhatsApp', const Color(0xFF25D366),   () => _via(context, 'WhatsApp'))),
          const SizedBox(width: 8),
          Expanded(child: _Btn('🐦', 'Twitter',  const Color(0xFF1DA1F2),   () => _via(context, 'Twitter'))),
          const SizedBox(width: 8),
          Expanded(child: _Btn('📱', 'More',     AppTheme.purple,           () => _via(context, 'other'))),
        ]),
      ]),
    );
  }

  void _copy(BuildContext ctx) {
    Clipboard.setData(ClipboardData(text: _text));
    _snack(ctx, 'Copied to clipboard! Paste anywhere 📋', AppTheme.blue);
  }

  void _via(BuildContext ctx, String platform) {
    Clipboard.setData(ClipboardData(text: _text));
    _snack(ctx, 'Copied! Open $platform and paste to share 📤', AppTheme.purple);
  }

  void _snack(BuildContext ctx, String msg, Color col) {
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      backgroundColor: col,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
      duration: const Duration(seconds: 3),
    ));
  }

  String _flag(String code) {
    if (code.length != 2) return '🌍';
    final b = 0x1F1E6 - 65;
    final c = code.toUpperCase().codeUnits;
    return String.fromCharCode(b + c[0]) + String.fromCharCode(b + c[1]);
  }

  String _powerLabel(int pwr) {
    if (pwr >= 145) return 'Legendary';
    if (pwr >= 130) return 'Epic';
    if (pwr >= 120) return 'Super';
    if (pwr >= 110) return 'Strong';
    if (pwr >= 90)  return 'Solid';
    return 'Growing';
  }
}

class _Btn extends StatelessWidget {
  final String icon, label;
  final Color color;
  final VoidCallback onTap;
  const _Btn(this.icon, this.label, this.color, this.onTap);
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.4))),
      child: Column(children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 2),
        Text(label, style: AppTheme.body(9, color: color, weight: FontWeight.w800),
            textAlign: TextAlign.center),
      ]),
    ),
  );
}