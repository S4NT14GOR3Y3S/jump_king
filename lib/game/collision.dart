import '../utils/constants.dart';
import 'game_map.dart';
import 'player.dart';

/// AABB collision for the player against tiles
class CollisionSystem {
  final GameMap map;

  CollisionSystem(this.map);

  /// Full collision resolution for player vs tiles.
  /// Returns true if player is grounded after resolution.
  CollisionResult resolve(Player player) {
    bool grounded = false;
    bool onIceTile = false;
    bool hitSpike = false;
    bool hitGoal = false;
    bool hitCheckpoint = false;
    double checkpointX = 0;
    double checkpointY = 0;
    int checkpointLevel = 0;

    double px = player.x;
    double py = player.y;
    double pw = player.width;
    double ph = player.height;
    double ts = JKConstants.tileSize;

    // ── Vertical resolution ──────────────────────
    // Falling down — check bottom edge
    if (player.vy >= 0) {
      double bottom = py + ph;
      int bottomRow = (bottom / ts).floor();
      int prevBottomRow = ((bottom - player.vy * 0.016) / ts).floor();

      // Columns the player overlaps
      int leftCol = (px / ts).floor();
      int rightCol = ((px + pw - 0.1) / ts).floor();

      for (int col = leftCol; col <= rightCol; col++) {
        // Solid tiles
        if (_isSolidForFall(col, bottomRow)) {
          double surfaceY = bottomRow * ts;
          if (bottom >= surfaceY && bottom <= surfaceY + 8) {
            py = surfaceY - ph;
            grounded = true;
            onIceTile = map.isIce(col, bottomRow);

            // Crumble?
            if (map.isCrumbleCollapsible(col, bottomRow)) {
              map.triggerCrumble(col, bottomRow);
            }
          }
        }

        // One-way platforms (only when falling through top)
        if (map.isPlatform(col, bottomRow)) {
          double surfaceY = bottomRow * ts;
          double prevBottom = py + ph - player.vy * 0.016;
          // Only land if coming from above
          if (bottom >= surfaceY && prevBottom <= surfaceY + 2) {
            py = surfaceY - ph;
            grounded = true;
          }
        }

        // Spikes
        if (map.isSpike(col, bottomRow)) {
          hitSpike = true;
        }

        // Checkpoint
        if (map.isCheckpoint(col, bottomRow)) {
          hitCheckpoint = true;
          checkpointX = col * ts;
          checkpointY = (bottomRow - 1) * ts;
          checkpointLevel = map.index;
        }

        // Goal
        if (map.isGoal(col, bottomRow)) {
          hitGoal = true;
        }
      }
    }

    // Jumping up — check top edge
    if (player.vy < 0) {
      double top = py;
      int topRow = (top / ts).floor();

      int leftCol = (px / ts).floor();
      int rightCol = ((px + pw - 0.1) / ts).floor();

      for (int col = leftCol; col <= rightCol; col++) {
        if (_isSolidForCeiling(col, topRow)) {
          double ceilY = (topRow + 1) * ts;
          if (top <= ceilY && top >= ceilY - 8) {
            py = ceilY;
            player.hitCeiling(py);
          }
        }
      }
    }

    // ── Horizontal resolution ────────────────────
    double newVx = player.vx;

    if (player.vx > 0) {
      // Moving right — check right edge
      double right = px + pw;
      int rightCol = (right / ts).floor();
      int topRow = (py / ts).floor();
      int bottomRow = ((py + ph - 0.1) / ts).floor();

      for (int row = topRow; row <= bottomRow; row++) {
        if (_isSolidHorizontal(rightCol, row)) {
          double wallX = rightCol * ts;
          if (right > wallX) {
            px = wallX - pw;
            newVx = 0;
          }
        }
      }
    } else if (player.vx < 0) {
      // Moving left — check left edge
      double left = px;
      int leftCol = (left / ts).floor();
      int topRow = (py / ts).floor();
      int bottomRow = ((py + ph - 0.1) / ts).floor();

      for (int row = topRow; row <= bottomRow; row++) {
        if (_isSolidHorizontal(leftCol, row)) {
          double wallX = (leftCol + 1) * ts;
          if (left < wallX) {
            px = wallX;
            newVx = 0;
          }
        }
      }
    }

    // Also check goal/checkpoint at player center
    int centerCol = ((px + pw / 2) / ts).floor();
    int topRow2 = (py / ts).floor();
    if (map.isGoal(centerCol, topRow2)) hitGoal = true;

    // Apply resolved position
    player.x = px;
    player.y = py;
    player.vx = newVx;

    if (grounded) {
      player.land(py + ph, onIceTile: onIceTile);
    } else {
      player.isGrounded = false;
      player.onIce = false;
    }

    return CollisionResult(
      grounded: grounded,
      hitSpike: hitSpike,
      hitGoal: hitGoal,
      hitCheckpoint: hitCheckpoint,
      checkpointX: checkpointX,
      checkpointY: checkpointY,
      checkpointLevel: checkpointLevel,
    );
  }

  bool _isSolidForFall(int col, int row) =>
      map.isSolid(col, row) || map.isCrumbleCollapsible(col, row);

  bool _isSolidForCeiling(int col, int row) =>
      map.isSolid(col, row) || map.isCrumbleCollapsible(col, row);

  bool _isSolidHorizontal(int col, int row) =>
      map.isSolid(col, row) || map.isCrumbleCollapsible(col, row);

  /// Check if player overlaps any wind zone and return force
  double getWindForce(Player player) {
    double cx = player.centerX;
    double cy = player.centerY;
    for (var zone in map.windZones) {
      if (cx >= zone.x && cx <= zone.x + zone.w &&
          cy >= zone.y && cy <= zone.y + zone.h) {
        return zone.force;
      }
    }
    return 0;
  }
}

class CollisionResult {
  final bool grounded;
  final bool hitSpike;
  final bool hitGoal;
  final bool hitCheckpoint;
  final double checkpointX;
  final double checkpointY;
  final int checkpointLevel;

  const CollisionResult({
    required this.grounded,
    required this.hitSpike,
    required this.hitGoal,
    required this.hitCheckpoint,
    this.checkpointX = 0,
    this.checkpointY = 0,
    this.checkpointLevel = 0,
  });
}
