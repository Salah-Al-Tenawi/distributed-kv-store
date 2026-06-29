const { NodeState } = require('./states');
const { CLUSTER } = require('../config');

class Node {

  constructor(id, port) {
    this.id = id;
    this.port = port;

    this.state = NodeState.FOLLOWER;
    this.term = 0;
    this.leaderId = null;

    this.votedFor = null;
    this.votesReceived = 0;

    this.alive = true;
    this.suspectedOffline = [];

    this.blockedPeers = new Set();

    this.log = [];
    this.commitIndex = -1;
    this.lastApplied = -1;
    this.kv = {};
    this.matchIndex = {};

    this.locks = {};

    this.voteAbort = false;
    this.lastTxn = null;

    this.vectorClock = {};
    for (const member of CLUSTER) this.vectorClock[member.id] = 0;

    this.onStateChange = () => {};
  }

  getSnapshot() {
    return {
      id: this.id,
      port: this.port,
      state: this.state,
      term: this.term,
      leaderId: this.leaderId,
      online: this.alive,
      suspectedOffline: this.suspectedOffline,
      kv: this.kv,
      logLength: this.log.length,
      commitIndex: this.commitIndex,
      blockedPeers: [...this.blockedPeers],
      locks: this.locks,
      voteAbort: this.voteAbort,
      lastTxn: this.lastTxn,
      vectorClock: this.vectorClock,
      timestamp: Date.now(),
    };
  }

  notifyChange() {
    this.onStateChange(this.getSnapshot());
  }
}

module.exports = { Node };
