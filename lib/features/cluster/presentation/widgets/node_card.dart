import 'package:flutter/material.dart';

import '../../domain/entities/cluster_node.dart';

/// بطاقة تعرض حالة عقدة واحدة. اللون يعكس الدور:
/// أخضر = Leader، أزرق = Follower، برتقالي = Candidate، رمادي = Offline.
class NodeCard extends StatelessWidget {
  final ClusterNode node;

  const NodeCard({super.key, required this.node});

  Color get _roleColor {
    if (!node.online) return Colors.grey;
    switch (node.role) {
      case NodeRole.leader:
        return Colors.green;
      case NodeRole.candidate:
        return Colors.orange;
      case NodeRole.follower:
        return Colors.blue;
      case NodeRole.unknown:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _roleColor.withValues(alpha: 0.12),
        border: Border.all(color: _roleColor, width: 2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            node.isLeader ? Icons.workspace_premium : Icons.dns,
            color: _roleColor,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            node.id,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            node.role.name.toUpperCase(),
            style: TextStyle(color: _roleColor, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text('Term: ${node.term}'),
          Text('Port: ${node.port}', style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          // على بطاقة التابع (Follower): نُظهر من هو قائده الحالي.
          if (!node.isLeader && node.leaderId != null)
            Text(
              '→ ${node.leaderId}',
              style: const TextStyle(fontSize: 11, color: Colors.green),
            ),
        ],
      ),
    );
  }
}
