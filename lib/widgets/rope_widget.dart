import 'dart:math';
import 'package:flutter/material.dart';

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

  static const _dash   = Color(0xFFAAAAAA);

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

    // Draw background characters
    _person(canvas, sz, cx: lB, gY: gY, phase: pi, right: true, skinId: playerCharId);
    _person(canvas, sz, cx: rB, gY: gY, phase: pi * 1.5, right: false, skinId: 'robot');

    // Draw Rope
    _rope(canvas, sz, knotX, knotY, gY, lF, lB, rF, rB);

    // Draw foreground characters
    _person(canvas, sz, cx: lF, gY: gY, phase: 0.0, right: true, skinId: playerCharId);
    _person(canvas, sz, cx: rF, gY: gY, phase: pi * 0.5, right: false, skinId: 'robot');

    _knot(canvas, Offset(knotX, knotY));
    _label(canvas, 'YOU', Offset((lF + lB) / 2, h * 0.05), const Color(0xFF1A6BE0));
    _label(canvas, 'CPU', Offset((rF + rB) / 2, h * 0.05), const Color(0xFFCC2200));
  }

  // ── PREMIUM CHARACTER INJECTION ON ORIGINAL SKELETON ──
  void _person(Canvas canvas, Size sz, {
    required double cx, required double gY, required double phase,
    required bool right, required String skinId,
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

    // ── 1. Define Skin Colors & Features (UC-003) ──
    Color shirtC, pantsC, shoeC, skinC, gloveC;
    bool isRobot = skinId == 'robot';
    
    switch (skinId) {
      case 'ninja': 
        shirtC = const Color(0xFF1A1A1A); pantsC = const Color(0xFF222222); shoeC = Colors.black; skinC = const Color(0xFFFFCCAA); gloveC = Colors.black; break;
      case 'wizard': 
        shirtC = const Color(0xFF6B21A8); pantsC = const Color(0xFF4C1D95); shoeC = Colors.brown; skinC = const Color(0xFFFFCCAA); gloveC = const Color(0xFFFFCCAA); break;
      case 'robot': 
        shirtC = const Color(0xFF9CA3AF); pantsC = const Color(0xFF6B7280); shoeC = Colors.grey.shade800; skinC = const Color(0xFF9CA3AF); gloveC = Colors.orange; break;
      case 'dragon': 
        shirtC = const Color(0xFFDC2626); pantsC = const Color(0xFF991B1B); shoeC = Colors.orange.shade800; skinC = const Color(0xFFDC2626); gloveC = Colors.orange; break;
      case 'hero':
      default:
        shirtC = const Color(0xFF2563EB); pantsC = const Color(0xFF1E3A8A); shoeC = const Color(0xFFDC2626); skinC = const Color(0xFFFFCCAA); gloveC = const Color(0xFFFFCCAA); break;
    }

    canvas.save();
    canvas.translate(cx, hipY);
    canvas.rotate(lean);
    canvas.translate(-cx, -hipY);

    // Drop shadow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, gY + 2), width: torsoH * 0.8, height: h * 0.02),
      Paint()..color = Colors.black.withOpacity(0.15)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // ── 2. Background Accessories (Tails / Capes) ──
    final tTop = hipCy - torsoH;
    final tMid = (hipCy + tTop) / 2;
    if (skinId == 'hero') {
      canvas.drawArc(Rect.fromCircle(center: Offset(cx + (15 * dir), tMid), radius: 25), 0, 3.14, true, Paint()..color = Colors.red.shade700);
    } else if (skinId == 'dragon') {
      canvas.drawArc(Rect.fromCircle(center: Offset(cx + (20 * dir), hipCy), radius: 15), 0, 3.14, false, Paint()..color = Colors.red.shade900..style = PaintingStyle.stroke..strokeWidth = 6);
    }

    // ── 3. Legs & Shoes (Original Kinematics) ──
    final lp = Paint()..color = pantsC..strokeWidth = legW..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;

    final lkX = cx + walk * str * 0.3;
    final lkY = hipCy + legLen * 0.52 + flex * (1 - walk.abs() * 0.55);
    final lfX = cx + walk * str;
    canvas.drawLine(Offset(cx, hipCy), Offset(lkX, lkY), lp);
    canvas.drawLine(Offset(lkX, lkY), Offset(lfX, gY),   lp);
    if (isRobot) canvas.drawCircle(Offset(lkX, lkY), legW*0.6, Paint()..color = Colors.orange); // Robot Joints

    final rkX = cx - walk * str * 0.3;
    final rkY = hipCy + legLen * 0.52 + flex * (1 - walk.abs() * 0.55);
    final rfX = cx - walk * str;
    canvas.drawLine(Offset(cx, hipCy), Offset(rkX, rkY), lp);
    canvas.drawLine(Offset(rkX, rkY), Offset(rfX, gY),   lp);
    if (isRobot) canvas.drawCircle(Offset(rkX, rkY), legW*0.6, Paint()..color = Colors.orange);

    final sp = Paint()..color = shoeC;
    for (final fx in [lfX, rfX]) {
      final lx = right ? fx - shoeW * 0.28 : fx - shoeW * 0.72;
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(lx, gY, shoeW, shoeH), Radius.circular(shoeH * 0.45)), sp);
    }

    // ── 4. Torso ──
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, tMid), width: torsoW, height: torsoH), Radius.circular(torsoW * 0.18)),
      Paint()..color = shirtC,
    );
    // Belt
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, hipCy - torsoH * 0.03), width: torsoW * 0.78, height: h * 0.015), const Radius.circular(2)), Paint()..color = Colors.black54);
    // Hero 'S'
    if (skinId == 'hero') canvas.drawCircle(Offset(cx - (4 * dir), tMid - 5), 8, Paint()..color = Colors.yellow);
    // Dragon Belly
    if (skinId == 'dragon') canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx - (5 * dir), tMid), width: torsoW*0.5, height: torsoH*0.7), Radius.circular(4)), Paint()..color = Colors.amber.shade200);

    // ── 5. Arms (Original Kinematics) ──
    final shouldY = tTop + torsoH * 0.10;
    final aDir    = right ? 1.0 : -1.0;
    final swing   = sin(t * pi * 2 + phase + pi) * h * 0.014;
    final ap = Paint()..color = shirtC..strokeWidth = armW * 1.6..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;

    final e1x = cx + aDir * torsoW * 0.52 + swing;
    final e1y = shouldY + torsoH * 0.28;
    final h1x = cx + aDir * torsoW * 0.90;
    final h1y = shouldY + torsoH * 0.52;
    canvas.drawLine(Offset(cx, shouldY), Offset(e1x, e1y), ap);
    canvas.drawLine(Offset(e1x, e1y), Offset(h1x, h1y), ap);
    if (isRobot) canvas.drawCircle(Offset(e1x, e1y), armW*0.8, Paint()..color = Colors.orange); // Robot Elbow

    final e2x = cx + aDir * torsoW * 0.44 - swing;
    final e2y = shouldY + torsoH * 0.40;
    final h2x = cx + aDir * torsoW * 0.82;
    final h2y = shouldY + torsoH * 0.66;
    canvas.drawLine(Offset(cx, shouldY + torsoH * 0.08), Offset(e2x, e2y), ap);
    canvas.drawLine(Offset(e2x, e2y), Offset(h2x, h2y), ap);

    // Hands
    canvas.drawCircle(Offset(h1x, h1y), armW * 1.45, Paint()..color = gloveC);
    canvas.drawCircle(Offset(h2x, h2y), armW * 1.20, Paint()..color = gloveC);

    // Wizard Wand
    if (skinId == 'wizard') {
      canvas.drawLine(Offset(h1x, h1y), Offset(h1x - (15 * dir), h1y - 20), Paint()..color = Colors.amber..strokeWidth = 3);
      canvas.drawCircle(Offset(h1x - (15 * dir), h1y - 20), 4, Paint()..color = Colors.yellowAccent);
    }

    // ── 6. Premium Custom Heads ──
    final bob   = sin(t * pi * 2 + phase) * h * 0.0038;
    final headY = tTop - headR * 1.08 + bob;

    _drawPremiumHead(canvas, Offset(cx, headY), headR, dir, skinId, skinC);

    canvas.restore();
  }

  void _drawPremiumHead(Canvas canvas, Offset pos, double r, double dir, String skinId, Color skinC) {
    // Base Head
    if (skinId == 'robot') {
      canvas.drawRect(Rect.fromCenter(center: pos, width: r*2, height: r*2), Paint()..color = skinC);
      // Antenna
      canvas.drawLine(Offset(pos.dx, pos.dy - r), Offset(pos.dx, pos.dy - r - 15), Paint()..color = Colors.grey..strokeWidth=2);
      canvas.drawCircle(Offset(pos.dx, pos.dy - r - 15), 3, Paint()..color = Colors.red);
      // Red Eyes
      canvas.drawRect(Rect.fromCenter(center: Offset(pos.dx - (6 * dir), pos.dy - 4), width: r*0.6, height: r*0.3), Paint()..color = Colors.redAccent);
    } else {
      // Humanoid/Dragon Head Base
      canvas.drawCircle(pos, r, Paint()..color = skinId == 'ninja' ? Colors.black : skinC);
      
      if (skinId == 'ninja') {
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(pos.dx - (4 * dir), pos.dy), width: r*1.2, height: r*0.6), const Radius.circular(4)), Paint()..color = const Color(0xFFFFCCAA));
        canvas.drawLine(Offset(pos.dx - r, pos.dy - r*0.6), Offset(pos.dx + r, pos.dy - r*0.6), Paint()..color = Colors.redAccent..strokeWidth=4); // Headband
      } else if (skinId == 'wizard') {
        // Pointy Hat
        final hat = Path()..moveTo(pos.dx - r*1.2, pos.dy - r*0.5)..lineTo(pos.dx + r*1.2, pos.dy - r*0.5)..lineTo(pos.dx + (5 * dir), pos.dy - r*2.5)..close();
        canvas.drawPath(hat, Paint()..color = const Color(0xFF6B21A8));
        canvas.drawCircle(Offset(pos.dx - (4 * dir), pos.dy + r*0.8), r*0.6, Paint()..color = Colors.white); // Beard
      } else if (skinId == 'dragon') {
        // Snout
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(pos.dx - (6 * dir), pos.dy), width: r*1.6, height: r*1.2), const Radius.circular(6)), Paint()..color = skinC);
        // Horns
        canvas.drawPath(Path()..moveTo(pos.dx - 4, pos.dy - r*0.8)..lineTo(pos.dx - 8, pos.dy - r*1.5)..lineTo(pos.dx + 4, pos.dy - r*0.8)..close(), Paint()..color = Colors.grey.shade300);
      }
      
      // Standard Eyes
      if (skinId != 'ninja' && skinId != 'robot') {
        canvas.drawCircle(Offset(pos.dx - (8 * dir), pos.dy - 2), 3, Paint()..color = Colors.black);
      } else if (skinId == 'ninja') {
        canvas.drawLine(Offset(pos.dx - (10 * dir), pos.dy - 1), Offset(pos.dx - (4 * dir), pos.dy + 1), Paint()..color = Colors.black..strokeWidth=2);
      }
    }
  }

  // ── ORIGINAL ROPE & KNOT DRAWING KEEPS WORKING PERFECTLY ──
  void _rope(Canvas canvas, Size sz, double knotX, double knotY, double gY, double lF, double lB, double rF, double rB) {
    final h  = sz.height;
    final w  = sz.width;
    final vib = sin(t * pi * 8) * 1.5;   

    final fistOff = h * 0.180 * 0.90;   
    final lFist   = lF + fistOff;   
    final rFist   = rF - fistOff;   
    final lBFist  = lB + fistOff;   
    final rBFist  = rB - fistOff;   

    final ropeBounds = Rect.fromLTRB(lBFist, knotY - 10, rBFist, knotY + 10);
    final ropeShader = LinearGradient(colors: ropeColors).createShader(ropeBounds);

    final mainPaint = Paint()..shader = ropeShader..strokeWidth = 6.5..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round..style = PaintingStyle.stroke;

    final ropePath = Path()..moveTo(lBFist, knotY + 2 + vib)..lineTo(lFist, knotY + 2 - vib)..lineTo(knotX, knotY + vib)..lineTo(rFist, knotY + 2 - vib)..lineTo(rBFist, knotY + 2 + vib);
    canvas.drawPath(ropePath, mainPaint);

    final tailPaint = Paint()..shader = ropeShader..strokeWidth = 4.0..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;
    final lTail = Path()..moveTo(lBFist, knotY + 2 + vib)..quadraticBezierTo(lB - fistOff - w * 0.02, knotY + 10, lB - fistOff - w * 0.04, gY * 0.90);
    canvas.drawPath(lTail, tailPaint);
    final rTail = Path()..moveTo(rBFist, knotY + 2 + vib)..quadraticBezierTo(rB + fistOff + w * 0.02, knotY + 10, rB + fistOff + w * 0.04, gY * 0.90);
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