// =============================================================
// election.js — منطق انتخاب القائد (Leader Election Logic)
// =============================================================
// يطبّق نواة خوارزمية Raft للانتخاب. الفكرة باختصار:
//   - كل عقدة تبدأ تابعاً (Follower) ومعها مؤقّت عشوائي (random Election Timeout).
//   - إن لم تسمع نبضة (Heartbeat) من قائد خلال المهلة → تصبح مرشّحاً (Candidate)
//     وتطلب أصواتاً (RequestVote).
//   - من يجمع أغلبية الأصوات (Majority) يصبح قائداً (Leader) ويبدأ بإرسال النبضات.
//
// العشوائية (randomness) في المهلة مهمّة: تمنع كل العُقَد من الترشّح معاً (Split Vote).

const { NodeState } = require('./states');
const { TIMING, getPeers } = require('../config');
const { recomputeCommit, followerSync } = require('./replication');

class Election {
  /**
   * @param {import('./Node').Node} node العقدة التي ندير انتخابها
   * @param {import('../transport/peerRpc').PeerClient} rpc عميل إرسال الرسائل
   */
  constructor(node, rpc) {
    this.node = node;
    this.rpc = rpc;
    this.peers = getPeers(node.id); // باقي العُقَد (عدا نفسها)

    this.electionTimer = null;   // مؤقّت بدء الانتخاب (Follower/Candidate)
    this.heartbeatTimer = null;  // مؤقّت إرسال النبضات (Leader فقط)
    this.peerLastAck = {};       // آخر وقت ردّ فيه كل قرين (peer) — لكشف الأعطال
  }

  /** نقطة البدء: العقدة تبدأ تابعاً وتشغّل مؤقّت الانتخاب. */
  start() {
    this.becomeFollower(this.node.term);
  }

  /** يوقف كل المؤقّتات (نستخدمه عند "قتل" العقدة / Crash). */
  stop() {
    clearTimeout(this.electionTimer);
    this.stopHeartbeats();
  }

  // ---------------------------------------------------------
  // قتل / إحياء العقدة (Kill / Revive — محاكاة الأعطال)
  // ---------------------------------------------------------

  /** "يقتل" العقدة: تتوقّف عن المشاركة تماماً (محاكاة Crash). */
  kill() {
    if (!this.node.alive) return;
    this.node.alive = false;
    this.stop();                       // توقف المؤقّتات (لا انتخاب ولا نبضات)
    this.node.state = NodeState.FOLLOWER;
    this.node.leaderId = null;
    this.node.suspectedOffline = [];
    console.log(`[${this.node.id}] 💀 قُتلت (CRASHED) — توقّفت عن المشاركة`);
    this.node.notifyChange();
  }

  /** "يُحيي" العقدة: تعود تابعاً وتستأنف المشاركة. */
  revive() {
    if (this.node.alive) return;
    this.node.alive = true;
    console.log(`[${this.node.id}] ❤️  أُحييت (REVIVED) — عادت تابعاً (Follower)`);
    this.becomeFollower(this.node.term);
  }

  // ---------------------------------------------------------
  // المؤقّتات (Timers)
  // ---------------------------------------------------------

  /** مهلة انتخاب عشوائية بين الحدّين (لكسر التعادل / avoid split vote). */
  randomTimeout() {
    const { electionTimeoutMin, electionTimeoutMax } = TIMING;
    return (
      electionTimeoutMin +
      Math.floor(Math.random() * (electionTimeoutMax - electionTimeoutMin))
    );
  }

  /** يعيد ضبط مؤقّت الانتخاب — نستدعيه كلما سمعنا من القائد أو منحنا صوتاً. */
  resetElectionTimer() {
    clearTimeout(this.electionTimer);
    this.electionTimer = setTimeout(() => this.startElection(), this.randomTimeout());
  }

  stopHeartbeats() {
    clearInterval(this.heartbeatTimer);
    this.heartbeatTimer = null;
  }

  // ---------------------------------------------------------
  // الانتقالات بين الحالات (State Transitions)
  // ---------------------------------------------------------

  /** يتحوّل إلى تابع (Follower) ضمن دورة (term) معيّنة. */
  becomeFollower(term) {
    this.node.state = NodeState.FOLLOWER;
    this.node.term = term;
    this.node.votedFor = null;
    this.node.votesReceived = 0;
    this.node.suspectedOffline = []; // كشف الأعطال مسؤولية القائد فقط
    this.stopHeartbeats();
    this.resetElectionTimer();
    this.node.notifyChange();
  }

  /** يبدأ انتخاباً: يصبح مرشّحاً (Candidate) ويطلب الأصوات. */
  async startElection() {
    if (!this.node.alive) return; // العقدة الميتة لا تترشّح
    this.node.state = NodeState.CANDIDATE;
    this.node.term += 1;             // كل انتخاب = دورة (term) جديدة
    this.node.votedFor = this.node.id; // يصوّت لنفسه
    this.node.votesReceived = 1;
    this.node.leaderId = null;
    this.node.notifyChange();
    console.log(`[${this.node.id}] ⏱️  انتهت المهلة → مرشّح (CANDIDATE) في term=${this.node.term}`);

    this.resetElectionTimer(); // إن فشل الانتخاب، نحاول مجدداً لاحقاً

    const args = { term: this.node.term, candidateId: this.node.id };

    // نرسل طلب التصويت (RequestVote) لكل الأقران بالتوازي.
    for (const peer of this.peers) {
      this.rpc.sendRequestVote(peer, args).then((reply) => {
        this.handleVoteReply(reply);
      });
    }
  }

  /** يصبح قائداً (Leader) ويبدأ بثّ النبضات فوراً. */
  becomeLeader() {
    if (this.node.state !== NodeState.CANDIDATE) return;
    this.node.state = NodeState.LEADER;
    this.node.leaderId = this.node.id;
    clearTimeout(this.electionTimer); // القائد لا يحتاج مؤقّت انتخاب
    // نعتبر كل الأقران أحياء لحظة الفوز، ثم يبدأ الكاشف بمراقبتهم.
    const now = Date.now();
    for (const peer of this.peers) this.peerLastAck[peer.id] = now;
    this.node.suspectedOffline = [];

    // نهيّئ matchIndex: نعرف موقعنا، ونجهل مواقع الأقران بعد (-1).
    this.node.matchIndex = { [this.node.id]: this.node.log.length - 1 };
    for (const peer of this.peers) this.node.matchIndex[peer.id] = -1;
    this.node.notifyChange();
    console.log(`[${this.node.id}] 👑 أصبح قائداً (LEADER) في term=${this.node.term}`);
    this.startHeartbeats();
  }

  // ---------------------------------------------------------
  // النبضات (Heartbeats) — يرسلها القائد فقط
  // ---------------------------------------------------------

  startHeartbeats() {
    this.stopHeartbeats();
    this.sendHeartbeat(); // نبضة فورية عند الفوز
    this.heartbeatTimer = setInterval(
      () => this.sendHeartbeat(),
      TIMING.heartbeatInterval,
    );
  }

  /** يرسل نبضة (AppendEntries) لكل الأقران؛ تحمل السجلّ ومؤشّر التثبيت. */
  sendHeartbeat() {
    if (this.node.state !== NodeState.LEADER) return;
    // النبضة تحمل السجلّ كاملاً + مؤشّر التثبيت (leaderCommit).
    // سجلّ فارغ → نبضة خالصة (heartbeat)؛ وإلا → نسخ بيانات (replication).
    const args = {
      term: this.node.term,
      leaderId: this.node.id,
      entries: this.node.log,
      leaderCommit: this.node.commitIndex,
    };
    for (const peer of this.peers) {
      this.rpc.sendAppendEntries(peer, args).then((reply) => {
        if (!reply) return; // قرين لم يردّ (ربما ميت) — كاشف الأعطال سيتولّاه
        this.peerLastAck[peer.id] = Date.now();
        // إن ردّ بدورة أحدث → نحن قائد قديم (stale leader)، نتنحّى.
        if (reply.term > this.node.term) return this.becomeFollower(reply.term);
        // نسجّل آخر مؤشّر نسخه القرين، ثم نعيد حساب التثبيت (commit).
        this.node.matchIndex[peer.id] = reply.matchIndex ?? -1;
        recomputeCommit(this.node, this.peers);
        this.node.notifyChange();
      });
    }
    this.detectFailures(); // بعد إرسال النبضات، نفحص من تأخّر بالرد
  }

  /**
   * كاشف الأعطال (Failure Detector) — يعمل في القائد فقط.
   * أي قرين لم يردّ منذ failureTimeout (≈3 نبضات) يُعدّ ميتاً (OFFLINE).
   */
  detectFailures() {
    if (this.node.state !== NodeState.LEADER) return;
    const now = Date.now();
    const offline = [];
    for (const peer of this.peers) {
      const last = this.peerLastAck[peer.id] || 0;
      if (now - last > TIMING.failureTimeout) offline.push(peer.id);
    }
    // نُسجّل فقط عند تغيّر القائمة (دخول/خروج عقدة) لتجنّب إغراق السجلّ.
    const changed =
      offline.length !== this.node.suspectedOffline.length ||
      offline.some((id) => !this.node.suspectedOffline.includes(id));
    if (changed) {
      const newlyDead = offline.filter((id) => !this.node.suspectedOffline.includes(id));
      for (const id of newlyDead) {
        console.log(`[${this.node.id}] ⚠️  القرين ${id} توقّف عن النبض — تمييزه OFFLINE`);
      }
      this.node.suspectedOffline = offline;
      this.node.notifyChange();
    }
  }

  // ---------------------------------------------------------
  // استقبال الردود والطلبات (Receivers)
  // ---------------------------------------------------------

  /** معالجة رد على طلب تصويت أرسلناه. */
  handleVoteReply(reply) {
    if (!reply) return; // قرين لم يردّ
    if (this.node.state !== NodeState.CANDIDATE) return;

    // إن كان رد القرين بدورة أحدث → نتراجع لتابع.
    if (reply.term > this.node.term) {
      this.becomeFollower(reply.term);
      return;
    }

    if (reply.voteGranted) {
      this.node.votesReceived += 1;
      const majority = Math.floor((this.peers.length + 1) / 2) + 1; // أكثر من النصف
      console.log(`[${this.node.id}] 🗳️  أصوات=${this.node.votesReceived}/${this.peers.length + 1} (نحتاج ${majority})`);
      if (this.node.votesReceived >= majority) {
        this.becomeLeader();
      }
    }
  }

  /** يستقبل طلب تصويت (RequestVote) من مرشّح آخر، ويقرّر التصويت. */
  handleRequestVote(args) {
    const { term, candidateId } = args;

    // 1) دورة المرشّح أقدم من دورتنا → نرفض.
    if (term < this.node.term) {
      return { term: this.node.term, voteGranted: false };
    }

    // 2) دورة المرشّح أحدث → نحدّث دورتنا ونصبح تابعاً (نعيد ضبط من صوّتنا له).
    if (term > this.node.term) {
      this.becomeFollower(term);
    }

    // 3) نصوّت إن لم نكن صوّتنا لأحد بعد في هذه الدورة (أو صوّتنا لنفس المرشّح).
    const canVote =
      this.node.votedFor === null || this.node.votedFor === candidateId;

    if (canVote) {
      this.node.votedFor = candidateId;
      this.resetElectionTimer(); // منحنا صوتاً → نؤجّل ترشّحنا
      this.node.notifyChange();
      return { term: this.node.term, voteGranted: true };
    }

    return { term: this.node.term, voteGranted: false };
  }

  /** يستقبل نبضة/سجلّات (AppendEntries) من القائد. */
  handleAppendEntries(args) {
    const { term, leaderId, entries, leaderCommit } = args;

    // نبضة من قائد بدورة أقدم → نرفض (قائد منتهي الصلاحية / stale leader).
    if (term < this.node.term) {
      return { term: this.node.term, success: false };
    }

    // نبضة صحيحة: نعترف بالقائد، نبقى/نصبح تابعين، ونعيد ضبط مؤقّت الانتخاب.
    this.node.leaderId = leaderId;
    if (term > this.node.term || this.node.state !== NodeState.FOLLOWER) {
      this.becomeFollower(term);
    } else {
      this.resetElectionTimer(); // أهم سطر: النبضة تمنع بدء انتخاب جديد
    }

    // نسخ السجلّ: نطابق سجلّنا مع القائد ونثبّت ما ثبّته.
    followerSync(this.node, entries, leaderCommit ?? -1);

    this.node.notifyChange();
    // نُبلغ القائد بآخر مؤشّر نملكه (matchIndex) ليحسب الأغلبية.
    return {
      term: this.node.term,
      success: true,
      matchIndex: this.node.log.length - 1,
    };
  }
}

module.exports = { Election };
