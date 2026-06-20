import '../entities/cluster_node.dart';
import '../repositories/cluster_repository.dart';

/// Use Case: مراقبة تغيّرات العُقَد.
///
/// الـ use case يمثّل "فعلاً" واحداً في النظام. هنا فعلنا هو: راقب العنقود.
/// الـ Cubit يستدعيه بدل أن يتعامل مع المستودع مباشرة — يبقي المنطق منظّماً.
class WatchCluster {
  final ClusterRepository repository;

  const WatchCluster(this.repository);

  Stream<ClusterNode> call() => repository.watchNodes();
}
