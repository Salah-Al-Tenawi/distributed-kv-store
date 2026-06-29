import '../repositories/cluster_repository.dart';

class AcquireLock {
  final ClusterRepository repository;

  const AcquireLock(this.repository);

  Future<void> call(int leaderPort, String lockName, String clientId) =>
      repository.acquireLock(leaderPort, lockName, clientId);
}
