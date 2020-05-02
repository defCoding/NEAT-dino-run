import java.util.Random;

class Connection {
  Node inNode;
  Node outNode;
  float weight;
  boolean enabled;
  int innovation;

  Connection(Node inNode, Node outNode, float weight, int innovation) {
    this.inNode = inNode;
    this.outNode = outNode;
    this.weight = weight;
    this.innovation = innovation;
    this.enabled = true; // Enabled by default.
  }

  // Mutates the weight.
  void mutate(Random r) {
    // According to MIT paper, 90% chance of uniform perturbance, and 10% chance of
    // completely random weight.
    if (r.nextFloat() < 0.9) {
      weight += r.nextGaussian() / 40; // Keep it small.

      // Bound weight to (-1, 1)
      weight = Math.min(1, weight);
      weight = Math.max(-1, weight);
    } else {
      weight = r.nextInt(2) - 1;
    }
  }

  // This is just used for hashing. Do not dare use it for anything else.
  boolean equals(Object other) {
    if (other instanceof Connection) {
      Connection otherNode = (Connection) other;
      return inNode.label == otherNode.inNode.label && outNode.label == otherNode.outNode.label;
    }

    return false;
  }
}
