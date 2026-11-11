const express = require('express');
const db = require('../db');
const { authenticate, requireBoss } = require('../middleware/auth');
const router = express.Router();

// GET /requests — pending list (boss sees all, employee sees own)
router.get('/', authenticate, async (req, res) => {
  try {
    const { status } = req.query;
    let sql = `
      SELECT r.*, p.name as product_name, p.unit,
             u.name as employee_name, u.email as employee_email,
             b.name as resolved_by_name
      FROM requests r
      JOIN products p ON r.product_id = p.id
      JOIN users u ON r.employee_id = u.id
      LEFT JOIN users b ON r.resolved_by = b.id
      WHERE 1=1
    `;
    const params = [];
    if (req.user.role === 'employee') {
      sql += ' AND r.employee_id = ?';
      params.push(req.user.id);
    }
    if (status) {
      sql += ' AND r.status = ?';
      params.push(status);
    }
    sql += ' ORDER BY r.created_at DESC';
    const rows = await db.prepare(sql).all(...params);
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /requests/count/pending — badge count for boss
router.get('/count/pending', authenticate, requireBoss, async (req, res) => {
  try {
    const row = await db.prepare("SELECT COUNT(*) as count FROM requests WHERE status='pending'").get();
    res.json({ count: row ? row.count : 0 });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /requests — employee submits action request
router.post('/', authenticate, async (req, res) => {
  try {
    const { product_id, action_type, quantity, note } = req.body;
    if (!product_id || !action_type || !quantity) return res.status(400).json({ error: 'product_id, action_type, quantity required' });
    const validActions = ['add','remove','sell','use','restock'];
    if (!validActions.includes(action_type)) return res.status(400).json({ error: 'Invalid action_type' });

    const product = await db.prepare('SELECT * FROM products WHERE id = ?').get(product_id);
    if (!product) return res.status(404).json({ error: 'Product not found' });

    // Boss can directly execute without approval
    if (req.user.role === 'boss') {
      return await executeAction(req, res, product, action_type, quantity, note, null);
    }

    const result = await db.prepare(`
      INSERT INTO requests (employee_id, product_id, action_type, quantity, note)
      VALUES (?, ?, ?, ?, ?)
    `).run(req.user.id, product_id, action_type, quantity, note || null);

    const request = await db.prepare('SELECT * FROM requests WHERE id = ?').get(result.lastInsertRowid);
    res.status(201).json({ message: 'Request submitted, waiting for boss approval', request });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// PUT /requests/:id/approve — boss approves
router.put('/:id/approve', authenticate, requireBoss, async (req, res) => {
  try {
    const request = await db.prepare("SELECT * FROM requests WHERE id = ? AND status = 'pending'").get(req.params.id);
    if (!request) return res.status(404).json({ error: 'Pending request not found' });

    const product = await db.prepare('SELECT * FROM products WHERE id = ?').get(request.product_id);
    if (!product) return res.status(404).json({ error: 'Product not found' });

    await db.prepare("UPDATE requests SET status='approved', resolved_by=?, resolved_at=NOW() WHERE id=?")
      .run(req.user.id, request.id);

    return await executeAction(req, res, product, request.action_type, request.quantity, request.note, request.id);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// PUT /requests/:id/reject — boss rejects
router.put('/:id/reject', authenticate, requireBoss, async (req, res) => {
  try {
    const { reason } = req.body;
    const request = await db.prepare("SELECT * FROM requests WHERE id = ? AND status = 'pending'").get(req.params.id);
    if (!request) return res.status(404).json({ error: 'Pending request not found' });
    await db.prepare("UPDATE requests SET status='rejected', reject_reason=?, resolved_by=?, resolved_at=NOW() WHERE id=?")
      .run(reason || null, req.user.id, request.id);
    res.json({ message: 'Request rejected', request_id: request.id });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

async function executeAction(req, res, product, action_type, quantity, note, request_id) {
  const qty = parseInt(quantity, 10);
  const before = product.quantity;
  let after = before;

  if (['remove','sell','use'].includes(action_type)) {
    if (before < qty) return res.status(400).json({ error: 'Insufficient stock' });
    after = before - qty;
  } else if (['add','restock'].includes(action_type)) {
    after = before + qty;
  }

  await db.transaction(async (trx) => {
    await trx.prepare("UPDATE products SET quantity=?, updated_at=NOW() WHERE id=?").run(after, product.id);
    await trx.prepare(`
      INSERT INTO transactions (product_id, user_id, action_type, quantity, quantity_before, quantity_after, note, request_id)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    `).run(product.id, req.user.id, action_type, qty, before, after, note || null, request_id || null);
  });

  res.json({ success: true, product_id: product.id, action_type, quantity: qty, stock_before: before, stock_after: after });
}

module.exports = router;
