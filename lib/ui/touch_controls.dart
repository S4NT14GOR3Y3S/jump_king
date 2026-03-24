import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Jump King touch controls:
/// - Left side: two visible buttons (← →) for movement
/// - Right side: tap/hold to charge jump, release to jump
class TouchControls extends StatefulWidget {
  final void Function(double dx) onMove;
  final void Function() onJumpStart;
  final void Function() onJumpRelease;

  const TouchControls({
    super.key,
    required this.onMove,
    required this.onJumpStart,
    required this.onJumpRelease,
  });

  @override
  State<TouchControls> createState() => _TouchControlsState();
}

class _TouchControlsState extends State<TouchControls> {
  bool _leftHeld = false;
  bool _rightHeld = false;
  bool _jumpHeld = false;

  void _setMove() {
    double val = 0;
    if (_leftHeld && !_rightHeld) val = -1;
    if (_rightHeld && !_leftHeld) val = 1;
    widget.onMove(val);
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final w = mq.size.width;
    final btnSize = (w * 0.12).clamp(52.0, 80.0);
    final bottomPad = mq.padding.bottom + 20;

    return Positioned.fill(
      child: Stack(
        children: [
          // LEFT button
          Positioned(
            left: 16,
            bottom: bottomPad,
            child: _GameButton(
              size: btnSize,
              held: _leftHeld,
              label: '◀',
              onDown: () { setState(() => _leftHeld = true); _setMove(); },
              onUp:   () { setState(() => _leftHeld = false); _setMove(); },
            ),
          ),

          // RIGHT button
          Positioned(
            left: 16 + btnSize + 14,
            bottom: bottomPad,
            child: _GameButton(
              size: btnSize,
              held: _rightHeld,
              label: '▶',
              onDown: () { setState(() => _rightHeld = true); _setMove(); },
              onUp:   () { setState(() => _rightHeld = false); _setMove(); },
            ),
          ),

          // JUMP button
          Positioned(
            right: 20,
            bottom: bottomPad,
            child: _JumpButton(
              size: btnSize * 1.18,
              held: _jumpHeld,
              onDown: () { setState(() => _jumpHeld = true); widget.onJumpStart(); },
              onUp:   () { setState(() => _jumpHeld = false); widget.onJumpRelease(); },
            ),
          ),
        ],
      ),
    );
  }
}

class _GameButton extends StatelessWidget {
  final double size;
  final bool held;
  final String label;
  final VoidCallback onDown;
  final VoidCallback onUp;
  const _GameButton({required this.size, required this.held, required this.label, required this.onDown, required this.onUp});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => onDown(),
      onTapUp: (_) => onUp(),
      onTapCancel: onUp,
      onPanStart: (_) => onDown(),
      onPanEnd: (_) => onUp(),
      onPanCancel: onUp,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        width: size, height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: held ? const Color(0xFFFFD700).withOpacity(0.22) : Colors.white.withOpacity(0.08),
          border: Border.all(
            color: held ? const Color(0xFFFFD700).withOpacity(0.85) : Colors.white.withOpacity(0.28),
            width: held ? 2.5 : 1.8,
          ),
          boxShadow: held ? [BoxShadow(color: const Color(0xFFFFD700).withOpacity(0.18), blurRadius: 14, spreadRadius: 2)] : [],
        ),
        child: Center(
          child: Text(label, style: TextStyle(color: held ? const Color(0xFFFFD700) : Colors.white60, fontSize: size * 0.38)),
        ),
      ),
    );
  }
}

class _JumpButton extends StatelessWidget {
  final double size;
  final bool held;
  final VoidCallback onDown;
  final VoidCallback onUp;
  const _JumpButton({required this.size, required this.held, required this.onDown, required this.onUp});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => onDown(),
      onTapUp: (_) => onUp(),
      onTapCancel: onUp,
      onPanStart: (_) => onDown(),
      onPanEnd: (_) => onUp(),
      onPanCancel: onUp,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        width: size, height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: held ? JKColors.chargeBar.withOpacity(0.28) : Colors.white.withOpacity(0.08),
          border: Border.all(
            color: held ? JKColors.chargeBar.withOpacity(0.9) : Colors.white.withOpacity(0.28),
            width: held ? 2.8 : 1.8,
          ),
          boxShadow: held ? [BoxShadow(color: JKColors.chargeBar.withOpacity(0.3), blurRadius: 18, spreadRadius: 3)] : [],
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('▲', style: TextStyle(color: held ? JKColors.chargeBar : Colors.white60, fontSize: size * 0.30, height: 1.1)),
              Text(held ? 'HOLD' : 'JUMP', style: TextStyle(color: held ? JKColors.chargeBar : Colors.white38, fontSize: size * 0.16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            ],
          ),
        ),
      ),
    );
  }
}
