// =============================================================
// dashboard.js — طبقة النقل (Transport) بين العقدة ولوحة Flutter
// =============================================================
// كل عقدة تشغّل:
//   1) سيرفر HTTP (express) — لفحص الصحة الآن، ولأوامر PUT/GET لاحقاً.
//   2) سيرفر WebSocket (ws) على نفس المنفذ — لبثّ حالة العقدة لحظياً.
//
// لماذا WebSocket؟ لأن HTTP عادي "طلب/رد" فقط، بينما WebSocket يبقي
// قناة مفتوحة في الاتجاهين، فتستطيع العقدة "دفع" التحديثات لـ Flutter
// فور حدوثها (مثلاً: تغيّر القائد) دون أن يسأل Flutter كل مرة.

const express = require('express');
const http = require('http');
const { WebSocketServer } = require('ws');

/**
 * يبني ويشغّل سيرفر HTTP + WebSocket لعقدة معيّنة.
 * @param {import('../node/Node').Node} node العقدة
 */
function startDashboardServer(node) {
  const app = express();
  app.use(express.json()); // ليفهم السيرفر أجسام الطلبات بصيغة JSON

  // --- نقطة فحص الصحة: نزورها بالمتصفح للتأكد أن العقدة تعمل ---
  app.get('/health', (req, res) => {
    res.json(node.getSnapshot());
  });

  // ننشئ سيرفر HTTP يدوياً حتى نربط عليه WebSocket على نفس المنفذ.
  const server = http.createServer(app);
  const wss = new WebSocketServer({ server });

  // نحتفظ بكل العملاء المتصلين (لوحات Flutter) لنبثّ لهم.
  const clients = new Set();

  wss.on('connection', (socket) => {
    clients.add(socket);
    console.log(`[${node.id}] لوحة جديدة اتصلت (المجموع: ${clients.size})`);

    // أول ما يتصل عميل، نرسل له الحالة الحالية فوراً.
    socket.send(JSON.stringify({ type: 'state', data: node.getSnapshot() }));

    socket.on('close', () => {
      clients.delete(socket);
      console.log(`[${node.id}] لوحة قطعت الاتصال (المجموع: ${clients.size})`);
    });
  });

  // نربط دالة التغيير في العقدة بالبثّ: أي تغيّر -> يصل لكل اللوحات.
  node.onStateChange = (snapshot) => {
    const message = JSON.stringify({ type: 'state', data: snapshot });
    for (const client of clients) {
      if (client.readyState === client.OPEN) {
        client.send(message);
      }
    }
  };

  server.listen(node.port, () => {
    console.log(`[${node.id}] يعمل على المنفذ ${node.port}`);
    console.log(`         HTTP:  http://localhost:${node.port}/health`);
    console.log(`         WS:    ws://localhost:${node.port}`);
  });

  return { app, server, wss };
}

module.exports = { startDashboardServer };
