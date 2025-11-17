# HemoAI Challenges Sistemi - Gerçekçi Implementasyon Planı

## Mevcut Durum

### ✅ Çalışan Özellikler
- **Su Takibi**: `WaterService` mevcut ve çalışıyor
  - Manuel bardak ekleme
  - Günlük hedef takibi
  - Streak (seri) hesaplama
  - Veritabanında saklama (`water_intake` tablosu)

### ❌ Eksik Özellikler
- **Adım Sayacı**: Sadece `HealthSyncService` var ama aktif değil
- **Uyku Takibi**: Hiç yok
- **Puan Sistemi**: `ChallengeService` var ama gerçek verilerle entegre değil

## Gerçekçi Çözüm Planı

### 1. Adım Sayacı (Steps Tracker)

#### Seçenek A: Manuel Giriş (Önerilen - Başlangıç)
- Kullanıcı günlük adım sayısını manuel olarak girer
- Basit ve güvenilir
- Tüm platformlarda çalışır (web, mobile)

#### Seçenek B: Health Package Entegrasyonu (Gelecek)
- `health` package ile otomatik senkronizasyon
- iOS HealthKit ve Android Google Fit entegrasyonu
- İzin gerektirir

**Implementasyon:**
```dart
// Yeni servis: StepsService
- logSteps(userId, steps, date)
- getTodaySteps(userId)
- getWeeklySteps(userId)
- getMonthlySteps(userId)
- setDailyGoal(userId, goal) // Varsayılan: 10000 adım
```

**Veritabanı:**
```sql
CREATE TABLE daily_activities (
  id INTEGER PRIMARY KEY,
  user_id INTEGER NOT NULL,
  date TEXT NOT NULL,
  steps INTEGER DEFAULT 0,
  sleep_minutes INTEGER DEFAULT 0,
  water_glasses INTEGER DEFAULT 0,
  points INTEGER DEFAULT 0,
  created_at TEXT NOT NULL,
  UNIQUE(user_id, date)
)
```

### 2. Uyku Takibi (Sleep Tracker)

**Manuel Giriş:**
- Kullanıcı uyku saatini ve uyanma saatini girer
- Otomatik olarak dakikaya çevrilir
- Günlük hedef: 7-8 saat (420-480 dakika)

**Implementasyon:**
```dart
// Yeni servis: SleepService
- logSleep(userId, sleepMinutes, date)
- getTodaySleep(userId)
- getWeeklySleep(userId)
- getMonthlySleep(userId)
- setDailyGoal(userId, goal) // Varsayılan: 480 dakika (8 saat)
```

### 3. Puan Sistemi (Points System)

**Hesaplama Mantığı:**
- **Adım Hedefi**: Günlük 10,000 adım = 10 puan
  - 10,000+ adım: 10 puan
  - 7,500-9,999: 7 puan
  - 5,000-7,499: 5 puan
  - 2,500-4,999: 2 puan
  - <2,500: 0 puan

- **Su Hedefi**: Günlük 8 bardak (2000ml) = 10 puan
  - 8+ bardak: 10 puan
  - 6-7 bardak: 7 puan
  - 4-5 bardak: 5 puan
  - 2-3 bardak: 2 puan
  - <2 bardak: 0 puan

- **Uyku Hedefi**: Günlük 8 saat (480 dakika) = 10 puan
  - 7-9 saat: 10 puan
  - 6-7 saat: 7 puan
  - 5-6 saat: 5 puan
  - 4-5 saat: 2 puan
  - <4 saat: 0 puan

- **Bonus Puanlar**:
  - Tüm hedefleri tamamlama: +5 bonus
  - 7 gün üst üste tamamlama: +20 bonus
  - 30 gün üst üste tamamlama: +50 bonus

**Günlük Maksimum**: 35 puan (10+10+10+5 bonus)

**Haftalık Maksimum**: 245 puan (35 x 7)

**Rozet Sistemi:**
- 100 puan = 1 rozet
- Her rozet için özel ikon ve isim

### 4. Streak (Seri) Sistemi

**Hesaplama:**
- Kullanıcı günlük hedeflerini tamamladığında streak artar
- En az 2 hedefi tamamlamak gerekir (örn: adım + su)
- 1 gün kaçırılırsa streak sıfırlanır

**Ödüller:**
- 3 gün: 🔥
- 7 gün: 🔥🔥
- 14 gün: 🔥🔥🔥
- 30 gün: 🏆
- 100 gün: 👑

## Veritabanı Şeması

```sql
-- Günlük aktiviteler tablosu
CREATE TABLE daily_activities (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  date TEXT NOT NULL, -- YYYY-MM-DD formatında
  steps INTEGER DEFAULT 0,
  sleep_minutes INTEGER DEFAULT 0,
  water_glasses INTEGER DEFAULT 0,
  points INTEGER DEFAULT 0,
  goals_achieved INTEGER DEFAULT 0, -- Kaç hedef tamamlandı (0-3)
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  UNIQUE(user_id, date),
  FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
);

-- Kullanıcı hedefleri tablosu
CREATE TABLE user_goals (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  steps_goal INTEGER DEFAULT 10000,
  water_goal INTEGER DEFAULT 8, -- bardak sayısı
  sleep_goal INTEGER DEFAULT 480, -- dakika
  updated_at TEXT NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
);

-- Streak bilgileri (mevcut ChallengeService'te var ama veritabanına taşınabilir)
```

## Implementasyon Adımları

### Adım 1: Veritabanı Güncellemeleri
1. `daily_activities` tablosunu oluştur
2. `user_goals` tablosunu oluştur
3. Migration script'i hazırla

### Adım 2: Servisler
1. `StepsService` oluştur
2. `SleepService` oluştur
3. `ActivityService` oluştur (tüm aktiviteleri yönetir)
4. `PointsCalculator` oluştur (puan hesaplama mantığı)

### Adım 3: UI Güncellemeleri
1. Challenges ekranında gerçek verileri göster
2. Manuel giriş ekranları ekle:
   - Adım girişi
   - Uyku girişi
3. Dashboard'a hızlı giriş butonları ekle

### Adım 4: Entegrasyon
1. `ChallengeService`'i gerçek verilerle entegre et
2. `SocialChallengeService`'i güncelle
3. Otomatik puan hesaplama ekle

## Kullanıcı Deneyimi

### Günlük Akış
1. Kullanıcı uygulamayı açar
2. Dashboard'da bugünkü ilerleme görür
3. Adım/su/uyku girişi yapar
4. Otomatik olarak puanlar hesaplanır
5. Streak güncellenir
6. Rozetler kazanılır

### Haftalık Özet
- Haftalık toplam adım
- Haftalık toplam su
- Haftalık ortalama uyku
- Haftalık toplam puan
- Kazanılan rozetler

### Aylık Özet
- Aylık toplam adım
- Aylık toplam su
- Aylık ortalama uyku
- Aylık toplam puan
- En uzun streak

## Gelecek Geliştirmeler

1. **Health Package Entegrasyonu**
   - Otomatik adım senkronizasyonu
   - Otomatik uyku takibi (akıllı saatler)

2. **Bildirimler**
   - Hedef hatırlatmaları
   - Streak koruma uyarıları

3. **Sosyal Özellikler**
   - Arkadaşlarla yarışma
   - Grup challenge'ları
   - Lider tablosu

4. **Gamification**
   - Daha fazla rozet türü
   - Seviye sistemi
   - Başarı rozetleri

