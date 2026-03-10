import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_providers.dart';
import '../models/game_models.dart';
import '../utils/theme.dart';
import '../widgets/common_widgets.dart';
import '../services/audio_service.dart'; // ADDED: Direct access to Audio Kill Switch
import 'parent_gate_dialog.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile  = ref.watch(profileProvider);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(children: [
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.bg2,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.bg3),
                    ),
                    child: const Center(child: Text('←', style: TextStyle(fontSize: 20, color: AppTheme.textPrimary))),
                  ),
                ),
                const SizedBox(width: 12),
                Text('⚙️ Settings', style: AppTheme.display(26)),
              ]),
              const SizedBox(height: 24),

              // ── GAME MODE ─────────────────────────────
              _sectionHeader('🎯 Game Mode'),
              const SizedBox(height: 10),
              _GameModeSelector(
                current: settings.gameModeEnum,
                onSelect: (m) => ref.read(settingsProvider.notifier).setGameMode(m),
              ),
              const SizedBox(height: 20),

              // ── MATCH DURATION ────────────────────────
              _sectionHeader('⏱️ Match Duration'),
              const SizedBox(height: 10),
              _DurationSelector(
                current: settings.matchDuration,
                onSelect: (v) => ref.read(settingsProvider.notifier).setMatchDuration(v),
              ),
              const SizedBox(height: 20),

              // ── GENERAL ───────────────────────────────
              _sectionHeader('🔧 General'),
              const SizedBox(height: 10),

              _SettingRow(
                name: '🔊 Sound Effects',
                desc: 'Toggle game sounds on/off',
                trailing: AppToggle(
                  value: profile.soundOn,
                  onChanged: (val) {
                    // Update the saved profile
                    ref.read(profileProvider.notifier).setSound(val);
                    
                    // MASTER KILL SWITCH: Directly command the Audio Service
                    if (!val) {
                      AudioService().soundEnabled = false;
                      AudioService().stopBgm(); 
                    } else {
                      AudioService().soundEnabled = true;
                      AudioService().setBgmState(BgmState.menu); // Resume music instantly
                    }
                  },
                ),
              ),
              const SizedBox(height: 8),
              _SettingRow(
                name: '📳 Vibration',
                desc: 'Haptic feedback on answers',
                trailing: AppToggle(
                  value: profile.vibrationOn,
                  onChanged: (v) => ref.read(profileProvider.notifier).setVibration(v),
                ),
              ),
              const SizedBox(height: 8),
              _SettingRow(
                name: '👶 Age Group',
                desc: settings.difficultyLock ? '🔒 Locked by parent' : 'A = Ages 5–7 · B = Ages 8–11',
                trailing: _PillGroup(
                  options: const ['A (5–7)', 'B (8–11)'],
                  values:  const [0, 1],
                  current: profile.ageGroup == 'A' ? 0 : 1,
                  onSelect: settings.difficultyLock
                      ? null
                      : (v) => ref.read(profileProvider.notifier).setAgeGroup(v == 0 ? 'A' : 'B'),
                ),
              ),
              const SizedBox(height: 24),

              // ── PARENT CONTROLS ───────────────────────
              _sectionHeader('🔒 Parent Controls'),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => _openParentGate(context, ref),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.bg2,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.purple.withOpacity(0.5), width: 1.5),
                  ),
                  child: Row(children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.purple.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(child: Text('🔐', style: TextStyle(fontSize: 22))),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Parent Settings', style: AppTheme.body(15, weight: FontWeight.w800)),
                      Text('Ads, difficulty lock, time limits', style: AppTheme.body(12, color: AppTheme.textSecondary)),
                    ])),
                    Text('›', style: AppTheme.display(24, color: AppTheme.textSecondary)),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String text) {
    return Text(text, style: AppTheme.body(14, color: AppTheme.textSecondary, weight: FontWeight.w800));
  }

  void _openParentGate(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => ParentGateDialog(
        onSuccess: () { Navigator.pop(context); context.push('/parent-settings'); },
      ),
    );
  }
}

// ── Game Mode Selector Grid ────────────────────────────────
class _GameModeSelector extends StatelessWidget {
  final GameMode current;
  final ValueChanged<GameMode> onSelect;
  const _GameModeSelector({required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 8, mainAxisSpacing: 8,
      childAspectRatio: 2.8,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: GameMode.values.map((mode) {
        final active = mode == current;
        return GestureDetector(
          onTap: () => onSelect(mode),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: active ? AppTheme.blue.withOpacity(0.15) : AppTheme.bg2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: active ? AppTheme.blue : AppTheme.bg3,
                width: active ? 2 : 1,
              ),
            ),
            child: Center(
              child: Text(
                mode.label,
                style: AppTheme.body(12,
                  color: active ? AppTheme.blueLight : AppTheme.textSecondary,
                  weight: active ? FontWeight.w800 : FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Duration Selector ─────────────────────────────────────
class _DurationSelector extends StatelessWidget {
  final int current;
  final ValueChanged<int> onSelect;
  static const _options = [
    {'label': '⚡ 30s', 'value': 30},
    {'label': '🕐 1 min', 'value': 60},
    {'label': '🕑 90s', 'value': 90},
    {'label': '🕒 2 min', 'value': 120},
    {'label': '🕓 3 min', 'value': 180},
    {'label': '🕔 5 min', 'value': 300},
  ];
  const _DurationSelector({required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _options.map((opt) {
        final active = opt['value'] == current;
        return Expanded(child: Padding(
          padding: const EdgeInsets.only(right: 5),
          child: GestureDetector(
            onTap: () => onSelect(opt['value'] as int),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: active ? AppTheme.yellow.withOpacity(0.12) : AppTheme.bg2,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: active ? AppTheme.yellow : AppTheme.bg3,
                  width: active ? 2 : 1,
                ),
              ),
              child: Center(child: Text(
                opt['label'] as String,
                style: AppTheme.body(10,
                  color: active ? AppTheme.yellowLight : AppTheme.textSecondary,
                  weight: active ? FontWeight.w800 : FontWeight.w600),
                textAlign: TextAlign.center,
              )),
            ),
          ),
        ));
      }).toList(),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final String name, desc;
  final Widget trailing;
  const _SettingRow({required this.name, required this.desc, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.bg2, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.bg3),
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: AppTheme.body(15, weight: FontWeight.w700)),
          Text(desc, style: AppTheme.body(12, color: AppTheme.textSecondary)),
        ])),
        const SizedBox(width: 12),
        trailing,
      ]),
    );
  }
}

class _PillGroup extends StatelessWidget {
  final List<String> options;
  final List<int> values;
  final int current;
  final ValueChanged<int>? onSelect;
  const _PillGroup({required this.options, required this.values,
      required this.current, this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(options.length, (i) {
        final active = values[i] == current;
        return GestureDetector(
          onTap: onSelect == null ? null : () => onSelect!(values[i]),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(left: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: active ? AppTheme.blue : AppTheme.bg3,
              borderRadius: BorderRadius.circular(50),
            ),
            child: Text(options[i],
              style: AppTheme.body(11, color: active ? Colors.white : AppTheme.textSecondary,
                  weight: FontWeight.w800)),
          ),
        );
      }),
    );
  }
}