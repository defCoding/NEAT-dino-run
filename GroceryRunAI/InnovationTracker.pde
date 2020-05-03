import java.util.Map;
import java.util.HashMap;

class InnovationTracker {
  ArrayList<ConnectionLog> connectionLogTracker;
  int nextInnovationNumber; // The next innovation number to assign.

  InnovationTracker() {
    connectionLogTracker = new ArrayList<ConnectionLog>();
    nextInnovationNumber = 0;
  }
  
  void reset() {
    connectionLogTracker.clear();
    nextInnovationNumber = 0;
  }
 
  void setInnovationNumber(Genome genome, Connection connection) {
    boolean found = false;

    for (ConnectionLog connectionLog : connectionLogTracker) {
      if (connectionLog.alleleMatches(genome, connection)) {
        found = true;
        connection.innovation = connectionLog.innovation;
        break;
      }
    }

    if (!found) {
      connection.innovation = nextInnovationNumber++;
      ArrayList<Integer> innovationLog = new ArrayList<Integer>();

      for (Connection gConnection : genome.connectionList) {
        innovationLog.add(gConnection.innovation);
      }

      ConnectionLog newLog = new ConnectionLog(connection.inNode.label, connection.outNode.label, connection.innovation, innovationLog);

      connectionLogTracker.add(newLog);
    }
  }

  int size() {
    return connectionLogTracker.size();
  }
}
