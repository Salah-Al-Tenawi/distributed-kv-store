// =============================================================
// start-cluster.js — يشغّل كل عُقَد العنقود دفعة واحدة
// =============================================================
// بدل فتح 5 نوافذ طرفية، هذا السكربت يشغّل كل عقدة في عملية فرعية
// (child process) منفصلة، ويجمع مخرجاتها في طرفية واحدة.
//
// التشغيل:  npm run cluster   (أو: node scripts/start-cluster.js)
// الإيقاف:  Ctrl + C  (يوقف كل العُقَد معاً)

const { spawn } = require('child_process');
const path = require('path');
const { CLUSTER } = require('../src/config');

const indexPath = path.join(__dirname, '..', 'src', 'index.js');
const children = [];

for (const node of CLUSTER) {
  const child = spawn('node', [indexPath, node.id], {
    stdio: 'inherit', // تظهر مخرجات كل عقدة في نفس الطرفية
  });
  children.push(child);
}

console.log(`\n🚀 تم تشغيل ${CLUSTER.length} عُقَد. اضغط Ctrl+C للإيقاف.\n`);

// عند الضغط على Ctrl+C، نوقف كل العُقَد قبل الخروج.
process.on('SIGINT', () => {
  console.log('\n⏹️  جارٍ إيقاف العنقود...');
  for (const child of children) {
    child.kill('SIGINT');
  }
  process.exit(0);
});
