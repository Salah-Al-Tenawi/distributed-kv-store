import 'package:get_it/get_it.dart';

import '../../features/cluster/data/datasources/cluster_remote_data_source.dart';
import '../../features/cluster/data/repositories/cluster_repository_impl.dart';
import '../../features/cluster/domain/repositories/cluster_repository.dart';
import '../../features/cluster/domain/usecases/acquire_lock.dart';
import '../../features/cluster/domain/usecases/delete_key.dart';
import '../../features/cluster/domain/usecases/kill_node.dart';
import '../../features/cluster/domain/usecases/release_lock.dart';
import '../../features/cluster/domain/usecases/put_key.dart';
import '../../features/cluster/domain/usecases/revive_node.dart';
import '../../features/cluster/domain/usecases/watch_cluster.dart';
import '../../features/cluster/presentation/cubit/cluster_cubit.dart';

final GetIt sl = GetIt.instance;

Future<void> initDependencies() async {

  sl.registerLazySingleton<ClusterRemoteDataSource>(
    () => ClusterRemoteDataSource(),
  );

  sl.registerLazySingleton<ClusterRepository>(
    () => ClusterRepositoryImpl(sl()),
  );

  sl.registerLazySingleton(() => WatchCluster(sl()));
  sl.registerLazySingleton(() => KillNode(sl()));
  sl.registerLazySingleton(() => ReviveNode(sl()));
  sl.registerLazySingleton(() => PutKey(sl()));
  sl.registerLazySingleton(() => DeleteKey(sl()));
  sl.registerLazySingleton(() => AcquireLock(sl()));
  sl.registerLazySingleton(() => ReleaseLock(sl()));

  sl.registerFactory(
    () => ClusterCubit(
      watchCluster: sl(),
      killNode: sl(),
      reviveNode: sl(),
      putKey: sl(),
      deleteKey: sl(),
      acquireLock: sl(),
      releaseLock: sl(),
      repository: sl(),
    ),
  );
}
