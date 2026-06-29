const express = require('express');
const http = require('http');
const path = require('path');
const fs = require('fs');
const { WebSocketServer, WebSocket } = require('ws');
const { CLUSTER } = require('./config');
const { startNode } = require('./startNode');

const PUBLIC_PORT = process.env.PORT || 8080;
const publicDir = path.join(__dirname, '..', 'public');

for (const node of CLUSTER) {
  startNode(node);
}
console.log(`Gateway started ${CLUSTER.length} nodes in-process.`);

const app = express();
app.use(express.json());

app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Content-Type');
  if (req.method === 'OPTIONS') return res.sendStatus(204);
  next();
});

app.all('/proxy/:port/*', async (req, res) => {
  const target = `http://localhost:${req.params.port}/${req.params[0]}`;
  const opts = { method: req.method, headers: {} };
  if (req.method !== 'GET' && req.method !== 'HEAD') {
    opts.headers['content-type'] = 'application/json';
    opts.body = JSON.stringify(req.body || {});
  }
  try {
    const r = await fetch(target, opts);
    const text = await r.text();
    res.status(r.status).type('application/json').send(text);
  } catch (err) {
    res.status(502).json({ ok: false, error: 'gateway proxy failed' });
  }
});

app.get('/gateway/health', (req, res) => res.json({ ok: true, nodes: CLUSTER.length }));

if (fs.existsSync(publicDir)) {
  app.use(express.static(publicDir));
  app.get('*', (req, res) => res.sendFile(path.join(publicDir, 'index.html')));
} else {
  app.get('/', (req, res) =>
    res.send('Gateway up. Flutter web not built yet (public/ missing).'),
  );
}

const server = http.createServer(app);

const wss = new WebSocketServer({ noServer: true });
server.on('upgrade', (req, socket, head) => {
  const match = req.url.match(/^\/ws\/(\d+)/);
  if (!match) return socket.destroy();
  const port = match[1];
  wss.handleUpgrade(req, socket, head, (browserWs) => {
    const nodeWs = new WebSocket(`ws://localhost:${port}`);
    nodeWs.on('message', (d) => browserWs.readyState === 1 && browserWs.send(d.toString()));
    nodeWs.on('close', () => browserWs.close());
    nodeWs.on('error', () => browserWs.close());
    browserWs.on('message', (d) => nodeWs.readyState === 1 && nodeWs.send(d.toString()));
    browserWs.on('close', () => nodeWs.close());
  });
});

server.listen(PUBLIC_PORT, () => {
  console.log(`Gateway listening on port ${PUBLIC_PORT}`);
  console.log(`   Web UI:  http://localhost:${PUBLIC_PORT}/`);
});

process.on('SIGINT', () => process.exit(0));
process.on('SIGTERM', () => process.exit(0));
