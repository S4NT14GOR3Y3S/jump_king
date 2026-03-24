import 'dart:ui';

class JKConstants {
  static const double tileSize = 40.0;
  static const int mapWidth = 16;
  static const int screenHeightTiles = 12;

  // Física rebalanceada para que el juego sea jugable
  static const double gravity = 900.0;        // menos gravedad = más tiempo en el aire
  static const double maxFallSpeed = 900.0;
  static const double jumpChargeRate = 900.0; // carga más rápido
  static const double maxJumpPower = 900.0;   // salto máximo más alto
  static const double minJumpPower = 200.0;
  static const double playerMoveSpeed = 150.0;
  static const double playerAirControl = 0.55; // menos control en el aire (más auténtico)
  static const double coyoteTime = 0.10;

  static const double playerWidth = 24.0;
  static const double playerHeight = 36.0;

  static const int totalLevels = 5;
  static const double levelHeightPixels = tileSize * 22;

  // Rebote en paredes (0 = sin rebote, 1 = rebote total)
  static const double wallBounce = 0.35;
}

class JKColors {
  static const List<Color> skyColors = [
    Color(0xFF1A1A2E),
    Color(0xFF0D2137),
    Color(0xFF162032),
    Color(0xFF1F1200),
    Color(0xFF0A0A0A),
  ];

  static const List<Color> terrainColors = [
    Color(0xFF5C4033),
    Color(0xFF1565C0),
    Color(0xFF2E7D32),
    Color(0xFF6D1B1B),
    Color(0xFFB0BEC5),
  ];

  static const List<Color> terrainDarkColors = [
    Color(0xFF3E2723),
    Color(0xFF0D47A1),
    Color(0xFF1B5E20),
    Color(0xFF4A0000),
    Color(0xFF78909C),
  ];

  static const List<Color> platformColors = [
    Color(0xFF795548),
    Color(0xFF1976D2),
    Color(0xFF388E3C),
    Color(0xFFD32F2F),
    Color(0xFF90A4AE),
  ];

  static const Color playerBody = Color(0xFF4CAF50);
  static const Color playerCrown = Color(0xFFFFD700);
  static const Color playerEyes = Color(0xFFFFFFFF);
  static const Color playerBoots = Color(0xFF5D4037);
  static const Color playerCape = Color(0xFF9C27B0);

  static const Color chargeBar = Color(0xFFFF6F00);
  static const Color chargeBarBg = Color(0xFF424242);
  static const Color chargeBarFull = Color(0xFFFF1744);
  static const Color chargeArrow = Color(0xFFFFEB3B);

  static const Color hudBackground = Color(0xCC1A1A2E);
  static const Color hudBorder = Color(0xFF8B5E3C);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textGold = Color(0xFFFFD700);
  static const Color textGray = Color(0xFF9E9E9E);

  static const Color menuBg = Color(0xFF0D0D1A);
  static const Color menuTitle = Color(0xFFFFD700);
  static const Color menuButton = Color(0xFF4A148C);
  static const Color menuButtonBorder = Color(0xFFFFD700);

  static const Color fallDustColor = Color(0xAAB0BEC5);
  static const Color landDustColor = Color(0xAAD7CCC8);
  static const Color damageFlash = Color(0x55FF0000);
  static const Color victoryGlow = Color(0xAAFFD700);

  static const Color checkpointInactive = Color(0xFF9E9E9E);
  static const Color checkpointActive = Color(0xFFFFEB3B);

  static const Color iceBlue = Color(0xFF80DEEA);
  static const Color iceBlueDark = Color(0xFF00ACC1);
  static const Color crumbleColor = Color(0xFFFF8F00);
  static const Color crumbleDark = Color(0xFFE65100);
  static const Color spikeColor = Color(0xFFBDBDBD);
  static const Color spikeShine = Color(0xFFEEEEEE);
  static const Color windColor = Color(0x4400BCD4);
}

enum TileType {
  empty,
  solid,
  platform,
  ice,
  crumble,
  spike,
  checkpoint,
  goal,
  wind,
}

enum PlayerState {
  idle,
  running,
  charging,
  jumping,
  falling,
  landing,
  hurt,
}

enum GameState {
  menu,
  playing,
  paused,
  victory,
  credits,
}
