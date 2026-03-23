import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../game/game_engine.dart';

class VictoryScreen extends StatefulWidget {
  final GameEngine engine;
  final VoidCallback onRestart;
  final VoidCallback onMenu;

  const VictoryScreen({
    super.key,
    required this.engine,
    required this.onRestart,
    required this.onMenu,
  });

  @override
  State<VictoryScreen> createState() => _VictoryScreenState();
}

class _VictoryScreenState extends State<VictoryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final player = widget.engine.player;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        double t = _ctrl.value;
        return Container(
          color: const Color(0xCC000000),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated crown
                Transform.translate(
                  offset: Offset(sin(t * 2 * pi) * 4, -8 * sin(t * pi)),
                  child: Transform.rotate(
                    angle: sin(t * 2 * pi) * 0.1,
                    child: const Text('👑', style: TextStyle(fontSize: 72)),
                  ),
                ),
                const SizedBox(height: 16),

                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      const Color(0xFFFFD700),
                      const Color(0xFFFFF9C4),
                      const Color(0xFFFFD700),
                    ],
                    stops: [0, t, 1],
                  ).createShader(bounds),
                  child: const Text(
                    'YOU ARE THE JUMP KING!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Stats
                _StatCard(
                  children: [
                    _Stat(label: 'TOTAL TIME', value: widget.engine.formattedTime),
                    _Stat(label: 'FALLS', value: '${player.deaths}'),
                    _Stat(label: 'JUMPS', value: '${player.jumps}'),
                  ],
                ),

                const SizedBox(height: 32),

                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _MenuButton(label: 'MAIN MENU', onTap: widget.onMenu, secondary: true),
                    const SizedBox(width: 16),
                    _MenuButton(label: 'PLAY AGAIN', onTap: widget.onRestart),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final List<Widget> children;
  const _StatCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      decoration: BoxDecoration(
        color: JKColors.hudBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: JKColors.menuButtonBorder.withOpacity(0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: children
            .expand((w) => [w, const SizedBox(width: 24)])
            .take(children.length * 2 - 1)
            .toList(),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label, value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: JKColors.textGray, fontSize: 9, letterSpacing: 1.5)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: JKColors.textGold, fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _MenuButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool secondary;

  const _MenuButton({required this.label, required this.onTap, this.secondary = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: secondary ? Colors.transparent : JKColors.menuButton,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: secondary ? Colors.white30 : JKColors.menuButtonBorder,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: secondary ? Colors.white60 : JKColors.textGold,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}
