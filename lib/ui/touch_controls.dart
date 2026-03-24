import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../utils/constants.dart';

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
  // Track individual pointer IDs so multi-touch works correctly
  int? _leftPointerId;
  int? _rightPointerId;
  int? _jumpPointerId;
  bool _jumpHeld = false;

  void _setMove() {
    double val = 0;
    if (_leftPointerId != null && _rightPointerId == null) val = -1;
    if (_rightPointerId != null && _leftPointerId == null) val = 1;
    widget.onMove(val);
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final w = mq.size.width;
    final btnSize = (w * 0.13).clamp(56.0, 84.0);
    final bottom = mq.padding.bottom + 18.0;

    return Positioned.fill(
      child: Stack(
        children: [
          // ── LEFT ──────────────────────────────────────────────
          Positioned(
            left: 14,
            bottom: bottom,
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (e) {
                if (_leftPointerId != null) return;
                setState(() => _leftPointerId = e.pointer);
                _setMove();
              },
              onPointerUp: (e) {
                if (e.pointer != _leftPointerId) return;
                setState(() => _leftPointerId = null);
                _setMove();
              },
              onPointerCancel: (e) {
                if (e.pointer != _leftPointerId) return;
                setState(() => _leftPointerId = null);
                _setMove();
              },
              child: _DpadButton(
                size: btnSize,
                label: '◀',
                held: _leftPointerId != null,
              ),
            ),
          ),

          // ── RIGHT ─────────────────────────────────────────────
          Positioned(
            left: 14 + btnSize + 12,
            bottom: bottom,
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (e) {
                if (_rightPointerId != null) return;
                setState(() => _rightPointerId = e.pointer);
                _setMove();
              },
              onPointerUp: (e) {
                if (e.pointer != _rightPointerId) return;
                setState(() => _rightPointerId = null);
                _setMove();
              },
              onPointerCancel: (e) {
                if (e.pointer != _rightPointerId) return;
                setState(() => _rightPointerId = null);
                _setMove();
              },
              child: _DpadButton(
                size: btnSize,
                label: '▶',
                held: _rightPointerId != null,
              ),
            ),
          ),

          // ── JUMP ──────────────────────────────────────────────
          Positioned(
            right: 14,
            bottom: bottom,
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (e) {
                if (_jumpPointerId != null) return;
                setState(() { _jumpPointerId = e.pointer; _jumpHeld = true; });
                widget.onJumpStart();
              },
              onPointerUp: (e) {
                if (e.pointer != _jumpPointerId) return;
                setState(() { _jumpPointerId = null; _jumpHeld = false; });
                widget.onJumpRelease();
              },
              onPointerCancel: (e) {
                if (e.pointer != _jumpPointerId) return;
                setState(() { _jumpPointerId = null; _jumpHeld = false; });
                widget.onJumpRelease();
              },
              child: _JumpButton(
                size: btnSize * 1.2,
                held: _jumpHeld,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── D-pad button (Left / Right) ────────────────────────────────────────────

class _DpadButton extends StatelessWidget {
  final double size;
  final String label;
  final bool held;
  const _DpadButton({required this.size, required this.label, required this.held});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 50),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: held
              ? [const Color(0xFFFFE566), const Color(0xFFB8860B)]
              : [const Color(0xFF3A3A5C), const Color(0xFF1A1A2E)],
        ),
        border: Border.all(
          color: held
              ? const Color(0xFFFFD700)
              : Colors.white.withOpacity(0.22),
          width: held ? 2.5 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: held
                ? const Color(0xFFFFD700).withOpacity(0.5)
                : Colors.black.withOpacity(0.4),
            blurRadius: held ? 16 : 6,
            spreadRadius: held ? 2 : 0,
          ),
        ],
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: held ? Colors.black87 : Colors.white60,
            fontSize: size * 0.36,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// ── Jump button ────────────────────────────────────────────────────────────

class _JumpButton extends StatelessWidget {
  final double size;
  final bool held;
  const _JumpButton({required this.size, required this.held});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 50),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: held
              ? [const Color(0xFFFF8C42), const Color(0xFFBF360C)]
              : [const Color(0xFF3A3A5C), const Color(0xFF1A1A2E)],
        ),
        border: Border.all(
          color: held
              ? const Color(0xFFFF6F00)
              : Colors.white.withOpacity(0.22),
          width: held ? 2.8 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: held
                ? const Color(0xFFFF6F00).withOpacity(0.55)
                : Colors.black.withOpacity(0.4),
            blurRadius: held ? 22 : 6,
            spreadRadius: held ? 4 : 0,
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '▲',
              style: TextStyle(
                color: held ? Colors.white : Colors.white54,
                fontSize: size * 0.28,
                height: 1.1,
              ),
            ),
            Text(
              held ? 'HOLD' : 'JUMP',
              style: TextStyle(
                color: held ? Colors.white : Colors.white38,
                fontSize: size * 0.15,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
