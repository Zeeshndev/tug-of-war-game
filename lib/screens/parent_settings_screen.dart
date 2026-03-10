import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_providers.dart';
import '../utils/theme.dart';
import '../widgets/common_widgets.dart';

class ParentSettingsScreen extends ConsumerWidget {
  const ParentSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier  = ref.read(settingsProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: const Text('←', style: TextStyle(fontSize: 30, color: AppTheme.textPrimary)),
                  ),
                  const SizedBox(width: 12),
                  Text('👨‍👩‍👧 Parent Controls', style: AppTheme.display(22)),
                ],
              ),
              const SizedBox(height: 20),

              _Row(
                name: '📺 Show Ads',
                desc: 'Enable rewarded video ads after matches',
                trailing: AppToggle(value: settings.adsEnabled, onChanged: (_) => notifier.toggleAds()),
              ),
              const SizedBox(height: 10),

              _Row(
                name: '🔒 Difficulty Lock',
                desc: 'Prevent child from changing age/difficulty',
                trailing: AppToggle(value: settings.difficultyLock, onChanged: (_) => notifier.toggleDifficultyLock()),
              ),
              const SizedBox(height: 10),

              _Row(
                name: '⏱️ Session Time Limit',
                desc: 'Max play time (0 = unlimited)',
                trailing: _PillRow(
                  options: ['Off', '15m', '30m'],
                  values:  [0, 15, 30],
                  current: settings.sessionTimeLimit,
                  onSelect: (v) => notifier.setTimeLimit(v),
                ),
              ),
              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                  border: Border.all(color: AppTheme.purple.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🛡️ Privacy Notice', style: AppTheme.body(15, weight: FontWeight.w800)),
                    const SizedBox(height: 10),
                    Text(
                      'No personal data is collected from your child. '
                      'All game data is stored locally on this device. '
                      'No accounts or login required. '
                      'This app complies with COPPA and GDPR-K guidelines.',
                      style: AppTheme.body(13, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String name, desc;
  final Widget trailing;

  const _Row({required this.name, required this.desc, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.bg2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.bg3),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTheme.body(15, weight: FontWeight.w700)),
                Text(desc, style: AppTheme.body(12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          trailing,
        ],
      ),
    );
  }
}

class _PillRow extends StatelessWidget {
  final List<String> options;
  final List<int> values;
  final int current;
  final ValueChanged<int> onSelect;

  const _PillRow({required this.options, required this.values, required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(options.length, (i) {
        final active = values[i] == current;
        return GestureDetector(
          onTap: () => onSelect(values[i]),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(left: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: active ? AppTheme.blue : AppTheme.bg3,
              borderRadius: BorderRadius.circular(50),
            ),
            child: Text(
              options[i],
              style: AppTheme.body(12, color: active ? Colors.white : AppTheme.textSecondary, weight: FontWeight.w800),
            ),
          ),
        );
      }),
    );
  }
}