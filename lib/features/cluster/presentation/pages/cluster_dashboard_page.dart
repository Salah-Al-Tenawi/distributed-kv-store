import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../cubit/cluster_cubit.dart';
import '../widgets/node_card.dart';

/// شاشة لوحة التحكّم: تعرض كل عُقَد العنقود وحالتها لحظياً.
class ClusterDashboardPage extends StatelessWidget {
  const ClusterDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ClusterCubit>()..start(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Distributed KV Store — Cluster'),
          actions: [
            BlocBuilder<ClusterCubit, ClusterState>(
              builder: (context, state) {
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.circle,
                        size: 12,
                        color: state.connected ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 6),
                      Text(state.connected ? 'Connected' : 'Disconnected'),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        body: BlocBuilder<ClusterCubit, ClusterState>(
          builder: (context, state) {
            if (state.nodes.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('بانتظار العُقَد... شغّل الـ backend'),
                  ],
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: [
                  for (final node in state.sortedNodes) NodeCard(node: node),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
