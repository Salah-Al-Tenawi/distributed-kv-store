// =============================================================
// Node.js — الكلاس الرئيسي لعقدة واحدة في العنقود
// =============================================================
// هذا الكلاس يحمل "حالة" العقدة. في Phase 0 الحالة بسيطة جداً
// (المعرّف + الدور + الدورة). سنضيف عليها تدريجياً مع كل تاسك:
//   - تاسك 1: منطق الانتخاب
//   - تاسك 2: النبضات وكشف الأعطال
//   - تاسك 3: السجلّ (log) والبيانات (kv store)
//   ... إلخ

const { NodeState } = require('./states');

class Node {
  /**
   * @param {string} id   معرّف العقدة، مثل 'node-1'
   * @param {number} port المنفذ الذي تعمل عليه
   */
  constructor(id, port) {
    this.id = id;
    this.port = port;

    // الحالة الأساسية (Core state):
    this.state = NodeState.FOLLOWER; // كل عقدة تبدأ كتابع (Follower)
    this.term = 0;                   // الدورة (Term) — عدّاد منطقي للانتخابات
    this.leaderId = null;            // من هو القائد الحالي (Leader)؟ لا نعرف بعد

    // حالة الانتخاب (Election state):
    this.votedFor = null;            // لمن صوّتنا في الدورة (Term) الحالية
    this.votesReceived = 0;          // كم صوتاً جمعنا (عندما نكون مرشّحاً Candidate)

    // كشف الأعطال (Failure Detection state):
    this.alive = true;               // هل العقدة حيّة؟ "قتلها" يجعلها false (محاكاة Crash)
    this.suspectedOffline = [];       // قائمة الأقران الذين يشكّ القائد (Leader) بموتهم

    // انقسام الشبكة (Network Partition): أقران لا نتواصل معهم (محاكاة انقطاع).
    this.blockedPeers = new Set();

    // نسخ البيانات (Replication state):
    this.log = [];                   // السجلّ (Log): مصفوفة المدخلات {term, op, key, value}
    this.commitIndex = -1;           // أعلى مؤشّر مدخلة "مثبّتة" (Committed) — نُسخت لأغلبية
    this.lastApplied = -1;           // أعلى مؤشّر مدخلة طُبّقت فعلاً على المخزن (kv)
    this.kv = {};                    // المخزن الفعلي (State Machine): مفتاح → قيمة
    this.matchIndex = {};            // (للقائد) آخر مؤشّر نسخه كل قرين — لحساب الأغلبية

    // الأقفال الموزّعة (Distributed Locks):
    // lockName → { owner, token (Fencing Token), expiresAt (TTL) }
    this.locks = {};

    // دالة تُستدعى عند أي تغيّر في الحالة، لنبثّها للوحة Flutter.
    // يحقنها transport لاحقاً. الافتراضي: لا تفعل شيئاً.
    this.onStateChange = () => {};
  }

  /**
   * يُرجع صورة (snapshot) من حالة العقدة — هذا ما نرسله للوحة Flutter.
   */
  getSnapshot() {
    return {
      id: this.id,
      port: this.port,
      state: this.state,
      term: this.term,
      leaderId: this.leaderId,
      online: this.alive,              // false عند "قتل" العقدة (محاكاة Crash)
      suspectedOffline: this.suspectedOffline, // من يشكّ القائد بموتهم
      kv: this.kv,                     // المخزن المثبّت (Committed key-value)
      logLength: this.log.length,      // عدد المدخلات في السجلّ
      commitIndex: this.commitIndex,   // مؤشّر آخر مدخلة مثبّتة
      blockedPeers: [...this.blockedPeers], // الأقران المحجوبون (عند انقسام الشبكة)
      locks: this.locks,               // الأقفال الموزّعة (owner/token/expiresAt)
      timestamp: Date.now(),
    };
  }

  /**
   * تُستدعى عند أي تغيير داخلي لإعلام المشتركين (Flutter).
   */
  notifyChange() {
    this.onStateChange(this.getSnapshot());
  }
}

module.exports = { Node };
