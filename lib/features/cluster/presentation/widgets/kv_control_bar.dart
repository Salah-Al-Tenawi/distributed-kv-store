import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/cluster_cubit.dart';

/// شريط كتابة المفاتيح (PUT) — يُرسل الأمر إلى القائد الحالي فقط.
class KvControlBar extends StatefulWidget {
  const KvControlBar({super.key});

  @override
  State<KvControlBar> createState() => _KvControlBarState();
}

class _KvControlBarState extends State<KvControlBar> {
  final _keyController = TextEditingController();
  final _valueController = TextEditingController();

  @override
  void dispose() {
    _keyController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context, bool hasLeader) {
    final key = _keyController.text.trim();
    final value = _valueController.text.trim();
    if (key.isEmpty || !hasLeader) return;
    context.read<ClusterCubit>().put(key, value);
    _keyController.clear();
    _valueController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClusterCubit, ClusterState>(
      builder: (context, state) {
        final leader = state.leader;
        final hasLeader = leader != null;
        return Card(
          margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.edit_note),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _keyController,
                    decoration: const InputDecoration(
                      labelText: 'Key',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _submit(context, hasLeader),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _valueController,
                    decoration: const InputDecoration(
                      labelText: 'Value',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _submit(context, hasLeader),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: hasLeader ? () => _submit(context, hasLeader) : null,
                  icon: const Icon(Icons.send, size: 18),
                  label: const Text('PUT'),
                ),
                const SizedBox(width: 12),
                // مؤشّر القائد الذي ستُرسَل إليه الكتابة.
                Text(
                  hasLeader ? 'Leader: ${leader.id}' : 'No leader (write blocked)',
                  style: TextStyle(
                    color: hasLeader ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
