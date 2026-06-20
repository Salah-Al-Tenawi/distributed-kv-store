import '../../domain/entities/cluster_node.dart';
import '../../domain/repositories/cluster_repository.dart';
import '../datasources/cluster_remote_data_source.dart';

/// التنفيذ الفعلي للمستودع: يربط طبقة الـ domain بمصدر البيانات (WebSocket).
class ClusterRepositoryImpl implements ClusterRepository {
  final ClusterRemoteDataSource remoteDataSource;

  ClusterRepositoryImpl(this.remoteDataSource);

  @override
  Stream<ClusterNode> watchNodes() => remoteDataSource.stream;

  @override
  Future<void> connect() async => remoteDataSource.connect();

  @override
  Future<void> disconnect() async => remoteDataSource.dispose();

  @override
  Future<void> killNode(int port) => remoteDataSource.killNode(port);

  @override
  Future<void> reviveNode(int port) => remoteDataSource.reviveNode(port);
}
