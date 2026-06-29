class ClusterConfig {

  static const bool gateway = bool.fromEnvironment('GATEWAY', defaultValue: false);

  static const String _devHost = 'localhost';

  static const List<int> nodePorts = [4001, 4002, 4003, 4004, 4005];

  static String get _origin {
    final b = Uri.base;
    return b.hasPort ? '${b.host}:${b.port}' : b.host;
  }

  static String get _wsScheme => Uri.base.scheme == 'https' ? 'wss' : 'ws';

  static String wsUrl(int port) => gateway
      ? '$_wsScheme://$_origin/ws/$port'
      : 'ws://$_devHost:$port';

  static String httpUrl(int port) => gateway
      ? '${Uri.base.scheme}://$_origin/proxy/$port'
      : 'http://$_devHost:$port';
}
