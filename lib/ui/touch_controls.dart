import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Controles:
/// - Botón JUMP (derecha): mantener = cargar potencia, soltar = saltar
/// - Giroscopio: inclinar teléfono izquierda/derecha mientras cargas = dirección
/// - Sin flechas: el movimiento en suelo también usa el giroscopio
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
  int? _jumpId;
  bool _jumpHeld = false;

  double _rawTilt  = 0.0;
  double _smoothTilt = 0.0;

  StreamSubscription<AccelerometerEvent>? _accelSub;
  Timer? _tiltTimer;

  @override
  void initState() {
    super.initState();

    _accelSub = accelerometerEventStream(
      samplingPeriod: SensorInterval.gameInterval,
    ).listen((e) {
      // En landscape (horizontal): el eje Y del acelerómetro controla la inclinación
      // e.y > 0 = inclinado a la izquierda, e.y < 0 = inclinado a la derecha
      // Normalizamos con ±5 m/s² como deflexión máxima
      _rawTilt = (-e.y / 5.0).clamp(-1.0, 1.0);
    });

    // Feed al juego a 60fps
    _tiltTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      // Suavizado exponencial
      _smoothTilt = _smoothTilt * 0.75 + _rawTilt * 0.25;

      // Movimiento en suelo también guiado por giroscopio
      if (_jumpHeld) {
        widget.onTilt?.call(_smoothTilt);
      } else {
        // Caminar con giroscopio cuando no está saltando
        // Solo activa si la inclinación supera un umbral
        double walkTilt = _smoothTilt.abs() > 0.2 ? _smoothTilt : 0.0;
        widget.onMove(walkTilt);
      }

      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    _tiltTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq  = MediaQuery.of(context);
    final w   = mq.size.width;
    final h   = mq.size.height;
    final btnSize  = (h * 0.28).clamp(70.0, 110.0);
    final bottom   = mq.padding.bottom + 20.0;

    return Positioned.fill(
      child: Stack(
        children: [
          // ── Indicador de inclinación (barra central inferior) ──
          Positioned(
            bottom: bottom + btnSize + 12,
            left: 0, right: 0,
            child: Center(child: _TiltBar(tilt: _smoothTilt, active: _jumpHeld)),
          ),

          // ── Botón JUMP (único botón de acción) ─────────────────
          Positioned(
            right: 20,
            bottom: bottom,
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (e) {
                if (_jumpId != null) return;
                setState(() { _jumpId = e.pointer; _jumpHeld = true; });
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
              child: _JumpBtn(size: btnSize, held: _jumpHeld, tilt: _smoothTilt),
            ),
          ),

          // ── Hint de giroscopio (solo al inicio, desaparece) ────
          Positioned(
            left: 20,
            bottom: bottom,
            child: _GyroHint(jumpHeld: _jumpHeld),
          ),
        ],
      ),
    );
  }
}

// ── Barra de inclinación ───────────────────────────────────────────────────

class _TiltBar extends StatelessWidget {
  final double tilt;
  final bool active;
  const _TiltBar({required this.tilt, required this.active});

  @override
  Widget build(BuildContext context) {
    final Color dotColor = tilt.abs() < 0.15
        ? Colors.greenAccent
        : tilt.abs() < 0.55
            ? Colors.yellowAccent
            : Colors.redAccent;

    return AnimatedOpacity(
      opacity: active ? 1.0 : 0.35,
      duration: const Duration(milliseconds: 200),
      child: Container(
        width: 160,
        height: 22,
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: Colors.white24),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Fondo de dirección
            if (tilt.abs() > 0.1)
              Align(
                alignment: tilt < 0 ? Alignment.centerLeft : Alignment.centerRight,
                child: Container(
                  width: (tilt.abs() * 75).clamp(0, 75),
                  height: 22,
                  decoration: BoxDecoration(
                    color: dotColor.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
              ),
            // Línea central
            Container(width: 2, height: 18, color: Colors.white30),
            // Punto indicador
            Align(
              alignment: Alignment(tilt.clamp(-0.82, 0.82), 0),
              child: Container(
                width: 18, height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dotColor,
                  boxShadow: [BoxShadow(color: dotColor.withOpacity(0.7), blurRadius: 8)],
                ),
              ),
            ),
            // Etiqueta dirección
            Positioned(
              top: 2,
              child: Text(
                tilt < -0.15 ? '◀ IZQ' : tilt > 0.15 ? 'DER ▶' : '▲ ARRIBA',
                style: const TextStyle(color: Colors.white60, fontSize: 7, letterSpacing: 0.5, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Botón JUMP ─────────────────────────────────────────────────────────────

class _JumpBtn extends StatelessWidget {
  final double size;
  final bool held;
  final double tilt;
  const _JumpBtn({required this.size, required this.held, required this.tilt});

  @override
  Widget build(BuildContext context) {
    // El botón se inclina visualmente según el giroscopio
    double rotation = held ? tilt * 0.25 : 0;

    return Transform.rotate(
      angle: rotation,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 50),
        width: size, height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: held
                ? [const Color(0xFFFF8C42), const Color(0xFFBF360C)]
                : [const Color(0xFF2A2A48), const Color(0xFF14141E)],
          ),
          border: Border.all(
            color: held ? const Color(0xFFFF6F00) : Colors.white24,
            width: held ? 3.0 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: held ? const Color(0xFFFF6F00).withOpacity(0.6) : Colors.black54,
              blurRadius: held ? 28 : 6,
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
                  fontSize: size * 0.30,
                  height: 1.0,
                ),
              ),
              Text(
                held ? 'INCLINA' : 'JUMP',
                style: TextStyle(
                  color: held ? Colors.white70 : Colors.white38,
                  fontSize: size * 0.13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Hint lateral con instrucciones ──────────────────────────────────────────

class _GyroHint extends StatelessWidget {
  final bool jumpHeld;
  const _GyroHint({required this.jumpHeld});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: jumpHeld ? 0.0 : 0.6,
      duration: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black45,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('📱 Inclina para moverte', style: TextStyle(color: Colors.white70, fontSize: 11)),
            SizedBox(height: 4),
            Text('▲ Mantén JUMP + inclina', style: TextStyle(color: Colors.white70, fontSize: 11)),
            SizedBox(height: 2),
            Text('   para apuntar el salto', style: TextStyle(color: Colors.white38, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
