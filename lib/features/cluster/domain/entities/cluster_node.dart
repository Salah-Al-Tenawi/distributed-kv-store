import 'package:equatable/equatable.dart';

import 'lock_info.dart';
import 'txn_info.dart';

enum NodeRole { follower, candidate, leader, unknown }

class ClusterNode extends Equatable {
  final String id;
  final int port;
  final NodeRole role;
  final int term;
  final String? leaderId;
  final bool online;

  final List<String> suspectedOffline;

  final Map<String, String> kv;

  final int commitIndex;

  final int logLength;

  final List<String> blockedPeers;

  final Map<String, LockInfo> locks;

  final bool voteAbort;

  final TxnInfo? lastTxn;

  final Map<String, int> vectorClock;

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
    this.voteAbort = false,
    this.lastTxn,
    this.vectorClock = const {},
  });

  bool get isLeader => role == NodeRole.leader;

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
        voteAbort,
        lastTxn,
        vectorClock,
      ];
}
