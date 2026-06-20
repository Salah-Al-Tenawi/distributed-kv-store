// =============================================================
// config.js — إعدادات العنقود (Cluster Configuration)
// =============================================================
// هنا نُعرّف كل العُقَد (Nodes) في النظام: معرّف كل عقدة والمنفذ (port)
// الذي تعمل عليه. كل عقدة تشغّل سيرفر HTTP + WebSocket على منفذها.
// نبدأ بـ 5 عُقَد (رقم فردي مهم لاحقاً لحساب الأغلبية / Majority).

const CLUSTER = [
  { id: 'node-1', port: 4001 },
  { id: 'node-2', port: 4002 },
  { id: 'node-3', port: 4003 },
  { id: 'node-4', port: 4004 },
  { id: 'node-5', port: 4005 },
];

// المهلات الزمنية (بالميلي ثانية / milliseconds).
const TIMING = {
  heartbeatInterval: 100,      // كل كم ms يرسل القائد (Leader) نبضة (Heartbeat)
  electionTimeoutMin: 400,     // أدنى مهلة قبل بدء انتخاب (Election Timeout)
  electionTimeoutMax: 800,     // أقصى مهلة — النافذة الواسعة (400ms) تقلّل تصادم الأصوات (Split Vote)
  failureTimeout: 350,         // إن غاب قرين (peer) عن الرد هذه المدة (~3 نبضات) → يُعدّ ميتاً (OFFLINE)
};

// دالة مساعدة: تُعيد باقي العُقَد (peers) عدا العقدة الحالية.
function getPeers(selfId) {
  return CLUSTER.filter((node) => node.id !== selfId);
}

module.exports = { CLUSTER, TIMING, getPeers };
