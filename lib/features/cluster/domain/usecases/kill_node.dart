import '../repositories/cluster_repository.dart';

/// Use Case: قتل عقدة (محاكاة تعطّل / Crash) لاختبار كشف الأعطال.
class KillNode {
  final ClusterRepository repository;

  const KillNode(this.repository);

  Future<void> call(int port) => repository.killNode(port);
}
