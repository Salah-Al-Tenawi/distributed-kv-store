import 'package:equatable/equatable.dart';

/// معلومات قفل موزّع (Distributed Lock):
/// - [owner]: مالك القفل حالياً (null = حرّ / free).
/// - [token]: رمز الحماية (Fencing Token) المتزايد.
/// - [expiresAt]: لحظة انتهاء المهلة (TTL) بالميلي ثانية (epoch).
class LockInfo extends Equatable {
  final String? owner;
  final int token;
  final int expiresAt;

  const LockInfo({
    required this.owner,
    required this.token,
    required this.expiresAt,
  });

  /// هل القفل مشغول الآن؟ (له مالك ولم تنتهِ مهلته).
  bool get isHeld =>
      owner != null && expiresAt > DateTime.now().millisecondsSinceEpoch;

  /// الثواني المتبقية قبل انتهاء المهلة (TTL).
  int get secondsLeft {
    final ms = expiresAt - DateTime.now().millisecondsSinceEpoch;
    return ms > 0 ? (ms / 1000).ceil() : 0;
  }

  factory LockInfo.fromJson(Map<String, dynamic> json) {
    return LockInfo(
      owner: json['owner'] as String?,
      token: json['token'] as int? ?? 0,
      expiresAt: json['expiresAt'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [owner, token, expiresAt];
}
