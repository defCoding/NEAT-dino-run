import java.util.Random;
import java.util.Map;
import java.util.HashMap;

class Genome {
  ArrayList<Connection> connectionList;
  ArrayList<Node> nodeList;
  int inputSize, outputSize;
  Node biasNode; // Needed to evolve XORS.
  ArrayList<Node> neuralNetwork; // So that we don't recalculate every time we want to feedForward.
  int totalLayers;

  Genome(int inputSize, int outputSize) {
    this.inputSize = inputSize;
    this.outputSize = outputSize;
    connectionList = new ArrayList<Connection>();
    nodeList = new ArrayList<Node>();
    neuralNetwork = new ArrayList<Node>();

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
    totalLayers = 2;
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
    } while (oldConnection.inNode.label == biasNode.label && connectionList.size() > 1);
    
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
      totalLayers++;
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
    int[] layerSizeMap = new int[totalLayers];

    for (Node node : nodeList) {
      layerSizeMap[node.depth] += 1;
    }


    // Calculate total possible connections.
    for (int i = 0; i < totalLayers - 1; i++) {
      int potentialNodes = 0; // All potential nodes in front of layer i.
      for (int j = i + 1; j < totalLayers; j++) {
        potentialNodes += totalLayers;
      }

      // Every node in layer i can connect to the potential nodes.
      maxConnections += totalLayers * potentialNodes;
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

    if (r.nextFloat() < 0.1) {
      mutateAddConnection(innovationTracker, r);
    }

    if (r.nextFloat() < 0.01) {
      mutateAddNode(innovationTracker, r);
    }
  }

  // Crossover between this genome (more fit) and other genome (less fit).
  Genome crossover(Genome otherLessFit, Random r) {
    Genome child = new Genome();
    child.inputSize = inputSize;
    child.outputSize = outputSize;
    child.totalLayers = totalLayers;

    // Maps a parent node to the copy in the child node. It's a little hackey, but I can't think of a better way at the moment.
    Map<Node, Node> parentToChild = new HashMap<Node, Node>();

    // Child takes all nodes from more fit parent, including excess and disjoint genes.
    for (Node node : nodeList) {
      Node copiedNode = node.copy();
      if (copiedNode.label == biasNode.label) {
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
      }
      // Add connection to child.
      child.connectionList.add(childConnection);
    }
    
    return child;
  }

  float[] feedForward(float[] inputVals) {
    // Set up input layer.
    for (int i = 0; i < inputSize; i++) {
      nodeList.get(i).outputVal = inputVals[i];
    }
    biasNode.outputVal = 1; // Bias node output is 1.

    for (Node node : neuralNetwork) {
      float nodeOutput = node.activate();
      for (Connection connection : connectionList) {
        if (connection.inNode.label == node.label && connection.enabled) {
          connection.outNode.inputVal += nodeOutput * connection.weight;
        }
      }
    }

    // Get result from output layer.
    float[] outputVals = new float[outputSize];
    for (int i = 0; i < outputSize; i++) {
      outputVals[i] = nodeList.get(inputSize + i).outputVal;
    }

    // Reset nodes.
    for (Node node : nodeList) {
      node.inputVal = 0;
      node.outputVal = 0;
    }

    return outputVals;
  }

  // List nodes in order in which they should be activated (used for feedForward).
  void generateTopologicalNetwork() {
    // Clear network.
    neuralNetwork = new ArrayList<Node>();

    // Topological sort.
    for (int i = 0; i < totalLayers; i++) {
      for (Node node : nodeList) {
        if (node.depth == i) {
          neuralNetwork.add(node);
        }
      }
    }
  }

  // Clones this genome.
  Genome copy() {
    Genome copy = new Genome();
    copy.inputSize = inputSize;
    copy.outputSize = outputSize;
    copy.totalLayers = totalLayers;

    Map<Node, Node> parentToCopy = new HashMap<Node, Node>();

    // Copy over nodes.
    for (Node node : nodeList) {
      Node copiedNode = node.copy();
      if (copiedNode.label == biasNode.label) {
        copy.biasNode = copiedNode;
      }

      copy.nodeList.add(copiedNode);
      parentToCopy.put(node, copiedNode);
    }

    // Copy over connections.
    for (Connection connection : connectionList) {
      Connection copyConnection = new Connection(parentToCopy.get(connection.inNode), parentToCopy.get(connection.outNode), connection.weight, connection.innovation);
      copyConnection.enabled = connection.enabled;
     

      copy.connectionList.add(copyConnection);
    }

    return copy;
  }
  
  void drawGenome(int x, int y, int w, int h) {
      Map<Node, PVector> nodeToLocation = new HashMap<Node, PVector>();
      Map<PVector, Number> numberForLocation = new HashMap<PVector, Number>();
      ArrayList<ArrayList<Node>> nodesByLayer = new ArrayList<ArrayList<Node>>(totalLayers);

      for (int i = 0; i < totalLayers; i++) {
        nodesByLayer.add(new ArrayList<Node>());
      }

      for (Node node : nodeList) {
        nodesByLayer.get(node.depth).add(node);
      }
      
      for (int i = 0; i < totalLayers; i++) {
        float xPos = x + ((float) w / totalLayers) * i;
        ArrayList<Node> nodesInLayerI = nodesByLayer.get(i);
        for (int j = 0; j < nodesInLayerI.size(); j++) {
          float yPos = y + ((float) h / nodesInLayerI.size()) * j;
          PVector pos = new PVector(xPos, yPos);
          nodeToLocation.put(nodesInLayerI.get(j), pos);
          numberForLocation.put(pos, nodesInLayerI.get(j).label);
        }
      }
     
      
      for (Connection connection : connectionList) {
        PVector in = nodeToLocation.get(connection.inNode);
        PVector out = nodeToLocation.get(connection.outNode);
        
        if (connection.weight > 0) {
          stroke(255, 0, 0);
        } else {
          stroke(0, 0, 255);
        }
        
        if (!connection.enabled) {
          stroke(171, 171, 171);
        }
        
        strokeWeight(map(abs(connection.weight), 0, 1, 0, 3));
        line(in.x, in.y, out.x, out.y);
      }
      

      stroke(0);
      strokeWeight(1);
      textSize(8);
      textAlign(CENTER, CENTER);

      for (PVector pos : numberForLocation.keySet()) {
        fill(255);
        ellipse(pos.x, pos.y, 15, 15);
        fill(0);
        text(numberForLocation.get(pos) + "", pos.x, pos.y);
      }

      // Draw labels.
      textSize(10);
      textAlign(LEFT);
      int input = 7;
      int output = nodeList.size() - 4;
      String inputStrings[] = {"Distance from obstacle.", "yPos of obstacle.", "Height of obstacle.", "Width of obstacle.", "Obstacle speed.", "Gap between next two.", "yPos of player."};
      String outputStrings[] = {"Crouch.", "Small jump.", "Regular Jump"};
      for (int i = 0; i < inputSize; i++) {
        PVector pos = nodeToLocation.get(nodeList.get(i));
        text(inputStrings[i], pos.x - 130, pos.y);
      }

      for (int i = 0; i < outputSize; i++) {
        PVector pos = nodeToLocation.get(nodeList.get(inputSize + i));
        text(outputStrings[i], pos.x + 20, pos.y);
      }

      PVector biasPos = nodeToLocation.get(biasNode);
      text("Bias", biasPos.x - 130, biasPos.y);
  }
}
