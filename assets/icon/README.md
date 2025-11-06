# İkon Dosyaları

## Gerekli Dosyalar

### Ana İkon (Zorunlu)
- **Dosya Adı:** `icon.png`
- **Boyut:** 1024x1024 px
- **Format:** PNG (32-bit, şeffaf arka plan olabilir)
- **İçerik:** Yuvarlatılmış kare içinde kırmızı kan damlası + beyaz devre deseni

### Foreground İkon (Opsiyonel - Adaptive Icon için)
- **Dosya Adı:** `icon_foreground.png`
- **Boyut:** 1024x1024 px
- **Format:** PNG (şeffaf arka plan)
- **İçerik:** Sadece kan damlası + desen (arka plan olmadan)

## Kullanım

1. **İkon dosyanızı buraya koyun:**
   - `assets/icon/icon.png` (1024x1024 px)

2. **Komutları çalıştırın:**
   ```bash
   flutter pub get
   flutter pub run flutter_launcher_icons
   ```

3. **Test edin:**
   ```bash
   flutter run
   ```

## Notlar

- İkon metin içermemelidir
- Merkeze hizalı olmalıdır (Android Adaptive Icon safe zone)
- Yüksek çözünürlükte olmalıdır (1024x1024 px minimum)
- Şeffaf arka plan kullanılabilir (Android otomatik arka plan ekler)

## Android Adaptive Icon

Android 8.0+ için Adaptive Icon kullanılır:
- **Foreground:** Kan damlası + desen (merkezde, safe zone içinde)
- **Background:** Açık gri renk (#E0E0E0) veya gradient

Safe zone: Merkezde 432x432 px (%42) alan önemli detaylar için kullanılmalı.

