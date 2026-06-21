import 'package:equatable/equatable.dart';

import 'lock_info.dart';

/// حالات العقدة الممكنة (تطابق ما يرسله الـ backend في states.js).
enum NodeRole { follower, candidate, leader, unknown }

/// كيان (Entity) يمثّل عقدة واحدة في العنقود.
///
/// طبقة الـ domain لا تعرف من أين أتت البيانات (WebSocket/HTTP) — تعرف
/// فقط "ما هي العقدة". هذا جوهر الـ Clean Architecture.
class ClusterNode extends Equatable {
  final String id;
  final int port;
  final NodeRole role;
  final int term;
  final String? leaderId;
  final bool online;

  /// القُرَناء الذين يشكّ هذا القائد (Leader) بموتهم — فارغة لغير القائد.
  final List<String> suspectedOffline;

  /// المخزن المثبّت (Committed key-value store) لهذه العقدة.
  final Map<String, String> kv;

  /// مؤشّر آخر مدخلة مثبّتة في السجلّ (Committed log index).
  final int commitIndex;

  /// عدد المدخلات في السجلّ (Log length).
  final int logLength;

  /// الأقران المحجوبون عن هذه العقدة (عند انقسام الشبكة / Network Partition).
  final List<String> blockedPeers;

  /// الأقفال الموزّعة (Distributed Locks): اسم القفل → معلوماته.
  final Map<String, LockInfo> locks;

  const ClusterNode({
    required this.id,
    required this.port,
    required this.role,
    required this.term,
    required this.leaderId,
    required this.online,
    this.suspectedOffline = const [],
    this.kv = const {},
    this.commitIndex = -1,
    this.logLength = 0,
    this.blockedPeers = const [],
    this.locks = const {},
  });

  bool get isLeader => role == NodeRole.leader;

  /// هل هذه العقدة معزولة (ضمن انقسام شبكة)؟
  bool get isPartitioned => blockedPeers.isNotEmpty;

  @override
  List<Object?> get props => [
        id,
        port,
        role,
        term,
        leaderId,
        online,
        suspectedOffline,
        kv,
        commitIndex,
        logLength,
        blockedPeers,
        locks,
      ];
}
