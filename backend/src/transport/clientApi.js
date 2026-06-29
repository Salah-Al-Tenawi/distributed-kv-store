const { NodeState } = require('../node/states');
const { leaderAppend } = require('../node/replication');

function registerClientRoutes(app, node, election) {

  app.post('/kv/put', (req, res) => {
    if (node.state !== NodeState.LEADER) {
      return res.status(409).json({ ok: false, leaderId: node.leaderId });
    }
    const { key, value } = req.body;
    if (!key) return res.status(400).json({ ok: false, error: 'key required' });

    leaderAppend(node, { op: 'SET', key, value: String(value ?? '') });
    console.log(`[${node.id}] 📝 أمر جديد في السجلّ: SET ${key}=${value}`);
    election.sendHeartbeat();
    node.notifyChange();
    res.json({ ok: true, logIndex: node.log.length - 1 });
  });

  app.post('/kv/del', (req, res) => {
    if (node.state !== NodeState.LEADER) {
      return res.status(409).json({ ok: false, leaderId: node.leaderId });
    }
    const { key } = req.body;
    if (!key) return res.status(400).json({ ok: false, error: 'key required' });

    leaderAppend(node, { op: 'DEL', key });
    console.log(`[${node.id}] 📝 أمر جديد في السجلّ: DEL ${key}`);
    election.sendHeartbeat();
    node.notifyChange();
    res.json({ ok: true, logIndex: node.log.length - 1 });
  });

  app.get('/kv', (req, res) => {
    res.json({ kv: node.kv, commitIndex: node.commitIndex });
  });
}

module.exports = { registerClientRoutes };
