const bcrypt = require('bcryptjs');
const db = require('./src/db');

async function seed() {
  await db.initPromise;
  console.log('Seeding rich test data into PostgreSQL...');

  // 1. Employees
  const empHash = bcrypt.hashSync('emp123', 10);
  let emp1 = await db.get('SELECT id FROM users WHERE email = $1', 'ahmet@stockmate.local');
  if (!emp1) {
    const res = await db.run(
      'INSERT INTO users (name, email, password, role) VALUES ($1, $2, $3, $4)',
      'Ahmet Yılmaz', 'ahmet@stockmate.local', empHash, 'employee'
    );
    emp1 = { id: res.lastInsertRowid };
    console.log('Created employee: Ahmet Yılmaz (ahmet@stockmate.local / emp123)');
  }

  let emp2 = await db.get('SELECT id FROM users WHERE email = $1', 'mehmet@stockmate.local');
  if (!emp2) {
    const res = await db.run(
      'INSERT INTO users (name, email, password, role) VALUES ($1, $2, $3, $4)',
      'Mehmet Demir', 'mehmet@stockmate.local', empHash, 'employee'
    );
    emp2 = { id: res.lastInsertRowid };
    console.log('Created employee: Mehmet Demir (mehmet@stockmate.local / emp123)');
  }

  const boss = await db.get('SELECT id FROM users WHERE role = $1', 'boss');

  // 2. Products
  const sampleProducts = [
    {
      name: 'NYA 2.5mm Bakır Kablo (100m Rulo)',
      barcode: '8690001001001',
      serial_key: 'SN-KBL-001',
      category_id: 1,
      quantity: 45,
      unit: 'rulo',
      price: 850.00,
      description: 'H07V-U tek damarlı bakır tesisat kablosu',
      min_stock: 10
    },
    {
      name: 'CAT6 UTP Ağ Kablosu (305m)',
      barcode: '8690001001002',
      serial_key: 'SN-KBL-002',
      category_id: 1,
      quantity: 12,
      unit: 'kutu',
      price: 1450.00,
      description: '23 AWG Gigabit Ethernet veri kablosu',
      min_stock: 5
    },
    {
      name: 'Viko İkili Topraklı Priz Beyaz',
      barcode: '8690001002001',
      serial_key: 'SN-PRZ-001',
      category_id: 2,
      quantity: 85,
      unit: 'adet',
      price: 65.00,
      description: 'Çocuk korumalı sıva altı priz',
      min_stock: 20
    },
    {
      name: 'Siemens 16A Otomatik Sigorta (B Tipi)',
      barcode: '8690001002002',
      serial_key: 'SN-SGR-001',
      category_id: 2,
      quantity: 120,
      unit: 'adet',
      price: 110.00,
      description: '1P 6kA B serisi minyatür devre kesici',
      min_stock: 15
    },
    {
      name: '60x60 Sıva Altı LED Panel 40W',
      barcode: '8690001003001',
      serial_key: 'SN-AYD-001',
      category_id: 3,
      quantity: 28,
      unit: 'adet',
      price: 320.00,
      description: '6500K Beyaz ışık ince tavan aydınlatma',
      min_stock: 10
    },
    {
      name: 'Osram LED Ampul E27 10W Günışığı',
      barcode: '8690001003002',
      serial_key: 'SN-AYD-002',
      category_id: 3,
      quantity: 3, // LOW STOCK
      unit: 'adet',
      price: 45.00,
      description: '806 lümen enerji tasarruflu ampul',
      min_stock: 10
    },
    {
      name: 'Mean Well 24V 10A Ray Tipi Güç Kaynağı',
      barcode: '8690001004001',
      serial_key: 'SN-GUC-001',
      category_id: 4,
      quantity: 14,
      unit: 'adet',
      price: 1150.00,
      description: 'NDR-240-24 DIN rail endüstriyel güç kaynağı',
      min_stock: 5
    },
    {
      name: '12V 7Ah Kuru Akü',
      barcode: '8690001004002',
      serial_key: 'SN-GUC-002',
      category_id: 4,
      quantity: 4, // LOW STOCK
      unit: 'adet',
      price: 420.00,
      description: 'UPS ve alarm sistemleri için bakımsız akü',
      min_stock: 5
    },
    {
      name: 'Omron E2B Endüktif Sensör M12',
      barcode: '8690001005001',
      serial_key: 'SN-SNS-001',
      category_id: 5,
      quantity: 18,
      unit: 'adet',
      price: 680.00,
      description: 'PNP NO 4mm algılama mesafeli sensör',
      min_stock: 5
    },
    {
      name: 'Delta DVP-14SS2 PLC Modülü',
      barcode: '8690001006001',
      serial_key: 'SN-PLC-001',
      category_id: 6,
      quantity: 6,
      unit: 'adet',
      price: 3850.00,
      description: '8 giriş 6 çıkış transistörlü kompakt PLC',
      min_stock: 3
    },
    {
      name: 'Fluke 107 Dijital Multimetre',
      barcode: '8690001008001',
      serial_key: 'SN-OLC-001',
      category_id: 8,
      quantity: 5,
      unit: 'adet',
      price: 2900.00,
      description: 'CAT III 600V taşınabilir hassas ölçü aleti',
      min_stock: 2
    },
    {
      name: '0.75kW Trifaze Asenkron Motor',
      barcode: '8690001007001',
      serial_key: 'SN-MTR-001',
      category_id: 7,
      quantity: 8,
      unit: 'adet',
      price: 4500.00,
      description: '1400 d/d B3 ayaklı alüminyum gövde',
      min_stock: 2
    }
  ];

  const productIds = [];
  for (const p of sampleProducts) {
    const existing = await db.get('SELECT id FROM products WHERE barcode = $1', p.barcode);
    if (!existing) {
      const res = await db.run(`
        INSERT INTO products (name, barcode, serial_key, category_id, quantity, unit, price, description, min_stock)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
      `, p.name, p.barcode, p.serial_key, p.category_id, p.quantity, p.unit, p.price, p.description, p.min_stock);
      productIds.push(res.lastInsertRowid);
    } else {
      productIds.push(existing.id);
    }
  }
  console.log(`Seeded ${sampleProducts.length} products`);

  // 3. Requests (Pending & Approved)
  const existingReqs = await db.get('SELECT COUNT(*) as c FROM requests');
  if (existingReqs && existingReqs.c === 0 && productIds.length >= 4) {
    await db.run(`
      INSERT INTO requests (employee_id, product_id, action_type, quantity, note, status)
      VALUES ($1, $2, 'use', 2, 'Müşteri pano montajında kullanılacak', 'pending')
    `, emp1.id, productIds[6]);

    await db.run(`
      INSERT INTO requests (employee_id, product_id, action_type, quantity, note, status)
      VALUES ($1, $2, 'sell', 5, 'Tezgah satışı - faturalı', 'pending')
    `, emp2.id, productIds[2]);

    await db.run(`
      INSERT INTO requests (employee_id, product_id, action_type, quantity, note, status, resolved_by, resolved_at)
      VALUES ($1, $2, 'restock', 20, 'Toptancıdan yeni parti geldi', 'approved', $3, NOW())
    `, emp1.id, productIds[5], boss.id);

    console.log('Seeded 3 sample requests (2 pending, 1 approved)');
  }

  // 4. Transactions (spread across recent days for activity chart)
  const existingTx = await db.get('SELECT COUNT(*) as c FROM transactions');
  if (existingTx && existingTx.c === 0 && productIds.length >= 6) {
    const txData = [
      { p: productIds[0], u: boss.id, act: 'add', qty: 45, b: 0, a: 45, note: 'Depo ilk giriş', daysAgo: 6 },
      { p: productIds[2], u: emp1.id, act: 'sell', qty: 10, b: 95, a: 85, note: 'Elektrikçi Ahmet usta satışı', daysAgo: 5 },
      { p: productIds[3], u: emp2.id, act: 'sell', qty: 15, b: 135, a: 120, note: 'Şantiye satışı', daysAgo: 4 },
      { p: productIds[4], u: emp1.id, act: 'use', qty: 4, b: 32, a: 28, note: 'Ofis aydınlatma değişimi', daysAgo: 3 },
      { p: productIds[6], u: boss.id, act: 'sell', qty: 2, b: 16, a: 14, note: 'Fabrika acil sipariş', daysAgo: 2 },
      { p: productIds[1], u: emp2.id, act: 'add', qty: 12, b: 0, a: 12, note: 'Yeni makara teslim alındı', daysAgo: 1 },
      { p: productIds[5], u: emp1.id, act: 'sell', qty: 7, b: 10, a: 3, note: 'Market aydınlatma satışı', daysAgo: 0 }
    ];

    for (const t of txData) {
      await db.run(`
        INSERT INTO transactions (product_id, user_id, action_type, quantity, quantity_before, quantity_after, note, created_at)
        VALUES ($1, $2, $3, $4, $5, $6, $7, NOW() - ($8 || ' days')::INTERVAL)
      `, t.p, t.u, t.act, t.qty, t.b, t.a, t.note, t.daysAgo.toString());
    }
    console.log('Seeded 7 transactions with dates for activity charts');
  }

  // 5. Technical Services
  const existingTs = await db.get('SELECT COUNT(*) as c FROM technical_services');
  if (existingTs && existingTs.c === 0) {
    await db.run(`
      INSERT INTO technical_services
        (customer_name, customer_phone, device_type, device_brand, device_model, serial_no,
         fault_description, parts_to_replace, technician_id, status, note, price)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
    `, 'Ali Kaya', '0532 111 2233', 'laptop', 'HP', 'Pavilion 15-EG', '5CD1234XYZ',
       'Aşırı ısınıyor ve 15 dk sonra kapanıyor', 'Termal macun, fan temizliği',
       emp1.id, 'in_progress', 'Müşteriye 1200 TL fiyat onaylatıldı', 1200.00);

    await db.run(`
      INSERT INTO technical_services
        (customer_name, customer_phone, device_type, device_brand, device_model, serial_no,
         fault_description, parts_to_replace, technician_id, status, note, price)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
    `, 'Zeynep Arslan', '0544 222 3344', 'phone', 'Apple', 'iPhone 13', 'DNPCW1234ABC',
       'Düşme sonucu ön cam çatlak, ekran dokunmatiği kısmi çalışıyor', 'Orijinal OLED Ekran',
       emp2.id, 'waiting', 'Parça tedariği bekleniyor', 3500.00);

    await db.run(`
      INSERT INTO technical_services
        (customer_name, customer_phone, device_type, device_brand, device_model, serial_no,
         fault_description, parts_to_replace, technician_id, status, note, price)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
    `, 'Kemal Sunal Ticaret', '0555 333 4455', 'tv', 'Samsung', '55AU7000 4K', '01A2345678',
       'Ses var ancak görüntü yok (arka aydınlatma sönük)', 'LED Bar Takımı',
       emp1.id, 'done', 'Test edildi, müşteri aranıp teslim edilecek', 2400.00);

    console.log('Seeded 3 technical service tickets (waiting, in_progress, done)');
  }

  console.log('Sample data seeding completed successfully!');
  process.exit(0);
}

seed().catch(err => {
  console.error('Error seeding data:', err);
  process.exit(1);
});
