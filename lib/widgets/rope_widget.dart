import 'dart:math';
import 'package:flutter/material.dart';
import '../models/game_models.dart';

class RopeWidget extends StatefulWidget {
  final double ropePosition; // −10 (player winning) … +10 (AI winning)
  final String playerCharId;
  final String ropeId;

  const RopeWidget({
    super.key,
    required this.ropePosition,
    this.playerCharId = 'hero',
    this.ropeId = 'classic',
  });

  @override
  State<RopeWidget> createState() => _RWState();
}

class _RWState extends State<RopeWidget> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1600))..repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  List<Color> _getRopeColors(String id) {
    switch (id) {
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
    final pct = ((widget.ropePosition + 10.0) / 20.0).clamp(0.05, 0.95);
    return Container(
      height: 190,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: const Color(0xFFF0F5FF),
        border: Border.all(color: const Color(0xFFCCD5EE), width: 1.5),
      ),
      clipBehavior: Clip.hardEdge,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => CustomPaint(
          painter: _Painter(
            pct:       pct,
            t:         _ctrl.value,
            ropeColors: _getRopeColors(widget.ropeId),
            playerCharId: widget.playerCharId,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _Painter extends CustomPainter {
  final double pct;       
  final double t;         
  final List<Color> ropeColors;
  final String playerCharId;

  const _Painter({
    required this.pct, 
    required this.t, 
    required this.ropeColors,
    required this.playerCharId,
  });

  static const _orange = Color(0xFFE06818);
  static const _pants  = Color(0xFF181830);
  static const _shoeL  = Color(0xFF1144AA);  
  static const _shoeR  = Color(0xFFBB1111);  
  static const _skin   = Color(0xFFF5C898);
  static const _dash   = Color(0xFFAAAAAA);

  Color _getShirtColor() {
    switch (playerCharId) {
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
    final w  = sz.width;
    final h  = sz.height;
    final gY = h * 0.88;   

    canvas.drawLine(Offset(0, gY), Offset(w, gY), Paint()..color = const Color(0xFFBBBBBB)..strokeWidth = 1.0);
    _dashV(canvas, w / 2, h * 0.06, gY);

    final knotX = w * 0.20 + w * 0.60 * pct;
    final knotY = h * 0.49;
    final pw = w * 0.11;

    final lF = knotX - pw * 1.0;   
    final lB = knotX - pw * 2.8;   
    final rF = knotX + pw * 1.0;
    final rB = knotX + pw * 2.8;

    final playerShirt = _getShirtColor();

    _person(canvas, sz, cx: lB, gY: gY, phase: pi, right: true, shirtA: playerShirt, shirtB: playerShirt.withOpacity(0.8), shoe: _shoeL, isPlayer: true);
    _person(canvas, sz, cx: rB, gY: gY, phase: pi * 1.5, right: false, shirtA: _orange, shirtB: _orange, shoe: _shoeR, isPlayer: false);

    _rope(canvas, sz, knotX, knotY, gY, lF, lB, rF, rB);

    _person(canvas, sz, cx: lF, gY: gY, phase: 0.0, right: true, shirtA: playerShirt, shirtB: playerShirt.withOpacity(0.8), shoe: _shoeL, isPlayer: true);
    _person(canvas, sz, cx: rF, gY: gY, phase: pi * 0.5, right: false, shirtA: _orange, shirtB: _orange, shoe: _shoeR, isPlayer: false);

    _knot(canvas, Offset(knotX, knotY));
    _label(canvas, 'YOU', Offset((lF + lB) / 2, h * 0.05), const Color(0xFF1A6BE0));
    _label(canvas, 'CPU', Offset((rF + rB) / 2, h * 0.05), const Color(0xFFCC2200));
  }

  void _person(Canvas canvas, Size sz, {
    required double cx, required double gY, required double phase,
    required bool right, required Color shirtA, required Color shirtB, 
    required Color shoe, required bool isPlayer,
  }) {
    final h = sz.height;
    final headR = h * 0.080;
    final torsoH= h * 0.220;
    final torsoW= h * 0.180;
    final legLen= h * 0.205;
    final legW  = h * 0.044;
    final armW  = h * 0.033;
    final shoeW = h * 0.065;
    final shoeH = h * 0.034;

    final walk  = sin(t * pi * 2 + phase);
    final str   = h * 0.058;    
    final flex  = h * 0.026;    
    final dir  = right ? -1.0 : 1.0;
    final lean = dir * 0.18;

    final hipY  = gY - legLen * 0.08;
    final hipCy = gY - legLen;

    canvas.save();
    canvas.translate(cx, hipY);
    canvas.rotate(lean);
    canvas.translate(-cx, -hipY);

    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, gY + 2), width: torsoH * 0.8, height: h * 0.02),
      Paint()..color = Colors.black.withOpacity(0.15)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    final lp = Paint()..color = _pants..strokeWidth = legW..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;

    final lkX = cx + walk * str * 0.3;
    final lkY = hipCy + legLen * 0.52 + flex * (1 - walk.abs() * 0.55);
    final lfX = cx + walk * str;
    canvas.drawLine(Offset(cx, hipCy), Offset(lkX, lkY), lp);
    canvas.drawLine(Offset(lkX, lkY), Offset(lfX, gY),   lp);

    final rkX = cx - walk * str * 0.3;
    final rkY = hipCy + legLen * 0.52 + flex * (1 - walk.abs() * 0.55);
    final rfX = cx - walk * str;
    canvas.drawLine(Offset(cx, hipCy), Offset(rkX, rkY), lp);
    canvas.drawLine(Offset(rkX, rkY), Offset(rfX, gY),   lp);

    final sp = Paint()..color = shoe;
    for (final fx in [lfX, rfX]) {
      final lx = right ? fx - shoeW * 0.28 : fx - shoeW * 0.72;
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(lx, gY, shoeW, shoeH), Radius.circular(shoeH * 0.45)), sp);
    }

    final tTop = hipCy - torsoH;
    final tMid = (hipCy + tTop) / 2;

    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, tMid), width: torsoW, height: torsoH), Radius.circular(torsoW * 0.18)),
      Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [shirtA, shirtB]).createShader(Rect.fromCenter(center: Offset(cx, tMid), width: torsoW, height: torsoH)),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, hipCy - torsoH * 0.03), width: torsoW * 0.78, height: h * 0.015), const Radius.circular(2)),
      Paint()..color = const Color(0xFF5A2800),
    );

    final shouldY = tTop + torsoH * 0.10;
    final aDir    = right ? 1.0 : -1.0;
    final swing   = sin(t * pi * 2 + phase + pi) * h * 0.014;
    final ap = Paint()..color = shirtA..strokeWidth = armW * 1.6..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;

    final e1x = cx + aDir * torsoW * 0.52 + swing;
    final e1y = shouldY + torsoH * 0.28;
    final h1x = cx + aDir * torsoW * 0.90;
    final h1y = shouldY + torsoH * 0.52;
    canvas.drawLine(Offset(cx, shouldY), Offset(e1x, e1y), ap);
    canvas.drawLine(Offset(e1x, e1y), Offset(h1x, h1y), ap);

    final e2x = cx + aDir * torsoW * 0.44 - swing;
    final e2y = shouldY + torsoH * 0.40;
    final h2x = cx + aDir * torsoW * 0.82;
    final h2y = shouldY + torsoH * 0.66;
    canvas.drawLine(Offset(cx, shouldY + torsoH * 0.08), Offset(e2x, e2y), ap);
    canvas.drawLine(Offset(e2x, e2y), Offset(h2x, h2y), ap);

    canvas.drawCircle(Offset(h1x, h1y), armW * 1.45, Paint()..color = _skin);
    canvas.drawCircle(Offset(h2x, h2y), armW * 1.20, Paint()..color = _skin);

    canvas.drawLine(Offset(cx, tTop), Offset(cx, tTop - headR * 0.62), Paint()..color = _skin..strokeWidth = headR * 0.65..strokeCap = StrokeCap.round);

    final bob   = sin(t * pi * 2 + phase) * h * 0.0038;
    final headY = tTop - headR * 1.08 + bob;

    String emojiChar = '🤖';
    if (isPlayer) {
      try { emojiChar = kCharacters.firstWhere((c) => c.id == playerCharId).emoji; } catch (_) { emojiChar = '🦸'; }
    }

    final tp = TextPainter(
      text: TextSpan(text: emojiChar, style: TextStyle(fontSize: headR * 2.5, shadows: const [Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2))])),
      textDirection: TextDirection.ltr,
    )..layout();
    
    tp.paint(canvas, Offset(cx - tp.width / 2, headY - tp.height / 2));
    canvas.restore();
  }

  void _rope(Canvas canvas, Size sz, double knotX, double knotY, double gY, double lF, double lB, double rF, double rB) {
    final h  = sz.height;
    final w  = sz.width;
    final vib = sin(t * pi * 8) * 1.5;   

    final fistOff = h * 0.180 * 0.90;   
    final lFist   = lF + fistOff;   
    final rFist   = rF - fistOff;   
    final lBFist  = lB + fistOff;   
    final rBFist  = rB - fistOff;   

    // Apply Premium Shader Gradient to Rope
    final ropeBounds = Rect.fromLTRB(lBFist, knotY - 10, rBFist, knotY + 10);
    final ropeShader = LinearGradient(colors: ropeColors).createShader(ropeBounds);

    final mainPaint = Paint()
      ..shader      = ropeShader
      ..strokeWidth = 6.5
      ..strokeCap   = StrokeCap.round
      ..strokeJoin  = StrokeJoin.round
      ..style       = PaintingStyle.stroke;

    final ropePath = Path()
      ..moveTo(lBFist, knotY + 2 + vib)
      ..lineTo(lFist, knotY + 2 - vib)
      ..lineTo(knotX, knotY + vib)
      ..lineTo(rFist, knotY + 2 - vib)
      ..lineTo(rBFist, knotY + 2 + vib);
      
    canvas.drawPath(ropePath, mainPaint);

    final tailPaint = Paint()
      ..shader      = ropeShader
      ..strokeWidth = 4.0
      ..strokeCap   = StrokeCap.round
      ..style       = PaintingStyle.stroke;

    final lTail = Path()
      ..moveTo(lBFist, knotY + 2 + vib)
      ..quadraticBezierTo(lB - fistOff - w * 0.02, knotY + 10, lB - fistOff - w * 0.04, gY * 0.90);
    canvas.drawPath(lTail, tailPaint);

    final rTail = Path()
      ..moveTo(rBFist, knotY + 2 + vib)
      ..quadraticBezierTo(rB + fistOff + w * 0.02, knotY + 10, rB + fistOff + w * 0.04, gY * 0.90);
    canvas.drawPath(rTail, tailPaint);
  }

  void _knot(Canvas canvas, Offset pos) {
    canvas.drawCircle(pos, 8.5, Paint()..color = const Color(0xFFDD0022));
    canvas.drawCircle(pos, 8.5, Paint()..color = Colors.white.withOpacity(0.20)..strokeWidth = 1.5..style = PaintingStyle.stroke);
    canvas.drawCircle(Offset(pos.dx - 2.5, pos.dy - 2.5), 3, Paint()..color = Colors.white.withOpacity(0.40));
  }

  void _dashV(Canvas canvas, double x, double top, double bot) {
    final p = Paint()..color = _dash..strokeWidth = 1.4;
    double y = top;
    while (y < bot) { canvas.drawLine(Offset(x, y), Offset(x, y + 9), p); y += 16; }
  }

  void _label(Canvas canvas, String text, Offset centre, Color color) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2, shadows: const [Shadow(color: Colors.white, blurRadius: 4)])),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(centre.dx - tp.width / 2, centre.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(_Painter o) => o.pct != pct || o.t != t || o.ropeColors != ropeColors || o.playerCharId != playerCharId;
}