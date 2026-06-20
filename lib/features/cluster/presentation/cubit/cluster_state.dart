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

  /// القائد الحالي إن وُجد (وكان حيّاً)، وإلا null.
  ClusterNode? get leader {
    for (final node in nodes.values) {
      if (node.isLeader && node.online) return node;
    }
    return null;
  }

  /// منفذ القائد الحالي — نرسل إليه أوامر الكتابة (PUT/DEL).
  int? get leaderPort => leader?.port;

  /// القُرَناء الذين يشكّ القائد الحالي (Leader) بموتهم.
  Set<String> get suspectedByLeader {
    for (final node in nodes.values) {
      if (node.isLeader) return node.suspectedOffline.toSet();
    }
    return const {};
  }

  /// هل العقدة تُعدّ ميتة؟ إمّا أبلغت عن نفسها (online=false)،
  /// أو القائد يشكّ بموتها (لم تردّ على نبضاته).
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
