import '../entities/cluster_node.dart';

/// عقد (Contract) مجرّد لمصدر بيانات العنقود.
///
/// طبقة الـ presentation (الـ Cubit) تعتمد على هذا التجريد فقط، ولا تعرف
/// أن التنفيذ الحقيقي يستخدم WebSocket. هذا يسمح بتبديل المصدر أو عمل
/// اختبارات بسهولة (Dependency Inversion).
abstract class ClusterRepository {
  /// تيّار (Stream) يبثّ حالة كل عقدة كلما تغيّرت.
  Stream<ClusterNode> watchNodes();

  /// بدء الاتصال بالعُقَد.
  Future<void> connect();

  /// قطع الاتصال وتحرير الموارد.
  Future<void> disconnect();

  /// "يقتل" عقدة (محاكاة تعطّل / Crash) عبر منفذها.
  Future<void> killNode(int port);

  /// "يُحيي" عقدة عبر منفذها.
  Future<void> reviveNode(int port);

  /// كتابة/تحديث مفتاح على القائد (عبر منفذه).
  Future<void> putKey(int leaderPort, String key, String value);

  /// حذف مفتاح على القائد.
  Future<void> deleteKey(int leaderPort, String key);

  /// يحجب أقراناً عن عقدة (محاكاة انقسام شبكة).
  Future<void> partitionNode(int port, List<String> blocked);

  /// يزيل الحجب عن عقدة (شفاء الشبكة).
  Future<void> healNode(int port);

  /// طلب قفل موزّع على القائد.
  Future<void> acquireLock(int leaderPort, String lockName, String clientId);

  /// تحرير قفل موزّع على القائد.
  Future<void> releaseLock(int leaderPort, String lockName, String clientId);

  /// يشغّل معاملة 2PC على القائد.
  Future<void> runTransaction(
    int leaderPort,
    List<Map<String, String>> operations,
  );

  /// يجعل عقدة تصوّت ABORT في 2PC (محاكاة رفض) أو يلغي ذلك.
  Future<void> setVoteAbort(int port, bool value);

  /// حدث محلّي على عقدة (يزيد ساعتها الشعاعية).
  Future<void> vcEvent(int port);

  /// رسالة سببية من عقدة إلى أخرى.
  Future<void> vcSend(int fromPort, String toId);
}
