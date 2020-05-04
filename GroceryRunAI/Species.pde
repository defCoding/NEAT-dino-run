import java.util.Collections;
import java.lang.Comparable;

class Species implements Comparable<Species> {
  // Constant values.
  static final float disjCoeff = 1;
  static final float weightCoeff = 0.6;
  static final float compatibilityThreshold = 3.0;

  ArrayList<Runner> runnerList;
  Runner fittestAgent;
  float bestFitness;
  float avgFitness;
  int staleFactor; // Number of generations without improvement.
  boolean isSorted; // Whether or not runnerList has been sorted.

  Genome representative;

  Species() {
    runnerList = new ArrayList<Runner>();
    bestFitness = 0;
    staleFactor = 0;
  }

  // Starts species with one agent.
  Species(Runner agent) {
    runnerList = new ArrayList<Runner>();
    runnerList.add(agent);
    fittestAgent = agent;
    bestFitness = agent.fitness;
    representative = agent.genome.copy();
    isSorted = true;
  }

  void addRunner(Runner agent) {
    isSorted = false; // No longer guaranteed to be sorted.
    runnerList.add(agent);
  }

  void setAvgFitness() {
    float sum = 0;

    for (Runner runner : runnerList) {
      sum += runner.fitness;
    }

    avgFitness = sum / runnerList.size();
  }
  
  // Page 110 talks about killing off the lowest performing members of the population, but does
  // not specify how many. I'm just going to fiddle with this until I like it I suppose.
  void genocide() {
    if (runnerList.size() > 2) { // Would like to keep 2 parents at least.
      int numToKill = runnerList.size() * 2 / 5; // Killing 40% for now.
      sortSpecies();

      // Remove the worst performing.
      for (int i = 0; i < numToKill; i++) {
        runnerList.remove(runnerList.size() - 1);
      }
    }
  }

  // Sort the species by fitness.
  void sortSpecies() {
    if (!isSorted) {
      Collections.sort(runnerList, Collections.reverseOrder());
      isSorted = true;
    }
  }

  // New generation has passed so update staleFactor.
  void updateStaleness() {
    sortSpecies(); 

    // If the species is empty, then we should get rid of it.
    if (runnerList.size() == 0) {
      staleFactor = 9001; // OVER 9000!!!
      return;
    }

    // Check for improvement.
    if (runnerList.get(0).fitness > bestFitness) {
      fittestAgent = runnerList.get(0);
      staleFactor = 0;
      bestFitness = fittestAgent.fitness;
      representative = fittestAgent.genome.copy();
    } else {
      staleFactor++;
    }
  }

  // Whether or not the given genome is in this species.
  boolean isCompatible(Genome g) {
    return calcIncompatibility(g, representative) <= compatibilityThreshold;
  }

  // Calculates the distance (incompatibility) between two genomes.
  float calcIncompatibility(Genome g1, Genome g2) {
    // You can find this equation on page 110 (1). Recommended values are strewn throughout the paper.

    // I opted to ignore excess genes because it takes more time to differentiate between excess and disjoint genes.
    // Source: https://stackoverflow.com/questions/13295240/difference-between-disjoint-and-excess-genes-in-neat
    // float excessCoeff = 1;

    int normalizedGeneCount = Math.max(g1.connectionList.size(), g2.connectionList.size());
    if (normalizedGeneCount <= 20) {
      normalizedGeneCount = 1;
    } 

    // Calculate values
    int excessDisjoint = countExcessDisjointGenes(g1, g2);
    float avgWeightDiff = calcAvgWeightDiff(g1, g2);

    return (excessDisjoint * disjCoeff) / normalizedGeneCount + avgWeightDiff * weightCoeff;
  }

  int countExcessDisjointGenes(Genome g1, Genome g2) {
    // Easier to count matching and then subtract from total.
    int matchingCount = 0;
    for (Connection g1Connection : g1.connectionList) {
      for (Connection g2Connection : g2.connectionList) {
        if (g1Connection.innovation == g2Connection.innovation) {
          matchingCount += 2; // Add 2 since it counts for both genes.
          break;
        }
      }
    }

    return g1.connectionList.size() + g2.connectionList.size() - matchingCount;
  }

  float calcAvgWeightDiff(Genome g1, Genome g2) {
    // Can't calculate weight difference if one is empty.
    if (g1.connectionList.size() == 0 || g2.connectionList.size() == 0) {
      return 0;
    }

    int matchingCount = 0; // Number of matching genes.
    float sumOfDifference = 0; // Summation of differences in weight between matching genes.

    for (Connection g1Connection : g1.connectionList) {
      for (Connection g2Connection : g2.connectionList) {
        if (g1Connection.innovation == g2Connection.innovation) {
          matchingCount++;
          sumOfDifference += Math.abs(g1Connection.weight - g2Connection.weight);
          break;
        }
      }
    }

    // If there are no matches whatsoever, the average weight difference doesn't even matter.
    if (matchingCount == 0) {
      return 200;
    }

    return sumOfDifference / matchingCount;
  }

  // Gets child from species. Honestly, I wasn't sure how I'm supposed to implement this, so I followed what I did in
  // my Mancala code (which admittedly, didn't do very well). Sometimes I'd just use a clone, and other times I would do
  // recombination.
  Runner generateChild(InnovationTracker innovationTracker, Random r) {
    Runner child;
    if (r.nextFloat() < 0.2) {
      child = pickParentWeighted(r);
    } else {
      Runner parentA, parentB;
      parentA = pickParentWeighted(r);
      parentB = pickParentWeighted(r);

      // crossover method requires that the fitter parent is the caller of the method
      Runner moreFit = parentA.fitness >= parentB.fitness ? parentA : parentB;
      Runner lessFit = parentB.fitness <= parentA.fitness ? parentB : parentA;

      child = moreFit.crossover(lessFit, r);
    }

    child.genome.mutate(innovationTracker, r); 
    return child;
  }

  // Pick a random parent, but biased towards more fit parents.
  Runner pickParentWeighted(Random r) {
    /*
    sortSpecies();
    
    float gaussianVal = (float) r.nextGaussian();
    // Constraint gaussian val to (-1, 1).
    gaussianVal = Math.max(-1, gaussianVal);
    gaussianVal = Math.min(1, gaussianVal);

    // Now shifted gaussian distribution to interval (0, 2);
    gaussianVal += 1;
    // Scale up gaussian distribution to (0, size of runnerList * 2).
    gaussianVal *= runnerList.size();

    // Some math to make it select properly.
    int randomIndex = Math.abs(runnerList.size() - floor(gaussianVal)) % runnerList.size();

    return runnerList.get(randomIndex);
    */
    float totalFitness = 0;

    for (Runner runner : runnerList) {
      totalFitness += runner.fitness;
    }

    float threshold = r.nextFloat() * totalFitness;
    float cumulativeSum = 0;
    for (Runner runner : runnerList) {
      cumulativeSum += runner.fitness;

      if (cumulativeSum >= threshold) {
        return runner;
      }
    }

    return null;
  }

  // Shares fitness among members of a species to avoid culling unique members. This equation can
  // be found on page 110 (2).
  void shareFitness() {
    for (Runner speciesMember : runnerList) { 
      speciesMember.fitness /= runnerList.size();
    }
  }

  int compareTo(Species other) {
    if (bestFitness > other.bestFitness) {
      return 1;
    } else if (bestFitness < other.bestFitness) {
      return -1;
    } else {
      return 0;
    }
  }
}
