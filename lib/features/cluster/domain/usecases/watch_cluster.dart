import '../entities/cluster_node.dart';
import '../repositories/cluster_repository.dart';

class WatchCluster {
  final ClusterRepository repository;

  const WatchCluster(this.repository);

  Stream<ClusterNode> call() => repository.watchNodes();
}
