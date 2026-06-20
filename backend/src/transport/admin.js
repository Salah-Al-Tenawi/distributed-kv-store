// =============================================================
// admin.js — أوامر التحكّم من لوحة Flutter (Admin / Control API)
// =============================================================
// نقاط HTTP تسمح للوحة بالتحكّم بالعقدة لأغراض العرض (Demo):
//   POST /admin/kill    → "يقتل" العقدة (محاكاة تعطّل / Crash)
//   POST /admin/revive  → "يُحيي" العقدة (تعود للمشاركة)
//
// ملاحظة: نقاط القتل/الإحياء تظلّ تعمل حتى وهي "ميتة" (لأنها قناة
// تحكّم خارجية وليست جزءاً من بروتوكول العنقود نفسه).

function registerAdminRoutes(app, election) {
  app.post('/admin/kill', (req, res) => {
    election.kill();
    res.json({ ok: true, alive: election.node.alive });
  });

  app.post('/admin/revive', (req, res) => {
    election.revive();
    res.json({ ok: true, alive: election.node.alive });
  });

  // انقسام الشبكة: نحجب التواصل مع الأقران في القائمة { blocked: [...] }.
  app.post('/admin/partition', (req, res) => {
    const blocked = Array.isArray(req.body?.blocked) ? req.body.blocked : [];
    election.setPartition(blocked);
    res.json({ ok: true, blocked });
  });

  // شفاء الشبكة: إزالة كل الحجب.
  app.post('/admin/heal', (req, res) => {
    election.heal();
    res.json({ ok: true });
  });
}

module.exports = { registerAdminRoutes };
