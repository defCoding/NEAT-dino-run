import java.util.ArrayList;

class Node {
  float inputVal, outputVal; // Input: values coming into node | Output: value after activation
  int depth; // Depth of the node in the neural network.
  int label; // Give this node a label.

  Node(int label) {
    this.label = label;
    depth = 0;
  }

  float activate() {
    // Inputs and bias don't apply sigmoid.
    if (depth != 0) {
      return sigmoid(inputVal);
    } else {
      return 0;
    }
  }

  float sigmoid(float input) {
    // MIT paper uses modified sigmoid function. (-4.5x instead of -x)
    return 1 / (1 + (float) Math.pow(Math.E, -4.5 * input));
  }

  Node copy() {
    return new Node(label);
  }
}
