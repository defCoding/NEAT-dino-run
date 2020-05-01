import pyglet, random, math

# Set constants
SCREEN_WIDTH = 1800
SCREEN_HEIGHT = 500
SCREEN_TITLE = "Grocery Run"
GAME_BOUNDARY = 20
JUMP_VELOCITY = 1200
GRAVITY = -4000
OBSTACLE_INTERVAL = 1.1
MIN_OBSTACLE_INTERVAL = .4
OBSTACLE_INTERVAL_RATE = .99
STARTING_SPEED = 800
SPEED = 800
ACCELERATION = 20
MAX_SPEED = 3000

# Sprite Values
SPRITE_DATA = {
        "STILL_RUNNER": {"x": 40, "y": 12, "w": 44, "h": 36},
        "RUNNER": {"x": 536, "y": 11, "w": 40, "h": 36, "offset": 3},
        "CROUCHED_RUNNER": {"x": 751, "y": 21, "w": 44, "h": 26, "offset": 3},
        "LARGE_OBSTACLE": {"x": 238, "y": 3, "w": 23, "h": 46, "offset": 3}, "SMALL_OBSTACLE": {"x": 181, "y": 3, "w": 15, "h": 33, "offset": 3},
        "FLYING_OBSTACLE": {"x": 134, "y": 12, "w": 41, "h": 28, "offset": 3},
        "RESTART_BUTTON": {"x": 3, "y": 3, "w": 34, "h": 30}
        }

SPRITE_SHEET = pyglet.image.load("assets/sprite-sheet.png")

def distance(p1, p2):
    """Return distance between two points."""
    return math.sqrt((p1[0] - p2[0]) ** 2 + (p1[1] - p2[1]) ** 2)

class Entity(pyglet.sprite.Sprite):
    """A sprite with physical properties."""

    def __init__(self, *args, **kwargs):
        super(Entity, self).__init__(*args, **kwargs)

        # Velocity
        self.velocity_x, self.velocity_y = 0.0, 0.0

        # A flag to check if this object can be removed from memory.
        self.can_remove = False


    def update(self, dt):
        """Called every frame."""

        # Update positions.
        self.x += self.velocity_x * dt
        self.y += self.velocity_y * dt

        # Only for obstacles. If x < 0, then obstacle has left screen.
        if self.x < 0:
            self.can_remove = True

        # Only for player. If y <= GAME_BOUNDARY, player should stay on ground.
        if self.y <= GAME_BOUNDARY + self.image.height / 2:
            self.y = GAME_BOUNDARY + self.image.height / 2
            self.grounded = True

    def collides(self, other):
        """Check for collision between two entities."""

        # Maximum distance for a collision.
        collision_threshold = self.image.width * 0.5 * self.scale + other.image.width * 0.5 * other.scale

        # Calculate Euclidian distance.
        dist = distance(self.position, other.position)

        return dist <= collision_threshold

class Runner(Entity):
    def __init__(self, *args, **kwargs):
        """Initializes the Runner."""
        # Get Sprite Data
        s_info = SPRITE_DATA["STILL_RUNNER"]
        sprite_img = SPRITE_SHEET.get_region(s_info["x"], s_info["y"], s_info["w"], s_info["h"])

        super(Runner, self).__init__(img = sprite_img, *args, **kwargs)

        # Set player coordinates.
        self.x = GAME_BOUNDARY + s_info["w"] / 2
        self.y = GAME_BOUNDARY + s_info["h"] / 2

        self.started = False # Game has begun.
        self.is_down = False # Player is pressing down.
        self.grounded = True # Player is on the ground.

        self.is_jumping = False # Player is pressing up.
        self.is_crouched = False # Player is crouched.

    def update(self, dt):
        super(Runner, self).update(dt)

        # Checks how player should be moved based on player movement.
        if self.is_down:
            self.down()
        else:
            self.is_crouched = False
            self.velocity_y += GRAVITY * dt

            if self.is_jumping:
                self.jump()

    def toggle_down(self, state):
        self.started = True
        self.is_jumping = False
        self.is_down = state

    def toggle_jump(self, state):
        self.started = True
        self.is_down = False
        self.is_jumping = state

    def jump(self):
        """Checks if player can jump, and if so, jumps."""
        if self.grounded and not self.is_crouched:
            self.grounded = False
            self.change_y = JUMP_VELOCITY

    def down(self):
        """Either accelerates the player towards the ground or crouches."""
        if self.grounded:
            self.is_crouched = True
        else:
            self.velocity_y = -JUMP_VELOCITY

class Obstacle(Entity):
    def __init__(self, *args, **kwargs):
        """Initializes the Obstacle."""
        # Get Sprite Data
        is_flying = True if random.randint(0, 2) == 2 else False
        s_info = {}
        count = 0
        h = GAME_BOUNDARY
    
        if is_flying:
            s_info = SPRITE_DATA["FLYING_OBSTACLE"]
            altitude = random.randint(0, 2)

            if altitude == 0:
                h += s_info["h"] / 2
            elif altitude == 1:
                h += SPRITE_DATA["CROUCHED_RUNNER"]["h"] * 2
            else:
                h += SPRITE_DATA["RUNNER"]["h"] * 4
        else:
            is_small = True if random.randint(0, 1) == 0 else False

            if is_small:
                count = random.randint(0, 2)
                s_info = SPRITE_DATA["SMALL_OBSTACLE"]
            else:
                count = random.randint(0, 3)
                s_info = SPRITE_DATA["LARGE_OBSTACLE"]
        
        sprite_img = SPRITE_SHEET.get_region(s_info["x"], s_info["y"], s_info["w"] + count * (s_info["w"] + s_info["offset"]), s_info["h"])

        super(Obstacle, self).__init__(img = sprite_img, *args, **kwargs)

        self.x, self.y = SCREEN_WIDTH, h + self.image.height / 2

    def update(self, dt):
        global SPEED
        self.velocity_y = SPEED
        super(Obstacle, self).update(dt)

        if self.can_remove:
            SPEED = min(MAX_SPEED, SPEED + ACCELERATION)
            OBSTACLE_INTERVAL = max(MIN_OBSTACLE_INTERVAL, OBSTACLE_INTERVAL * OBSTACLE_INTERVAL_RATE)
            super(Obstacle, self).delete()

time_last_spawn = 0
game_over = False

game_window = pyglet.window.Window(SCREEN_WIDTH, SCREEN_HEIGHT)

main_batch = pyglet.graphics.Batch()

runner = Runner(batch = main_batch)

obstacle_list = []

@game_window.event
def on_draw():
    game_window.clear()
    main_batch.draw()

def update(dt):
    # Check for collision.
    for obstacle in obstacle_list:
        if runner.collides(obstacle):
            print("HI")
            game_over = True
            break

    global time_last_spawn 
    time_last_spawn += dt

    if time_last_spawn >= OBSTACLE_INTERVAL:
        obstacle_list.append(Obstacle(batch = main_batch))
        time_last_spawn = 0

    runner.update(dt)

    for obstacle in obstacle_list:
        obstacle.update(dt)

    for obstacle in obstacle_list:
        if obstacle.can_remove:
            obstacle_list.remove(obstacle)

pyglet.clock.schedule_interval(update, 1 / 120.0)

pyglet.app.run()

    
