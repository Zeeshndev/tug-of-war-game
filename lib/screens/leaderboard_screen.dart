import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_providers.dart';
import '../models/game_models.dart';
import '../utils/theme.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final board = ref.watch(leaderboardProvider);
    final userCountry = ref.watch(profileProvider).countryCode;

    // Filter lists
    final globalList = List<LeaderboardEntry>.from(board);
    final localList = board.where((e) => e.countryCode == userCountry).toList();

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(children: [
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: AppTheme.bg2, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.bg3)),
                    child: const Center(child: Text('←', style: TextStyle(fontSize: 20, color: AppTheme.textPrimary))),
                  ),
                ),
                const SizedBox(width: 12),
                Text('🏆 Ranks', style: AppTheme.display(26, color: AppTheme.yellowLight)),
              ]),
            ),

            // ── Tabs ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(color: AppTheme.bg2, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.bg3)),
                child: TabBar(
                  controller: _tabCtrl,
                  indicator: BoxDecoration(color: AppTheme.yellow.withOpacity(0.12), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.yellow, width: 2)),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelStyle: AppTheme.body(13, weight: FontWeight.w800),
                  labelColor: AppTheme.yellowLight,
                  unselectedLabelColor: AppTheme.textSecondary,
                  tabs: [
                    const Tab(text: '🌍 Global (200)'),
                    Tab(text: '📍 Local ($userCountry)'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // ── List View with Sticky Bottom Bar ──
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _buildTabContent(globalList),
                  _buildTabContent(localList),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(List<LeaderboardEntry> list) {
    if (list.isEmpty) {
      return Center(child: Text('No players found.', style: AppTheme.body(16, color: AppTheme.textSecondary)));
    }

    final myIndex = list.indexWhere((e) => e.isCurrentUser);

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            itemCount: list.length,
            itemBuilder: (context, index) {
              return _buildRankRow(list[index], index + 1);
            },
          ),
        ),
        
        // ── STICKY USER BAR AT THE BOTTOM ──
        if (myIndex != -1)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            decoration: BoxDecoration(
              color: AppTheme.bg,
              boxShadow: [BoxShadow(color: AppTheme.blue.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, -5))],
              border: Border(top: BorderSide(color: AppTheme.blue.withOpacity(0.5), width: 2)),
            ),
            child: _buildRankRow(list[myIndex], myIndex + 1, isSticky: true),
          ),
      ],
    );
  }

  Widget _buildRankRow(LeaderboardEntry entry, int rank, {bool isSticky = false}) {
    final isMe = entry.isCurrentUser;

    Color rankColor;
    if (rank == 1) rankColor = const Color(0xFFFFD700); // Gold
    else if (rank == 2) rankColor = const Color(0xFFC0C0C0); // Silver
    else if (rank == 3) rankColor = const Color(0xFFCD7F32); // Bronze
    else rankColor = AppTheme.textSecondary;

    // Premium styling for the player so they cannot miss it
    final bgColor = isMe ? AppTheme.blue.withOpacity(0.35) : AppTheme.bg2;
    final borderColor = isMe ? AppTheme.yellow : AppTheme.bg3;
    final borderWidth = isMe ? 2.5 : 1.0;

    return Container(
      margin: EdgeInsets.only(bottom: isSticky ? 0 : 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: isMe && !isSticky ? [BoxShadow(color: AppTheme.blue.withOpacity(0.2), blurRadius: 8, spreadRadius: 1)] : null,
      ),
      child: Row(
        children: [
          // Rank Number
          SizedBox(
            width: 40,
            child: Text('#$rank', style: AppTheme.display(16, color: rankColor)),
          ),
          const SizedBox(width: 4),

          // Country Flag Placeholder
          Container(
            width: 32, height: 24,
            decoration: BoxDecoration(color: AppTheme.bg3, borderRadius: BorderRadius.circular(4)),
            child: Center(child: Text(entry.countryCode, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white))),
          ),
          const SizedBox(width: 12),

          // Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.playerName,
                        style: AppTheme.body(15, color: AppTheme.textPrimary, weight: FontWeight.w800),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppTheme.yellow, borderRadius: BorderRadius.circular(4)),
                        child: Text('⭐ YOU', style: AppTheme.body(9, color: Colors.black, weight: FontWeight.w900)),
                      )
                    ]
                  ],
                ),
                const SizedBox(height: 2),
                Text('Accuracy: ${(entry.accuracy * 100).toStringAsFixed(1)}%', style: AppTheme.body(11, color: isMe ? Colors.white70 : AppTheme.textSecondary)),
              ],
            ),
          ),

          // Brain Power
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('🧠 ${entry.brainPower}', style: AppTheme.display(18, color: AppTheme.yellowLight)),
              Text('Score: ${entry.score}', style: AppTheme.body(10, color: isMe ? Colors.white70 : AppTheme.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}









