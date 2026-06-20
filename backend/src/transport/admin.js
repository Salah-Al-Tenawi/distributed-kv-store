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
}

module.exports = { registerAdminRoutes };
