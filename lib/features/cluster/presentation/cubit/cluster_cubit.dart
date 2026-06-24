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

/// الـ Cubit: يدير حالة شاشة العنقود.
///
/// يستمع لتيّار العُقَد عبر الـ use case، ويحدّث الـ state كلما وصلت
/// حالة عقدة جديدة. لا يعرف شيئاً عن WebSocket — فقط use cases.
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

  /// يبدأ الاتصال بالعنقود ويستمع للتحديثات.
  Future<void> start() async {
    _subscription = watchCluster().listen(_onNodeUpdate);
    await repository.connect();
    emit(state.copyWith(connected: true));
  }

  void _onNodeUpdate(ClusterNode node) {
    // ننسخ الخريطة الحالية ونضع/نحدّث العقدة الواصلة.
    final updated = Map<String, ClusterNode>.from(state.nodes);
    updated[node.id] = node;
    emit(state.copyWith(nodes: updated));
  }

  /// قتل عقدة (محاكاة Crash) — نمرّر منفذها للـ backend.
  Future<void> kill(int port) => killNode(port);

  /// إحياء عقدة بعد قتلها.
  Future<void> revive(int port) => reviveNode(port);

  /// كتابة مفتاح: نرسلها لمنفذ القائد الحالي (الكتابة للقائد فقط).
  Future<void> put(String key, String value) async {
    final port = state.leaderPort;
    if (port != null) await putKey(port, key, value);
  }

  /// حذف مفتاح: نرسلها لمنفذ القائد الحالي.
  Future<void> delete(String key) async {
    final port = state.leaderPort;
    if (port != null) await deleteKey(port, key);
  }

  /// يقسم الشبكة إلى مجموعتين: {أول عقدتين} ⟷ {الباقي}.
  /// كل عقدة تُحجب عن المجموعة الأخرى — لمحاكاة Network Partition.
  Future<void> partitionNetwork() async {
    final ids = state.sortedNodes.map((n) => n.id).toList();
    if (ids.length < 3) return;
    final groupA = ids.take(2).toSet(); // الأقلية
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

  /// يشفي الشبكة: يزيل كل الحجب عن جميع العُقَد.
  Future<void> healNetwork() async {
    for (final node in state.sortedNodes) {
      await repository.healNode(node.port);
    }
  }

  /// طلب قفل باسم عميل معيّن (يُرسَل للقائد).
  Future<void> acquire(String lockName, String clientId) async {
    final port = state.leaderPort;
    if (port != null) await acquireLock(port, lockName, clientId);
  }

  /// تحرير قفل (يُرسَل للقائد).
  Future<void> release(String lockName, String clientId) async {
    final port = state.leaderPort;
    if (port != null) await releaseLock(port, lockName, clientId);
  }

  /// يشغّل معاملة 2PC على القائد (مجموعة عمليات ذرّية).
  Future<void> runTransaction(List<Map<String, String>> operations) async {
    final port = state.leaderPort;
    if (port != null) await repository.runTransaction(port, operations);
  }

  /// يبدّل تصويت عقدة على ABORT في 2PC (لمحاكاة الرفض).
  Future<void> toggleVoteAbort(int port, bool value) =>
      repository.setVoteAbort(port, value);

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    await repository.disconnect();
    return super.close();
  }
}
