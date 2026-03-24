import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../game/game_engine.dart';
import '../game/game_map.dart';
import '../game/player.dart';

class GameRenderer extends CustomPainter {
  final GameEngine engine;
  final double time;

  GameRenderer({required this.engine, required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    final player = engine.player;
    final map = engine.currentMap;
    final levelIdx = map.index.clamp(0, JKColors.skyColors.length - 1);

    double camY = player.centerY - size.height * 0.5;
    camY = camY.clamp(0, (map.pixelHeight - size.height).clamp(0, double.infinity));

    // ── Sky gradient background ──────────────────────────────────
    _drawSkyGradient(canvas, size, levelIdx);

    // ── Background atmosphere (stars/clouds/mist) ────────────────
    _drawAtmosphere(canvas, size, camY, levelIdx, time);

    canvas.save();
    canvas.translate(0, -camY);

    // ── Tiles ────────────────────────────────────────────────────
    double ts = JKConstants.tileSize;
    int startRow = (camY / ts).floor() - 1;
    int endRow = ((camY + size.height) / ts).floor() + 2;
    startRow = startRow.clamp(0, map.height - 1);
    endRow = endRow.clamp(0, map.height - 1);

    for (int row = startRow; row <= endRow; row++) {
      for (int col = 0; col < map.width; col++) {
        TileType tile = map.getTile(col, row);
        if (tile == TileType.empty) continue;
        Rect tileRect = Rect.fromLTWH(col * ts, row * ts, ts, ts);
        _drawTile(canvas, tileRect, tile, levelIdx, col, row, map, time);
      }
    }

    // ── Tile top-edge shadow pass ────────────────────────────────
    for (int row = startRow; row <= endRow; row++) {
      for (int col = 0; col < map.width; col++) {
        TileType tile = map.getTile(col, row);
        if (tile != TileType.solid && tile != TileType.ice && tile != TileType.crumble) continue;
        // Only draw shadow under empty tile above
        if (row > 0 && map.getTile(col, row - 1) == TileType.empty) {
          double ts2 = JKConstants.tileSize;
          Rect r = Rect.fromLTWH(col * ts2, row * ts2, ts2, ts2);
          _drawTileTopHighlight(canvas, r, levelIdx);
        }
      }
    }

    // ── Particles ────────────────────────────────────────────────
    for (var p in engine.particles) {
      _drawParticle(canvas, p);
    }

    // ── Player shadow ────────────────────────────────────────────
    _drawPlayerShadow(canvas, player);

    // ── Player ───────────────────────────────────────────────────
    _drawPlayer(canvas, player, time);

    // ── Charge arrow ─────────────────────────────────────────────
    if (player.isCharging) {
      _drawChargeArrow(canvas, player);
    }

    canvas.restore();

    // ── Vignette ─────────────────────────────────────────────────
    _drawVignette(canvas, size);

    // ── Hurt flash ───────────────────────────────────────────────
    if (player.isHurt) {
      double a = (player.hurtTimer / 1.5 * 0.45).clamp(0, 0.45);
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
          Paint()..color = Colors.red.withOpacity(a));
    }

    if (engine.checkpointFlash) {
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
          Paint()..color = JKColors.victoryGlow.withOpacity(0.14));
    }
  }

  // ── Sky gradient ───────────────────────────────────────────────────────────

  void _drawSkyGradient(Canvas canvas, Size size, int levelIdx) {
    final List<List<Color>> skyGradients = [
      [const Color(0xFF0D0D1F), const Color(0xFF1A1A3E), const Color(0xFF2D1B4E)],
      [const Color(0xFF051525), const Color(0xFF0D2137), const Color(0xFF163050)],
      [const Color(0xFF0A1A14), const Color(0xFF162032), const Color(0xFF1E3040)],
      [const Color(0xFF1A0800), const Color(0xFF2D0F00), const Color(0xFF3D1500)],
      [const Color(0xFF050508), const Color(0xFF0A0A12), const Color(0xFF101018)],
    ];
    final colors = skyGradients[levelIdx.clamp(0, skyGradients.length - 1)];
    final grad = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: colors,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..shader = grad.createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
  }

  // ── Atmosphere ────────────────────────────────────────────────────────────

  void _drawAtmosphere(Canvas canvas, Size size, double camY, int levelIdx, double time) {
    final rng = Random(levelIdx * 7777);
    final paint = Paint();

    // Stars for dark levels
    if (levelIdx != 2) {
      for (int i = 0; i < 60; i++) {
        double sx = rng.nextDouble() * size.width;
        double sy = rng.nextDouble() * size.height;
        double parallaxY = (sy - camY * 0.15) % size.height;
        if (parallaxY < 0) parallaxY += size.height;
        double twinkle = 0.4 + 0.6 * sin(time * 1.8 + i * 0.7).abs();
        double starSize = 0.8 + rng.nextDouble() * 1.8;
        paint.color = Colors.white.withOpacity(0.07 + 0.12 * twinkle);
        canvas.drawCircle(Offset(sx, parallaxY), starSize, paint);
      }
    }

    // Level-specific BG elements
    if (levelIdx == 0) {
      // Dungeon: floating dust motes
      for (int i = 0; i < 12; i++) {
        double mx = rng.nextDouble() * size.width;
        double my = (rng.nextDouble() * size.height * 2 - camY * 0.3 + time * 15 * (0.3 + rng.nextDouble())) % size.height;
        if (my < 0) my += size.height;
        paint.color = Colors.amber.withOpacity(0.04 + 0.03 * sin(time + i));
        canvas.drawCircle(Offset(mx, my), 2 + rng.nextDouble() * 3, paint);
      }
    } else if (levelIdx == 3) {
      // Volcano: embers rising
      for (int i = 0; i < 10; i++) {
        double ex = (rng.nextDouble() * size.width + sin(time * 0.7 + i) * 20);
        double ey = (size.height - (time * 30 * (0.5 + rng.nextDouble() * 0.8) + i * 70) % (size.height + 100));
        paint.color = Colors.deepOrange.withOpacity(0.3 * sin(time * 2 + i).abs().clamp(0.1, 1.0));
        canvas.drawCircle(Offset(ex, ey), 1.5 + rng.nextDouble() * 2, paint);
      }
    } else if (levelIdx == 4) {
      // Summit: snow flakes
      for (int i = 0; i < 20; i++) {
        double flakeX = (rng.nextDouble() * size.width + sin(time * 0.5 + i) * 15) % size.width;
        double flakeY = (time * 25 * (0.4 + rng.nextDouble() * 0.6) + i * 37) % (size.height + 50) - 25;
        paint.color = Colors.white.withOpacity(0.25 * sin(time + i * 1.3).abs().clamp(0.1, 1.0));
        canvas.drawCircle(Offset(flakeX, flakeY), 1 + rng.nextDouble(), paint);
      }
    }
  }

  // ── Vignette ──────────────────────────────────────────────────────────────

  void _drawVignette(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.85,
        colors: [Colors.transparent, Colors.black.withOpacity(0.55)],
      ).createShader(rect);
    canvas.drawRect(rect, paint);
  }

  // ── Tile top highlight ────────────────────────────────────────────────────

  void _drawTileTopHighlight(Canvas canvas, Rect r, int levelIdx) {
    final color = JKColors.platformColors[levelIdx].withOpacity(0.7);
    final paint = Paint()..color = color;
    canvas.drawRect(Rect.fromLTWH(r.left, r.top, r.width, 3), paint);
  }

  // ── Tile drawing ──────────────────────────────────────────────────────────

  void _drawTile(Canvas canvas, Rect r, TileType type, int levelIdx,
      int col, int row, GameMap map, double time) {
    final paint = Paint();
    double ts = JKConstants.tileSize;

    switch (type) {
      case TileType.solid:
        // Base gradient
        final gradient = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            JKColors.platformColors[levelIdx],
            JKColors.terrainColors[levelIdx],
            JKColors.terrainDarkColors[levelIdx],
          ],
        );
        paint.shader = gradient.createShader(r);
        canvas.drawRect(r, paint);
        paint.shader = null;

        // Subtle inner texture
        paint.color = Colors.black.withOpacity(0.12);
        // Horizontal mortar line
        if (row % 2 == 0) {
          canvas.drawRect(Rect.fromLTWH(r.left, r.top + ts * 0.5, r.width, 1), paint);
        }
        // Vertical mortar line (checkerboard)
        if ((col + row) % 2 == 0) {
          canvas.drawRect(Rect.fromLTWH(r.left + ts * 0.5, r.top, 1, r.height), paint);
        }

        // Right edge shadow
        paint.color = Colors.black.withOpacity(0.25);
        canvas.drawRect(Rect.fromLTWH(r.right - 3, r.top, 3, r.height), paint);
        // Bottom shadow
        canvas.drawRect(Rect.fromLTWH(r.left, r.bottom - 3, r.width, 3), paint);
        break;

      case TileType.platform:
        // Plank shape with wood look
        final plankRect = Rect.fromLTWH(r.left + 1, r.top, r.width - 2, 12);
        final woodGrad = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            JKColors.platformColors[levelIdx].withOpacity(0.95),
            JKColors.terrainDarkColors[levelIdx],
          ],
        );
        paint.shader = woodGrad.createShader(plankRect);
        canvas.drawRRect(RRect.fromRectAndRadius(plankRect, const Radius.circular(2)), paint);
        paint.shader = null;

        // Top shine
        paint.color = Colors.white.withOpacity(0.22);
        canvas.drawRect(Rect.fromLTWH(r.left + 2, r.top, r.width - 4, 2), paint);
        // Wood grain lines
        paint.color = Colors.black.withOpacity(0.1);
        paint.style = PaintingStyle.stroke;
        paint.strokeWidth = 1;
        canvas.drawLine(Offset(r.left + 6, r.top + 3), Offset(r.left + 6, r.top + 9), paint);
        canvas.drawLine(Offset(r.left + r.width / 2, r.top + 2), Offset(r.left + r.width / 2, r.top + 10), paint);
        canvas.drawLine(Offset(r.right - 7, r.top + 3), Offset(r.right - 7, r.top + 9), paint);
        paint.style = PaintingStyle.fill;
        // Peg bolts
        paint.color = JKColors.terrainDarkColors[levelIdx];
        canvas.drawCircle(Offset(r.left + 5, r.top + 5), 2.5, paint);
        canvas.drawCircle(Offset(r.right - 5, r.top + 5), 2.5, paint);
        break;

      case TileType.ice:
        // Ice base with deep blue gradient
        final iceGrad = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFFB3E5FC), JKColors.iceBlueDark, const Color(0xFF01579B)],
        );
        paint.shader = iceGrad.createShader(r);
        canvas.drawRect(r, paint);
        paint.shader = null;

        // Frosted texture overlay
        paint.color = Colors.white.withOpacity(0.12);
        canvas.drawRect(r, paint);

        // Glint lines
        paint.color = Colors.white.withOpacity(0.55 + 0.3 * sin(time * 2.5 + col * 0.7));
        paint.style = PaintingStyle.stroke;
        paint.strokeWidth = 1.2;
        canvas.drawLine(Offset(r.left + 5, r.top + 4), Offset(r.left + 14, r.top + 4), paint);
        canvas.drawLine(Offset(r.right - 10, r.top + 7), Offset(r.right - 4, r.top + 7), paint);
        paint.style = PaintingStyle.fill;

        // Top gloss
        paint.color = Colors.white.withOpacity(0.28);
        canvas.drawRect(Rect.fromLTWH(r.left, r.top, r.width, 4), paint);
        break;

      case TileType.crumble:
        double frac = map.getCrumbleFraction(col, row);
        double shakeX = frac > 0.3 ? sin(time * 35) * 2.5 * frac : 0;
        double shakeY = frac > 0.5 ? cos(time * 30) * 1.5 * frac : 0;
        Rect cr = r.translate(shakeX, shakeY);

        final crGrad = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            JKColors.crumbleColor.withOpacity(1.0 - frac * 0.4),
            JKColors.crumbleDark.withOpacity(1.0 - frac * 0.4),
          ],
        );
        paint.shader = crGrad.createShader(cr);
        canvas.drawRect(cr, paint);
        paint.shader = null;

        // Top highlight
        paint.color = Colors.orange.withOpacity(0.4 * (1 - frac));
        canvas.drawRect(Rect.fromLTWH(cr.left, cr.top, cr.width, 4), paint);

        if (frac > 0.15) {
          paint.color = Colors.black.withOpacity(frac * 0.9);
          paint.style = PaintingStyle.stroke;
          paint.strokeWidth = 1.8;
          paint.strokeCap = StrokeCap.round;
          canvas.drawLine(Offset(cr.left + 7, cr.top + 2), Offset(cr.left + 18, cr.bottom - 5), paint);
          canvas.drawLine(Offset(cr.right - 9, cr.top + 4), Offset(cr.right - 20, cr.bottom - 3), paint);
          if (frac > 0.45) {
            canvas.drawLine(Offset(cr.left + 15, cr.top + 3), Offset(cr.left + 9, cr.top + 10), paint);
          }
          paint.style = PaintingStyle.fill;
        }
        break;

      case TileType.spike:
        // Ground base
        paint.color = JKColors.terrainDarkColors[levelIdx].withOpacity(0.6);
        canvas.drawRect(Rect.fromLTWH(r.left, r.bottom - 5, r.width, 5), paint);

        int spikeCount = 3;
        double sw = r.width / spikeCount;
        for (int i = 0; i < spikeCount; i++) {
          double sx = r.left + i * sw;
          double tipX = sx + sw / 2;
          double tipY = r.top + 4;

          // Spike gradient
          final spikeGrad = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [const Color(0xFFE8E8E8), const Color(0xFF9E9E9E), const Color(0xFF616161)],
          );
          Path spike = Path();
          spike.moveTo(sx + 2, r.bottom - 4);
          spike.lineTo(tipX, tipY);
          spike.lineTo(sx + sw - 2, r.bottom - 4);
          spike.close();
          paint.shader = spikeGrad.createShader(Rect.fromLTWH(sx, tipY, sw, r.height - 4));
          canvas.drawPath(spike, paint);
          paint.shader = null;

          // Shine
          paint.color = Colors.white.withOpacity(0.7);
          paint.style = PaintingStyle.stroke;
          paint.strokeWidth = 1;
          canvas.drawLine(Offset(tipX, tipY), Offset(tipX - sw * 0.15, r.bottom - 6), paint);
          paint.style = PaintingStyle.fill;
        }
        break;

      case TileType.checkpoint:
        // Pole
        paint.color = const Color(0xFFBDBDBD);
        canvas.drawRect(Rect.fromLTWH(r.left + r.width / 2 - 1.5, r.top + 3, 3, r.height - 5), paint);

        // Flag body with wave
        double wave = sin(time * 4) * 4;
        Path flag = Path();
        double fx = r.left + r.width / 2 + 1;
        flag.moveTo(fx, r.top + 4);
        flag.quadraticBezierTo(fx + 10 + wave, r.top + 9, fx + 14 + wave, r.top + 12);
        flag.quadraticBezierTo(fx + 10 + wave, r.top + 15, fx, r.top + 20);
        flag.close();

        // Alternating color flag
        paint.color = const Color(0xFFFFEB3B);
        canvas.drawPath(flag, paint);
        paint.color = const Color(0xFFFFA000);
        paint.style = PaintingStyle.stroke;
        paint.strokeWidth = 1;
        canvas.drawPath(flag, paint);
        paint.style = PaintingStyle.fill;

        // Star on flag
        paint.color = Colors.white.withOpacity(0.8);
        canvas.drawCircle(Offset(fx + 7 + wave * 0.5, r.top + 12), 2.5, paint);
        break;

      case TileType.goal:
        double glow = 0.55 + 0.45 * sin(time * 2.5);
        // Pulsing portal background
        final portalGrad = RadialGradient(
          center: Alignment.center,
          colors: [
            const Color(0xFFFFD700).withOpacity(glow),
            const Color(0xFFFF8F00).withOpacity(glow * 0.6),
            Colors.transparent,
          ],
        );
        paint.shader = portalGrad.createShader(r);
        canvas.drawRect(r.inflate(8), paint);
        paint.shader = null;

        // Crown
        paint.color = JKColors.menuTitle;
        Path crown = Path();
        double cx = r.left + r.width / 2;
        double cy = r.top + r.height / 2 + 2;
        crown.moveTo(cx - 14, cy + 8);
        crown.lineTo(cx - 14, cy - 4);
        crown.lineTo(cx - 7, cy - 12);
        crown.lineTo(cx, cy - 5);
        crown.lineTo(cx + 7, cy - 12);
        crown.lineTo(cx + 14, cy - 4);
        crown.lineTo(cx + 14, cy + 8);
        crown.close();
        canvas.drawPath(crown, paint);

        // Crown jewels
        final jewels = [Colors.red, Colors.cyanAccent, Colors.green];
        for (int j = 0; j < 3; j++) {
          paint.color = jewels[j].withOpacity(0.7 + 0.3 * sin(time * 3 + j));
          canvas.drawCircle(Offset(cx - 9 + j * 9.0, cy + 4), 3, paint);
        }
        break;

      case TileType.wind:
        double alpha = 0.2 + 0.15 * sin(time * 5 + col);
        paint.color = Colors.cyan.withOpacity(alpha * 0.5);
        canvas.drawRect(r, paint);

        paint.color = Colors.cyanAccent.withOpacity(0.35);
        paint.style = PaintingStyle.stroke;
        paint.strokeWidth = 1.3;
        paint.strokeCap = StrokeCap.round;

        double force = 0;
        for (var zone in map.windZones) {
          double zoneCol = zone.x / ts;
          if (col >= zoneCol && col < zoneCol + zone.w / ts) force = zone.force;
        }
        double dir = force >= 0 ? 1 : -1;
        double offset = (time * 50) % 24;
        for (double ax = r.left + offset * dir; ax > r.left - 24 && ax < r.right + 24; ax += 24 * dir) {
          double midY = r.top + r.height * 0.5;
          canvas.drawLine(Offset(ax, midY - 3), Offset(ax + 12 * dir, midY), paint);
          canvas.drawLine(Offset(ax + 12 * dir, midY), Offset(ax, midY + 3), paint);
        }
        paint.style = PaintingStyle.fill;
        break;

      default:
        break;
    }
  }

  // ── Player shadow ─────────────────────────────────────────────────────────

  void _drawPlayerShadow(Canvas canvas, Player player) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(player.centerX, player.y + player.height + 2),
        width: player.width * 0.85,
        height: 6,
      ),
      paint,
    );
  }

  // ── Player drawing ────────────────────────────────────────────────────────

  void _drawPlayer(Canvas canvas, Player player, double time) {
    double px = player.x;
    double py = player.y;
    double pw = player.width;
    double ph = player.height;
    bool faceRight = player.facingRight;

    double scaleY = 1.0, scaleX = 1.0, crouchY = 0;

    if (player.state == PlayerState.landing && player.landingTimer > 0) {
      double t = player.landingTimer / 0.12;
      scaleY = 1.0 - 0.28 * t;
      scaleX = 1.0 + 0.18 * t;
    }
    if (player.isCharging) {
      crouchY = player.chargeFraction * 7;
      scaleY = 1.0 - player.chargeFraction * 0.18;
    }

    if (player.isHurt && (player.hurtTimer * 9).floor().isOdd) return;

    canvas.save();
    canvas.translate(px + pw / 2, py + ph / 2 + crouchY / 2);
    canvas.scale(faceRight ? scaleX : -scaleX, scaleY);

    final p = Paint();
    double hTop = -ph / 2 + crouchY;

    // ── Cape ─────────────────────────────────────────────────────
    double capeWave = sin(time * 5) * 3.5;
    p.color = const Color(0xFF7B1FA2);
    Path cape = Path();
    cape.moveTo(-pw / 2 + 3, hTop + 8);
    cape.quadraticBezierTo(-pw / 2 - 7 + capeWave, 2, -pw / 2 - 5 + capeWave, ph / 2 - 4);
    cape.lineTo(-pw / 2 + 3, ph / 2 - 10);
    cape.close();
    canvas.drawPath(cape, p);

    // Cape highlight
    p.color = const Color(0xFFAB47BC).withOpacity(0.5);
    Path capeShine = Path();
    capeShine.moveTo(-pw / 2 + 3, hTop + 8);
    capeShine.quadraticBezierTo(-pw / 2 - 3 + capeWave, 0, -pw / 2 - 2 + capeWave, ph / 4);
    capeShine.lineTo(-pw / 2 + 1, ph / 4);
    capeShine.close();
    canvas.drawPath(capeShine, p);

    // ── Body ─────────────────────────────────────────────────────
    final bodyGrad = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [const Color(0xFF388E3C), const Color(0xFF4CAF50), const Color(0xFF2E7D32)],
    );
    Rect bodyRect = Rect.fromCenter(center: Offset(0, crouchY / 2), width: pw - 4, height: ph - 12);
    p.shader = bodyGrad.createShader(bodyRect);
    canvas.drawRRect(RRect.fromRectAndRadius(bodyRect, const Radius.circular(3)), p);
    p.shader = null;

    // Body shading
    p.color = Colors.black.withOpacity(0.18);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(bodyRect.right - 5, bodyRect.top, 5, bodyRect.height), const Radius.circular(3)),
      p,
    );

    // Belt
    p.color = const Color(0xFF5D4037);
    canvas.drawRect(Rect.fromLTWH(bodyRect.left, bodyRect.top + bodyRect.height * 0.6, bodyRect.width, 5), p);
    // Belt buckle
    p.color = const Color(0xFFFFD700);
    canvas.drawRect(Rect.fromLTWH(-4, bodyRect.top + bodyRect.height * 0.6 + 1, 8, 3), p);

    // ── Head ─────────────────────────────────────────────────────
    Rect headRect = Rect.fromLTWH(-pw / 2 + 3, hTop + 8, pw - 6, 14);
    final headGrad = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [const Color(0xFF66BB6A), const Color(0xFF4CAF50)],
    );
    p.shader = headGrad.createShader(headRect);
    canvas.drawRRect(RRect.fromRectAndRadius(headRect, const Radius.circular(3)), p);
    p.shader = null;

    // Eyes
    p.color = Colors.white;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(2, hTop + 11, 6, 5), const Radius.circular(1)), p);
    p.color = const Color(0xFF1A237E);
    canvas.drawCircle(Offset(4.5, hTop + 13.5), 1.8, p);
    // Eye shine
    p.color = Colors.white.withOpacity(0.8);
    canvas.drawCircle(Offset(5.2, hTop + 12.8), 0.7, p);

    // ── Crown ────────────────────────────────────────────────────
    final crownGrad = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [const Color(0xFFFFF176), const Color(0xFFFFD700), const Color(0xFFFF8F00)],
    );
    Path crown = Path();
    crown.moveTo(-pw / 2 + 3, hTop + 12);
    crown.lineTo(-pw / 2 + 3, hTop + 5);
    crown.lineTo(-5, hTop);
    crown.lineTo(0, hTop + 5);
    crown.lineTo(5, hTop);
    crown.lineTo(pw / 2 - 3, hTop + 5);
    crown.lineTo(pw / 2 - 3, hTop + 12);
    crown.close();
    p.shader = crownGrad.createShader(Rect.fromLTWH(-pw / 2 + 3, hTop, pw - 6, 12));
    canvas.drawPath(crown, p);
    p.shader = null;

    // Crown outline
    p.color = const Color(0xFFFF8F00);
    p.style = PaintingStyle.stroke;
    p.strokeWidth = 0.8;
    canvas.drawPath(crown, p);
    p.style = PaintingStyle.fill;

    // Crown gems
    p.color = const Color(0xFFE53935);
    canvas.drawCircle(Offset(0, hTop + 3), 2, p);
    p.color = const Color(0xFF1E88E5);
    canvas.drawCircle(Offset(-5, hTop + 6), 1.5, p);
    p.color = const Color(0xFF43A047);
    canvas.drawCircle(Offset(5, hTop + 6), 1.5, p);

    // ── Boots ────────────────────────────────────────────────────
    double bootTop = ph / 2 - 10 + crouchY;
    final bootGrad = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [const Color(0xFF6D4C41), const Color(0xFF3E2723)],
    );

    // Running animation
    double legOffset = 0;
    if (player.state == PlayerState.running) {
      legOffset = sin(time * 13) * 3;
    }

    Rect leftBoot = Rect.fromLTWH(-pw / 2 + 2, bootTop + legOffset, pw / 2 - 3, 10);
    p.shader = bootGrad.createShader(leftBoot);
    canvas.drawRRect(RRect.fromRectAndRadius(leftBoot, const Radius.circular(2)), p);

    Rect rightBoot = Rect.fromLTWH(2, bootTop - legOffset, pw / 2 - 3, 10);
    p.shader = bootGrad.createShader(rightBoot);
    canvas.drawRRect(RRect.fromRectAndRadius(rightBoot, const Radius.circular(2)), p);
    p.shader = null;

    // Boot buckles
    p.color = const Color(0xFFFFD700).withOpacity(0.8);
    canvas.drawRect(Rect.fromLTWH(-pw / 2 + 5, bootTop + legOffset + 3, 6, 2), p);
    canvas.drawRect(Rect.fromLTWH(4, bootTop - legOffset + 3, 6, 2), p);

    canvas.restore();
  }

  // ── Charge arrow ──────────────────────────────────────────────────────────

  void _drawChargeArrow(Canvas canvas, Player player) {
    double cx = player.centerX;
    double cy = player.y + player.height * 0.25;
    double angle = player.chargeAngle;
    double frac = player.chargeFraction;
    double arrowLen = 22 + frac * 44;

    double endX = cx + cos(angle) * arrowLen;
    double endY = cy + sin(angle) * arrowLen;

    Color arrowColor = frac < 0.5
        ? Color.lerp(Colors.greenAccent, Colors.yellowAccent, frac * 2)!
        : Color.lerp(Colors.yellowAccent, Colors.redAccent, (frac - 0.5) * 2)!;

    // Glow
    final glowPaint = Paint()
      ..color = arrowColor.withOpacity(0.3)
      ..strokeWidth = 7
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawLine(Offset(cx, cy), Offset(endX, endY), glowPaint);

    // Main line
    final linePaint = Paint()
      ..color = arrowColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx, cy), Offset(endX, endY), linePaint);

    // Arrowhead
    double headLen = 11;
    linePaint.style = PaintingStyle.fill;
    Path head = Path();
    head.moveTo(endX, endY);
    head.lineTo(endX - cos(angle - 0.45) * headLen, endY - sin(angle - 0.45) * headLen);
    head.lineTo(endX - cos(angle + 0.45) * headLen, endY - sin(angle + 0.45) * headLen);
    head.close();
    canvas.drawPath(head, linePaint);
  }

  // ── Particle ───────────────────────────────────────────────────────────────

  void _drawParticle(Canvas canvas, DustParticle p) {
    Color c = p.isDeath
        ? Color.lerp(Colors.red, Colors.orange, p.alpha)!
        : Color.lerp(JKColors.landDustColor, Colors.white, p.alpha * 0.5)!;
    final paint = Paint()
      ..color = c.withOpacity(p.alpha * 0.75)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawCircle(Offset(p.x, p.y), p.size * p.alpha, paint);
  }

  @override
  bool shouldRepaint(GameRenderer oldDelegate) => true;
}
