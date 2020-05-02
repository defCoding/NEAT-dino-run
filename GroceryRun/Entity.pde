abstract class Entity {
  float xPos, yPos;
  float dx, dy;
  float w, h;

  abstract void show();

  void move() {
    xPos += dx;
    yPos += dy;
  }

  boolean collidesWith(Entity other) {
    // Turn upper left corner and lower right corner into points for both entities.
    float l1[] = {xPos - w / 2, yPos - h};
    float r1[] = {xPos + w / 2, yPos};

    float l2[] = {other.xPos - other.w / 2, other.yPos - other.h};
    float r2[] = {other.xPos + other.w / 2, other.yPos};

    if (l1[0] > r2[0] || l2[0] > r1[0]) {
      return false;
    } else if (l1[1] > r2[1] || l2[1] > r1[1]) {
      return false;
    }

    return true;
  }
}
