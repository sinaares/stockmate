const express = require('express');
const bcrypt = require('bcryptjs');
const db = require('../db');
const { authenticate, requireBoss } = require('../middleware/auth');
const router = express.Router();

// GET /employees
router.get('/', authenticate, requireBoss, (req, res) => {
  const rows = db.prepare("SELECT id, name, email, role, active, created_at FROM users WHERE role='employee' ORDER BY name").all();
  res.json(rows);
});

// POST /employees — boss creates employee
router.post('/', authenticate, requireBoss, (req, res) => {
  const { name, email, password } = req.body;
  if (!name || !email || !password) return res.status(400).json({ error: 'name, email, password required' });
  const hash = bcrypt.hashSync(password, 10);
  try {
    const result = db.prepare("INSERT INTO users (name, email, password, role) VALUES (?, ?, ?, 'employee')").run(name, email, hash);
    res.status(201).json({ id: result.lastInsertRowid, name, email, role: 'employee' });
  } catch (e) {
    if (e.message.includes('UNIQUE')) return res.status(409).json({ error: 'Email already exists' });
    res.status(500).json({ error: e.message });
  }
});

// PUT /employees/:id/toggle — activate/deactivate
router.put('/:id/toggle', authenticate, requireBoss, (req, res) => {
  const user = db.prepare('SELECT * FROM users WHERE id = ? AND role = ?').get(req.params.id, 'employee');
  if (!user) return res.status(404).json({ error: 'Employee not found' });
  db.prepare('UPDATE users SET active = ? WHERE id = ?').run(user.active ? 0 : 1, req.params.id);
  res.json({ active: !user.active });
});

// DELETE /employees/:id
router.delete('/:id', authenticate, requireBoss, (req, res) => {
  db.prepare("DELETE FROM users WHERE id = ? AND role = 'employee'").run(req.params.id);
  res.json({ success: true });
});

module.exports = router;
