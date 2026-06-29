const CLUSTER = [
  { id: 'node-1', port: 4001 },
  { id: 'node-2', port: 4002 },
  { id: 'node-3', port: 4003 },
  { id: 'node-4', port: 4004 },
  { id: 'node-5', port: 4005 },
];

const TIMING = {
  heartbeatInterval: 100,
  electionTimeoutMin: 400,
  electionTimeoutMax: 800,
  failureTimeout: 350,
  lockTtl: 8000,
};

function getPeers(selfId) {
  return CLUSTER.filter((node) => node.id !== selfId);
}

module.exports = { CLUSTER, TIMING, getPeers };
