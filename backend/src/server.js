const http = require('http');
const path = require('path');
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const config = require('./config');
const { router: authRouter } = require('./auth');
const apiRouter = require('./api');
const { initRealtime } = require('./realtime');

const app = express();
const server = http.createServer(app);
initRealtime(server);
app.set('trust proxy', 1);
app.use(helmet({ crossOriginResourcePolicy: { policy: 'cross-origin' } }));
app.use(cors());
app.use(express.json({ limit: '100kb' }));
app.use(morgan('dev'));

app.use('/art', express.static(path.join(__dirname, '..', 'public', 'art'), { maxAge: '7d' }));
app.get('/health', (_req, res) => res.json({ ok: true, db: mongoose.connection.readyState === 1 }));
app.use('/api/auth', authRouter);
app.use('/api', apiRouter);

app.use((_req, res) => res.status(404).json({ error: 'Not found' }));
// eslint-disable-next-line no-unused-vars
app.use((err, _req, res, _next) => {
  if (err.type === 'entity.parse.failed') return res.status(400).json({ error: 'Malformed JSON' });
  const status = err.status || 500;
  if (status >= 500) console.error(err);
  res.status(status).json({ error: status >= 500 ? 'Something went wrong' : err.message });
});

server.listen(config.port, '0.0.0.0', () => console.log(`Solis API & Realtime listening on :${config.port}`));

mongoose.set('bufferCommands', false);

function connectMongo() {
  mongoose
    .connect(config.mongoUri, { serverSelectionTimeoutMS: 5000 })
    .then(() => {
      console.log('MongoDB Atlas connected');
    })
    .catch((e) => {
      console.warn('MongoDB connection notice:', e.message);
      // Retry in 15 seconds
      setTimeout(connectMongo, 15000);
    });
}
connectMongo();
