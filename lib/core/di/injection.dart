import 'package:get_it/get_it.dart';

import '../../features/cluster/data/datasources/cluster_remote_data_source.dart';
import '../../features/cluster/data/repositories/cluster_repository_impl.dart';
import '../../features/cluster/domain/repositories/cluster_repository.dart';
import '../../features/cluster/domain/usecases/watch_cluster.dart';
import '../../features/cluster/presentation/cubit/cluster_cubit.dart';

/// حاوية حقن التبعيّات (Service Locator) باستخدام get_it.
/// نسجّل كل الطبقات هنا مرة واحدة، ونطلبها عند الحاجة.
final GetIt sl = GetIt.instance;

Future<void> initDependencies() async {
  // Data sources
  sl.registerLazySingleton<ClusterRemoteDataSource>(
    () => ClusterRemoteDataSource(),
  );

  // Repositories
  sl.registerLazySingleton<ClusterRepository>(
    () => ClusterRepositoryImpl(sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => WatchCluster(sl()));

  // Cubit (factory: نسخة جديدة عند كل طلب)
  sl.registerFactory(
    () => ClusterCubit(watchCluster: sl(), repository: sl()),
  );
}
