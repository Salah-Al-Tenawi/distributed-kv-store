import '../repositories/cluster_repository.dart';

/// Use Case: كتابة/تحديث مفتاح في المخزن (يُرسَل للقائد).
class PutKey {
  final ClusterRepository repository;

  const PutKey(this.repository);

  Future<void> call(int leaderPort, String key, String value) =>
      repository.putKey(leaderPort, key, value);
}
