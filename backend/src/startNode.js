// =============================================================
// startNode.js — تشغيل عقدة واحدة (قابلة لإعادة الاستخدام)
// =============================================================
// تُستخدم من:
//   - index.js     : لتشغيل عقدة واحدة في عملية مستقلّة (CLI / start-cluster).
//   - gateway.js   : لتشغيل كل العُقَد داخل عملية واحدة (in-process) للنشر.

const { Node } = require('./node/Node');
const { Election } = require('./node/election');
const { startDashboardServer } = require('./transport/dashboard');
const { PeerClient, registerPeerRoutes } = require('./transport/peerRpc');
const { registerAdminRoutes } = require('./transport/admin');
const { registerClientRoutes } = require('./transport/clientApi');
const { registerLockRoutes } = require('./transport/lockApi');
const { registerTxnRoutes } = require('./transport/txnApi');
const { registerVcRoutes } = require('./transport/vcApi');

/**
 * يُنشئ عقدة، يشغّل سيرفرها (HTTP + WebSocket)، ويبدأ منطق الانتخاب.
 * @param {{id: string, port: number}} nodeConfig
 */
function startNode(nodeConfig) {
  // 1) العقدة + سيرفر اللوحة (HTTP /health + WebSocket لبثّ الحالة).
  const node = new Node(nodeConfig.id, nodeConfig.port);
  const { app, server } = startDashboardServer(node);

  // 2) التواصل بين العُقَد (Peer RPC) + منطق الانتخاب (Election).
  const rpc = new PeerClient();
  const election = new Election(node, rpc);

  // 3) تسجيل كل المسارات (RPC + الأوامر).
  registerPeerRoutes(app, election);
  registerAdminRoutes(app, election);
  registerClientRoutes(app, node, election);
  registerLockRoutes(app, node, election);
  registerTxnRoutes(app, node, election);
  registerVcRoutes(app, node, election);

  // 4) بدء الانتخاب بعد مهلة قصيرة (لتقلع كل العُقَد أولاً).
  setTimeout(() => election.start(), 500);

  return { node, election, app, server };
}

module.exports = { startNode };
