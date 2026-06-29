const { localEvent, mergeClock } = require('../node/vectorClock');

function registerVcRoutes(app, node, election) {

  app.post('/vc/event', (req, res) => {
    localEvent(node);
    node.notifyChange();
    res.json({ ok: true, vectorClock: node.vectorClock });
  });

  app.post('/vc/send', async (req, res) => {
    const to = req.body?.to;
    const peer = election.peers.find((p) => p.id === to);
    if (!peer) return res.status(400).json({ ok: false, error: 'unknown target' });

    localEvent(node);
    node.notifyChange();

    await election.rpc.sendVcMerge(peer, { clock: node.vectorClock });
    res.json({ ok: true, vectorClock: node.vectorClock });
  });

  app.post('/vc/reset', (req, res) => {
    for (const id of Object.keys(node.vectorClock)) node.vectorClock[id] = 0;
    node.notifyChange();
    res.json({ ok: true });
  });

  app.post('/rpc/vc-merge', (req, res) => {
    mergeClock(node, req.body?.clock);
    node.notifyChange();
    res.json({ ok: true });
  });
}

module.exports = { registerVcRoutes };
