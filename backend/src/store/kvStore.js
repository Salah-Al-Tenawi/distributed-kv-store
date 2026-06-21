// =============================================================
// kvStore.js — آلة الحالة (State Machine): تطبيق المدخلات على المخزن
// =============================================================
// المبدأ الذهبي في Raft: "Replicated State Machine" (آلة حالة منسوخة).
// لا نخزّن "الحالة النهائية" مباشرة، بل نطبّق سجلّاً (Log) من الأوامر
// المرتّبة بنفس الترتيب على كل العُقَد → فتصل كلها لنفس النتيجة بالضبط.
//
// "التطبيق" (apply) يعني تنفيذ الأمر فعلياً على المخزن kv، ولا يحدث
// إلا للمدخلات "المثبّتة" (Committed) — أي التي نُسخت لأغلبية العُقَد.

/**
 * يطبّق كل المدخلات المثبّتة التي لم تُطبَّق بعد (من lastApplied+1 إلى commitIndex).
 */
function applyCommitted(node) {
  while (node.lastApplied < node.commitIndex) {
    node.lastApplied += 1;
    const entry = node.log[node.lastApplied];
    if (!entry) break;
    if (entry.op === 'SET') {
      node.kv[entry.key] = entry.value;
    } else if (entry.op === 'DEL') {
      delete node.kv[entry.key];
    } else if (entry.op === 'LOCK_ACQUIRE') {
      // منح القفل: نسجّل المالك + رمز الحماية (Fencing Token) + مهلة الانتهاء (TTL).
      node.locks[entry.key] = {
        owner: entry.owner,
        token: entry.token,
        expiresAt: entry.expiresAt,
      };
    } else if (entry.op === 'LOCK_RELEASE') {
      // لا نحذف القفل، بل نحرّره مع الاحتفاظ برمز الحماية (Fencing Token)
      // ليبقى متزايداً في المرّة القادمة (لا يعود للرقم 1 أبداً).
      const existing = node.locks[entry.key];
      node.locks[entry.key] = {
        owner: null,
        token: existing?.token ?? 0,
        expiresAt: 0,
      };
    }
    console.log(
      `[${node.id}] ✅ طُبّقت المدخلة #${node.lastApplied}: ${entry.op} ${entry.key}` +
        (entry.op === 'SET' ? `=${entry.value}` : ''),
    );
  }
}

module.exports = { applyCommitted };
