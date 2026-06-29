const { NodeState } = require('./states');
const { TIMING, getPeers } = require('../config');
const { recomputeCommit, followerSync, leaderAppend } = require('./replication');

class Election {

  constructor(node, rpc) {
    this.node = node;
    this.rpc = rpc;
    this.peers = getPeers(node.id);

    this.electionTimer = null;
    this.heartbeatTimer = null;
    this.peerLastAck = {};
    this.releasing = new Set();
  }

  start() {
    this.becomeFollower(this.node.term);
  }

  stop() {
    clearTimeout(this.electionTimer);
    this.stopHeartbeats();
  }

  kill() {
    if (!this.node.alive) return;
    this.node.alive = false;
    this.stop();
    this.node.state = NodeState.FOLLOWER;
    this.node.leaderId = null;
    this.node.suspectedOffline = [];
    console.log(`[${this.node.id}] CRASHED - stopped participating`);
    this.node.notifyChange();
  }

  revive() {
    if (this.node.alive) return;
    this.node.alive = true;
    console.log(`[${this.node.id}] REVIVED - back as Follower`);
    this.becomeFollower(this.node.term);
  }

  setPartition(blockedIds) {
    this.node.blockedPeers = new Set(blockedIds);
    console.log(`[${this.node.id}] network partition - blocked: [${blockedIds.join(', ')}]`);
    this.node.notifyChange();
  }

  heal() {
    this.node.blockedPeers = new Set();
    console.log(`[${this.node.id}] network HEALED - connectivity restored`);
    this.node.notifyChange();
  }

  randomTimeout() {
    const { electionTimeoutMin, electionTimeoutMax } = TIMING;
    return (
      electionTimeoutMin +
      Math.floor(Math.random() * (electionTimeoutMax - electionTimeoutMin))
    );
  }

  resetElectionTimer() {
    clearTimeout(this.electionTimer);
    this.electionTimer = setTimeout(() => this.startElection(), this.randomTimeout());
  }

  stopHeartbeats() {
    clearInterval(this.heartbeatTimer);
    this.heartbeatTimer = null;
  }

  becomeFollower(term) {
    this.node.state = NodeState.FOLLOWER;
    this.node.term = term;
    this.node.votedFor = null;
    this.node.votesReceived = 0;
    this.node.suspectedOffline = [];
    this.stopHeartbeats();
    this.resetElectionTimer();
    this.node.notifyChange();
  }

  async startElection() {
    if (!this.node.alive) return;
    this.node.state = NodeState.CANDIDATE;
    this.node.term += 1;
    this.node.votedFor = this.node.id;
    this.node.votesReceived = 1;
    this.node.leaderId = null;
    this.node.notifyChange();
    console.log(`[${this.node.id}] election timeout -> CANDIDATE in term=${this.node.term}`);

    this.resetElectionTimer();

    const lastLogIndex = this.node.log.length - 1;
    const lastLogTerm = lastLogIndex >= 0 ? this.node.log[lastLogIndex].term : 0;
    const args = {
      term: this.node.term,
      candidateId: this.node.id,
      lastLogIndex,
      lastLogTerm,
    };

    for (const peer of this.peers) {
      if (this.node.blockedPeers.has(peer.id)) continue;
      this.rpc.sendRequestVote(peer, args).then((reply) => {
        this.handleVoteReply(reply);
      });
    }
  }

  becomeLeader() {
    if (this.node.state !== NodeState.CANDIDATE) return;
    this.node.state = NodeState.LEADER;
    this.node.leaderId = this.node.id;
    clearTimeout(this.electionTimer);

    const now = Date.now();
    for (const peer of this.peers) this.peerLastAck[peer.id] = now;
    this.node.suspectedOffline = [];

    this.node.matchIndex = { [this.node.id]: this.node.log.length - 1 };
    for (const peer of this.peers) this.node.matchIndex[peer.id] = -1;
    this.node.notifyChange();
    console.log(`[${this.node.id}] became LEADER in term=${this.node.term}`);
    this.startHeartbeats();
  }

  startHeartbeats() {
    this.stopHeartbeats();
    this.sendHeartbeat();
    this.heartbeatTimer = setInterval(
      () => this.sendHeartbeat(),
      TIMING.heartbeatInterval,
    );
  }

  sendHeartbeat() {
    if (this.node.state !== NodeState.LEADER) return;

    const args = {
      term: this.node.term,
      leaderId: this.node.id,
      entries: this.node.log,
      leaderCommit: this.node.commitIndex,
    };
    for (const peer of this.peers) {
      if (this.node.blockedPeers.has(peer.id)) continue;
      this.rpc.sendAppendEntries(peer, args).then((reply) => {
        if (!reply) return;
        this.peerLastAck[peer.id] = Date.now();

        if (reply.term > this.node.term) return this.becomeFollower(reply.term);

        this.node.matchIndex[peer.id] = reply.matchIndex ?? -1;
        recomputeCommit(this.node, this.peers);
        this.node.notifyChange();
      });
    }
    this.detectFailures();
    this.sweepExpiredLocks();
  }

  sweepExpiredLocks() {
    if (this.node.state !== NodeState.LEADER) return;
    const now = Date.now();
    for (const [name, lock] of Object.entries(this.node.locks)) {
      if (lock.expiresAt <= now && !this.releasing.has(name)) {
        this.releasing.add(name);
        leaderAppend(this.node, { op: 'LOCK_RELEASE', key: name });
        console.log(`[${this.node.id}] lock "${name}" expired - auto released`);
      }
    }

    for (const name of this.releasing) {
      if (!this.node.locks[name] || this.node.locks[name].owner == null) {
        this.releasing.delete(name);
      }
    }
  }

  detectFailures() {
    if (this.node.state !== NodeState.LEADER) return;
    const now = Date.now();
    const offline = [];
    for (const peer of this.peers) {
      const last = this.peerLastAck[peer.id] || 0;
      if (now - last > TIMING.failureTimeout) offline.push(peer.id);
    }

    const changed =
      offline.length !== this.node.suspectedOffline.length ||
      offline.some((id) => !this.node.suspectedOffline.includes(id));
    if (changed) {
      const newlyDead = offline.filter((id) => !this.node.suspectedOffline.includes(id));
      for (const id of newlyDead) {
        console.log(`[${this.node.id}] peer ${id} stopped responding - marked OFFLINE`);
      }
      this.node.suspectedOffline = offline;
      this.node.notifyChange();
    }
  }

  handleVoteReply(reply) {
    if (!reply) return;
    if (this.node.state !== NodeState.CANDIDATE) return;

    if (reply.term > this.node.term) {
      this.becomeFollower(reply.term);
      return;
    }

    if (reply.voteGranted) {
      this.node.votesReceived += 1;
      const majority = Math.floor((this.peers.length + 1) / 2) + 1;
      console.log(`[${this.node.id}] votes=${this.node.votesReceived}/${this.peers.length + 1} (need ${majority})`);
      if (this.node.votesReceived >= majority) {
        this.becomeLeader();
      }
    }
  }

  handleRequestVote(args) {
    const { term, candidateId } = args;

    if (this.node.blockedPeers.has(candidateId)) {
      return { term: this.node.term, voteGranted: false };
    }

    if (term < this.node.term) {
      return { term: this.node.term, voteGranted: false };
    }

    if (term > this.node.term) {
      this.becomeFollower(term);
    }

    const myLastIndex = this.node.log.length - 1;
    const myLastTerm = myLastIndex >= 0 ? this.node.log[myLastIndex].term : 0;
    const candidateLogOk =
      (args.lastLogTerm ?? 0) > myLastTerm ||
      ((args.lastLogTerm ?? 0) === myLastTerm &&
        (args.lastLogIndex ?? -1) >= myLastIndex);

    const canVote =
      (this.node.votedFor === null || this.node.votedFor === candidateId) &&
      candidateLogOk;

    if (canVote) {
      this.node.votedFor = candidateId;
      this.resetElectionTimer();
      this.node.notifyChange();
      return { term: this.node.term, voteGranted: true };
    }

    return { term: this.node.term, voteGranted: false };
  }

  handleAppendEntries(args) {
    const { term, leaderId, entries, leaderCommit } = args;

    if (this.node.blockedPeers.has(leaderId)) {
      return { term: this.node.term, success: false };
    }

    if (term < this.node.term) {
      return { term: this.node.term, success: false };
    }

    this.node.leaderId = leaderId;
    if (term > this.node.term || this.node.state !== NodeState.FOLLOWER) {
      this.becomeFollower(term);
    } else {
      this.resetElectionTimer();
    }

    followerSync(this.node, entries, leaderCommit ?? -1);

    this.node.notifyChange();

    return {
      term: this.node.term,
      success: true,
      matchIndex: this.node.log.length - 1,
    };
  }
}

module.exports = { Election };
