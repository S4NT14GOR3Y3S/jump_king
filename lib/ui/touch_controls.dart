import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class TouchControls extends StatefulWidget {
  final void Function(double dx) onMove;
  final void Function() onJumpStart;
  final void Function() onJumpRelease;
  final void Function(double tilt)? onTilt;

  const TouchControls({
    super.key,
    required this.onMove,
    required this.onJumpStart,
    required this.onJumpRelease,
    this.onTilt,
  });

  @override
  State<TouchControls> createState() => _TouchControlsState();
}

class _TouchControlsState extends State<TouchControls> {
  int? _leftId, _rightId, _jumpId;
  bool _jumpHeld = false;

  double _rawTilt = 0.0;
  double _smoothTilt = 0.0;

  StreamSubscription<AccelerometerEvent>? _accelSub;
  Timer? _tiltTimer;

  @override
  void initState() {
    super.initState();

    // Read accelerometer
    _accelSub = accelerometerEventStream(
      samplingPeriod: SensorInterval.gameInterval,
    ).listen((e) {
      // Landscape: e.x negativo = inclinado a la derecha, positivo = izquierda
      _rawTilt = (-e.x / 4.0).clamp(-1.0, 1.0);
    });

    // Feed tilt to game at 60hz
    _tiltTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!_jumpHeld) return;
      _smoothTilt = _smoothTilt * 0.8 + _rawTilt * 0.2;
      widget.onTilt?.call(_smoothTilt);
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    _tiltTimer?.cancel();
    super.dispose();
  }

  void _setMove() {
    double val = 0;
    if (_leftId != null && _rightId == null) val = -1;
    if (_rightId != null && _leftId == null) val = 1;
    widget.onMove(val);
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final w = mq.size.width;
    final btnSize = (w * 0.13).clamp(56.0, 88.0);
    final bottom = mq.padding.bottom + 16.0;

    return Positioned.fill(
      child: Stack(
        children: [
          // LEFT
          Positioned(
            left: 14, bottom: bottom,
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (e) { if (_leftId != null) return; setState(() => _leftId = e.pointer); _setMove(); },
              onPointerUp: (e) { if (e.pointer != _leftId) return; setState(() => _leftId = null); _setMove(); },
              onPointerCancel: (e) { if (e.pointer != _leftId) return; setState(() => _leftId = null); _setMove(); },
              child: _DpadBtn(size: btnSize, label: '◀', held: _leftId != null),
            ),
          ),

          // RIGHT
          Positioned(
            left: 14 + btnSize + 12, bottom: bottom,
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (e) { if (_rightId != null) return; setState(() => _rightId = e.pointer); _setMove(); },
              onPointerUp: (e) { if (e.pointer != _rightId) return; setState(() => _rightId = null); _setMove(); },
              onPointerCancel: (e) { if (e.pointer != _rightId) return; setState(() => _rightId = null); _setMove(); },
              child: _DpadBtn(size: btnSize, label: '▶', held: _rightId != null),
            ),
          ),

          // JUMP + tilt indicator
          Positioned(
            right: 14, bottom: bottom,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_jumpHeld) ...[
                  _TiltBar(tilt: _smoothTilt),
                  const SizedBox(height: 8),
                ],
                Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: (e) {
                    if (_jumpId != null) return;
                    setState(() { _jumpId = e.pointer; _jumpHeld = true; _smoothTilt = 0; });
                    widget.onJumpStart();
                  },
                  onPointerUp: (e) {
                    if (e.pointer != _jumpId) return;
                    setState(() { _jumpId = null; _jumpHeld = false; });
                    widget.onJumpRelease();
                  },
                  onPointerCancel: (e) {
                    if (e.pointer != _jumpId) return;
                    setState(() { _jumpId = null; _jumpHeld = false; });
                    widget.onJumpRelease();
                  },
                  child: _JumpBtn(size: btnSize * 1.2, held: _jumpHeld),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Barra que muestra hacia dónde apunta el salto
class _TiltBar extends StatelessWidget {
  final double tilt;
  const _TiltBar({required this.tilt});

  @override
  Widget build(BuildContext context) {
    final Color dot = tilt.abs() < 0.15
        ? Colors.greenAccent
        : tilt.abs() < 0.55
            ? Colors.yellowAccent
            : Colors.redAccent;

    return Container(
      width: 96,
      height: 20,
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white24),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // línea central
          Container(width: 1.5, height: 16, color: Colors.white24),
          // punto indicador
          Align(
            alignment: Alignment(tilt.clamp(-0.85, 0.85), 0),
            child: Container(
              width: 16, height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dot,
                boxShadow: [BoxShadow(color: dot.withOpacity(0.6), blurRadius: 6)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DpadBtn extends StatelessWidget {
  final double size;
  final String label;
  final bool held;
  const _DpadBtn({required this.size, required this.label, required this.held});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 45),
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: held
              ? [const Color(0xFFFFE566), const Color(0xFFB8860B)]
              : [const Color(0xFF2A2A45), const Color(0xFF14141E)],
        ),
        border: Border.all(
          color: held ? const Color(0xFFFFD700) : Colors.white24,
          width: held ? 2.5 : 1.5,
        ),
        boxShadow: [BoxShadow(
          color: held ? const Color(0xFFFFD700).withOpacity(0.5) : Colors.black54,
          blurRadius: held ? 18 : 5,
        )],
      ),
      child: Center(
        child: Text(label,
          style: TextStyle(
            color: held ? Colors.black87 : Colors.white54,
            fontSize: size * 0.38,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _JumpBtn extends StatelessWidget {
  final double size;
  final bool held;
  const _JumpBtn({required this.size, required this.held});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 45),
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: held
              ? [const Color(0xFFFF8C42), const Color(0xFFBF360C)]
              : [const Color(0xFF2A2A45), const Color(0xFF14141E)],
        ),
        border: Border.all(
          color: held ? const Color(0xFFFF6F00) : Colors.white24,
          width: held ? 2.8 : 1.5,
        ),
        boxShadow: [BoxShadow(
          color: held ? const Color(0xFFFF6F00).withOpacity(0.55) : Colors.black54,
          blurRadius: held ? 24 : 5,
          spreadRadius: held ? 3 : 0,
        )],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('▲', style: TextStyle(
              color: held ? Colors.white : Colors.white54,
              fontSize: size * 0.28,
              height: 1.1,
            )),
            Text(held ? 'INCLINA' : 'JUMP', style: TextStyle(
              color: held ? Colors.white70 : Colors.white38,
              fontSize: size * 0.13,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            )),
          ],
        ),
      ),
    );
  }
}
