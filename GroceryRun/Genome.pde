import java.util.Random;

class Genome {
  ArrayList<Connection> connectionList;
  ArrayList<Node> nodeList;
  int inputSize, outputSize;
  Node biasNode; // Needed to evolve XORS.

  Genome(int inputSize, int outputSize) {
    this.inputSize = inputSize;
    this.outputSize = outputSize;
    connectionList = new ArrayList<Connection>();
    nodeList = new ArrayList<Node>();

    for (int i = 0; i < inputSize; i++) {
      Node n = new Node(i);
      n.depth = 0;
      nodeList.add(n);
    }

    for (int i = 0; i < outputSize; i++) {
      Node n = new Node(i + inputSize);
      n.depth = 1;
      nodeList.add(n);
    }

    // Add bias node for XOR.
    biasNode = new Node(inputSize + outputSize);
    biasNode.depth = 0;
    nodeList.add(biasNode);
  }

  // This is for crossover genomes, that shouldn't fill up the lists automatically
  // and needs to get information from parents.
  Genome() {
    inputSize = 0;
    outputSize = 0;
    connectionList = new ArrayList<Connection>();
    nodeList = new ArrayList<Node>();
  }

  void mutateAddConnection(InnovationTracker innovationTracker, Random r) {
    // Only add connections if there is space.
    if (isFullyConnected()) {
      return;
    }

    Node nodeA, nodeB;
    do {
      nodeA = nodeList.get(r.nextInt(nodeList.size()));
      nodeB = nodeList.get(r.nextInt(nodeList.size()));
    } while (isInvalidNewConnection(nodeA, nodeB));

    // Input connects to hidden/output, and hidden connects to output.
    // If nodeB should connect to nodeA, then reverse is set to true.
    Node inNode = nodeA.depth < nodeB.depth ? nodeA : nodeB;
    Node outNode = nodeB.depth > nodeA.depth ? nodeB : nodeA;

    // Create Connection.
    // Weight should be between -1 and 1.
    Connection newConnection = new Connection(inNode, outNode, r.nextFloat() * 2.0 - 1.0, 0);
    innovationTracker.setInnovationNumber(newConnection);
     
    connectionList.add(newConnection);
  }

  void mutateAddNode(InnovationTracker innovationTracker, Random r) {
    // Can't add node if there are no connections.
    if (connectionList.isEmpty()) {
      mutateAddConnection(innovationTracker, r);
      return;
    }

    Connection oldConnection;

    // Cannot disconnect bias node as it should reach everything, so keep searching
    // for a connection that isn't using the bias node.
    do {
      oldConnection = connectionList.get(r.nextInt(connectionList.size()));
    } while (oldConnection.inNode.label == biasNode.label);
    
    Node inNode = oldConnection.inNode;
    Node outNode = oldConnection.outNode;

    // Disable oldConnection.
    oldConnection.enabled = false;

    Node newNode = new Node(nodeList.size());
    nodeList.add(newNode);

    // Add new connection.
    // Connect old inNode to newNode with weight of 1.
    Connection newConnection = new Connection(inNode, newNode, 1, 0);
    innovationTracker.setInnovationNumber(newConnection);
    connectionList.add(newConnection);

    // Update depth of newNode.
    newNode.depth = inNode.depth + 1;

    // Connect newNode to old outNode with weight of original connection.
    newConnection = new Connection(newNode, outNode, oldConnection.weight, 0);
    innovationTracker.setInnovationNumber(newConnection);
    connectionList.add(newConnection);

    // Connect bias to newNode with weight 0.
    newConnection = new Connection(biasNode, newNode, 0, 0);
    innovationTracker.setInnovationNumber(newConnection);
    connectionList.add(newConnection);

    // See if a new layer needs to be updated with the creation of this new node.
    // (i.e. newNode is on same depth as old outNode).
    if (newNode.depth == outNode.depth) {
      for (Node node : nodeList) {
        if (node.depth >= newNode.depth && node.label != newNode.label) {
          node.depth++;
        }
      }
    }
  }


  // Checks if a new connection can be made from node A to node B.
  boolean isInvalidNewConnection(Node nodeA, Node nodeB) {
    // Nodes cannot be in same layer or already have a connection.
    return nodeA.depth == nodeB.depth || isConnected(nodeA, nodeB);
  }

  // Checks if two nodes are connected.
  boolean isConnected(Node nodeA, Node nodeB) {
    // Nodes at same depth cannot be connected.
    if (nodeA.depth == nodeB.depth) {
      return false;
    }

    // Look for connection otherwise.
    for (Connection connection : connectionList) {
      if ((connection.inNode.label == nodeA.label && connection.outNode.label == nodeB.label) || (connection.inNode.label == nodeB.label && connection.outNode.label == nodeA.label)) {
        return true;
      }
    }

    return false;
  }


  // Check if network is fully connected.
  boolean isFullyConnected() {
    int maxConnections = 0; // Total amount of possible connections in the provided network.
    Map<Integer, Integer> layerSizeMap = new HashMap<Integer, Integer>(); // Maps layer to number of nodes in layer.

    for (Node node : nodeList) {
      int newCount = layerSizeMap.containsKey(node.depth) ? layerSizeMap.get(node.depth) + 1 : 1;
      layerSizeMap.put(node.depth, newCount);
    }


    // Calculate total possible connections.
    for (int i = 0; i < layerSizeMap.size() - 1; i++) {
      int potentialNodes = 0; // All potential nodes in front of layer i.
      for (int j = i + 1; j < layerSizeMap.size(); j++) {
        potentialNodes += layerSizeMap.get(j);
      }

      // Every node in layer i can connect to the potential nodes.
      maxConnections += layerSizeMap.get(i) * potentialNodes;
    }

    return maxConnections == connectionList.size();
  }

  // Mutate the genome.
  void mutate(InnovationTracker innovationTracker, Random r) {
    // Need a connection if there are no connections.
    if (connectionList.isEmpty()) {
      mutateAddConnection(innovationTracker, r);
    }

    // According to MIT paper, 80% chance of mutation in connection weights,
    // 5% chance of new connection, and 3% chance of new node.
    if (r.nextFloat() < 0.8) {
      for (Connection connection : connectionList) {
        connection.mutate(r);
      }
    }

    if (r.nextFloat() < 0.05) {
      mutateAddConnection(innovationTracker, r);
    }

    if (r.nextFloat() < 0.03) {
      mutateAddNode(innovationTracker, r);
    }
  }

  // Crossover between this genome (more fit) and other genome (less fit).
  Genome crossover(Genome otherLessFit, Random r) {
    Genome child = new Genome();
    child.inputSize = inputSize;
    child.outputSize = outputSize;

    // Maps a parent node to the copy in the child node. It's a little hackey, but I can't think of a better way at the moment.
    Map<Node, Node> parentToChild = new HashMap<Node, Node>();

    // Child takes all nodes from more fit parent, including excess and disjoint genes.
    for (Node node : nodeList) {
      Node copiedNode = node.copy();
      if (node.label == biasNode.label) {
        child.biasNode = copiedNode;
      }

      child.nodeList.add(copiedNode);
      parentToChild.put(node, copiedNode);
    }

    // Add all connections from parents.
    for (Connection p1Connection : connectionList) {
      Connection childConnection = new Connection(parentToChild.get(p1Connection.inNode), parentToChild.get(p1Connection.outNode), p1Connection.weight, p1Connection.innovation);
      childConnection.enabled = p1Connection.enabled;

      // Look for matching connection in p2.
      for (Connection p2Connection : otherLessFit.connectionList) {
        if (p1Connection.innovation == p2Connection.innovation) {
          // 50% chance of picking either parent.
          if (r.nextFloat() < 0.5) {
            childConnection.weight = p2Connection.weight;
          }

          // If either parent is disabled, 75% chance that child is also disabled. (You know, this sentence sounds really sad if you don't know we're talking about connections).
          if (!p1Connection.enabled || !p2Connection.enabled) {
            if (r.nextFloat() < 0.75) {
              childConnection.enabled = false;
            }
          }

          break;
        }

        // Add connection to child.
        child.connectionList.add(childConnection);
      }
    }
    
    return child;
  }

  float[] feedForward(float[] inputVals) {
    // Set up input layer.
    for (int i = 0; i < inputSize; i++) {
      nodeList.get(i).outputVal = inputVals[i];
    }
    biasNode.outputVal = 1; // Bias node output is 1.

    ArrayList<Node> network = getTopologicalNetwork();

    for (Node node : network) {
      float nodeOutput = node.activate();
      for (Connection connection : connectionList) {
        if (connection.inNode.label == node.label) {
          connection.outNode.inputVal += nodeOutput;
        }
      }
    }

    // Get result from output layer.
    float[] outputVals = new float[outputSize];
    for (int i = 0; i < outputSize; i++) {
      outputVals[i] = nodeList.get(inputSize + 1).outputVal;
    }

    // Reset nodes.
    for (Node node : nodeList) {
      node.inputVal = 0;
    }

    return outputVals;
  }

  // List nodes in order in which they should be activated (used for feedForward).
  ArrayList<Node> getTopologicalNetwork() {
    ArrayList<Node> network = new ArrayList<Node>();

    // Find maximum depth.
    int maxDepth = 0;
    for (Node node : nodeList) {
      maxDepth = Math.max(maxDepth, node.depth);
    }

    // Topological sort. There is definitely a better way time complexity wise to do this.
    for (int i = 0; i <= maxDepth; i++) {
      for (Node node : nodeList) {
        if (node.depth == i) {
          network.add(node);
        }
      }
    }
    
    return network;
  }
}
