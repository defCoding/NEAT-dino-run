import java.util.ArrayList;
import java.util.Arrays;
import java.util.Random;

// Set constants
final float SCREENHEIGHT = 675;
final float SCREENWIDTH = 1200;
final float GROUNDHEIGHT = 20;
final float JUMP_VEL = 14;
final int OBSTACLE_INTERVAL = 35;
final float MAX_SPEED = 150;
final float ACCELERATION = 1;
final float STARTING_SPEED = 9;

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
int randInterval = rand.nextInt(25); // Added to obstacle interval to vary spawn times.
float speed = 9;

Population pop;
ArrayList<Obstacle> obstacleList;
PFont font, boldFont;

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
  
  pop = new Population(1000);
  obstacleList = new ArrayList<Obstacle>();
  pop.setObstacleList(obstacleList);

  font = createFont("Source Code Pro", 32);
  boldFont = createFont("Source Code Pro Bold", 32);
  // Setup Window
  size(1200, 675);
  frameRate(FPS);
  textFont(font);
}

// Called every frame.
void draw() {
  drawBackground();
  if (!pop.isDead()) {
    updateObstacles();
    pop.updateAliveRunners();
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
  pop.drawAMember();
  textSize(20);
  text("Pop Size: " + pop.pop.size(), 10, 25);
  text("Generation: " + pop.genNum, 10, 55);
  text("Species: " + pop.speciesList.size(), 10, 85);
  text("Best Score: " + pop.highScore, 10, 115);
  textSize(12);
  text("FPS: " + FPS, 1100, 665);
  fill(0, 171, 57);
  text("Green is a positive connection.", 300, 25);
  fill(194, 0, 0);
  text("Red is a negative connection.", 300, 45);
  fill(79, 79, 79);
  text("Grey is a disabled connection.", 300, 65);
  fill(0);
  textFont(boldFont);
  textSize(12);
  text("Thickness represents weight of connection.", 300, 85);
  textFont(font);
  textSize(12);


  int score = 0;
  int alive = 0;
  // Ok this is terrible, but sue me. I could not care less about time complexity rn.
  for (Runner runner : pop.pop) {
    if (runner.alive) {
      score = runner.score;
      alive++;
    }
  }

  text("Score: " + score, 20, 665);
  text(String.format("Speed: %.2f", speed), 150, 665);
  text("Alive " + alive, 20, 500);

  pop.drawGraph(675, 10, 500, 450);
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
      frameRate(FPS);
      System.out.println("FPS: " + FPS);
      break;
    case '-':
      FPS -= 10;
      FPS = Math.max(FPS, 30);
      frameRate(FPS);
      System.out.println("FPS: " + FPS);
      break;
    default:   
  }
}
