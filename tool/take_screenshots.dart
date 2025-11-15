/// Basit screenshot alma scripti
/// Kullanım: dart run tool/take_screenshots.dart
/// 
/// Bu script, emulator/simulator'den manuel screenshot almanızı kolaylaştırır.
/// Flutter Screenshots paketi null safety desteklemediği için bu alternatif kullanılıyor.

import 'dart:io';

void main() {
  print('📸 HemoAI Screenshot Alma Rehberi\n');
  print('=' * 60);
  print('\nFlutter Screenshots paketi null safety desteklemediği için');
  print('manuel screenshot alma yöntemini kullanıyoruz.\n');
  print('=' * 60);
  print('\n📋 ADIMLAR:\n');
  
  print('1️⃣  Emulator/Simulator\'ü başlatın:');
  print('   Android: flutter emulators --launch Pixel_7_Pro_API_33');
  print('   iOS:     Xcode Simulator\'ü açın (iPhone 15 Pro)\n');
  
  print('2️⃣  Uygulamayı çalıştırın:');
  print('   flutter run --release\n');
  
  print('3️⃣  Screenshot alın:');
  print('   Android: Emulator toolbar\'dan 📷 ikonu veya Ctrl+S');
  print('   iOS:     Cmd+S veya Device > Screenshot\n');
  
  print('4️⃣  Screenshot konumları:');
  if (Platform.isWindows) {
    print('   Android: %LOCALAPPDATA%\\Android\\sdk\\platform-tools\\screenshots\\');
  } else if (Platform.isMacOS) {
    print('   Android: ~/Library/Android/sdk/platform-tools/screenshots/');
    print('   iOS:     Desktop (otomatik kaydedilir)');
  } else {
    print('   Android: ~/Android/Sdk/platform-tools/screenshots/');
  }
  
  print('\n5️⃣  Boyutları düzenleyin:');
  print('   Online: https://squoosh.app');
  print('   Gerekli boyutlar:');
  print('   - Play Store: 1080 × 1920 px');
  print('   - App Store:  1290 × 2796 px (iPhone 15 Pro)\n');
  
  print('📸 Screenshot alınacak ekranlar:');
  print('   1. Dashboard (Ana ekran)');
  print('   2. Analysis (Hemogram analiz)');
  print('   3. Diet Program (Beslenme planı)');
  print('   4. Family Panel (Aile üyeleri)');
  print('   5. Reminders (Hatırlatıcılar)');
  print('   6. Challenges (Motivasyon) - Opsiyonel\n');
  
  print('💡 İpuçları:');
  print('   - Test kullanıcısı: Phone 5551234567, Password 1234');
  print('   - Debug banner\'ı kapatın');
  print('   - Status bar: Saat 10:00, batarya dolu');
  print('   - Gerçekçi veriler ekleyin\n');
  
  print('🚀 Hızlı başlamak için:');
  print('   flutter emulators --launch Pixel_7_Pro_API_33');
  print('   flutter run --release\n');
  
  print('=' * 60);
  print('\n✅ Hazırsanız emulator\'ü başlatın ve uygulamayı çalıştırın!\n');
}

