import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/cluster_node.dart';
import '../cubit/cluster_cubit.dart';

class VectorClockPanel extends StatefulWidget {
  const VectorClockPanel({super.key});

  @override
  State<VectorClockPanel> createState() => _VectorClockPanelState();
}

class _VectorClockPanelState extends State<VectorClockPanel> {
  String? _from;
  String? _to;

  String _format(ClusterNode node, List<String> ids) {
    final values = ids.map((id) => node.vectorClock[id] ?? 0).join(', ');
    return '[$values]';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClusterCubit, ClusterState>(
      builder: (context, state) {
        final cubit = context.read<ClusterCubit>();
        final nodes = state.sortedNodes;
        final ids = nodes.map((n) => n.id).toList();
        _from ??= ids.isNotEmpty ? ids.first : null;
        _to ??= ids.length > 1 ? ids[1] : null;

        return Card(
          margin: const EdgeInsets.fromLTRB(24, 8, 24, 0),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 20),
                    const SizedBox(width: 8),
                    const Text('Vector Clocks',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Order: [${ids.join(', ')}]  -  a local event bumps the node counter; a message merges clocks',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    for (final node in nodes)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.indigo.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('${node.id}: ',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            Text(_format(node, ids),
                                style: const TextStyle(
                                    fontFamily: 'monospace')),
                            const SizedBox(width: 6),
                            IconButton(
                              tooltip: 'Local event',
                              visualDensity: VisualDensity.compact,
                              onPressed: () => cubit.vcEvent(node.port),
                              icon: const Icon(Icons.add_circle_outline,
                                  size: 18),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    const Text('Send message: '),
                    DropdownButton<String>(
                      value: _from,
                      items: [
                        for (final id in ids)
                          DropdownMenuItem(value: id, child: Text(id)),
                      ],
                      onChanged: (v) => setState(() => _from = v),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.arrow_forward, size: 18),
                    ),
                    DropdownButton<String>(
                      value: _to,
                      items: [
                        for (final id in ids)
                          DropdownMenuItem(value: id, child: Text(id)),
                      ],
                      onChanged: (v) => setState(() => _to = v),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.tonalIcon(
                      onPressed: (_from != null && _to != null && _from != _to)
                          ? () {
                              final fromNode =
                                  nodes.firstWhere((n) => n.id == _from);
                              cubit.vcSend(fromNode.port, _to!);
                            }
                          : null,
                      icon: const Icon(Icons.send, size: 16),
                      label: const Text('Send'),
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
