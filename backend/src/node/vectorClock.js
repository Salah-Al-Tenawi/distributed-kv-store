// =============================================================
// vectorClock.js — الساعات الشعاعية (Vector Clocks)
// =============================================================
// ساعة شعاعية = خريطة { nodeId: counter } تتبع السببية (Causality)
// بين الأحداث في نظام موزّع لا توجد فيه ساعة فيزيائية مشتركة.
//
// القواعد:
//   1) عند حدث محلّي (Local Event): العقدة تزيد عدّادها هي فقط.
//   2) عند إرسال رسالة: تزيد عدّادها وترفق ساعتها كاملة.
//   3) عند الاستقبال: تدمج (Merge) بأخذ الأكبر لكل عنصر، ثم تزيد عدّادها.
//
// المقارنة:
//   - A → B (سبق سببي / happened-before): كل عناصر A ≤ B وأحدها أصغر فعلاً.
//   - متزامنان (Concurrent): لا A ≤ B ولا B ≤ A (مستقلّان سببياً).

/** حدث محلّي: نزيد عدّاد هذه العقدة فقط. */
function localEvent(node) {
  node.vectorClock[node.id] = (node.vectorClock[node.id] ?? 0) + 1;
}

/** دمج ساعة واردة (عند استقبال رسالة): max لكل عنصر، ثم زيادة عدّادنا. */
function mergeClock(node, incoming) {
  for (const [id, val] of Object.entries(incoming || {})) {
    node.vectorClock[id] = Math.max(node.vectorClock[id] ?? 0, val);
  }
  node.vectorClock[node.id] = (node.vectorClock[node.id] ?? 0) + 1;
}

module.exports = { localEvent, mergeClock };
