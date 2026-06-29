const { NodeState } = require('../node/states');
const { TIMING } = require('../config');
const { leaderAppend } = require('../node/replication');

function isHeld(lock) {
  return lock && lock.owner && lock.expiresAt > Date.now();
}

function registerLockRoutes(app, node, election) {

  app.post('/lock/acquire', (req, res) => {
    if (node.state !== NodeState.LEADER) {
      return res.status(409).json({ ok: false, leaderId: node.leaderId });
    }
    const { lockName, clientId } = req.body;
    if (!lockName || !clientId) {
      return res.status(400).json({ ok: false, error: 'lockName & clientId required' });
    }

    const current = node.locks[lockName];

    if (isHeld(current) && current.owner !== clientId) {
      return res.json({ ok: false, granted: false, owner: current.owner, token: current.token });
    }

    const token = (current?.token ?? 0) + 1;
    const expiresAt = Date.now() + TIMING.lockTtl;
    leaderAppend(node, { op: 'LOCK_ACQUIRE', key: lockName, owner: clientId, token, expiresAt });
    console.log(`[${node.id}] 🔒 منح القفل "${lockName}" لـ ${clientId} (token=${token})`);
    election.sendHeartbeat();
    node.notifyChange();
    res.json({ ok: true, granted: true, token, expiresAt });
  });

  app.post('/lock/release', (req, res) => {
    if (node.state !== NodeState.LEADER) {
      return res.status(409).json({ ok: false, leaderId: node.leaderId });
    }
    const { lockName, clientId } = req.body;
    const current = node.locks[lockName];
    if (!current || current.owner !== clientId) {
      return res.json({ ok: false, error: 'not the owner' });
    }
    leaderAppend(node, { op: 'LOCK_RELEASE', key: lockName });
    console.log(`[${node.id}] 🔓 حرّر ${clientId} القفل "${lockName}"`);
    election.sendHeartbeat();
    node.notifyChange();
    res.json({ ok: true });
  });
}

module.exports = { registerLockRoutes, isHeld };
