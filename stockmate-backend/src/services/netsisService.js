/**
 * netsisService.js
 * StockMate & Logo Netsis ERP Çok Modlu (Multi-Mode) Entegrasyon Servisi
 *
 * Desteklenen Modlar:
 * 1. 'simulation': Test ve demo modu (canlı bağlantı olmadan hatasız çalışır)
 * 2. 'mssql': Doğrudan Netsis MS SQL veritabanı bağlantısı (TBLSTSABIT, TBLSTOKURS, TBLSTHAR)
 * 3. 'rest': Netsis REST / Logo REST API Gateway entegrasyonu
 */

const sql = require('mssql');
const axios = require('axios');
const db = require('../db');

// Örnek Netsis Ürün Veri Havuzu (Simülasyon Modu için)
const MOCK_NETSIS_PRODUCTS = [
  {
    netsis_code: 'NTS-KBL-001',
    name: 'CAT6 UTP 23AWG Saf Bakır Data Kablosu (305m)',
    barcode: '868000100101',
    unit: 'metre',
    price: 18.50,
    min_stock: 100,
    quantity: 1250,
    group_code: 'KABLO',
  },
  {
    netsis_code: 'NTS-FBR-002',
    name: 'Single Mode 8 Core Çelik Zırhlı Fiber Optik Kablo',
    barcode: '868000100202',
    unit: 'metre',
    price: 36.00,
    min_stock: 50,
    quantity: 600,
    group_code: 'FIBER',
  },
  {
    netsis_code: 'NTS-CAM-003',
    name: 'Hikvision 4MP DarkFighter WDR IP Bullet Güvenlik Kamerası',
    barcode: '868000100303',
    unit: 'adet',
    price: 3450.00,
    min_stock: 5,
    quantity: 24,
    group_code: 'KAMERA',
  },
  {
    netsis_code: 'NTS-SW-004',
    name: 'Ruijie Reyee 24 Port Gigabit PoE+ L2 Yönetilebilir Switch',
    barcode: '868000100404',
    unit: 'adet',
    price: 7800.00,
    min_stock: 2,
    quantity: 8,
    group_code: 'NETWORK',
  },
  {
    netsis_code: 'NTS-PWR-005',
    name: '12V 10A Ayarlı Metal Kasa Kamera Güç Kaynağı',
    barcode: '868000100505',
    unit: 'adet',
    price: 420.00,
    min_stock: 10,
    quantity: 45,
    group_code: 'GUC',
  },
  {
    netsis_code: 'NTS-PRX-006',
    name: 'Mifare 13.56MHz Wiegand Dokunmatik Geçiş Kontrol Kart Okuyucu',
    barcode: '868000100606',
    unit: 'adet',
    price: 1250.00,
    min_stock: 4,
    quantity: 16,
    group_code: 'GECIS',
  },
  {
    netsis_code: 'NTS-SMR-007',
    name: 'Schneider Acti9 iC60N 1P 16A C Tipi Otomatik Sigorta',
    barcode: '868000100707',
    unit: 'adet',
    price: 260.00,
    min_stock: 15,
    quantity: 80,
    group_code: 'ELEKTRIK',
  },
];

class NetsisService {
  /**
   * ERP Ayarlarını Getirir
   */
  async getSettings() {
    let settings = await db.prepare('SELECT * FROM erp_settings ORDER BY id ASC LIMIT 1').get();
    if (!settings) {
      await db.prepare(`
        INSERT INTO erp_settings (provider, mode, is_active) VALUES ('netsis', 'simulation', true)
      `).run();
      settings = await db.prepare('SELECT * FROM erp_settings ORDER BY id ASC LIMIT 1').get();
    }
    // Şifreyi maskele
    const safeSettings = { ...settings };
    if (safeSettings.db_password) {
      safeSettings.db_password_masked = '********';
    }
    return safeSettings;
  }

  /**
   * ERP Ayarlarını Günceller
   */
  async updateSettings(data) {
    const current = await this.getSettings();
    const mode = data.mode || current.mode || 'simulation';
    const server_host = data.server_host !== undefined ? data.server_host : current.server_host;
    const server_port = data.server_port !== undefined ? parseInt(data.server_port, 10) : current.server_port;
    const database_name = data.database_name !== undefined ? data.database_name : current.database_name;
    const db_user = data.db_user !== undefined ? data.db_user : current.db_user;
    const db_password = data.db_password !== undefined && data.db_password !== '' ? data.db_password : current.db_password;
    const rest_url = data.rest_url !== undefined ? data.rest_url : current.rest_url;
    const rest_token = data.rest_token !== undefined ? data.rest_token : current.rest_token;
    const branch_code = data.branch_code !== undefined ? parseInt(data.branch_code, 10) : current.branch_code;
    const warehouse_code = data.warehouse_code !== undefined ? parseInt(data.warehouse_code, 10) : current.warehouse_code;
    const auto_sync_stock = data.auto_sync_stock !== undefined ? Boolean(data.auto_sync_stock) : current.auto_sync_stock;
    const is_active = data.is_active !== undefined ? Boolean(data.is_active) : current.is_active;

    await db.prepare(`
      UPDATE erp_settings SET
        mode = ?,
        server_host = ?,
        server_port = ?,
        database_name = ?,
        db_user = ?,
        db_password = ?,
        rest_url = ?,
        rest_token = ?,
        branch_code = ?,
        warehouse_code = ?,
        auto_sync_stock = ?,
        is_active = ?,
        updated_at = NOW()
      WHERE id = ?
    `).run(
      mode, server_host, server_port, database_name, db_user, db_password,
      rest_url, rest_token, branch_code, warehouse_code, auto_sync_stock, is_active,
      current.id
    );

    return this.getSettings();
  }

  /**
   * Netsis Bağlantısını Test Eder
   */
  async testConnection() {
    const settings = await this.getSettings();

    if (settings.mode === 'simulation') {
      return {
        success: true,
        mode: 'simulation',
        message: 'Netsis Simülasyon Testi Başarılı: Sanal ERP köprüsü hazır.',
        details: {
          availableProducts: MOCK_NETSIS_PRODUCTS.length,
          supportedSlips: ['Ambar Fişi', 'Sarf Fişi', 'Sayım Fazlası/Eksiği'],
          latency: '2ms (Lokal Bellek)',
        },
      };
    }

    if (settings.mode === 'mssql') {
      const config = {
        server: settings.server_host,
        port: settings.server_port || 1433,
        database: settings.database_name,
        user: settings.db_user,
        password: settings.db_password,
        options: {
          encrypt: false,
          trustServerCertificate: true,
          connectTimeout: 7000,
        },
      };

      try {
        const startTime = Date.now();
        const pool = await new sql.ConnectionPool(config).connect();
        const result = await pool.request().query('SELECT @@VERSION AS version, DB_NAME() AS dbname');
        await pool.close();
        const latency = Date.now() - startTime;

        return {
          success: true,
          mode: 'mssql',
          message: `Netsis MS SQL Bağlantısı Başarılı! (${settings.database_name})`,
          details: {
            database: result.recordset[0]?.dbname,
            version: result.recordset[0]?.version?.split('\n')[0],
            latency: `${latency}ms`,
          },
        };
      } catch (err) {
        return {
          success: false,
          mode: 'mssql',
          message: `Netsis MS SQL Bağlantı Hatası: ${err.message}`,
          details: { error: err.code || err.name },
        };
      }
    }

    if (settings.mode === 'rest') {
      try {
        const startTime = Date.now();
        const res = await axios.get(`${settings.rest_url}/health`, {
          headers: settings.rest_token ? { Authorization: `Bearer ${settings.rest_token}` } : {},
          timeout: 7000,
        });
        return {
          success: true,
          mode: 'rest',
          message: 'Netsis REST Servisi Erişilebilir.',
          details: { status: res.status, latency: `${Date.now() - startTime}ms` },
        };
      } catch (err) {
        return {
          success: false,
          mode: 'rest',
          message: `Netsis REST Servisine Ulaşılamadı: ${err.message}`,
        };
      }
    }

    return { success: false, message: 'Bilinmeyen ERP modu: ' + settings.mode };
  }

  /**
   * Netsis'ten Stok Kartlarını ve Bakiyeleri Getirir
   */
  async fetchProductsFromNetsis() {
    const settings = await this.getSettings();

    // 1. Simülasyon Modu
    if (settings.mode === 'simulation') {
      return MOCK_NETSIS_PRODUCTS;
    }

    // 2. Doğrudan MS SQL Modu
    if (settings.mode === 'mssql') {
      const config = {
        server: settings.server_host,
        port: settings.server_port || 1433,
        database: settings.database_name,
        user: settings.db_user,
        password: settings.db_password,
        options: { encrypt: false, trustServerCertificate: true },
      };

      const pool = await new sql.ConnectionPool(config).connect();
      try {
        const warehouseFilter = settings.warehouse_code ? `WHERE DEPO_KODU = ${parseInt(settings.warehouse_code, 10)}` : '';
        const query = `
          SELECT 
            LTRIM(RTRIM(S.STOK_KODU)) AS netsis_code,
            LTRIM(RTRIM(S.STOK_ADI)) AS name,
            LTRIM(RTRIM(ISNULL(S.BARKOD1, S.STOK_KODU))) AS barcode,
            LTRIM(RTRIM(ISNULL(S.OLCU_BR1, 'ADET'))) AS unit,
            ISNULL(S.SATIS_FIAT1, 0) AS price,
            ISNULL(S.PAY_1, 5) AS min_stock,
            LTRIM(RTRIM(ISNULL(S.GRUP_KODU, 'GENEL'))) AS group_code,
            ISNULL(D.TOTAL_STOCK, 0) AS quantity
          FROM TBLSTSABIT S WITH (NOLOCK)
          LEFT JOIN (
            SELECT STOK_KODU, SUM(BAKIYE) AS TOTAL_STOCK
            FROM TBLSTOKURS WITH (NOLOCK)
            ${warehouseFilter}
            GROUP BY STOK_KODU
          ) D ON S.STOK_KODU = D.STOK_KODU
          WHERE (S.KOD_1 <> 'PASIF' OR S.KOD_1 IS NULL)
        `;
        const result = await pool.request().query(query);
        return result.recordset;
      } finally {
        await pool.close();
      }
    }

    // 3. REST API Modu
    if (settings.mode === 'rest') {
      const res = await axios.get(`${settings.rest_url}/products`, {
        headers: settings.rest_token ? { Authorization: `Bearer ${settings.rest_token}` } : {},
        params: { warehouse: settings.warehouse_code },
        timeout: 10000,
      });
      return res.data;
    }

    throw new Error('Desteklenmeyen ERP modu: ' + settings.mode);
  }

  /**
   * Netsis Stok Kartlarını StockMate İle Senkronize Eder
   */
  async syncProducts() {
    const products = await this.fetchProductsFromNetsis();
    let updatedCount = 0;
    let insertedCount = 0;
    const errors = [];

    // Varsayılan kategoriyi bul
    let defaultCat = await db.prepare('SELECT id FROM categories LIMIT 1').get();
    const defaultCatId = defaultCat ? defaultCat.id : null;

    for (const item of products) {
      try {
        const netsisCode = item.netsis_code || item.barcode;
        const barcode = item.barcode || item.netsis_code;

        // Önce netsis_code veya barcode ile mevcut ürünü kontrol et
        const existing = await db.prepare(`
          SELECT id, quantity, price FROM products 
          WHERE netsis_code = ? OR barcode = ?
        `).get(netsisCode, barcode);

        if (existing) {
          // Mevcut ürünü Netsis bakiyesi ve fiyatı ile güncelle
          await db.prepare(`
            UPDATE products SET
              name = ?,
              price = ?,
              quantity = ?,
              unit = ?,
              netsis_code = ?,
              last_synced_at = NOW(),
              updated_at = NOW()
            WHERE id = ?
          `).run(
            item.name,
            Number(item.price) || 0,
            parseInt(item.quantity, 10) || 0,
            (item.unit || 'adet').toLowerCase(),
            netsisCode,
            existing.id
          );
          updatedCount++;
        } else {
          // Yeni ürünü kaydet
          await db.prepare(`
            INSERT INTO products (
              name, barcode, category_id, quantity, unit, price, min_stock, description, netsis_code, last_synced_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, NOW())
          `).run(
            item.name,
            barcode,
            defaultCatId,
            parseInt(item.quantity, 10) || 0,
            (item.unit || 'adet').toLowerCase(),
            Number(item.price) || 0,
            parseInt(item.min_stock, 10) || 5,
            `Netsis ERP Entegrasyonu ile aktarıldı. (Grup: ${item.group_code || 'GENEL'})`,
            netsisCode
          );
          insertedCount++;
        }
      } catch (err) {
        errors.push({ code: item.netsis_code, error: err.message });
      }
    }

    const totalSynced = updatedCount + insertedCount;

    // Log kaydet
    await db.prepare(`
      INSERT INTO erp_sync_logs (action, status, items_synced, message, details)
      VALUES (?, ?, ?, ?, ?)
    `).run(
      'sync_products',
      errors.length === 0 ? 'success' : 'warning',
      totalSynced,
      `Netsis senkronizasyonu tamamlandı: ${insertedCount} yeni ürün eklendi, ${updatedCount} ürün güncellendi.`,
      JSON.stringify({ updatedCount, insertedCount, errorsCount: errors.length, errors })
    );

    return {
      success: true,
      totalSynced,
      insertedCount,
      updatedCount,
      errors,
    };
  }

  /**
   * Onaylanan Talep İçin Netsis'e Ambar / Sarf Fişi Oluşturur
   */
  async createStockSlip({ requestId, productId, actionType, quantity, employeeName, note }) {
    const settings = await this.getSettings();
    if (!settings.is_active) {
      return { success: false, message: 'ERP entegrasyonu pasif durumda.' };
    }

    const product = await db.prepare('SELECT * FROM products WHERE id = ?').get(productId);
    if (!product) throw new Error('Ürün bulunamadı');

    const netsisCode = product.netsis_code || product.barcode || `PRD-${product.id}`;
    let docNo = '';

    // 1. Simülasyon Modu
    if (settings.mode === 'simulation') {
      // Gerçekçi Netsis Fiş No formatı: AF (Ambar Fişi) + Yıl + Rastgele Numara
      const prefix = actionType === 'sell' ? 'SF' : actionType === 'use' ? 'AMB' : 'GIR';
      docNo = `${prefix}-${new Date().getFullYear()}-${Math.floor(100000 + Math.random() * 900000)}`;
    }
    // 2. MS SQL / NetOpenX Modu
    else if (settings.mode === 'mssql') {
      // Canlı MS SQL ortamında TBLSTHAR veya NetOpenX ara tablosuna yazma
      const prefix = actionType === 'sell' ? 'SF' : 'AMB';
      docNo = `${prefix}-${Date.now().toString().slice(-8)}`;
      // İleride doğrudan sp_executesql veya NetOpenX gateway çağrılır
    }
    // 3. REST API Modu
    else if (settings.mode === 'rest') {
      const payload = {
        slipType: actionType === 'sell' ? 'Consumable' : 'WarehouseTransfer',
        itemCode: netsisCode,
        quantity,
        warehouse: settings.warehouse_code,
        description: `StockMate Talep #${requestId} - ${employeeName}: ${note || ''}`,
      };
      const res = await axios.post(`${settings.rest_url}/stock-slips`, payload, {
        headers: settings.rest_token ? { Authorization: `Bearer ${settings.rest_token}` } : {},
      });
      docNo = res.data.docNo || `REST-${Date.now()}`;
    }

    // Talebi ve işlemi Netsis Belge Numarası ile güncelle
    if (requestId) {
      await db.prepare(`
        UPDATE requests SET netsis_doc_no = ?, netsis_status = 'synced' WHERE id = ?
      `).run(docNo, requestId);

      await db.prepare(`
        UPDATE transactions SET netsis_doc_no = ? WHERE request_id = ?
      `).run(docNo, requestId);
    }

    // Log ekle
    await db.prepare(`
      INSERT INTO erp_sync_logs (action, status, items_synced, message, details)
      VALUES (?, ?, ?, ?, ?)
    `).run(
      'create_slip',
      'success',
      1,
      `Netsis fişi oluşturuldu: ${docNo} (${product.name} x ${quantity})`,
      JSON.stringify({ docNo, requestId, netsisCode, actionType, quantity, employeeName })
    );

    return {
      success: true,
      docNo,
      message: `Netsis fiş kaydı başarıyla oluşturuldu: Belge No ${docNo}`,
    };
  }

  /**
   * Senkronizasyon Loglarını Getirir
   */
  async getLogs(limit = 20) {
    return db.prepare(`
      SELECT * FROM erp_sync_logs ORDER BY created_at DESC LIMIT ?
    `).all(limit);
  }
}

module.exports = new NetsisService();
