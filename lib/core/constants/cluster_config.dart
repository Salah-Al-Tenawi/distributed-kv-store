/// إعدادات العنقود من جهة Flutter — يجب أن تطابق backend/src/config.js
///
/// كل عقدة تعمل على منفذ، ونتصل بها عبر WebSocket على نفس المنفذ.
/// ملاحظة: على المحاكي (Android emulator) العنوان 10.0.2.2 يشير للجهاز
/// المضيف؛ على الويب/سطح المكتب نستخدم localhost.
class ClusterConfig {
  static const String host = 'localhost';

  static const List<int> nodePorts = [4001, 4002, 4003, 4004, 4005];

  static String wsUrl(int port) => 'ws://$host:$port';

  static String httpUrl(int port) => 'http://$host:$port';
}
