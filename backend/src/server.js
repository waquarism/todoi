require('dotenv').config();

const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const morgan = require('morgan');

const { initDb } = require('./db/database');
const todoRoutes = require('./routes/todo.routes');

const app = express();

const PORT = process.env.PORT || 3000;
const NODE_ENV = process.env.NODE_ENV || 'development';
const allowedOrigins = (process.env.ALLOWED_ORIGINS || '')
  .split(',')
  .map((o) => o.trim())
  .filter(Boolean);

app.use(helmet());
app.use(
  cors({
    origin: allowedOrigins.length ? allowedOrigins : true,
    methods: ['GET', 'POST', 'PATCH', 'DELETE', 'OPTIONS'],
  })
);
app.use(express.json({ limit: '1mb' }));
app.use(morgan(NODE_ENV === 'production' ? 'combined' : 'dev'));

app.get('/health', (req, res) => {
  res.json({ status: 'ok', time: new Date().toISOString() });
});

app.use('/api/todos', todoRoutes);

app.use((req, res) => {
  res.status(404).json({ success: false, message: 'Route not found' });
});

app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).json({ success: false, message: 'Internal server error' });
});

initDb();

app.listen(PORT, () => {
  const baseUrl = `http://localhost:${PORT}`;
  console.log(`Todo API running on ${baseUrl} (${NODE_ENV})`);
  console.log('Endpoints:');
  console.log(`  GET    ${baseUrl}/health`);
  console.log(`  GET    ${baseUrl}/api/todos`);
  console.log(`  GET    ${baseUrl}/api/todos/stats`);
  console.log(`  GET    ${baseUrl}/api/todos/:id`);
  console.log(`  POST   ${baseUrl}/api/todos`);
  console.log(`  PATCH  ${baseUrl}/api/todos/:id`);
  console.log(`  DELETE ${baseUrl}/api/todos/:id`);
  console.log(`  POST   ${baseUrl}/api/todos/bulk/complete`);
  console.log(`  POST   ${baseUrl}/api/todos/bulk/delete`);
});
