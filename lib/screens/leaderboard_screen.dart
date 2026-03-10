import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_models.dart'; // ADDED: This fixes the missing LeaderboardEntry error
import '../providers/app_providers.dart';
import '../services/storage_service.dart';
import '../utils/theme.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});
  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  String _filter = 'ALL';

  @override
  Widget build(BuildContext context) {
    final board   = ref.watch(leaderboardProvider);
    final profile = ref.watch(profileProvider);

    // All unique countries in board
    final countries = ['ALL', ...{...board.map((e) => e.countryCode)}];

    final filtered = _filter == 'ALL'
        ? board
        : board.where((e) => e.countryCode == _filter).toList();

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(children: [
          // ── Header ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.bg2, borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.bg3)),
                  child: const Center(
                      child: Text('←', style: TextStyle(fontSize: 20, color: AppTheme.textPrimary))),
                ),
              ),
              const SizedBox(width: 12),
              Text('🏆 Leaderboard',
                  style: AppTheme.display(22, color: AppTheme.yellowLight)),
              const Spacer(),
              // Share top 5
              GestureDetector(
                onTap: () => _shareLeaderboard(filtered),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.purple.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.purple.withOpacity(0.4))),
                  child: Text('📤 Share', style: AppTheme.body(12,
                      color: AppTheme.purple, weight: FontWeight.w700)),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 12),

          // ── Country filter chips ────────────────────────────────────
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: countries.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final c      = countries[i];
                final active = c == _filter;
                return GestureDetector(
                  onTap: () => setState(() => _filter = c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: active ? AppTheme.yellow.withOpacity(0.14) : AppTheme.bg2,
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(
                          color: active ? AppTheme.yellow : AppTheme.bg3,
                          width: active ? 2 : 1)),
                    child: Text(
                      c == 'ALL' ? '🌍 Global' : '${_flag(c)} $c',
                      style: AppTheme.body(11,
                        color: active ? AppTheme.yellowLight : AppTheme.textSecondary,
                        weight: active ? FontWeight.w800 : FontWeight.w500),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // ── Column header ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              const SizedBox(width: 38),
              Expanded(child: Text('PLAYER', style: AppTheme.body(10,
                  color: AppTheme.textSecondary, weight: FontWeight.w800))),
              _hdr('IQ',    54),
              _hdr('SCORE', 54),
              _hdr('ACC',   48),
            ]),
          ),
          const SizedBox(height: 4),

          // ── List ────────────────────────────────────────────────────
          Expanded(
            child: filtered.isEmpty
                ? Center(child: Text('No entries yet!',
                    style: AppTheme.body(14, color: AppTheme.textSecondary)))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => _Row(
                      rank:  i + 1,
                      entry: filtered[i],
                      isMe:  filtered[i].playerName == profile.playerName &&
                             filtered[i].countryCode == profile.countryCode,
                    ),
                  ),
          ),
        ]),
      ),
    );
  }

  Widget _hdr(String t, double w) => SizedBox(width: w,
      child: Center(child: Text(t, style: AppTheme.body(10,
          color: AppTheme.textSecondary, weight: FontWeight.w800))));

  void _shareLeaderboard(List<LeaderboardEntry> board) {
    final top = board.take(5).toList();
    final sb  = StringBuffer()
      ..writeln('🏆 Tug of War: Math — Top Players')
      ..writeln('━━━━━━━━━━━━━━━━');
    for (var i = 0; i < top.length; i++) {
      final e = top[i];
      sb.writeln('${i+1}. ${_flag(e.countryCode)} ${e.playerName}'
          '  IQ:${e.iqScore}  Score:${e.score}  ${(e.accuracy*100).round()}%');
    }
    sb.writeln('━━━━━━━━━━━━━━━━');
    sb.write('Play: tugofwar.math 🎮');
    Clipboard.setData(ClipboardData(text: sb.toString()));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Leaderboard copied! Paste to share 📋'),
      backgroundColor: AppTheme.yellow,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
      duration: const Duration(seconds: 2),
    ));
  }

  String _flag(String code) {
    if (code.length != 2) return '🌍';
    final b = 0x1F1E6 - 65;
    final c = code.toUpperCase().codeUnits;
    return String.fromCharCode(b + c[0]) + String.fromCharCode(b + c[1]);
  }
}

// ── Single leaderboard row ───────────────────────────────────────────────────
class _Row extends StatelessWidget {
  final int rank;
  final LeaderboardEntry entry;
  final bool isMe;
  const _Row({required this.rank, required this.entry, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final medal = rank == 1 ? '🥇' : rank == 2 ? '🥈' : rank == 3 ? '🥉' : '#$rank';
    final iqCol = entry.iqScore >= 130 ? AppTheme.yellowLight
                : entry.iqScore >= 110 ? AppTheme.greenLight
                : AppTheme.blueLight;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isMe ? AppTheme.blue.withOpacity(0.09) : AppTheme.bg2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMe ? AppTheme.blueLight.withOpacity(0.55) : AppTheme.bg3,
          width: isMe ? 2 : 1),
      ),
      child: Row(children: [
        SizedBox(width: 38, child: Text(medal,
            style: TextStyle(fontSize: rank <= 3 ? 20 : 13,
                color: AppTheme.textSecondary, fontWeight: FontWeight.w700))),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(_flag(entry.countryCode), style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Flexible(child: Text(entry.playerName,
                style: AppTheme.body(13, weight: FontWeight.w700,
                    color: isMe ? AppTheme.blueLight : AppTheme.textPrimary),
                overflow: TextOverflow.ellipsis)),
            if (isMe) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                    color: AppTheme.blue, borderRadius: BorderRadius.circular(50)),
                child: Text('YOU', style: AppTheme.body(9,
                    color: Colors.white, weight: FontWeight.w900)),
              ),
            ],
          ]),
          Text(_iqLabel(entry.iqScore),
              style: AppTheme.body(10, color: AppTheme.textSecondary)),
        ])),
        SizedBox(width: 54, child: Center(child: Text('${entry.iqScore}',
            style: AppTheme.body(14, color: iqCol, weight: FontWeight.w800)))),
        SizedBox(width: 54, child: Center(child: Text('${entry.score}',
            style: AppTheme.body(14, color: AppTheme.textPrimary, weight: FontWeight.w700)))),
        SizedBox(width: 48, child: Center(child: Text(
            '${(entry.accuracy * 100).round()}%',
            style: AppTheme.body(13, color: AppTheme.greenLight)))),
      ]),
    );
  }

  String _iqLabel(int iq) {
    if (iq >= 145) return 'Genius 🧠';
    if (iq >= 130) return 'Gifted 🌟';
    if (iq >= 120) return 'Superior ⭐';
    if (iq >= 110) return 'Above Avg 👍';
    if (iq >= 90)  return 'Average 📊';
    return 'Developing 📈';
  }

  String _flag(String code) {
    if (code.length != 2) return '🌍';
    final b = 0x1F1E6 - 65;
    final c = code.toUpperCase().codeUnits;
    return String.fromCharCode(b + c[0]) + String.fromCharCode(b + c[1]);
  }
}