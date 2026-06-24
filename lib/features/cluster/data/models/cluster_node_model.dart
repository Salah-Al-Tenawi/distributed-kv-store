import '../../domain/entities/cluster_node.dart';
import '../../domain/entities/lock_info.dart';
import '../../domain/entities/txn_info.dart';

/// نموذج البيانات (Model): يرث من الكيان ويضيف التحويل من/إلى JSON.
///
/// JSON يأتي من الـ backend (dashboard.js -> getSnapshot) بهذا الشكل:
/// { "id": "node-1", "port": 4001, "state": "FOLLOWER",
///   "term": 0, "leaderId": null, "online": true }
class ClusterNodeModel extends ClusterNode {
  const ClusterNodeModel({
    required super.id,
    required super.port,
    required super.role,
    required super.term,
    required super.leaderId,
    required super.online,
    super.suspectedOffline,
    super.kv,
    super.commitIndex,
    super.logLength,
    super.blockedPeers,
    super.locks,
    super.voteAbort,
    super.lastTxn,
    super.vectorClock,
  });

  factory ClusterNodeModel.fromJson(Map<String, dynamic> json) {
    return ClusterNodeModel(
      id: json['id'] as String,
      port: json['port'] as int,
      role: _roleFromString(json['state'] as String?),
      term: json['term'] as int? ?? 0,
      leaderId: json['leaderId'] as String?,
      online: json['online'] as bool? ?? true,
      suspectedOffline:
          (json['suspectedOffline'] as List<dynamic>?)?.cast<String>() ??
              const [],
      kv: (json['kv'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, value.toString()),
          ) ??
          const {},
      commitIndex: json['commitIndex'] as int? ?? -1,
      logLength: json['logLength'] as int? ?? 0,
      blockedPeers:
          (json['blockedPeers'] as List<dynamic>?)?.cast<String>() ?? const [],
      locks: (json['locks'] as Map<String, dynamic>?)?.map(
            (name, info) =>
                MapEntry(name, LockInfo.fromJson(info as Map<String, dynamic>)),
          ) ??
          const {},
      voteAbort: json['voteAbort'] as bool? ?? false,
      lastTxn: json['lastTxn'] == null
          ? null
          : TxnInfo.fromJson(json['lastTxn'] as Map<String, dynamic>),
      vectorClock: (json['vectorClock'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as num).toInt()),
          ) ??
          const {},
    );
  }

  static NodeRole _roleFromString(String? value) {
    switch (value) {
      case 'FOLLOWER':
        return NodeRole.follower;
      case 'CANDIDATE':
        return NodeRole.candidate;
      case 'LEADER':
        return NodeRole.leader;
      default:
        return NodeRole.unknown;
    }
  }
}
