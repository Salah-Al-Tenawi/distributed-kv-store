import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/cluster_node.dart';
import '../../domain/repositories/cluster_repository.dart';
import '../../domain/usecases/acquire_lock.dart';
import '../../domain/usecases/delete_key.dart';
import '../../domain/usecases/kill_node.dart';
import '../../domain/usecases/put_key.dart';
import '../../domain/usecases/release_lock.dart';
import '../../domain/usecases/revive_node.dart';
import '../../domain/usecases/watch_cluster.dart';

part 'cluster_state.dart';

class ClusterCubit extends Cubit<ClusterState> {
  final WatchCluster watchCluster;
  final KillNode killNode;
  final ReviveNode reviveNode;
  final PutKey putKey;
  final DeleteKey deleteKey;
  final AcquireLock acquireLock;
  final ReleaseLock releaseLock;
  final ClusterRepository repository;

  StreamSubscription<ClusterNode>? _subscription;

  ClusterCubit({
    required this.watchCluster,
    required this.killNode,
    required this.reviveNode,
    required this.putKey,
    required this.deleteKey,
    required this.acquireLock,
    required this.releaseLock,
    required this.repository,
  }) : super(const ClusterState());

  Future<void> start() async {
    _subscription = watchCluster().listen(_onNodeUpdate);
    await repository.connect();
    emit(state.copyWith(connected: true));
  }

  void _onNodeUpdate(ClusterNode node) {

    final updated = Map<String, ClusterNode>.from(state.nodes);
    updated[node.id] = node;
    emit(state.copyWith(nodes: updated));
  }

  Future<void> kill(int port) => killNode(port);

  Future<void> revive(int port) => reviveNode(port);

  Future<void> put(String key, String value) async {
    final port = state.leaderPort;
    if (port != null) await putKey(port, key, value);
  }

  Future<void> delete(String key) async {
    final port = state.leaderPort;
    if (port != null) await deleteKey(port, key);
  }

  Future<void> partitionNetwork() async {
    final ids = state.sortedNodes.map((n) => n.id).toList();
    if (ids.length < 3) return;
    final groupA = ids.take(2).toSet();
    for (final node in state.sortedNodes) {
      final inA = groupA.contains(node.id);
      final blocked =
          state.sortedNodes
              .where((n) => groupA.contains(n.id) != inA)
              .map((n) => n.id)
              .toList();
      await repository.partitionNode(node.port, blocked);
    }
  }

  Future<void> healNetwork() async {
    for (final node in state.sortedNodes) {
      await repository.healNode(node.port);
    }
  }

  Future<void> acquire(String lockName, String clientId) async {
    final port = state.leaderPort;
    if (port != null) await acquireLock(port, lockName, clientId);
  }

  Future<void> release(String lockName, String clientId) async {
    final port = state.leaderPort;
    if (port != null) await releaseLock(port, lockName, clientId);
  }

  Future<void> runTransaction(List<Map<String, String>> operations) async {
    final port = state.leaderPort;
    if (port != null) await repository.runTransaction(port, operations);
  }

  Future<void> toggleVoteAbort(int port, bool value) =>
      repository.setVoteAbort(port, value);

  Future<void> vcEvent(int port) => repository.vcEvent(port);

  Future<void> vcSend(int fromPort, String toId) =>
      repository.vcSend(fromPort, toId);

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    await repository.disconnect();
    return super.close();
  }
}
