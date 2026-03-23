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

    // ── Camera: center player vertically, clamp to map ──────────
    double camX = 0; // horizontal fixed (map is same width as screen)
    double camY = player.centerY - size.height * 0.5;
    camY = camY.clamp(0, (map.pixelHeight - size.height).clamp(0, double.infinity));

    // ── Background sky ────────────────────────────────────────────
    final bgPaint = Paint()..color = JKColors.skyColors[levelIdx];
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Background parallax stars / texture
    _drawBackground(canvas, size, camY, levelIdx, time);

    canvas.save();
    canvas.translate(-camX, -camY);

    // ── Tiles ─────────────────────────────────────────────────────
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

    // ── Dust particles ────────────────────────────────────────────
    for (var p in engine.particles) {
      _drawParticle(canvas, p);
    }

    // ── Player ───────────────────────────────────────────────────
    _drawPlayer(canvas, player, time);

    // ── Jump charge arrow ────────────────────────────────────────
    if (player.isCharging) {
      _drawChargeArrow(canvas, player);
    }

    canvas.restore();

    // ── Damage/hurt overlay ───────────────────────────────────────
    if (player.isHurt) {
      double hurtAlpha = (player.hurtTimer / 1.5 * 0.5).clamp(0, 0.5);
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = JKColors.damageFlash.withOpacity(hurtAlpha),
      );
    }

    // ── Checkpoint flash ──────────────────────────────────────────
    if (engine.checkpointFlash) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = JKColors.victoryGlow.withOpacity(0.18),
      );
    }
  }

  void _drawBackground(Canvas canvas, Size size, double camY, int levelIdx, double time) {
    final paint = Paint();
    // Draw subtle background decorations based on level
    final bgRng = Random(levelIdx * 999);
    paint.color = Colors.white.withOpacity(0.12);
    for (int i = 0; i < 40; i++) {
      double sx = bgRng.nextDouble() * size.width;
      double sy = bgRng.nextDouble() * size.height;
      // Parallax: bg moves at 20% of camera
      double parallaxY = (sy - camY * 0.2) % size.height;
      double starSize = 1 + bgRng.nextDouble() * 2;
      // Twinkle
      double twinkle = 0.5 + 0.5 * sin(time * 2 + i);
      paint.color = Colors.white.withOpacity(0.05 + 0.1 * twinkle);
      canvas.drawCircle(Offset(sx, parallaxY), starSize, paint);
    }
  }

  void _drawTile(Canvas canvas, Rect r, TileType type, int levelIdx,
      int col, int row, GameMap map, double time) {
    final paint = Paint();
    double ts = JKConstants.tileSize;

    switch (type) {
      case TileType.solid:
        // Main face
        paint.color = JKColors.terrainColors[levelIdx];
        canvas.drawRect(r, paint);
        // Top highlight
        paint.color = JKColors.platformColors[levelIdx];
        canvas.drawRect(Rect.fromLTWH(r.left, r.top, r.width, 4), paint);
        // Dark bottom
        paint.color = JKColors.terrainDarkColors[levelIdx];
        canvas.drawRect(Rect.fromLTWH(r.left, r.bottom - 3, r.width, 3), paint);
        // Mortar lines
        paint.color = JKColors.terrainDarkColors[levelIdx].withOpacity(0.5);
        paint.strokeWidth = 1;
        paint.style = PaintingStyle.stroke;
        if (col % 2 == row % 2) {
          canvas.drawLine(Offset(r.left + ts / 2, r.top), Offset(r.left + ts / 2, r.bottom), paint);
        }
        paint.style = PaintingStyle.fill;
        break;

      case TileType.platform:
        // One-way platform: thin plank
        paint.color = JKColors.platformColors[levelIdx];
        canvas.drawRect(Rect.fromLTWH(r.left + 2, r.top, r.width - 4, 10), paint);
        paint.color = JKColors.terrainDarkColors[levelIdx];
        canvas.drawRect(Rect.fromLTWH(r.left + 2, r.top + 10, r.width - 4, 3), paint);
        break;

      case TileType.ice:
        // Icy blue solid
        paint.color = JKColors.iceBlueDark;
        canvas.drawRect(r, paint);
        paint.color = JKColors.iceBlue;
        canvas.drawRect(Rect.fromLTWH(r.left, r.top, r.width, 5), paint);
        // Shine glints
        paint.color = Colors.white.withOpacity(0.4 + 0.3 * sin(time * 3 + col));
        canvas.drawRect(Rect.fromLTWH(r.left + 4, r.top + 3, 8, 2), paint);
        canvas.drawRect(Rect.fromLTWH(r.left + r.width - 14, r.top + 6, 6, 2), paint);
        break;

      case TileType.crumble:
        double frac = map.getCrumbleFraction(col, row);
        // Shake if crumbling
        double shakeX = frac > 0.3 ? sin(time * 30) * 2 * frac : 0;
        Rect cr = r.translate(shakeX, 0);
        paint.color = JKColors.crumbleColor.withOpacity(1.0 - frac * 0.5);
        canvas.drawRect(cr, paint);
        paint.color = JKColors.crumbleDark.withOpacity(1.0 - frac * 0.5);
        canvas.drawRect(Rect.fromLTWH(cr.left, cr.top, cr.width, 5), paint);
        // Crack lines
        if (frac > 0.2) {
          paint.color = Colors.black.withOpacity(frac * 0.8);
          paint.strokeWidth = 1.5;
          paint.style = PaintingStyle.stroke;
          canvas.drawLine(Offset(cr.left + 8, cr.top + 2), Offset(cr.left + 15, cr.bottom - 4), paint);
          canvas.drawLine(Offset(cr.right - 10, cr.top + 5), Offset(cr.right - 18, cr.bottom - 2), paint);
          paint.style = PaintingStyle.fill;
        }
        break;

      case TileType.spike:
        // Draw spikes (triangles)
        int spikeCount = 3;
        double sw = r.width / spikeCount;
        for (int i = 0; i < spikeCount; i++) {
          Path spike = Path();
          double sx = r.left + i * sw;
          spike.moveTo(sx, r.bottom);
          spike.lineTo(sx + sw / 2, r.top + 6);
          spike.lineTo(sx + sw, r.bottom);
          spike.close();
          paint.color = JKColors.spikeColor;
          canvas.drawPath(spike, paint);
          // Shine
          paint.color = JKColors.spikeShine;
          canvas.drawLine(Offset(sx + sw / 2, r.top + 6), Offset(sx + sw / 3, r.bottom - 4), paint..strokeWidth = 1..style = PaintingStyle.stroke);
          paint.style = PaintingStyle.fill;
        }
        break;

      case TileType.checkpoint:
        // Draw a flag/banner
        paint.color = JKColors.checkpointActive;
        // Pole
        paint.strokeWidth = 2;
        paint.style = PaintingStyle.stroke;
        canvas.drawLine(Offset(r.left + r.width / 2, r.top + 4), Offset(r.left + r.width / 2, r.bottom - 2), paint);
        paint.style = PaintingStyle.fill;
        // Flag waving
        double wave = sin(time * 4) * 3;
        Path flag = Path();
        flag.moveTo(r.left + r.width / 2, r.top + 5);
        flag.lineTo(r.left + r.width / 2 + 14 + wave, r.top + 11);
        flag.lineTo(r.left + r.width / 2, r.top + 17);
        flag.close();
        paint.color = JKColors.checkpointActive;
        canvas.drawPath(flag, paint);
        break;

      case TileType.goal:
        // Glowing crown/portal
        double glow = 0.6 + 0.4 * sin(time * 3);
        paint.color = JKColors.victoryGlow.withOpacity(glow);
        canvas.drawRect(r, paint);
        // Crown shape
        paint.color = JKColors.menuTitle;
        Path crown = Path();
        double cx = r.left + r.width / 2;
        double cy = r.top + r.height / 2;
        crown.moveTo(cx - 12, cy + 8);
        crown.lineTo(cx - 12, cy - 4);
        crown.lineTo(cx - 6, cy - 10);
        crown.lineTo(cx, cy - 4);
        crown.lineTo(cx + 6, cy - 10);
        crown.lineTo(cx + 12, cy - 4);
        crown.lineTo(cx + 12, cy + 8);
        crown.close();
        canvas.drawPath(crown, paint);
        break;

      case TileType.wind:
        // Wind lines
        double alpha = 0.3 + 0.2 * sin(time * 5 + col);
        paint.color = JKColors.windColor.withOpacity(alpha);
        canvas.drawRect(r, paint);
        // Arrows
        paint.color = Colors.cyan.withOpacity(0.5);
        paint.strokeWidth = 1.5;
        paint.style = PaintingStyle.stroke;
        double arrowOffset = (time * 40) % ts;
        // determine direction from windZones
        double force = 0;
        for (var zone in map.windZones) {
          double zoneCol = zone.x / ts;
          double zoneRow = zone.y / ts;
          if (col >= zoneCol && col < zoneCol + zone.w / ts) {
            force = zone.force;
          }
        }
        double arrowDir = force >= 0 ? 1 : -1;
        for (double ax = r.left + arrowOffset; ax < r.right; ax += 20) {
          canvas.drawLine(Offset(ax, r.top + r.height / 2), Offset(ax + 10 * arrowDir, r.top + r.height / 2), paint);
          canvas.drawLine(Offset(ax + 10 * arrowDir, r.top + r.height / 2), Offset(ax + 4 * arrowDir, r.top + r.height / 2 - 4), paint);
          canvas.drawLine(Offset(ax + 10 * arrowDir, r.top + r.height / 2), Offset(ax + 4 * arrowDir, r.top + r.height / 2 + 4), paint);
        }
        paint.style = PaintingStyle.fill;
        break;

      default:
        break;
    }
  }

  void _drawPlayer(Canvas canvas, Player player, double time) {
    double px = player.x;
    double py = player.y;
    double pw = player.width;
    double ph = player.height;
    bool faceRight = player.facingRight;

    // Squash/stretch on landing
    double scaleY = 1.0;
    double scaleX = 1.0;
    if (player.state == PlayerState.landing && player.landingTimer > 0) {
      double t = player.landingTimer / 0.12;
      scaleY = 1.0 - 0.25 * t;
      scaleX = 1.0 + 0.15 * t;
    }

    // Charging: slight crouch
    double crouchY = 0;
    if (player.isCharging) {
      crouchY = player.chargeFraction * 6;
      scaleY = 1.0 - player.chargeFraction * 0.15;
    }

    canvas.save();

    // Hurt: flash red
    if (player.isHurt) {
      if ((player.hurtTimer * 8).floor().isOdd) {
        canvas.restore();
        return; // blink
      }
    }

    double cx = px + pw / 2;
    double cy = py + ph / 2 + crouchY / 2;

    canvas.translate(cx, cy);
    canvas.scale(faceRight ? scaleX : -scaleX, scaleY);

    final paint = Paint();

    // Body
    paint.color = JKColors.playerBody;
    canvas.drawRect(Rect.fromCenter(center: Offset(0, crouchY / 2), width: pw - 4, height: ph - 8), paint);

    // Cape (behind body, so draw first in back)
    paint.color = JKColors.playerCape;
    Path cape = Path();
    double capeWave = sin(time * 5) * 3;
    cape.moveTo(-pw / 2 + 2, -ph / 2 + 6);
    cape.lineTo(-pw / 2 - 8 + capeWave, 0);
    cape.lineTo(-pw / 2 - 4 + capeWave, ph / 2 - 2);
    cape.lineTo(-pw / 2 + 2, ph / 2 - 8);
    cape.close();
    canvas.drawPath(cape, paint);

    // Crown / helmet
    paint.color = JKColors.playerCrown;
    Path crown = Path();
    double headTop = -ph / 2 + crouchY;
    crown.moveTo(-pw / 2 + 2, headTop + 12);
    crown.lineTo(-pw / 2 + 2, headTop + 4);
    crown.lineTo(-4, headTop);
    crown.lineTo(0, headTop + 5);
    crown.lineTo(4, headTop);
    crown.lineTo(pw / 2 - 2, headTop + 4);
    crown.lineTo(pw / 2 - 2, headTop + 12);
    crown.close();
    canvas.drawPath(crown, paint);

    // Head
    paint.color = JKColors.playerBody;
    canvas.drawRect(Rect.fromLTWH(-pw / 2 + 2, headTop + 8, pw - 4, 14), paint);

    // Eyes
    paint.color = JKColors.playerEyes;
    canvas.drawRect(Rect.fromLTWH(2, headTop + 11, 5, 4), paint);

    // Eye pupil
    paint.color = Colors.black;
    canvas.drawRect(Rect.fromLTWH(4, headTop + 12, 2, 3), paint);

    // Boots
    paint.color = JKColors.playerBoots;
    canvas.drawRect(Rect.fromLTWH(-pw / 2 + 2, ph / 2 - 9 + crouchY, pw / 2 - 2, 9), paint);
    canvas.drawRect(Rect.fromLTWH(2, ph / 2 - 9 + crouchY, pw / 2 - 2, 9), paint);

    // Running animation: leg bob
    if (player.state == PlayerState.running) {
      double legBob = sin(time * 12) * 2;
      paint.color = JKColors.playerBoots.withOpacity(0.6);
      canvas.drawRect(Rect.fromLTWH(-pw / 2 + 2, ph / 2 - 9 + crouchY + legBob, pw / 2 - 2, 4), paint);
      canvas.drawRect(Rect.fromLTWH(2, ph / 2 - 9 + crouchY - legBob, pw / 2 - 2, 4), paint);
    }

    canvas.restore();
  }

  void _drawChargeArrow(Canvas canvas, Player player) {
    double cx = player.centerX;
    double cy = player.y + player.height * 0.3;

    double angle = player.chargeAngle;
    double frac = player.chargeFraction;
    double arrowLen = 20 + frac * 40;

    double endX = cx + cos(angle) * arrowLen;
    double endY = cy + sin(angle) * arrowLen;

    // Color: green → yellow → red
    Color arrowColor;
    if (frac < 0.5) {
      arrowColor = Color.lerp(Colors.greenAccent, Colors.yellow, frac * 2)!;
    } else {
      arrowColor = Color.lerp(Colors.yellow, JKColors.chargeBarFull, (frac - 0.5) * 2)!;
    }

    final paint = Paint()
      ..color = arrowColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(cx, cy), Offset(endX, endY), paint);

    // Arrowhead
    double headAngle = angle;
    double headLen = 10;
    paint.style = PaintingStyle.fill;
    Path head = Path();
    head.moveTo(endX, endY);
    head.lineTo(endX - cos(headAngle - 0.5) * headLen, endY - sin(headAngle - 0.5) * headLen);
    head.lineTo(endX - cos(headAngle + 0.5) * headLen, endY - sin(headAngle + 0.5) * headLen);
    head.close();
    canvas.drawPath(head, paint);
  }

  void _drawParticle(Canvas canvas, DustParticle p) {
    final paint = Paint()
      ..color = (p.isDeath ? Colors.red : JKColors.landDustColor).withOpacity(p.alpha * 0.8);
    canvas.drawCircle(Offset(p.x, p.y), p.size * p.alpha, paint);
  }

  @override
  bool shouldRepaint(GameRenderer oldDelegate) => true;
}
