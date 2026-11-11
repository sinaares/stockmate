const express = require('express');
const db = require('../db');
const { authenticate } = require('../middleware/auth');
const router = express.Router();

router.get('/', authenticate, async (req, res) => {
  try {
    const rows = await db.prepare('SELECT * FROM categories ORDER BY name_tr').all();
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
