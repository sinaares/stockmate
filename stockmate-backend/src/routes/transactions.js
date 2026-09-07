const express = require('express');
const db = require('../db');
const { authenticate, requireBoss } = require('../middleware/auth');
const router = express.Router();

// GET /transactions
router.get('/', authenticate, (req, res) => {
  const { product_id, action_type, limit = 100 } = req.query;
  let sql = `
    SELECT t.*, p.name as product_name, u.name as user_name, u.role as user_role
    FROM transactions t
    JOIN products p ON t.product_id = p.id
    JOIN users u ON t.user_id = u.id
    WHERE 1=1
  `;
  const params = [];
  if (req.user.role === 'employee') { sql += ' AND t.user_id = ?'; params.push(req.user.id); }
  if (product_id) { sql += ' AND t.product_id = ?'; params.push(product_id); }
  if (action_type) { sql += ' AND t.action_type = ?'; params.push(action_type); }
  sql += ' ORDER BY t.created_at DESC LIMIT ?';
  params.push(parseInt(limit));
  res.json(db.prepare(sql).all(...params));
});

// GET /transactions/stats — dashboard stats for boss
router.get('/stats', authenticate, requireBoss, (req, res) => {
  const totalProducts = db.prepare('SELECT COUNT(*) as c FROM products').get().c;
  const totalStock = db.prepare('SELECT SUM(quantity) as s FROM products').get().s || 0;
  const lowStock = db.prepare('SELECT COUNT(*) as c FROM products WHERE quantity <= min_stock').get().c;
  const pendingRequests = db.prepare("SELECT COUNT(*) as c FROM requests WHERE status='pending'").get().c;
  const totalSold = db.prepare("SELECT COALESCE(SUM(quantity),0) as s FROM transactions WHERE action_type='sell'").get().s;
  const recentActivity = db.prepare(`
    SELECT t.action_type, t.quantity, t.created_at, p.name as product_name, u.name as user_name
    FROM transactions t JOIN products p ON t.product_id=p.id JOIN users u ON t.user_id=u.id
    ORDER BY t.created_at DESC LIMIT 10
  `).all();
  const categoryStats = db.prepare(`
    SELECT c.name_tr, c.name_en, COUNT(p.id) as count, COALESCE(SUM(p.quantity),0) as total_qty
    FROM categories c LEFT JOIN products p ON p.category_id = c.id
    GROUP BY c.id ORDER BY total_qty DESC
  `).all();
  const dailyTransactions = db.prepare(`
    SELECT date(created_at) as day, action_type, SUM(quantity) as total
    FROM transactions
    WHERE created_at >= date('now','-30 days')
    GROUP BY day, action_type ORDER BY day ASC
  `).all();

  res.json({ totalProducts, totalStock, lowStock, pendingRequests, totalSold, recentActivity, categoryStats, dailyTransactions });
});

module.exports = router;
