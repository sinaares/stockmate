require('dotenv').config();
const express = require('express');
const cors = require('cors');
const db = require('./src/db');
const app = express();

app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));
app.options(/.*/, cors()); // handle preflight for all routes
app.use(express.json());

// Request logger for easy debugging
app.use((req, res, next) => {
  const start = Date.now();
  res.on('finish', () => {
    console.log(`${new Date().toISOString()} [${req.method}] ${req.url} -> ${res.statusCode} (${Date.now() - start}ms) Auth: ${req.headers['authorization'] ? 'YES' : 'NO'}`);
  });
  next();
});

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

// Root welcome page
app.get('/', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html>
      <head>
        <meta charset="utf-8">
        <title>StockMate API</title>
        <style>
          body { font-family: system-ui, -apple-system, sans-serif; background: #0D0F14; color: #fff; padding: 40px; text-align: center; }
          .card { background: #161B26; max-width: 520px; margin: 40px auto; padding: 36px; border-radius: 16px; border: 1px solid #2A3447; box-shadow: 0 10px 30px rgba(0,0,0,0.5); }
          h1 { color: #22D3EE; margin: 0 0 12px; font-size: 26px; }
          p { color: #94A3B8; font-size: 14px; line-height: 1.6; margin: 8px 0; }
          .badge { display: inline-block; background: rgba(52, 211, 153, 0.15); color: #34D399; padding: 4px 12px; border-radius: 20px; font-size: 12px; font-weight: 600; margin-bottom: 16px; border: 1px solid rgba(52, 211, 153, 0.3); }
          .btn { display: inline-block; background: linear-gradient(135deg, #22D3EE, #818CF8); color: #0D0F14; font-weight: 700; padding: 14px 28px; border-radius: 10px; text-decoration: none; margin-top: 24px; font-size: 15px; }
        </style>
      </head>
      <body>
        <div class="card">
          <h1>StockMate Backend API</h1>
          <div><span class="badge">● PostgreSQL 18 Bağlı & Çalışıyor</span></div>
          <p>Burası arka plan REST API servisidir (Port 3000).</p>
          <p>Kullanıcı arayüzüne (Frontend) erişmek için aşağıdaki butona tıklayın:</p>
          <a class="btn" href="http://localhost:8080">StockMate Arayüzünü Aç (Port 8080) &rarr;</a>
        </div>
      </body>
    </html>
  `);
});

const PORT = process.env.PORT || 3000;

async function start() {
  try {
    await db.initPromise;
    // Listen on 0.0.0.0 (IPv4)
    app.listen(PORT, '0.0.0.0', () => {
      console.log(`StockMate API running on http://0.0.0.0:${PORT} (PostgreSQL connected)`);
      console.log(`Health check: http://localhost:${PORT}/health`);
    });
    // Also listen on ::1 (IPv6) so browsers resolving localhost to IPv6 connect seamlessly
    try {
      app.listen(PORT, '::1', () => {
        console.log(`StockMate API also listening on IPv6 [::1]:${PORT}`);
      });
    } catch (e) {
      // IPv6 not supported or already bound
    }
  } catch (err) {
    console.error('Failed to start server:', err);
    process.exit(1);
  }
}

start();
