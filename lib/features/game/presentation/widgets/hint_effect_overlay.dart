import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'hint_effect_type.dart';

/// Animated overlay widget that plays a hint effect animation on a cell.
///
/// The effect plays for [_kDuration] then calls [onComplete].
/// The number underneath is revealed as the effect fades out.
class HintEffectOverlay extends StatefulWidget {
  const HintEffectOverlay({
    super.key,
    required this.effectType,
    required this.onComplete,
  });

  final HintEffectType effectType;
  final VoidCallback onComplete;

  @override
  State<HintEffectOverlay> createState() => _HintEffectOverlayState();
}

const Duration _kDuration = Duration(milliseconds: 1600);

class _HintEffectOverlayState extends State<HintEffectOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final int _seed;

  @override
  void initState() {
    super.initState();
    _seed = DateTime.now().microsecondsSinceEpoch % 10000;
    _controller = AnimationController(
      duration: _kDuration,
      vsync: this,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onComplete();
        }
      });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _createPainter(_controller.value),
          size: Size.infinite,
        );
      },
    );
  }

  CustomPainter _createPainter(double progress) {
    switch (widget.effectType) {
      case HintEffectType.lightning:
        return _LightningPainter(progress: progress, seed: _seed);
      case HintEffectType.bomb:
        return _BombPainter(progress: progress, seed: _seed);
      case HintEffectType.hurricane:
        return _HurricanePainter(progress: progress, seed: _seed);
      case HintEffectType.hammer:
        return _HammerPainter(progress: progress, seed: _seed);
      case HintEffectType.fire:
        return _FirePainter(progress: progress, seed: _seed);
      case HintEffectType.magicSparkle:
        return _MagicSparklePainter(progress: progress, seed: _seed);
    }
  }
}

// ============================================================
// Utility helpers
// ============================================================

/// Returns sub-animation progress within [start]..[end] range, clamped 0..1.
double _phase(double progress, double start, double end) {
  if (end <= start) return 1.0;
  return ((progress - start) / (end - start)).clamp(0.0, 1.0);
}

/// Deterministic pseudo-random value in [0..1) from seed and index.
double _rand(int seed, int index) {
  return ((sin(index * 127.1 + seed * 311.7) * 43758.5453) % 1.0).abs();
}

/// Easing function: ease out cubic.
double _easeOut(double t) => 1.0 - pow(1.0 - t, 3).toDouble();

/// Easing function: ease in cubic.
double _easeIn(double t) => pow(t, 3).toDouble();

// ============================================================
// 1. Lightning Effect (번개 - 헤라클레스 번개)
// ============================================================

class _LightningPainter extends CustomPainter {
  final double progress;
  final int seed;
  _LightningPainter({required this.progress, required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // --- Background flash ---
    final flashIn = _phase(progress, 0.05, 0.2);
    final flashOut = _phase(progress, 0.4, 0.7);
    final flashAlpha = ((flashIn - flashOut) * 0.75).clamp(0.0, 1.0);
    if (flashAlpha > 0) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = const Color(0xFFE0F0FF).withOpacity(flashAlpha),
      );
    }

    // --- Lightning bolt ---
    final boltDraw = _phase(progress, 0.0, 0.25);
    final boltFade = _phase(progress, 0.45, 0.75);
    if (boltDraw > 0 && boltFade < 1) {
      _drawBolt(canvas, size, boltDraw, 1.0 - boltFade);
    }

    // --- Impact glow ---
    final glowIn = _phase(progress, 0.15, 0.35);
    final glowOut = _phase(progress, 0.5, 0.85);
    final glowI = (_easeOut(glowIn) - glowOut).clamp(0.0, 1.0);
    if (glowI > 0) {
      canvas.drawCircle(
        Offset(cx, cy),
        size.width * 0.35 * glowI,
        Paint()
          ..color = const Color(0xFF64C8FF).withOpacity(glowI * 0.55)
          ..maskFilter = MaskFilter.blur(
            BlurStyle.normal,
            size.width * 0.2 * glowI,
          ),
      );
    }

    // --- Sparks ---
    final sparkPhase = _phase(progress, 0.25, 0.8);
    if (sparkPhase > 0 && sparkPhase < 1) {
      _drawSparks(canvas, size, sparkPhase);
    }

    // --- Small secondary bolts ---
    final secPhase = _phase(progress, 0.2, 0.55);
    final secFade = _phase(progress, 0.55, 0.8);
    if (secPhase > 0 && secFade < 1) {
      _drawSecondaryBolts(canvas, size, secPhase, 1.0 - secFade);
    }
  }

  void _drawBolt(Canvas canvas, Size size, double drawProg, double opacity) {
    if (opacity <= 0) return;
    final cx = size.width / 2;
    final startY = -size.height * 0.15;
    final endY = size.height * 0.55;
    final totalLen = endY - startY;

    final path = Path()..moveTo(cx + _rand(seed, 0) * 4 - 2, startY);
    const segments = 7;
    for (var i = 1; i <= segments; i++) {
      final t = i / segments;
      if (t > drawProg) break;
      final y = startY + totalLen * t;
      final xOff =
          (i % 2 == 0 ? 1 : -1) * size.width * 0.14 * sin(i * 2.1 + seed);
      path.lineTo(cx + xOff, y);
    }

    // Outer glow
    canvas.drawPath(
      path,
      Paint()
        ..color = Color.fromRGBO(100, 200, 255, opacity * 0.35)
        ..strokeWidth = 10
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    // Core bolt
    canvas.drawPath(
      path,
      Paint()
        ..color = Color.fromRGBO(230, 245, 255, opacity)
        ..strokeWidth = 2.8
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawSparks(Canvas canvas, Size size, double t) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    const count = 14;
    final fade = _easeOut(1.0 - t);
    for (var i = 0; i < count; i++) {
      final angle = (i / count) * 2 * pi + _rand(seed, i + 10) * pi * 0.5;
      final speed = 0.3 + _rand(seed, i + 50) * 0.7;
      final dist = speed * _easeOut(t) * size.width * 0.55;
      final x = cx + cos(angle) * dist;
      final y = cy + sin(angle) * dist;
      final r = (2.0 + _rand(seed, i + 80) * 1.5) * fade;
      canvas.drawCircle(
        Offset(x, y),
        r,
        Paint()..color = Color.fromRGBO(180, 225, 255, fade * 0.85),
      );
    }
  }

  void _drawSecondaryBolts(
      Canvas canvas, Size size, double prog, double opacity) {
    if (opacity <= 0) return;
    final cx = size.width / 2;
    final cy = size.height / 2;
    for (var b = 0; b < 3; b++) {
      final angle = _rand(seed, b + 200) * 2 * pi;
      final len = size.width * 0.2;
      final path = Path()..moveTo(cx, cy);
      for (var s = 1; s <= 3; s++) {
        final t = s / 3;
        if (t > prog) break;
        final d = len * t;
        final jitter =
            (s % 2 == 0 ? 1 : -1) * size.width * 0.05 * _rand(seed, b * 10 + s);
        final x = cx + cos(angle) * d + cos(angle + pi / 2) * jitter;
        final y = cy + sin(angle) * d + sin(angle + pi / 2) * jitter;
        path.lineTo(x, y);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = Color.fromRGBO(200, 235, 255, opacity * 0.6)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LightningPainter old) =>
      old.progress != progress;
}

// ============================================================
// 2. Bomb Explosion Effect (폭탄 폭발)
// ============================================================

class _BombPainter extends CustomPainter {
  final double progress;
  final int seed;
  _BombPainter({required this.progress, required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // --- Phase 1: Bomb drops in (0 - 0.25) ---
    final dropPhase = _phase(progress, 0.0, 0.25);
    if (dropPhase < 1) {
      _drawBomb(canvas, size, dropPhase);
    }

    // --- Phase 2: Fuse spark (0.2 - 0.35) ---
    final fusePhase = _phase(progress, 0.2, 0.35);
    if (fusePhase > 0 && fusePhase < 1) {
      _drawFuse(canvas, size, fusePhase);
    }

    // --- Phase 3: Explosion flash + ring (0.3 - 0.7) ---
    final explPhase = _phase(progress, 0.3, 0.7);
    if (explPhase > 0 && explPhase < 1) {
      // Flash
      final flashI =
          explPhase < 0.2 ? explPhase / 0.2 : 1.0 - (explPhase - 0.2) / 0.8;
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..color =
              const Color(0xFFFF6B35).withOpacity(flashI.clamp(0.0, 1.0) * 0.6),
      );

      // Expanding ring
      final ringR = _easeOut(explPhase) * size.width * 0.6;
      final ringOpacity = (1.0 - explPhase).clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(cx, cy),
        ringR,
        Paint()
          ..color = Color.fromRGBO(255, 140, 50, ringOpacity * 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0 * (1.0 - explPhase)
          ..maskFilter =
              MaskFilter.blur(BlurStyle.normal, 4 * (1.0 - explPhase)),
      );

      // Core fireball
      final fireR =
          _easeOut(explPhase) * size.width * 0.3 * (1.0 - explPhase * 0.5);
      canvas.drawCircle(
        Offset(cx, cy),
        fireR,
        Paint()
          ..shader = ui.Gradient.radial(
            Offset(cx, cy),
            fireR,
            [
              Color.fromRGBO(255, 255, 200, ringOpacity),
              Color.fromRGBO(255, 120, 30, ringOpacity * 0.6),
              Color.fromRGBO(255, 50, 0, 0),
            ],
            [0.0, 0.5, 1.0],
          ),
      );
    }

    // --- Phase 4: Debris particles (0.35 - 0.85) ---
    final debrisPhase = _phase(progress, 0.35, 0.85);
    if (debrisPhase > 0 && debrisPhase < 1) {
      _drawDebris(canvas, size, debrisPhase);
    }

    // --- Phase 5: Smoke (0.5 - 1.0) ---
    final smokePhase = _phase(progress, 0.5, 1.0);
    if (smokePhase > 0 && smokePhase < 1) {
      _drawSmoke(canvas, size, smokePhase);
    }
  }

  void _drawBomb(Canvas canvas, Size size, double t) {
    final cx = size.width / 2;
    // Bomb drops from above with easeIn bounce
    final dropY = -size.height * 0.3 + size.height * 0.8 * _easeIn(t);
    final bombRadius = size.width * 0.12;

    // Bomb body
    canvas.drawCircle(
      Offset(cx, dropY),
      bombRadius,
      Paint()..color = const Color(0xFF333333),
    );
    // Fuse line
    canvas.drawLine(
      Offset(cx + bombRadius * 0.5, dropY - bombRadius * 0.7),
      Offset(cx + bombRadius * 0.9, dropY - bombRadius * 1.3),
      Paint()
        ..color = const Color(0xFF8B6914)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
    // Highlight
    canvas.drawCircle(
      Offset(cx - bombRadius * 0.3, dropY - bombRadius * 0.3),
      bombRadius * 0.2,
      Paint()..color = const Color(0xFF555555),
    );
  }

  void _drawFuse(Canvas canvas, Size size, double t) {
    final cx = size.width / 2;
    final bombY = size.height * 0.5;
    final bombRadius = size.width * 0.12;
    final fuseX = cx + bombRadius * 0.9;
    final fuseY = bombY - bombRadius * 1.3;
    // Spark
    final sparkSize = 4.0 * (1.0 - t);
    canvas.drawCircle(
      Offset(fuseX, fuseY),
      sparkSize,
      Paint()
        ..color = Color.fromRGBO(255, 220, 50, 1.0 - t)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, sparkSize),
    );
    // Small spark particles
    for (var i = 0; i < 5; i++) {
      final angle = _rand(seed, i + 300) * 2 * pi;
      final dist = t * size.width * 0.08;
      canvas.drawCircle(
        Offset(fuseX + cos(angle) * dist, fuseY + sin(angle) * dist),
        1.5 * (1.0 - t),
        Paint()..color = Color.fromRGBO(255, 200, 50, (1.0 - t) * 0.8),
      );
    }
  }

  void _drawDebris(Canvas canvas, Size size, double t) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    const count = 16;
    final fade = (1.0 - t).clamp(0.0, 1.0);

    for (var i = 0; i < count; i++) {
      final angle = (i / count) * 2 * pi + _rand(seed, i + 400) * 0.8;
      final speed = 0.4 + _rand(seed, i + 450) * 0.6;
      final dist = speed * _easeOut(t) * size.width * 0.55;
      // Gravity effect
      final gravity = t * t * size.height * 0.15;
      final x = cx + cos(angle) * dist;
      final y = cy + sin(angle) * dist + gravity;
      final r = (1.5 + _rand(seed, i + 500) * 2.0) * fade;

      final colorVal = _rand(seed, i + 550);
      final color = colorVal < 0.33
          ? Color.fromRGBO(255, 100, 30, fade * 0.9)
          : colorVal < 0.66
              ? Color.fromRGBO(255, 180, 50, fade * 0.8)
              : Color.fromRGBO(200, 60, 20, fade * 0.7);
      canvas.drawCircle(Offset(x, y), r, Paint()..color = color);
    }
  }

  void _drawSmoke(Canvas canvas, Size size, double t) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    const count = 6;
    final opacity = (1.0 - t) * 0.25;
    if (opacity <= 0) return;

    for (var i = 0; i < count; i++) {
      final angle = _rand(seed, i + 600) * 2 * pi;
      final dist = _easeOut(t) * size.width * 0.25;
      final rise = t * size.height * 0.15;
      final r = (size.width * 0.08 + _rand(seed, i + 650) * size.width * 0.06) *
          _easeOut(t);
      canvas.drawCircle(
        Offset(cx + cos(angle) * dist, cy + sin(angle) * dist - rise),
        r,
        Paint()
          ..color = Color.fromRGBO(100, 100, 100, opacity)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.6),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BombPainter old) => old.progress != progress;
}

// ============================================================
// 3. Hurricane Effect (허리케인)
// ============================================================

class _HurricanePainter extends CustomPainter {
  final double progress;
  final int seed;
  _HurricanePainter({required this.progress, required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // --- Background tint ---
    final tintIn = _phase(progress, 0.0, 0.2);
    final tintOut = _phase(progress, 0.7, 1.0);
    final tint = (tintIn - tintOut).clamp(0.0, 1.0) * 0.35;
    if (tint > 0) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = Color.fromRGBO(0, 206, 209, tint),
      );
    }

    // --- Spiral particles ---
    final spiralPhase = _phase(progress, 0.0, 0.85);
    final fadeOut = _phase(progress, 0.7, 1.0);
    if (spiralPhase > 0) {
      _drawSpiralParticles(canvas, size, spiralPhase, 1.0 - fadeOut);
    }

    // --- Wind arcs ---
    final windPhase = _phase(progress, 0.05, 0.8);
    final windFade = _phase(progress, 0.65, 0.9);
    if (windPhase > 0 && windFade < 1) {
      _drawWindArcs(canvas, size, windPhase, 1.0 - windFade);
    }

    // --- Center vortex ---
    final vortexIn = _phase(progress, 0.2, 0.5);
    final vortexOut = _phase(progress, 0.6, 0.9);
    final vortexI = (_easeOut(vortexIn) - vortexOut).clamp(0.0, 1.0);
    if (vortexI > 0) {
      canvas.drawCircle(
        Offset(cx, cy),
        size.width * 0.12 * vortexI,
        Paint()
          ..color = Color.fromRGBO(0, 230, 230, vortexI * 0.4)
          ..maskFilter = MaskFilter.blur(
            BlurStyle.normal,
            size.width * 0.08 * vortexI,
          ),
      );
    }
  }

  void _drawSpiralParticles(
      Canvas canvas, Size size, double t, double opacity) {
    if (opacity <= 0) return;
    final cx = size.width / 2;
    final cy = size.height / 2;
    const count = 20;
    // Rotation speed increases over time
    final rotation = t * pi * 6;

    for (var i = 0; i < count; i++) {
      final baseAngle = (i / count) * 2 * pi;
      final angle = baseAngle + rotation + _rand(seed, i + 100) * 0.5;
      // Spiral inward: radius decreases as t increases
      final maxR = size.width * (0.45 - _rand(seed, i + 150) * 0.1);
      final radius = maxR * (1.0 - t * 0.6);
      final x = cx + cos(angle) * radius;
      final y = cy + sin(angle) * radius;
      final particleSize = (1.5 + _rand(seed, i + 200) * 1.5) * opacity;

      final hue = 170 + _rand(seed, i + 250) * 30; // Cyan-teal range
      canvas.drawCircle(
        Offset(x, y),
        particleSize,
        Paint()
          ..color = HSVColor.fromAHSV(opacity * 0.85, hue, 0.7, 1.0).toColor(),
      );
    }
  }

  void _drawWindArcs(Canvas canvas, Size size, double t, double opacity) {
    if (opacity <= 0) return;
    final cx = size.width / 2;
    final cy = size.height / 2;
    const count = 5;
    final rotation = t * pi * 4;

    for (var i = 0; i < count; i++) {
      final baseAngle = (i / count) * 2 * pi + rotation;
      final r = size.width * (0.2 + _rand(seed, i + 300) * 0.15);
      final sweepAngle = pi * 0.5 + _rand(seed, i + 350) * pi * 0.3;

      final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);
      canvas.drawArc(
        rect,
        baseAngle,
        sweepAngle,
        false,
        Paint()
          ..color = Color.fromRGBO(100, 230, 230, opacity * 0.5)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HurricanePainter old) =>
      old.progress != progress;
}

// ============================================================
// 4. Hammer Effect (망치 타격)
// ============================================================

class _HammerPainter extends CustomPainter {
  final double progress;
  final int seed;
  _HammerPainter({required this.progress, required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // --- Phase 1: Hammer appears & swings (0 - 0.45) ---
    final swingPhase = _phase(progress, 0.0, 0.45);
    if (swingPhase > 0 && swingPhase <= 1) {
      _drawHammer(canvas, size, swingPhase);
    }

    // --- Phase 2: Impact flash (0.4 - 0.65) ---
    final impactIn = _phase(progress, 0.4, 0.5);
    final impactOut = _phase(progress, 0.5, 0.7);
    final impactI = (_easeOut(impactIn) - impactOut).clamp(0.0, 1.0);
    if (impactI > 0) {
      // White flash
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = Color.fromRGBO(255, 255, 230, impactI * 0.65),
      );

      // Impact star burst
      _drawImpactStar(
          canvas, Offset(cx, cy), size.width * 0.3 * impactI, impactI);
    }

    // --- Phase 3: Impact sparks (0.45 - 0.85) ---
    final sparkPhase = _phase(progress, 0.45, 0.85);
    if (sparkPhase > 0 && sparkPhase < 1) {
      _drawImpactSparks(canvas, size, sparkPhase);
    }

    // --- Phase 4: Shockwave ring (0.4 - 0.8) ---
    final shockPhase = _phase(progress, 0.4, 0.8);
    if (shockPhase > 0 && shockPhase < 1) {
      final ringR = _easeOut(shockPhase) * size.width * 0.5;
      final ringO = (1.0 - shockPhase).clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(cx, cy),
        ringR,
        Paint()
          ..color = Color.fromRGBO(200, 200, 200, ringO * 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0 * (1.0 - shockPhase),
      );
    }
  }

  void _drawHammer(Canvas canvas, Size size, double t) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    canvas.save();
    canvas.translate(cx, cy);

    // Swing angle: starts from top-right, swings to center
    // t=0 -> -90deg (hammer up), t=1 -> 0deg (hammer down)
    final swingAngle = -pi / 2 * (1.0 - _easeIn(t));
    canvas.rotate(swingAngle);

    final headW = size.width * 0.25;
    final headH = size.height * 0.12;
    final handleLen = size.height * 0.35;
    final handleW = size.width * 0.06;

    // Handle
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(0, -handleLen / 2),
          width: handleW,
          height: handleLen,
        ),
        Radius.circular(handleW / 2),
      ),
      Paint()..color = const Color(0xFF8B6914),
    );

    // Hammer head
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(0, -handleLen + headH / 2),
          width: headW,
          height: headH,
        ),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFF888888),
    );
    // Head highlight
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(0, -handleLen + headH * 0.3),
          width: headW * 0.8,
          height: headH * 0.3,
        ),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFFAAAAAA),
    );

    canvas.restore();
  }

  void _drawImpactStar(
      Canvas canvas, Offset center, double radius, double opacity) {
    if (opacity <= 0 || radius <= 0) return;
    const rays = 8;
    final path = Path();
    for (var i = 0; i < rays; i++) {
      final angle = (i / rays) * 2 * pi - pi / 2;
      final outerX = center.dx + cos(angle) * radius;
      final outerY = center.dy + sin(angle) * radius;
      final innerR = radius * 0.3;
      final midAngle = angle + pi / rays;
      final innerX = center.dx + cos(midAngle) * innerR;
      final innerY = center.dy + sin(midAngle) * innerR;
      if (i == 0) {
        path.moveTo(outerX, outerY);
      } else {
        path.lineTo(outerX, outerY);
      }
      path.lineTo(innerX, innerY);
    }
    path.close();
    canvas.drawPath(
      path,
      Paint()
        ..color = Color.fromRGBO(255, 255, 200, opacity * 0.7)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.15),
    );
  }

  void _drawImpactSparks(Canvas canvas, Size size, double t) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    const count = 12;
    final fade = (1.0 - t).clamp(0.0, 1.0);

    for (var i = 0; i < count; i++) {
      final angle = (i / count) * 2 * pi + _rand(seed, i + 700);
      final speed = 0.4 + _rand(seed, i + 750) * 0.6;
      final dist = speed * _easeOut(t) * size.width * 0.5;
      final gravity = t * t * size.height * 0.1;
      final x = cx + cos(angle) * dist;
      final y = cy + sin(angle) * dist + gravity;
      final r = (1.5 + _rand(seed, i + 800) * 1.5) * fade;

      canvas.drawCircle(
        Offset(x, y),
        r,
        Paint()..color = Color.fromRGBO(255, 220, 150, fade * 0.8),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HammerPainter old) => old.progress != progress;
}

// ============================================================
// 5. Fire Effect (불꽃) — Bonus
// ============================================================

class _FirePainter extends CustomPainter {
  final double progress;
  final int seed;
  _FirePainter({required this.progress, required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // --- Background warm glow ---
    final glowIn = _phase(progress, 0.05, 0.25);
    final glowOut = _phase(progress, 0.65, 1.0);
    final glowI = (glowIn - glowOut).clamp(0.0, 1.0);
    if (glowI > 0) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = Color.fromRGBO(255, 80, 0, glowI * 0.3),
      );
    }

    // --- Flame particles ---
    final flamePhase = _phase(progress, 0.0, 0.85);
    final flameFade = _phase(progress, 0.7, 1.0);
    if (flamePhase > 0) {
      _drawFlames(canvas, size, flamePhase, 1.0 - flameFade);
    }

    // --- Core fire ---
    final coreIn = _phase(progress, 0.1, 0.35);
    final coreOut = _phase(progress, 0.6, 0.9);
    final coreI = (_easeOut(coreIn) - coreOut).clamp(0.0, 1.0);
    if (coreI > 0) {
      final coreR = size.width * 0.2 * coreI;
      canvas.drawCircle(
        Offset(cx, cy + size.height * 0.05),
        coreR,
        Paint()
          ..shader = ui.Gradient.radial(
            Offset(cx, cy + size.height * 0.05),
            coreR,
            [
              Color.fromRGBO(255, 255, 180, coreI),
              Color.fromRGBO(255, 150, 30, coreI * 0.7),
              Color.fromRGBO(255, 50, 0, 0),
            ],
            [0.0, 0.5, 1.0],
          ),
      );
    }

    // --- Rising sparks ---
    final sparkPhase = _phase(progress, 0.15, 0.9);
    if (sparkPhase > 0 && sparkPhase < 1) {
      _drawRisingSparks(canvas, size, sparkPhase);
    }
  }

  void _drawFlames(Canvas canvas, Size size, double t, double opacity) {
    if (opacity <= 0) return;
    final cx = size.width / 2;
    const count = 18;

    for (var i = 0; i < count; i++) {
      // Each flame particle has its own timing offset
      final offset = _rand(seed, i + 900) * 0.3;
      final localT = ((t - offset) / (1.0 - offset)).clamp(0.0, 1.0);
      if (localT <= 0) continue;

      final xSpread = (i / count - 0.5) * size.width * 0.8;
      final jitter = (_rand(seed, i + 950) - 0.5) * size.width * 0.15;
      final x = cx + xSpread + jitter;
      // Rise from bottom
      final startY = size.height * 1.1;
      final endY = size.height * (-0.1 - _rand(seed, i + 1000) * 0.2);
      final y = startY + (endY - startY) * _easeOut(localT);
      final r =
          (2.0 + _rand(seed, i + 1050) * 3.0) * opacity * (1.0 - localT * 0.5);

      // Color: yellow at start, orange, red at end
      final colorT = localT;
      final red = 255;
      final green = (255 - colorT * 180).round().clamp(50, 255);
      final blue = (80 - colorT * 80).round().clamp(0, 80);
      canvas.drawCircle(
        Offset(x, y),
        r,
        Paint()
          ..color =
              Color.fromRGBO(red, green, blue, opacity * (1.0 - localT * 0.3))
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.5),
      );
    }
  }

  void _drawRisingSparks(Canvas canvas, Size size, double t) {
    final cx = size.width / 2;
    const count = 8;
    final fade = (1.0 - t).clamp(0.0, 1.0);

    for (var i = 0; i < count; i++) {
      final xOff = (_rand(seed, i + 1100) - 0.5) * size.width * 0.6;
      final speed = 0.5 + _rand(seed, i + 1150) * 0.5;
      final y = size.height * (1.0 - speed * _easeOut(t) * 1.4);
      final x = cx + xOff + sin(t * pi * 4 + i) * size.width * 0.05;
      final r = 1.5 * fade;

      canvas.drawCircle(
        Offset(x, y),
        r,
        Paint()..color = Color.fromRGBO(255, 240, 100, fade * 0.9),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FirePainter old) => old.progress != progress;
}

// ============================================================
// 6. Magic Sparkle Effect (마법 반짝임) — Bonus
// ============================================================

class _MagicSparklePainter extends CustomPainter {
  final double progress;
  final int seed;
  _MagicSparklePainter({required this.progress, required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // --- Background magic glow ---
    final glowIn = _phase(progress, 0.0, 0.25);
    final glowOut = _phase(progress, 0.7, 1.0);
    final glowI = (glowIn - glowOut).clamp(0.0, 1.0);
    if (glowI > 0) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = Color.fromRGBO(130, 50, 220, glowI * 0.2),
      );
    }

    // --- Orbiting stars ---
    final orbitPhase = _phase(progress, 0.0, 0.75);
    final orbitFade = _phase(progress, 0.65, 0.9);
    if (orbitPhase > 0) {
      _drawOrbitingStars(canvas, size, orbitPhase, 1.0 - orbitFade);
    }

    // --- Magic dust trail ---
    final dustPhase = _phase(progress, 0.1, 0.8);
    final dustFade = _phase(progress, 0.7, 1.0);
    if (dustPhase > 0) {
      _drawMagicDust(canvas, size, dustPhase, 1.0 - dustFade);
    }

    // --- Center convergence flash ---
    final flashIn = _phase(progress, 0.55, 0.7);
    final flashOut = _phase(progress, 0.7, 0.95);
    final flashI = (_easeOut(flashIn) - flashOut).clamp(0.0, 1.0);
    if (flashI > 0) {
      canvas.drawCircle(
        Offset(cx, cy),
        size.width * 0.25 * flashI,
        Paint()
          ..color = Color.fromRGBO(220, 180, 255, flashI * 0.6)
          ..maskFilter = MaskFilter.blur(
            BlurStyle.normal,
            size.width * 0.15 * flashI,
          ),
      );
      // Gold sparkle at center
      _drawStar(canvas, Offset(cx, cy), size.width * 0.08 * flashI,
          Color.fromRGBO(255, 215, 0, flashI));
    }
  }

  void _drawOrbitingStars(Canvas canvas, Size size, double t, double opacity) {
    if (opacity <= 0) return;
    final cx = size.width / 2;
    final cy = size.height / 2;
    const count = 8;
    final rotation = t * pi * 5;
    // Stars converge to center over time
    final convergence = t > 0.7 ? (t - 0.7) / 0.3 : 0.0;

    for (var i = 0; i < count; i++) {
      final baseAngle = (i / count) * 2 * pi;
      final angle = baseAngle + rotation + _rand(seed, i + 1200) * 0.3;
      final maxR = size.width * (0.3 + _rand(seed, i + 1250) * 0.1);
      final radius = maxR * (1.0 - convergence * 0.8);
      final x = cx + cos(angle) * radius;
      final y = cy + sin(angle) * radius;

      // Twinkle: scale pulsates
      final twinkle = 0.5 + 0.5 * sin(t * pi * 8 + i * pi * 0.5);
      final starSize =
          (size.width * 0.04 + _rand(seed, i + 1300) * size.width * 0.02) *
              twinkle *
              opacity;

      // Alternate gold and purple
      final color = i % 2 == 0
          ? Color.fromRGBO(255, 215, 0, opacity * 0.9)
          : Color.fromRGBO(180, 100, 255, opacity * 0.9);

      _drawStar(canvas, Offset(x, y), starSize, color);
    }
  }

  void _drawMagicDust(Canvas canvas, Size size, double t, double opacity) {
    if (opacity <= 0) return;
    final cx = size.width / 2;
    final cy = size.height / 2;
    const count = 15;
    final rotation = t * pi * 3;

    for (var i = 0; i < count; i++) {
      final angle = (i / count) * 2 * pi + rotation;
      final r = size.width * (0.15 + _rand(seed, i + 1400) * 0.2);
      final x = cx + cos(angle) * r;
      final y = cy + sin(angle) * r;
      final dotR = 1.2 * opacity;

      final hue = 270 + _rand(seed, i + 1450) * 60; // Purple-pink range
      canvas.drawCircle(
        Offset(x, y),
        dotR,
        Paint()
          ..color =
              HSVColor.fromAHSV(opacity * 0.6, hue % 360, 0.6, 1.0).toColor(),
      );
    }
  }

  /// Draws a 4-pointed star shape.
  void _drawStar(Canvas canvas, Offset center, double radius, Color color) {
    if (radius <= 0) return;
    const points = 4;
    final path = Path();
    for (var i = 0; i < points * 2; i++) {
      final angle = (i / (points * 2)) * 2 * pi - pi / 2;
      final r = i.isEven ? radius : radius * 0.35;
      final x = center.dx + cos(angle) * r;
      final y = center.dy + sin(angle) * r;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
    // Soft glow
    canvas.drawCircle(
      center,
      radius * 0.6,
      Paint()
        ..color = color.withOpacity(color.opacity * 0.3)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.4),
    );
  }

  @override
  bool shouldRepaint(covariant _MagicSparklePainter old) =>
      old.progress != progress;
}
