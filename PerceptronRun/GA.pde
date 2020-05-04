import java.util.Random;

class GA {
  int n;
  int popSize;
  float mutProb;
  float recomProb;
  int tournaments;
  int gen;
  ArrayList<float[]> population;
  Random r;

  Runner currentPlayer1;
  Runner currentPlayer2;

  GA(int n, int popSize, float mutProb, float recomProb) {
    this.n = n;
    this.popSize = popSize;
    this.mutProb = mutProb;
    this.recomProb = recomProb;
    

    r = new Random();
    population = new ArrayList<float[]>();

    for (int i = 0; i < popSize; i++) {
      float[] newGenotype = new float[n];
      for (int j = 0; j < n; j++) {
        newGenotype[j] = r.nextFloat() * 2 - 1;
      }

      population.add(newGenotype);
    }

    tournaments = 0;
    gen = 0;
    currentPlayer1 = new Runner();
    currentPlayer2 = new Runner();
  }
  
  void mutate(float[] genotype) {
    for (int i = 0; i < genotype.length; i++) {
      if (r.nextFloat() < mutProb) {
        genotype[i] += r.nextFloat() * 2 - 1;

        if (genotype[i] > 1) {
          genotype[i] = 1;
        } else if (genotype[i] < -1) {
          genotype[i] = -1;
        }
      }
    }
  }

  void recombination(float[] winner, float[] loser) {
    for (int i = 0; i < winner.length; i++) {
      if (r.nextFloat() < recomProb) {
        loser[i] = winner[i];
      }
    }
  }

  void setPlayers() {
    float[] genotype1 = population.get(r.nextInt(population.size()));
    float[] genotype2 = population.get(r.nextInt(population.size()));
    currentPlayer1.perceptronLayers = new Perceptron(genotype1);
    currentPlayer2.perceptronLayers = new Perceptron(genotype2);

    currentPlayer1.reset();
    currentPlayer2.reset();
  }

  void updatePlayers() {
    if (currentPlayer1.alive) {
      currentPlayer1.decide(currentPlayer1.readInput());
      currentPlayer1.update();
      currentPlayer1.show();
    }
    if (currentPlayer2.alive) {
      currentPlayer2.decide(currentPlayer2.readInput());
      currentPlayer2.update();
      currentPlayer2.show();
    }
  }

  boolean done() {
    return !(currentPlayer1.alive || currentPlayer2.alive);
  }

  void doGeneticAlgoStuff() {
    float fitness1 = currentPlayer1.score;
    float fitness2 = currentPlayer2.score;

    float[] winner = fitness1 >= fitness2 ? currentPlayer1.perceptronLayers.genotype : currentPlayer2.perceptronLayers.genotype;

    float[] loser = fitness1 < fitness2 ? currentPlayer1.perceptronLayers.genotype : currentPlayer2.perceptronLayers.genotype;

    mutate(loser);
    recombination(winner, loser);

    tournaments++;

    if (tournaments != 0 && tournaments == popSize / 2) {
      tournaments = 0;
      gen++;
    }
  }
}
