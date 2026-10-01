require('dotenv').config();
const express = require('express');
const cors = require('cors');
const app = express();

app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));
app.options(/.*/, cors()); // handle preflight for all routes
app.use(express.json());

// Routes
app.use('/auth',               require('./src/routes/auth'));
app.use('/products',           require('./src/routes/products'));
app.use('/requests',           require('./src/routes/requests'));
app.use('/transactions',       require('./src/routes/transactions'));
app.use('/employees',          require('./src/routes/employees'));
app.use('/categories',         require('./src/routes/categories'));
app.use('/technical-services', require('./src/routes/technical_services'));

// Health check
app.get('/health', (req, res) => res.json({ status: 'ok', time: new Date().toISOString() }));

const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`StockMate API running on http://0.0.0.0:${PORT}`);
  console.log(`Health check: http://localhost:${PORT}/health`);
});
