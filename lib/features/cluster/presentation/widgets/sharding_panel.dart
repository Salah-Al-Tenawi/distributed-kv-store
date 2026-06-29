import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/util/consistent_hash_ring.dart';
import '../cubit/cluster_cubit.dart';

class ShardingPanel extends StatefulWidget {
  const ShardingPanel({super.key});

  static const List<String> sampleKeys = [
    'user-1', 'user-2', 'user-3', 'user-4', 'cart-9', 'cart-7',
    'order-42', 'order-88', 'photo-x', 'photo-y', 'session-a', 'session-b',
  ];

  @override
  State<ShardingPanel> createState() => _ShardingPanelState();
}

class _ShardingPanelState extends State<ShardingPanel> {
  final _keyController = TextEditingController();
  String? _testResult;

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClusterCubit, ClusterState>(
      builder: (context, state) {

        final liveIds = state.sortedNodes
            .where((n) => !state.isOffline(n))
            .map((n) => n.id)
            .toList();
        final ring = ConsistentHashRing(liveIds);

        final byNode = <String, List<String>>{for (final id in liveIds) id: []};
        for (final key in ShardingPanel.sampleKeys) {
          final owner = ring.owner(key);
          if (owner != null) byNode[owner]!.add(key);
        }

        return Card(
          margin: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.donut_large, size: 20),
                    const SizedBox(width: 8),
                    const Text('Consistent Hashing / Sharding',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Keys are distributed over live nodes - kill a node and only its keys move',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    for (final id in liveIds)
                      Container(
                        width: 200,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.teal.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: Colors.teal.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$id  (${byNode[id]!.length} keys)',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text(
                              byNode[id]!.isEmpty ? '—' : byNode[id]!.join(', '),
                              style: const TextStyle(
                                  fontSize: 11, fontFamily: 'monospace'),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    SizedBox(
                      width: 240,
                      child: TextField(
                        controller: _keyController,
                        decoration: const InputDecoration(
                          labelText: 'Type a key to see its node',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (v) => setState(
                            () => _testResult = ring.owner(v.trim())),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (_testResult != null && _keyController.text.isNotEmpty)
                      Text(
                        '→ $_testResult',
                        style: const TextStyle(
                          color: Colors.teal,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
