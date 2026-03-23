import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/constants.dart';

class MainMenuScreen extends StatefulWidget {
  final VoidCallback onStartGame;
  const MainMenuScreen({super.key, required this.onStartGame});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        double t = _ctrl.value;
        return Container(
          decoration: const BoxDecoration(color: JKColors.menuBg),
          child: Stack(
            children: [
              // Background stars
              CustomPaint(
                painter: _StarsPainter(t),
                child: const SizedBox.expand(),
              ),

              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Crown icon, animated bounce
                    Transform.translate(
                      offset: Offset(0, -6 * sin(t * 2 * pi)),
                      child: _buildCrown(t),
                    ),
                    const SizedBox(height: 24),

                    // Title
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFFF176), Color(0xFFFFD700)],
                      ).createShader(bounds),
                      child: const Text(
                        'JUMP KING',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 6,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),
                    Text(
                      'REACH THE SUMMIT',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                        letterSpacing: 4,
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Start button
                    GestureDetector(
                      onTap: widget.onStartGame,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 100),
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                        decoration: BoxDecoration(
                          color: JKColors.menuButton,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: JKColors.menuButtonBorder, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: JKColors.menuButtonBorder.withOpacity(0.4),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Text(
                          'NEW GAME',
                          style: TextStyle(
                            color: JKColors.textGold,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 3,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Controls hint
                    _buildControlsHint(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCrown(double t) {
    return CustomPaint(
      size: const Size(80, 60),
      painter: _CrownPainter(t),
    );
  }

  Widget _buildControlsHint() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white12),
      ),
      child: const Column(
        children: [
          Text('HOW TO PLAY', style: TextStyle(color: JKColors.textGold, fontSize: 10, letterSpacing: 2)),
          SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Hint(icon: '👈', text: 'Drag left side\nto move'),
              SizedBox(width: 24),
              _Hint(icon: '⬆️', text: 'Hold right side\nto charge jump'),
              SizedBox(width: 24),
              _Hint(icon: '🏔️', text: 'Reach the\nSummit!'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  final String icon, text;
  const _Hint({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 4),
        Text(text, textAlign: TextAlign.center, style: const TextStyle(color: JKColors.textGray, fontSize: 10)),
      ],
    );
  }
}

class _StarsPainter extends CustomPainter {
  final double t;
  _StarsPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(42);
    final paint = Paint();
    for (int i = 0; i < 80; i++) {
      double x = rng.nextDouble() * size.width;
      double y = rng.nextDouble() * size.height;
      double twinkle = 0.2 + 0.8 * sin(t * 2 * pi * (0.3 + rng.nextDouble() * 0.7) + i).abs();
      paint.color = Colors.white.withOpacity(twinkle * 0.5);
      canvas.drawCircle(Offset(x, y), 1 + rng.nextDouble() * 1.5, paint);
    }
  }

  @override
  bool shouldRepaint(_StarsPainter old) => true;
}

class _CrownPainter extends CustomPainter {
  final double t;
  _CrownPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = JKColors.menuTitle
      ..style = PaintingStyle.fill;

    double glow = 0.4 + 0.6 * sin(t * 2 * pi).abs();

    // Glow
    paint.color = JKColors.menuTitle.withOpacity(glow * 0.3);
    canvas.drawCircle(Offset(size.width / 2, size.height / 2 + 10), 35, paint);

    paint.color = JKColors.menuTitle;
    Path crown = Path();
    double cx = size.width / 2;
    double base = size.height - 8;
    crown.moveTo(8, base);
    crown.lineTo(8, base - 22);
    crown.lineTo(cx - 10, base - 36);
    crown.lineTo(cx, base - 16);
    crown.lineTo(cx + 10, base - 36);
    crown.lineTo(size.width - 8, base - 22);
    crown.lineTo(size.width - 8, base);
    crown.close();
    canvas.drawPath(crown, paint);

    // Jewels
    final jewelColors = [Colors.red, Colors.blue, Colors.green];
    for (int i = 0; i < 3; i++) {
      paint.color = jewelColors[i];
      double jx = 18 + i * (size.width - 36) / 2;
      canvas.drawCircle(Offset(jx, base - 8), 5, paint);
    }
  }

  @override
  bool shouldRepaint(_CrownPainter old) => true;
}
