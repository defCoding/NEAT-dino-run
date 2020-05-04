import java.util.Random;
import java.lang.Error;

class Obstacle extends Entity {
  boolean flying; // Obstacle is flying.
  boolean small; // (Ground) obstacle is small.
  boolean can_remove; // Checks if object can be removed from screen.
  int size; // Size of (ground) obstacle.

  Obstacle(Random r) {
    xPos = SCREENWIDTH;
    flying = r.nextInt(4) == 3; // 1 in 4 chance of being a flying obstacle.

    if (!flying) {
      yPos = 0;
      small = r.nextInt(3) < 2; // 66% chance of being a small obstacle.
      
      if (small) {
        size = r.nextInt(3); // Group size of 1 - 3.
        sprite = smallObstacles.get(0, 0, 15 + size * 18, 33);
        w = sprite.width;
        h = sprite.height;
      } else {
        size = r.nextInt(3); // Group size of 1 - 3.
        sprite = largeObstacles.get(0, 0, 23 + size * 26, 46);
        w = sprite.width;
        h = sprite.height;
      }
    } else {
      size = 1;
      sprite = flyingObstacle;
      w = sprite.width;
      h = sprite.height;

      height = r.nextInt(3); // Three possible heights for flying obstacles.
      
      switch (height) {
        case 0:
          yPos = 0;
          break;
        case 1:
          yPos = regCart1.height - 5;
          break;
        case 2:
          yPos = regCart1.height * 2;
          break;
        default:
          throw new Error("Invalid height.");
      }
    }

    w -= 3;
    h -= 2;

    showHitbox = false;
    targeted = false;
  }

  void move(float dx) {
    this.dx = -1 * dx;
    super.move();
    if (xPos < -1 * w / 2) {
      can_remove = true;
    }
  }
}
