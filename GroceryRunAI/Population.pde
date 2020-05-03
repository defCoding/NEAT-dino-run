class Population {
  ArrayList<Runner> pop = new ArrayList<Runner>();
  Runner fittestAgent;
  int highScore;
  int genNum;

  InnovationTracker innovationTracker;
  ArrayList<Species> speciesList = new ArrayList<Species>();


  Population(int size) {
    for (int i = 0; i < size; i++) {
      pop.add(new Runner());

}
