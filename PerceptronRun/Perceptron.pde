class Perceptron {
  float[] genotype;
  float[] layer1Weights;
  float[] layer2Weights;

  Perceptron(float[] genotype) {
    this.genotype = genotype;
    this.layer1Weights = new float[8];
    this.layer2Weights = new float[3];

    for (int i = 0; i < 8; i++) {
      layer1Weights[i] = genotype[i];
    }

    for (int i = 0; i < 3; i++) {
      layer2Weights[i] = genotype[8 + i];
    }
  }

  float hiddenLayer(float[] inputs) {
    float activation = 0;
    for (int i = 0; i < inputs.length; i++) {
      activation += inputs[i] * layer1Weights[i];
    }

    return activation;
  }

  float[] getSoftMax(float[] inputs) {
    float prevLayer = hiddenLayer(inputs);
    float smSum = 0;
    float[] probDist = new float[layer2Weights.length];

    for (int i = 0; i < layer2Weights.length; i++) {
      smSum += Math.pow(Math.E, layer2Weights[i] * prevLayer);
    }

    for (int i = 0; i < layer2Weights.length; i++) {
      probDist[i] = (float) Math.pow(Math.E, layer2Weights[i] * prevLayer) / smSum;
    }

    return probDist;
  }

  int getIndex(float[] inputs) {
    float[] probDist = getSoftMax(inputs);
    float maxProb = probDist[0];
    int maxIndex = 0;

    for (int i = 1; i < probDist.length; i++) {
      if (probDist[i] > maxProb) {
        maxProb = probDist[i];
        maxIndex = i;
      }
    }

    return maxIndex;
  }
}
