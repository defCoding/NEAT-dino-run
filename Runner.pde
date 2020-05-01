class Runner {
  int score;
  float y_pos;
  float dy;
  float gravity;
  
  boolean down;// Player is pressing down.
  
  Runner() {
    score = 0;
    y_pos = 0;
    dy = 0;
    gravity = 1.5;
    down = false;
  }
  
  void show()
