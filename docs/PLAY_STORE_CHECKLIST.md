# Play Store Submission Checklist for HemoAI

## ✅ Completed
- [x] Release signing configured (keystore + key.properties)
- [x] Android minSdk: 26 (required for ML Kit + TFLite)
- [x] Version: 4.0.0+400
- [x] App ID: com.meloshemo.hemoai
- [x] Release builds working (APK, AAB, Web, Windows)
- [x] ProGuard rules for ML Kit & TFLite
- [x] Keystore secured in .gitignore
- [x] App metadata updated (name, description, manifest)

## ⚠️ Must Complete Before Submission

### 1. **Privacy Policy (CRITICAL)**
   - [x] Create privacy policy HTML page ✅ (`docs/privacy-policy.html`)
   - [ ] Host at a publicly accessible URL (GitHub Pages, own domain, etc.)
   - [ ] Add URL to Play Console → Data safety section
   - [ ] Required by Google for apps handling health/medical data

### 2. **App Store Listing** (Play Console)
   - [x] Content prepared ✅ (See `docs/PLAY_STORE_LISTING_CONTENT.md`)
   - [ ] App name: "HemoAI" (max 30 chars)
   - [ ] Short description: "Smart hemogram analysis & health tracking" (max 80 chars)
   - [ ] Full description (max 4000 chars):
     ```
     HemoAI helps you track and analyze your blood test results with AI-powered insights.
     
     **Features:**
     - Smart analysis with risk scoring
     - Personalized diet recommendations based on your values
     - Alternative medicine suggestions (herbs, supplements)
     - Reminders for medications, tests, and appointments
     - Family health tracking
     - Secure encrypted backups
     - Multi-language support (Turkish, English, Spanish, French, German, Arabic)
     
     **Privacy First:**
     - All data stays on your device
     - No cloud upload (unless you explicitly enable)
     - AES-256 encrypted backups
     
     Perfect for monitoring hemoglobin, iron, cholesterol, and other vital parameters.
     ```
   - [ ] Screenshots: 2-8 required
     - Phone (1080x1920 or higher)
     - Tablet (7"-10"): optional
   - [ ] Feature graphic: 1024x500px
   - [ ] App icon: 512x512px
   - [ ] Category: Medical / Health & Fitness

### 3. **Data Safety Declaration** (Play Console)
   - [x] Answers prepared ✅ (See `docs/DATA_SAFETY_DECLARATION.md`)
   - [ ] Data types collected:
     - [ ] Health & fitness (hemogram values, medications)
     - [ ] Personal info (age, gender, BMI)
     - [ ] App activity (usage analytics - if enabled)
   - [ ] Data sharing: None (everything local)
   - [ ] Data security: Encrypted backups, local storage only
   - [ ] Data deletion: Users can export/delete via app

### 4. **Content Rating** (required for Medical category)
   - [x] Guide prepared ✅ (See `docs/CONTENT_RATING_GUIDE.md`)
   - [ ] Complete questionnaire in Play Console
   - [ ] Answer questions about content type (Medical app)
   - [ ] Get rating certificate

### 5. **Target Audience**
   - [ ] Age: 18+ (handles medical data)
   - [ ] Countries: All or specific list

### 6. **Pricing**
   - [ ] Free (recommended for initial launch)
   - [ ] Or set price tier

### 7. **Release Type**
   - [ ] Internal testing (testers: internal team)
   - [ ] Closed testing (testers: beta group)
   - [ ] Open testing (wider beta)
   - [ ] Production (full release)

## 📋 Optional but Recommended

### App Content Improvements
- [ ] Add app icon variations (adaptive icon)
- [ ] Create promo videos (YouTube)
- [ ] Add "What's New" changelog
- [ ] Request user reviews after happy flows

### Compliance
- [ ] GDPR compliance statement (if targeting EU)
- [ ] HIPAA compliance (if US users)
- [ ] Medical disclaimer in-app:
  > "HemoAI provides health information for educational purposes only. It is not a substitute for professional medical advice, diagnosis, or treatment. Always consult with qualified healthcare providers."

### Analytics & Monitoring
- [ ] Set up Google Analytics for Firebase
- [ ] Configure Crashlytics
- [ ] Monitor Play Console vitals

### Localization
- [ ] Translate store listing (TR, ES, FR, DE, AR)
- [ ] Add localized screenshots

## 🚫 Not Needed for v1 Release
- Payment integration
- In-app purchases
- Social media login
- Cloud sync (already opt-in only)
- Dark mode toggle (auto system)
- Custom themes

## 📝 Quick Reference

**Keystore Info:**
- Path: `android/app/keystore/release.jks`
- Alias: `hemoai`
- Passwords: See `android/key.properties` (NOT COMMITTED)

**Build Commands:**
```bash
# AAB for Play Store
flutter build appbundle --release

# APK for direct install
flutter build apk --release

# Web
flutter build web --release

# Windows
flutter build windows --release
```

**Outputs:**
- AAB: `build/app/outputs/bundle/release/app-release.aab`
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- Web: `build/web/`
- Windows: `build/windows/x64/runner/Release/`

## 🔗 Resources
- [Play Console](https://play.google.com/console)
- [Play Store Publishing Overview](https://support.google.com/googleplay/android-developer/topic/3450762)
- [Data Safety Form](https://support.google.com/googleplay/android-developer/answer/10787469)
- [Content Rating](https://support.google.com/googleplay/android-developer/answer/188189)

## ⚠️ Critical Notes
1. **Never lose the keystore** - You cannot publish updates without it!
   - Backup `android/app/keystore/release.jks` securely
   - Keep `android/key.properties` secret
   
2. **Medical app regulations** vary by country. Research:
   - Turkey: No specific app store requirements
   - EU: General Data Protection Regulation (GDPR)
   - US: Federal Trade Commission (FTC) guidance
   
3. **AI/ML claims**: Be careful with marketing language. Don't claim "AI diagnosis" - say "AI-assisted analysis" or "health insights."

4. **First submission**: Expect 1-3 days review time for medical apps.

## ✅ Quality Gates (Pre-Upload)
- [ ] All critical bugs fixed
- [ ] No crashes on main flows
- [ ] Performance: <3s app start
- [ ] Privacy policy accessible
- [ ] User testing done (friends, family)
- [ ] Localization complete for target languages
- [ ] Backwards compatibility tested (Android 8.0+)

