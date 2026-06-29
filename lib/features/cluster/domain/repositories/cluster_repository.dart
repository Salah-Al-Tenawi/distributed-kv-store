import '../entities/cluster_node.dart';

abstract class ClusterRepository {

  Stream<ClusterNode> watchNodes();

  Future<void> connect();

  Future<void> disconnect();

  Future<void> killNode(int port);

  Future<void> reviveNode(int port);

  Future<void> putKey(int leaderPort, String key, String value);

  Future<void> deleteKey(int leaderPort, String key);

  Future<void> partitionNode(int port, List<String> blocked);

  Future<void> healNode(int port);

  Future<void> acquireLock(int leaderPort, String lockName, String clientId);

  Future<void> releaseLock(int leaderPort, String lockName, String clientId);

  Future<void> runTransaction(
    int leaderPort,
    List<Map<String, String>> operations,
  );

  Future<void> setVoteAbort(int port, bool value);

  Future<void> vcEvent(int port);

  Future<void> vcSend(int fromPort, String toId);
}
