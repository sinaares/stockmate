# StockMate 📦
**Elektrik & Elektronik Mağaza Stok Yönetim Sistemi**
**Electrical & Electronics Store Inventory Management System**

---

## Hızlı Başlangıç / Quick Start

### 1. Backend'i Başlat (Ofis Sunucusu)

```bash
cd stockmate-backend
npm install
npm start
```

Sunucu `http://0.0.0.0:3000` adresinde çalışacak.
Varsayılan yönetici hesabı:
- E-posta: `boss@stockmate.local`
- Şifre: `boss123`

### 2. Flutter Uygulamasını Kur

Flutter yüklü değilse:
- https://docs.flutter.dev/get-started/install/windows adresinden indirin
- PATH'e ekleyin: `C:\flutter\bin`
- Çalıştırın: `flutter doctor`

```bash
cd stockmate-app
flutter pub get
flutter run   # Android/iOS cihaza bağlayın
```

### 3. İlk Kullanım

1. Uygulamayı açın
2. Sunucu Ayarı'na tıklayın → ofis sunucu IP'sini girin (örn: http://192.168.1.100:3000)
3. Boss hesabıyla giriş yapın
4. İşçi hesapları oluşturun (Personel > Personel Ekle)
5. Ürün eklemeye başlayın!

---

## Özellikler / Features

### 👑 Boss (Yönetici)
- ✅ Dashboard: Stok özeti, bekleyen onaylar, grafikler
- ✅ Ürün ekleme/düzenleme/silme
- ✅ Barkod / Seri no ile ürün tanıma
- ✅ Çalışan isteklerini onaylama veya reddetme
- ✅ Personel yönetimi
- ✅ Tam işlem geçmişi

### 👷 Çalışan / Employee
- ✅ Barkod tarama ile hızlı ürün arama
- ✅ Satış / Kullanım / Yenileme isteği gönderme
- ✅ Kendi istek durumlarını görme (onay/red)
- ✅ Kendi işlem geçmişi

### 📋 Onay Sistemi / Approval System
Çalışanların her stok işlemi (satış, kullanım, yenileme)
yönetici onayına gönderilir. Yönetici kabul veya red edebilir.

---

## Kategori Listesi / Category List

- Kablo & Bağlantı / Cable & Connectivity
- Anahtar & Priz / Switch & Socket
- Aydınlatma / Lighting
- Güç Kaynağı / Power Supply
- Sensör & Dedektör / Sensor & Detector
- Otomasyon / Automation
- Motor & Sürücü / Motor & Driver
- Ölçüm Cihazı / Measurement Device
- Yedek Parça / Spare Parts
- Diğer / Other

---

## API Uç Noktaları / API Endpoints

| Method | Endpoint | Açıklama |
|--------|----------|----------|
| POST | /auth/login | Giriş |
| GET | /products | Ürün listesi |
| POST | /products | Yeni ürün (boss) |
| GET | /products/lookup/:code | Barkod/seri ile ara |
| POST | /requests | İstek gönder |
| GET | /requests?status=pending | Bekleyen istekler |
| PUT | /requests/:id/approve | Onayla (boss) |
| PUT | /requests/:id/reject | Reddet (boss) |
| GET | /transactions/stats | Dashboard istatistikleri |
| GET | /employees | Personel listesi |

---

## Mimari / Architecture

```
stockmate/
├── stockmate-backend/    # Node.js + Express + SQLite
│   ├── src/
│   │   ├── db.js         # Veritabanı şeması
│   │   ├── routes/       # API rotaları
│   │   └── middleware/   # JWT auth
│   └── index.js
└── stockmate-app/        # Flutter
    └── lib/
        ├── core/         # Tema, router, sabitler
        ├── features/     # Ekran ve provider'lar
        └── shared/       # Ortak servisler
```
