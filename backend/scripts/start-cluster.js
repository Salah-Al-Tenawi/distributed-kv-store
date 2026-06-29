const { spawn } = require('child_process');
const path = require('path');
const { CLUSTER } = require('../src/config');

const indexPath = path.join(__dirname, '..', 'src', 'index.js');
const children = [];

for (const node of CLUSTER) {
  const child = spawn('node', [indexPath, node.id], {
    stdio: 'inherit',
  });
  children.push(child);
}

console.log(`\n🚀 تم تشغيل ${CLUSTER.length} عُقَد. اضغط Ctrl+C للإيقاف.\n`);

process.on('SIGINT', () => {
  console.log('\n⏹️  جارٍ إيقاف العنقود...');
  for (const child of children) {
    child.kill('SIGINT');
  }
  process.exit(0);
});
