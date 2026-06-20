import 'package:equatable/equatable.dart';

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

  const ClusterNode({
    required this.id,
    required this.port,
    required this.role,
    required this.term,
    required this.leaderId,
    required this.online,
    this.suspectedOffline = const [],
  });

  bool get isLeader => role == NodeRole.leader;

  @override
  List<Object?> get props =>
      [id, port, role, term, leaderId, online, suspectedOffline];
}
