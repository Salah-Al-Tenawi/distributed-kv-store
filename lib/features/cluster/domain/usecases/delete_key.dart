import '../repositories/cluster_repository.dart';

/// Use Case: حذف مفتاح من المخزن (يُرسَل للقائد).
class DeleteKey {
  final ClusterRepository repository;

  const DeleteKey(this.repository);

  Future<void> call(int leaderPort, String key) =>
      repository.deleteKey(leaderPort, key);
}
