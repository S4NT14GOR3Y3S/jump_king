import 'package:flutter/material.dart';
import '../game/game_engine.dart';
import '../utils/constants.dart';

class HudOverlay extends StatelessWidget {
  final GameEngine engine;
  const HudOverlay({super.key, required this.engine});

  @override
  Widget build(BuildContext context) {
    final player = engine.player;

    return Positioned.fill(
      child: Stack(
        children: [
          // Top left: level name + time
          Positioned(
            top: 16,
            left: 16,
            child: _HudPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    engine.currentMap.name.toUpperCase(),
                    style: const TextStyle(
                      color: JKColors.textGold,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.timer, color: JKColors.textGray, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        engine.formattedTime,
                        style: const TextStyle(color: JKColors.textWhite, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Top right: level indicator + deaths
          Positioned(
            top: 16,
            right: 16,
            child: _HudPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.layers, color: JKColors.textGold, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        'LEVEL ${engine.currentLevel + 1}/${JKConstants.totalLevels}',
                        style: const TextStyle(
                          color: JKColors.textGold,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.close, color: Colors.redAccent, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        '${player.deaths} FALLS',
                        style: const TextStyle(color: Colors.redAccent, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Bottom center: charge bar (visible while charging)
          if (player.isCharging)
            Positioned(
              bottom: 130,
              left: 0,
              right: 0,
              child: Center(
                child: _ChargeBar(fraction: player.chargeFraction),
              ),
            ),

          // Checkpoint save notification
          if (engine.checkpointFlash)
            Positioned(
              top: 80,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: JKColors.checkpointActive.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '✦ CHECKPOINT SAVED ✦',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HudPanel extends StatelessWidget {
  final Widget child;
  const _HudPanel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: JKColors.hudBackground,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: JKColors.hudBorder.withOpacity(0.5), width: 1),
      ),
      child: child,
    );
  }
}

class _ChargeBar extends StatelessWidget {
  final double fraction;
  const _ChargeBar({required this.fraction});

  @override
  Widget build(BuildContext context) {
    Color barColor;
    if (fraction < 0.5) {
      barColor = Color.lerp(Colors.greenAccent, Colors.yellow, fraction * 2)!;
    } else {
      barColor = Color.lerp(Colors.yellow, Colors.redAccent, (fraction - 0.5) * 2)!;
    }

    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: JKColors.chargeBarBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Stack(
        children: [
          FractionallySizedBox(
            widthFactor: fraction.clamp(0, 1),
            child: Container(
              height: 18,
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
          SizedBox(
            height: 18,
            child: Center(
              child: Text(
                'CHARGE',
                style: TextStyle(
                  color: fraction > 0.3 ? Colors.black87 : Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
