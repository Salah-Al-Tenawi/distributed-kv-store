const { NodeState } = require('./states');
const { leaderAppend } = require('./replication');

function participantVote(node) {
  if (!node.alive) return 'NO';
  if (node.voteAbort) return 'NO';
  return 'YES';
}

async function runTransaction(node, rpc, peers, election, operations) {
  const txId = `tx-${Date.now()}`;
  const votes = {};

  votes[node.id] = participantVote(node);
  await Promise.all(
    peers.map(async (peer) => {
      const reply = await rpc.send2pcPrepare(peer, { txId, operations });
      votes[peer.id] = reply?.vote ?? 'NO';
    }),
  );

  const allYes = Object.values(votes).every((v) => v === 'YES');
  let result;
  if (allYes) {

    for (const op of operations) {
      leaderAppend(node, { op: 'SET', key: op.key, value: String(op.value ?? '') });
    }
    election.sendHeartbeat();
    result = 'COMMITTED';
  } else {
    result = 'ABORTED';
  }

  node.lastTxn = { id: txId, operations, votes, result, ts: Date.now() };
  console.log(`[${node.id}] 2PC transaction ${txId}: ${result} | votes: ${JSON.stringify(votes)}`);
  node.notifyChange();
  return node.lastTxn;
}

module.exports = { participantVote, runTransaction, NodeState };
