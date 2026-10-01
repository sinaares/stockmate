let DatabaseSync;
try {
  ({ DatabaseSync } = require('node:sqlite'));
} catch (_) {}

const bcrypt = require('bcryptjs');
const path = require('path');
require('dotenv').config();

const DB_PATH = process.env.DB_PATH || './stockmate.db';
let db;

if (DatabaseSync) {
  db = new DatabaseSync(path.resolve(DB_PATH));
  db.pragma = (str) => db.exec(`PRAGMA ${str}`);
  db.transaction = (fn) => (...args) => {
    db.exec('BEGIN');
    try {
      const result = fn(...args);
      db.exec('COMMIT');
      return result;
    } catch (err) {
      db.exec('ROLLBACK');
      throw err;
    }
  };
} else {
  const Database = require('better-sqlite3');
  db = new Database(path.resolve(DB_PATH));
}

db.pragma('journal_mode = WAL');
db.pragma('foreign_keys = ON');

function initDb() {
  db.exec(`
    CREATE TABLE IF NOT EXISTS users (
      id          INTEGER PRIMARY KEY AUTOINCREMENT,
      name        TEXT    NOT NULL,
      email       TEXT    NOT NULL UNIQUE,
      password    TEXT    NOT NULL,
      role        TEXT    NOT NULL CHECK(role IN ('boss','employee')),
      active      INTEGER NOT NULL DEFAULT 1,
      created_at  TEXT    NOT NULL DEFAULT (datetime('now'))
    );
  `);

  db.exec(`
    CREATE TABLE IF NOT EXISTS categories (
      id      INTEGER PRIMARY KEY AUTOINCREMENT,
      name_tr TEXT NOT NULL,
      name_en TEXT NOT NULL
    );
  `);

  db.exec(`
    CREATE TABLE IF NOT EXISTS products (
      id            INTEGER PRIMARY KEY AUTOINCREMENT,
      name          TEXT    NOT NULL,
      barcode       TEXT    UNIQUE,
      serial_key    TEXT    UNIQUE,
      category_id   INTEGER REFERENCES categories(id),
      quantity      INTEGER NOT NULL DEFAULT 0,
      unit          TEXT    NOT NULL DEFAULT 'adet',
      price         REAL    NOT NULL DEFAULT 0,
      description   TEXT,
      min_stock     INTEGER NOT NULL DEFAULT 5,
      created_at    TEXT    NOT NULL DEFAULT (datetime('now')),
      updated_at    TEXT    NOT NULL DEFAULT (datetime('now'))
    );
  `);

  db.exec(`
    CREATE TABLE IF NOT EXISTS requests (
      id            INTEGER PRIMARY KEY AUTOINCREMENT,
      employee_id   INTEGER NOT NULL REFERENCES users(id),
      product_id    INTEGER NOT NULL REFERENCES products(id),
      action_type   TEXT    NOT NULL CHECK(action_type IN ('add','remove','sell','use','restock')),
      quantity      INTEGER NOT NULL,
      note          TEXT,
      status        TEXT    NOT NULL DEFAULT 'pending' CHECK(status IN ('pending','approved','rejected')),
      reject_reason TEXT,
      resolved_by   INTEGER REFERENCES users(id),
      resolved_at   TEXT,
      created_at    TEXT    NOT NULL DEFAULT (datetime('now'))
    );
  `);

  db.exec(`
    CREATE TABLE IF NOT EXISTS transactions (
      id              INTEGER PRIMARY KEY AUTOINCREMENT,
      product_id      INTEGER NOT NULL REFERENCES products(id),
      user_id         INTEGER NOT NULL REFERENCES users(id),
      action_type     TEXT    NOT NULL,
      quantity        INTEGER NOT NULL,
      quantity_before INTEGER NOT NULL,
      quantity_after  INTEGER NOT NULL,
      note            TEXT,
      request_id      INTEGER REFERENCES requests(id),
      created_at      TEXT    NOT NULL DEFAULT (datetime('now'))
    );
  `);

  db.exec(`
    CREATE TABLE IF NOT EXISTS technical_services (
      id                INTEGER PRIMARY KEY AUTOINCREMENT,
      customer_name     TEXT    NOT NULL,
      customer_phone    TEXT,
      device_type       TEXT    NOT NULL CHECK(device_type IN ('laptop','phone','tablet','tv','other')),
      device_brand      TEXT    NOT NULL,
      device_model      TEXT,
      serial_no         TEXT,
      fault_description TEXT    NOT NULL,
      parts_to_replace  TEXT,
      technician_id     INTEGER REFERENCES users(id),
      status            TEXT    NOT NULL DEFAULT 'waiting' CHECK(status IN ('waiting','in_progress','done','delivered','cancelled')),
      note              TEXT,
      price             REAL    NOT NULL DEFAULT 0,
      created_at        TEXT    NOT NULL DEFAULT (datetime('now')),
      updated_at        TEXT    NOT NULL DEFAULT (datetime('now'))
    );
  `);

  const boss = db.prepare('SELECT id FROM users WHERE email = ?').get('boss@stockmate.local');
  if (!boss) {
    const hash = bcrypt.hashSync('boss123', 10);
    db.prepare(`INSERT INTO users (name, email, password, role) VALUES (?, ?, ?, 'boss')`).run('Boss', 'boss@stockmate.local', hash);
    console.log('Default boss created — email: boss@stockmate.local  password: boss123');
  }

  const catCount = db.prepare('SELECT COUNT(*) as c FROM categories').get();
  if (catCount.c === 0) {
    const cats = [
      ['Kablo & Baglanti','Cable & Connectivity'],
      ['Anahtar & Priz','Switch & Socket'],
      ['Aydinlatma','Lighting'],
      ['Guc Kaynagi','Power Supply'],
      ['Sensor & Detektor','Sensor & Detector'],
      ['Otomasyon','Automation'],
      ['Motor & Surucu','Motor & Driver'],
      ['Olcum Cihazi','Measurement Device'],
      ['Yedek Parca','Spare Parts'],
      ['Diger','Other']
    ];
    const ins = db.prepare('INSERT INTO categories (name_tr, name_en) VALUES (?, ?)');
    cats.forEach(([tr, en]) => ins.run(tr, en));
    console.log('Default categories seeded');
  }
  console.log('Database initialized');
}

initDb();
module.exports = db;
