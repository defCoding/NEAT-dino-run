class ConnectionLog {
  int inNodeLabel;
  int outNodeLabel;
  int innovation;
  ArrayList<Integer> innovationLog;

  ConnectionLog(int inNodeLabel, int outNodeLabel, int innovation, ArrayList<Integer> innovationLog) {
    this.inNodeLabel = inNodeLabel;
    this.outNodeLabel = outNodeLabel;
    this.innovation = innovation;
    this.innovationLog = (ArrayList) innovationLog.clone();
  }

  boolean alleleMatches(Genome genome, Connection connection) {
    if (genome.connectionList.size() == innovationLog.size()) {
      if (inNodeLabel == connection.inNode.label && outNodeLabel == connection.outNode.label) {
        // InnovationLog should contain every mutation found in the genome.
        for (Connection gConnection : genome.connectionList) {
          if (!innovationLog.contains(gConnection.innovation)) {
            return false;
          }
        }

        return true;
      }
    }
    return false;
  }
}
