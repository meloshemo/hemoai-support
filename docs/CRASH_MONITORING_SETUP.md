# 📊 Crash & Performance Monitoring Kurulumu

Bu rehber, Firebase Crashlytics ve Performance Monitoring’i HemoAI uygulamasına
entegre etmek için gereken adımları açıklar.

> ⚠️ Aşağıdaki adımlar tamamlandıktan sonra **Android** ve **iOS** için yeni
> build almanız gerekir. Crash raporlarının gelmesi genellikle ilk crash’ten
> sonra birkaç dakika sürer.

---

## 1. Firebase projesi ve uygulama tanımları

1. **Firebase Console** → [https://console.firebase.google.com](https://console.firebase.google.com)
2. Yeni proje oluştur veya mevcut projeyi seç (`hemoai-production` gibi).
3. **Project settings** → **Your apps** → `Android` ve `iOS` uygulamalarını ekle:
   - App ID: `com.meloshemo.hemoai`
   - `google-services.json` dosyasını `android/app/` dizinine kopyala.
   - `GoogleService-Info.plist` dosyasını `ios/Runner/` dizinine kopyala.

> Not: FlutterFire CLI (`flutterfire configure`) çalıştırırsan bu dosyalar ve
> `lib/firebase/firebase_options.dart` otomatik güncellenir.

---

## 2. FlutterFire CLI ile otomatik konfigürasyon (önerilen)

```bash
flutter pub global activate flutterfire_cli
flutterfire configure \
  --project=<firebase-proje-id> \
  --out=lib/firebase/firebase_options.dart \
  --ios-bundle-id=com.meloshemo.hemoai \
  --android-package-name=com.meloshemo.hemoai
```

Bu komut:
- `firebase_options.dart` dosyasını gerçek değerlerle günceller.
- Android/iOS projelerine gerekli pluginleri ekler.
- Crashlytics/Analytics için Google servis dosyalarını indirir.

---

## 3. Android yapılandırması

1. `android/settings.gradle.kts` dosyasında aşağıdaki plugin satırlarının
   bulunduğundan emin ol:
   ```kotlin
   id("com.google.gms.google-services") version "4.4.2" apply false
   id("com.google.firebase.crashlytics") version "3.0.2" apply false
   ```
2. `android/app/build.gradle.kts` dosyasının **plugins** bölümünde:
   ```kotlin
   id("com.google.gms.google-services")
   id("com.google.firebase.crashlytics")
   ```
3. Aynı dosyada `dependencies` bloğunda Firebase BoM ve Crashlytics
   referansları eklendi.
4. Release build’ler için `android/app/proguard-rules.pro` dosyasına
   Crashlytics kuralları işlendi.
5. Release build alırken Google Play’e sembol yüklemek için Gradle otomatik
   çalışır; manuel yükleme gerekiyorsa:
   ```bash
   ./gradlew app:uploadCrashlyticsSymbolFileRelease
   ```

---

## 4. iOS yapılandırması

1. Eğer `ios/Podfile` henüz yoksa `flutterfire configure` sonrası otomatik
   oluşturulur. Alternatif olarak manuel olarak aşağıdaki komutları çalıştır:
   ```bash
   cd ios
   pod init
   ```
2. `Podfile` içinde hedef blokta Crashlytics pod’ları vardır (FlutterFire CLI
   ekler). Emin olmak için `pod install` çalıştır:
   ```bash
   pod install
   ```
3. Xcode → Runner target → Build Phases → “Run Script” ekle:
   ```bash
   "${PODS_ROOT}/FirebaseCrashlytics/run"
   ```
4. iOS cihazda test etmek için `flutter run --release` ile crash tetikle ve
   Crashlytics panelinden doğrula.

---

## 5. Flutter tarafı

`lib/main.dart` artık `initializeFirebaseTelemetry()` çağrısını yapıyor. Crashler
otomatik raporlanacak. `lib/firebase/firebase_initializer.dart` dosyası, Firebase
opsiyonları `REPLACE_ME` olarak bırakıldıysa başlangıcı atlar.

- Yerine gerçek değerleri koymak için `firebase_options.dart` dosyasını FlutterFire
  CLI ile yeniden üret.
- Debug build’lerde Crashlytics/Performance varsayılan olarak kapalıdır.

Crash test için:

```dart
ElevatedButton(
  onPressed: () => FirebaseCrashlytics.instance.crash(),
  child: const Text('Force Crash'),
);
```

Crash raporunun Firebase Console’da göründüğünü doğrula.

---

## 6. Performance Monitoring

- Performance izleme varsayılan olarak sadece release modunda açıktır.
- Özel trace eklemek istersen:
  ```dart
  final trace = FirebasePerformance.instance.newTrace('hemogram_sync');
  await trace.start();
  // ... işlerin
  await trace.stop();
  ```
- Performans raporlarını Firebase Console → Performance sekmesinden incele.

---

## 7. Yayına çıkmadan önce yapılacak son doğrulamalar

- [ ] Android release APK/AAB build al, Crashlytics test crash’ı gönder.
- [ ] iOS TestFlight build al, Crashlytics test crash’ı gönder.
- [ ] Firebase Console → Crashlytics panelinde uygulamanın SDK versiyonu görünür.
- [ ] Privacy Policy’de crash toplama açıklaması güncel.
- [ ] Git’e commit + tag (`git tag crashlytics-setup`).

Kurulum sırasında karşılaşılan sorunları bu dosyaya not düşersen ileride tekrar
gerektiğinde referans olacaktır.

