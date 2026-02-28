const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const { createServer } = require('y-websocket');
const path = require('path');

const app = express();
const server = http.createServer(app);

// --------------------------
// 1. Socket.io：在线人数统计
// --------------------------
const io = new Server(server, {
  cors: { origin: '*', methods: ['GET', 'POST'], credentials: true },
  perMessageDeflate: { threshold: 1024, zlibDeflateOptions: { level: 6 } },
  pingInterval: 10000,
  pingTimeout: 5000
});

let onlineUsers = 0;
io.on('connection', (socket) => {
  onlineUsers++;
  io.emit('onlineUsers', onlineUsers);
  socket.on('disconnect', () => {
    onlineUsers--;
    io.emit('onlineUsers', onlineUsers);
  });
});

// --------------------------
// 2. Yjs WebSocket：文档 CRDT 同步
// --------------------------
const yServer = createServer(server, {
  cors: { origin: '*' },
  gc: true // 启用垃圾回收，优化内存
});

// --------------------------
// 3. 生产环境：托管前端构建产物
// --------------------------
if (process.env.NODE_ENV === 'production') {
  app.use(express.static(path.join(__dirname, '../dist')));
  app.get('*', (req, res) => res.sendFile(path.join(__dirname, '../dist', 'index.html')));
}

// --------------------------
// 4. 启动服务
// --------------------------
const PORT = 8081;
const HOST = '0.0.0.0';
server.listen(PORT, HOST, () => {
  console.log(`Server running at http://${HOST}:${PORT}`);
  console.log(`Yjs CRDT 同步服务已启动`);
  console.log(`Socket.io 在线人数服务已启动`);
});
