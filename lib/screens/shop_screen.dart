import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_providers.dart';
import '../models/game_models.dart';
import '../utils/theme.dart';
import '../widgets/common_widgets.dart';

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});
  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen>
    with TickerProviderStateMixin {
  ShopCategory _tab = ShopCategory.character;
  late TabController _tabCtrl;
  late ConfettiController _confetti;
  
  late AnimationController _chestShakeCtrl;
  late Animation<double> _chestShakeAnim;
  bool _isOpeningChest = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) {
        setState(() => _tab = _tabCtrl.index == 0 ? ShopCategory.character : ShopCategory.rope);
      }
    });

    _confetti = ConfettiController(duration: const Duration(seconds: 3));

    _chestShakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _chestShakeAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -0.1), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -0.1, end: 0.1), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 0.1, end: -0.1), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -0.1, end: 0.1), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 0.1, end: 0.0), weight: 1),
    ]).animate(_chestShakeCtrl);
  }

  @override
  void dispose() { 
    _tabCtrl.dispose(); 
    _confetti.dispose();
    _chestShakeCtrl.dispose();
    super.dispose(); 
  }

  Future<void> _openMysteryBox() async {
    if (_isOpeningChest) return;
    final progress = ref.read(progressProvider);

    if (progress.coins < 100) {
      _toast('❌ Need ${100 - progress.coins} more coins!', AppTheme.red);
      return;
    }

    final lockedChars = kCharacters.where((c) => !progress.unlockedItems.contains(c.id)).toList();
    final lockedRopes = kRopes.where((r) => !progress.unlockedItems.contains(r.id)).toList();
    final allLocked = [...lockedChars, ...lockedRopes];

    if (allLocked.isEmpty) {
      _toast('🎉 You have unlocked everything in the game!', AppTheme.green);
      return;
    }

    setState(() => _isOpeningChest = true);
    await _chestShakeCtrl.forward(from: 0);
    await _chestShakeCtrl.forward(from: 0);

    final random = Random();
    final prize = allLocked[random.nextInt(allLocked.length)];

    final proxyItem = ShopItem(
      id: prize.id, name: prize.name, emoji: prize.emoji, 
      price: 100, category: prize.category, description: prize.description
    );

    await ref.read(progressProvider.notifier).purchaseItem(proxyItem);

    setState(() => _isOpeningChest = false);
    _confetti.play();
    _showPrizeDialog(prize);
  }

  void _showPrizeDialog(ShopItem prize) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: TweenAnimationBuilder(
          tween: Tween<double>(begin: 0.5, end: 1.0),
          duration: const Duration(milliseconds: 600),
          curve: Curves.elasticOut,
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.bg2,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.yellow, width: 3),
                  boxShadow: [BoxShadow(color: AppTheme.yellow.withOpacity(0.3), blurRadius: 20, spreadRadius: 5)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('MYSTERY PRIZE!', style: AppTheme.body(14, color: AppTheme.yellowLight, weight: FontWeight.w900)),
                    const SizedBox(height: 16),
                    SizedBox(height: 100, width: 100, child: prize.category == ShopCategory.character 
                      ? FullCharacterPreview(charId: prize.id, emoji: prize.emoji) 
                      : FullRopePreview(ropeId: prize.id)),
                    const SizedBox(height: 12),
                    Text('You unlocked', style: AppTheme.body(12, color: AppTheme.textSecondary)),
                    Text(prize.name, style: AppTheme.display(28, color: AppTheme.textPrimary)),
                    const SizedBox(height: 24),
                    BigButton(
                      label: 'Awesome!', 
                      onTap: () {
                        Navigator.pop(context);
                        _toast('${prize.emoji} ${prize.name} added to collection!', AppTheme.green);
                      }, 
                      color: AppTheme.green, 
                      shadowColor: const Color(0xFF15803D)
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(progressProvider);
    final items = _tab == ShopCategory.character ? kCharacters : kRopes;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: Row(children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.bg2, borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.bg3)),
                        child: const Center(child: Text('←', style: TextStyle(fontSize: 20, color: AppTheme.textPrimary))),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('🛒 Shop', style: AppTheme.display(26, color: AppTheme.yellowLight)),
                    const Spacer(),
                    CoinBadge(coins: progress.coins),
                  ]),
                ),
                const SizedBox(height: 14),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GestureDetector(
                    onTap: _openMysteryBox,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppTheme.purple.withOpacity(0.3), AppTheme.blue.withOpacity(0.3)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.purple, width: 2),
                      ),
                      child: Row(
                        children: [
                          AnimatedBuilder(
                            animation: _chestShakeAnim,
                            builder: (context, child) => Transform.rotate(
                              angle: _chestShakeAnim.value,
                              child: const Text('🎁', style: TextStyle(fontSize: 48)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('MYSTERY CHEST', style: AppTheme.body(14, color: Colors.white, weight: FontWeight.w900)),
                                Text('Unlock a random legendary character or rope!', style: AppTheme.body(11, color: AppTheme.textSecondary)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: progress.coins >= 100 ? AppTheme.yellow : AppTheme.bg3,
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Text(
                              '🪙 100', 
                              style: AppTheme.body(12, color: progress.coins >= 100 ? AppTheme.bg : AppTheme.textSecondary, weight: FontWeight.w900)
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.bg2,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.bg3),
                    ),
                    child: TabBar(
                      controller: _tabCtrl,
                      indicator: BoxDecoration(
                        color: AppTheme.yellow.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.yellow, width: 2),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelStyle: AppTheme.body(13, weight: FontWeight.w800),
                      unselectedLabelStyle: AppTheme.body(13),
                      labelColor: AppTheme.yellowLight,
                      unselectedLabelColor: AppTheme.textSecondary,
                      tabs: const [
                        Tab(text: '🦸 Characters'),
                        Tab(text: '🪢 Ropes'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),

                Expanded(
                  child: GridView.count(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12, mainAxisSpacing: 12,
                    childAspectRatio: 0.72,
                    children: items.map((item) {
                      final owned = progress.unlockedItems.contains(item.id);
                      final selected = _tab == ShopCategory.character
                          ? progress.selectedCharacter == item.id
                          : progress.selectedRope == item.id;
                      return _ShopCard(
                        item: item, owned: owned, selected: selected,
                        canAfford: progress.coins >= item.price,
                        onTap: () => _handleTap(item, owned),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          
          Align(
            alignment: Alignment.center,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              colors: const [AppTheme.yellow, AppTheme.red, AppTheme.blue, AppTheme.green, AppTheme.purple],
              numberOfParticles: 50,
              maxBlastForce: 40,
            ),
          ),
        ],
      ),
    );
  }

  void _handleTap(ShopItem item, bool owned) async {
    final notifier = ref.read(progressProvider.notifier);
    if (owned) {
      await notifier.equipItem(item);
      _toast('${item.emoji} ${item.name} equipped!', AppTheme.green);
    } else {
      final ok = await notifier.purchaseItem(item);
      if (ok) {
        _confetti.play();
        _toast('🎉 ${item.name} purchased!', AppTheme.yellow);
      } else {
        final need = item.price - ref.read(progressProvider).coins;
        _toast('❌ Need $need more coins!', AppTheme.red);
      }
    }
  }

  void _toast(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: AppTheme.body(14)),
      backgroundColor: color.withOpacity(0.9),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    ));
  }
}

class _ShopCard extends StatelessWidget {
  final ShopItem item;
  final bool owned, selected, canAfford;
  final VoidCallback onTap;
  const _ShopCard({required this.item, required this.owned, required this.selected,
      required this.canAfford, required this.onTap});

  @override
  Widget build(BuildContext context) {
    Color borderColor = AppTheme.bg3;
    Color bgColor = AppTheme.bg2;
    if (selected) { borderColor = AppTheme.yellow; bgColor = AppTheme.yellow.withOpacity(0.08); }
    else if (owned) { borderColor = AppTheme.green; bgColor = AppTheme.green.withOpacity(0.05); }
    else if (!canAfford) { bgColor = AppTheme.bg.withOpacity(0.8); }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: selected ? 2.5 : 1.5),
          boxShadow: selected ? [BoxShadow(color: AppTheme.yellow.withOpacity(0.2), blurRadius: 12, spreadRadius: 1)] : null,
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          
          if (selected)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: AppTheme.yellow, borderRadius: BorderRadius.circular(50)),
              child: Text('✓ EQUIPPED', style: AppTheme.body(9, color: Colors.black, weight: FontWeight.w900)),
            )
          else const SizedBox(height: 6),

          // ── PREMIUM 3D PREVIEW INJECTION ──
          Stack(
            alignment: Alignment.center, 
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.bg.withOpacity(0.5),
                ),
              ),
              if (item.category == ShopCategory.character)
                SizedBox(height: 70, width: 70, child: FullCharacterPreview(charId: item.id, emoji: item.emoji))
              else
                SizedBox(height: 60, width: 60, child: FullRopePreview(ropeId: item.id)),

              if (!owned && !canAfford)
                Positioned(bottom: 0, right: 0, child: Container(
                  width: 26, height: 26,
                  decoration: BoxDecoration(color: Colors.black87, shape: BoxShape.circle, border: Border.all(color: AppTheme.bg3)),
                  child: const Center(child: Text('🔒', style: TextStyle(fontSize: 14))),
                )),
            ]
          ),
          const SizedBox(height: 12),

          Text(item.name, style: AppTheme.body(14, weight: FontWeight.w800), textAlign: TextAlign.center),
          
          if (item.description != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Text(item.description!, style: AppTheme.body(10, color: AppTheme.textSecondary), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),

          const SizedBox(height: 8),

          if (owned && !selected)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(color: AppTheme.green.withOpacity(0.15), borderRadius: BorderRadius.circular(50), border: Border.all(color: AppTheme.green.withOpacity(0.4))),
              child: Text('Tap to Equip', style: AppTheme.body(11, color: AppTheme.greenLight)),
            )
          else if (!owned)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: canAfford ? AppTheme.yellow.withOpacity(0.12) : AppTheme.bg3.withOpacity(0.5),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: canAfford ? AppTheme.yellow : AppTheme.bg3),
              ),
              child: Text(
                item.price == 0 ? '✓ FREE' : '🪙 ${item.price}',
                style: AppTheme.body(12, color: item.price == 0 ? AppTheme.greenLight : canAfford ? AppTheme.yellowLight : AppTheme.textSecondary, weight: FontWeight.w800),
              ),
            ),
        ]),
      ),
    );
  }
}

// ── FULL HEAD-TO-TOE CHARACTER PREVIEWER ──
class FullCharacterPreview extends StatelessWidget {
  final String charId;
  final String emoji;
  const FullCharacterPreview({super.key, required this.charId, required this.emoji});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _MiniCharacterPainter(charId: charId, emoji: emoji),
    );
  }
}

class _MiniCharacterPainter extends CustomPainter {
  final String charId;
  final String emoji;
  const _MiniCharacterPainter({required this.charId, required this.emoji});

  Color _getShirtColor() {
    switch (charId) {
      case 'ninja': return const Color(0xFF222222);
      case 'wizard': return const Color(0xFF8B5CF6);
      case 'robot': return const Color(0xFF9CA3AF);
      case 'alien': return const Color(0xFF10B981);
      case 'astronaut': return const Color(0xFFF3F4F6);
      case 'vampire': return const Color(0xFF991B1B);
      case 'dragon': return const Color(0xFF065F46);
      case 'knight': return const Color(0xFF6B7280);
      case 'pirate': return const Color(0xFF581C87);
      case 'clown': return const Color(0xFFDB2777);
      case 'dino': return const Color(0xFF65A30D);
      default: return const Color(0xFF3A88C8); 
    }
  }

  @override
  void paint(Canvas canvas, Size sz) {
    final cx = sz.width / 2;
    final cy = sz.height / 2;
    final h = sz.height * 1.5; 
    
    final headR = h * 0.080;
    final torsoH= h * 0.220;
    final torsoW= h * 0.180;
    final legLen= h * 0.205;
    final legW  = h * 0.044;
    final armW  = h * 0.033;
    final shoeW = h * 0.065;
    final shoeH = h * 0.034;

    final shirtColor = _getShirtColor();
    final pantsColor = const Color(0xFF181830);
    final skinColor = const Color(0xFFF5C898);

    // Legs
    final lp = Paint()..color = pantsColor..strokeWidth = legW..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx - 5, cy + torsoH/2), Offset(cx - 10, cy + torsoH/2 + legLen), lp);
    canvas.drawLine(Offset(cx + 5, cy + torsoH/2), Offset(cx + 10, cy + torsoH/2 + legLen), lp);

    // Shoes
    final sp = Paint()..color = const Color(0xFF1144AA);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - 15, cy + torsoH/2 + legLen, shoeW, shoeH), const Radius.circular(5)), sp);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx + 5, cy + torsoH/2 + legLen, shoeW, shoeH), const Radius.circular(5)), sp);

    // Torso
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy), width: torsoW, height: torsoH), Radius.circular(torsoW * 0.18)),
      Paint()..color = shirtColor,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + torsoH/2 - 2), width: torsoW * 0.78, height: h * 0.015), const Radius.circular(2)),
      Paint()..color = const Color(0xFF5A2800),
    );

    // Arms
    final ap = Paint()..color = shirtColor..strokeWidth = armW * 1.6..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx - torsoW/2, cy - torsoH/4), Offset(cx - torsoW, cy + 10), ap);
    canvas.drawLine(Offset(cx + torsoW/2, cy - torsoH/4), Offset(cx + torsoW, cy + 10), ap);
    
    canvas.drawCircle(Offset(cx - torsoW, cy + 10), armW * 1.4, Paint()..color = skinColor);
    canvas.drawCircle(Offset(cx + torsoW, cy + 10), armW * 1.4, Paint()..color = skinColor);

    // Neck
    canvas.drawLine(Offset(cx, cy - torsoH/2), Offset(cx, cy - torsoH/2 - headR), Paint()..color = skinColor..strokeWidth = headR * 0.65..strokeCap = StrokeCap.round);

    // Head (Emoji)
    final tp = TextPainter(
      text: TextSpan(text: emoji, style: TextStyle(fontSize: headR * 3.5, shadows: const [Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2))])),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - torsoH/2 - headR - tp.height / 2));
  }
  @override bool shouldRepaint(_MiniCharacterPainter old) => old.charId != charId;
}

// ── FULL PREMIUM ROPE PREVIEWER ──
class FullRopePreview extends StatelessWidget {
  final String ropeId;
  const FullRopePreview({super.key, required this.ropeId});

  List<Color> _getRopeColors() {
    switch (ropeId) {
      case 'fire':     return [Colors.red.shade900, Colors.orange, Colors.yellow, Colors.orange];
      case 'ice':      return [Colors.blue.shade800, Colors.cyanAccent, Colors.white, Colors.cyanAccent];
      case 'gold':     return [Colors.amber.shade800, Colors.yellowAccent, Colors.white, Colors.amber];
      case 'rainbow':  return [Colors.red, Colors.yellow, Colors.green, Colors.blue, Colors.purple];
      case 'electric': return [Colors.indigo, Colors.lightBlueAccent, Colors.white, Colors.indigo];
      case 'lava':     return [Colors.black87, Colors.red.shade600, Colors.orange, Colors.black87];
      case 'neon':     return [Colors.green.shade900, Colors.greenAccent, Colors.white, Colors.greenAccent];
      case 'cosmic':   return [Colors.deepPurple.shade900, Colors.purpleAccent, Colors.pinkAccent];
      case 'dragon':   return [Colors.green.shade900, Colors.lightGreenAccent, Colors.green.shade800];
      case 'classic': 
      default:         return [const Color(0xFF4A2F1D), const Color(0xFF8B5A2B), const Color(0xFF4A2F1D)];
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = _getRopeColors();
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [BoxShadow(color: colors.first.withOpacity(0.8), blurRadius: 15, spreadRadius: 2)],
      ),
      child: Center(
        child: Container(
          width: 30, height: 30,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.black45, width: 2)),
        )
      ),
    );
  }
}