const { CLUSTER } = require('./config');
const { startNode } = require('./startNode');

const nodeId = process.argv[2] || 'node-1';
const nodeConfig = CLUSTER.find((n) => n.id === nodeId);
if (!nodeConfig) {
  console.error(`Error: no node with id "${nodeId}" in config.js`);
  console.error(`Available nodes: ${CLUSTER.map((n) => n.id).join(', ')}`);
  process.exit(1);
}

startNode(nodeConfig);
