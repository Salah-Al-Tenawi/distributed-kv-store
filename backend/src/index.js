// =============================================================
// index.js — نقطة الدخول: تشغيل عقدة واحدة (CLI)
// =============================================================
// نشغّل العقدة هكذا:  node src/index.js node-1
// إن لم نمرّر معرّفاً، تعمل node-1 افتراضياً.
//
// كل عقدة تُشغَّل في عملية (process) منفصلة — كأنها جهاز مستقل.
// scripts/start-cluster.js يشغّل الخمسة (كلٌّ في عمليته) للتطوير المحلّي.

const { CLUSTER } = require('./config');
const { startNode } = require('./startNode');

const nodeId = process.argv[2] || 'node-1';
const nodeConfig = CLUSTER.find((n) => n.id === nodeId);
if (!nodeConfig) {
  console.error(`خطأ: لا توجد عقدة بالمعرّف "${nodeId}" في config.js`);
  console.error(`العُقَد المتاحة: ${CLUSTER.map((n) => n.id).join(', ')}`);
  process.exit(1);
}

startNode(nodeConfig);
