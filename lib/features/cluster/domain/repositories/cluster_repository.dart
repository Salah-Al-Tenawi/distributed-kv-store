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
}
