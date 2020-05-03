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
      outputVal = sigmoid(inputVal);
    } else {
      outputVal = 0;
    }
    
    return outputVal;
  }

  float sigmoid(float input) {
    // MIT paper uses modified sigmoid function. (-4.5x instead of -x)
    return 1 / (1 + (float) Math.pow(Math.E, -4.5 * input));
  }
  
  boolean equals(Object other) {
    if (other instanceof Node) {
      Node otherNode = (Node) other;
      return label == otherNode.label;
    }
    return false;
  }
  
  int hashCode() {
    return new Integer(label).hashCode();
  }

  Node copy() {
    Node copy =new Node(label);
    copy.depth = depth;
    return copy;
  }
}
