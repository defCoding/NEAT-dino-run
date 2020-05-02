import java.util.ArrayList;

// Set constants
final int FPS = 60;
final float SCREENHEIGHT = 400;
final float SCREENWIDTH = 900;
final float GROUNDHEIGHT = 20;
final float JUMP_VEL = 13;
final int OBSTACLE_INTERVAL = 60;
final float MAX_SPEED = 200;
final float ACCELERATION = 10;

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
int obstacleTimer = 0;
int randInterval = floor(random(30)); // Added to obstacle interval to vary spawn times.
float speed = 11;
boolean gameOver = false;

Runner player;
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
  
  player = new Runner();
  obstacleList = new ArrayList<Obstacle>();

  // Setup Window
  size(900, 400);
  frameRate(FPS);
}

void draw() {
  if (!gameOver) {
    drawBackground();
    player.show();
    player.move();
    updateObstacles();
    gameOver = checkCollisions();
  }
}

void updateObstacles() {
  obstacleTimer++;

  if (obstacleTimer > OBSTACLE_INTERVAL + randInterval) {
    obstacleList.add(new Obstacle());
    obstacleTimer = 0;
    randInterval = floor(random(30));
  }

  moveObstacles();
}

void moveObstacles() {
  for (int i = 0; i < obstacleList.size(); i++) {
    obstacleList.get(i).move(speed);

    if (obstacleList.get(i).can_remove) {
      obstacleList.remove(i);
      i--;
    }
  }

  showObstacles();
}

void showObstacles() {
  for (Obstacle obstacle : obstacleList) {
    obstacle.show();
  }
}

boolean checkCollisions() {
  for (Obstacle obstacle : obstacleList) {
    if (player.collidesWith(obstacle)) {
      return true;
    }
  }

  return false;
}

void drawBackground() {
  background(255);
  stroke(0);
  strokeWeight(3);
  line(0, SCREENHEIGHT - GROUNDHEIGHT - 15, width, SCREENHEIGHT - GROUNDHEIGHT - 15);
}

void keyPressed() {
  switch (key) {
    case 'w':
      player.jump();
      break;
    case 's':
      player.toggleDown(true);
      break;
    default:
  }
}

void keyReleased() {
  switch (key) {
    case 's':
      player.toggleDown(false);
      break;
    default:
  }
}
