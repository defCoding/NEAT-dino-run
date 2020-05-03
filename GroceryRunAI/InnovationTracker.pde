import java.util.Map;
import java.util.HashMap;

class InnovationTracker {
  Map<Connection, Integer> connectionInnovation;
  int nextInnovationNumber; // The next innovation number to assign.

  InnovationTracker() {
    connectionInnovation = new HashMap<Connection, Integer>();
    nextInnovationNumber = 0;
  }
  
  void reset() {
    connectionInnovation.clear();
  }
  
  void setInnovationNumber(Connection connection) {
    if (!connectionInnovation.containsKey(connection)) {
      connectionInnovation.put(connection, nextInnovationNumber++);
    }

    connection.innovation = connectionInnovation.get(connection);
  }

  int size() {
    return connectionInnovation.size();
  }
}
