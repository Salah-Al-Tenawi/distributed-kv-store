import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/cluster_cubit.dart';

class TxnPanel extends StatelessWidget {
  const TxnPanel({super.key});

  static const List<Map<String, String>> _demoTxn = [
    {'key': 'A', 'value': '100'},
    {'key': 'B', 'value': '200'},
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClusterCubit, ClusterState>(
      builder: (context, state) {
        final cubit = context.read<ClusterCubit>();
        final txn = state.leader?.lastTxn;
        final hasLeader = state.leader != null;

        return Card(
          margin: const EdgeInsets.fromLTRB(24, 8, 24, 0),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.account_tree, size: 20),
                    const SizedBox(width: 8),
                    const Text('Two-Phase Commit (2PC)',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'معاملة ذرّية: set A=100, B=200 (الكل أو لا أحد)',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: hasLeader
                          ? () => cubit.runTransaction(_demoTxn)
                          : null,
                      icon: const Icon(Icons.play_arrow, size: 18),
                      label: const Text('Run 2PC'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                if (txn != null) ...[
                  Row(
                    children: [
                      Chip(
                        backgroundColor: txn.committed
                            ? Colors.green.withValues(alpha: 0.2)
                            : Colors.red.withValues(alpha: 0.2),
                        label: Text(
                          txn.result,
                          style: TextStyle(
                            color: txn.committed ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Wrap(
                          spacing: 6,
                          children: [
                            for (final entry in txn.votes.entries)
                              Text(
                                '${entry.key}:${entry.value}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontFamily: 'monospace',
                                  color: entry.value == 'YES'
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],

                const Text('محاكاة رفض عقدة (vote ABORT):',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final node in state.sortedNodes)
                      FilterChip(
                        label: Text(node.id),
                        selected: node.voteAbort,
                        selectedColor: Colors.red.withValues(alpha: 0.2),
                        onSelected: (v) => cubit.toggleVoteAbort(node.port, v),
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
