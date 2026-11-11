const express = require('express');
const db = require('../db');
const { authenticate, requireBoss } = require('../middleware/auth');
const router = express.Router();

// GET /transactions
router.get('/', authenticate, async (req, res) => {
  try {
    const { product_id, action_type, limit = 100 } = req.query;
    let sql = `
      SELECT t.*, p.name as product_name, u.name as user_name, u.role as user_role
      FROM transactions t
      JOIN products p ON t.product_id = p.id
      JOIN users u ON t.user_id = u.id
      WHERE 1=1
    `;
    const params = [];
    if (req.user.role === 'employee') {
      sql += ' AND t.user_id = ?';
      params.push(req.user.id);
    }
    if (product_id) {
      sql += ' AND t.product_id = ?';
      params.push(parseInt(product_id));
    }
    if (action_type) {
      sql += ' AND t.action_type = ?';
      params.push(action_type);
    }
    sql += ' ORDER BY t.created_at DESC LIMIT ?';
    params.push(parseInt(limit));
    const rows = await db.prepare(sql).all(...params);
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /transactions/stats — dashboard stats for boss
router.get('/stats', authenticate, requireBoss, async (req, res) => {
  try {
    const totalProductsRow = await db.prepare('SELECT COUNT(*) as c FROM products').get();
    const totalProducts = totalProductsRow ? totalProductsRow.c : 0;

    const totalStockRow = await db.prepare('SELECT SUM(quantity) as s FROM products').get();
    const totalStock = totalStockRow && totalStockRow.s !== null ? totalStockRow.s : 0;

    const lowStockRow = await db.prepare('SELECT COUNT(*) as c FROM products WHERE quantity <= min_stock').get();
    const lowStock = lowStockRow ? lowStockRow.c : 0;

    const pendingRequestsRow = await db.prepare("SELECT COUNT(*) as c FROM requests WHERE status='pending'").get();
    const pendingRequests = pendingRequestsRow ? pendingRequestsRow.c : 0;

    const totalSoldRow = await db.prepare("SELECT COALESCE(SUM(quantity),0) as s FROM transactions WHERE action_type='sell'").get();
    const totalSold = totalSoldRow && totalSoldRow.s !== null ? totalSoldRow.s : 0;

    const recentActivity = await db.prepare(`
      SELECT t.action_type, t.quantity, t.created_at, p.name as product_name, u.name as user_name
      FROM transactions t
      JOIN products p ON t.product_id = p.id
      JOIN users u ON t.user_id = u.id
      ORDER BY t.created_at DESC LIMIT 10
    `).all();

    const categoryStats = await db.prepare(`
      SELECT c.name_tr, c.name_en, COUNT(p.id) as count, COALESCE(SUM(p.quantity),0) as total_qty
      FROM categories c
      LEFT JOIN products p ON p.category_id = c.id
      GROUP BY c.id, c.name_tr, c.name_en
      ORDER BY total_qty DESC
    `).all();

    const dailyTransactions = await db.prepare(`
      SELECT TO_CHAR(created_at, 'YYYY-MM-DD') as day, action_type, SUM(quantity) as total
      FROM transactions
      WHERE created_at >= NOW() - INTERVAL '30 days'
      GROUP BY TO_CHAR(created_at, 'YYYY-MM-DD'), action_type
      ORDER BY day ASC
    `).all();

    res.json({
      totalProducts,
      totalStock,
      lowStock,
      pendingRequests,
      totalSold,
      recentActivity,
      categoryStats,
      dailyTransactions,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
