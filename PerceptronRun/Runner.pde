import java.lang.Error;
import java.lang.Comparable;
import java.util.Arrays;

class Runner extends Entity {
  final static float def_gravity = -1.2;
  int score;
  float gravity;
  boolean down; // Player is pressing down key.
  boolean alive; // Player is alive.
  int animationFrame; // For animation.

  Perceptron perceptronLayers;
  
  Runner() {
    score = 0;
    sprite = regCart1;
    w = regCart1.width;
    h = regCart1.height;
    xPos = w / 2 + 30;
    dx = 0;
    yPos = 0;
    dy = 0;
    gravity = def_gravity;
    alive = true;
    down = false;
    showHitbox = false;
    targeted = false;

    animationFrame = 0;
  }

  void reset() {
    alive = true;
    down = false;
    gravity = def_gravity;
    animationFrame = 0;
    dx = 0;
    dy = 0;
    yPos = 0;
    score = 0;
  }

  // Called every frame.
  void update() {
    updateCounters();
    checkCollisions();
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

  // Check if player collides with any obstacle.
  void checkCollisions() {
    for (Obstacle obstacle : obstacleList) {
      if (collidesWith(obstacle)) {
        alive = false;
      }
    }
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
  void jump(boolean smallHop) {
    gravity = def_gravity;
    down = false;
    if (yPos == 0) {
      if (!smallHop) {
        dy = JUMP_VEL;
      } else {
        dy = JUMP_VEL - 4;
      }
    }
  }

  // Get input for NEAT.
  float[] readInput() {
    // Inputs are as follows:
    // 1. Distance from next obstacle.
    // 2. yPos of obstacle.
    // 3. Height of obstacle.
    // 4. Width of obstacle.
    // 5. Speed of obstacles.
    // 6. Interval of obstacle after.
    // 7. Is the obstacle flying?
    // 8. yPos of player.
    float[] inputVals = new float[8];

    Obstacle nextObstacle = null;
    Obstacle nextNextObstacle = null;
    
    for (int i = 0; i < obstacleList.size(); i++) {
      Obstacle thisObstacle = obstacleList.get(i);
      if (thisObstacle.xPos + thisObstacle.w / 2 > xPos - w / 2) {
         nextObstacle = thisObstacle;
         
         if (i < obstacleList.size() - 1) {
           nextNextObstacle = obstacleList.get(i + 1);
         }
      }
    }
    

    if (nextObstacle != null) {
      nextObstacle.targeted = true;
      inputVals[0] = 1 - nextObstacle.xPos / SCREENWIDTH;
      inputVals[1] = 1 - nextObstacle.yPos / SCREENHEIGHT;
      inputVals[2] = nextObstacle.h / SCREENHEIGHT;
      inputVals[3] = nextObstacle.w / SCREENWIDTH;
      inputVals[4] = speed / MAX_SPEED;
      if (nextNextObstacle != null && nextNextObstacle != nextObstacle) {
        nextNextObstacle.targeted = true;
        inputVals[5] = 1 - (nextNextObstacle.xPos - nextObstacle.xPos) / SCREENWIDTH;
      } else {
        inputVals[5] = 0;
      }
      inputVals[6] = nextObstacle.flying ? 1 : 0;
    } else {
      for (int i = 0; i < 7; i++) { 
        inputVals[i] = 0;
      }
    }
    inputVals[7] = yPos / SCREENHEIGHT;

    return inputVals;
  }

  // The fun part. The player feeds data through the neural network to decide what to do.
  void decide(float[] inputVals) {
    int decisionIndex = perceptronLayers.getIndex(inputVals);

    switch (decisionIndex) {
      case 0: // Crouch
        toggleDown(false);
        break;
      case 1: // Regular Jump
        toggleDown(true);
        break;
      case 2: // Regular Jump
        jump(false);
        break;
      default:
        throw new Error("Invalid decision.");
    }
  }
}
