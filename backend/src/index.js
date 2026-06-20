// =============================================================
// index.js — نقطة الدخول: تشغيل عقدة واحدة
// =============================================================
// نشغّل العقدة هكذا:  node src/index.js node-1
// إن لم نمرّر معرّفاً، تعمل node-1 افتراضياً.
//
// كل عقدة تُشغَّل في عملية (process) منفصلة — كأنها جهاز مستقل.
// scripts/start-cluster.js (لاحقاً) يشغّل الخمسة دفعة واحدة.

const { CLUSTER } = require('./config');
const { Node } = require('./node/Node');
const { startDashboardServer } = require('./transport/dashboard');

// نقرأ معرّف العقدة من سطر الأوامر (args)، أو نستخدم node-1 افتراضياً.
const nodeId = process.argv[2] || 'node-1';

// نبحث عن إعدادات هذه العقدة في قائمة العنقود.
const nodeConfig = CLUSTER.find((n) => n.id === nodeId);
if (!nodeConfig) {
  console.error(`خطأ: لا توجد عقدة بالمعرّف "${nodeId}" في config.js`);
  console.error(`العُقَد المتاحة: ${CLUSTER.map((n) => n.id).join(', ')}`);
  process.exit(1);
}

// ننشئ العقدة ونشغّل سيرفرها.
const node = new Node(nodeConfig.id, nodeConfig.port);
startDashboardServer(node);

// --- اختبار Phase 0 فقط ---
// نغيّر الحالة بشكل وهمي كل 3 ثوانٍ لنرى البثّ يعمل في Flutter.
// (سنحذف هذا في Phase 1 عندما يصبح التغيّر حقيقياً عبر الانتخاب).
let demoCounter = 0;
setInterval(() => {
  demoCounter++;
  node.term = demoCounter; // نزيد الدورة كمثال
  console.log(`[${node.id}] تحديث تجريبي — term=${node.term}`);
  node.notifyChange();     // يبثّ الحالة الجديدة لكل اللوحات المتصلة
}, 3000);
