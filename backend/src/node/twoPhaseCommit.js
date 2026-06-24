// =============================================================
// twoPhaseCommit.js — الالتزام ثنائي الطور (Two-Phase Commit / 2PC)
// =============================================================
// بروتوكول لتنفيذ معاملة (Transaction) على عدّة عُقَد بشكل ذرّي
// (Atomic): إمّا تلتزم كل العُقَد أو لا تلتزم أيّ منها.
//
// الأطوار:
//   Phase 1 — Prepare/Vote (التحضير/التصويت): المنسّق (Coordinator = Leader)
//             يسأل كل مشارك (Participant): "هل تستطيع الالتزام؟" فيصوّت YES أو NO.
//   Phase 2 — Commit/Abort: إن صوّت الجميع YES → COMMIT للجميع.
//             إن صوّت أحدهم NO (أو لم يردّ) → ABORT للجميع.
//
// نموذجنا: القائد هو المنسّق، والعُقَد هي المشاركون. عند الالتزام نكتب
// عمليات المعاملة عبر سجلّ Raft (فتُنسَخ بأمان كالمعتاد).

const { NodeState } = require('./states');
const { leaderAppend } = require('./replication');

/**
 * تصويت المشارك (Participant vote): يصوّت NO إن كان ميتاً أو مُجبَراً على الرفض
 * (محاكاة تعارض موارد / نقص مساحة)، وإلا YES.
 */
function participantVote(node) {
  if (!node.alive) return 'NO';
  if (node.voteAbort) return 'NO';
  return 'YES';
}

/**
 * يشغّل معاملة 2PC على القائد (المنسّق).
 * @param {object} node العقدة (يجب أن تكون LEADER)
 * @param {object} rpc عميل الـ RPC للوصول للأقران
 * @param {Array} peers الأقران
 * @param {object} election وحدة الانتخاب (لإرسال نبضة النسخ بعد الالتزام)
 * @param {Array} operations عمليات المعاملة [{ key, value }]
 */
async function runTransaction(node, rpc, peers, election, operations) {
  const txId = `tx-${Date.now()}`;
  const votes = {};

  // --- Phase 1: Prepare/Vote ---
  votes[node.id] = participantVote(node); // صوت المنسّق نفسه
  await Promise.all(
    peers.map(async (peer) => {
      const reply = await rpc.send2pcPrepare(peer, { txId, operations });
      votes[peer.id] = reply?.vote ?? 'NO'; // لم يردّ = ميت/معزول → NO
    }),
  );

  // --- Phase 2: Commit/Abort ---
  const allYes = Object.values(votes).every((v) => v === 'YES');
  let result;
  if (allYes) {
    // الكل وافق → نلتزم: نكتب العمليات عبر سجلّ Raft (نسخ آمن).
    for (const op of operations) {
      leaderAppend(node, { op: 'SET', key: op.key, value: String(op.value ?? '') });
    }
    election.sendHeartbeat();
    result = 'COMMITTED';
  } else {
    result = 'ABORTED'; // أحدهم رفض → لا شيء يُكتب
  }

  node.lastTxn = { id: txId, operations, votes, result, ts: Date.now() };
  console.log(`[${node.id}] 🧾 معاملة 2PC ${txId}: ${result} | الأصوات: ${JSON.stringify(votes)}`);
  node.notifyChange();
  return node.lastTxn;
}

module.exports = { participantVote, runTransaction, NodeState };
