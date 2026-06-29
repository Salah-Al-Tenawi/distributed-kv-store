async function postToPeer(peer, path, body, timeoutMs = 120) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);
  try {
    const res = await fetch(`http://localhost:${peer.port}${path}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
      signal: controller.signal,
    });
    return await res.json();
  } catch (err) {
    return null;
  } finally {
    clearTimeout(timer);
  }
}

const { participantVote } = require('../node/twoPhaseCommit');

class PeerClient {
  sendRequestVote(peer, args) {
    return postToPeer(peer, '/rpc/request-vote', args);
  }

  sendAppendEntries(peer, args) {
    return postToPeer(peer, '/rpc/append-entries', args);
  }

  send2pcPrepare(peer, args) {
    return postToPeer(peer, '/rpc/2pc-prepare', args);
  }

  sendVcMerge(peer, args) {
    return postToPeer(peer, '/rpc/vc-merge', args);
  }
}

function registerPeerRoutes(app, election) {

  const dropIfDead = (req, res, next) => {
    if (!election.node.alive) return req.socket.destroy();
    next();
  };

  app.post('/rpc/request-vote', dropIfDead, (req, res) => {
    res.json(election.handleRequestVote(req.body));
  });

  app.post('/rpc/append-entries', dropIfDead, (req, res) => {
    res.json(election.handleAppendEntries(req.body));
  });

  app.post('/rpc/2pc-prepare', dropIfDead, (req, res) => {
    res.json({ vote: participantVote(election.node) });
  });
}

module.exports = { PeerClient, registerPeerRoutes };
