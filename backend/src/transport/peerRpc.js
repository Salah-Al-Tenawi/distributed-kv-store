// =============================================================
// peerRpc.js — التواصل بين العُقَد (Node-to-Node Communication / RPC)
// =============================================================
// RPC = Remote Procedure Call (استدعاء إجراء بعيد): عقدة "تنادي" دالة
// على عقدة أخرى عبر الشبكة. نستخدم HTTP بسيطاً (POST + JSON).
//
// نوعا الرسائل في الانتخاب (Raft):
//   1) RequestVote   (طلب تصويت)  — يرسلها المرشّح (Candidate) ليجمع أصواتاً.
//   2) AppendEntries (إلحاق سجلّات) — يرسلها القائد (Leader)؛ الفارغة منها = نبضة (Heartbeat).
//
// هذا الملف يحوي:
//   - PeerClient: لإرسال الرسائل إلى عقدة أخرى (الجانب المُرسِل / sender).
//   - registerPeerRoutes: لاستقبال الرسائل (الجانب المُستقبِل / receiver).
//
// ملاحظة: Node.js 20 يوفّر fetch() عالمياً، فلا نحتاج مكتبة إضافية.

/**
 * يرسل طلباً إلى عقدة أخرى. يُعيد رد العقدة (JSON) أو null عند الفشل
 * (مثلاً العقدة الأخرى ميتة / غير متاحة — وهذا أمر طبيعي ومتوقّع).
 */
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
    return null; // العقدة لا ترد (ميتة أو بطيئة) — نتعامل معها كصمت.
  } finally {
    clearTimeout(timer);
  }
}

/** عميل لإرسال رسائل RPC من هذه العقدة إلى أقرانها (peers). */
class PeerClient {
  sendRequestVote(peer, args) {
    return postToPeer(peer, '/rpc/request-vote', args);
  }

  sendAppendEntries(peer, args) {
    return postToPeer(peer, '/rpc/append-entries', args);
  }
}

/**
 * يسجّل مسارات (routes) استقبال الرسائل على سيرفر express.
 * عند وصول رسالة، نستدعي الدالة المناسبة في وحدة الانتخاب (election).
 */
function registerPeerRoutes(app, election) {
  app.post('/rpc/request-vote', (req, res) => {
    res.json(election.handleRequestVote(req.body));
  });

  app.post('/rpc/append-entries', (req, res) => {
    res.json(election.handleAppendEntries(req.body));
  });
}

module.exports = { PeerClient, registerPeerRoutes };
