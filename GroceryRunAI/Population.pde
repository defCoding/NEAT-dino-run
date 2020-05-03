import java.util.Collections;
import java.util.Random;

class Population {
  ArrayList<Runner> pop;
  Runner fittestAgent;
  int highScore;
  int genNum;
  int lifespan; // How long the population has been alive.
  boolean isSorted; // Species list is sorted.
  Random r;
  ArrayList<Obstacle> obstacleList;

  InnovationTracker innovationTracker;
  ArrayList<Species> speciesList;
  ArrayList<Runner> bestOfGenerations;



  // Creates a population of a given size.
  Population(int size) {
    r = new Random();
    pop = new ArrayList<Runner>();
    speciesList = new ArrayList<Species>();
    bestOfGenerations = new ArrayList<Runner>();
    obstacleList = new ArrayList<Obstacle>();
    fittestAgent = null;
    highScore = 0;
    genNum = 0;
    lifespan = 0;
    isSorted = true;
    innovationTracker = new InnovationTracker();
    
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
    lifespan++;

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
  
      if (bestRightNow.score > highScore) {
        bestOfGenerations.add(bestRightNow);
        System.out.println("Old High Score: " + highScore);
        System.out.println("New High Score: " + bestRightNow.score);
        highScore = bestRightNow.score;
        fittestAgent = bestRightNow;
      }
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
    // At least save 2 so that we can keep growing the population.
    for (int i = 4; i < speciesList.size(); i++) {
      if (speciesList.get(i).staleFactor >= 18) {
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

  // Removes all but top 5 species. Needed when no improvement is happening.
  void smite() {
    int numToKill = speciesList.size() - 5;
    for (int i = 0; i < numToKill; i++) {
      speciesList.remove(speciesList.size() - 1);
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

    for (Species species : speciesList) {
      childPop.add(species.fittestAgent.copy());

      // Number of children from species is relative to its fitness score and the total fitness score.
      int numChildren = floor(species.avgFitness / sumAvg * pop.size()) - 1;
    
      for (int i = 0; i < numChildren; i++) {
        childPop.add(species.generateChild(innovationTracker, r));
      }
    }

    // Add more children if need be.
    while (childPop.size() < pop.size()) {
      childPop.add(speciesList.get(0).generateChild(innovationTracker, r));
    }
    
    System.out.printf("Generation: %d | Pop Size: %d | # Mutations: %d | # Species: %d\n", genNum, pop.size(), innovationTracker.size(), speciesList.size());
    pop = childPop;
    isSorted = false;
    genNum++;
    for (Runner runner : pop) {
      runner.genome.generateTopologicalNetwork();
    }
   
    lifespan = 0;
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
        textSize(12);
        text("Some Alive Player's Neural Network", 100, 20);
        runner.genome.drawGenome(180, 40, 350, 200);
        break;
      }
    }
  }
}
