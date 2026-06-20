part of 'cluster_cubit.dart';

/// حالة شاشة العنقود. نحتفظ بالعُقَد في خريطة (id -> node) لتحديث
/// عقدة واحدة بسهولة عند وصول تحديثها دون لمس الباقي.
class ClusterState extends Equatable {
  final Map<String, ClusterNode> nodes;
  final bool connected;

  const ClusterState({
    this.nodes = const {},
    this.connected = false,
  });

  /// قائمة مرتّبة بالعُقَد (حسب المعرّف) للعرض.
  List<ClusterNode> get sortedNodes {
    final list = nodes.values.toList();
    list.sort((a, b) => a.id.compareTo(b.id));
    return list;
  }

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
