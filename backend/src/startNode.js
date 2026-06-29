const { Node } = require('./node/Node');
const { Election } = require('./node/election');
const { startDashboardServer } = require('./transport/dashboard');
const { PeerClient, registerPeerRoutes } = require('./transport/peerRpc');
const { registerAdminRoutes } = require('./transport/admin');
const { registerClientRoutes } = require('./transport/clientApi');
const { registerLockRoutes } = require('./transport/lockApi');
const { registerTxnRoutes } = require('./transport/txnApi');
const { registerVcRoutes } = require('./transport/vcApi');

function startNode(nodeConfig) {

  const node = new Node(nodeConfig.id, nodeConfig.port);
  const { app, server } = startDashboardServer(node);

  const rpc = new PeerClient();
  const election = new Election(node, rpc);

  registerPeerRoutes(app, election);
  registerAdminRoutes(app, election);
  registerClientRoutes(app, node, election);
  registerLockRoutes(app, node, election);
  registerTxnRoutes(app, node, election);
  registerVcRoutes(app, node, election);

  setTimeout(() => election.start(), 500);

  return { node, election, app, server };
}

module.exports = { startNode };
