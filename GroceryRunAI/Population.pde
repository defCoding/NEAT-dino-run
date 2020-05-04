import java.util.Collections;
import java.util.Random;

class Population {
  ArrayList<Runner> pop;
  Runner fittestAgent;
  int highScore;
  int genNum;
  boolean isSorted; // Species list is sorted.
  Random r;
  int maxSize;
  ArrayList<Obstacle> obstacleList;

  InnovationTracker innovationTracker;
  ArrayList<Species> speciesList;
  ArrayList<Integer> bestOfGenerations; // For graphing purposes



  // Creates a population of a given size.
  Population(int size) {
    r = new Random();
    pop = new ArrayList<Runner>();
    speciesList = new ArrayList<Species>();
    bestOfGenerations = new ArrayList<Integer>();
    obstacleList = new ArrayList<Obstacle>();
    fittestAgent = null;
    highScore = 0;
    genNum = 0;
    isSorted = true;
    innovationTracker = new InnovationTracker();
    maxSize = size;
    
    for (int i = 0; i < size; i++) {
      Runner newRunner = new Runner();
      
      newRunner.genome.generateTopologicalNetwork();
      newRunner.genome.mutate(innovationTracker, r);
      pop.add(newRunner);
    }
  }

  void setObstacleList(ArrayList<Obstacle> obstacles) {
    obstacleList = obstacles;
  }
  
  // Has all alive runner decide what to do and move.
  void updateAliveRunners() {

    for (Runner runner : pop) {
      if (runner.alive) {
        // Read the screen and have the runner decide what to do.
        runner.decide(runner.readInput());
        runner.update();
        runner.show();
      }
    }
  }

  // Returns true if all members of population are dead.
  boolean isDead() {
    for (Runner runner : pop) {
      if (runner.alive) {
        return false;
      }
    }

    return true;
  }


  void setFittestAgent() {
    sortAllSpecies();

    if (speciesList.get(0).runnerList.size() > 0) {
      Runner bestRightNow = speciesList.get(0).runnerList.get(0);
      bestRightNow.genNum = genNum;
  
      // bestOfGenerations.add(bestRightNow.score);

      if (bestRightNow.score > highScore) {
        highScore = bestRightNow.score;
        fittestAgent = bestRightNow;
      }
      bestOfGenerations.add(highScore);
    }
  }

  // Split up population into species. This helps protect more unique members of the population by sheltering them inside of a group, which allows for more diversity.
  void speciate() {
    // Empty species for new species categorization.
    for (Species s : speciesList) {
      s.runnerList.clear();
    }

    for (Runner runner : pop) {
      boolean found = false; // Have we found a species for runner
      for (Species species : speciesList) {
        if (species.isCompatible(runner.genome)) {
          species.addRunner(runner);
          found = true;
          break;
        }
      }

      // Did not find species for runner.
      if (!found) {
        speciesList.add(new Species(runner));
      }
    }

    isSorted = false;
  }

  // Remove all species who have not improved in 15 generations (page 111)
  void removeStaleSpecies() {
    // At least save some so that we can keep growing the population.
    sortAllSpecies();
    for (int i = 4; i < speciesList.size(); i++) {
      if (speciesList.get(i).staleFactor >= 15) {
        speciesList.remove(i--);
      }
    }
  }

  // Kills lower performing members of all species.
  void genocideSpecies() {
    for (Species species : speciesList) {
      species.genocide();
      species.shareFitness();
      species.setAvgFitness();
      isSorted = false;
    }
  }

  // Calculates fitness of all members of population so that we can do genetic algorithm.
  void calcFitness() {
    for (Runner runner : pop) {
      runner.calcFitness();
    }
  }

  void sortAllSpecies() {
    if (!isSorted) {
      // Sort species by their best fitness.
      Collections.sort(speciesList, Collections.reverseOrder());

      // Update species staleness.
      for (Species species : speciesList) {
        species.updateStaleness();
      }

      isSorted = true;
    }
  }

  float sumAvgFitness() {
    float sum = 0;
    for (Species species : speciesList) {
      sum += species.avgFitness;
    }

    return sum;
  }

  void commenceEvolution() {
    speciate();
    calcFitness();
    sortAllSpecies();
    genocideSpecies();
    setFittestAgent();
    removeStaleSpecies();
    removeNonreproducingSpecies();
    
    // Create next generation.
    float sumAvg = sumAvgFitness();
    ArrayList<Runner> childPop = new ArrayList<Runner>();

    // Interspecies mating.
    /*
    if (r.nextFloat() < 0.001) {
      Species species1 = speciesList.get(r.nextInt(speciesList.size()));

      Species species2;
      do {
        species2 = speciesList.get(r.nextInt(speciesList.size()));
      } while (species1 == species2 && speciesList.size() > 1);

      if (species1.runnerList.size() > 0 && species2.runnerList.size() > 0) {
        Runner r1 = species1.runnerList.get(0);
        Runner r2 = species2.runnerList.get(0);

        Runner moreFit = r1.fitness >= r1.fitness ? r1 : r2;
        Runner lessFit = r2.fitness <= r1.fitness ? r2 : r1;

        childPop.add(moreFit.crossover(lessFit, r));
      }
    }
    */

    for (Species species : speciesList) {
      // Paper said only if there were more than 5 networks, but I'm finding that setting it like that makes it perform worse.
      childPop.add(species.fittestAgent.copy());   

      // Number of children from species is relative to its fitness score and the total fitness score.
      int numChildren = floor(species.avgFitness / sumAvg * maxSize) - 1;
    
      for (int i = 0; i < numChildren; i++) {
        childPop.add(species.generateChild(innovationTracker, r));
      }
    }

    println(maxSize);
    // Add more children if need be.
    while (childPop.size() < maxSize) {
      childPop.add(speciesList.get(0).generateChild(innovationTracker, r));
    }

    pop = childPop;
    isSorted = false;
    genNum++;
    for (Runner runner : pop) {
      runner.genome.generateTopologicalNetwork();
    }
   
    //innovationTracker.reset();
  }

  // Removes species that can no longer reproduce due to poor performance.
  void removeNonreproducingSpecies() {
    float sumAvg = sumAvgFitness();

    for (int i = 0; i < speciesList.size(); i++) {
      if (speciesList.get(i).avgFitness / sumAvg * pop.size() < 1) {
        speciesList.remove(i);
        i--;
      }
    }
    isSorted = false;
  }

  void drawAMember() {
    for (Runner runner : pop) {
      if (runner.alive) {
        textFont(boldFont);
        textSize(18);
        text("Some Alive Player's Neural Network", 100, 155);
        textFont(font);
        runner.genome.drawGenome(200, 185, 400, 300);
        break;
      }
    }
  }

  void drawGraph(int x, int y, int w, int h) {
    // Draw graph edges.
    stroke(0);
    strokeWeight(1);
    textSize(12);
    line(x, y, x, y + h);
    line(x, y + h, x + w, y + h);
    // Label graph edges.
    text("Generations", x + w / 2 - 30, y + h + 10);
    pushMatrix();
    translate(x - 15, y + h / 2 + 30);
    rotate(-HALF_PI);
    text("Best Score", 0, 0);
    popMatrix();

    if (bestOfGenerations.size() > 1) {
      float yMax = (float) Math.max(Collections.max(bestOfGenerations), 1000);
      
      for (int i = 0; i < bestOfGenerations.size() - 1; i++) {
        float startX, startY, stopX, stopY;
        float score = (float) bestOfGenerations.get(i);
        float nextScore = (float) bestOfGenerations.get(i + 1);

        startX = x + map(i, 0, bestOfGenerations.size() - 1, 0f, (float) w);
        startY = y + h - map(score, 0, yMax, 0f, (float) h);
        stopX = x + map(i + 1, 0, bestOfGenerations.size() - 1, 0f, (float) w);
        stopY = y + h - map(nextScore, 0, yMax, 0f, (float) h);

        stroke(0, 0, 255);
        line(startX, startY, stopX, stopY);
      }
    }
      
  }
}
