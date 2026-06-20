import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/cluster_node.dart';
import '../../domain/repositories/cluster_repository.dart';
import '../../domain/usecases/kill_node.dart';
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
  final ClusterRepository repository;

  StreamSubscription<ClusterNode>? _subscription;

  ClusterCubit({
    required this.watchCluster,
    required this.killNode,
    required this.reviveNode,
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

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    await repository.disconnect();
    return super.close();
  }
}
