// =============================================================
// replication.js — منطق نسخ السجلّ (Log Replication Logic)
// =============================================================
// يحوي العمليات التي تخصّ السجلّ (Log) بمعزل عن منطق الانتخاب:
//   - leaderAppend:   القائد يضيف أمراً جديداً لسجلّه.
//   - recomputeCommit: القائد يحسب أي المدخلات نُسخت لأغلبية (تُصبح مثبّتة).
//   - followerSync:    التابع يطابق سجلّه مع سجلّ القائد.
//
// تبسيط مقصود (للتعليم): القائد يرسل سجلّه كاملاً في كل نبضة، والتابع
// ينسخه كما هو ("القائد مصدر الحقيقة / source of truth"). Raft الحقيقي
// يرسل الفروقات فقط (incremental) عبر مطابقة prevLogIndex — لكن النتيجة
// المفاهيمية واحدة، والنسخة الكاملة أوضح للفهم في عنقود صغير.

const { applyCommitted } = require('../store/kvStore');

/** القائد يضيف أمراً جديداً (SET/DEL) إلى نهاية سجلّه (غير مثبّت بعد). */
function leaderAppend(node, command) {
  node.log.push({ term: node.term, ...command });
  // matchIndex الخاص بالقائد نفسه = آخر مؤشّر (يملك المدخلة فوراً).
  node.matchIndex[node.id] = node.log.length - 1;
}

/**
 * القائد يعيد حساب مؤشّر التثبيت (commitIndex):
 * أعلى مؤشّر نسخته أغلبية العُقَد (Majority) — ويكون من الدورة الحالية.
 */
function recomputeCommit(node, peers) {
  // نجمع آخر مؤشّر لدى كل عقدة (القائد + الأقران).
  const indices = [node.log.length - 1];
  for (const peer of peers) {
    indices.push(node.matchIndex[peer.id] ?? -1);
  }
  // نرتّب تنازلياً؛ العنصر عند موضع الأغلبية = المؤشّر المنسوخ لأغلبية.
  indices.sort((a, b) => b - a);
  const majorityPos = Math.floor((peers.length + 1) / 2); // 5 عُقَد → الموضع 2
  const candidate = indices[majorityPos];

  // نثبّت فقط إن كانت المدخلة من دورتنا الحالية (قاعدة أمان في Raft).
  if (
    candidate > node.commitIndex &&
    node.log[candidate] &&
    node.log[candidate].term === node.term
  ) {
    node.commitIndex = candidate;
    applyCommitted(node); // طبّق الجديد على المخزن kv
  }
}

/** التابع يطابق سجلّه مع القائد، ثم يثبّت ما ثبّته القائد. */
function followerSync(node, entries, leaderCommit) {
  node.log = Array.isArray(entries) ? entries : [];
  const lastIndex = node.log.length - 1;
  // نثبّت حتى ما ثبّته القائد، دون تجاوز ما نملكه فعلاً.
  node.commitIndex = Math.min(leaderCommit, lastIndex);
  applyCommitted(node);
}

module.exports = { leaderAppend, recomputeCommit, followerSync };
