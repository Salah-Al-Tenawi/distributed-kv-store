import '../repositories/cluster_repository.dart';

class KillNode {
  final ClusterRepository repository;

  const KillNode(this.repository);

  Future<void> call(int port) => repository.killNode(port);
}
