import 'package:flutter/material.dart';
import '../models/game_models.dart';
import '../utils/theme.dart';

/// Shows the AI's separate question AND its answer attempt — fully visible to player
class AiFeedbackWidget extends StatelessWidget {
  final AiState aiState;
  final MathQuestion? aiQuestion;

  const AiFeedbackWidget({super.key, required this.aiState, this.aiQuestion});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(_faceEmoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // AI's question
                Row(
                  children: [
                    Text('CPU Question: ', style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondary, letterSpacing: 0.5,
                    )),
                    Flexible(child: Text(
                      aiQuestion?.displayText ?? aiState.aiQuestion,
                      style: TextStyle(fontSize: 11, color: AppTheme.redLight, fontWeight: FontWeight.w800),
                      overflow: TextOverflow.ellipsis,
                    )),
                  ],
                ),
                const SizedBox(height: 3),
                // AI's answer status
                _buildStatus(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatus() {
    switch (aiState.status) {
      case AiThinkingStatus.idle:
        return Text('Waiting...', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary));
      case AiThinkingStatus.thinking:
        return _ThinkingDots();
      case AiThinkingStatus.answered:
        return Row(
          children: [
            Text('${aiState.displayedAnswer}',
                style: TextStyle(fontSize: 18, color: AppTheme.redLight, fontWeight: FontWeight.w900,
                    fontFamily: 'Fredoka')),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: AppTheme.red.withOpacity(0.2), borderRadius: BorderRadius.circular(50)),
              child: Text('✓ Correct!', style: TextStyle(fontSize: 10, color: AppTheme.redLight, fontWeight: FontWeight.w800)),
            ),
          ],
        );
      case AiThinkingStatus.wrong:
        return Row(
          children: [
            Text('${aiState.displayedAnswer}',
                style: TextStyle(fontSize: 18, color: AppTheme.textSecondary, fontWeight: FontWeight.w900)),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(color: AppTheme.bg3, borderRadius: BorderRadius.circular(50)),
              child: Text('✗ Wrong', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.w800)),
            ),
          ],
        );
    }
  }

  String get _faceEmoji {
    switch (aiState.status) {
      case AiThinkingStatus.idle:     return '🤖';
      case AiThinkingStatus.thinking: return '🤔';
      case AiThinkingStatus.answered: return '😈';
      case AiThinkingStatus.wrong:    return '😅';
    }
  }

  Color get _bgColor {
    if (aiState.status == AiThinkingStatus.answered) return AppTheme.red.withOpacity(0.08);
    return AppTheme.bg2;
  }
  Color get _borderColor {
    if (aiState.status == AiThinkingStatus.answered) return AppTheme.red.withOpacity(0.35);
    return AppTheme.bg3;
  }
}

class _ThinkingDots extends StatefulWidget {
  @override
  State<_ThinkingDots> createState() => _ThinkingDotsState();
}
class _ThinkingDotsState extends State<_ThinkingDots> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() { super.initState(); _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(); }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(animation: _c, builder: (_, __) {
      return Row(children: List.generate(3, (i) {
        final t = (_c.value - i * 0.2).clamp(0.0, 1.0);
        final op = (t < 0.5 ? t * 2 : (1.0 - t) * 2).clamp(0.2, 1.0);
        return Opacity(opacity: op, child: Padding(padding: const EdgeInsets.only(right: 4),
          child: Container(width: 7, height: 7, decoration: const BoxDecoration(
              color: AppTheme.textSecondary, shape: BoxShape.circle))));
      }));
    });
  }
}
