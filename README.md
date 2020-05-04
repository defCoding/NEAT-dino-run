## Grocery Run (Chrome Dino Game) AI
### Using Neuroevolution of Augmenting Topologies

The goal of this project was to create an artifical intelligence that could beat the classic Dino Game that pops up when the Chrome browser loses internet connection (or can be accessed through chrome://dino). The game was recreated in Processing Java (albeit with slightly different sprites to match the current environment of COVID19).

<br />

### How to Setup and Run the AI

To run the code, download Processing 3 from their website at https://processing.org/download/. Once downloaded, simply pull up the code in the application and press the run button.

<br />

### How the Game Works

The game is fairly simple. The player controls a character that can only jump up, do a short hop, or move down. If the player is midair when moving down, the character accelerates quickly towards the ground. If the player is already on the ground, moving down allows the player to crouch.

Obstacles will begin moving toward the player at random intervals, and the player must evade the obstacles using either of the aforementioned movements. As the player passes each obstacle, the game gets progressively harder, and the obstacles begin moving faster and faster. Eventually, the obstacles are only on screen for a few frames, in which case it becomes near impossible for a human to evade the obstacles consistently.

To make the game slightly more difficult, there are a variety of obstacles. There are two types of ground obstacles, small and large. Small obstacles are shorter and narrower, and can spawn in groups of size 1 to 3. Large obstacles are taller and wider, and can spawn in groups of 1 to 4. Naturally, this makes large obstacles harder to navigate. To avoid these, the player must jump.

In addition, there are flying obstacles, which can spawn at three different elevations: ground, player level, or player jump level. Ground level flying obstacles must be jumped over. Player level flying obstacles spawn at around the same height as the top of the player. The player can still choose to jump over these, but the player can also crouch under them. The final elevation is the highest, and the obstacle spawns around the same level at which the player can jump to. That means that the player cannot jump over them, and any attempt to do so will result in a loss. Instead the player can choose to not move at all, or crouch.

<br />

### The Algorithm

The Neuroevolution of Augmenting Technologies was used to create the neural network of the AI agents. In short, the algorithm works by initializing agents with a minimal neural network, an input layer, an output layer, and one connection between the two. The agents play the game, and their scores are recorded as their fitness level. Weaker players are selectively removed, and better performing agents are allowed to reproduce. At each generation, players are also mutated to allow for diversity and more complexity in neural networks.

However, simply removing weaker players would also remove any valid attempts at mutation. While most mutations are bad, the trend towards beneficial behavior is often characterized by a series of individually harmful mutations. To protect these "innovative" mutations, the population is divided into species of similar agents (agents with a similar genome), and agents must only compete with members of their own species. With speciating, even if a particular agent does poorly compared to the entirety of the population, it can still be allowed to reproduce if it does well within its own species. This is key in allowing the population to produce an optimal agent. If a species does not improve after a set amount of generations, the species will then be deleted.

<br />

For more information on the algorithm and its implementations, you can find the original research paper on the topic here: [[PAPER]](http://nn.cs.utexas.edu/downloads/papers/stanley.ec02.pdf "[PAPER]").

This particular algorithm was implemented with the assistance of the paper above, Hydrozoa's HydroNeat implementation, and YouTube channel CodeBullet. The links can be found below.

[Hydrozoa's Channel](https://www.youtube.com/channel/UCQ3I9UG_zvcQOs6tTPyyz_A "Hydrozoa's Channel")

[HydroNeat Github](https://github.com/hydrozoa-yt/hydroneat "[HydroNeat Github]")

[CodeBullet Channel](https://www.youtube.com/channel/UC0e3QhIYukixgh5VVpKHH9Q "CodeBullet Channel")


<br />


### Findings

The AI were originally provided the following input parameters:

1. Distance from obstacle.
2. y-Position of obstacle.
3. Height of obstacle.
4. Width of obstacle.
5. Obstacle speed.
6. Interval between first and second obstacle.
7. y-Position of player.

With this set of parameters, the agents were able to jump over obstacles consistently within 10 generations. However, flying obstacles seemed to prove the challenge.

The AI seemed to consistently jump at every flying obstacle, which worked for all except the obstacle at the highest elevation. It wasn't until generation 80 before the AI seemed to consistently crouch under the flying obstacles instead of jumping over them. The following graph shows the growth rate of the top score over the generations. (Flying bit is disabled, and set to 0).

![](https://i.imgur.com/I0OUrSO.png)

<br />

Adding an additional bit, Flying?, improved results significantly. Flying? was set to 1 if the obstacle was a flying obstacle AND had a y position greater than 0. With this addition, we could see similar results in far less generations, at around generation 20. However, this seemed a bit disingenuous as we were feeding the AI more data than we really needed to be. As such, it would likely only be used for demonstration purposes. The following graph shows the growth with the flying input added:

![](https://i.imgur.com/zUe0nIg.png)

As we can see, there is less stagnation in growth due to the ability to navigate the flying obstacles.

<br />

Here is a video demonstration of the AI in action:

[![Youtube Video](https://img.youtube.com/vi/5eMnGvzL1DA/0.jpg)](https://youtu.be/5eMnGvzL1DA)
