const { NodeState } = require('../node/states');
const { runTransaction } = require('../node/twoPhaseCommit');

function registerTxnRoutes(app, node, election) {
  app.post('/txn', async (req, res) => {
    if (node.state !== NodeState.LEADER) {
      return res.status(409).json({ ok: false, leaderId: node.leaderId });
    }
    const operations = Array.isArray(req.body?.operations) ? req.body.operations : [];
    if (operations.length === 0) {
      return res.status(400).json({ ok: false, error: 'operations required' });
    }
    const result = await runTransaction(
      node,
      election.rpc,
      election.peers,
      election,
      operations,
    );
    res.json({ ok: true, ...result });
  });
}

module.exports = { registerTxnRoutes };
