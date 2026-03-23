import '../utils/constants.dart';

/// A crumbling tile instance (runtime state)
class CrumbleTile {
  final int col;
  final int row;
  final int levelIndex;
  double crumbleTimer; // counts down from 0.4 to 0 then collapses
  bool collapsed;
  double respawnTimer;

  CrumbleTile({
    required this.col,
    required this.row,
    required this.levelIndex,
    this.crumbleTimer = 0.5,
    this.collapsed = false,
    this.respawnTimer = 4.0,
  });
}

/// A wind zone (pushes player)
class WindZone {
  final double x, y, w, h;
  final double force; // positive = right, negative = left
  const WindZone({required this.x, required this.y, required this.w, required this.h, required this.force});
}

/// One level's map data
class GameLevel {
  final int index;
  final List<List<TileType>> tiles; // tiles[row][col]
  final double playerSpawnX;
  final double playerSpawnY;
  final double exitX;   // tile col of exit
  final double exitY;   // tile row of exit
  final String name;
  final List<WindZone> windZones;

  const GameLevel({
    required this.index,
    required this.tiles,
    required this.playerSpawnX,
    required this.playerSpawnY,
    required this.exitX,
    required this.exitY,
    required this.name,
    this.windZones = const [],
  });

  int get width => tiles.isNotEmpty ? tiles[0].length : 0;
  int get height => tiles.length;

  double get pixelWidth => width * JKConstants.tileSize;
  double get pixelHeight => height * JKConstants.tileSize;

  TileType getTile(int col, int row) {
    if (row < 0 || row >= height || col < 0 || col >= width) {
      return TileType.solid; // Out of bounds = solid wall
    }
    return tiles[row][col];
  }

  bool isSolid(int col, int row) {
    final t = getTile(col, row);
    return t == TileType.solid || t == TileType.ice || t == TileType.crumble;
  }

  bool isPlatform(int col, int row) => getTile(col, row) == TileType.platform;
  bool isIce(int col, int row) => getTile(col, row) == TileType.ice;
  bool isCrumble(int col, int row) => getTile(col, row) == TileType.crumble;
  bool isSpike(int col, int row) => getTile(col, row) == TileType.spike;
  bool isCheckpoint(int col, int row) => getTile(col, row) == TileType.checkpoint;
  bool isGoal(int col, int row) => getTile(col, row) == TileType.goal;
  bool isWind(int col, int row) => getTile(col, row) == TileType.wind;
}

/// Runtime map state (manages crumble tiles)
class GameMap {
  final GameLevel level;
  final List<CrumbleTile> crumbleTiles = [];
  // Copy of tiles so we can modify crumble state
  late List<List<TileType>> runtimeTiles;

  GameMap(this.level) {
    // Deep copy tiles
    runtimeTiles = level.tiles.map((row) => List<TileType>.from(row)).toList();
  }

  int get width => level.width;
  int get height => level.height;
  double get pixelWidth => level.pixelWidth;
  double get pixelHeight => level.pixelHeight;
  int get index => level.index;
  String get name => level.name;
  List<WindZone> get windZones => level.windZones;

  TileType getTile(int col, int row) {
    if (row < 0 || row >= height || col < 0 || col >= width) return TileType.solid;
    return runtimeTiles[row][col];
  }

  bool isSolid(int col, int row) {
    final t = getTile(col, row);
    return t == TileType.solid || t == TileType.ice;
  }

  bool isCrumbleCollapsible(int col, int row) {
    return getTile(col, row) == TileType.crumble;
  }

  bool isPlatform(int col, int row) => getTile(col, row) == TileType.platform;
  bool isIce(int col, int row) => getTile(col, row) == TileType.ice;
  bool isSpike(int col, int row) => getTile(col, row) == TileType.spike;
  bool isCheckpoint(int col, int row) => getTile(col, row) == TileType.checkpoint;
  bool isGoal(int col, int row) => getTile(col, row) == TileType.goal;
  bool isWind(int col, int row) => getTile(col, row) == TileType.wind;

  void triggerCrumble(int col, int row) {
    // Check already tracked
    for (var ct in crumbleTiles) {
      if (ct.col == col && ct.row == row && !ct.collapsed) return;
    }
    crumbleTiles.add(CrumbleTile(col: col, row: row, levelIndex: level.index));
  }

  void update(double dt) {
    for (var ct in crumbleTiles) {
      if (!ct.collapsed) {
        ct.crumbleTimer -= dt;
        if (ct.crumbleTimer <= 0) {
          ct.collapsed = true;
          runtimeTiles[ct.row][ct.col] = TileType.empty;
          ct.respawnTimer = 4.0;
        }
      } else {
        ct.respawnTimer -= dt;
        if (ct.respawnTimer <= 0) {
          ct.collapsed = false;
          ct.crumbleTimer = 0.5;
          runtimeTiles[ct.row][ct.col] = TileType.crumble;
        }
      }
    }
    crumbleTiles.removeWhere((ct) => ct.collapsed && ct.respawnTimer <= 0 && ct.crumbleTimer > 0 && !ct.collapsed);
  }

  double getCrumbleFraction(int col, int row) {
    for (var ct in crumbleTiles) {
      if (ct.col == col && ct.row == row && !ct.collapsed) {
        return 1.0 - (ct.crumbleTimer / 0.5);
      }
    }
    return 0.0;
  }
}
