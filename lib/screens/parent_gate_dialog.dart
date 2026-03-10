import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../widgets/common_widgets.dart';

class ParentGateDialog extends StatefulWidget {
  final VoidCallback onSuccess;
  const ParentGateDialog({super.key, required this.onSuccess});

  @override
  State<ParentGateDialog> createState() => _ParentGateDialogState();
}

class _ParentGateDialogState extends State<ParentGateDialog> {
  final _controller = TextEditingController();
  late int _a, _b, _answer;
  String? _error;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    _a = 10 + rng.nextInt(21);  // 10–30
    _b = 5  + rng.nextInt(16);  // 5–20
    _answer = _a + _b;
  }

  void _check() {
    final val = int.tryParse(_controller.text);
    if (val == _answer) {
      widget.onSuccess();
    } else {
      setState(() => _error = '❌ Wrong answer. Try again!');
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.bg2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🔐 Parent Gate', style: AppTheme.display(26)),
            const SizedBox(height: 6),
            Text(
              'Solve this to access parent settings',
              style: AppTheme.body(14, color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Text(
              '$_a + $_b = ?',
              style: AppTheme.display(40, color: AppTheme.yellowLight),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              textAlign: TextAlign.center,
              style: AppTheme.display(28),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppTheme.bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.bg3),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.blue, width: 2),
                ),
                hintText: 'Answer',
                hintStyle: AppTheme.display(24, color: AppTheme.bg3),
              ),
              onSubmitted: (_) => _check(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: AppTheme.body(13, color: AppTheme.redLight)),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: BigButton(
                    label: '✓ Unlock',
                    onTap: _check,
                    color: AppTheme.blue,
                    shadowColor: AppTheme.blueDark,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GhostButton(
                    label: 'Cancel',
                    onTap: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
