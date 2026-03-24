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
  bool _showOrientationTip = true;

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
    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;

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

              // Main content
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 24),

                        // Crown icon, animated bounce
                        Transform.translate(
                          offset: Offset(0, -6 * sin(t * 2 * pi)),
                          child: _buildCrown(t),
                        ),
                        const SizedBox(height: 20),

                        // Title
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFFFF176), Color(0xFFFFD700)],
                          ).createShader(bounds),
                          child: const Text(
                            'JUMP KING',
                            style: TextStyle(
                              fontSize: 46,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 6,
                            ),
                          ),
                        ),

                        const SizedBox(height: 6),
                        Text(
                          'REACH THE SUMMIT',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.45),
                            fontSize: 12,
                            letterSpacing: 4,
                          ),
                        ),

                        const SizedBox(height: 36),

                        // Orientation tip banner
                        if (_showOrientationTip)
                          _OrientationTip(
                            isLandscape: isLandscape,
                            onDismiss: () => setState(() => _showOrientationTip = false),
                          ),

                        const SizedBox(height: 28),

                        // Start button
                        _StartButton(onTap: widget.onStartGame, t: t),

                        const SizedBox(height: 40),

                        // Controls hint
                        _buildControlsHint(),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
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
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Column(
        children: [
          Text(
            'CÓMO JUGAR',
            style: TextStyle(
              color: JKColors.textGold.withOpacity(0.9),
              fontSize: 10,
              letterSpacing: 3,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: const [
              _Hint(icon: '◀  ▶', text: 'Botones\nizquierda/derecha'),
              _Hint(icon: '▲', text: 'Mantén JUMP\ny suelta para saltar'),
              _Hint(icon: '🏔️', text: 'Llega a\nla cima'),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Orientation tip ──────────────────────────────────────────────────────────

class _OrientationTip extends StatelessWidget {
  final bool isLandscape;
  final VoidCallback onDismiss;
  const _OrientationTip({required this.isLandscape, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 28),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isLandscape
              ? [const Color(0xFF1B5E20).withOpacity(0.7), const Color(0xFF2E7D32).withOpacity(0.5)]
              : [const Color(0xFF4A148C).withOpacity(0.7), const Color(0xFF6A1B9A).withOpacity(0.5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isLandscape
              ? Colors.greenAccent.withOpacity(0.45)
              : const Color(0xFFFFD700).withOpacity(0.45),
          width: 1.3,
        ),
      ),
      child: Row(
        children: [
          Text(
            isLandscape ? '✅' : '📱',
            style: const TextStyle(fontSize: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLandscape ? '¡Modo ideal!' : 'Recomendación',
                  style: TextStyle(
                    color: isLandscape ? Colors.greenAccent : const Color(0xFFFFD700),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isLandscape
                      ? 'Estás en horizontal — la mejor experiencia para Jump King.'
                      : 'Rota el teléfono a horizontal para ver mejor el mapa y tener más espacio para los controles.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onDismiss,
            child: Icon(Icons.close, color: Colors.white.withOpacity(0.4), size: 16),
          ),
        ],
      ),
    );
  }
}

// ── Start button ─────────────────────────────────────────────────────────────

class _StartButton extends StatefulWidget {
  final VoidCallback onTap;
  final double t;
  const _StartButton({required this.onTap, required this.t});

  @override
  State<_StartButton> createState() => _StartButtonState();
}

class _StartButtonState extends State<_StartButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    double pulse = 1.0 + 0.03 * sin(widget.t * 2 * pi * 1.5);
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: Transform.scale(
        scale: _pressed ? 0.94 : pulse,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6A1B9A), Color(0xFF4A148C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: JKColors.menuButtonBorder, width: 2),
            boxShadow: [
              BoxShadow(
                color: JKColors.menuButtonBorder.withOpacity(_pressed ? 0.2 : 0.45),
                blurRadius: _pressed ? 8 : 20,
                spreadRadius: _pressed ? 1 : 4,
              ),
            ],
          ),
          child: const Text(
            'NUEVA PARTIDA',
            style: TextStyle(
              color: JKColors.textGold,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _Hint extends StatelessWidget {
  final String icon, text;
  const _Hint({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 20, color: Colors.white70)),
        const SizedBox(height: 6),
        Text(text, textAlign: TextAlign.center,
            style: const TextStyle(color: JKColors.textGray, fontSize: 10, height: 1.4)),
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
    final paint = Paint()..color = JKColors.menuTitle..style = PaintingStyle.fill;

    double glow = 0.4 + 0.6 * sin(t * 2 * pi).abs();

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
