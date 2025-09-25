@echo off
echo HemoAI Android Setup Script
echo ========================

echo 1. Flutter Android yapılandırması...
flutter config --android-studio-dir "C:\Program Files\Android\Android Studio"
flutter config --android-sdk "%LOCALAPPDATA%\Android\Sdk"

echo 2. Flutter doctor kontrol...
flutter doctor

echo 3. Android lisanslarını kabul et...
flutter doctor --android-licenses

echo 4. Son kontrol...
flutter doctor

echo 5. Android cihazları listele...
flutter devices

echo Setup tamamlandı!
pause