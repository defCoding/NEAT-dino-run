import open_color, arcade, random, perceptron

# Set constants
SCREEN_WIDTH = 1800
SCREEN_HEIGHT = 500
SCREEN_TITLE = "Grocery Run"
FLOOR_BOUNDARY = 20
JUMP_VELOCITY = 1200
GRAVITY = -4000
OBSTACLE_INTERVAL = 1.1
MIN_OBSTACLE_INTERVAL = .4
OBSTACLE_INTERVAL_RATE = .99
STARTING_SPEED = 800
SPEED = 800
ACCELERATION = 20
MAX_SPEED = 3000


SPRITE_SHEET = {
        "STILL_RUNNER": {"x": 40, "y": 12, "w": 44, "h": 36},
        "RUNNER": {"x": 536, "y": 11, "w": 40, "h": 36, "offset": 3},
        "CROUCHED_RUNNER": {"x": 751, "y": 21, "w": 44, "h": 26, "offset": 3},
        "LARGE_OBSTACLE": {"x": 238, "y": 3, "w": 23, "h": 46, "offset": 3},
        "SMALL_OBSTACLE": {"x": 181, "y": 3, "w": 15, "h": 33, "offset": 3},
        "FLYING_OBSTACLE": {"x": 134, "y": 12, "w": 41, "h": 28, "offset": 3},
        "RESTART_BUTTON": {"x": 3, "y": 3, "w": 34, "h": 30}
        }

class Runner(arcade.Sprite):
    def __init__(self):
        """Initializes the Runner, controlled by the player."""
        sprite_info = SPRITE_SHEET["STILL_RUNNER"]
        super().__init__(filename = "assets/sprite-sheet.png", scale = 2, image_x = sprite_info["x"], image_y = sprite_info["y"], image_width = sprite_info["w"], image_height = sprite_info["h"])

        (self.center_x, self.center_y) = (20 + self.width / 2, FLOOR_BOUNDARY + self.height / 2)

        # ################## #
        # Load move textures #
        # ################## #
        sprite_info = SPRITE_SHEET["RUNNER"]
        self.move_textures = []
        for i in range(4):
            offset = i * (sprite_info["offset"] + sprite_info["w"])
            texture = arcade.load_texture(file_name = "assets/sprite-sheet.png", x = sprite_info["x"] + offset, y = sprite_info["y"], width = sprite_info["w"], height = sprite_info["h"])

            self.move_textures.append(texture)

        # #################### #
        # Load crouch textures #
        # #################### #
        sprite_info = SPRITE_SHEET["CROUCHED_RUNNER"]
        self.crouch_textures = []
        for i in range(2):
            offset = i * (sprite_info["offset"] + sprite_info["w"])
            texture = arcade.load_texture(file_name = "assets/sprite-sheet.png", x = sprite_info["x"] + offset, y = sprite_info["y"], width = sprite_info["w"], height = sprite_info["h"])
            self.crouch_textures.append(texture)

        self.started = False # True if game has begun. Used for determining sprite texture.

        self.is_down = False # True if the player is pressing the down button.
        self.grounded = True # True if the runner is on the ground.

        self.is_jumping = False 
        self.is_crouched = False

        self.change_y = 0
        self.move_frame = 0 # Which texture in move_textures we are currently on.
        self.crouch_frame = 0 # Which texture in crouch_textures we are currently on.
        self.animation_interval = .2
        self.time_counter = self.animation_interval

    def toggle_down(self, state):
        self.started = True
        self.is_down = state

    def toggle_jump(self, state):
        self.started = True
        self.is_jumping = state

    def jump(self):
        if self.grounded and not self.is_crouched:
            self.grounded = False
            self.change_y = JUMP_VELOCITY

    def on_update(self, delta_time):
        # When the player is pressing down, and they are on the ground, crouch.
        # If they are not on the ground, speed up their descent.
        if self.is_down:
            if self.grounded:
                self.is_crouched = True
            else:
                self.change_y = -JUMP_VELOCITY
        else:
            self.is_crouched = False
            self.change_y += GRAVITY * delta_time
            if self.is_jumping:
                self.jump()

        self.center_y += self.change_y * delta_time

        self.center_y = max(self.center_y, FLOOR_BOUNDARY + self.height / 2)

        if self.center_y == FLOOR_BOUNDARY + self.height / 2:
            self.grounded = True

    def update_animation(self, delta_time):
        if self.started:
            self.time_counter += delta_time

            if self.time_counter > self.animation_interval:
                if self.is_crouched:
                    self.texture = self.crouch_textures[self.crouch_frame]
                    self.set_hit_box(self.texture.hit_box_points)

                    # Go to next frame.
                    self.crouch_frame += 1
                    self.crouch_frame %= 2
                else:
                    self.texture = self.move_textures[self.move_frame]
                    self.set_hit_box(self.texture.hit_box_points)

                    # Go to next frame.
                    self.move_frame += 1
                    self.move_frame %= 4
                
                self.time_counter = 0

class Obstacle(arcade.Sprite):
    def __init__(self):
        self.elapsed_time_since_update = 0

        flying = random.randint(0, 2)
        sprite_info = {}
        count = 0
        h = FLOOR_BOUNDARY # Vertical placement of the obstacle.
        

        if flying == 2:
            sprite_info = SPRITE_SHEET["FLYING_OBSTACLE"]

            altitude = random.randint(0, 2)
            
            if altitude == 0:
                h += sprite_info["h"] / 2
            elif altitude == 1:
                h += SPRITE_SHEET["CROUCHED_RUNNER"]["h"] * 2
            else:
                h += SPRITE_SHEET["RUNNER"]["h"] * 4
        else:
            size = random.randint(0, 1)

            if size == 0:
                count = random.randint(0, 2)
                sprite_info = SPRITE_SHEET["SMALL_OBSTACLE"]
            else:
                count = random.randint(0, 3)
                sprite_info = SPRITE_SHEET["LARGE_OBSTACLE"]


        super().__init__(filename = "assets/sprite-sheet.png", scale = 2, image_x = sprite_info["x"], image_y = sprite_info["y"], image_width = sprite_info["w"] + count * (sprite_info["w"] + sprite_info["offset"]), image_height = sprite_info["h"])

        (self.center_x, self.center_y) = (SCREEN_WIDTH, h + self.height / 2)

    def on_update(self, delta_time):
        global SPEED
        global OBSTACLE_INTERVAL
        self.center_x -= SPEED * delta_time
        if self.center_x + self.width / 2 <= 0:
            self.kill()
            SPEED = min(MAX_SPEED, SPEED + ACCELERATION)
            OBSTACLE_INTERVAL = max(MIN_OBSTACLE_INTERVAL, OBSTACLE_INTERVAL * OBSTACLE_INTERVAL_RATE)

    def get_distance(self):
        return self.center_x - self.width / 2


class Window(arcade.Window):
    def __init__(self):
        super().__init__(SCREEN_WIDTH, SCREEN_HEIGHT, SCREEN_TITLE)
        arcade.set_background_color(open_color.white)

    def setup(self, agent, should_draw):
        """Set up required sprites and data."""
        global SPEED

        self.game_over= False
        self.should_draw = should_draw
        SPEED = STARTING_SPEED
        self.set_update_rate(1 / 60)
        self.runner = Runner()
        self.score = 0
        self.max_time = 200
        self.agent = agent
        self.obstacle_list = arcade.SpriteList()
        self.time_since_last_spawn = OBSTACLE_INTERVAL

    def on_draw(self):
        """Called when the window needs to be drawn."""
        if self.should_draw:
            arcade.start_render()
            self.runner.draw()
            self.obstacle_list.draw()

            arcade.draw_text(f'{self.score}', SCREEN_WIDTH - 90, SCREEN_HEIGHT - 20, open_color.black, 15, bold = True)

            if self.game_over:
                arcade.draw_text("GAME OVER", SCREEN_WIDTH / 2 -90, SCREEN_HEIGHT / 2 - 15, open_color.black, 30, bold = True)

            arcade.finish_render()


    def on_update(self, delta_time):

        if not self.game_over:
            # Increase score
            self.score += delta_time

            # Don't let game last too long:
            if (self.score > self.max_time):
                self.game_over = True
                arcade.close_window()
                return

            # Get inputs for perceptron
            distance = SCREEN_WIDTH
            height = SCREEN_HEIGHT # obstacle height
            width = 0

            if len(self.obstacle_list) != 0:
                next_obstacle_index = 0
                while next_obstacle_index < len(self.obstacle_list) and self.obstacle_list[next_obstacle_index].center_x <= self.runner.center_x:
                    next_obstacle_index += 1
                
                if next_obstacle_index < len(self.obstacle_list):
                    distance = self.obstacle_list[next_obstacle_index].get_distance()
                    height = self.obstacle_list[next_obstacle_index].center_y
                    width = self.obstacle_list[next_obstacle_index].width

            global SPEED, MAX_SPEED

            distance /= SCREEN_WIDTH
            width /= SCREEN_WIDTH
            height /= SCREEN_HEIGHT
            speed = SPEED / MAX_SPEED
            player_y = self.runner.center_y / SCREEN_HEIGHT
            inputs = [speed, distance, width, height, player_y]

            decision = self.agent.get_index(inputs)

            if decision == 1:
                self.runner.toggle_jump(True)
            else:
                self.runner.toggle_jump(False)

            self.time_since_last_spawn += delta_time
            if self.time_since_last_spawn >= OBSTACLE_INTERVAL:
                self.obstacle_list.append(Obstacle())
                self.time_since_last_spawn = 0

            self.runner.on_update(delta_time)
            # self.runner.update_animation(delta_time)
            self.obstacle_list.on_update(delta_time)

            if len(self.runner.collides_with_list(self.obstacle_list)) > 0:
                self.game_over = True
                arcade.close_window()


    #def on_key_press(self, key, modifiers):
        #if key == arcade.key.SPACE or key == arcade.key.W:
            #self.runner.toggle_jump(True)
        #if key == arcade.key.S:
            #self.runner.toggle_down(True)
#
    #def on_key_release(self, key, modifiers):
        #if key == arcade.key.SPACE or key == arcade.key.W:
            #self.runner.toggle_jump(False)
        #if key == arcade.key.S:
            #self.runner.toggle_down(False)
