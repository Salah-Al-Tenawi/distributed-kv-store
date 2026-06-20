import '../repositories/cluster_repository.dart';

/// Use Case: إحياء عقدة بعد قتلها.
class ReviveNode {
  final ClusterRepository repository;

  const ReviveNode(this.repository);

  Future<void> call(int port) => repository.reviveNode(port);
}
