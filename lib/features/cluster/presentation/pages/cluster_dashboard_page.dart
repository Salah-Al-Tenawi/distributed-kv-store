import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../cubit/cluster_cubit.dart';
import '../widgets/kv_control_bar.dart';
import '../widgets/lock_panel.dart';
import '../widgets/node_card.dart';
import '../widgets/sharding_panel.dart';
import '../widgets/txn_panel.dart';
import '../widgets/vector_clock_panel.dart';

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
            // زر تقسيم/شفاء الشبكة (Network Partition / Heal).
            BlocBuilder<ClusterCubit, ClusterState>(
              builder: (context, state) {
                final cubit = context.read<ClusterCubit>();
                return TextButton.icon(
                  onPressed: state.isPartitioned
                      ? cubit.healNetwork
                      : cubit.partitionNetwork,
                  icon: Icon(
                    state.isPartitioned ? Icons.link : Icons.flash_on,
                    color: state.isPartitioned ? Colors.green : Colors.amber,
                  ),
                  label: Text(
                    state.isPartitioned ? 'Heal Network' : 'Partition Network',
                    style: TextStyle(
                      color: state.isPartitioned ? Colors.green : Colors.amber,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
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
            final cubit = context.read<ClusterCubit>();
            return SingleChildScrollView(
              child: Column(
                children: [
                  if (state.isPartitioned)
                    Container(
                      width: double.infinity,
                      color: Colors.amber.withValues(alpha: 0.25),
                      padding: const EdgeInsets.all(10),
                      child: const Text(
                        '⚡ Network Partitioned — الأقلية متجمّدة، والأغلبية فقط تثبّت الكتابة (Split-Brain protection)',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  const SizedBox(height: 8),
                  // بطاقات العُقَد.
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      alignment: WrapAlignment.center,
                      children: [
                        for (final node in state.sortedNodes)
                          NodeCard(
                            node: node,
                            isOffline: state.isOffline(node),
                            onKill: () => cubit.kill(node.port),
                            onRevive: () => cubit.revive(node.port),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // لوحات التحكّم بالمفاهيم.
                  const KvControlBar(),
                  const SizedBox(height: 8),
                  const LockPanel(),
                  const SizedBox(height: 8),
                  const TxnPanel(),
                  const SizedBox(height: 8),
                  const VectorClockPanel(),
                  const SizedBox(height: 8),
                  const ShardingPanel(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
