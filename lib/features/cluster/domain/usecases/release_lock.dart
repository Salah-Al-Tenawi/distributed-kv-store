import '../repositories/cluster_repository.dart';

/// Use Case: تحرير قفل موزّع (يُرسَل للقائد).
class ReleaseLock {
  final ClusterRepository repository;

  const ReleaseLock(this.repository);

  Future<void> call(int leaderPort, String lockName, String clientId) =>
      repository.releaseLock(leaderPort, lockName, clientId);
}
