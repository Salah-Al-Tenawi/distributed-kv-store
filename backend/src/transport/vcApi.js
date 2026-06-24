// =============================================================
// vcApi.js — واجهة الساعات الشعاعية (Vector Clock API)
// =============================================================
//   POST /vc/event            → حدث محلّي على هذه العقدة (تزيد عدّادها)
//   POST /vc/send  { to }      → ترسل رسالة سببية لعقدة أخرى (to = معرّفها)
//   POST /vc/reset            → تصفير الساعة (للعرض)
//   POST /rpc/vc-merge { clock } → (داخلي) استقبال رسالة ودمج الساعة

const { localEvent, mergeClock } = require('../node/vectorClock');

function registerVcRoutes(app, node, election) {
  // حدث محلّي.
  app.post('/vc/event', (req, res) => {
    localEvent(node);
    node.notifyChange();
    res.json({ ok: true, vectorClock: node.vectorClock });
  });

  // إرسال رسالة سببية إلى عقدة أخرى.
  app.post('/vc/send', async (req, res) => {
    const to = req.body?.to;
    const peer = election.peers.find((p) => p.id === to);
    if (!peer) return res.status(400).json({ ok: false, error: 'unknown target' });

    localEvent(node); // الإرسال حدث، نزيد عدّادنا أولاً
    node.notifyChange();
    // نرفق ساعتنا كاملة؛ المستقبِل يدمجها ثم يزيد عدّاده.
    await election.rpc.sendVcMerge(peer, { clock: node.vectorClock });
    res.json({ ok: true, vectorClock: node.vectorClock });
  });

  // تصفير الساعة (لإعادة بدء العرض).
  app.post('/vc/reset', (req, res) => {
    for (const id of Object.keys(node.vectorClock)) node.vectorClock[id] = 0;
    node.notifyChange();
    res.json({ ok: true });
  });

  // استقبال رسالة سببية: دمج الساعة الواردة.
  app.post('/rpc/vc-merge', (req, res) => {
    mergeClock(node, req.body?.clock);
    node.notifyChange();
    res.json({ ok: true });
  });
}

module.exports = { registerVcRoutes };
