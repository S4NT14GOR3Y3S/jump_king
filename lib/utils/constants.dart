import 'dart:ui';

/// Global constants for Jump King
class JKConstants {
  // Tile & Map
  static const double tileSize = 40.0;
  static const int mapWidth = 16;    // tiles wide
  static const int screenHeightTiles = 12; // tiles visible vertically

  // Physics
  static const double gravity = 1400.0;       // pixels/s²
  static const double maxFallSpeed = 1000.0;
  static const double jumpChargeRate = 650.0; // power per second held
  static const double maxJumpPower = 650.0;
  static const double minJumpPower = 180.0;
  static const double playerMoveSpeed = 130.0;
  static const double playerAirControl = 0.7;  // air movement multiplier
  static const double coyoteTime = 0.08;        // seconds after leaving ledge still can jump

  // Player
  static const double playerWidth = 24.0;
  static const double playerHeight = 36.0;

  // Game
  static const int totalLevels = 5;
  static const double levelHeightPixels = tileSize * 22; // Each level is 22 tiles tall
}

/// Jump King color palette
class JKColors {
  // Sky backgrounds per level
  static const List<Color> skyColors = [
    Color(0xFF1A1A2E),  // Dark purple (dungeon)
    Color(0xFF0D2137),  // Deep blue (underground)
    Color(0xFF162032),  // Dark teal (cave)
    Color(0xFF1F1200),  // Dark orange (volcano)
    Color(0xFF0A0A0A),  // Near black (summit)
  ];

  // Terrain colors per level
  static const List<Color> terrainColors = [
    Color(0xFF5C4033),  // Brown stone
    Color(0xFF1565C0),  // Blue stone
    Color(0xFF2E7D32),  // Green mossy
    Color(0xFF6D1B1B),  // Red volcanic
    Color(0xFFB0BEC5),  // Gray summit
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

  // Player
  static const Color playerBody = Color(0xFF4CAF50);
  static const Color playerCrown = Color(0xFFFFD700);
  static const Color playerEyes = Color(0xFFFFFFFF);
  static const Color playerBoots = Color(0xFF5D4037);
  static const Color playerCape = Color(0xFF9C27B0);

  // Physics/charge
  static const Color chargeBar = Color(0xFFFF6F00);
  static const Color chargeBarBg = Color(0xFF424242);
  static const Color chargeBarFull = Color(0xFFFF1744);
  static const Color chargeArrow = Color(0xFFFFEB3B);

  // UI
  static const Color hudBackground = Color(0xCC1A1A2E);
  static const Color hudBorder = Color(0xFF8B5E3C);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textGold = Color(0xFFFFD700);
  static const Color textGray = Color(0xFF9E9E9E);

  // Menu
  static const Color menuBg = Color(0xFF0D0D1A);
  static const Color menuTitle = Color(0xFFFFD700);
  static const Color menuButton = Color(0xFF4A148C);
  static const Color menuButtonBorder = Color(0xFFFFD700);

  // Effects
  static const Color fallDustColor = Color(0xAAB0BEC5);
  static const Color landDustColor = Color(0xAAD7CCC8);
  static const Color damageFlash = Color(0x55FF0000);
  static const Color victoryGlow = Color(0xAAFFD700);

  // Checkpoints
  static const Color checkpointInactive = Color(0xFF9E9E9E);
  static const Color checkpointActive = Color(0xFFFFEB3B);

  // Platforms
  static const Color iceBlue = Color(0xFF80DEEA);
  static const Color iceBlueDark = Color(0xFF00ACC1);
  static const Color crumbleColor = Color(0xFFFF8F00);
  static const Color crumbleDark = Color(0xFFE65100);
  static const Color spikeColor = Color(0xFFBDBDBD);
  static const Color spikeShine = Color(0xFFEEEEEE);
  static const Color windColor = Color(0x4400BCD4);
}

/// Tile types
enum TileType {
  empty,
  solid,         // Normal solid tile
  platform,      // One-way platform (can jump through from below)
  ice,           // Slippery platform
  crumble,       // Falls after player stands on it
  spike,         // Kills player (fall to last checkpoint)
  checkpoint,    // Saves progress
  goal,          // End of game / level transition
  wind,          // Pushes player horizontally
}

/// Player states
enum PlayerState {
  idle,
  running,
  charging,   // Holding jump button, building charge
  jumping,
  falling,
  landing,    // Brief landing animation
  hurt,       // Hit spikes, falling back
}

/// Game states
enum GameState {
  menu,
  playing,
  paused,
  victory,
  credits,
}
