import 'dart:math';
import '../utils/constants.dart';

class Player {
  // Position (top-left of bounding box)
  double x;
  double y;

  // Velocity
  double vx = 0;
  double vy = 0;

  // State
  PlayerState state = PlayerState.idle;
  bool isGrounded = false;
  bool facingRight = true;

  // Jump charging
  double chargeTime = 0.0;   // How long jump button held
  bool isCharging = false;
  double chargeAngle = 0.0;  // Direction of jump (radians, 0 = up)

  // Coyote time (allows jumping briefly after walking off edge)
  double coyoteTimer = 0.0;
  bool wasPreviouslyGrounded = false;

  // Ice physics
  bool onIce = false;
  double iceSlipX = 0.0;    // Carry-over velocity on ice

  // Crumble tracking
  int? crumbleTileCol;
  int? crumbleTileRow;

  // Checkpoint / respawn
  double checkpointX;
  double checkpointY;
  int checkpointLevel;

  // Animation
  double animTimer = 0.0;
  double landingTimer = 0.0;
  double hurtTimer = 0.0;
  double dustTimer = 0.0;

  // Input
  double moveInput = 0.0;    // -1 left, 0 none, 1 right
  bool jumpPressed = false;

  // Stats
  int deaths = 0;
  int jumps = 0;

  Player({
    required this.x,
    required this.y,
    this.checkpointX = 0,
    this.checkpointY = 0,
    this.checkpointLevel = 0,
  });

  double get width => JKConstants.playerWidth;
  double get height => JKConstants.playerHeight;
  double get centerX => x + width / 2;
  double get centerY => y + height / 2;
  double get bottom => y + height;
  double get right => x + width;

  // Normalized charge (0.0 - 1.0)
  double get chargeFraction => (chargeTime * JKConstants.jumpChargeRate / JKConstants.maxJumpPower).clamp(0.0, 1.0);

  bool get canJump => isGrounded || coyoteTimer > 0;
  bool get isHurt => state == PlayerState.hurt;
  bool get isAlive => hurtTimer <= 0 || state != PlayerState.hurt;

  void update(double dt) {
    animTimer += dt;
    if (landingTimer > 0) landingTimer -= dt;
    if (dustTimer > 0) dustTimer -= dt;

    // Coyote time
    if (wasPreviouslyGrounded && !isGrounded) {
      coyoteTimer = JKConstants.coyoteTime;
    }
    if (coyoteTimer > 0) coyoteTimer -= dt;
    wasPreviouslyGrounded = isGrounded;

    // Hurt state: frozen, fall back to checkpoint after timer
    if (state == PlayerState.hurt) {
      hurtTimer -= dt;
      // Hurt bounces the player upward briefly
      vy -= 200 * dt;
      x += vx * dt;
      y += vy * dt;
      if (hurtTimer <= 0) {
        _respawn();
      }
      return;
    }

    _handleInput(dt);
    _applyGravity(dt);
    _clampVelocity();
  }

  void _handleInput(double dt) {
    if (state == PlayerState.jumping || state == PlayerState.falling) {
      // Air control (reduced)
      double airMove = moveInput * JKConstants.playerMoveSpeed * JKConstants.playerAirControl;
      vx = vx * 0.95 + airMove * 0.05;  // Smooth air control
      if (moveInput != 0) facingRight = moveInput > 0;
    } else if (isGrounded) {
      if (isCharging) {
        // While charging, slight deceleration on ground
        vx *= 0.85;
        state = PlayerState.charging;

        // Build charge angle based on horizontal input
        chargeTime += dt;
        chargeTime = chargeTime.clamp(0, JKConstants.maxJumpPower / JKConstants.jumpChargeRate);

        // Angle: -PI/2 is straight up, tilted by moveInput
        chargeAngle = -pi / 2 + moveInput * pi / 3;

      } else {
        // Normal ground movement
        if (moveInput != 0) {
          if (onIce) {
            // Ice: gradual acceleration
            vx += moveInput * JKConstants.playerMoveSpeed * 3 * dt;
            vx = vx.clamp(-JKConstants.playerMoveSpeed * 1.5, JKConstants.playerMoveSpeed * 1.5);
          } else {
            vx = moveInput * JKConstants.playerMoveSpeed;
          }
          facingRight = moveInput > 0;
          state = PlayerState.running;
        } else {
          if (onIce) {
            vx *= 0.98; // Slip on ice
          } else {
            vx = 0;
          }
          state = PlayerState.idle;
        }
      }
    }
  }

  void _applyGravity(double dt) {
    if (!isGrounded || vy < 0) {
      vy += JKConstants.gravity * dt;
    }

    // Move
    x += vx * dt;
    if (!isGrounded) {
      y += vy * dt;
      state = vy < 0 ? PlayerState.jumping : PlayerState.falling;
    }
  }

  void _clampVelocity() {
    vy = vy.clamp(-2000, JKConstants.maxFallSpeed);
  }

  /// Called when jump button is pressed (start charging)
  void startCharge() {
    if (!canJump) return;
    isCharging = true;
    chargeTime = 0;
    chargeAngle = -pi / 2; // Default: straight up
  }

  /// Called when jump button is released (execute jump)
  void releaseJump() {
    if (!isCharging) return;
    isCharging = false;

    double power = (chargeTime * JKConstants.jumpChargeRate)
        .clamp(JKConstants.minJumpPower, JKConstants.maxJumpPower);

    vx = cos(chargeAngle) * power;
    vy = sin(chargeAngle) * power;

    isGrounded = false;
    coyoteTimer = 0;
    state = PlayerState.jumping;
    jumps++;
  }

  /// Called by collision system when player lands on a surface
  void land(double surfaceY, {bool onIceTile = false}) {
    double prevVy = vy;
    y = surfaceY - height;
    vy = 0;
    if (!isGrounded) {
      // Just landed
      landingTimer = 0.12;
      dustTimer = 0.3;
      state = PlayerState.landing;
    }
    isGrounded = true;
    onIce = onIceTile;
    isCharging = isCharging; // maintain charge if already pressing
    if (landingTimer <= 0) {
      state = isCharging ? PlayerState.charging : (vx.abs() > 10 ? PlayerState.running : PlayerState.idle);
    }
  }

  /// Called when player hits a ceiling
  void hitCeiling(double ceilingY) {
    y = ceilingY + 0.5;
    vy = vy.abs() * 0.1; // small bounce down
  }

  /// Called when player hits a wall from the side
  void hitWall(double wallX, bool fromLeft) {
    if (fromLeft) {
      x = wallX;
    } else {
      x = wallX - width;
    }
    vx = 0;
  }

  /// Player hit a spike — trigger hurt state
  void hitSpike() {
    if (state == PlayerState.hurt) return;
    state = PlayerState.hurt;
    hurtTimer = 1.5;
    vy = -300;
    vx = facingRight ? -150 : 150;
    isGrounded = false;
    deaths++;
  }

  void _respawn() {
    x = checkpointX;
    y = checkpointY;
    vx = 0;
    vy = 0;
    isGrounded = false;
    state = PlayerState.falling;
    hurtTimer = 0;
  }

  void setCheckpoint(double cx, double cy, int level) {
    checkpointX = cx;
    checkpointY = cy;
    checkpointLevel = level;
  }

  void reset(double startX, double startY) {
    x = startX;
    y = startY;
    vx = 0;
    vy = 0;
    isGrounded = false;
    isCharging = false;
    chargeTime = 0;
    state = PlayerState.falling;
    hurtTimer = 0;
    landingTimer = 0;
    checkpointX = startX;
    checkpointY = startY;
  }

  void fullReset(double startX, double startY) {
    reset(startX, startY);
    deaths = 0;
    jumps = 0;
    checkpointLevel = 0;
  }
}
