import java.util.ArrayList;
import java.util.Random;

// Set constants
final float SCREENHEIGHT = 400;
final float SCREENWIDTH = 900;
final float GROUNDHEIGHT = 20;
final float JUMP_VEL = 13;
final int OBSTACLE_INTERVAL = 60;
final float MAX_SPEED = 100;
final float ACCELERATION = .5;
final float STARTING_SPEED = 11;

int FPS = 60;
// Sprites
PImage regCart1;
PImage regCart2;
PImage regCart3;
PImage regCart4;
PImage crouchedCart1;
PImage crouchedCart2;
PImage smallObstacles;
PImage largeObstacles;
PImage flyingObstacle;

// Variables
Random rand = new Random();
int obstacleTimer = 0;
int randInterval = rand.nextInt(30); // Added to obstacle interval to vary spawn times.
float speed = 11;

Population pop;
ArrayList<Obstacle> obstacleList;

void setup() {
  // Load sprite sheet.
  PImage sprite_sheet = loadImage("assets/sprite-sheet.png");

  // Crop sprites from sprite sheet.
  regCart1 = sprite_sheet.get(536, 11, 40, 36);
  regCart2 = sprite_sheet.get(579, 11, 40, 36);
  regCart3 = sprite_sheet.get(622, 11, 40, 36);
  regCart4 = sprite_sheet.get(665, 11, 40, 36);

  crouchedCart1 = sprite_sheet.get(751, 21, 44, 26);
  crouchedCart2 = sprite_sheet.get(798, 21, 44, 26);

  smallObstacles = sprite_sheet.get(181, 3, 232, 33);
  largeObstacles = sprite_sheet.get(238, 3, 339, 46);
  flyingObstacle = sprite_sheet.get(134, 12, 41, 28);
  
  pop = new Population(500);
  obstacleList = new ArrayList<Obstacle>();
  pop.setObstacleList(obstacleList);

  // Setup Window
  size(900, 400);
  frameRate(FPS);
}

// Called every frame.
void draw() {
  drawBackground();
  if (!pop.isDead()) {
    updateObstacles();
    pop.updateAliveRunners();
    if (pop.speciesList.size() > 0) {
      pop.speciesList.get(0).runnerList.get(0).genome.drawGenome(50, 20, 300, 150);
    }
  } else {
    System.out.println("Preparing new Generation.");
    pop.commenceEvolution();
    resetGame();
  }
}

// Increments obstacle timer, attempts to spawn an obstacle, and moves all obstacles.
void updateObstacles() {
  obstacleTimer++;

  // Check if we can spawn obstacle.
  if (obstacleTimer > OBSTACLE_INTERVAL + randInterval) {
    // If so, generate obstacle, and reset timer and recreate a random
    // interval to add to default interval.
    Obstacle obs = new Obstacle(rand);
    obs.showHitbox = true;
    obstacleList.add(obs);
    obstacleTimer = 0;
    randInterval = rand.nextInt(30);
  }

  moveObstacles();
}

// Moves all obstacles.
void moveObstacles() {
  for (int i = 0; i < obstacleList.size(); i++) {
    obstacleList.get(i).move(speed);

    // Remove obstacle if it leaves the screen.
    if (obstacleList.get(i).can_remove) {
      obstacleList.remove(i);
      i--;

      // If obstacle is removed, the game should get harder.
      speed = Math.min(speed + ACCELERATION, MAX_SPEED);
    }
  }

  showObstacles();
}

// Draws all obstacles.
void showObstacles() {
  for (Obstacle obstacle : obstacleList) {
    obstacle.show();
  }
}


void drawBackground() {
  background(255);
  stroke(0);
  strokeWeight(1);
  line(0, SCREENHEIGHT - GROUNDHEIGHT - 15, width, SCREENHEIGHT - GROUNDHEIGHT - 15);
}

void resetGame() {
  obstacleList.clear();
  speed = STARTING_SPEED;
  obstacleTimer = 0;
  randInterval = rand.nextInt(30);
}


void keyPressed() {
  switch (key) {
    case '+':
      FPS += 10;
      System.out.println("FPS: " + FPS);
      break;
    case '-':
      FPS -= 10;
      System.out.println("FPS: " + FPS);
      break;
    default:   
  }
}
