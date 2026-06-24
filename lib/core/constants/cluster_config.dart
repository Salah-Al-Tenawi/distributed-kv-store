/// إعدادات العنقود من جهة Flutter — يجب أن تطابق backend/src/config.js
///
/// وضعان للتشغيل:
///  - **محلّي (Local dev):** كل عقدة على منفذها مباشرةً (localhost:4001..4005).
///  - **بوّابة (Gateway):** خدمة واحدة عامة تخدم الواجهة وتوجّه عبر مسارات
///    `/ws/:port` و `/proxy/:port` على نفس الأصل (origin). نُفعّله للنشر بـ:
///       flutter build web --dart-define=GATEWAY=true
class ClusterConfig {
  /// عند true نستخدم البوّابة (نفس أصل الصفحة)؛ نُمرّره وقت بناء النشر.
  static const bool gateway = bool.fromEnvironment('GATEWAY', defaultValue: false);

  /// عنوان التطوير المحلّي (يُستخدم خارج وضع البوّابة).
  static const String _devHost = 'localhost';

  static const List<int> nodePorts = [4001, 4002, 4003, 4004, 4005];

  /// أصل الصفحة الحالي (للويب في وضع البوّابة): host[:port].
  static String get _origin {
    final b = Uri.base;
    return b.hasPort ? '${b.host}:${b.port}' : b.host;
  }

  /// مخطّط WebSocket حسب أمان الصفحة (wss على https).
  static String get _wsScheme => Uri.base.scheme == 'https' ? 'wss' : 'ws';

  static String wsUrl(int port) => gateway
      ? '$_wsScheme://$_origin/ws/$port'
      : 'ws://$_devHost:$port';

  static String httpUrl(int port) => gateway
      ? '${Uri.base.scheme}://$_origin/proxy/$port'
      : 'http://$_devHost:$port';
}
