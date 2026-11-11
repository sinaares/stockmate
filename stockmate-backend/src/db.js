const { Pool, types } = require('pg');
const bcrypt = require('bcryptjs');
require('dotenv').config();

// Parse BigInt (e.g. COUNT(*)) as numbers
types.setTypeParser(20, val => (val === null ? null : parseInt(val, 10)));
// Parse Numeric / Decimal (e.g. price, SUM) as numbers
types.setTypeParser(1700, val => (val === null ? null : parseFloat(val)));

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
});

pool.on('error', (err) => {
  console.error('Unexpected PostgreSQL pool error:', err);
});

function formatSql(sql) {
  let paramIndex = 1;
  let formatted = sql.replace(/\?/g, () => `$${paramIndex++}`);
  formatted = formatted.replace(/datetime\('now'\)/gi, 'NOW()');
  formatted = formatted.replace(/date\('now',\s*'-30 days'\)/gi, "(CURRENT_DATE - INTERVAL '30 days')");
  formatted = formatted.replace(/date\(created_at\)/gi, 'DATE(created_at)');
  return formatted;
}

function normalizeParams(params) {
  if (params.length === 1 && Array.isArray(params[0])) {
    return params[0];
  }
  return params;
}

async function query(sql, params = []) {
  const formattedSql = formatSql(sql);
  const flatParams = normalizeParams(params);
  return pool.query(formattedSql, flatParams);
}

async function all(sql, ...params) {
  const res = await query(sql, params);
  return res.rows;
}

async function get(sql, ...params) {
  const res = await query(sql, params);
  return res.rows[0] || null;
}

async function run(sql, ...params) {
  let formattedSql = formatSql(sql);
  const flatParams = normalizeParams(params);
  const isInsert = /^\s*INSERT\s+INTO/i.test(formattedSql);
  if (isInsert && !/RETURNING/i.test(formattedSql)) {
    formattedSql += ' RETURNING id';
  }
  const res = await pool.query(formattedSql, flatParams);
  const lastInsertRowid = res.rows[0]?.id;
  return {
    rowCount: res.rowCount,
    lastInsertRowid,
  };
}

async function transaction(fn) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const trxDb = {
      query: (sql, params = []) => client.query(formatSql(sql), normalizeParams(params)),
      get: async (sql, ...params) => {
        const res = await client.query(formatSql(sql), normalizeParams(params));
        return res.rows[0] || null;
      },
      all: async (sql, ...params) => {
        const res = await client.query(formatSql(sql), normalizeParams(params));
        return res.rows;
      },
      run: async (sql, ...params) => {
        let formattedSql = formatSql(sql);
        const flatParams = normalizeParams(params);
        if (/^\s*INSERT\s+INTO/i.test(formattedSql) && !/RETURNING/i.test(formattedSql)) {
          formattedSql += ' RETURNING id';
        }
        const res = await client.query(formattedSql, flatParams);
        return {
          rowCount: res.rowCount,
          lastInsertRowid: res.rows[0]?.id,
        };
      },
      prepare: (sql) => ({
        all: (...p) => trxDb.all(sql, ...p),
        get: (...p) => trxDb.get(sql, ...p),
        run: (...p) => trxDb.run(sql, ...p),
      }),
    };
    const result = await fn(trxDb);
    await client.query('COMMIT');
    return result;
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

function prepare(sql) {
  return {
    all: (...p) => all(sql, ...p),
    get: (...p) => get(sql, ...p),
    run: (...p) => run(sql, ...p),
  };
}

async function initDb() {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS users (
      id          SERIAL PRIMARY KEY,
      name        VARCHAR(255) NOT NULL,
      email       VARCHAR(255) NOT NULL UNIQUE,
      password    VARCHAR(255) NOT NULL,
      role        VARCHAR(50) NOT NULL CHECK(role IN ('boss','employee')),
      active      INTEGER NOT NULL DEFAULT 1,
      created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );
  `);

  await pool.query(`
    CREATE TABLE IF NOT EXISTS categories (
      id      SERIAL PRIMARY KEY,
      name_tr VARCHAR(255) NOT NULL,
      name_en VARCHAR(255) NOT NULL
    );
  `);

  await pool.query(`
    CREATE TABLE IF NOT EXISTS products (
      id            SERIAL PRIMARY KEY,
      name          VARCHAR(255) NOT NULL,
      barcode       VARCHAR(255) UNIQUE,
      serial_key    VARCHAR(255) UNIQUE,
      category_id   INTEGER REFERENCES categories(id) ON DELETE SET NULL,
      quantity      INTEGER NOT NULL DEFAULT 0,
      unit          VARCHAR(50) NOT NULL DEFAULT 'adet',
      price         NUMERIC(12,2) NOT NULL DEFAULT 0,
      description   TEXT,
      min_stock     INTEGER NOT NULL DEFAULT 5,
      created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );
  `);

  await pool.query(`
    CREATE TABLE IF NOT EXISTS requests (
      id            SERIAL PRIMARY KEY,
      employee_id   INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      product_id    INTEGER NOT NULL REFERENCES products(id) ON DELETE CASCADE,
      action_type   VARCHAR(50) NOT NULL CHECK(action_type IN ('add','remove','sell','use','restock')),
      quantity      INTEGER NOT NULL,
      note          TEXT,
      status        VARCHAR(50) NOT NULL DEFAULT 'pending' CHECK(status IN ('pending','approved','rejected')),
      reject_reason TEXT,
      resolved_by   INTEGER REFERENCES users(id) ON DELETE SET NULL,
      resolved_at   TIMESTAMPTZ,
      created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );
  `);

  await pool.query(`
    CREATE TABLE IF NOT EXISTS transactions (
      id              SERIAL PRIMARY KEY,
      product_id      INTEGER NOT NULL REFERENCES products(id) ON DELETE CASCADE,
      user_id         INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      action_type     VARCHAR(50) NOT NULL,
      quantity        INTEGER NOT NULL,
      quantity_before INTEGER NOT NULL,
      quantity_after  INTEGER NOT NULL,
      note            TEXT,
      request_id      INTEGER REFERENCES requests(id) ON DELETE SET NULL,
      created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );
  `);

  await pool.query(`
    CREATE TABLE IF NOT EXISTS technical_services (
      id                SERIAL PRIMARY KEY,
      customer_name     VARCHAR(255) NOT NULL,
      customer_phone    VARCHAR(100),
      device_type       VARCHAR(50) NOT NULL CHECK(device_type IN ('laptop','phone','tablet','tv','other')),
      device_brand      VARCHAR(255) NOT NULL,
      device_model      VARCHAR(255),
      serial_no         VARCHAR(255),
      fault_description TEXT NOT NULL,
      parts_to_replace  TEXT,
      technician_id     INTEGER REFERENCES users(id) ON DELETE SET NULL,
      status            VARCHAR(50) NOT NULL DEFAULT 'waiting' CHECK(status IN ('waiting','in_progress','done','delivered','cancelled')),
      note              TEXT,
      price             NUMERIC(12,2) NOT NULL DEFAULT 0,
      created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );
  `);

  const boss = await get('SELECT id FROM users WHERE email = $1', 'boss@stockmate.local');
  if (!boss) {
    const hash = bcrypt.hashSync('boss123', 10);
    await run('INSERT INTO users (name, email, password, role) VALUES ($1, $2, $3, $4)', 'Boss', 'boss@stockmate.local', hash, 'boss');
    console.log('Default boss created — email: boss@stockmate.local  password: boss123');
  }

  const catCount = await get('SELECT COUNT(*) as c FROM categories');
  if (catCount && catCount.c === 0) {
    const cats = [
      ['Kablo & Baglanti', 'Cable & Connectivity'],
      ['Anahtar & Priz', 'Switch & Socket'],
      ['Aydinlatma', 'Lighting'],
      ['Guc Kaynagi', 'Power Supply'],
      ['Sensor & Detektor', 'Sensor & Detector'],
      ['Otomasyon', 'Automation'],
      ['Motor & Surucu', 'Motor & Driver'],
      ['Olcum Cihazi', 'Measurement Device'],
      ['Yedek Parca', 'Spare Parts'],
      ['Diger', 'Other']
    ];
    for (const [tr, en] of cats) {
      await run('INSERT INTO categories (name_tr, name_en) VALUES ($1, $2)', tr, en);
    }
    console.log('Default categories seeded');
  }
  console.log('PostgreSQL Database initialized');
}

const initPromise = initDb().catch((err) => {
  console.error('Failed to initialize PostgreSQL Database:', err);
});

module.exports = {
  pool,
  query,
  all,
  get,
  run,
  prepare,
  transaction,
  initPromise,
};
