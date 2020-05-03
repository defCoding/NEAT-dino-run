class ConnectionLog {
  int inNode;
  int outNode;
  int innovation;
  
  ArrayList<Integer> innovationLog = new ArrayList<Integer>(); // This will let us track the innoation numbers from the first genome that had this mutation.
  // Genomes that do not follow this innovationLog do not count as the same allele, and thus will not cross over at this.
  
  ConnectionLog(Node inNode, Node outNode, int innovation, ArrayList<Integer> innovationLog) {
    this.inNode = inNode.label;
    this.outNode = outNode.label;
    this.innovation = innovation;
    this.innovationLog = (ArrayList) innovationLog.clone();
  }
  
  boolean checkHomology(Genome genome, Node inNode, Node outNode) {
    if (genome.connectionList.size() == innovationLog.size()) { // Number of connections must equal number of mutations first of all.
      if (inNode.label == this.inNode && outNode.label == this.inNode) {
        // Check that all innovation numbers match.
        for (Connection connection : genome.connectionList) {
          if (!innovationLog.contains(connection.innovation)) {  
            return false;
          }
        }
        // Everything matched
        return true;
      }
    }
    
    return false;
  }
}
    
