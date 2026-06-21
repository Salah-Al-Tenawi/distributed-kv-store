import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../../core/constants/cluster_config.dart';
import '../models/cluster_node_model.dart';

/// مصدر البيانات البعيد: يفتح اتصال WebSocket مع كل عقدة في العنقود،
/// ويحوّل الرسائل القادمة (JSON) إلى نماذج ClusterNodeModel.
///
/// كل عقدة تبثّ حالتها على منفذها الخاص، فنفتح 5 اتصالات وندمجها في
/// تيّار واحد (single Stream) تستهلكه بقية الطبقات.
class ClusterRemoteDataSource {
  final List<WebSocketChannel> _channels = [];
  final List<StreamSubscription> _subscriptions = [];

  // ناقل (broadcast) يجمع تحديثات كل العُقَد في تيّار واحد.
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
          // عقدة غير متاحة (لم تُشغَّل بعد) — نتجاهل بهدوء.
        },
        cancelOnError: false,
      );
      _subscriptions.add(sub);
    } catch (_) {
      // فشل فتح الاتصال — نتجاهل، سنعيد المحاولة لاحقاً (مرحلة قادمة).
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
      // رسالة غير متوقّعة — نتجاهلها.
    }
  }

  /// كتابة مفتاح على القائد (POST /kv/put). port = منفذ القائد.
  Future<void> putKey(int port, String key, String value) async {
    await http.post(
      Uri.parse('${ClusterConfig.httpUrl(port)}/kv/put'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'key': key, 'value': value}),
    );
  }

  /// حذف مفتاح على القائد (POST /kv/del).
  Future<void> deleteKey(int port, String key) async {
    await http.post(
      Uri.parse('${ClusterConfig.httpUrl(port)}/kv/del'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'key': key}),
    );
  }

  /// "يقتل" عقدة عبر منفذها (POST /admin/kill).
  Future<void> killNode(int port) async {
    await http.post(Uri.parse('${ClusterConfig.httpUrl(port)}/admin/kill'));
  }

  /// "يُحيي" عقدة عبر منفذها (POST /admin/revive).
  Future<void> reviveNode(int port) async {
    await http.post(Uri.parse('${ClusterConfig.httpUrl(port)}/admin/revive'));
  }

  /// طلب قفل موزّع على القائد (POST /lock/acquire).
  Future<void> acquireLock(int port, String lockName, String clientId) async {
    await http.post(
      Uri.parse('${ClusterConfig.httpUrl(port)}/lock/acquire'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'lockName': lockName, 'clientId': clientId}),
    );
  }

  /// تحرير قفل موزّع على القائد (POST /lock/release).
  Future<void> releaseLock(int port, String lockName, String clientId) async {
    await http.post(
      Uri.parse('${ClusterConfig.httpUrl(port)}/lock/release'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'lockName': lockName, 'clientId': clientId}),
    );
  }

  /// يحجب أقراناً عن عقدة (محاكاة انقسام شبكة / POST /admin/partition).
  Future<void> partitionNode(int port, List<String> blocked) async {
    await http.post(
      Uri.parse('${ClusterConfig.httpUrl(port)}/admin/partition'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'blocked': blocked}),
    );
  }

  /// يزيل الحجب عن عقدة (شفاء الشبكة / POST /admin/heal).
  Future<void> healNode(int port) async {
    await http.post(Uri.parse('${ClusterConfig.httpUrl(port)}/admin/heal'));
  }

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
