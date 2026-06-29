import '../repositories/cluster_repository.dart';

class ReviveNode {
  final ClusterRepository repository;

  const ReviveNode(this.repository);

  Future<void> call(int port) => repository.reviveNode(port);
}
