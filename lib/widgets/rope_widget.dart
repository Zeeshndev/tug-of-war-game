import 'dart:math';
import 'package:flutter/material.dart';

/// TugOfWar scene — 2 persons per side, clearly spaced apart.
/// The rope runs from back-person's waist → front-person's hands
/// → center marker → right front-person → right back-person.
/// Rope between the two teammates droops naturally.
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

  Color _ropeColor(String id) {
    const m = {
      'fire':     Color(0xFFE84000), 'ice':      Color(0xFF22BBEE),
      'rainbow':  Color(0xFF9900EE), 'gold':     Color(0xFFBB8800),
      'electric': Color(0xFFCCBB00), 'lava':     Color(0xFFBB1100),
      'neon':     Color(0xFF00BB55), 'cosmic':   Color(0xFF5500BB),
      'dragon':   Color(0xFF771100),
    };
    return m[id] ?? const Color(0xFF3A1F0A);
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
            ropeColor: _ropeColor(widget.ropeId),
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _Painter extends CustomPainter {
  final double pct;       // 0 = player side, 1 = AI side
  final double t;         // 0..1 animation clock
  final Color  ropeColor;

  const _Painter({required this.pct, required this.t, required this.ropeColor});

  // ── Palette ───────────────────────────────────────────────────────────────
  static const _blueA  = Color(0xFF3A88C8);
  static const _blueB  = Color(0xFF62A8E0);
  static const _orange = Color(0xFFE06818);
  static const _pants  = Color(0xFF181830);
  static const _shoeL  = Color(0xFF1144AA);  // left team (blue)
  static const _shoeR  = Color(0xFFBB1111);  // right team (red)
  static const _skin   = Color(0xFFF5C898);
  static const _band   = Color(0xFF1A1A33);
  static const _dash   = Color(0xFFAAAAAA);

  @override
  void paint(Canvas canvas, Size sz) {
    final w  = sz.width;
    final h  = sz.height;
    final gY = h * 0.88;   // ground

    // Ground
    canvas.drawLine(Offset(0, gY), Offset(w, gY),
        Paint()..color = const Color(0xFFBBBBBB)..strokeWidth = 1.0);

    // Centre dashed line (fixed at w/2 — it's the territory border)
    _dashV(canvas, w / 2, h * 0.06, gY);

    // ── Rope knot X — slides 20%..80% of width ──────────────────────────
    final knotX = w * 0.20 + w * 0.60 * pct;
    final knotY = h * 0.49;

    // ── Person geometry ──────────────────────────────────────────────────
    // One "person unit" = pw wide. We use pw to space people out.
    // Front person of each team: centre is 1.0 pw away from the knot.
    // Back  person of each team: centre is 2.8 pw away from the knot.
    // Gap between front & back = 1.8 pw  →  clearly visible space between them.
    final pw = w * 0.11;

    // LEFT team (blue, facing right)
    final lF = knotX - pw * 1.0;   // front person x
    final lB = knotX - pw * 2.8;   // back  person x

    // RIGHT team (orange, facing left)
    final rF = knotX + pw * 1.0;
    final rB = knotX + pw * 2.8;

    // Draw order: back persons first → rope → front persons → knot flag
    // This makes the rope appear between the back and front person correctly.

    _person(canvas, sz, cx: lB, gY: gY, phase: pi,       right: true,
        shirtA: _blueA, shirtB: _blueB, shoe: _shoeL);
    _person(canvas, sz, cx: rB, gY: gY, phase: pi * 1.5, right: false,
        shirtA: _orange, shirtB: _orange, shoe: _shoeR);

    _rope(canvas, sz, knotX, knotY, gY, lF, lB, rF, rB);

    _person(canvas, sz, cx: lF, gY: gY, phase: 0.0,      right: true,
        shirtA: _blueA, shirtB: _blueB, shoe: _shoeL);
    _person(canvas, sz, cx: rF, gY: gY, phase: pi * 0.5, right: false,
        shirtA: _orange, shirtB: _orange, shoe: _shoeR);

    _knot(canvas, Offset(knotX, knotY));

    // Team labels above each team's centre
    _label(canvas, 'YOU', Offset((lF + lB) / 2, h * 0.05), const Color(0xFF1A6BE0));
    _label(canvas, 'CPU', Offset((rF + rB) / 2, h * 0.05), const Color(0xFFCC2200));
  }

  // ── Draw one person ──────────────────────────────────────────────────────
  void _person(Canvas canvas, Size sz, {
    required double cx, required double gY, required double phase,
    required bool right,
    required Color shirtA, required Color shirtB, required Color shoe,
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
    final str   = h * 0.058;    // stride amplitude
    final flex  = h * 0.026;    // knee flex

    // Lean away from centre (backward pull)
    final dir  = right ? -1.0 : 1.0;
    final lean = dir * 0.18;

    final hipY  = gY - legLen * 0.08;
    final hipCy = gY - legLen;

    canvas.save();
    canvas.translate(cx, hipY);
    canvas.rotate(lean);
    canvas.translate(-cx, -hipY);

    // Shadow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, gY + 2), width: torsoH * 0.8, height: h * 0.02),
      Paint()..color = Colors.black.withOpacity(0.15)
             ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // ── Legs ──────────────────────────────────────────────────────────────
    final lp = Paint()..color = _pants..strokeWidth = legW
      ..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;

    // left leg
    final lkX = cx + walk * str * 0.3;
    final lkY = hipCy + legLen * 0.52 + flex * (1 - walk.abs() * 0.55);
    final lfX = cx + walk * str;
    canvas.drawLine(Offset(cx, hipCy), Offset(lkX, lkY), lp);
    canvas.drawLine(Offset(lkX, lkY), Offset(lfX, gY),   lp);

    // right leg (opposite phase)
    final rkX = cx - walk * str * 0.3;
    final rkY = hipCy + legLen * 0.52 + flex * (1 - walk.abs() * 0.55);
    final rfX = cx - walk * str;
    canvas.drawLine(Offset(cx, hipCy), Offset(rkX, rkY), lp);
    canvas.drawLine(Offset(rkX, rkY), Offset(rfX, gY),   lp);

    // Shoes
    final sp = Paint()..color = shoe;
    for (final fx in [lfX, rfX]) {
      final lx = right ? fx - shoeW * 0.28 : fx - shoeW * 0.72;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(lx, gY, shoeW, shoeH),
            Radius.circular(shoeH * 0.45)),
        sp,
      );
    }

    // ── Torso ──────────────────────────────────────────────────────────────
    final tTop = hipCy - torsoH;
    final tMid = (hipCy + tTop) / 2;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, tMid), width: torsoW, height: torsoH),
        Radius.circular(torsoW * 0.18)),
      Paint()..shader = LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [shirtA, shirtB],
      ).createShader(Rect.fromCenter(center: Offset(cx, tMid),
          width: torsoW, height: torsoH)),
    );

    // Mottled stripe pattern (like the Chinese jersey in video)
    if (shirtA != shirtB) {
      final sp2 = Paint()..color = shirtB.withOpacity(0.50)
          ..strokeWidth = torsoW * 0.11;
      for (final dx in [-0.26, 0.0, 0.26]) {
        canvas.drawLine(
          Offset(cx + dx * torsoW, tTop + torsoH * 0.09),
          Offset(cx + dx * torsoW + torsoW * 0.07, hipCy - torsoH * 0.06),
          sp2,
        );
      }
    }

    // Belt
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, hipCy - torsoH * 0.03),
            width: torsoW * 0.78, height: h * 0.015),
        const Radius.circular(2)),
      Paint()..color = const Color(0xFF5A2800),
    );

    // ── Arms ──────────────────────────────────────────────────────────────
    final shouldY = tTop + torsoH * 0.10;
    final aDir    = right ? 1.0 : -1.0;
    final swing   = sin(t * pi * 2 + phase + pi) * h * 0.014;

    final ap = Paint()..color = shirtA..strokeWidth = armW * 1.6
      ..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;

    // Upper arm (front)
    final e1x = cx + aDir * torsoW * 0.52 + swing;
    final e1y = shouldY + torsoH * 0.28;
    final h1x = cx + aDir * torsoW * 0.90;
    final h1y = shouldY + torsoH * 0.52;
    canvas.drawLine(Offset(cx, shouldY),            Offset(e1x, e1y), ap);
    canvas.drawLine(Offset(e1x, e1y),               Offset(h1x, h1y), ap);

    // Lower arm (back)
    final e2x = cx + aDir * torsoW * 0.44 - swing;
    final e2y = shouldY + torsoH * 0.40;
    final h2x = cx + aDir * torsoW * 0.82;
    final h2y = shouldY + torsoH * 0.66;
    canvas.drawLine(Offset(cx, shouldY + torsoH * 0.08), Offset(e2x, e2y), ap);
    canvas.drawLine(Offset(e2x, e2y),                    Offset(h2x, h2y), ap);

    // Fists
    canvas.drawCircle(Offset(h1x, h1y), armW * 1.45, Paint()..color = _skin);
    canvas.drawCircle(Offset(h2x, h2y), armW * 1.20, Paint()..color = _skin);

    // ── Neck ──────────────────────────────────────────────────────────────
    canvas.drawLine(Offset(cx, tTop), Offset(cx, tTop - headR * 0.62),
        Paint()..color = _skin..strokeWidth = headR * 0.65
               ..strokeCap = StrokeCap.round);

    // ── Head ──────────────────────────────────────────────────────────────
    final bob   = sin(t * pi * 2 + phase) * h * 0.0038;
    final headY = tTop - headR * 1.08 + bob;

    canvas.drawCircle(Offset(cx, headY), headR, Paint()..color = _skin);

    // Headband (top half dark)
    final hbPath = Path()
      ..moveTo(cx - headR, headY)
      ..arcTo(Rect.fromCircle(center: Offset(cx, headY), radius: headR), pi, pi, false)
      ..close();
    canvas.drawPath(hbPath, Paint()..color = _band);

    // Band dividing line
    canvas.drawLine(Offset(cx - headR, headY), Offset(cx + headR, headY),
        Paint()..color = Colors.white60..strokeWidth = headR * 0.13);

    // Eyes
    final eyeY = headY + headR * 0.12;
    final eyeR = headR * 0.13;
    final eyeO = headR * 0.50;
    canvas.drawCircle(Offset(cx - eyeO, eyeY), eyeR, Paint()..color = const Color(0xFF111111));
    canvas.drawCircle(Offset(cx + eyeO, eyeY), eyeR, Paint()..color = const Color(0xFF111111));

    // Mouth (determined straight line)
    canvas.drawLine(
      Offset(cx - headR * 0.22, headY + headR * 0.46),
      Offset(cx + headR * 0.22, headY + headR * 0.46),
      Paint()..color = const Color(0xFF553322)
             ..strokeWidth = headR * 0.12..strokeCap = StrokeCap.round,
    );

    canvas.restore();
  }

  // ── Draw rope ─────────────────────────────────────────────────────────────
  // Layout:
  //   lTail → lB_hand ~~(sag)~~ lF_hand → KNOT → rF_hand ~~(sag)~~ rB_hand → rTail
  //
  // The two segments with sag (between teammates) show a realistic flexible rope.
  // The two segments from front-hand to knot are nearly taut (slight vibration).
  void _rope(Canvas canvas, Size sz,
      double knotX, double knotY, double gY,
      double lF, double lB, double rF, double rB) {
    final h  = sz.height;
    final w  = sz.width;
    final vib = sin(t * pi * 4) * 2.8;   // subtle vibration

    // Fist positions (at arm extension from each person's torso)
    final fistOff = h * 0.180 * 0.90;   // approx distance to fist from cx
    final lFist   = lF + fistOff;   // left-front person's right hand
    final rFist   = rF - fistOff;   // right-front person's left hand
    final lBFist  = lB + fistOff;   // left-back person's right hand
    final rBFist  = rB - fistOff;   // right-back person's left hand

    final mainPaint = Paint()
      ..color     = ropeColor
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..style     = PaintingStyle.stroke;

    final sagPaint = Paint()
      ..color     = ropeColor
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style     = PaintingStyle.stroke;

    final tailPaint = Paint()
      ..color     = ropeColor.withOpacity(0.55)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style     = PaintingStyle.stroke;

    // ── Taut segment: left-front hand → knot ─────────────────────────────
    final lSag = (knotX - lFist) * 0.06 + vib;
    final lMain = Path()
      ..moveTo(lFist, knotY + 2)
      ..quadraticBezierTo((lFist + knotX) / 2, knotY + lSag.abs() + 3, knotX, knotY);
    canvas.drawPath(lMain, mainPaint);

    // ── Taut segment: knot → right-front hand ────────────────────────────
    final rSag = (rFist - knotX) * 0.06 + vib;
    final rMain = Path()
      ..moveTo(knotX, knotY)
      ..quadraticBezierTo((knotX + rFist) / 2, knotY + rSag.abs() + 3, rFist, knotY + 2);
    canvas.drawPath(rMain, mainPaint);

    // ── Sagging segment: left-back hand → left-front hand ─────────────────
    // Rope between the two LEFT team members droops down
    final lInnerLen = lFist - lBFist;
    final lDropAnim = sin(t * pi * 2) * 4.0;
    final lDrop = lInnerLen * 0.22 + lDropAnim.abs() + 8;
    final lInner = Path()
      ..moveTo(lBFist, knotY + 4)
      ..cubicTo(
        lBFist + lInnerLen * 0.25, knotY + lDrop,
        lBFist + lInnerLen * 0.75, knotY + lDrop,
        lFist,  knotY + 2,
      );
    canvas.drawPath(lInner, sagPaint);

    // ── Sagging segment: right-front hand → right-back hand ───────────────
    final rInnerLen = rBFist - rFist;
    final rDropAnim = sin(t * pi * 2 + pi) * 4.0;
    final rDrop = rInnerLen * 0.22 + rDropAnim.abs() + 8;
    final rInner = Path()
      ..moveTo(rFist, knotY + 2)
      ..cubicTo(
        rFist  + rInnerLen * 0.25, knotY + rDrop,
        rFist  + rInnerLen * 0.75, knotY + rDrop,
        rBFist, knotY + 4,
      );
    canvas.drawPath(rInner, sagPaint);

    // ── Rope tail trailing off behind back persons ────────────────────────
    // Left tail
    final lTail = Path()
      ..moveTo(lBFist, knotY + 5)
      ..cubicTo(
        lBFist - w * 0.05, knotY + 8,
        lB     - fistOff - w * 0.02, gY * 0.82,
        lB     - fistOff - w * 0.04, gY * 0.90,
      );
    canvas.drawPath(lTail, tailPaint);

    // Right tail
    final rTail = Path()
      ..moveTo(rBFist, knotY + 5)
      ..cubicTo(
        rBFist + w * 0.05, knotY + 8,
        rB     + fistOff + w * 0.02, gY * 0.82,
        rB     + fistOff + w * 0.04, gY * 0.90,
      );
    canvas.drawPath(rTail, tailPaint);
  }

  // ── Red center knot/flag ──────────────────────────────────────────────────
  void _knot(Canvas canvas, Offset pos) {
    canvas.drawCircle(pos, 8.5, Paint()..color = const Color(0xFFDD0022));
    canvas.drawCircle(pos, 8.5,
        Paint()..color = Colors.white.withOpacity(0.20)
               ..strokeWidth = 1.5..style = PaintingStyle.stroke);
    canvas.drawCircle(Offset(pos.dx - 2.5, pos.dy - 2.5), 3,
        Paint()..color = Colors.white.withOpacity(0.40));
  }

  void _dashV(Canvas canvas, double x, double top, double bot) {
    final p = Paint()..color = _dash..strokeWidth = 1.4;
    double y = top;
    while (y < bot) { canvas.drawLine(Offset(x, y), Offset(x, y + 9), p); y += 16; }
  }

  void _label(Canvas canvas, String text, Offset centre, Color color) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(
        color: color, fontSize: 11, fontWeight: FontWeight.w900,
        letterSpacing: 1.2,
        shadows: const [Shadow(color: Colors.white, blurRadius: 4)],
      )),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(centre.dx - tp.width / 2, centre.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(_Painter o) =>
      o.pct != pct || o.t != t || o.ropeColor != ropeColor;
}
