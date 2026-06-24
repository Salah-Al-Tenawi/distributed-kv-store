import '../../domain/entities/cluster_node.dart';
import '../../domain/repositories/cluster_repository.dart';
import '../datasources/cluster_remote_data_source.dart';

/// التنفيذ الفعلي للمستودع: يربط طبقة الـ domain بمصدر البيانات (WebSocket).
class ClusterRepositoryImpl implements ClusterRepository {
  final ClusterRemoteDataSource remoteDataSource;

  ClusterRepositoryImpl(this.remoteDataSource);

  @override
  Stream<ClusterNode> watchNodes() => remoteDataSource.stream;

  @override
  Future<void> connect() async => remoteDataSource.connect();

  @override
  Future<void> disconnect() async => remoteDataSource.dispose();

  @override
  Future<void> killNode(int port) => remoteDataSource.killNode(port);

  @override
  Future<void> reviveNode(int port) => remoteDataSource.reviveNode(port);

  @override
  Future<void> putKey(int leaderPort, String key, String value) =>
      remoteDataSource.putKey(leaderPort, key, value);

  @override
  Future<void> deleteKey(int leaderPort, String key) =>
      remoteDataSource.deleteKey(leaderPort, key);

  @override
  Future<void> partitionNode(int port, List<String> blocked) =>
      remoteDataSource.partitionNode(port, blocked);

  @override
  Future<void> healNode(int port) => remoteDataSource.healNode(port);

  @override
  Future<void> acquireLock(int leaderPort, String lockName, String clientId) =>
      remoteDataSource.acquireLock(leaderPort, lockName, clientId);

  @override
  Future<void> releaseLock(int leaderPort, String lockName, String clientId) =>
      remoteDataSource.releaseLock(leaderPort, lockName, clientId);

  @override
  Future<void> runTransaction(
    int leaderPort,
    List<Map<String, String>> operations,
  ) =>
      remoteDataSource.runTransaction(leaderPort, operations);

  @override
  Future<void> setVoteAbort(int port, bool value) =>
      remoteDataSource.setVoteAbort(port, value);

  @override
  Future<void> vcEvent(int port) => remoteDataSource.vcEvent(port);

  @override
  Future<void> vcSend(int fromPort, String toId) =>
      remoteDataSource.vcSend(fromPort, toId);
}
