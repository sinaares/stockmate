const express = require('express');
const router = express.Router();
const db = require('../db');
const { authenticate } = require('../middleware/auth');

// GET /technical-services — list all (boss) or own (employee technician)
router.get('/', authenticate, async (req, res) => {
  try {
    const { status, device_type, search } = req.query;
    let query = `
      SELECT ts.*,
             u.name AS technician_name
      FROM technical_services ts
      LEFT JOIN users u ON u.id = ts.technician_id
      WHERE 1=1
    `;
    const params = [];

    if (status) {
      query += ' AND ts.status = ?';
      params.push(status);
    }
    if (device_type) {
      query += ' AND ts.device_type = ?';
      params.push(device_type);
    }
    if (search) {
      query += ' AND (ts.customer_name ILIKE ? OR ts.device_brand ILIKE ? OR ts.device_model ILIKE ? OR ts.serial_no ILIKE ?)';
      const s = `%${search}%`;
      params.push(s, s, s, s);
    }

    query += ' ORDER BY ts.created_at DESC';
    const rows = await db.prepare(query).all(...params);
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /technical-services/stats — counts by status
router.get('/stats', authenticate, async (req, res) => {
  try {
    const stats = await db.prepare(`
      SELECT status, COUNT(*) as count FROM technical_services GROUP BY status
    `).all();
    const totalRow = await db.prepare('SELECT COUNT(*) as c FROM technical_services').get();
    res.json({ total: totalRow ? totalRow.c : 0, byStatus: stats });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /technical-services/:id
router.get('/:id', authenticate, async (req, res) => {
  try {
    const row = await db.prepare(`
      SELECT ts.*, u.name AS technician_name
      FROM technical_services ts
      LEFT JOIN users u ON u.id = ts.technician_id
      WHERE ts.id = ?
    `).get(req.params.id);
    if (!row) return res.status(404).json({ error: 'Not found' });
    res.json(row);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /technical-services — create new service record
router.post('/', authenticate, async (req, res) => {
  try {
    const {
      customer_name, customer_phone, device_type, device_brand,
      device_model, serial_no, fault_description, parts_to_replace,
      technician_id, status, note, price
    } = req.body;

    if (!customer_name || !device_type || !device_brand || !fault_description) {
      return res.status(400).json({ error: 'customer_name, device_type, device_brand, fault_description are required' });
    }

    const result = await db.prepare(`
      INSERT INTO technical_services
        (customer_name, customer_phone, device_type, device_brand, device_model, serial_no,
         fault_description, parts_to_replace, technician_id, status, note, price)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `).run(
      customer_name,
      customer_phone || null,
      device_type,
      device_brand,
      device_model || null,
      serial_no || null,
      fault_description,
      parts_to_replace || null,
      technician_id || null,
      status || 'waiting',
      note || null,
      price || 0
    );

    const created = await db.prepare('SELECT * FROM technical_services WHERE id = ?').get(result.lastInsertRowid);
    res.status(201).json(created);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// PUT /technical-services/:id — full update
router.put('/:id', authenticate, async (req, res) => {
  try {
    const {
      customer_name, customer_phone, device_type, device_brand,
      device_model, serial_no, fault_description, parts_to_replace,
      technician_id, status, note, price
    } = req.body;

    const existing = await db.prepare('SELECT id FROM technical_services WHERE id = ?').get(req.params.id);
    if (!existing) return res.status(404).json({ error: 'Not found' });

    await db.prepare(`
      UPDATE technical_services SET
        customer_name = ?, customer_phone = ?, device_type = ?, device_brand = ?,
        device_model = ?, serial_no = ?, fault_description = ?, parts_to_replace = ?,
        technician_id = ?, status = ?, note = ?, price = ?,
        updated_at = NOW()
      WHERE id = ?
    `).run(
      customer_name, customer_phone || null, device_type, device_brand,
      device_model || null, serial_no || null, fault_description,
      parts_to_replace || null, technician_id || null, status, note || null,
      price || 0, req.params.id
    );

    const updated = await db.prepare(`
      SELECT ts.*, u.name AS technician_name
      FROM technical_services ts
      LEFT JOIN users u ON u.id = ts.technician_id
      WHERE ts.id = ?
    `).get(req.params.id);
    res.json(updated);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// PATCH /technical-services/:id/status — quick status update
router.patch('/:id/status', authenticate, async (req, res) => {
  try {
    const { status } = req.body;
    const valid = ['waiting', 'in_progress', 'done', 'delivered', 'cancelled'];
    if (!valid.includes(status)) return res.status(400).json({ error: 'Invalid status' });

    const existing = await db.prepare('SELECT id FROM technical_services WHERE id = ?').get(req.params.id);
    if (!existing) return res.status(404).json({ error: 'Not found' });

    await db.prepare('UPDATE technical_services SET status = ?, updated_at = NOW() WHERE id = ?')
      .run(status, req.params.id);

    res.json({ id: req.params.id, status });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// DELETE /technical-services/:id
router.delete('/:id', authenticate, async (req, res) => {
  try {
    const existing = await db.prepare('SELECT id FROM technical_services WHERE id = ?').get(req.params.id);
    if (!existing) return res.status(404).json({ error: 'Not found' });
    await db.prepare('DELETE FROM technical_services WHERE id = ?').run(req.params.id);
    res.json({ message: 'Deleted' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
