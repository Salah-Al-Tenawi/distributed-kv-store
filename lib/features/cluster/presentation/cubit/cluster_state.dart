part of 'cluster_cubit.dart';

class ClusterState extends Equatable {
  final Map<String, ClusterNode> nodes;
  final bool connected;

  const ClusterState({
    this.nodes = const {},
    this.connected = false,
  });

  List<ClusterNode> get sortedNodes {
    final list = nodes.values.toList();
    list.sort((a, b) => a.id.compareTo(b.id));
    return list;
  }

  ClusterNode? get leader {
    for (final node in nodes.values) {
      if (node.isLeader && node.online) return node;
    }
    return null;
  }

  int? get leaderPort => leader?.port;

  bool get isPartitioned => nodes.values.any((n) => n.isPartitioned);

  Set<String> get suspectedByLeader {
    for (final node in nodes.values) {
      if (node.isLeader) return node.suspectedOffline.toSet();
    }
    return const {};
  }

  bool isOffline(ClusterNode node) =>
      !node.online || suspectedByLeader.contains(node.id);

  ClusterState copyWith({
    Map<String, ClusterNode>? nodes,
    bool? connected,
  }) {
    return ClusterState(
      nodes: nodes ?? this.nodes,
      connected: connected ?? this.connected,
    );
  }

  @override
  List<Object?> get props => [nodes, connected];
}
