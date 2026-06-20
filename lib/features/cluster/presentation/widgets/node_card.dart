import 'package:flutter/material.dart';

import '../../domain/entities/cluster_node.dart';

/// بطاقة تعرض حالة عقدة واحدة. اللون يعكس الدور:
/// أخضر = Leader، أزرق = Follower، برتقالي = Candidate، رمادي = Offline.
class NodeCard extends StatelessWidget {
  final ClusterNode node;
  final bool isOffline;
  final VoidCallback onKill;
  final VoidCallback onRevive;

  const NodeCard({
    super.key,
    required this.node,
    required this.isOffline,
    required this.onKill,
    required this.onRevive,
  });

  Color get _roleColor {
    if (isOffline) return Colors.grey;
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
      width: 170,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _roleColor.withValues(alpha: 0.12),
        border: Border.all(color: _roleColor, width: 2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // مؤشّر النبض (Heartbeat): قلب نابض أخضر للحيّة، رمادي للميتة.
          _Heartbeat(active: !isOffline, color: _roleColor),
          const SizedBox(height: 8),
          Icon(
            node.isLeader && !isOffline ? Icons.workspace_premium : Icons.dns,
            color: _roleColor,
            size: 30,
          ),
          const SizedBox(height: 6),
          Text(
            node.id,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            isOffline ? 'OFFLINE' : node.role.name.toUpperCase(),
            style: TextStyle(color: _roleColor, fontWeight: FontWeight.w600),
          ),
          if (node.isPartitioned)
            const Text(
              '⚡ isolated',
              style: TextStyle(fontSize: 10, color: Colors.amber),
            ),
          const SizedBox(height: 8),
          Text('Term: ${node.term}  ·  commit: ${node.commitIndex}'),
          if (!isOffline && !node.isLeader && node.leaderId != null)
            Text(
              '→ ${node.leaderId}',
              style: const TextStyle(fontSize: 11, color: Colors.green),
            ),
          const SizedBox(height: 8),
          // المخزن المثبّت (Committed KV store) لهذه العقدة.
          _KvBox(kv: node.kv),
          const SizedBox(height: 10),
          // زر القتل/الإحياء (Kill / Revive).
          SizedBox(
            width: double.infinity,
            child: isOffline
                ? OutlinedButton.icon(
                    onPressed: onRevive,
                    icon: const Icon(Icons.favorite, size: 16),
                    label: const Text('Revive'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                    ),
                  )
                : OutlinedButton.icon(
                    onPressed: onKill,
                    icon: const Icon(Icons.power_settings_new, size: 16),
                    label: const Text('Kill'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// صندوق يعرض محتوى المخزن (Committed key-value store) للعقدة.
class _KvBox extends StatelessWidget {
  final Map<String, String> kv;

  const _KvBox({required this.kv});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 36, maxHeight: 96),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
      ),
      child: kv.isEmpty
          ? const Center(
              child: Text(
                'empty store',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final entry in kv.entries)
                    Text(
                      '${entry.key} = ${entry.value}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

/// قلب نابض بسيط (Heartbeat indicator): يكبر ويصغر عندما تكون العقدة حيّة.
class _Heartbeat extends StatefulWidget {
  final bool active;
  final Color color;

  const _Heartbeat({required this.active, required this.color});

  @override
  State<_Heartbeat> createState() => _HeartbeatState();
}

class _HeartbeatState extends State<_Heartbeat>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) {
      return Icon(Icons.heart_broken, color: Colors.grey, size: 18);
    }
    return ScaleTransition(
      scale: Tween(begin: 0.8, end: 1.2).animate(_controller),
      child: Icon(Icons.favorite, color: widget.color, size: 18),
    );
  }
}
