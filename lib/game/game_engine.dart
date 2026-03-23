import 'dart:math';
import '../utils/constants.dart';
import '../utils/audio_manager.dart';
import 'player.dart';
import 'game_map.dart';
import 'levels.dart';
import 'collision.dart';

class GameEngine {
  GameState state = GameState.menu;
  late Player player;
  late GameMap currentMap;
  late CollisionSystem collision;

  int currentLevel = 0;
  double totalTime = 0.0;
  bool checkpointFlash = false;
  double checkpointFlashTimer = 0.0;

  // Particles
  List<DustParticle> particles = [];
  final Random _rng = Random();

  final AudioManager audio = AudioManager();

  GameEngine() {
    player = Player(x: 0, y: 0);
    _loadLevel(0);
  }

  void _loadLevel(int index) {
    currentLevel = index;
    currentMap = Levels.getLevel(index);
    collision = CollisionSystem(currentMap);
    particles.clear();

    // Spawn player
    player.reset(
      Levels.getLevel(index).level.playerSpawnX,
      Levels.getLevel(index).level.playerSpawnY,
    );
  }

  void startNewGame() {
    currentLevel = 0;
    totalTime = 0;
    particles.clear();
    player.fullReset(
      Levels.getLevel(0).level.playerSpawnX,
      Levels.getLevel(0).level.playerSpawnY,
    );
    _loadLevel(0);
    state = GameState.playing;
    audio.playGameMusic(0);
  }

  void update(double dt) {
    if (state != GameState.playing) return;

    totalTime += dt;

    // Flash timer
    if (checkpointFlashTimer > 0) {
      checkpointFlashTimer -= dt;
      checkpointFlash = (checkpointFlashTimer * 6).floor().isEven;
      if (checkpointFlashTimer <= 0) checkpointFlash = false;
    }

    // Update crumble tiles
    currentMap.update(dt);

    // Wind force
    double windForce = collision.getWindForce(player);

    // Update player
    player.update(dt);

    // Apply wind in air
    if (!player.isGrounded && !player.isHurt) {
      player.vx += windForce * dt;
      player.vx = player.vx.clamp(-300, 300);
    }

    // Resolve collisions
    if (!player.isHurt) {
      CollisionResult result = collision.resolve(player);

      if (result.hitSpike) {
        player.hitSpike();
        audio.playHurt();
        _spawnHurtParticles();
      }

      if (result.hitCheckpoint) {
        bool isNew = (result.checkpointX != player.checkpointX ||
            result.checkpointY != player.checkpointY);
        if (isNew) {
          player.setCheckpoint(result.checkpointX, result.checkpointY, currentLevel);
          audio.playCheckpoint();
          checkpointFlashTimer = 1.5;
          checkpointFlash = true;
        }
      }

      if (result.hitGoal) {
        _onLevelComplete();
      }
    }

    // Clamp player to map horizontal bounds
    player.x = player.x.clamp(JKConstants.tileSize, // 1 tile from left wall
        currentMap.pixelWidth - player.width - JKConstants.tileSize);

    // If player falls below map, respawn at checkpoint
    if (player.y > currentMap.pixelHeight + 100) {
      player.hitSpike(); // treat falling off as death
    }

    // Spawn landing dust
    if (player.state == PlayerState.landing && player.dustTimer > 0.25) {
      _spawnLandDust(player.x + player.width / 2, player.y + player.height);
      player.dustTimer = 0.0; // prevent repeated spawns
    }

    // Update particles
    for (var p in particles) p.update(dt);
    particles.removeWhere((p) => !p.isActive);
  }

  void _onLevelComplete() {
    if (currentLevel + 1 >= JKConstants.totalLevels) {
      state = GameState.victory;
      audio.playVictory();
    } else {
      currentLevel++;
      currentMap = Levels.getLevel(currentLevel);
      collision = CollisionSystem(currentMap);
      particles.clear();
      player.reset(
        Levels.getLevel(currentLevel).level.playerSpawnX,
        Levels.getLevel(currentLevel).level.playerSpawnY,
      );
      player.setCheckpoint(
        Levels.getLevel(currentLevel).level.playerSpawnX,
        Levels.getLevel(currentLevel).level.playerSpawnY,
        currentLevel,
      );
      audio.playGameMusic(currentLevel);
    }
  }

  void _spawnLandDust(double x, double y) {
    for (int i = 0; i < 6; i++) {
      double angle = pi + _rng.nextDouble() * pi; // downward spread
      double speed = 30 + _rng.nextDouble() * 60;
      particles.add(DustParticle(
        x: x + (_rng.nextDouble() - 0.5) * 16,
        y: y,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed - 20,
        lifetime: 0.3 + _rng.nextDouble() * 0.2,
        size: 3 + _rng.nextDouble() * 3,
        isDeath: false,
      ));
    }
  }

  void _spawnHurtParticles() {
    for (int i = 0; i < 10; i++) {
      double angle = _rng.nextDouble() * 2 * pi;
      double speed = 50 + _rng.nextDouble() * 100;
      particles.add(DustParticle(
        x: player.centerX,
        y: player.centerY,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed,
        lifetime: 0.4 + _rng.nextDouble() * 0.3,
        size: 4 + _rng.nextDouble() * 4,
        isDeath: true,
      ));
    }
  }

  String get formattedTime {
    int minutes = totalTime ~/ 60;
    int seconds = totalTime.toInt() % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

class DustParticle {
  double x, y, vx, vy;
  double lifetime, maxLifetime, size;
  bool isActive, isDeath;

  DustParticle({
    required this.x, required this.y,
    required this.vx, required this.vy,
    required this.lifetime, required this.size,
    required this.isDeath,
  }) : maxLifetime = lifetime, isActive = true;

  double get alpha => (lifetime / maxLifetime).clamp(0, 1);

  void update(double dt) {
    if (!isActive) return;
    x += vx * dt;
    y += vy * dt;
    vy += 200 * dt; // gravity on dust
    vx *= 0.92;
    lifetime -= dt;
    if (lifetime <= 0) isActive = false;
  }
}
