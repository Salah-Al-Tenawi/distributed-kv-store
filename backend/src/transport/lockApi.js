// =============================================================
// lockApi.js — واجهة الأقفال الموزّعة (Distributed Lock API)
// =============================================================
// يطبّق قفلاً موزّعاً (Distributed Lock) فوق المخزن المنسوخ. القائد
// (Leader) هو من يقرّر منح/رفض القفل، ثم ينسخ القرار عبر السجلّ (Log).
//
// ثلاثة مفاهيم:
//   1) Mutual Exclusion (إقصاء متبادل): مالك واحد فقط في كل لحظة.
//   2) TTL Lease (مهلة): القفل ينتهي تلقائياً (lockTtl) فلا يبقى للأبد لو مات صاحبه.
//   3) Fencing Token (رمز حماية): رقم متزايد مع كل منح؛ يرفض المورد أي رمز أقدم.
//
//   POST /lock/acquire { lockName, clientId }
//   POST /lock/release { lockName, clientId }

const { NodeState } = require('../node/states');
const { TIMING } = require('../config');
const { leaderAppend } = require('../node/replication');

/** هل القفل مشغول فعلياً الآن؟ (له مالك ولم تنتهِ مهلته). */
function isHeld(lock) {
  return lock && lock.owner && lock.expiresAt > Date.now();
}

function registerLockRoutes(app, node, election) {
  // طلب القفل (Acquire) — القائد فقط يقرّر.
  app.post('/lock/acquire', (req, res) => {
    if (node.state !== NodeState.LEADER) {
      return res.status(409).json({ ok: false, leaderId: node.leaderId });
    }
    const { lockName, clientId } = req.body;
    if (!lockName || !clientId) {
      return res.status(400).json({ ok: false, error: 'lockName & clientId required' });
    }

    const current = node.locks[lockName];
    // مشغول من عميل آخر ولم تنتهِ مهلته → نرفض (إقصاء متبادل).
    if (isHeld(current) && current.owner !== clientId) {
      return res.json({ ok: false, granted: false, owner: current.owner, token: current.token });
    }

    // حرّ (أو منتهٍ، أو نفس المالك يجدّد) → نمنحه برمز حماية جديد متزايد.
    const token = (current?.token ?? 0) + 1; // Fencing Token متزايد
    const expiresAt = Date.now() + TIMING.lockTtl;
    leaderAppend(node, { op: 'LOCK_ACQUIRE', key: lockName, owner: clientId, token, expiresAt });
    console.log(`[${node.id}] 🔒 منح القفل "${lockName}" لـ ${clientId} (token=${token})`);
    election.sendHeartbeat(); // نسخ فوري
    node.notifyChange();
    res.json({ ok: true, granted: true, token, expiresAt });
  });

  // تحرير القفل (Release) — المالك فقط.
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
