import java.lang.Error;
import java.lang.Comparable;

class Runner extends Entity implements Comparable<Runner> {
  final static float def_gravity = -1.2;
  int score;
  int genNum; // The generation this runner belongs to
  float gravity;
  boolean down; // Player is pressing down key.
  boolean alive; // Player is alive.

  int animationFrame; // For animation.

  // For NEAT algorithm.
  final int genomeInputSize = 6;
  final int genomeOutputSize = 2; // 3 options
  Genome genome;
  float fitness;
  
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
    animationFrame = 0;
    genome = new Genome(genomeInputSize, genomeOutputSize);
    fitness = 0;
    genNum = 0;
  }

  // Called every frame.
  void update(ArrayList<Obstacle> obstacleList) {
    updateCounters();
    checkCollisions(obstacleList);
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
  void checkCollisions(ArrayList<Obstacle> obstacleList) {
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

  void calcFitness() {
    fitness = score * score;
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
      dy = JUMP_VEL;
    }
  }

  // Get input for NEAT.
  float[] readInput(ArrayList<Obstacle> obstacleList) {
    // Inputs are as follows:
    // 1. Distance from next obstacle.
    // 2. yPos of obstacle.
    // 3. Height of obstacle.
    // 4. Width of obstacle.
    // 5. Speed of obstacles.
    // 6. yPos of player.

    Obstacle nextObstacle = null;
    float[] inputVals = new float[genomeInputSize];

    for (Obstacle obstacle : obstacleList) {
      if (obstacle.xPos - obstacle.w / 2 > xPos + w / 2) {
        nextObstacle = obstacle;
        break;
      }
    }
    
    

    if (nextObstacle != null) {
      inputVals[0] = 1 / (nextObstacle.xPos / 12.0);
      inputVals[1] = nextObstacle.yPos;
      inputVals[2] = nextObstacle.h;
      inputVals[3] = nextObstacle.w;
      inputVals[4] = speed;
    } else {
      for (int i = 0; i < 5; i++) { 
        inputVals[i] = 0;
      }
    }
    inputVals[5] = yPos;

    return inputVals;
  }

  // The fun part. The player feeds data through the neural network to decide what to do.
  void decide(float[] inputVals) {
    float max = 0;
    int decisionIndex = 5;

    float[] decisions = genome.feedForward(inputVals);
    

    for (int i = 0; i < genomeOutputSize; i++) {
      if (decisions[i] > max) {
        max = decisions[i];
        decisionIndex = i;
      }
    }

    if (max < 0.7) {
      toggleDown(false);
      return;
    }

    switch (decisionIndex) {
      case 0: // Jump
        jump();
        break;
      case 1: // Crouch
        toggleDown(true);
        break;
      default:
    }
  }
  
  // Does genome crossover between this Runner and another runner to make a child runner.
  Runner crossover(Runner other, Random r) {
    Runner child = new Runner();
    child.genome = genome.crossover(other.genome, r);
    child.genome.generateTopologicalNetwork();
    return child;
  }

  // Creates a copy of this runner.
  Runner copy() {
    Runner copy = new Runner();
    copy.genome = genome.copy();
    copy.fitness = fitness;
    copy.genome.generateTopologicalNetwork();
    copy.genNum = genNum;
    return copy;
  }

  int compareTo(Runner other) {
    if (fitness > other.fitness) {
      return 1;
    } else if (fitness < other.fitness) {
      return -1;
    } else {
      return 0;
    }
  }
}
