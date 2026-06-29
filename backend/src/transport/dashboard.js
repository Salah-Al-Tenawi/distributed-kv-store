const express = require('express');
const http = require('http');
const { WebSocketServer } = require('ws');

function startDashboardServer(node) {
  const app = express();

  app.use((req, res, next) => {
    res.header('Access-Control-Allow-Origin', '*');
    res.header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.header('Access-Control-Allow-Headers', 'Content-Type');
    if (req.method === 'OPTIONS') return res.sendStatus(204);
    next();
  });

  app.use(express.json());

  app.get('/health', (req, res) => {
    res.json(node.getSnapshot());
  });

  const server = http.createServer(app);
  const wss = new WebSocketServer({ server });

  const clients = new Set();

  wss.on('connection', (socket) => {
    clients.add(socket);
    console.log(`[${node.id}] dashboard connected (total: ${clients.size})`);

    socket.send(JSON.stringify({ type: 'state', data: node.getSnapshot() }));

    socket.on('close', () => {
      clients.delete(socket);
      console.log(`[${node.id}] dashboard disconnected (total: ${clients.size})`);
    });
  });

  node.onStateChange = (snapshot) => {
    const message = JSON.stringify({ type: 'state', data: snapshot });
    for (const client of clients) {
      if (client.readyState === client.OPEN) {
        client.send(message);
      }
    }
  };

  server.listen(node.port, () => {
    console.log(`[${node.id}] listening on port ${node.port}`);
    console.log(`         HTTP:  http://localhost:${node.port}/health`);
    console.log(`         WS:    ws://localhost:${node.port}`);
  });

  return { app, server, wss };
}

module.exports = { startDashboardServer };
