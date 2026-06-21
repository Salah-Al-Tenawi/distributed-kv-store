import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/lock_info.dart';
import '../cubit/cluster_cubit.dart';

/// لوحة المورد المشترك (Shared Resource) لعرض قفل موزّع واحد
/// والتحكّم به من عميلين (Client-A / Client-B) لإظهار الإقصاء المتبادل.
class LockPanel extends StatefulWidget {
  const LockPanel({super.key});

  static const String lockName = 'seat-12A';

  @override
  State<LockPanel> createState() => _LockPanelState();
}

class _LockPanelState extends State<LockPanel> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // مؤقّت لتحديث العدّاد التنازلي (TTL) كل ثانية.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClusterCubit, ClusterState>(
      builder: (context, state) {
        final cubit = context.read<ClusterCubit>();
        final LockInfo? lock = state.leader?.locks[LockPanel.lockName];
        final held = lock?.isHeld ?? false;
        final owner = held ? lock!.owner : null;

        return Card(
          margin: const EdgeInsets.fromLTRB(24, 0, 24, 0),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(held ? Icons.lock : Icons.lock_open,
                    color: held ? Colors.red : Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Resource "${LockPanel.lockName}"',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 16),
                // حالة القفل: المالك + رمز الحماية + المهلة المتبقية.
                Expanded(
                  child: held
                      ? Text(
                          'مقفول لـ $owner  ·  Fencing Token: ${lock!.token}  ·  TTL: ${lock.secondsLeft}s',
                          style: const TextStyle(color: Colors.red),
                        )
                      : Text(
                          'FREE${lock != null ? '  (آخر token: ${lock.token})' : ''}',
                          style: const TextStyle(color: Colors.green),
                        ),
                ),
                // أزرار العميلين.
                _clientButton(context, cubit, 'Client-A', owner, held),
                const SizedBox(width: 8),
                _clientButton(context, cubit, 'Client-B', owner, held),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _clientButton(
    BuildContext context,
    ClusterCubit cubit,
    String clientId,
    String? owner,
    bool held,
  ) {
    final isOwner = owner == clientId;
    if (isOwner) {
      return OutlinedButton.icon(
        onPressed: () => cubit.release(LockPanel.lockName, clientId),
        icon: const Icon(Icons.lock_open, size: 16),
        label: Text('Release ($clientId)'),
        style: OutlinedButton.styleFrom(foregroundColor: Colors.orange),
      );
    }
    return FilledButton.tonalIcon(
      // معطّل إن كان القفل مشغولاً من الآخر.
      onPressed: held ? null : () => cubit.acquire(LockPanel.lockName, clientId),
      icon: const Icon(Icons.lock, size: 16),
      label: Text('Acquire ($clientId)'),
    );
  }
}
