function registerAdminRoutes(app, election) {
  app.post('/admin/kill', (req, res) => {
    election.kill();
    res.json({ ok: true, alive: election.node.alive });
  });

  app.post('/admin/revive', (req, res) => {
    election.revive();
    res.json({ ok: true, alive: election.node.alive });
  });

  app.post('/admin/partition', (req, res) => {
    const blocked = Array.isArray(req.body?.blocked) ? req.body.blocked : [];
    election.setPartition(blocked);
    res.json({ ok: true, blocked });
  });

  app.post('/admin/heal', (req, res) => {
    election.heal();
    res.json({ ok: true });
  });

  app.post('/admin/vote-abort', (req, res) => {
    election.node.voteAbort = req.body?.value === true;
    election.node.notifyChange();
    res.json({ ok: true, voteAbort: election.node.voteAbort });
  });
}

module.exports = { registerAdminRoutes };
