// =============================================================
// index.js — نقطة الدخول: تشغيل عقدة واحدة
// =============================================================
// نشغّل العقدة هكذا:  node src/index.js node-1
// إن لم نمرّر معرّفاً، تعمل node-1 افتراضياً.
//
// كل عقدة تُشغَّل في عملية (process) منفصلة — كأنها جهاز مستقل.
// scripts/start-cluster.js يشغّل الخمسة دفعة واحدة.

const { CLUSTER } = require('./config');
const { Node } = require('./node/Node');
const { Election } = require('./node/election');
const { startDashboardServer } = require('./transport/dashboard');
const { PeerClient, registerPeerRoutes } = require('./transport/peerRpc');
const { registerAdminRoutes } = require('./transport/admin');

// نقرأ معرّف العقدة من سطر الأوامر (args)، أو نستخدم node-1 افتراضياً.
const nodeId = process.argv[2] || 'node-1';

const nodeConfig = CLUSTER.find((n) => n.id === nodeId);
if (!nodeConfig) {
  console.error(`خطأ: لا توجد عقدة بالمعرّف "${nodeId}" في config.js`);
  console.error(`العُقَد المتاحة: ${CLUSTER.map((n) => n.id).join(', ')}`);
  process.exit(1);
}

// 1) ننشئ العقدة (Node) ونشغّل سيرفر اللوحة (HTTP /health + WebSocket).
const node = new Node(nodeConfig.id, nodeConfig.port);
const { app } = startDashboardServer(node);

// 2) نجهّز التواصل بين العُقَد (Peer RPC) ومنطق الانتخاب (Election).
const rpc = new PeerClient();
const election = new Election(node, rpc);

// 3) نسجّل مسارات استقبال الرسائل (RequestVote / AppendEntries) + أوامر التحكّم.
registerPeerRoutes(app, election);
registerAdminRoutes(app, election);

// 4) نبدأ الانتخاب: العقدة تبدأ تابعاً، وإن لم تسمع قائداً تترشّح.
//    مهلة بسيطة لإعطاء كل العُقَد فرصة للإقلاع قبل بدء الانتخابات.
setTimeout(() => election.start(), 500);
