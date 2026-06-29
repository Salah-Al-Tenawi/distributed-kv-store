const { applyCommitted } = require('../store/kvStore');

function leaderAppend(node, command) {
  node.log.push({ term: node.term, ...command });

  node.matchIndex[node.id] = node.log.length - 1;
}

function recomputeCommit(node, peers) {

  const indices = [node.log.length - 1];
  for (const peer of peers) {
    indices.push(node.matchIndex[peer.id] ?? -1);
  }

  indices.sort((a, b) => b - a);
  const majorityPos = Math.floor((peers.length + 1) / 2);
  const candidate = indices[majorityPos];

  if (
    candidate > node.commitIndex &&
    node.log[candidate] &&
    node.log[candidate].term === node.term
  ) {
    node.commitIndex = candidate;
    applyCommitted(node);
  }
}

function followerSync(node, entries, leaderCommit) {
  node.log = Array.isArray(entries) ? entries : [];
  const lastIndex = node.log.length - 1;

  node.commitIndex = Math.min(leaderCommit, lastIndex);
  applyCommitted(node);
}

module.exports = { leaderAppend, recomputeCommit, followerSync };
