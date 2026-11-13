const { WebSocketServer, WebSocket } = require('ws');

let wss = null;
const viewers = new Map(); // auctionId -> Set of client sockets

function initRealtime(server) {
  wss = new WebSocketServer({ server });

  wss.on('connection', (ws) => {
    let currentAuction = null;

    ws.on('message', (msg) => {
      try {
        const data = JSON.parse(msg.toString());
        if (data.type === 'subscribe_auction') {
          if (currentAuction && viewers.has(currentAuction)) {
            viewers.get(currentAuction).delete(ws);
          }
          currentAuction = data.auctionId;
          if (!viewers.has(currentAuction)) viewers.set(currentAuction, new Set());
          viewers.get(currentAuction).add(ws);

          // Reply with live viewer count
          const count = viewers.get(currentAuction).size + 3; // base 3 collectors
          broadcastToAuction(currentAuction, {
            type: 'viewers',
            auctionId: currentAuction,
            count,
          });
        }
      } catch (_) {}
    });

    ws.on('close', () => {
      if (currentAuction && viewers.has(currentAuction)) {
        viewers.get(currentAuction).delete(ws);
        const count = viewers.get(currentAuction).size + 3;
        broadcastToAuction(currentAuction, {
          type: 'viewers',
          auctionId: currentAuction,
          count,
        });
      }
    });

    // Send connection welcome
    ws.send(JSON.stringify({ type: 'connected', time: new Date().toISOString() }));
  });

  return wss;
}

function broadcast(event) {
  if (!wss) return;
  const msg = JSON.stringify(event);
  wss.clients.forEach((client) => {
    if (client.readyState === WebSocket.OPEN) {
      client.send(msg);
    }
  });
}

function broadcastToAuction(auctionId, event) {
  const set = viewers.get(auctionId);
  if (!set) return;
  const msg = JSON.stringify(event);
  set.forEach((client) => {
    if (client.readyState === WebSocket.OPEN) {
      client.send(msg);
    }
  });
}

module.exports = { initRealtime, broadcast, broadcastToAuction };
