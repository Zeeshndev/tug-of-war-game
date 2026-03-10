import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_providers.dart';
import '../utils/theme.dart';
import '../widgets/common_widgets.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _step = 0;
  String _selectedAge = 'A';
  bool _soundOn = true;

  void _next() async {
    if (_step < 2) {
      setState(() => _step++);
    } else {
      // Complete onboarding
      await ref.read(profileProvider.notifier).setAgeGroup(_selectedAge);
      await ref.read(profileProvider.notifier).setSound(_soundOn);
      await ref.read(profileProvider.notifier).completeOnboarding();
      if (mounted) context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F2E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Logo
              const SizedBox(height: 20),
              Text('🪢', style: const TextStyle(fontSize: 72)),
              Text('Tug of War', style: AppTheme.display(36, color: AppTheme.yellowLight)),
              Text(
                'MATHEMATICS',
                style: AppTheme.body(13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 32),

              // Step content
              Expanded(child: _buildStep()),

              // Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) => _Dot(active: i == _step)),
              ),
              const SizedBox(height: 20),

              // Button
              BigButton(
                label: _step < 2 ? 'Continue ▶' : "Let's Play! 🎮",
                onTap: _next,
                color: AppTheme.green,
                shadowColor: const Color(0xFF15803D),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _AgeGroupStep(
          selected: _selectedAge,
          onSelect: (g) => setState(() => _selectedAge = g),
        );
      case 1:
        return _SoundStep(
          soundOn: _soundOn,
          onToggle: (v) => setState(() => _soundOn = v),
        );
      case 2:
        return const _PrivacyStep();
      default:
        return const SizedBox();
    }
  }
}

class _Dot extends StatelessWidget {
  final bool active;
  const _Dot({required this.active});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: active ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? AppTheme.blue : AppTheme.bg3,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _AgeGroupStep extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;

  const _AgeGroupStep({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Who's playing? 👋", style: AppTheme.display(26)),
        const SizedBox(height: 6),
        Text('Choose the right age group', style: AppTheme.body(14, color: AppTheme.textSecondary)),
        const SizedBox(height: 20),
        _AgeCard(
          emoji: '🌱', title: 'Group A — Ages 5–7',
          desc: 'Addition & Subtraction, small numbers, forgiving pace',
          selected: selected == 'A',
          onTap: () => onSelect('A'),
        ),
        const SizedBox(height: 12),
        _AgeCard(
          emoji: '🚀', title: 'Group B — Ages 8–11',
          desc: 'All 4 operations, bigger numbers, fast-paced challenge',
          selected: selected == 'B',
          onTap: () => onSelect('B'),
        ),
      ],
    );
  }
}

class _AgeCard extends StatelessWidget {
  final String emoji, title, desc;
  final bool selected;
  final VoidCallback onTap;

  const _AgeCard({
    required this.emoji, required this.title, required this.desc,
    required this.selected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected ? AppTheme.blue.withOpacity(0.15) : AppTheme.bg2,
          borderRadius: BorderRadius.circular(AppTheme.radius),
          border: Border.all(
            color: selected ? AppTheme.blue : AppTheme.bg3,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 40)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTheme.display(18)),
                  Text(desc, style: AppTheme.body(13, color: AppTheme.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoundStep extends StatelessWidget {
  final bool soundOn;
  final ValueChanged<bool> onToggle;

  const _SoundStep({required this.soundOn, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sound effects? 🔊', style: AppTheme.display(26)),
        const SizedBox(height: 6),
        Text('You can change this anytime in Settings', style: AppTheme.body(14, color: AppTheme.textSecondary)),
        const SizedBox(height: 20),
        Row(
          children: [
            _SoundBtn(emoji: '🔊', label: 'Sound ON', selected: soundOn, onTap: () => onToggle(true)),
            const SizedBox(width: 12),
            _SoundBtn(emoji: '🔇', label: 'Sound OFF', selected: !soundOn, onTap: () => onToggle(false)),
          ],
        ),
      ],
    );
  }
}

class _SoundBtn extends StatelessWidget {
  final String emoji, label;
  final bool selected;
  final VoidCallback onTap;

  const _SoundBtn({required this.emoji, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: selected ? AppTheme.green.withOpacity(0.15) : AppTheme.bg2,
            borderRadius: BorderRadius.circular(AppTheme.radius),
            border: Border.all(color: selected ? AppTheme.green : AppTheme.bg3, width: 2),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 36)),
              const SizedBox(height: 8),
              Text(label, style: AppTheme.body(14)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrivacyStep extends StatelessWidget {
  const _PrivacyStep();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Safe & Private 🛡️', style: AppTheme.display(26)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.purple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.radius),
            border: Border.all(color: AppTheme.purple.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Your child's privacy matters.", style: AppTheme.body(16, weight: FontWeight.w800)),
              const SizedBox(height: 14),
              for (final item in [
                '✅  No personal data collected',
                '✅  No account required to play',
                '✅  All data stays on this device',
                '✅  Parent settings behind a gate',
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(item, style: AppTheme.body(14)),
                ),
              const SizedBox(height: 6),
              Text(
                'Parent controls are available in Settings to adjust difficulty, time limits, and ads.',
                style: AppTheme.body(13, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
