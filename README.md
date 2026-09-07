# 📦 StockMate

> **Smart Inventory Management for Electrical & Electronics Stores**

A full-stack inventory management system built with **Flutter** (mobile) and **Node.js + SQLite** (backend). Designed for small-to-medium electrical & electronics shops with role-based access, barcode scanning, and a manager approval workflow.

---

## ✨ Features

### 👑 Boss (Manager)
- 📊 Dashboard with stock summary, charts & pending approvals
- ➕ Add / edit / delete products
- 🔍 Barcode & serial number lookup
- ✅ Approve or reject employee stock requests
- 👥 Employee management
- 📋 Full transaction history

### 👷 Employee
- 📷 Barcode scanner for fast product search
- 📤 Submit sale / usage / restock requests
- 🔔 Track own request status (approved / rejected)
- 📋 Personal transaction history

### 📋 Approval System
Every stock operation (sale, usage, restock) is submitted for manager review before being applied.

---

## 🗂️ Project Structure

```
stockmate/
├── stockmate-backend/    # Node.js + Express + SQLite REST API
│   ├── src/
│   │   ├── db.js         # Database schema & seed
│   │   ├── routes/       # Auth, products, requests, transactions, employees
│   │   └── middleware/   # JWT authentication
│   └── index.js          # Entry point (port 3000)
│
└── stockmate-app/        # Flutter mobile app
    └── lib/
        ├── core/         # Theme, router, constants
        ├── features/     # Screens & Riverpod providers
        └── shared/       # API service & utilities
```

---

## 🚀 Quick Start

### 1. Start the Backend

```bash
cd stockmate-backend
npm install
npm start
```

Server runs at `http://0.0.0.0:3000`

**Default admin credentials:**
| Field    | Value                  |
|----------|------------------------|
| Email    | `boss@stockmate.local` |
| Password | `boss123`              |

### 2. Run the Flutter App

> **Prerequisite:** [Install Flutter](https://docs.flutter.dev/get-started/install/windows) and add it to PATH.

```bash
cd stockmate-app
flutter pub get
flutter run
```

### 3. First-Time Setup

1. Open the app on your device
2. Tap **Server Settings** → enter the backend IP (e.g. `http://192.168.1.100:3000`)
3. Log in with the boss account
4. Create employee accounts via **Staff → Add Employee**
5. Start adding products!

---

## 🔌 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/auth/login` | Login |
| `GET` | `/products` | List all products |
| `POST` | `/products` | Add product *(boss only)* |
| `GET` | `/products/lookup/:code` | Search by barcode/serial |
| `POST` | `/requests` | Submit a stock request |
| `GET` | `/requests?status=pending` | View pending requests |
| `PUT` | `/requests/:id/approve` | Approve request *(boss only)* |
| `PUT` | `/requests/:id/reject` | Reject request *(boss only)* |
| `GET` | `/transactions/stats` | Dashboard statistics |
| `GET` | `/employees` | List employees |

---

## 🛠️ Tech Stack

| Layer | Technology |
|-------|-----------|
| Mobile App | Flutter + Riverpod + GoRouter |
| HTTP Client | Dio |
| Barcode Scanner | mobile_scanner |
| Charts | fl_chart |
| Backend | Node.js + Express 5 |
| Database | SQLite (better-sqlite3) |
| Auth | JWT + bcryptjs |

---

## 📦 Categories

`Cable & Connectivity` · `Switch & Socket` · `Lighting` · `Power Supply` · `Sensor & Detector` · `Automation` · `Motor & Driver` · `Measurement Device` · `Spare Parts` · `Other`

---

## 📄 License

MIT © [sinaares](https://github.com/sinaares)
