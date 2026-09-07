const express = require('express');
const db = require('../db');
const { authenticate } = require('../middleware/auth');
const router = express.Router();

router.get('/', authenticate, (req, res) => {
  res.json(db.prepare('SELECT * FROM categories ORDER BY name_tr').all());
});

module.exports = router;
