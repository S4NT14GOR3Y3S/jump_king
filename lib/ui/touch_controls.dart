import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Jump King touch controls:
/// - Left half of screen: left/right movement via drag
/// - Right half of screen: tap/hold to charge jump, release to jump
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
  // Movement (left side)
  int? _moveTouchId;
  double _moveStartX = 0;
  double _currentMoveX = 0;
  static const double _deadzone = 10.0;
  static const double _maxDrift = 80.0;

  // Jump (right side)
  int? _jumpTouchId;
  bool _jumpHeld = false;

  double get _moveValue {
    double delta = _currentMoveX - _moveStartX;
    if (delta.abs() < _deadzone) return 0;
    return (delta / _maxDrift).clamp(-1.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final halfW = screenWidth / 2;

    return Positioned.fill(
      child: Stack(
        children: [
          // ── Left half: movement ──────────────────────
          Positioned(
            left: 0, top: 0,
            width: halfW, height: screenHeight,
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (e) {
                if (_moveTouchId != null) return;
                _moveTouchId = e.pointer;
                _moveStartX = e.position.dx;
                _currentMoveX = e.position.dx;
                widget.onMove(_moveValue);
              },
              onPointerMove: (e) {
                if (e.pointer != _moveTouchId) return;
                setState(() => _currentMoveX = e.position.dx);
                widget.onMove(_moveValue);
              },
              onPointerUp: (e) {
                if (e.pointer != _moveTouchId) return;
                _moveTouchId = null;
                _currentMoveX = _moveStartX;
                widget.onMove(0);
              },
              onPointerCancel: (e) {
                if (e.pointer != _moveTouchId) return;
                _moveTouchId = null;
                widget.onMove(0);
              },
              child: _buildMovePad(halfW, screenHeight),
            ),
          ),

          // ── Right half: jump ──────────────────────────
          Positioned(
            left: halfW, top: 0,
            width: halfW, height: screenHeight,
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (e) {
                if (_jumpTouchId != null) return;
                _jumpTouchId = e.pointer;
                setState(() => _jumpHeld = true);
                widget.onJumpStart();
              },
              onPointerUp: (e) {
                if (e.pointer != _jumpTouchId) return;
                _jumpTouchId = null;
                setState(() => _jumpHeld = false);
                widget.onJumpRelease();
              },
              onPointerCancel: (e) {
                if (e.pointer != _jumpTouchId) return;
                _jumpTouchId = null;
                setState(() => _jumpHeld = false);
                widget.onJumpRelease();
              },
              child: _buildJumpPad(halfW, screenHeight),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMovePad(double w, double h) {
    return Stack(
      children: [
        // Background hint
        Positioned(
          bottom: 20, left: 10, right: 10,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ControlHint(icon: Icons.arrow_back_ios, active: _moveValue < -0.1),
              _ControlHint(icon: Icons.arrow_forward_ios, active: _moveValue > 0.1),
            ],
          ),
        ),
        // Drag indicator
        if (_moveTouchId != null)
          Positioned(
            left: _currentMoveX - 20,
            bottom: 50,
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.15),
                border: Border.all(color: Colors.white30, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildJumpPad(double w, double h) {
    return Stack(
      children: [
        Positioned(
          bottom: 20,
          right: 20,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 80),
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _jumpHeld
                  ? JKColors.chargeBar.withOpacity(0.4)
                  : Colors.white.withOpacity(0.08),
              border: Border.all(
                color: _jumpHeld ? JKColors.chargeBar : Colors.white24,
                width: _jumpHeld ? 2.5 : 1.5,
              ),
            ),
            child: Center(
              child: Text(
                _jumpHeld ? 'HOLD' : 'JUMP',
                style: TextStyle(
                  color: _jumpHeld ? JKColors.chargeBar : Colors.white60,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ControlHint extends StatelessWidget {
  final IconData icon;
  final bool active;
  const _ControlHint({required this.icon, required this.active});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: active ? 1.0 : 0.25,
      duration: const Duration(milliseconds: 60),
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }
}
