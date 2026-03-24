import '../utils/constants.dart';
import 'game_map.dart';

const _ = TileType.empty;
const W = TileType.solid;
const P = TileType.platform;
const I = TileType.ice;
const C = TileType.crumble;
const S = TileType.spike;
const K = TileType.checkpoint;
const G = TileType.goal;
const N = TileType.wind;

class Levels {
  static GameMap getLevel(int index) {
    switch (index) {
      case 0: return GameMap(_level0);
      case 1: return GameMap(_level1);
      case 2: return GameMap(_level2);
      case 3: return GameMap(_level3);
      case 4: return GameMap(_level4);
      default: return GameMap(_level0);
    }
  }

  // ── LEVEL 0 — The Dungeon (tutorial) ──────────────────────────
  // Plataformas más cercanas, camino claro de abajo hacia arriba
  static const GameLevel _level0 = GameLevel(
    index: 0,
    name: 'The Dungeon',
    playerSpawnX: 7 * 40.0,
    playerSpawnY: 19 * 40.0,
    exitX: 7,
    exitY: 0,
    tiles: [
      // row 0 (top) — meta
      [W,W,W,W,W,W,W,G,G,W,W,W,W,W,W,W],
      // row 1
      [W,_,_,_,_,_,_,_,_,_,_,_,_,_,_,W],
      // row 2 — plataforma ancha cerca de la meta
      [W,_,_,P,P,P,P,_,_,P,P,P,P,_,_,W],
      // row 3
      [W,_,_,_,_,_,_,_,_,_,_,_,_,_,_,W],
      // row 4 — plataformas laterales
      [W,_,P,P,_,_,_,_,_,_,_,P,P,_,_,W],
      // row 5
      [W,_,_,_,_,_,_,_,_,_,_,_,_,_,_,W],
      // row 6 — plataforma central
      [W,_,_,_,_,P,P,P,P,P,_,_,_,_,_,W],
      // row 7
      [W,_,_,_,_,_,_,_,_,_,_,_,_,_,_,W],
      // row 8 — plataformas escalonadas
      [W,_,P,P,_,_,_,_,_,_,P,P,_,_,_,W],
      // row 9
      [W,_,_,_,_,_,_,_,_,_,_,_,_,_,_,W],
      // row 10 — checkpoint + plataformas de hielo
      [W,_,_,_,_,I,I,K,I,I,_,_,_,_,_,W],
      // row 11
      [W,_,_,_,_,_,_,_,_,_,_,_,_,_,_,W],
      // row 12 — plataformas laterales con gap
      [W,_,P,P,P,_,_,_,_,_,P,P,P,_,_,W],
      // row 13
      [W,_,_,_,_,_,_,_,_,_,_,_,_,_,_,W],
      // row 14 — bloques que se rompen
      [W,_,_,_,C,C,C,_,_,C,C,C,_,_,_,W],
      // row 15
      [W,_,_,_,_,_,_,_,_,_,_,_,_,_,_,W],
      // row 16 — plataforma amplia baja
      [W,_,_,P,P,P,P,P,P,P,_,_,_,_,_,W],
      // row 17
      [W,_,_,_,_,_,_,_,_,_,_,_,_,_,_,W],
      // row 18 — pinchos centrales, espacio para esquivar
      [W,_,_,_,_,_,S,S,S,_,_,_,_,_,_,W],
      // row 19 — suelo con espacio spawn
      [W,_,_,_,_,_,_,_,_,_,_,_,_,_,_,W],
      // row 20 — plataforma baja para empezar
      [W,_,_,P,P,P,P,P,P,P,P,P,_,_,_,W],
      // row 21 — suelo
      [W,W,W,W,W,W,W,W,W,W,W,W,W,W,W,W],
    ],
  );

  // ── LEVEL 1 — The Caverns ──────────────────────────────────────
  static const GameLevel _level1 = GameLevel(
    index: 1,
    name: 'The Caverns',
    playerSpawnX: 7 * 40.0,
    playerSpawnY: 19 * 40.0,
    exitX: 7,
    exitY: 0,
    tiles: [
      [W,W,W,W,W,W,W,G,G,W,W,W,W,W,W,W],
      [W,_,_,_,_,_,_,_,_,_,_,_,_,_,_,W],
      [W,_,_,I,I,I,_,_,_,I,I,I,_,_,_,W],
      [W,_,_,_,_,_,_,_,_,_,_,_,_,_,_,W],
      [W,_,_,_,_,P,P,_,P,P,_,_,_,_,_,W],
      [W,_,_,_,_,_,_,_,_,_,_,_,_,_,_,W],
      [W,_,_,P,P,_,_,_,_,_,P,P,_,_,_,W],
      [W,_,_,_,_,_,_,_,_,_,_,_,_,_,_,W],
      [W,_,_,_,_,_,K,_,_,_,_,_,_,_,_,W],
      [W,W,W,_,_,_,_,_,_,_,_,W,W,W,W,W],
      [W,_,_,_,_,_,_,_,_,_,_,_,_,_,_,W],
      [W,_,C,C,_,_,_,_,_,_,C,C,_,_,_,W],
      [W,_,_,_,_,_,_,_,_,_,_,_,_,_,_,W],
      [W,_,_,_,P,P,_,S,S,_,P,P,_,_,_,W],
      [W,_,_,_,_,_,_,_,_,_,_,_,_,_,_,W],
      [W,_,_,P,_,_,_,_,_,_,_,P,_,_,_,W],
      [W,_,_,_,_,_,_,_,_,_,_,_,_,_,_,W],
      [W,_,_,_,_,S,S,_,S,S,_,_,_,_,_,W],
      [W,_,_,_,_,_,_,_,_,_,_,_,_,_,_,W],
      [W,_,_,_,_,_,_,_,_,_,_,_,_,_,_,W],
      [W,_,P,P,P,P,P,P,P,P,P,P,P,_,_,W],
      [W,W,W,W,W,W,W,W,W,W,W,W,W,W,W,W],
    ],
  );

  // ── LEVEL 2 — The Mossy Ruins ──────────────────────────────────
  static const GameLevel _level2 = GameLevel(
    index: 2,
    name: 'The Mossy Ruins',
    playerSpawnX: 6 * 40.0,
    playerSpawnY: 19 * 40.0,
    exitX: 7,
    exitY: 0,
    tiles: [
      [W,W,W,W,W,W,W,G,G,W,W,W,W,W,W,W],
      [W,_,_,_,_,_,_,_,_,_,_,_,_,_,_,W],
      [W,_,_,P,P,_,K,_,_,P,P,_,_,_,_,W],
      [W,_,_,_,_,_,_,_,_,_,_,_,_,_,_,W],
      [W,_,C,C,_,_,_,_,_,_,C,C,_,_,_,W],
      [W,_,_,_,_,_,_,_,_,_,_,_,_,_,_,W],
      [W,_,_,_,I,I,_,_,_,I,I,_,_,_,_,W],
      [W,_,_,_,_,_,_,_,_,_,_,_,_,_,_,W],
      [W,_,_,_,_,_,_,_,_,_,_,_,_,_,_,W],
      [W,W,W,W,_,_,_,_,_,_,W,W,W,W,W,W],
      [W,_,_,_,_,_,_,_,_,_,_,_,_,_,_,W],
      [W,_,_,_,P,P,_,_,_,P,P,_,_,_,_,W],
      [W,_,_,_,_,_,_,_,_,_,_,_,_,_,_,W],
      [W,_,_,N,N,N,N,_,N,N,N,N,_,_,_,W],
      [W,_,_,_,_,_,_,_,_,_,_,_,_,_,_,W],
      [W,_,P,_,_,_,_,_,_,_,_,P,_,_,_,W],
      [W,_,_,_,_,_,_,_,_,_,_,_,_,_,_,W],
      [W,_,_,_,_,S,S,S,S,S,_,_,_,_,_,W],
      [W,_,_,_,_,_,_,_,_,_,_,_,_,_,_,W],
      [W,_,_,_,_,_,_,_,_,_,_,_,_,_,_,W],
      [W,_,P,P,P,P,P,P,P,P,P,P,_,_,_,W],
      [W,W,W,W,W,W,W,W,W,W,W,W,W,W,W,W],
    ],
    windZones: [
      WindZone(x: 3*40, y: 13*40, w: 4*40, h: 40, force: -130),
      WindZone(x: 8*40, y: 13*40, w: 4*40, h: 40, force: 130),
    ],
  );

  // ── LEVEL 3 — The Volcanic Peaks ───────────────────────────────
  static const GameLevel _level3 = GameLevel(
    index: 3,
    name: 'The Volcanic Peaks',
    playerSpawnX: 7 * 40.0,
    playerSpawnY: 19 * 40.0,
    exitX: 7,
    exitY: 0,
    tiles: [
      [W,W,W,W,W,W,W,G,G,W,W,W,W,W,W,W],
      [W,_,_,_,_,_,_,_,_,_,_,_,_,_,_,W],
      [W,_,C,C,_,_,_,_,_,_,C,C,_,_,_,W],
      [W,_,_,_,_,_,_,_,_,_,_,_,_,_,_,W],
      [W,_,_,_,I,I,_,_,I,I,_,_,_,_,_,W],
      [W,_,_,_,_,_,_,_,_,_,_,_,_,_,_,W],
      [W,_,_,_,K,_,_,_,_,_,_,_,_,_,_,W],
      [W,W,W,W,W,_,_,_,_,W,W,W,W,W,W,W],
      [W,_,_,_,_,_,_,_,_,_,_,_,_,_,_,W],
      [W,_,_,P,P,_,_,_,_,P,P,_,_,_,_,W],
      [W,_,_,_,_,_,_,_,_,_,_,_,_,_,_,W],
      [W,_,P,_,_,_,S,S,S,_,_,P,_,_,_,W],
      [W,_,_,_,_,_,_,_,_,_,_,_,_,_,_,W],
      [W,_,_,_,N,N,N,_,N,N,N,_,_,_,_,W],
      [W,_,_,_,_,_,_,_,_,_,_,_,_,_,_,W],
      [W,_,_,I,I,_,_,_,_,I,I,_,_,_,_,W],
      [W,_,_,_,_,_,_,_,_,_,_,_,_,_,_,W],
      [W,_,_,_,_,S,S,_,S,S,_,_,_,_,_,W],
      [W,_,_,_,_,_,_,_,_,_,_,_,_,_,_,W],
      [W,_,_,_,_,_,_,_,_,_,_,_,_,_,_,W],
      [W,_,P,P,P,P,P,P,P,P,P,P,_,_,_,W],
      [W,W,W,W,W,W,W,W,W,W,W,W,W,W,W,W],
    ],
    windZones: [
      WindZone(x: 4*40, y: 13*40, w: 3*40, h: 40, force: 160),
      WindZone(x: 8*40, y: 13*40, w: 3*40, h: 40, force: -160),
    ],
  );

  // ── LEVEL 4 — The Summit ───────────────────────────────────────
  static const GameLevel _level4 = GameLevel(
    index: 4,
    name: 'The Summit',
    playerSpawnX: 7 * 40.0,
    playerSpawnY: 19 * 40.0,
    exitX: 7,
    exitY: 0,
    tiles: [
      [W,W,W,W,W,W,W,G,G,W,W,W,W,W,W,W],
      [W,_,_,_,_,_,_,_,_,_,_,_,_,_,_,W],
      [W,_,C,_,C,_,_,_,_,C,_,C,_,_,_,W],
      [W,_,_,_,_,_,_,_,_,_,_,_,_,_,_,W],
      [W,_,_,I,_,_,_,_,_,_,I,_,_,_,_,W],
      [W,_,_,_,_,_,_,_,_,_,_,_,_,_,_,W],
      [W,_,_,_,_,_,K,_,_,_,_,_,_,_,_,W],
      [W,W,_,_,_,_,_,_,_,_,_,W,W,W,W,W],
      [W,_,_,_,_,_,_,_,_,_,_,_,_,_,_,W],
      [W,_,C,C,_,_,_,_,_,C,C,_,_,_,_,W],
      [W,_,_,_,_,_,_,_,_,_,_,_,_,_,_,W],
      [W,_,_,S,_,P,_,_,P,_,S,_,_,_,_,W],
      [W,_,_,_,_,_,_,_,_,_,_,_,_,_,_,W],
      [W,_,N,N,N,N,_,_,N,N,N,N,_,_,_,W],
      [W,_,_,_,_,_,_,_,_,_,_,_,_,_,_,W],
      [W,_,_,_,I,_,_,_,I,_,_,_,_,_,_,W],
      [W,_,_,_,_,_,_,_,_,_,_,_,_,_,_,W],
      [W,_,S,S,_,_,_,_,_,S,S,_,_,_,_,W],
      [W,_,_,_,_,_,_,_,_,_,_,_,_,_,_,W],
      [W,_,_,_,_,_,_,_,_,_,_,_,_,_,_,W],
      [W,_,P,P,P,P,P,P,P,P,P,P,_,_,_,W],
      [W,W,W,W,W,W,W,W,W,W,W,W,W,W,W,W],
    ],
    windZones: [
      WindZone(x: 2*40, y: 13*40, w: 4*40, h: 40, force: -200),
      WindZone(x: 8*40, y: 13*40, w: 4*40, h: 40, force: 200),
    ],
  );
}
