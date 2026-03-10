import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_providers.dart';
import '../utils/theme.dart';

class CountdownScreen extends ConsumerStatefulWidget {
  const CountdownScreen({super.key});

  @override
  ConsumerState<CountdownScreen> createState() => _CountdownScreenState();
}

class _CountdownScreenState extends ConsumerState<CountdownScreen>
    with SingleTickerProviderStateMixin {
  int _count = 3;
  bool _showGo = false;
  late AnimationController _pulseController;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_count > 1) {
        setState(() => _count--);
      } else if (_count == 1 && !_showGo) {
        setState(() { _count = 0; _showGo = true; });
      } else {
        t.cancel();
        Future.delayed(const Duration(milliseconds: 700), () {
          if (mounted) {
            ref.read(gameProvider.notifier).startMatch();
            context.go('/game');
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Get ready!', style: AppTheme.display(24, color: AppTheme.textSecondary)),
            const SizedBox(height: 24),
            AnimatedBuilder(
              animation: _pulseController,
              builder: (_, __) {
                final scale = 1.0 + _pulseController.value * 0.05;
                return Transform.scale(
                  scale: scale,
                  child: _showGo
                      ? Text('GO!', style: AppTheme.display(100, color: AppTheme.greenLight))
                      : Text('$_count', style: AppTheme.display(120, color: AppTheme.yellowLight)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
