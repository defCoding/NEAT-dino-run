import numpy as np

class Perceptron:
  def __init__(self, weights, biases, threshold):
    self.weights = weights
    self.biases = biases
    self.threshold = threshold

  # gets output of basic perceptron
  def get_output(self, inputs):
    activation = np.matmul(inputs, self.weights)
    
    for bias in range(len(self.biases)):
      activation += self.biases[bias]

    if activation > self.threshold:
      return 1

    return 0

class MultilayerPerceptron:
  def __init__(self, layer1_weights, layer2_weights):
    self.layer1_weights = layer1_weights
    self.layer2_weights = layer2_weights
    
  # gets the hidden layer activation (hidden layer only contains one node)
  def hidden_layer(self, inputs):
    activation = np.matmul(inputs, self.layer1_weights)
    return activation

  # gets the softmax probability distribution
  def get_softmax(self, inputs):
    prev_layer = self.hidden_layer(inputs)
    sm_sum = 0
    prob_dist = []
    
    for weight in range(len(self.layer2_weights)):
      sm_sum += np.exp(prev_layer * self.layer2_weights[weight])
      
    for weight in range(len(self.layer2_weights)):
      prob_dist.append(np.exp(prev_layer* self.layer2_weights[weight])/sm_sum)

    return prob_dist
  
  # gets the index of the largest probability in the softmax probability distribution
  # the idea is there will be a corresponding list of actions the player can choose from
  def get_index(self, inputs):
    prob_dist = self.get_softmax(inputs)
    max_prob = 0 
    prob_index = 0

    for prob in range(len(prob_dist)):
      if prob_dist[prob] > max_prob:
        max_prob = prob_dist[prob]
        prob_index = prob

    return prob_index 
