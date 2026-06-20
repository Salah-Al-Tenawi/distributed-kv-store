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

    // الحالة الأساسية:
    this.state = NodeState.FOLLOWER; // كل عقدة تبدأ كتابع
    this.term = 0;                   // الدورة (Term) — عدّاد منطقي للانتخابات
    this.leaderId = null;            // من هو القائد الحالي (لا نعرف بعد)

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
      online: true, // في Phase 0 العقدة دائماً حيّة (نضيف "القتل" لاحقاً)
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
