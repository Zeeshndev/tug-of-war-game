import 'package:flutter/material.dart';
import '../utils/theme.dart';

// ── Big primary button ────────────────────────────────────
class BigButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color color;
  final Color shadowColor;
  final double fontSize;
  final Widget? icon;

  const BigButton({
    super.key,
    required this.label,
    this.onTap,
    this.color = AppTheme.blue,
    this.shadowColor = AppTheme.blueDark,
    this.fontSize = 22,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppTheme.radius),
          boxShadow: [
            BoxShadow(color: shadowColor, offset: const Offset(0, 4), blurRadius: 0),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[icon!, const SizedBox(width: 10)],
            Text(label, style: AppTheme.display(fontSize, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

// ── Ghost button ─────────────────────────────────────────
class GhostButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const GhostButton({super.key, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.bg2,
          borderRadius: BorderRadius.circular(AppTheme.radius),
          border: Border.all(color: AppTheme.bg3, width: 2),
        ),
        child: Center(
          child: Text(label, style: AppTheme.display(18, color: AppTheme.textPrimary)),
        ),
      ),
    );
  }
}

// ── Coin display badge ────────────────────────────────────
class CoinBadge extends StatelessWidget {
  final int coins;
  const CoinBadge({super.key, required this.coins});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: AppDecoration.pill(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🪙', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 6),
          Text(
            '$coins',
            style: AppTheme.display(18, color: AppTheme.yellowLight),
          ),
        ],
      ),
    );
  }
}

// ── Section card ─────────────────────────────────────────
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? borderColor;

  const AppCard({super.key, required this.child, this.padding, this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(18),
      decoration: AppDecoration.card(borderColor: borderColor),
      child: child,
    );
  }
}

// ── Toggle switch ─────────────────────────────────────────
class AppToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const AppToggle({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 52, height: 28,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: value ? AppTheme.green : AppTheme.bg3,
          borderRadius: BorderRadius.circular(14),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 22, height: 22,
            decoration: const BoxDecoration(
              color: Colors.white, shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Stat card ─────────────────────────────────────────────
class StatCard extends StatelessWidget {
  final String value;
  final String label;
  const StatCard({super.key, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppDecoration.card(),
      child: Column(
        children: [
          Text(value, style: AppTheme.display(28, color: AppTheme.blueLight)),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: AppTheme.body(11, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ── Keypad ────────────────────────────────────────────────
class NumericKeypad extends StatelessWidget {
  final Function(String) onDigit;
  final VoidCallback onDelete;
  final VoidCallback onSubmit;

  const NumericKeypad({
    super.key,
    required this.onDigit,
    required this.onDelete,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.4,
      children: [
        _key('7'), _key('8'), _key('9'),
        _key('4'), _key('5'), _key('6'),
        _key('1'), _key('2'), _key('3'),
        _delKey(), _key('0'), _submitKey(),
      ],
    );
  }

  Widget _key(String digit) => _KeyButton(
    label: digit,
    onTap: () => onDigit(digit),
    color: AppTheme.bg2,
    borderColor: AppTheme.bg3,
    textColor: AppTheme.textPrimary,
    fontSize: 24,
  );

  Widget _delKey() => _KeyButton(
    label: '⌫',
    onTap: onDelete,
    color: AppTheme.bg2,
    borderColor: AppTheme.bg3,
    textColor: AppTheme.redLight,
    fontSize: 20,
    useSystemFont: true,
  );

  Widget _submitKey() => _KeyButton(
    label: '✓',
    onTap: onSubmit,
    color: AppTheme.green,
    borderColor: AppTheme.green,
    textColor: Colors.white,
    fontSize: 22,
    useSystemFont: true,
  );
}

class _KeyButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;
  final Color borderColor;
  final Color textColor;
  final double fontSize;
  final bool useSystemFont;

  const _KeyButton({
    required this.label, required this.onTap,
    required this.color, required this.borderColor,
    required this.textColor, required this.fontSize,
    this.useSystemFont = false,
  });

  @override
  State<_KeyButton> createState() => _KeyButtonState();
}

class _KeyButtonState extends State<_KeyButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        decoration: BoxDecoration(
          color: _pressed ? AppTheme.blue : widget.color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _pressed ? AppTheme.blue : widget.borderColor, width: 2),
        ),
        child: Center(
          child: Text(
            widget.label,
            style: widget.useSystemFont
                ? TextStyle(fontSize: widget.fontSize, color: widget.textColor, fontWeight: FontWeight.bold)
                : AppTheme.display(widget.fontSize, color: widget.textColor),
          ),
        ),
      ),
    );
  }
}
