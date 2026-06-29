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

console.log(`\nStarted ${CLUSTER.length} nodes. Press Ctrl+C to stop.\n`);

process.on('SIGINT', () => {
  console.log('\nStopping the cluster...');
  for (const child of children) {
    child.kill('SIGINT');
  }
  process.exit(0);
});
