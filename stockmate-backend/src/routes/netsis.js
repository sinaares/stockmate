const express = require('express');
const netsisService = require('../services/netsisService');
const { authenticate, requireBoss } = require('../middleware/auth');
const router = express.Router();

// GET /netsis/settings — Ayarları getir
router.get('/settings', authenticate, requireBoss, async (req, res) => {
  try {
    const settings = await netsisService.getSettings();
    res.json(settings);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /netsis/settings — Ayarları kaydet
router.post('/settings', authenticate, requireBoss, async (req, res) => {
  try {
    const updated = await netsisService.updateSettings(req.body);
    res.json({ success: true, message: 'Netsis ERP ayarları güncellendi.', settings: updated });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /netsis/test — Bağlantıyı test et
router.get('/test', authenticate, requireBoss, async (req, res) => {
  try {
    const result = await netsisService.testConnection();
    res.json(result);
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// POST /netsis/sync — Netsis'ten stokları senkronize et
router.post('/sync', authenticate, requireBoss, async (req, res) => {
  try {
    const result = await netsisService.syncProducts();
    res.json(result);
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// GET /netsis/logs — Entegrasyon işlem loglarını getir
router.get('/logs', authenticate, requireBoss, async (req, res) => {
  try {
    const limit = parseInt(req.query.limit, 10) || 20;
    const logs = await netsisService.getLogs(limit);
    res.json(logs);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /netsis/manual-slip — Belirli bir talep için fiş oluştur
router.post('/manual-slip', authenticate, requireBoss, async (req, res) => {
  try {
    const { requestId, productId, actionType, quantity, employeeName, note } = req.body;
    const result = await netsisService.createStockSlip({
      requestId,
      productId,
      actionType,
      quantity,
      employeeName: employeeName || 'Sistem Yöneticisi',
      note,
    });
    res.json(result);
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

module.exports = router;
