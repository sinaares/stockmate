const express = require('express');
const db = require('../db');
const { authenticate, requireBoss } = require('../middleware/auth');
const router = express.Router();

// GET /products — list all products
router.get('/', authenticate, (req, res) => {
  const { search, category_id, low_stock } = req.query;
  let sql = `
    SELECT p.*, c.name_tr as category_tr, c.name_en as category_en
    FROM products p
    LEFT JOIN categories c ON p.category_id = c.id
    WHERE 1=1
  `;
  const params = [];
  if (search) { sql += ' AND (p.name LIKE ? OR p.barcode LIKE ? OR p.serial_key LIKE ?)'; const s = `%${search}%`; params.push(s,s,s); }
  if (category_id) { sql += ' AND p.category_id = ?'; params.push(category_id); }
  if (low_stock === '1') { sql += ' AND p.quantity <= p.min_stock'; }
  sql += ' ORDER BY p.name ASC';
  const rows = db.prepare(sql).all(...params);
  res.json(rows);
});

// GET /products/barcode/:code — lookup by barcode or serial
router.get('/lookup/:code', authenticate, (req, res) => {
  const code = req.params.code;
  const product = db.prepare(`
    SELECT p.*, c.name_tr as category_tr, c.name_en as category_en
    FROM products p LEFT JOIN categories c ON p.category_id = c.id
    WHERE p.barcode = ? OR p.serial_key = ?
  `).get(code, code);
  if (!product) return res.status(404).json({ error: 'Product not found' });
  res.json(product);
});

// GET /products/:id
router.get('/:id', authenticate, (req, res) => {
  const product = db.prepare(`
    SELECT p.*, c.name_tr as category_tr, c.name_en as category_en
    FROM products p LEFT JOIN categories c ON p.category_id = c.id
    WHERE p.id = ?
  `).get(req.params.id);
  if (!product) return res.status(404).json({ error: 'Not found' });
  res.json(product);
});

// POST /products — boss only
router.post('/', authenticate, requireBoss, (req, res) => {
  const { name, barcode, serial_key, category_id, quantity, unit, price, description, min_stock } = req.body;
  if (!name) return res.status(400).json({ error: 'Product name required' });
  try {
    const result = db.prepare(`
      INSERT INTO products (name, barcode, serial_key, category_id, quantity, unit, price, description, min_stock)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    `).run(name, barcode||null, serial_key||null, category_id||null, quantity||0, unit||'adet', price||0, description||null, min_stock||5);
    const product = db.prepare('SELECT * FROM products WHERE id = ?').get(result.lastInsertRowid);

    // Log transaction
    db.prepare(`INSERT INTO transactions (product_id, user_id, action_type, quantity, quantity_before, quantity_after, note)
      VALUES (?, ?, 'add', ?, 0, ?, 'Initial stock')`)
      .run(product.id, req.user.id, quantity||0, quantity||0);

    res.status(201).json(product);
  } catch (e) {
    if (e.message.includes('UNIQUE')) return res.status(409).json({ error: 'Barcode or serial key already exists' });
    res.status(500).json({ error: e.message });
  }
});

// PUT /products/:id — boss only
router.put('/:id', authenticate, requireBoss, (req, res) => {
  const { name, barcode, serial_key, category_id, unit, price, description, min_stock } = req.body;
  const existing = db.prepare('SELECT * FROM products WHERE id = ?').get(req.params.id);
  if (!existing) return res.status(404).json({ error: 'Not found' });
  try {
    db.prepare(`UPDATE products SET name=?, barcode=?, serial_key=?, category_id=?, unit=?, price=?, description=?, min_stock=?, updated_at=datetime('now') WHERE id=?`)
      .run(name||existing.name, barcode||null, serial_key||null, category_id||existing.category_id, unit||existing.unit, price||existing.price, description||existing.description, min_stock||existing.min_stock, req.params.id);
    res.json(db.prepare('SELECT * FROM products WHERE id = ?').get(req.params.id));
  } catch (e) {
    if (e.message.includes('UNIQUE')) return res.status(409).json({ error: 'Barcode or serial key already exists' });
    res.status(500).json({ error: e.message });
  }
});

// DELETE /products/:id — boss only
router.delete('/:id', authenticate, requireBoss, (req, res) => {
  const existing = db.prepare('SELECT * FROM products WHERE id = ?').get(req.params.id);
  if (!existing) return res.status(404).json({ error: 'Not found' });
  db.prepare('DELETE FROM products WHERE id = ?').run(req.params.id);
  res.json({ success: true });
});

module.exports = router;
