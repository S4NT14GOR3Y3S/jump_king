import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'game/game_engine.dart';
import 'rendering/game_renderer.dart';
import 'ui/hud.dart';
import 'ui/touch_controls.dart';
import 'ui/main_menu.dart';
import 'ui/victory_screen.dart';
import 'utils/constants.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const JumpKingApp());
}

class JumpKingApp extends StatelessWidget {
  const JumpKingApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jump King',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: JKColors.menuBg),
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  late GameEngine engine;
  late Ticker _ticker;
  Duration _lastTick = Duration.zero;
  double _totalTime = 0;

  bool _keyLeft = false;
  bool _keyRight = false;
  bool _keyJump = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    engine = GameEngine();
    _ticker = createTicker(_onTick);
    _ticker.start();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  void _onTick(Duration elapsed) {
    if (_lastTick == Duration.zero) { _lastTick = elapsed; return; }
    double dt = (elapsed - _lastTick).inMicroseconds / 1000000.0;
    _lastTick = elapsed;
    if (dt > 0.05) dt = 0.05;

    if (engine.state == GameState.playing) {
      double move = 0;
      if (_keyLeft) move -= 1;
      if (_keyRight) move += 1;
      engine.player.moveInput = move;
    }

    _totalTime += dt;
    engine.update(dt);
    setState(() {});
  }

  void _handleKeyEvent(KeyEvent event) {
    if (engine.state != GameState.playing) return;
    final isDown = event is KeyDownEvent;
    final isUp = event is KeyUpEvent;
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft || event.logicalKey == LogicalKeyboardKey.keyA) {
      if (isDown) _keyLeft = true; if (isUp) _keyLeft = false;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight || event.logicalKey == LogicalKeyboardKey.keyD) {
      if (isDown) _keyRight = true; if (isUp) _keyRight = false;
    }
    if (event.logicalKey == LogicalKeyboardKey.space || event.logicalKey == LogicalKeyboardKey.arrowUp || event.logicalKey == LogicalKeyboardKey.keyW) {
      if (isDown && !_keyJump) { _keyJump = true; engine.player.startCharge(); }
      if (isUp && _keyJump) { _keyJump = false; engine.player.releaseJump(); }
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _focusNode.dispose();
    engine.audio.dispose();
    super.dispose();
  }

  void _onMove(double dx) => engine.player.moveInput = dx;
  void _onJumpStart() => engine.player.startCharge();
  void _onJumpRelease() => engine.player.releaseJump();

  // Gyroscope tilt -1..1 → chargeAngle while charging
  void _onTilt(double tilt) {
    if (engine.state == GameState.playing && engine.player.isCharging) {
      engine.player.chargeAngle = -pi / 2 + tilt * (pi / 3);
    }
  }

  void _startNewGame() {
    engine.startNewGame();
    _focusNode.requestFocus();
    setState(() {});
  }

  void _goToMenu() {
    engine.state = GameState.menu;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        body: Stack(
          children: [
            if (engine.state == GameState.menu)
              MainMenuScreen(onStartGame: _startNewGame),

            if (engine.state == GameState.playing || engine.state == GameState.victory) ...[
              Positioned.fill(
                child: CustomPaint(
                  painter: GameRenderer(engine: engine, time: _totalTime),
                  child: const SizedBox.expand(),
                ),
              ),
              if (engine.state == GameState.playing)
                HudOverlay(engine: engine),
              if (engine.state == GameState.playing)
                TouchControls(
                  onMove: _onMove,
                  onJumpStart: _onJumpStart,
                  onJumpRelease: _onJumpRelease,
                  onTilt: _onTilt,
                ),
            ],

            if (engine.state == GameState.victory)
              VictoryScreen(engine: engine, onRestart: _startNewGame, onMenu: _goToMenu),
          ],
        ),
      ),
    );
  }
}
