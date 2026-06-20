import 'package:flutter/material.dart';

import 'core/di/injection.dart';
import 'features/cluster/presentation/pages/cluster_dashboard_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDependencies();
  runApp(const DistributedKVApp());
}

class DistributedKVApp extends StatelessWidget {
  const DistributedKVApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Distributed KV Store',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const ClusterDashboardPage(),
    );
  }
}
