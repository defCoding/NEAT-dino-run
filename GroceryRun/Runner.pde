import java.lang.Error;

class Runner extends Entity {
  final static float def_gravity = -1.2;
  int score;
  float gravity;
  boolean down; // Player is pressing down key.

  int animationFrame; // For animation.
  
  Runner() {
    this.score = 0;
    this.sprite = regCart1;
    this.w = regCart1.width;
    this.h = regCart1.height;
    this.xPos = w / 2 + 30;
    this.dx = 0;
    this.yPos = 0;
    this.dy = 0;
    this.gravity = def_gravity;
    this.down = false;
    this.showHitbox = false;
    this.animationFrame = 0;
  }

  // Called every frame.
  void update() {
    updateCounters();
    move();
  }
 
  // Draws the Runner. 
  void show() {
    // Get correct animation sprite based on player crouch status and animation frame.
    if (down && yPos == 0) {
      sprite = animationFrame < 2 ? crouchedCart1 : crouchedCart2;
    } else {
      // Find animation frame.
      switch (animationFrame) {
        case 0:
          sprite = regCart1;
          break;
        case 1:
          sprite = regCart2;
          break;
        case 2:
          sprite = regCart3;
          break;
        case 3:
          sprite = regCart4;
          break;
        default:
          throw new Error("Runner sprite index out of bounds.");
      }
    }

    w = sprite.width - 2;
    h = sprite.height;
    animationFrame = (animationFrame + 1) % 4;

    super.show();
  }

  // Moves Runner and checks for collisions.
  void move() {
    super.move();

    // Update velocity and check if player is grounded.
    if (yPos > 0) {
      dy += gravity;
    } else {
      yPos = 0;
      dy = 0;
    }
  }

  // Updates any frame specific counters.
  void updateCounters() {
    score += 1;
  }

  // Has the player go down.
  void toggleDown(boolean goDown) {
    if (yPos != 0 && goDown) {
      gravity = -3;
    }

    down = goDown;
  }

  // If the player can jump, jump.
  void jump() {
    gravity = def_gravity;
    down = false;
    if (yPos == 0) {
      dy = JUMP_VEL - 4;
    }
  }
}
