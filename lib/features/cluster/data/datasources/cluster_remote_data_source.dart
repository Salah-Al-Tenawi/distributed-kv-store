import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../../core/constants/cluster_config.dart';
import '../models/cluster_node_model.dart';

class ClusterRemoteDataSource {
  final List<WebSocketChannel> _channels = [];
  final List<StreamSubscription> _subscriptions = [];

  final StreamController<ClusterNodeModel> _controller =
      StreamController<ClusterNodeModel>.broadcast();

  Stream<ClusterNodeModel> get stream => _controller.stream;

  void connect() {
    for (final port in ClusterConfig.nodePorts) {
      _connectToNode(port);
    }
  }

  void _connectToNode(int port) {
    try {
      final channel = WebSocketChannel.connect(
        Uri.parse(ClusterConfig.wsUrl(port)),
      );
      _channels.add(channel);

      final sub = channel.stream.listen(
        (event) => _onMessage(event, port),
        onError: (_) {

        },
        cancelOnError: false,
      );
      _subscriptions.add(sub);
    } catch (_) {

    }
  }

  void _onMessage(dynamic event, int port) {
    try {
      final decoded = jsonDecode(event as String) as Map<String, dynamic>;
      if (decoded['type'] == 'state' && decoded['data'] != null) {
        final model = ClusterNodeModel.fromJson(
          decoded['data'] as Map<String, dynamic>,
        );
        _controller.add(model);
      }
    } catch (_) {

    }
  }

  Future<void> _post(int port, String path, [Map<String, dynamic>? body]) async {
    try {
      await http.post(
        Uri.parse('${ClusterConfig.httpUrl(port)}$path'),
        headers: body == null ? null : {'Content-Type': 'application/json'},
        body: body == null ? null : jsonEncode(body),
      );
    } catch (_) {

    }
  }

  Future<void> putKey(int port, String key, String value) =>
      _post(port, '/kv/put', {'key': key, 'value': value});

  Future<void> deleteKey(int port, String key) =>
      _post(port, '/kv/del', {'key': key});

  Future<void> killNode(int port) => _post(port, '/admin/kill');

  Future<void> reviveNode(int port) => _post(port, '/admin/revive');

  Future<void> acquireLock(int port, String lockName, String clientId) =>
      _post(port, '/lock/acquire', {'lockName': lockName, 'clientId': clientId});

  Future<void> releaseLock(int port, String lockName, String clientId) =>
      _post(port, '/lock/release', {'lockName': lockName, 'clientId': clientId});

  Future<void> partitionNode(int port, List<String> blocked) =>
      _post(port, '/admin/partition', {'blocked': blocked});

  Future<void> healNode(int port) => _post(port, '/admin/heal');

  Future<void> runTransaction(
    int leaderPort,
    List<Map<String, String>> operations,
  ) =>
      _post(leaderPort, '/txn', {'operations': operations});

  Future<void> setVoteAbort(int port, bool value) =>
      _post(port, '/admin/vote-abort', {'value': value});

  Future<void> vcEvent(int port) => _post(port, '/vc/event');

  Future<void> vcSend(int fromPort, String toId) =>
      _post(fromPort, '/vc/send', {'to': toId});

  Future<void> dispose() async {
    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    for (final channel in _channels) {
      await channel.sink.close();
    }
    _subscriptions.clear();
    _channels.clear();
    await _controller.close();
  }
}
