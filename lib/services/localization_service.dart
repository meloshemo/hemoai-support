import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Localization Service for Multi-language Support
class LocalizationService extends ChangeNotifier {
  static final LocalizationService _instance = LocalizationService._internal();
  factory LocalizationService() => _instance;
  LocalizationService._internal();

  // Current language (start with neutral fallback; will auto-detect on initialize if no saved preference)
  Locale _currentLocale = const Locale('en', '');
  Locale get currentLocale => _currentLocale;
  String get currentLanguageCode => _currentLocale.languageCode;

  String get currentLanguageName =>
    languageNames[_currentLocale.languageCode] ?? _currentLocale.languageCode;

  String get currentLanguageFlag =>
    languageFlags[_currentLocale.languageCode] ?? '';

  // Basic RTL detection (extend if more RTL languages are added)
  bool get isRTL => _currentLocale.languageCode == 'ar';
  TextDirection get textDirection => isRTL ? TextDirection.rtl : TextDirection.ltr;

  // Supported languages
  final List<Locale> supportedLocales = [
    const Locale('tr', ''), // Turkish
    const Locale('en', ''), // English
    const Locale('es', ''), // Spanish
    const Locale('fr', ''), // French
    const Locale('de', ''), // German
    const Locale('ar', ''), // Arabic
  ];

  // Language names for UI
  final Map<String, String> languageNames = {
    'tr': 'Türkçe',
    'en': 'English',
    'es': 'Español',
    'fr': 'Français',
    'de': 'Deutsch',
    'ar': 'العربية',
  };

  // Language flags/icons
  final Map<String, String> languageFlags = {
    'tr': '🇹🇷',
    'en': '🇺🇸',
    'es': '🇪🇸',
    'fr': '🇫🇷',
    'de': '🇩🇪',
    'ar': '🇸🇦',
  };

  // Initialize localization service
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguage = prefs.getString('selected_language');

      if (savedLanguage != null) {
        final locale = Locale(savedLanguage, '');
        if (supportedLocales.any((l) => l.languageCode == locale.languageCode)) {
          _currentLocale = locale;
        }
      } else {
        // No saved preference -> detect device locale
        try {
          final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
          final deviceCode = deviceLocale.languageCode;
          final matched = supportedLocales.firstWhere(
            (l) => l.languageCode == deviceCode,
            orElse: () => const Locale('en', ''),
          );
          _currentLocale = matched;
        } catch (e) {
          // Fallback already English
          if (kDebugMode) {
            debugPrint('⚠️ Failed to detect system locale, using fallback en. Error: $e');
          }
        }
      }

      // Notify listeners after initialization
      notifyListeners();

      if (kDebugMode) {
        debugPrint('🌍 LocalizationService initialized with locale: ${_currentLocale.languageCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error initializing LocalizationService: $e');
      }
    }
  }

  // Change language
  Future<void> changeLanguage(String languageCode) async {
    try {
      final newLocale = Locale(languageCode, '');
      if (supportedLocales.any((l) => l.languageCode == newLocale.languageCode)) {
        _currentLocale = newLocale;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('selected_language', languageCode);
        notifyListeners();
        if (kDebugMode) {
          debugPrint('🌍 Language changed to: $languageCode');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error changing language: $e');
      }
    }
  }

  // Master localization map
  static const Map<String, Map<String, String>> _localizedStrings = {
    // Diet program helper labels
    'include_colon': {
      'tr': 'Önerilenler:',
      'en': 'Include:',
    },
    'limit_colon': {
      'tr': 'Sınırlanın:',
      'en': 'Limit:',
    },
    // Common UI (only unique keys here; others exist with full language sets later)
    // 'close' defined earlier in Common UI
    'done': {
      'tr': 'Bitti',
      'en': 'Done',
    },
    'preferences': {
      'tr': 'Tercihler',
      'en': 'Preferences',
    },
    'users': {
      'tr': 'Kullanıcılar',
      'en': 'Users',
    },
      'load_more': {
        'tr': 'Daha fazla yükle',
        'en': 'Load more',
      },
    'hemogram_tests': {
      'tr': 'Hemogram Testleri',
      'en': 'Hemogram Tests',
    },
    'family_invitations': {
      'tr': 'Aile Davetleri',
      'en': 'Family Invitations',
    },
    'water': {
      'tr': 'Su',
      'en': 'Water',
    },
    'restore_preview': {
      'tr': 'Geri Yükleme Önizleme',
      'en': 'Restore Preview',
    },
    'backup_overview': {
      'tr': 'Yedek Özeti',
      'en': 'Backup Overview',
    },
    'backup_platform': {
      'tr': 'Platform',
      'en': 'Platform',
    },
    'restore_strategy': {
      'tr': 'Geri Yükleme Stratejisi',
      'en': 'Restore Strategy',
    },
    'restore_merge': {
      'tr': 'Birleştir (varsa koru)',
      'en': 'Merge (keep existing)',
    },
    'restore_merge_desc': {
      'tr': 'Mevcut verileri korur, yedekten eksik olanları ekler.',
      'en': 'Keeps your existing data, adds only what is missing from backup.',
    },
    'restore_replace': {
      'tr': 'Değiştir (üzerine yaz)',
      'en': 'Replace (overwrite)',
    },
    'restore_replace_desc': {
      'tr': 'Uygun bölümlerde mevcut verileri temizler ve yedek ile değiştirir.',
      'en': 'Clears applicable sections and replaces them with backup contents.',
    },
    'apply_restore': {
      'tr': 'Geri Yüklemeyi Uygula',
      'en': 'Apply Restore',
    },
    'you': {
      'tr': 'Sen',
      'en': 'You',
    },
    'privacy_summary_title': {
      'tr': 'Mahremiyet Özeti',
      'en': 'Privacy Summary',
    },
    'privacy_summary_desc': {
      'tr': 'Veriler cihazda; şifreli yedek ipuçları.',
      'en': 'On-device data; encrypted backup tips.',
    },
    'privacy_summary_body': {
      'tr': '• Verileriniz cihazda tutulur; ağ üzerinden gönderilmez.\n• İsteğe bağlı Analitik, yalnızca yerelde ve anonimdir.\n• Şifreli yedek: Güçlü parola seçin, parolayı güvenli saklayın.\n• Yedeği doğrulamak için “deneme yedeği” alıp Geri Yükleme Önizleme’de kontrol edebilirsiniz.',
      'en': '• Your data stays on device; nothing is sent over the network.\n• Optional Analytics is local-only and anonymous.\n• Encrypted backup: choose a strong passphrase and store it safely.\n• To verify, make a trial backup and inspect it in Restore Preview before relying on it.',
    },
    // Alternative Medicine UI additions
    'search_herbs_placeholder': {
      'tr': 'Bitkiler ve çözümler içinde ara...',
      'en': 'Search herbs and solutions...',
    },
    'favorites': {
      'tr': 'Favoriler',
      'en': 'Favorites',
    },
    'all_categories': {
      'tr': 'Tümü',
      'en': 'All',
    },
    'no_results': {
      'tr': 'Sonuç bulunamadı',
      'en': 'No results',
    },
    'toggle_favorite': {
      'tr': 'Favorilere ekle/çıkar',
      'en': 'Toggle favorite',
    },
    'trial_backup_title': {
      'tr': 'Deneme Yedeği (Roundtrip)',
      'en': 'Trial Backup (Roundtrip)',
    },
    'trial_backup_desc': {
      'tr': 'Hızlı bir yedek al ve Geri Yükleme Önizleme’de doğrula (uygulanmaz).',
      'en': 'Create a quick backup and verify in Restore Preview (no apply).',
    },
      'stats_overview_title': {
        'tr': 'İstatistikler',
        'en': 'Statistics',
        'es': 'Estadísticas',
        'fr': 'Statistiques',
        'de': 'Statistiken',
        'ar': 'إحصائيات',
      },
      'stats_overview_desc': {
        'tr': 'Zaman içinde ilerlemenizi gösteren hafif özetler.',
        'en': 'Lightweight summaries showing your progress over time.',
        'es': 'Resúmenes ligeros que muestran tu progreso en el tiempo.',
        'fr': 'Synthèses légères montrant votre progression dans le temps.',
        'de': 'Leichte Zusammenfassungen Ihrer Fortschritte im Zeitverlauf.',
        'ar': 'ملخصات خفيفة تظهر تقدمك مع الوقت.',
      },
      'stats_total_tests': {
        'tr': 'Toplam test sayısı',
        'en': 'Total tests',
        'es': 'Pruebas totales',
        'fr': 'Nombre total de tests',
        'de': 'Gesamtanzahl Tests',
        'ar': 'إجمالي الاختبارات',
      },
      'stats_family_members': {
        'tr': 'Aile üyesi',
        'en': 'Family members',
        'es': 'Miembros de la familia',
        'fr': 'Membres de la famille',
        'de': 'Familienmitglieder',
        'ar': 'أفراد العائلة',
      },
      'stats_active_medications': {
        'tr': 'Aktif ilaçlar',
        'en': 'Active medications',
        'es': 'Medicamentos activos',
        'fr': 'Médicaments actifs',
        'de': 'Aktive Medikamente',
        'ar': 'الأدوية النشطة',
      },
      'stats_unread_notifications': {
        'tr': 'Okunmamış bildirimler',
        'en': 'Unread notifications',
        'es': 'Notificaciones no leídas',
        'fr': 'Notifications non lues',
        'de': 'Ungelesene Benachrichtigungen',
        'ar': 'إشعارات غير مقروءة',
      },
      'privacy_local_analytics_note': {
        'tr': 'Not: İstatistikler cihazda tutulur; ağ bağlantısı veya kimlik verisi kullanılmaz.',
        'en': 'Note: Stats are kept on-device; no network or identity data is used.',
        'es': 'Nota: Las estadísticas se guardan en el dispositivo; no se usan redes ni datos de identidad.',
        'fr': 'Remarque : Les statistiques sont conservées sur l’appareil ; pas de réseau ni de données d’identité.',
        'de': 'Hinweis: Statistiken werden auf dem Gerät gespeichert; keine Netzwerk- oder Identitätsdaten.',
        'ar': 'ملاحظة: يتم الاحتفاظ بالإحصاءات على الجهاز؛ دون شبكة أو بيانات هوية.',
      },
      'why_did_i_get_this': {
        'tr': 'Bu bildirimi neden aldım?',
        'en': 'Why did I get this?',
        'es': '¿Por qué recibí esto?',
        'fr': 'Pourquoi ai-je reçu ceci ?',
        'de': 'Warum habe ich das erhalten?',
        'ar': 'لماذا تلقيت هذا؟',
      },
      'reason_scheduled_time': {
        'tr': 'Planlanan Zaman',
        'en': 'Scheduled Time',
      },
      'reason_received_at': {
        'tr': 'Alınma Zamanı',
        'en': 'Received At',
      },
      'reason_repeat': {
        'tr': 'Tekrar',
        'en': 'Repeat',
      },
      'reason_reminder_id': {
        'tr': 'Hatırlatıcı ID',
        'en': 'Reminder ID',
      },
      'reason_category': {
        'tr': 'Kategori',
        'en': 'Category',
      },
      'reason_hour': {
        'tr': 'Saat',
        'en': 'Hour',
      },
      'reason_minute': {
        'tr': 'Dakika',
        'en': 'Minute',
      },
      'reason_device_token': {
        'tr': 'Cihaz Anahtarı',
        'en': 'Device Token',
      },
      'reason_permission_granted': {
        'tr': 'İzin Verildi',
        'en': 'Permission Granted',
      },
    // Settings hub
    'settings_personal_data': {
      'tr': 'Kişisel Veriler',
      'en': 'Personal Data',
    },
    'settings_privacy': {
      'tr': 'Gizlilik',
      'en': 'Privacy',
    },
    'settings_security': {
      'tr': 'Güvenlik',
      'en': 'Security',
    },
    'settings_data_backup': {
      'tr': 'Veri & Yedekleme',
      'en': 'Data & Backup',
    },
    'settings_legal': {
      'tr': 'Hukuki',
      'en': 'Legal',
    },
    'edit_profile': {
      'tr': 'Profili Düzenle',
      'en': 'Edit Profile',
    },
    'edit_profile_desc': {
      'tr': 'Kişisel bilgilerinizi güncelleyin',
      'en': 'Update your personal information',
    },
    'account_login': {
      'tr': 'Hesap / Giriş',
      'en': 'Account / Login',
    },
    'account_login_desc': {
      'tr': 'Oturum aç veya hesap değiştir',
      'en': 'Sign in or switch account',
    },
    'privacy_policy': {
      'tr': 'Gizlilik Politikası',
      'en': 'Privacy Policy',
    },
    'privacy_policy_desc': {
      'tr': 'Kişisel verilerinizin işlenmesi hakkında',
      'en': 'How we process your personal data',
    },
    'privacy_policy_body': {
      'tr': 'Verileriniz cihazınızda saklanır. Yedekleme veya paylaşım yapmadığınız sürece sunucularımıza gönderilmez. Bildirim tercihleri ve sağlık verileri yalnızca uygulama içinde kullanılır.',
      'en': 'Your data is stored on your device. It is not sent to our servers unless you choose to back up or share. Notification preferences and health data are used only within the app.',
    },
    'terms_of_use': {
      'tr': 'Kullanım Şartları',
      'en': 'Terms of Use',
    },
    'terms_of_use_desc': {
      'tr': 'Uygulama kullanım koşulları',
      'en': 'Application usage terms',
    },
    'terms_of_use_body': {
      'tr': 'Bu uygulama tıbbi tanı yerine geçmez. Sağlık durumunuz için her zaman bir uzmana danışın. Uygulama özellikleri, yerel yasalara uygun olarak kullanılmalıdır.',
      'en': 'This app does not substitute medical diagnosis. Always consult a professional for your health condition. Use the app features in compliance with local laws.',
    },
      // Legal: Medical disclaimer (Settings > Legal)
      'medical_disclaimer': {
        'tr': 'Tıbbi Uyarı',
        'en': 'Medical Disclaimer',
      },
      'medical_disclaimer_desc': {
        'tr': 'Uygulama yalnızca bilgilendirme amaçlıdır',
        'en': 'The app is for informational purposes only',
      },
      'medical_disclaimer_body': {
        'tr': 'HemoAI tarafından sunulan bilgiler yalnızca genel bilgilendirme amaçlıdır ve tıbbi tavsiye niteliği taşımaz. Sağlık durumunuzla ilgili tanı ve tedavi kararlarını doktorunuz verir. Acil bir durumda yerel acil yardım hattını arayın veya en yakın sağlık kuruluşuna başvurun. Uygulamadaki veriler üçüncü taraf kaynaklara ve kullanıcı girişlerine dayanabilir; doğruluğu ve güncelliği garanti edilmez.',
        'en': 'The information provided by HemoAI is for general informational purposes only and does not constitute medical advice. Only your physician can diagnose and treat health conditions. In case of emergency, call your local emergency number or visit the nearest healthcare facility. Data in the app may rely on third-party sources and user input; accuracy and timeliness are not guaranteed.',
      },
    'analytics_opt_in': {
      'tr': 'Analitiklere Katıl',
      'en': 'Join Analytics',
    },
    'analytics_opt_in_desc': {
      'tr': 'Kullanım verilerini anonim olarak paylaş',
      'en': 'Share anonymous usage analytics',
    },
    'app_lock': {
      'tr': 'Uygulama Kilidi',
      'en': 'App Lock',
    },
    'app_lock_desc': {
      'tr': 'Uygulama açılışında kilit ekranı',
      'en': 'Lock screen on app launch',
    },
    'clear_notifications': {
      'tr': 'Bildirimleri Temizle',
      'en': 'Clear Notifications',
    },
    'clear_notifications_desc': {
      'tr': 'Tüm yerel bildirimleri sil',
      'en': 'Remove all local notifications',
    },
    'notification_debug_title': {
      'tr': 'Bildirim Hata Ayıklama',
      'en': 'Notification Debug',
    },
    'notification_debug_desc': {
      'tr': 'Planlanan, alınan ve günlükleri görüntüle',
      'en': 'View scheduled, received and logs',
    },
    'notification_debug_scheduled': {
      'tr': 'Planlanan Bildirimler',
      'en': 'Scheduled Notifications',
    },
    'notification_debug_received': {
      'tr': 'Alınan Bildirimler',
      'en': 'Received Notifications',
    },
    'notification_debug_logs': {
      'tr': 'Günlükler',
      'en': 'Logs',
    },
    'none': {
      'tr': 'Yok',
      'en': 'None',
    },
    'mark_read': {
      'tr': 'Okundu işaretle',
      'en': 'Mark read',
    },
    'mark_read_long': {
      'tr': 'Bu bildirimi okundu olarak işaretle',
      'en': 'Mark this notification as read',
    },
    // Backup & restore actions (keys exist later for export options; keep section titles here only if unique)
    'delete_all_data': {
      'tr': 'Tüm Verileri Sil',
      'en': 'Delete All Data',
    },
    'delete_all_data_desc': {
      'tr': 'Tüm uygulama verilerini kalıcı olarak sil',
      'en': 'Permanently delete all app data',
    },
    'delete_all_data_confirm': {
      'tr': 'Bu işlem geri alınamaz. Tüm veriler silinsin mi?',
      'en': 'This action cannot be undone. Delete all data?',
    },
    'data_deleted': {
      'tr': 'Veriler silindi',
      'en': 'Data deleted',
    },
    // Encrypted backup UI
    'encrypted_backup': {
      'tr': 'Şifreli Yedek',
      'en': 'Encrypted Backup',
    },
    'encrypted_backup_desc': {
      'tr': 'Yedeği parola ile AES‑GCM şifrele',
      'en': 'Encrypt backup with password (AES‑GCM)',
    },
    'set_backup_password': {
      'tr': 'Yedek Parolası Belirle',
      'en': 'Set Backup Password',
    },
    'enter_backup_password': {
      'tr': 'Yedek Parolasını Gir',
      'en': 'Enter Backup Password',
    },
    'password': {
      'tr': 'Parola',
      'en': 'Password',
    },
    'confirm_password': {
      'tr': 'Parolayı Doğrula',
      'en': 'Confirm Password',
    },
    'encryption_enabled': {
      'tr': 'Şifreleme etkin',
      'en': 'Encryption enabled',
    },
    'decryption_failed': {
      'tr': 'Şifre çözme başarısız',
      'en': 'Decryption failed',
    },
    'help_support': {
      'tr': 'Yardım & Destek',
      'en': 'Help & Support',
    },
    'help_support_desc': {
      'tr': 'Geri bildirim paylaşın veya sorun bildirin',
      'en': 'Share feedback or report issues',
    },
    'help_support_body': {
      'tr': 'Bize düşüncelerinizi iletin: hemoai-support@example.com. Kullanıcı deneyiminizi geliştirmek için buradayız.',
      'en': 'Tell us what you think: hemoai-support@example.com. We are here to improve your experience.',
    },
    'error_details': {
      'tr': 'Hata Detayları',
      'en': 'Error Details',
    },
    // Backup helpers (defined in export section later)
    'smart_health_assistant': {
      'tr': 'Akıllı Sağlık Asistanı',
      'en': 'Smart Health Assistant',
    },
    // Exported PDF headings
    'analysis_details_heading': {
      'tr': 'Analiz Detayları',
      'en': 'Analysis Details',
    },
    'recommendations_heading': {
      'tr': 'Öneriler',
      'en': 'Recommendations',
    },
    'key_parameters_heading': {
      'tr': 'Temel Parametreler',
      'en': 'Key Parameters',
    },
    // Diet program exported filenames/texts
    'diet_programs': {
      'tr': 'Diyet Programları',
      'en': 'Diet Programs',
    },
    'daily_menu_heading': {
      'tr': 'Günlük Menü',
      'en': 'Daily Menu',
    },
    'daily_menu': {
      'tr': 'Günlük Menü',
      'en': 'Daily Menu',
    },
    // Meal slot labels
    'breakfast_label': {
      'tr': 'Kahvaltı',
      'en': 'Breakfast',
    },
    'lunch_label': {
      'tr': 'Öğle Yemeği',
      'en': 'Lunch',
    },
    'snack_label': {
      'tr': 'Ara Öğün',
      'en': 'Snack',
    },
    'dinner_label': {
      'tr': 'Akşam Yemeği',
      'en': 'Dinner',
    },
    'weekly_overview': {
      'tr': 'Haftalık Özet',
      'en': 'Weekly Overview',
    },
    'hydration_tip': {
      'tr': 'Gün boyu su tüketimini artırın.',
      'en': 'Increase water intake throughout the day.',
    },
    // Diet quick actions
    'copy_todays_menu': {
      'tr': 'Bugünkü menüyü kopyala',
      'en': "Copy today's menu",
    },
    'menu_copied': {
      'tr': 'Menü panoya kopyalandı',
      'en': 'Menu copied to clipboard',
    },
    // Smart substitutions UI
    'smart_substitutions': {
      'tr': 'Akıllı alternatifler',
      'en': 'Smart substitutions',
    },
    'alternatives_for': {
      'tr': '{item} için alternatifler',
      'en': 'Alternatives for {item}',
    },
    'no_alternatives_available': {
      'tr': 'Alternatif bulunamadı',
      'en': 'No alternatives available',
    },
    // Substitution lists (newline separated), keep concise and localized
    'diet_subs_oatmeal_molasses': {
      'tr': 'Keçi boynuzu pekmezli yulaf (1 YK)\nFındık + bal ile yulaf (küçük porsiyon)\nTam buğday gevreği + süt',
      'en': 'Oatmeal with carob molasses (1 tbsp)\nOatmeal with nuts + honey (small)\nWhole-wheat cereal + milk',
    },
    'diet_subs_boiled_egg': {
      'tr': 'Menemen (az yağlı)\nHaşlanmış nohut (yarım kase)\nLor peyniri (2-3 YK) + domates',
      'en': 'Light veggie scramble\nBoiled chickpeas (half bowl)\nCurd cheese (2-3 tbsp) + tomato',
    },
    'diet_subs_chicken_or_legumes': {
      'tr': 'Hindi göğüs (ızgara)\nTofu sote\nSomon (ızgara, küçük porsiyon)',
      'en': 'Turkey breast (grilled)\nTofu stir-fry\nSalmon (grilled, small)',
    },
    // Diet item strings (used by DietMenuService)
    'diet_item_oatmeal_molasses': {
      'tr': 'Pekmezli yulaf (1 yemek kaşığı)',
      'en': 'Oatmeal with molasses (1 tbsp)',
    },
    'diet_item_boiled_egg': {
      'tr': 'Haşlanmış yumurta',
      'en': 'Boiled egg',
    },
    'diet_item_orange_or_kiwi': {
      'tr': 'Taze portakal veya kivi',
      'en': 'Fresh orange or kiwi',
    },
    'diet_item_walnuts_handful': {
      'tr': 'Bir avuç ceviz',
      'en': 'Handful of walnuts',
    },
    'diet_item_yogurt_kefir': {
      'tr': 'Sade yoğurt + kefir (200 ml)',
      'en': 'Plain yogurt + kefir (200 ml)',
    },
    'diet_item_mixed_berries': {
      'tr': 'Karışık orman meyveleri',
      'en': 'Mixed berries',
    },
    'diet_item_chia_tbsp': {
      'tr': 'Chia tohumu (1 yemek kaşığı)',
      'en': 'Chia seeds (1 tbsp)',
    },
    'diet_item_omelette_veggies': {
      'tr': 'Sebzeli omlet',
      'en': 'Omelette with vegetables',
    },
    'diet_item_wholegrain_toast': {
      'tr': 'Tam tahıllı tost',
      'en': 'Whole-grain toast',
    },
    'diet_item_seasonal_fruit': {
      'tr': 'Mevsim meyvesi',
      'en': 'Seasonal fruit',
    },
    'diet_item_grilled_lean_meat_or_liver': {
      'tr': 'Izgara yağsız kırmızı et veya tavuk ciğeri (haftada 2x)',
      'en': 'Grilled lean red meat or chicken liver (2x/week)',
    },
    'diet_item_green_salad_lemon': {
      'tr': 'Yeşil salata + limon',
      'en': 'Green salad + lemon',
    },
    'diet_item_quinoa_or_bulgur': {
      'tr': 'Kinoa veya bulgur',
      'en': 'Quinoa or bulgur',
    },
    'diet_item_salmon_or_legumes': {
      'tr': 'Izgara somon veya baklagiller (nohut/mercimek)',
      'en': 'Grilled salmon or legumes (chickpeas/lentils)',
    },
    'diet_item_olive_oil_salad': {
      'tr': 'Zeytinyağlı salata',
      'en': 'Olive oil salad',
    },
    'diet_item_brown_rice': {
      'tr': 'Esmer pirinç',
      'en': 'Brown rice',
    },
    'diet_item_chicken_or_legumes': {
      'tr': 'Tavuk göğüs veya baklagiller',
      'en': 'Chicken breast or legumes',
    },
    'diet_item_mixed_salad': {
      'tr': 'Karışık salata',
      'en': 'Mixed salad',
    },
    'diet_item_wholegrain_pasta_or_bulgur': {
      'tr': 'Tam tahıllı makarna veya bulgur',
      'en': 'Whole-grain pasta or bulgur',
    },
    'diet_item_dried_apricots_pumpkin_seeds': {
      'tr': 'Kuru kayısı + kabak çekirdeği',
      'en': 'Dried apricots + pumpkin seeds',
    },
    'diet_item_molasses_milk': {
      'tr': 'Pekmezli süt (küçük bardak) haftada 2-3x',
      'en': 'Molasses milk (small glass) 2-3x/week',
    },
    'diet_item_apple_almonds': {
      'tr': 'Elma + badem',
      'en': 'Apple + almonds',
    },
    'diet_item_probiotic_yogurt': {
      'tr': 'Probiyotik yoğurt',
      'en': 'Probiotic yogurt',
    },
    'diet_item_fruit_nuts': {
      'tr': 'Meyve + kuruyemiş',
      'en': 'Fruit + nuts',
    },
    'diet_item_dark_chocolate_70': {
      'tr': 'Bitter çikolata (%70) 10-15g',
      'en': 'Dark chocolate (70%) 10-15g',
    },
    'diet_item_legume_stew': {
      'tr': 'Baklagil yemeği (mercimek/kuru fasulye)',
      'en': 'Legume stew (lentils/beans)',
    },
    'diet_item_beet_or_spinach_salad': {
      'tr': 'Pancar veya ıspanak salatası',
      'en': 'Beet or spinach salad',
    },
    'diet_item_wholegrain_bread_slice': {
      'tr': 'Tam tahıllı ekmek (1 dilim)',
      'en': 'Whole-grain bread (1 slice)',
    },
    'diet_item_turkey_or_tofu_stirfry': {
      'tr': 'Hindi veya tofu sote',
      'en': 'Turkey or tofu stir-fry',
    },
    'diet_item_steamed_veg_broccoli_cauliflower': {
      'tr': 'Buharda sebze (brokoli/karnabahar)',
      'en': 'Steamed vegetables (broccoli/cauliflower)',
    },
    'diet_item_sweet_potato': {
      'tr': 'Tatlı patates',
      'en': 'Sweet potato',
    },
    'diet_item_grilled_fish_or_egg_dish': {
      'tr': 'Izgara balık veya yumurta bazlı yemek',
      'en': 'Grilled fish or egg-based dish',
    },
    'diet_item_seasonal_salad': {
      'tr': 'Mevsim salatası',
      'en': 'Seasonal salad',
    },
    'diet_item_whole_grains_small_portion': {
      'tr': 'Tam tahıllar (küçük porsiyon)',
      'en': 'Whole grains (small portion)',
    },
    // OCR legacy keys (kept for backup screens and embedded OCR button label)
    'ocr_reader': {
      'tr': 'OCR Okuyucu',
      'en': 'OCR Reader',
    },
    'enhanced_notifications': {
      'tr': 'Gelişmiş Bildirimler',
      'en': 'Enhanced Notifications',
    },
    'ocr_desktop_placeholder': {
      'tr': 'Bu özellik masaüstünde devre dışı.',
      'en': 'This feature is disabled on desktop.',
    },
    'ocr_not_available_web': {
      'tr': 'OCR özelliği web üzerinde kullanılamıyor.',
      'en': 'OCR is not available on the web.',
    },
    'scan_document': {
      'tr': 'Belge Tara',
      'en': 'Scan Document',
    },
    'no_text_yet': {
      'tr': 'Henüz metin algılanmadı.',
      'en': 'No text recognized yet.',
    },
    'ocr_values_populated': {
      'tr': 'OCR ile alanlar dolduruldu. Lütfen kontrol edin.',
      'en': 'Values populated from OCR. Please review.',
    },
    'ocr_error': {
      'tr': 'OCR işleminde bir hata oluştu.',
      'en': 'An error occurred during OCR.',
    },
    'ocr_processing_error': {
      'tr': 'İşleme sırasında bir hata oluştu.',
      'en': 'An error occurred during processing.',
    },
    'ocr_review_title': {
      'tr': 'OCR Sonuçlarını Gözden Geçir',
      'en': 'Review OCR Results',
    },
    'view_source_image': {
      'tr': 'Kaynak görüntüyü görüntüle',
      'en': 'View source image',
    },
    'ocr_review_instructions': {
      'tr': 'Algılanan değerleri kontrol edin ve gerekli düzenlemeleri yapın.',
      'en': 'Review the recognized values and make adjustments if needed.',
    },
    'ocr_review_description': {
      'tr': 'Saptanan hemogram parametreleri aşağıdadır. Doktorunuzla paylaşmadan önce doğrulayın.',
      'en': 'Detected hemogram parameters are listed below. Verify them before sharing with your doctor.',
    },
    'ocr_review_warnings': {
      'tr': 'Bazı değerler normal aralığın dışında olabilir. Lütfen kontrol edin.',
      'en': 'Some values may be outside the normal range. Please check.',
    },
    'processing': {
      'tr': 'İşleniyor...',
      'en': 'Processing...',
    },
    'confirm_values': {
      'tr': 'Değerleri Onayla',
      'en': 'Confirm Values',
    },
    'enter_value': {
      'tr': 'Değer girin',
      'en': 'Enter value',
    },
    'value_outside_normal_range': {
      'tr': 'Değer normal aralığın dışında',
      'en': 'Value is outside normal range',
    },
    // Drawer profile switcher input label
    'user_id': {
      'tr': 'Kullanıcı ID',
      'en': 'User ID',
    },
    'app_name': {
      'tr': 'HemoAI',
      'en': 'HemoAI',
      'es': 'HemoAI',
      'fr': 'HemoAI',
      'de': 'HemoAI',
      'ar': 'هيموأي',
    },
    'welcome': {
      'tr': 'Hoş Geldiniz',
      'en': 'Welcome',
      'es': 'Bienvenido',
      'fr': 'Bienvenue',
      'de': 'Willkommen',
      'ar': 'مرحباً بك',
    },
    'login': {
      'tr': 'Giriş Yap',
      'en': 'Login',
      'es': 'Iniciar Sesión',
      'fr': 'Connexion',
      'de': 'Anmelden',
      'ar': 'تسجيل الدخول',
    },
    // Common navigation labels
    'ai_analysis': {
      'tr': 'AI Analizi',
      'en': 'AI Analysis',
    },
    'personal_info': {
      'tr': 'Kişisel Bilgiler',
      'en': 'Personal Info',
    },
    'about_hemoai_title': {
      'tr': 'HemoAI Hakkında',
      'en': 'About HemoAI',
    },
    // Back-compat: some screens use 'about_hemoai' key
    'about_hemoai': {
      'tr': 'HemoAI Hakkında',
      'en': 'About HemoAI',
    },
    'health_assistant': {
      'tr': 'Sağlık Asistanı',
      'en': 'Health Assistant',
    },
    // Export Options Backup UI (Export Options screen - backup)
    'export_header_title': {
      'en': 'Export Your Reports',
      'tr': 'Raporlarınızı Export Edin',
    },
    'export_header_subtitle': {
      'en': 'Download your hemogram results, analysis reports, and reminders in PDF or Excel format',
      'tr': 'Hemogram sonuçları, analiz raporları ve hatırlatıcılarınızı PDF veya Excel formatında indirin',
    },
    'hemogram_reports': {
      'en': 'Hemogram Reports',
      'tr': 'Hemogram Raporları',
    },
    'hemogram_reports_subtitle': {
      'en': 'Export your test results as detailed reports',
      'tr': 'Test sonuçlarınızı detaylı raporlar halinde export edin',
    },
    'hemogram_pdf_report': {
      'en': 'Hemogram PDF Report',
      'tr': 'Hemogram PDF Raporu',
    },
    'hemogram_pdf_description': {
      'en': 'Detailed PDF report with reference values and analyses',
      'tr': 'Referans değerleri ve analizlerle detaylı PDF raporu',
    },
    'patient_name_default': {
      'tr': 'Hasta Adı',
      'en': 'Patient Name',
    },
    'hemogram_excel_data': {
      'en': 'Hemogram Excel Data',
      'tr': 'Hemogram Excel Verileri',
    },
    'hemogram_excel_description': {
      'en': 'Export test data in Excel format for analysis',
      'tr': 'Test verilerini Excel formatında analiz için export edin',
    },
    'analysis_reports': {
      'en': 'Analysis Reports',
      'tr': 'Analiz Raporları',
    },
    'analysis_reports_subtitle': {
      'en': 'Save AI analysis results and recommendations',
      'tr': 'AI analiz sonuçları ve önerilerinizi kaydedin',
    },
    'analysis_report_pdf': {
      'en': 'Analysis Report PDF',
      'tr': 'Analiz Raporu PDF',
    },
    'analysis_report_pdf_description': {
      'en': 'Report including AI analysis, risk assessment, and recommendations',
      'tr': 'AI analizi, risk değerlendirmesi ve önerileri içeren rapor',
    },
    'comprehensive_report': {
      'en': 'Comprehensive Report',
      'tr': 'Kapsamlı Rapor',
    },
    'comprehensive_report_subtitle': {
      'en': 'Detailed health report containing all your data',
      'tr': 'Tüm verilerinizi içeren detaylı sağlık raporu',
    },
    'comprehensive_health_report_description': {
      'en': 'Hemogram, analysis, reminders - all your data together',
      'tr': 'Hemogram, analiz, hatırlatıcılar - tüm verileriniz bir arada',
    },
    'no_analysis_data': {
      'en': 'No analysis data found',
      'tr': 'Analiz verileri bulunamadı',
    },
    'analysis_report_downloaded': {
      'en': 'Analysis report downloaded successfully',
      'tr': 'Analiz raporu başarıyla indirildi',
    },
    'analysis_report_export_failed': {
      'en': 'Analysis report export failed',
      'tr': 'Analiz raporu export işlemi başarısız',
    },
    // Missing/general export and analysis keys used across backup/export screens
    'export_options': {
      'tr': 'Dışa Aktarma Seçenekleri',
      'en': 'Export Options',
    },
    'loading_data': {
      'tr': 'Veriler yükleniyor...',
      'en': 'Loading data...',
    },
    'error_loading_data': {
      'tr': 'Veriler yüklenirken hata oluştu',
      'en': 'Error loading data',
    },
    'generated_by_hemoai': {
      'tr': 'HemoAI tarafından oluşturuldu',
      'en': 'Generated by HemoAI',
    },
    'pdf_export_success': {
      'tr': 'PDF dışa aktarma başarılı',
      'en': 'PDF export successful',
    },
    'pdf_export_failed': {
      'tr': 'PDF dışa aktarma başarısız',
      'en': 'PDF export failed',
    },
    'excel_export_success': {
      'tr': 'Excel dışa aktarma başarılı',
      'en': 'Excel export successful',
    },
    'excel_export_failed': {
      'tr': 'Excel dışa aktarma başarısız',
      'en': 'Excel export failed',
    },
    'analysis_error': {
      'tr': 'Analiz hatası',
      'en': 'Analysis error',
    },
    'unknown_risk': {
      'tr': 'Bilinmeyen risk',
      'en': 'Unknown risk',
    },
    'consult_healthcare_provider': {
      'tr': 'Lütfen bir sağlık uzmanına danışın',
      'en': 'Please consult a healthcare provider',
    },
    'consult_doctor': {
      'tr': 'Doktora danışın',
      'en': 'Consult a doctor',
    },
    
    'export_success': {
      'tr': 'Dışa aktarma başarılı',
      'en': 'Export successful',
    },
    'export_failed': {
      'tr': 'Dışa aktarma başarısız',
      'en': 'Export failed',
    },
    // Risk label used in analytics/exports
    'risk_level': {
      'tr': 'Risk seviyesi',
      'en': 'Risk level',
    },
    
    'no_hemogram_data': {
      'en': 'No hemogram data found',
      'tr': 'Hemogram verileri bulunamadı',
    },
    'no_analysis_available': {
      'tr': 'Analiz mevcut değil',
      'en': 'No analysis available',
    },
    'comprehensive_report_export_success': {
      'en': 'Comprehensive health report downloaded successfully',
      'tr': 'Kapsamlı sağlık raporu başarıyla indirildi',
    },
    'comprehensive_report_export_failed': {
      'en': 'Comprehensive report export failed',
      'tr': 'Kapsamlı rapor export işlemi başarısız',
    },
    'export_info_title': {
      'en': 'Export Information',
      'tr': 'Export Bilgileri',
    },
    'export_info_content': {
      'en': '• PDF reports include detailed analysis and reference values\n\n• Excel data is suitable for analysis and comparison\n\n• Comprehensive report presents all your data together\n\n• All reports are prepared for doctor consultation',
      'tr': '• PDF raporları detaylı analiz ve referans değerleri içerir\n\n• Excel verileri analiz ve karşılaştırma için uygundur\n\n• Kapsamlı rapor tüm verilerinizi bir arada sunar\n\n• Tüm raporlar doktor konsültasyonu için hazırlanmıştır',
    },
    // Simple labels used in analysis/entry screens
    'good': {
      'tr': 'İyi',
      'en': 'Good',
    },
    'risk': {
      'tr': 'Risk',
      'en': 'Risk',
    },
    'value': {
      'tr': 'Değer',
      'en': 'Value',
    },
    'reminders': {
      'tr': 'Hatırlatıcılar',
      'en': 'Reminders',
    },
    'register': {
      'tr': 'Kayıt Ol',
      'en': 'Register',
      'es': 'Registrarse',
      'fr': 'S\'inscrire',
      'de': 'Registrieren',
      'ar': 'تسجيل حساب',
    },
    'register_success': {
      'tr': 'Kayıt başarılı: {phone}',
      'en': 'Registration successful: {phone}',
    },
    'dashboard': {
      'tr': 'Ana Panel',
      'en': 'Dashboard',
      'es': 'Panel Principal',
      'fr': 'Tableau de Bord',
      'de': 'Dashboard',
      'ar': 'لوحة التحكم',
    },
    // Authentication / Login Screen
    'services_not_loaded': {
      'tr': 'Servisler henüz yüklenmedi, lütfen bekleyin',
      'en': 'Services not loaded yet, please wait',
      'es': 'Los servicios aún no se han cargado, espere por favor',
      'fr': 'Les services ne sont pas encore chargés, veuillez patienter',
      'de': 'Dienste noch nicht geladen, bitte warten',
      'ar': 'الخدمات لم تُحمّل بعد، يرجى الانتظار',
    },
    'enter_phone_password': {
      'tr': 'Lütfen telefon numarası ve şifre girin',
      'en': 'Please enter phone number and password',
      'es': 'Ingrese número de teléfono y contraseña',
      'fr': 'Veuillez entrer le numéro de téléphone et le mot de passe',
      'de': 'Bitte Telefonnummer und Passwort eingeben',
      'ar': 'يرجى إدخال رقم الهاتف وكلمة المرور',
    },
    'welcome_test_user': {
      'tr': 'Hoş geldiniz Test Kullanıcısı!',
      'en': 'Welcome Test User!',
      'es': '¡Bienvenido Usuario de Prueba!',
      'fr': 'Bienvenue Utilisateur Test !',
      'de': 'Willkommen Testbenutzer!',
      'ar': 'مرحباً مستخدم الاختبار!',
    },
    'welcome_generic': {
      'tr': 'Hoş geldiniz!',
      'en': 'Welcome!',
      'es': '¡Bienvenido!',
      'fr': 'Bienvenue !',
      'de': 'Willkommen!',
      'ar': 'مرحباً!',
    },
    'continue_as_guest': {
      'tr': 'Misafir Modu',
      'en': 'Guest Mode',
    },
    'guest_mode_description': {
      'tr': 'HEMOAI Misafir Modu\n\nKayıt olmadan uygulamanın temel özelliklerini deneyimleyebilirsiniz. Kişisel bilgilerinizi girip hemogram sonuçlarınızı analiz ettirebilir, tavsiye ve diyet programı alabilirsiniz.',
      'en': 'HEMOAI Guest Mode\n\nTry the core features without registration. Enter personal info, analyze your hemogram, and get advice and diet suggestions.',
    },
    'password_incorrect': {
      'tr': 'Şifre hatalı!',
      'en': 'Incorrect password!',
      'es': '¡Contraseña incorrecta!',
      'fr': 'Mot de passe incorrect !',
      'de': 'Falsches Passwort!',
      'ar': 'كلمة المرور غير صحيحة!',
    },
    'user_not_found': {
      'tr': 'Kullanıcı bulunamadı!',
      'en': 'User not found!',
      'es': '¡Usuario no encontrado!',
      'fr': 'Utilisateur introuvable !',
      'de': 'Benutzer nicht gefunden!',
      'ar': 'المستخدم غير موجود!',
    },
    'login_error_prefix': {
      'tr': 'Giriş yapılırken hata oluştu: ',
      'en': 'Error during login: ',
      'es': 'Error durante el inicio de sesión: ',
      'fr': 'Erreur lors de la connexion : ',
      'de': 'Fehler beim Anmelden: ',
      'ar': 'حدث خطأ أثناء تسجيل الدخول: ',
    },
    'phone_number_label': {
      'tr': 'Telefon Numarası',
      'en': 'Phone Number',
      'es': 'Número de Teléfono',
      'fr': 'Numéro de Téléphone',
      'de': 'Telefonnummer',
      'ar': 'رقم الهاتف',
    },
    'password_label': {
      'tr': 'Şifre',
      'en': 'Password',
      'es': 'Contraseña',
      'fr': 'Mot de Passe',
      'de': 'Passwort',
      'ar': 'كلمة المرور',
    },
    'test_credentials_hint': {
      'tr': 'Test için:\nTelefon: 5551234567\nŞifre: 1234',
      'en': 'For test:\nPhone: 5551234567\nPassword: 1234',
      'es': 'Para prueba:\nTeléfono: 5551234567\nContraseña: 1234',
      'fr': 'Pour test :\nTéléphone : 5551234567\nMot de passe : 1234',
      'de': 'Für Test:\nTelefon: 5551234567\nPasswort: 1234',
      'ar': 'للاختبار:\nالهاتف: 5551234567\nكلمة المرور: 1234',
    },
    // Registration Screen
    'register_appbar_title': {
      'tr': 'Üye Ol',
      'en': 'Register',
      'es': 'Registrarse',
      'fr': 'S\'inscrire',
      'de': 'Registrieren',
      'ar': 'تسجيل',
    },
    'register_heading': {
      'tr': 'Üye Olun',
      'en': 'Create Account',
      'es': 'Crea tu Cuenta',
      'fr': 'Créez votre Compte',
      'de': 'Konto Erstellen',
      'ar': 'إنشاء حساب',
    },
    'register_subheading': {
      'tr': 'HemoAI ile sağlığınızı takip edin',
      'en': 'Track your health with HemoAI',
      'es': 'Controla tu salud con HemoAI',
      'fr': 'Suivez votre santé avec HemoAI',
      'de': 'Verfolge deine Gesundheit mit HemoAI',
      'ar': 'راقب صحتك مع HemoAI',
    },
    'name_label': {
      'tr': 'Ad Soyad',
      'en': 'Full Name',
      'es': 'Nombre Completo',
      'fr': 'Nom Complet',
      'de': 'Vollständiger Name',
      'ar': 'الاسم الكامل',
    },
    'name_required': {
      'tr': 'Lütfen ad soyad giriniz',
      'en': 'Please enter full name',
      'es': 'Ingrese nombre completo',
      'fr': 'Veuillez entrer le nom complet',
      'de': 'Bitte vollständigen Namen eingeben',
      'ar': 'يرجى إدخال الاسم الكامل',
    },
    // 'personal_info' key already defined earlier under common navigation labels
    'age_label': {
      'tr': 'Yaş',
      'en': 'Age',
    },
    'gender': {
      'tr': 'Cinsiyet',
      'en': 'Gender',
    },
    'male': {
      'tr': 'Erkek',
      'en': 'Male',
    },
    'female': {
      'tr': 'Kadın',
      'en': 'Female',
    },
    // 'weight_kg' and 'height_cm' defined earlier
    'calculate_bmi': {
      'tr': 'VKİ Hesapla',
      'en': 'Calculate BMI',
    },
    'bmi': {
      'tr': 'VKİ',
      'en': 'BMI',
    },
    'continue': {
      'tr': 'Devam Et',
      'en': 'Continue',
    },
    'phone_hint': {
      'tr': '05XXXXXXXXX',
      'en': 'Ex: 5551234567',
      'es': 'Ej: 5551234567',
      'fr': 'Ex : 5551234567',
      'de': 'Bsp: 5551234567',
      'ar': 'مثال: 5551234567',
    },
    'phone_required': {
      'tr': 'Lütfen telefon numarası giriniz',
      'en': 'Please enter phone number',
      'es': 'Ingrese número de teléfono',
      'fr': 'Veuillez entrer le numéro de téléphone',
      'de': 'Bitte Telefonnummer eingeben',
      'ar': 'يرجى إدخال رقم الهاتف',
    },
    'phone_invalid': {
      'tr': 'Geçerli telefon numarası giriniz',
      'en': 'Enter a valid phone number',
      'es': 'Ingrese un número válido',
      'fr': 'Entrez un numéro valide',
      'de': 'Gültige Telefonnummer eingeben',
      'ar': 'أدخل رقم هاتف صالح',
    },
    'password_required': {
      'tr': 'Lütfen şifre giriniz',
      'en': 'Please enter password',
      'es': 'Ingrese contraseña',
      'fr': 'Veuillez entrer le mot de passe',
      'de': 'Bitte Passwort eingeben',
      'ar': 'يرجى إدخال كلمة المرور',
    },
    'password_min_length': {
      'tr': 'Şifre en az 4 karakter olmalı',
      'en': 'Password must be at least 4 characters',
      'es': 'La contraseña debe tener al menos 4 caracteres',
      'fr': 'Le mot de passe doit contenir au moins 4 caractères',
      'de': 'Passwort muss mindestens 4 Zeichen haben',
      'ar': 'يجب أن تتكون كلمة المرور من 4 أحرف على الأقل',
    },
    'password_confirm_label': {
      'tr': 'Şifre Tekrar',
      'en': 'Confirm Password',
      'es': 'Confirmar Contraseña',
      'fr': 'Confirmer le Mot de Passe',
      'de': 'Passwort Bestätigen',
      'ar': 'تأكيد كلمة المرور',
    },
    'password_confirm_required': {
      'tr': 'Lütfen şifreyi tekrar giriniz',
      'en': 'Please re-enter password',
      'es': 'Vuelva a ingresar la contraseña',
      'fr': 'Veuillez ressaisir le mot de passe',
      'de': 'Bitte Passwort erneut eingeben',
      'ar': 'يرجى إعادة إدخال كلمة المرور',
    },
    'password_mismatch': {
      'tr': 'Şifreler eşleşmiyor',
      'en': 'Passwords do not match',
      'es': 'Las contraseñas no coinciden',
      'fr': 'Les mots de passe ne correspondent pas',
      'de': 'Passwörter stimmen nicht überein',
      'ar': 'كلمات المرور غير متطابقة',
    },
    'phone_exists': {
      'tr': 'Bu telefon numarası ile kayıtlı kullanıcı zaten mevcut!',
      'en': 'A user with this phone number already exists!',
      'es': '¡Ya existe un usuario con este número!',
      'fr': 'Un utilisateur avec ce numéro existe déjà !',
      'de': 'Benutzer mit dieser Telefonnummer existiert bereits!',
      'ar': 'يوجد مستخدم بهذا الرقم مسبقاً!',
    },
    'registration_success': {
      'tr': 'Kayıt başarılı! Profilinizi tamamlayın.',
      'en': 'Registration successful! Complete your profile.',
      'es': 'Registro exitoso. Complete su perfil.',
      'fr': 'Inscription réussie. Complétez votre profil.',
      'de': 'Registrierung erfolgreich! Profil vervollständigen.',
      'ar': 'تم التسجيل بنجاح! أكمل ملفك.',
    },
    'registration_error_prefix': {
      'tr': 'Kayıt sırasında hata oluştu: ',
      'en': 'Error during registration: ',
      'es': 'Error durante el registro: ',
      'fr': 'Erreur lors de l\'inscription : ',
      'de': 'Fehler bei der Registrierung: ',
      'ar': 'حدث خطأ أثناء التسجيل: ',
    },
    // Forgot password & BMI labels
    'forgot_password': {
      'tr': 'Şifremi Unuttum',
      'en': 'Forgot Password',
      'es': 'Olvidé mi Contraseña',
      'fr': 'Mot de Passe Oublié',
      'de': 'Passwort Vergessen',
      'ar': 'نسيت كلمة المرور',
    },
    'forgot_password_coming_soon': {
      'tr': 'Şifre sıfırlama özelliği yakında eklenecek',
      'en': 'Password reset feature coming soon',
      'es': 'La función de restablecer contraseña llegará pronto',
      'fr': 'La réinitialisation du mot de passe arrive bientôt',
      'de': 'Passwort-Zurücksetzen Funktion kommt bald',
      'ar': 'ميزة إعادة تعيين كلمة المرور قادمة قريباً',
    },
    'bmi_label': {
      'tr': 'VKİ',
      'en': 'BMI',
      'es': 'IMC',
      'fr': 'IMC',
      'de': 'BMI',
      'ar': 'مؤشر كتلة الجسم',
    },
    // Add Reminder Screen
    'add_reminder': {
      'tr': 'Hatırlatıcı Ekle',
      'en': 'Add Reminder',
      'es': 'Agregar Recordatorio',
      'fr': 'Ajouter un Rappel',
      'de': 'Erinnerung hinzufügen',
      'ar': 'إضافة تذكير',
    },
    'new_reminder': {
      'tr': 'Yeni Hatırlatıcı',
      'en': 'New Reminder',
      'es': 'Nuevo Recordatorio',
      'fr': 'Nouveau Rappel',
      'de': 'Neue Erinnerung',
      'ar': 'تذكير جديد',
    },
    'reminder_header_description': {
      'tr': 'İlaç, randevu, test ve diğer önemli konular için hatırlatıcı oluşturun',
      'en': 'Create reminders for medications, appointments, tests and other important items',
      'es': 'Cree recordatorios para medicamentos, citas, pruebas y otros elementos importantes',
      'fr': 'Créez des rappels pour les médicaments, rendez-vous, tests et autres éléments importants',
      'de': 'Erstellen Sie Erinnerungen für Medikamente, Termine, Tests und andere wichtige Dinge',
      'ar': 'أنشئ تذكيرات للأدوية والمواعيد والاختبارات وغيرها من العناصر المهمة',
    },
    'reminder_title_label': {
      'tr': 'Hatırlatıcı Başlığı *',
      'en': 'Reminder Title *',
      'es': 'Título del Recordatorio *',
      'fr': 'Titre du Rappel *',
      'de': 'Erinnerungstitel *',
      'ar': 'عنوان التذكير *',
    },
    'reminder_title_hint': {
      'tr': 'Örn: Aspirin Al',
      'en': 'Ex: Take Aspirin',
      'es': 'Ej: Tomar Aspirina',
      'fr': 'Ex: Prendre Aspirine',
      'de': 'Bsp: Aspirin nehmen',
      'ar': 'مثال: تناول الأسبرين',
    },
    'reminder_title_validate': {
      'tr': 'Lütfen hatırlatıcı başlığını girin',
      'en': 'Please enter a reminder title',
      'es': 'Por favor ingrese un título',
      'fr': 'Veuillez entrer un titre',
      'de': 'Bitte geben Sie einen Titel ein',
      'ar': 'يرجى إدخال عنوان التذكير',
    },
    'reminder_description_label': {
      'tr': 'Açıklama *',
      'en': 'Description *',
      'es': 'Descripción *',
      'fr': 'Description *',
      'de': 'Beschreibung *',
      'ar': 'الوصف *',
    },
    'reminder_description_hint': {
      'tr': 'Detayları buraya yazın...',
      'en': 'Write details here...',
      'es': 'Escriba los detalles aquí...',
      'fr': 'Écrivez les détails ici...',
      'de': 'Details hier eingeben...',
      'ar': 'اكتب التفاصيل هنا...',
    },
    'reminder_description_validate': {
      'tr': 'Lütfen açıklama girin',
      'en': 'Please enter a description',
      'es': 'Por favor ingrese una descripción',
      'fr': 'Veuillez entrer une description',
      'de': 'Bitte geben Sie eine Beschreibung ein',
      'ar': 'يرجى إدخال وصف',
    },
    'reminder_type_label': {
      'tr': 'Hatırlatıcı Türü',
      'en': 'Reminder Type',
      'es': 'Tipo de Recordatorio',
      'fr': 'Type de Rappel',
      'de': 'Erinnerungsart',
      'ar': 'نوع التذكير',
    },
    'date_label': {
      'tr': 'Tarih',
      'en': 'Date',
      'es': 'Fecha',
      'fr': 'Date',
      'de': 'Datum',
      'ar': 'التاريخ',
    },
    'time_label': {
      'tr': 'Saat',
      'en': 'Time',
      'es': 'Hora',
      'fr': 'Heure',
      'de': 'Uhrzeit',
      'ar': 'الوقت',
    },
    'repeat_label': {
      'tr': 'Tekrar',
      'en': 'Repeat',
      'es': 'Repetir',
      'fr': 'Répétition',
      'de': 'Wiederholen',
      'ar': 'تكرار',
    },
    'repeat_none': {
      'tr': 'Tekrarlamaz',
      'en': 'No Repeat',
      'es': 'Sin repetición',
      'fr': 'Pas de répétition',
      'de': 'Keine Wiederholung',
      'ar': 'بدون تكرار',
    },
    'repeat_daily': {
      'tr': 'Günlük',
      'en': 'Daily',
      'es': 'Diario',
      'fr': 'Quotidien',
      'de': 'Täglich',
      'ar': 'يومي',
    },
    'repeat_weekly': {
      'tr': 'Haftalık',
      'en': 'Weekly',
      'es': 'Semanal',
      'fr': 'Hebdomadaire',
      'de': 'Wöchentlich',
      'ar': 'أسبوعي',
    },
    'repeat_monthly': {
      'tr': 'Aylık',
      'en': 'Monthly',
      'es': 'Mensual',
      'fr': 'Mensuel',
      'de': 'Monatlich',
      'ar': 'شهري',
    },
    'reminder_type_medication': {
      'tr': 'İlaç Hatırlatıcısı',
      'en': 'Medication Reminder',
      'es': 'Recordatorio de Medicación',
      'fr': 'Rappel Médicament',
      'de': 'Medikationserinnerung',
      'ar': 'تذكير بالدواء',
    },
    'reminder_type_test': {
      'tr': 'Test/Tahlil',
      'en': 'Lab/Test',
      'es': 'Prueba/Análisis',
      'fr': 'Test/Analyse',
      'de': 'Test/Analyse',
      'ar': 'تحليل/فحص',
    },
    'reminder_type_appointment': {
      'tr': 'Randevu',
      'en': 'Appointment',
      'es': 'Cita',
      'fr': 'Rendez-vous',
      'de': 'Termin',
      'ar': 'موعد',
    },
    'reminder_type_general_reminder': {
      'tr': 'Genel Hatırlatıcı',
      'en': 'General Reminder',
      'es': 'Recordatorio General',
      'fr': 'Rappel Général',
      'de': 'Allgemeine Erinnerung',
      'ar': 'تذكير عام',
    },
    'reminder_type_general': {
      'tr': 'Genel',
      'en': 'General',
      'es': 'General',
      'fr': 'Général',
      'de': 'Allgemein',
      'ar': 'عام',
    },
    'reminder_added_success': {
      'tr': 'Hatırlatıcı başarıyla eklendi!',
      'en': 'Reminder added successfully!',
      'es': '¡Recordatorio agregado con éxito!',
      'fr': 'Rappel ajouté avec succès !',
      'de': 'Erinnerung erfolgreich hinzugefügt!',
      'ar': 'تمت إضافة التذكير بنجاح!',
    },
    'error_prefix': {
      'tr': 'Hata: ',
      'en': 'Error: ',
      'es': 'Error: ',
      'fr': 'Erreur : ',
      'de': 'Fehler: ',
      'ar': 'خطأ: ',
    },
    'save_reminder_button': {
      'tr': 'Hatırlatıcıyı Kaydet',
      'en': 'Save Reminder',
      'es': 'Guardar Recordatorio',
      'fr': 'Enregistrer le Rappel',
      'de': 'Erinnerung speichern',
      'ar': 'حفظ التذكير',
    },
    // Reminder List Screen additions
    'reminders_title': {
      'en': 'Reminders',
      'tr': 'Hatırlatıcılar',
    },
    'reminder_tab_upcoming': {
      'en': 'Upcoming',
      'tr': 'Yaklaşan',
    },
    'reminder_tab_overdue': {
      'en': 'Overdue',
      'tr': 'Geciken',
    },
    'reminder_tab_completed': {
      'en': 'Completed',
      'tr': 'Tamamlanan',
    },
    'reminder_empty_upcoming': {
      'en': 'No upcoming reminders',
      'tr': 'Yaklaşan hatırlatıcınız yok',
    },
    'reminder_empty_overdue': {
      'en': 'No overdue reminders',
      'tr': 'Geciken hatırlatıcınız yok',
    },
    'reminder_empty_completed': {
      'en': 'No completed reminders',
      'tr': 'Tamamlanan hatırlatıcınız yok',
    },
    'reminder_time_label': {
      'en': 'Time',
      'tr': 'Zamanı',
    },
    'reminder_description_heading': {
      'en': 'Description',
      'tr': 'Açıklama',
    },
    'reminder_action_pause': {
      'en': 'Pause',
      'tr': 'Duraklat',
    },
    'reminder_action_activate': {
      'en': 'Activate',
      'tr': 'Etkinleştir',
    },
    'reminder_deleted': {
      'en': 'Reminder deleted',
      'tr': 'Hatırlatıcı silindi',
    },
    'reminder_badge_overdue': {
      'en': 'LATE',
      'tr': 'GEÇ',
    },
    'date_today': {
      'en': 'Today',
      'tr': 'Bugün',
    },
    'date_tomorrow': {
      'en': 'Tomorrow',
      'tr': 'Yarın',
    },
    'date_yesterday': {
      'en': 'Yesterday',
      'tr': 'Dün',
    },
    'menu': {
      'tr': 'Menü',
      'en': 'Menu',
      'es': 'Menú',
      'fr': 'Menu',
      'de': 'Menü',
      'ar': 'القائمة',
    },
    'hemogram_entry': {
      'tr': 'Hemogram Girişi',
      'en': 'Hemogram Entry',
      'es': 'Entrada de Hemograma',
      'fr': 'Saisie d\'Hémogramme',
      'de': 'Hämogramm Eingabe',
      'ar': 'إدخال تعداد الدم',
    },
    'analysis': {
      'tr': 'Analiz',
      'en': 'Analysis',
      'es': 'Análisis',
      'fr': 'Analyse',
      'de': 'Analyse',
      'ar': 'تحليل',
    },
    'results': {
      'tr': 'Sonuçlar',
      'en': 'Results',
      'es': 'Resultados',
      'fr': 'Résultats',
      'de': 'Ergebnisse',
      'ar': 'النتائج',
    },
    // Full Results screen
    'full_results_title': {
      'tr': 'Tüm Sonuçlar',
      'en': 'Full Results',
    },
    'no_results_available': {
      'tr': 'Gösterilecek sonuç yok',
      'en': 'No results to display',
    },
    'view_full_results': {
      'tr': 'Tüm sonuçları gör',
      'en': 'View full results',
    },
    // Section titles
    'cbc': {
      'tr': 'Tam Kan Sayımı (CBC)',
      'en': 'Complete Blood Count (CBC)',
    },
    // Recommendation and analysis phrases for exports/backups
    'abnormal_wbc': {
      'tr': 'Anormal beyaz kan hücresi düzeyi',
      'en': 'Abnormal white blood cell level',
    },
    'abnormal_hemoglobin': {
      'tr': 'Anormal hemoglobin düzeyi',
      'en': 'Abnormal hemoglobin level',
    },
    'check_iron_levels': {
      'tr': 'Demir seviyelerinizi kontrol edin',
      'en': 'Check your iron levels',
    },
    'abnormal_platelets': {
      'tr': 'Anormal trombosit düzeyi',
      'en': 'Abnormal platelet level',
    },
    'monitor_bleeding': {
      'tr': 'Kanama belirtilerini takip edin',
      'en': 'Monitor for bleeding',
    },
    'normal_values': {
      'tr': 'Normal değerler',
      'en': 'Normal values',
    },
    'maintain_healthy_lifestyle': {
      'tr': 'Sağlıklı yaşam tarzını sürdürün',
      'en': 'Maintain a healthy lifestyle',
    },
    'wbc_differential': {
      'tr': 'Beyaz Kan Hücresi Dağılımı',
      'en': 'White Blood Cell Differential',
    },
    'iron_studies': {
      'tr': 'Demir Tetkikleri',
      'en': 'Iron Studies',
    },
    'liver_function': {
      'tr': 'Karaciğer Fonksiyonları',
      'en': 'Liver Function',
    },
    'kidney_function': {
      'tr': 'Böbrek Fonksiyonları',
      'en': 'Kidney Function',
    },
    'lipid_profile': {
      'tr': 'Lipid Profili',
      'en': 'Lipid Profile',
    },
    'diabetes_markers': {
      'tr': 'Diyabet Göstergeleri',
      'en': 'Diabetes Markers',
    },
    'thyroid_function': {
      'tr': 'Tiroid Fonksiyonları',
      'en': 'Thyroid Function',
    },
    'electrolytes': {
      'tr': 'Elektrolitler',
      'en': 'Electrolytes',
    },
    'vitamins': {
      'tr': 'Vitaminler',
      'en': 'Vitamins',
    },
    'tumor_markers': {
      'tr': 'Tümör Belirteçleri',
      'en': 'Tumor Markers',
    },
    'cardiac_markers': {
      'tr': 'Kardiyak Belirteçler',
      'en': 'Cardiac Markers',
    },
    'inflammatory_markers': {
      'tr': 'İnflamasyon Belirteçleri',
      'en': 'Inflammatory Markers',
    },
    'hormones': {
      'tr': 'Hormonlar',
      'en': 'Hormones',
    },
    
    // Blood Test Parameter Labels
    // CBC Parameters
    'hemoglobin': {
      'tr': 'Hemoglobin',
      'en': 'Hemoglobin',
    },
    'hematocrit': {
      'tr': 'Hematokrit',
      'en': 'Hematocrit',
    },
    'red_blood_cells': {
      'tr': 'Alyuvar',
      'en': 'Red Blood Cells',
    },
    'white_blood_cells': {
      'tr': 'Akyuvar',
      'en': 'White Blood Cells',
    },
    'platelets': {
      'tr': 'Trombosit',
      'en': 'Platelets',
    },
    'mcv': {
      'tr': 'MCV',
      'en': 'MCV',
    },
    'mch': {
      'tr': 'MCH',
      'en': 'MCH',
    },
    'mchc': {
      'tr': 'MCHC',
      'en': 'MCHC',
    },
    'rdw': {
      'tr': 'RDW',
      'en': 'RDW',
    },
    'mpv': {
      'tr': 'MPV',
      'en': 'MPV',
    },
    
    // White Blood Cell Differential
    'neutrophils': {
      'tr': 'Nötrofil',
      'en': 'Neutrophils',
    },
    'lymphocytes': {
      'tr': 'Lenfosit',
      'en': 'Lymphocytes',
    },
    'monocytes': {
      'tr': 'Monosit',
      'en': 'Monocytes',
    },
    'eosinophils': {
      'tr': 'Eozinofil',
      'en': 'Eosinophils',
    },
    'basophils': {
      'tr': 'Bazofil',
      'en': 'Basophils',
    },
    
    // Iron Studies
    'iron': {
      'tr': 'Demir',
      'en': 'Iron',
    },
    'ferritin': {
      'tr': 'Ferritin',
      'en': 'Ferritin',
    },
    'transferrin': {
      'tr': 'Transferrin',
      'en': 'Transferrin',
    },
    'tibc': {
      'tr': 'TIBC',
      'en': 'TIBC',
    },
    'transferrin_saturation': {
      'tr': 'Transferrin Doygunluğu',
      'en': 'Transferrin Saturation',
    },
    
    // Liver Function
    'alt': {
      'tr': 'ALT',
      'en': 'ALT',
    },
    'ast': {
      'tr': 'AST',
      'en': 'AST',
    },
    'alp': {
      'tr': 'ALP',
      'en': 'ALP',
    },
    'ggt': {
      'tr': 'GGT',
      'en': 'GGT',
    },
    'bilirubin': {
      'tr': 'Bilirubin',
      'en': 'Bilirubin',
    },
    'direct_bilirubin': {
      'tr': 'Direkt Bilirubin',
      'en': 'Direct Bilirubin',
    },
    'albumin': {
      'tr': 'Albumin',
      'en': 'Albumin',
    },
    'total_protein': {
      'tr': 'Toplam Protein',
      'en': 'Total Protein',
    },
    
    // Kidney Function
    'creatinine': {
      'tr': 'Kreatinin',
      'en': 'Creatinine',
    },
    'urea': {
      'tr': 'Üre',
      'en': 'Urea',
    },
    'uric_acid': {
      'tr': 'Ürik Asit',
      'en': 'Uric Acid',
    },
    'gfr': {
      'tr': 'GFR',
      'en': 'GFR',
    },
    
    // Lipid Profile
    'total_cholesterol': {
      'tr': 'Toplam Kolesterol',
      'en': 'Total Cholesterol',
    },
    'ldl_cholesterol': {
      'tr': 'LDL Kolesterol',
      'en': 'LDL Cholesterol',
    },
    'hdl_cholesterol': {
      'tr': 'HDL Kolesterol',
      'en': 'HDL Cholesterol',
    },
    'triglycerides': {
      'tr': 'Trigliserit',
      'en': 'Triglycerides',
    },
    'non_hdl_cholesterol': {
      'tr': 'Non-HDL Kolesterol',
      'en': 'Non-HDL Cholesterol',
    },
    
    // Diabetes Markers
    'glucose': {
      'tr': 'Glukoz',
      'en': 'Glucose',
    },
    'hba1c': {
      'tr': 'HbA1c',
      'en': 'HbA1c',
    },
    'fructosamine': {
      'tr': 'Fruktosamin',
      'en': 'Fructosamine',
    },
    
    // Thyroid Function
    'tsh': {
      'tr': 'TSH',
      'en': 'TSH',
    },
    't3': {
      'tr': 'T3',
      'en': 'T3',
    },
    't4': {
      'tr': 'T4',
      'en': 'T4',
    },
    'free_t3': {
      'tr': 'Serbest T3',
      'en': 'Free T3',
    },
    'free_t4': {
      'tr': 'Serbest T4',
      'en': 'Free T4',
    },
    
    // Electrolytes
    'sodium': {
      'tr': 'Sodyum',
      'en': 'Sodium',
    },
    'potassium': {
      'tr': 'Potasyum',
      'en': 'Potassium',
    },
    'chloride': {
      'tr': 'Klorür',
      'en': 'Chloride',
    },
    'calcium': {
      'tr': 'Kalsiyum',
      'en': 'Calcium',
    },
    'magnesium': {
      'tr': 'Magnezyum',
      'en': 'Magnesium',
    },
    'phosphorus': {
      'tr': 'Fosfor',
      'en': 'Phosphorus',
    },
    
    // Vitamins
    'vitamin_b12': {
      'tr': 'Vitamin B12',
      'en': 'Vitamin B12',
    },
    'vitamin_d': {
      'tr': 'Vitamin D',
      'en': 'Vitamin D',
    },
    'folate': {
      'tr': 'Folat',
      'en': 'Folate',
    },
    'vitamin_a': {
      'tr': 'Vitamin A',
      'en': 'Vitamin A',
    },
    'vitamin_e': {
      'tr': 'Vitamin E',
      'en': 'Vitamin E',
    },
    'vitamin_c': {
      'tr': 'Vitamin C',
      'en': 'Vitamin C',
    },
    
    // Tumor Markers
    'cea': {
      'tr': 'CEA',
      'en': 'CEA',
    },
    'afp': {
      'tr': 'AFP',
      'en': 'AFP',
    },
    'ca125': {
      'tr': 'CA 125',
      'en': 'CA 125',
    },
    'ca199': {
      'tr': 'CA 19-9',
      'en': 'CA 19-9',
    },
    'ca153': {
      'tr': 'CA 15-3',
      'en': 'CA 15-3',
    },
    'psa': {
      'tr': 'PSA',
      'en': 'PSA',
    },
    
    // Cardiac Markers
    'troponin': {
      'tr': 'Troponin',
      'en': 'Troponin',
    },
    'ck_mb': {
      'tr': 'CK-MB',
      'en': 'CK-MB',
    },
    'ldh': {
      'tr': 'LDH',
      'en': 'LDH',
    },
    'bnp': {
      'tr': 'BNP',
      'en': 'BNP',
    },
    
    // Inflammatory Markers
    'crp': {
      'tr': 'CRP',
      'en': 'CRP',
    },
    'esr': {
      'tr': 'ESR',
      'en': 'ESR',
    },
    'procalcitonin': {
      'tr': 'Prokalsitonin',
      'en': 'Procalcitonin',
    },
    
    // Hormones
    'insulin': {
      'tr': 'İnsülin',
      'en': 'Insulin',
    },
    'cortisol': {
      'tr': 'Kortizol',
      'en': 'Cortisol',
    },
    'testosterone': {
      'tr': 'Testosteron',
      'en': 'Testosterone',
    },
    'estradiol': {
      'tr': 'Estradiol',
      'en': 'Estradiol',
    },
    'progesterone': {
      'tr': 'Progesteron',
      'en': 'Progesterone',
    },
    'prolactin': {
      'tr': 'Prolaktin',
      'en': 'Prolactin',
    },
    'fsh': {
      'tr': 'FSH',
      'en': 'FSH',
    },
    'lh': {
      'tr': 'LH',
      'en': 'LH',
    },
    
    // Additional keys for Full Results screen
    'test_results_summary': {
      'tr': 'Test Sonuçları Özeti',
      'en': 'Test Results Summary',
    },
    'import_test_results': {
      'tr': 'Test Sonuçlarını İçe Aktar',
      'en': 'Import Test Results',
    },
    'share_results': {
      'tr': 'Sonuçları Paylaş',
      'en': 'Share Results',
    },
    'share_feature_coming_soon': {
      'tr': 'Paylaşım özelliği yakında!',
      'en': 'Share feature coming soon!',
    },
    'laboratory_name': {
      'tr': 'Laboratuvar Adı',
      'en': 'Laboratory Name',
    },
    'doctor_name': {
      'tr': 'Doktor Adı',
      'en': 'Doctor Name',
    },
    'test_type': {
      'tr': 'Test Türü',
      'en': 'Test Type',
    },
    
    'diet_program': {
      'tr': 'Diyet Programı',
      'en': 'Diet Program',
      'es': 'Programa de Dieta',
      'fr': 'Programme de Régime',
      'de': 'Diätprogramm',
      'ar': 'برنامج الحمية',
    },
    // Diet program weekly planner additions
    'personal_diet_program': {
      'tr': 'Kişisel Diyet Programı',
      'en': 'Personal Diet Program',
    },
    'diet_recommendations_title': {
      'tr': 'Diyet Önerileri',
      'en': 'Diet Recommendations',
    },
    'diet_program_description': {
      'tr': 'Hemogram değerlerinize ve yaş grubunuza göre önerilen beslenme planı.',
      'en': 'Recommended nutrition plan based on your hemogram and age group.',
    },
    'suitable_for_age': {
      'tr': '{age_group} için uygun',
      'en': 'Suitable for {age_group}',
    },
    'weekly_plan': {
      'tr': 'Haftalık Plan',
      'en': 'Weekly Plan',
    },
    'week_completed_congrats': {
      'tr': 'Haftayı tamamladınız! 🎉',
      'en': 'Week completed! 🎉',
    },
    'month_completed_congrats': {
      'tr': 'Bir ayı tamamladınız! Tebrikler! 🎉',
      'en': 'You completed a month! Congratulations! 🎉',
    },
    'mark_done': {
      'tr': 'Tamamlandı olarak işaretle',
      'en': 'Mark as done',
    },
    'mark_undone': {
      'tr': 'Tamamlandı işaretini kaldır',
      'en': 'Marked done ✓',
    },
    'week_progress': {
      'tr': 'Hafta ilerlemesi',
      'en': 'Week progress',
    },
    'weeks_completed': {
      'tr': 'Tamamlanan hafta',
      'en': 'Weeks completed',
    },
    'sunday': {
      'tr': 'Pazar',
      'en': 'Sunday',
    },
    'monday': {
      'tr': 'Pazartesi',
      'en': 'Monday',
    },
    'tuesday': {
      'tr': 'Salı',
      'en': 'Tuesday',
    },
    'wednesday': {
      'tr': 'Çarşamba',
      'en': 'Wednesday',
    },
    'thursday': {
      'tr': 'Perşembe',
      'en': 'Thursday',
    },
    'friday': {
      'tr': 'Cuma',
      'en': 'Friday',
    },
    'saturday': {
      'tr': 'Cumartesi',
      'en': 'Saturday',
    },
    'schedule_daily_reminder': {
      'tr': 'Günlük hatırlatıcı planla',
      'en': 'Schedule Daily Reminder',
    },
    'schedule_weekly_reminders': {
      'tr': 'Haftalık hatırlatıcıları planla',
      'en': 'Schedule Weekly Reminders',
    },
    'weekly_reminders_scheduled': {
      'tr': '{count} haftalık hatırlatıcı planlandı',
      'en': '{count} weekly reminders scheduled',
    },
    'weekly_reminders_failed': {
      'tr': 'Haftalık hatırlatıcılar planlanamadı',
      'en': 'Failed to schedule weekly reminders',
    },
    'family_panel': {
      'tr': 'Aile Paneli',
      'en': 'Family Panel',
      'es': 'Panel Familiar',
      'fr': 'Panneau Familial',
      'de': 'Familien Panel',
      'ar': 'لوحة العائلة',
    },
    // Family details sheet additions
    'family_personal_info': {
      'tr': 'Kişisel Bilgiler',
      'en': 'Personal Information',
    },
    'family_connection_status': {
      'tr': 'Bağlantı Durumu',
      'en': 'Connection Status',
    },
    'family_connected': {
      'tr': 'Bağlı',
      'en': 'Connected',
    },
    'family_manual_entry': {
      'tr': 'Manuel Giriş',
      'en': 'Manual Entry',
    },
    'family_last_update': {
      'tr': 'Son Güncelleme',
      'en': 'Last Update',
    },
    'family_never': {
      'tr': 'Hiç',
      'en': 'Never',
    },
    'family_actions': {
      'tr': 'İşlemler',
      'en': 'Actions',
    },
    'notifications': {
      'tr': 'Bildirimler',
      'en': 'Notifications',
      'es': 'Notificaciones',
      'fr': 'Notifications',
      'de': 'Benachrichtigungen',
      'ar': 'الإشعارات',
    },
    'settings': {
      'tr': 'Ayarlar',
      'en': 'Settings',
      'es': 'Configuración',
      'fr': 'Paramètres',
      'de': 'Einstellungen',
      'ar': 'الإعدادات',
    },
    // Family Panel enhancements
    'family_search_members': {
      'tr': 'Aile üyelerinde ara',
      'en': 'Search family members',
    },
    'family_stat_members': {
      'tr': 'Üye Sayısı',
      'en': 'Members',
    },
    'family_stat_invites': {
      'tr': 'Bekleyen Davet',
      'en': 'Pending Invites',
    },
    'family_stat_water_avg': {
      'tr': 'Su (7g ort.)',
      'en': 'Water (7d avg.)',
    },
    'family_leaderboard_title': {
      'tr': 'Su Tüketimi Lider Tablosu',
      'en': 'Water Intake Leaderboard',
    },
    'family_no_data': {
      'tr': 'Veri yok',
      'en': 'No data',
    },
    'family_copy_phone': {
      'tr': 'Telefonu kopyala',
      'en': 'Copy phone',
    },
    'family_phone_copied': {
      'tr': 'Telefon kopyalandı',
      'en': 'Phone copied',
    },
    'family_add_water': {
      'tr': '1 bardak su ekle',
      'en': 'Add 1 glass of water',
    },
    'language': {
      'tr': 'Dil',
      'en': 'Language',
      'es': 'Idioma',
      'fr': 'Langue',
      'de': 'Sprache',
      'ar': 'اللغة',
    },
    'theme': {
      'tr': 'Tema',
      'en': 'Theme',
      'es': 'Tema',
      'fr': 'Thème',
      'de': 'Design',
      'ar': 'المظهر',
    },
    'dark_theme': {
      'tr': 'Karanlık Tema',
      'en': 'Dark Theme',
      'es': 'Tema Oscuro',
      'fr': 'Thème Sombre',
      'de': 'Dunkles Design',
      'ar': 'المظهر الداكن',
    },
    'light_theme': {
      'tr': 'Aydınlık Tema',
      'en': 'Light Theme',
      'es': 'Tema Claro',
      'fr': 'Thème Clair',
      'de': 'Helles Design',
      'ar': 'المظهر الفاتح',
    },
    'save': {
      'tr': 'Kaydet',
      'en': 'Save',
      'es': 'Guardar',
      'fr': 'Sauvegarder',
      'de': 'Speichern',
      'ar': 'حفظ',
    },
    'cancel': {
      'tr': 'İptal',
      'en': 'Cancel',
      'es': 'Cancelar',
      'fr': 'Annuler',
      'de': 'Abbrechen',
      'ar': 'إلغاء',
    },
    'ok': {
      'tr': 'Tamam',
      'en': 'OK',
      'es': 'OK',
      'fr': 'OK',
      'de': 'OK',
      'ar': 'موافق',
    },
    'yes': {
      'tr': 'Evet',
      'en': 'Yes',
      'es': 'Sí',
      'fr': 'Oui',
      'de': 'Ja',
      'ar': 'نعم',
    },
    'no': {
      'tr': 'Hayır',
      'en': 'No',
      'es': 'No',
      'fr': 'Non',
      'de': 'Nein',
      'ar': 'لا',
    },
    // Snooze actions
    'snooze_30m': {
      'tr': '30 dk ertele',
      'en': 'Snooze 30m',
    },
    'snooze_60m': {
      'tr': '60 dk ertele',
      'en': 'Snooze 60m',
    },
    'snoozed_for_30': {
      'tr': '30 dakika ertelendi',
      'en': 'Snoozed for 30 minutes',
    },
    'snoozed_for_60': {
      'tr': '60 dakika ertelendi',
      'en': 'Snoozed for 60 minutes',
    },
    // Custom snooze picker
    'custom_snooze': {
      'tr': 'Özel erteleme',
      'en': 'Custom snooze',
    },
    'snooze_15m': {
      'tr': '15 dk ertele',
      'en': 'Snooze 15m',
    },
    'snooze_2h': {
      'tr': '2 sa ertele',
      'en': 'Snooze 2h',
    },
    'tomorrow_morning': {
      'tr': 'Yarın sabah (09:00)',
      'en': 'Tomorrow morning (09:00)',
    },
    'enter_minutes': {
      'tr': 'Dakika girin',
      'en': 'Enter minutes',
    },
    'invalid_minutes': {
      'tr': 'Lütfen 1-1440 arasında bir değer girin',
      'en': 'Please enter a value between 1 and 1440',
    },
    'snoozed_for_n_minutes': {
      'tr': '{minutes} dakika ertelendi',
      'en': 'Snoozed for {minutes} minutes',
    },
    'delete': {
      'tr': 'Sil',
      'en': 'Delete',
      'es': 'Eliminar',
      'fr': 'Supprimer',
      'de': 'Löschen',
      'ar': 'حذف',
    },
    'edit': {
      'tr': 'Düzenle',
      'en': 'Edit',
      'es': 'Editar',
      'fr': 'Modifier',
      'de': 'Bearbeiten',
      'ar': 'تعديل',
    },
    'add': {
      'tr': 'Ekle',
      'en': 'Add',
      'es': 'Añadir',
      'fr': 'Ajouter',
      'de': 'Hinzufügen',
      'ar': 'إضافة',
    },
    'search': {
      'tr': 'Ara',
      'en': 'Search',
      'es': 'Buscar',
      'fr': 'Rechercher',
      'de': 'Suchen',
      'ar': 'بحث',
    },
    'export': {
      'tr': 'Dışa Aktar',
      'en': 'Export',
      'es': 'Exportar',
      'fr': 'Exporter',
      'de': 'Exportieren',
      'ar': 'تصدير',
    },
    'import': {
      'tr': 'İçe Aktar',
      'en': 'Import',
      'es': 'Importar',
      'fr': 'Importer',
      'de': 'Importieren',
      'ar': 'استيراد',
    },
    'profile': {
      'tr': 'Profil',
      'en': 'Profile',
      'es': 'Perfil',
      'fr': 'Profil',
      'de': 'Profil',
      'ar': 'الملف الشخصي',
    },
    'logout': {
      'tr': 'Çıkış Yap',
      'en': 'Logout',
      'es': 'Cerrar Sesión',
      'fr': 'Déconnexion',
      'de': 'Abmelden',
      'ar': 'تسجيل الخروج',
    },
    'error': {
      'tr': 'Hata',
      'en': 'Error',
      'es': 'Error',
      'fr': 'Erreur',
      'de': 'Fehler',
      'ar': 'خطأ',
    },
    'success': {
      'tr': 'Başarılı',
      'en': 'Success',
      'es': 'Éxito',
      'fr': 'Succès',
      'de': 'Erfolg',
      'ar': 'نجح',
    },
    'warning': {
      'tr': 'Uyarı',
      'en': 'Warning',
      'es': 'Advertencia',
      'fr': 'Avertissement',
      'de': 'Warnung',
      'ar': 'تحذير',
    },
    'info': {
      'tr': 'Bilgi',
      'en': 'Info',
      'es': 'Información',
      'fr': 'Information',
      'de': 'Information',
      'ar': 'معلومات',
    },
    'loading': {
      'tr': 'Yükleniyor...',
      'en': 'Loading...',
      'es': 'Cargando...',
      'fr': 'Chargement...',
      'de': 'Wird geladen...',
      'ar': 'جاري التحميل...',
    },
    'please_wait': {
      'tr': 'Lütfen bekleyiniz',
      'en': 'Please wait',
      'es': 'Por favor espere',
      'fr': 'Veuillez patienter',
      'de': 'Bitte warten',
      'ar': 'يرجى الانتظار',
    },
    'retry': {
      'tr': 'Tekrar Dene',
      'en': 'Retry',
      'es': 'Reintentar',
      'fr': 'Réessayer',
      'de': 'Wiederholen',
      'ar': 'إعادة المحاولة',
    },
    'refresh': {
      'tr': 'Yenile',
      'en': 'Refresh',
      'es': 'Actualizar',
      'fr': 'Actualiser',
      'de': 'Aktualisieren',
      'ar': 'تحديث',
    },
    // Dashboard specific translations
    'health_tracking_ai': {
      'tr': 'Sağlığınızı AI ile takip edin',
      'en': 'Track your health with AI',
      'es': 'Rastrea tu salud con IA',
      'fr': 'Suivez votre santé avec l\'IA',
      'de': 'Verfolgen Sie Ihre Gesundheit mit KI',
      'ar': 'تتبع صحتك بالذكاء الاصطناعي',
    },
    'main_features': {
      'tr': 'Ana Özellikler',
      'en': 'Main Features',
      'es': 'Características Principales',
      'fr': 'Fonctionnalités Principales',
      'de': 'Hauptfunktionen',
      'ar': 'الميزات الرئيسية',
    },
    'additional_features': {
      'tr': 'Diğer Özellikler',
      'en': 'Additional Features',
      'es': 'Características Adicionales',
      'fr': 'Fonctionnalités Supplémentaires',
      'de': 'Zusätzliche Funktionen',
      'ar': 'ميزات إضافية',
    },
    'welcome_title_hemoai': {
      'tr': 'HemoAI\'ya Hoş Geldiniz!',
      'en': 'Welcome to HemoAI!',
    },
    'welcome_subtitle': {
      'tr': 'Sağlığınızı takip edin, AI destekli analizler alın ve sağlıklı yaşam için öneriler keşfedin.',
      'en': 'Track your health, get AI-powered analysis, and discover healthy living tips.',
    },
    'health_goals_achievements': {
      'tr': 'Sağlık Hedefleri ve Başarılar',
      'en': 'Health Goals and Achievements',
    },
    'this_month_goals': {
      'tr': 'Bu Ay Hedefleri',
      'en': 'This Month\'s Goals',
    },
    'goals_updated': {
      'tr': 'Hedefleriniz güncellendi!',
      'en': 'Your goals have been updated!',
    },
    'goal_settings_title': {
      'tr': 'Hedef Ayarları',
      'en': 'Goal Settings',
    },
    'customize_health_goals': {
      'tr': 'Sağlık hedeflerinizi özelleştirin:',
      'en': 'Customize your health goals:',
    },
    'goal_monthly_hemogram': {
      'tr': 'Aylık hemogram kontrolü',
      'en': 'Monthly hemogram check',
    },
    'goal_monthly_hemogram_sub': {
      'tr': 'Ayda en az 1 test yaptırın',
      'en': 'Have at least 1 test per month',
    },
    'goal_daily_water': {
      'tr': 'Günlük su tüketimi',
      'en': 'Daily water intake',
    },
    'goal_daily_water_sub': {
      'tr': 'Günde 2-3 litre su için',
      'en': 'Drink 2-3 liters of water daily',
    },
    'goal_weekly_exercise': {
      'tr': 'Haftalık egzersiz',
      'en': 'Weekly exercise',
    },
    'goal_weekly_exercise_sub': {
      'tr': 'Haftada 3-4 gün spor yapın',
      'en': 'Exercise 3-4 days a week',
    },
    'goal_healthy_nutrition': {
      'tr': 'Sağlıklı beslenme',
      'en': 'Healthy nutrition',
    },
    'goal_healthy_nutrition_sub': {
      'tr': 'Diyet programını takip edin',
      'en': 'Follow your diet program',
    },
    'badges_earned': {
      'tr': 'Kazanılan Rozetler',
      'en': 'Earned Badges',
    },
    'badge_first_test': {
      'tr': 'İlk Test',
      'en': 'First Test',
    },
    'badge_water_drinker': {
      'tr': 'Su İçici',
      'en': 'Water Drinker',
    },
    'badge_regular_tracking': {
      'tr': 'Düzenli Takip',
      'en': 'Regular Tracking',
    },
    'badge_health_expert': {
      'tr': 'Sağlık Uzmanı',
      'en': 'Health Expert',
    },
    'badge_nutrition_guru': {
      'tr': 'Beslenme Gurusu',
      'en': 'Nutrition Guru',
    },
    'goal_progress_monthly_test_1': {
      'tr': 'Bu ay 1 test yaptınız',
      'en': 'You have done 1 test this month',
    },
    'goal_progress_water_avg_2_1l': {
      'tr': 'Günde ortalama 2.1L su içtiniz',
      'en': 'You drank an average of 2.1L of water per day',
    },
    'goal_progress_exercise_3_days': {
      'tr': '3 gün spor yaptınız',
      'en': 'You exercised 3 days',
    },
    'language_settings': {
      'tr': 'Dil Ayarları',
      'en': 'Language Settings',
    },
    // export_options defined later with full languages
    'alternative_medicine': {
      'tr': 'Alternatif\nTıp',
      'en': 'Alternative\nMedicine',
      'es': 'Medicina\nAlternativa',
      'fr': 'Médecine\nAlternative',
      'de': 'Alternative\nMedizin',
      'ar': 'الطب\nالبديل',
    },
    'coming_soon': {
      'tr': 'Bu özellik yakında eklenecek!',
      'en': 'This feature will be added soon!',
      'es': '¡Esta característica se añadirá pronto!',
      'fr': 'Cette fonctionnalité sera bientôt ajoutée!',
      'de': 'Diese Funktion wird bald hinzugefügt!',
      'ar': 'ستضاف هذه الميزة قريباً!',
    },
    'logout_confirmation': {
      'tr': 'Çıkış yapmak istediğinize emin misiniz?',
      'en': 'Are you sure you want to logout?',
      'es': '¿Está seguro de que quiere cerrar sesión?',
      'fr': 'Êtes-vous sûr de vouloir vous déconnecter?',
      'de': 'Sind Sie sicher, dass Sie sich abmelden möchten?',
      'ar': 'هل أنت متأكد من أنك تريد تسجيل الخروج؟',
    },
    'soon_badge': {
      'tr': 'Yakında',
      'en': 'Soon',
      'es': 'Pronto',
      'fr': 'Bientôt',
      'de': 'Bald',
      'ar': 'قريباً',
    },
    // Personal information translations  
    'name': {
      'tr': 'Ad',
      'en': 'Name',
      'es': 'Nombre',
      'fr': 'Nom',
      'de': 'Name',
      'ar': 'الاسم',
    },
    'surname': {
      'tr': 'Soyad',
      'en': 'Surname',
      'es': 'Apellido',
      'fr': 'Nom de famille',
      'de': 'Nachname',
      'ar': 'الكنية',
    },
    'age': {
      'tr': 'Yaş',
      'en': 'Age',
      'es': 'Edad',
      'fr': 'Âge',
      'de': 'Alter',
      'ar': 'العمر',
    },
    // 'gender', 'male', 'female' defined earlier
    'email': {
      'tr': 'E-posta',
      'en': 'Email',
      'es': 'Correo electrónico',
      'fr': 'E-mail',
      'de': 'E-Mail',
      'ar': 'البريد الإلكتروني',
    },
    'phone': {
      'tr': 'Telefon',
      'en': 'Phone',
      'es': 'Teléfono',
      'fr': 'Téléphone',
      'de': 'Telefon',
      'ar': 'الهاتف',
    },
    'address': {
      'tr': 'Adres',
      'en': 'Address',
      'es': 'Dirección',
      'fr': 'Adresse',
      'de': 'Adresse',
      'ar': 'العنوان',
    },
    'blood_type': {
      'tr': 'Kan Grubu',
      'en': 'Blood Type',
      'es': 'Tipo de Sangre',
      'fr': 'Groupe Sanguin',
      'de': 'Blutgruppe',
      'ar': 'فصيلة الدم',
    },
    'height': {
      'tr': 'Boy',
      'en': 'Height',
      'es': 'Altura',
      'fr': 'Taille',
      'de': 'Größe',
      'ar': 'الطول',
    },
    'weight': {
      'tr': 'Kilo',
      'en': 'Weight',
      'es': 'Peso',
      'fr': 'Poids',
      'de': 'Gewicht',
      'ar': 'الوزن',
    },
    'medical_history': {
      'tr': 'Tıbbi Geçmiş',
      'en': 'Medical History',
      'es': 'Historia Médica',
      'fr': 'Antécédents Médicaux',
      'de': 'Krankengeschichte',
      'ar': 'التاريخ الطبي',
    },
    'allergies': {
      'tr': 'Alerjiler',
      'en': 'Allergies',
      'es': 'Alergias',
      'fr': 'Allergies',
      'de': 'Allergien',
      'ar': 'الحساسية',
    },
    'medications': {
      'tr': 'İlaçlar',
      'en': 'Medications',
      'es': 'Medicamentos',
      'fr': 'Médicaments',
      'de': 'Medikamente',
      'ar': 'الأدوية',
    },
    'date_of_birth': {
      'tr': 'Doğum Tarihi',
      'en': 'Date of Birth',
      'es': 'Fecha de Nacimiento',
      'fr': 'Date de Naissance',
      'de': 'Geburtsdatum',
      'ar': 'تاريخ الميلاد',
    },
    'emergency_contact': {
      'tr': 'Acil Durum İletişim',
      'en': 'Emergency Contact',
      'es': 'Contacto de Emergencia',
      'fr': 'Contact d\'Urgence',
      'de': 'Notfallkontakt',
      'ar': 'جهة اتصال الطوارئ',
    },
    'please_fill_all_fields': {
      'tr': 'Lütfen tüm alanları doldurun',
      'en': 'Please fill all fields',
      'es': 'Por favor complete todos los campos',
      'fr': 'Veuillez remplir tous les champs',
      'de': 'Bitte füllen Sie alle Felder aus',
      'ar': 'يرجى ملء جميع الحقول',
    },
    'info_saved_successfully': {
      'tr': 'Bilgiler başarıyla kaydedildi!',
      'en': 'Information saved successfully!',
      'es': '¡Información guardada exitosamente!',
      'fr': 'Informations enregistrées avec succès!',
      'de': 'Informationen erfolgreich gespeichert!',
      'ar': 'تم حفظ المعلومات بنجاح!',
    },
    'enter_personal_info': {
      'tr': 'Kişisel Bilgilerinizi Girin',
      'en': 'Enter Your Personal Information',
      'es': 'Ingrese su Información Personal',
      'fr': 'Saisissez vos Informations Personnelles',
      'de': 'Geben Sie Ihre persönlichen Daten ein',
      'ar': 'أدخل معلوماتك الشخصية',
    },
    // 'calculate_bmi' defined earlier
    'go_to_hemogram_entry': {
      'tr': 'Hemogram Girişine Git',
      'en': 'Go to Hemogram Entry',
      'es': 'Ir a Ingreso de Hemograma',
      'fr': "Aller à la Saisie d'Hémogramme",
      'de': 'Zur Hämogramm-Eingabe',
      'ar': 'اذهب إلى إدخال الهيموجرام',
    },
    'go_to_main_panel': {
      'tr': 'Ana Panele Git',
      'en': 'Go to Main Panel',
      'es': 'Ir al Panel Principal',
      'fr': 'Aller au Panneau Principal',
      'de': 'Zum Hauptpanel',
      'ar': 'اذهب إلى اللوحة الرئيسية',
  },
    'underweight': {
      'tr': 'Zayıf',
      'en': 'Underweight',
      'es': 'Bajo Peso',
      'fr': 'Insuffisance Pondérale',
      'de': 'Untergewicht',
      'ar': 'نقص في الوزن',
    },
    'overweight': {
      'tr': 'Fazla Kilolu',
      'en': 'Overweight',
      'es': 'Sobrepeso',
      'fr': 'Surpoids',
      'de': 'Übergewicht',
      'ar': 'زيادة في الوزن',
    },
    'obese': {
      'tr': 'Obez',
      'en': 'Obese',
      'es': 'Obeso',
      'fr': 'Obèse',
      'de': 'Adipös',
      'ar': 'سمنة',
    },
    // Analysis screen translations
    'test_results': {
      'tr': 'Test Sonuçları',
      'en': 'Test Results',
      'es': 'Resultados de Pruebas',
      'fr': 'Résultats des Tests',
      'de': 'Testergebnisse',
      'ar': 'نتائج الاختبار',
    },
    'enter_test_values': {
      'tr': 'Test Değerlerini Girin',
      'en': 'Enter Test Values',
      'es': 'Ingrese Valores de Prueba',
      'fr': 'Saisissez les Valeurs de Test',
      'de': 'Testwerte Eingeben',
      'ar': 'أدخل قيم الاختبار',
    },
    'view_results': {
      'tr': 'Sonuçları Görüntüle',
      'en': 'View Results',
      'es': 'Ver Resultados',
      'fr': 'Voir les Résultats',
      'de': 'Ergebnisse Anzeigen',
      'ar': 'عرض النتائج',
    },
    'no_data_available': {
      'tr': 'Veri bulunmuyor',
      'en': 'No data available',
      'es': 'No hay datos disponibles',
      'fr': 'Aucune donnée disponible',
      'de': 'Keine Daten verfügbar',
      'ar': 'لا توجد بيانات متاحة',
    },
    // Hemogram entry translations
    'enter_hemogram_values': {
      'tr': 'Hemogram Değerlerini Girin',
      'en': 'Enter Hemogram Values',
      'es': 'Ingrese Valores del Hemograma',
      'fr': 'Saisissez les Valeurs d\'Hémogramme',
      'de': 'Hämogramm-Werte Eingeben',
      'ar': 'أدخل قيم تعداد الدم',
    },
    'reference_values': {
      'tr': 'Referans Değerleri',
      'en': 'Reference Values',
      'es': 'Valores de Referencia',
      'fr': 'Valeurs de Référence',
      'de': 'Referenzwerte',
      'ar': 'القيم المرجعية',
    },
    'your_value': {
      'tr': 'Değeriniz',
      'en': 'Your Value',
      'es': 'Su Valor',
      'fr': 'Votre Valeur',
      'de': 'Ihr Wert',
      'ar': 'قيمتك',
    },
    'status': {
      'tr': 'Durum',
      'en': 'Status',
      'es': 'Estado',
      'fr': 'Statut',
      'de': 'Status',
      'ar': 'الحالة',
    },
    'basophil': {
      'tr': 'Bazofil',
      'en': 'Basophil',
      'es': 'Basófilo',
      'fr': 'Basophile',
      'de': 'Basophil',
      'ar': 'الخلايا القاعدية',
    },
    'medium': {
      'tr': 'Orta',
      'en': 'Medium',
      'es': 'Medio',
      'fr': 'Moyen',
      'de': 'Mittel',
      'ar': 'متوسط',
    },
    'ocr_feature_coming_soon': {
      'tr': 'OCR ile belge okuma özelliği yakında eklenecek.',
      'en': 'OCR document scanning feature will be added soon.',
      'es': 'La función de escaneo de documentos OCR se agregará pronto.',
      'fr': 'La fonctionnalité de numérisation de documents OCR sera bientôt ajoutée.',
      'de': 'OCR-Dokumentenscanning-Funktion wird bald hinzugefügt.',
      'ar': 'ستضاف ميزة مسح المستندات بتقنية OCR قريباً.',
    },
    'scan_document_ocr': {
      'tr': 'Belgeyi Fotoğrafla Oku (OCR)',
      'en': 'Scan Document with Photo (OCR)',
      'es': 'Escanear Documento con Foto (OCR)',
      'fr': 'Numériser le Document avec Photo (OCR)',
      'de': 'Dokument mit Foto Scannen (OCR)',
      'ar': 'امسح المستند بالصورة (OCR)',
    },
    // Review-before-save (OCR/entry confirmation)
    'review_before_save_title': {
      'tr': 'Kaydetmeden Önce İnceleyin',
      'en': 'Review Before Saving',
    },
    'review_before_save_desc': {
      'tr': 'Aşağıdaki değerler kaydedilecek. Devam etmek istiyor musunuz?',
      'en': 'The following values will be saved. Do you want to continue?',
    },
    'confirm_and_save': {
      'tr': 'Onayla ve Kaydet',
      'en': 'Confirm & Save',
    },
    'edit_values': {
      'tr': 'Değerleri Düzenle',
      'en': 'Edit Values',
    },
    'hemogram_info': {
      'tr': 'Test sonuçlarınızı girin. Değerler referans aralığıyla karşılaştırılacak.',
      'en': 'Enter your test results. Values will be compared with reference ranges.',
      'es': 'Ingrese sus resultados de prueba. Los valores se compararán con los rangos de referencia.',
      'fr': 'Saisissez vos résultats de test. Les valeurs seront comparées aux plages de référence.',
      'de': 'Geben Sie Ihre Testergebnisse ein. Werte werden mit Referenzbereichen verglichen.',
      'ar': 'أدخل نتائج الفحص. ستتم مقارنة القيم مع النطاقات المرجعية.',
    },
    'invalid_value': {
      'tr': 'için geçersiz değer girildi',
      'en': 'invalid value entered for',
      'es': 'valor inválido ingresado para',
      'fr': 'valeur invalide saisie pour',
      'de': 'ungültiger Wert eingegeben für',
      'ar': 'تم إدخال قيمة غير صالحة لـ',
    },
    'enter_at_least_one_value': {
      'tr': 'Lütfen en az bir değer girin',
      'en': 'Please enter at least one value',
      'es': 'Por favor ingrese al menos un valor',
      'fr': 'Veuillez saisir au moins une valeur',
      'de': 'Bitte geben Sie mindestens einen Wert ein',
      'ar': 'يرجى إدخال قيمة واحدة على الأقل',
    },
    'save_and_analyze': {
      'tr': 'Kaydet ve Analiz Et',
      'en': 'Save and Analyze',
      'es': 'Guardar y Analizar',
      'fr': 'Enregistrer et Analyser',
      'de': 'Speichern und Analysieren',
      'ar': 'حفظ وتحليل',
    },
    'hemogram_values_saved': {
      'tr': 'Hemogram değerleri kaydedildi!',
      'en': 'Hemogram values saved!',
      'es': '¡Valores del hemograma guardados!',
      'fr': 'Valeurs d\'hémogramme enregistrées!',
      'de': 'Hämogramm-Werte gespeichert!',
      'ar': 'تم حفظ قيم تعداد الدم!',
    },
    // Advanced Analytics translations
    'advanced_analytics': {
      'tr': 'Gelişmiş\nAnaliz',
      'en': 'Advanced\nAnalytics',
      'es': 'Análisis\nAvanzado',
      'fr': 'Analyses\nAvancées',
      'de': 'Erweiterte\nAnalyse',
      'ar': 'تحليلات\nمتقدمة',
    },
    'overview': {
      'tr': 'Genel',
      'en': 'Overview',
      'es': 'Vista General',
      'fr': 'Aperçu',
      'de': 'Übersicht',
      'ar': 'نظرة عامة',
    },
    'trends': {
      'tr': 'Trendler',
      'en': 'Trends',
      'es': 'Tendencias',
      'fr': 'Tendances',
      'de': 'Trends',
      'ar': 'الاتجاهات',
    },
    'compare': {
      'tr': 'Karşılaştır',
      'en': 'Compare',
      'es': 'Comparar',
      'fr': 'Comparer',
      'de': 'Vergleichen',
      'ar': 'قارن',
    },
    'insights': {
      'tr': 'İçgörü',
      'en': 'Insights',
      'es': 'Perspectivas',
      'fr': 'Aperçus',
      'de': 'Einblicke',
      'ar': 'رؤى',
    },
    'health_score': {
      'tr': 'Sağlık Skoru',
      'en': 'Health Score',
      'es': 'Puntuación de Salud',
      'fr': 'Score de Santé',
      'de': 'Gesundheits-Score',
      'ar': 'نقاط الصحة',
    },
    'quick_stats': {
      'tr': 'Hızlı İstatistikler',
      'en': 'Quick Statistics',
      'es': 'Estadísticas Rápidas',
      'fr': 'Statistiques Rapides',
      'de': 'Schnellstatistiken',
      'ar': 'إحصائيات سريعة',
    },
    'total_tests': {
      'tr': 'Toplam Test',
      'en': 'Total Tests',
      'es': 'Total de Pruebas',
      'fr': 'Total des Tests',
      'de': 'Gesamt Tests',
      'ar': 'إجمالي الاختبارات',
    },
    'last_test': {
      'tr': 'Son Test',
      'en': 'Last Test',
      'es': 'Última Prueba',
      'fr': 'Dernier Test',
      'de': 'Letzter Test',
      'ar': 'آخر اختبار',
    },
    'trend': {
      'tr': 'Trend',
      'en': 'Trend',
      'es': 'Tendencia',
      'fr': 'Tendance',
      'de': 'Trend',
      'ar': 'الاتجاه',
    },
    'latest_test_results': {
      'tr': 'Son Test Sonuçları',
      'en': 'Latest Test Results',
      'es': 'Últimos Resultados de Pruebas',
      'fr': 'Derniers Résultats de Test',
      'de': 'Neueste Testergebnisse',
      'ar': 'نتائج الاختبار الأخيرة',
    },
    'test_date': {
      'tr': 'Test Tarihi',
      'en': 'Test Date',
      'es': 'Fecha de Prueba',
      'fr': 'Date du Test',
      'de': 'Testdatum',
      'ar': 'تاريخ الاختبار',
    },
    'hemoglobin_trend': {
      'tr': 'Hemoglobin Trendi',
      'en': 'Hemoglobin Trend',
      'es': 'Tendencia de Hemoglobina',
      'fr': 'Tendance de l\'Hémoglobine',
      'de': 'Hämoglobin-Trend',
      'ar': 'اتجاه الهيموجلوبين',
    },
    'iron_trend': {
      'tr': 'Demir Trendi',
      'en': 'Iron Trend',
      'es': 'Tendencia de Hierro',
      'fr': 'Tendance du Fer',
      'de': 'Eisen-Trend',
      'ar': 'اتجاه الحديد',
    },
    'no_data_for_chart': {
      'tr': 'Grafik için yeterli veri yok',
      'en': 'Not enough data for chart',
      'es': 'No hay suficientes datos para el gráfico',
      'fr': 'Pas assez de données pour le graphique',
      'de': 'Nicht genug Daten für Diagramm',
      'ar': 'بيانات غير كافية للرسم البياني',
    },
    'compare_feature_coming_soon': {
      'tr': 'Karşılaştırma özelliği yakında eklenecek',
      'en': 'Compare feature will be added soon',
      'es': 'La función de comparación se agregará pronto',
      'fr': 'La fonction de comparaison sera bientôt ajoutée',
      'de': 'Vergleichsfunktion wird bald hinzugefügt',
      'ar': 'ستضاف ميزة المقارنة قريباً',
    },
    'ai_insights': {
      'tr': 'AI İçgörüleri',
      'en': 'AI Insights',
      'es': 'Perspectivas de IA',
      'fr': 'Aperçus IA',
      'de': 'KI-Einblicke',
      'ar': 'رؤى الذكاء الاصطناعي',
    },
    'excellent_health': {
      'tr': 'Mükemmel sağlık durumu',
      'en': 'Excellent health condition',
      'es': 'Excelente condición de salud',
      'fr': 'Excellent état de santé',
      'de': 'Ausgezeichneter Gesundheitszustand',
      'ar': 'حالة صحية ممتازة',
    },
    'good_health': {
      'tr': 'İyi sağlık durumu',
      'en': 'Good health condition',
      'es': 'Buena condición de salud',
      'fr': 'Bon état de santé',
      'de': 'Guter Gesundheitszustand',
      'ar': 'حالة صحية جيدة',
    },
    'fair_health': {
      'tr': 'Orta sağlık durumu',
      'en': 'Fair health condition',
      'es': 'Condición de salud regular',
      'fr': 'État de santé moyen',
      'de': 'Mittelmäßiger Gesundheitszustand',
      'ar': 'حالة صحية متوسطة',
    },
    'poor_health': {
      'tr': 'Zayıf sağlık durumu',
      'en': 'Poor health condition',
      'es': 'Condición de salud deficiente',
      'fr': 'Mauvais état de santé',
      'de': 'Schlechter Gesundheitszustand',
      'ar': 'حالة صحية ضعيفة',
    },
    'critical_health': {
      'tr': 'Kritik sağlık durumu',
      'en': 'Critical health condition',
      'es': 'Condición de salud crítica',
      'fr': 'État de santé critique',
      'de': 'Kritischer Gesundheitszustand',
      'ar': 'حالة صحية خطيرة',
    },
    'low_hemoglobin_insight': {
      'tr': 'Düşük Hemoglobin',
      'en': 'Low Hemoglobin',
      'es': 'Hemoglobina Baja',
      'fr': 'Hémoglobine Basse',
      'de': 'Niedriges Hämoglobin',
      'ar': 'هيموجلوبين منخفض',
    },
    'low_hemoglobin_desc': {
      'tr': 'Hemoglobin değeriniz normalden düşük. Demir açığı olabilir.',
      'en': 'Your hemoglobin level is below normal. You may have iron deficiency.',
      'es': 'Su nivel de hemoglobina está por debajo de lo normal. Puede tener deficiencia de hierro.',
      'fr': 'Votre taux d\'hémoglobine est inférieur à la normale. Vous pourriez avoir une carence en fer.',
      'de': 'Ihr Hämoglobinspiegel liegt unter dem Normalbereich. Sie könnten einen Eisenmangel haben.',
      'ar': 'مستوى الهيموجلوبين لديك أقل من الطبيعي. قد تعاني من نقص الحديد.',
    },
    'low_iron_insight': {
      'tr': 'Düşük Demir',
      'en': 'Low Iron',
      'es': 'Hierro Bajo',
      'fr': 'Fer Bas',
      'de': 'Niedriges Eisen',
      'ar': 'حديد منخفض',
    },
    'low_iron_desc': {
      'tr': 'Demir seviyeniz düşük. Demir açığı anemisi riski var.',
      'en': 'Your iron level is low. There is a risk of iron deficiency anemia.',
      'es': 'Su nivel de hierro es bajo. Existe riesgo de anemia por deficiencia de hierro.',
      'fr': 'Votre taux de fer est bas. Il y a un risque d\'anémie ferriprive.',
      'de': 'Ihr Eisenspiegel ist niedrig. Es besteht das Risiko einer Eisenmangelanämie.',
      'ar': 'مستوى الحديد لديك منخفض. هناك خطر الإصابة بفقر الدم بسبب نقص الحديد.',
    },
    'great_progress_insight': {
      'tr': 'Harika İlerleme',
      'en': 'Great Progress',
      'es': 'Gran Progreso',
      'fr': 'Excellent Progrès',
      'de': 'Großartiger Fortschritt',
      'ar': 'تقدم رائع',
    },
    'great_progress_desc': {
      'tr': 'Kan değerleriniz mükemmel durumda. Bu düzeyi koruyun.',
      'en': 'Your blood values are in excellent condition. Keep this level.',
      'es': 'Sus valores sanguíneos están en excelente condición. Mantenga este nivel.',
      'fr': 'Vos valeurs sanguines sont en excellent état. Maintenez ce niveau.',
      'de': 'Ihre Blutwerte sind in ausgezeichnetem Zustand. Halten Sie dieses Niveau.',
      'ar': 'قيم الدم لديك في حالة ممتازة. حافظ على هذا المستوى.',
    },
    'no_insights_insight': {
      'tr': 'Henüz İçgörü Yok',
      'en': 'No Insights Yet',
      'es': 'Aún No Hay Perspectivas',
      'fr': 'Pas Encore d\'Aperçus',
      'de': 'Noch Keine Einblicke',
      'ar': 'لا توجد رؤى حتى الآن',
    },
    'no_insights_desc': {
      'tr': 'Daha fazla test verisi girdiğinizde AI içgörüleri burada görünecek.',
      'en': 'AI insights will appear here when you enter more test data.',
      'es': 'Las perspectivas de IA aparecerán aquí cuando ingrese más datos de prueba.',
      'fr': 'Les aperçus IA apparaîtront ici lorsque vous saisissez plus de données de test.',
      'de': 'KI-Einblicke werden hier angezeigt, wenn Sie mehr Testdaten eingeben.',
      'ar': 'ستظهر رؤى الذكاء الاصطناعي هنا عند إدخال المزيد من بيانات الاختبار.',
    },
    'test_history_count': {
      'tr': 'Son {count} test sonucunuz:',
      'en': 'Your last {count} test results:',
    },
    'first_test_message': {
      'tr': 'Bu ilk test sonucunuz. Gelecekteki testleriniz burada karşılaştırılacak.',
      'en': 'This is your first test result. Your future tests will be compared here.',
    },
    // Common small labels
    'no_data': {
      'tr': 'Veri yok',
      'en': 'No data',
    },
    // Analysis screen misc
    'analysis_results': {
      'tr': 'Analiz Sonuçları',
      'en': 'Analysis Results',
    },
    // Debug login screen (dev only)
    'debug_login_title': {
      'tr': 'Debug Giriş Testi',
      'en': 'Debug Login Test',
    },
    'test_register': {
      'tr': 'Test Kayıt',
      'en': 'Test Register',
    },
    'test_login': {
      'tr': 'Test Giriş',
      'en': 'Test Login',
    },
    'export_options_title': {
      'tr': 'Dışa Aktarma Seçenekleri',
      'en': 'Export Options',
    },
    'export_options_subtitle': {
      'tr': 'Raporunuzu istediğiniz formatta dışa aktarın',
      'en': 'Export your report in the desired format',
    },
    'export_options_go': {
      'tr': 'Seçenekleri Gör',
      'en': 'View Options',
    },
    'quick_pdf': {
      'tr': 'Hızlı PDF',
      'en': 'Quick PDF',
    },
    // Export options screens
    'export_description': {
      'tr': 'Sağlık verilerinizi çeşitli formatlarda dışa aktarın',
      'en': 'Export your health data in various formats',
    },
    'export_pdf': {
      'tr': 'PDF olarak dışa aktar',
      'en': 'Export to PDF',
    },
    'pdf_description': {
      'tr': 'PDF formatında kapsamlı rapor',
      'en': 'Comprehensive report in PDF format',
    },
    'export_excel': {
      'tr': 'Excel olarak dışa aktar',
      'en': 'Export to Excel',
    },
    'excel_description': {
      'tr': 'Excel çalışma sayfası formatında veriler',
      'en': 'Data in spreadsheet format',
    },
    'export_analysis': {
      'tr': 'Analiz Raporunu Dışa Aktar',
      'en': 'Export Analysis Report',
    },
    'analysis_description': {
      'tr': 'Detaylı sağlık analizi',
      'en': 'Detailed health analysis',
    },
    // Backup & Restore
    'backup_data': {
      'tr': 'Verileri Yedekle',
      'en': 'Backup Data',
    },
    'backup_data_desc': {
      'tr': 'Tüm kullanıcı ve uygulama verilerini JSON olarak dışa aktar',
      'en': 'Export all user and app data as JSON',
    },
    'restore_data': {
      'tr': 'Yedeği Geri Yükle',
      'en': 'Restore Backup',
    },
    'restore_data_desc': {
      'tr': 'JSON yedek dosyasından verilerinizi geri yükleyin',
      'en': 'Restore your data from a JSON backup file',
    },
    'backup_ready': {
      'tr': 'Yedek hazır',
      'en': 'Backup is ready',
    },
    'no_file_selected': {
      'tr': 'Dosya seçilmedi',
      'en': 'No file selected',
    },
    // Status synonyms and critical
    'status_normal': {
      'tr': 'Normal',
      'en': 'Normal',
    },
    'status_low': {
      'tr': 'Düşük',
      'en': 'Low',
    },
    'status_high': {
      'tr': 'Yüksek',
      'en': 'High',
    },
    'status_very_high': {
      'tr': 'Çok Yüksek',
      'en': 'Very High',
    },
    // Profile switching
    'switch_profile': {
      'tr': 'Profili Değiştir',
      'en': 'Switch Profile',
    },
    'select_profile': {
      'tr': 'Profil Seçin',
      'en': 'Select Profile',
    },
    'no_profiles_found': {
      'tr': 'Kullanılabilir profil bulunamadı',
      'en': 'No available profiles found',
    },
    // Personal info screen additions
    'save_error': {
      'tr': 'Kaydetme hatası: {error}',
      'en': 'Save error: {error}',
    },
    'personal_info_entry': {
      'tr': 'Kişisel Bilgi Girişi',
      'en': 'Personal Info Entry',
    },
    'enter_your_personal_info': {
      'tr': 'Kişisel bilgilerinizi girin',
      'en': 'Enter your personal information',
    },
    'weight_kg': {
      'tr': 'Kilo (kg)',
      'en': 'Weight (kg)',
    },
    'height_cm': {
      'tr': 'Boy (cm)',
      'en': 'Height (cm)',
    },
    'bmi_calculate': {
      'tr': 'VKİ Hesapla',
      'en': 'Calculate BMI',
    },
    'bmi_short': {
      'tr': 'VKİ',
      'en': 'BMI',
    },
    'bmi_status_ideal': {
      'tr': 'İdeal',
      'en': 'Ideal',
    },
    'bmi_status_normal': {
      'tr': 'Normal',
      'en': 'Normal',
    },
    'bmi_status_risk': {
      'tr': 'Riskli',
      'en': 'At Risk',
    },
    // Generic patient label used in backups
    'patient': {
      'tr': 'Hasta',
      'en': 'Patient',
    },
    // Risk labels
    'low_risk': {
      'tr': 'Düşük Risk',
      'en': 'Low Risk',
    },
    'moderate_risk': {
      'tr': 'Orta Risk',
      'en': 'Moderate Risk',
    },
    'high_risk': {
      'tr': 'Yüksek Risk',
      'en': 'High Risk',
    },
    // App drawer / About
    'about_hemoai_full': {
      'tr': 'HemoAI, hemogram ve sağlık takibi için geliştirilen akıllı bir asistandır.',
      'en': 'HemoAI is a smart assistant for hemogram and health tracking.',
    },
    'version_label': {
      'tr': 'Sürüm',
      'en': 'Version',
    },
    'developer_team_label': {
      'tr': 'Geliştirici Ekip',
      'en': 'Developer Team',
    },
    'about_hemoai_description': {
      'tr': 'Bu uygulama tıbbi tavsiye vermez; bilgi amaçlıdır.',
      'en': 'This app does not provide medical advice; it is for informational purposes.',
    },
    'medical_disclaimer_short': {
      'tr': 'Tıbbi kararlar için doktorunuza danışın.',
      'en': 'Consult your doctor for medical decisions.',
    },
    // Drawer and small labels
    'about': {
      'tr': 'Hakkında',
      'en': 'About',
    },
    // Generic fallbacks for notifications/medications defaults
    'no_subtitle': {
      'tr': 'Alt başlık yok',
      'en': 'No subtitle',
    },
    'no_description': {
      'tr': 'Açıklama bulunmuyor',
      'en': 'No description provided',
    },
    'medication': {
      'tr': 'İlaç',
      'en': 'Medication',
    },
    'default_dosage': {
      'tr': '1 doz',
      'en': '1 dose',
    },
    'default_frequency': {
      'tr': 'Günde bir kez',
      'en': 'Once daily',
    },
    'default_time': {
      'tr': 'Ayarlanmadı',
      'en': 'Not set',
    },
    
    // Guest Screen
    'guest_mode': {
      'tr': 'Misafir Modu',
      'en': 'Guest Mode',
    },
    'guest_description': {
      'tr': 'Kayıt olmadan uygulamanın temel özelliklerini deneyimleyebilirsiniz.\n\nKişisel bilgilerinizi girip hemogram sonuçlarınızı analiz ettirebilir, AI destekli tavsiye ve diyet programı alabilirsiniz.',
      'en': 'You can try the core features without registering.\n\nEnter your personal info and hemogram results to get analysis, AI-powered advice, and a diet program.',
    },
    'enter_personal_info_short': {
      'tr': 'Kişisel Bilgi Gir',
      'en': 'Enter Personal Info',
    },
    'enter_hemogram_result': {
      'tr': 'Hemogram Sonucu Gir',
      'en': 'Enter Hemogram Result',
    },
    'get_ai_analysis_advice': {
      'tr': 'AI Analiz ve Tavsiye Al',
      'en': 'Get AI Analysis & Advice',
    },
    // Language selection and privacy
    'select_language': {
      'tr': 'Dil Seçin',
      'en': 'Select Language',
    },
    'privacy_notice': {
      'tr': 'Üye olarak Gizlilik Politikası ve Kullanım Şartlarını kabul etmiş olursunuz.',
      'en': 'By registering, you accept the Privacy Policy and Terms of Use.',
    },
    // Generic labels
    'reminder': {
      'tr': 'Hatırlatıcı',
      'en': 'Reminder',
    },
    'reminders_subtitle': {
      'tr': 'Tüm hatırlatıcılarınızı organize edin',
      'en': 'Organize all your reminders',
    },
    'reminders_excel': {
      'tr': 'Hatırlatıcılar Excel',
      'en': 'Reminders Excel',
    },
    'reminders_excel_description': {
      'tr': 'Tüm aktif ve geçmiş hatırlatıcılarınızın listesi',
      'en': 'List of all active and past reminders',
    },
    'reminders_export_success': {
      'tr': 'Hatırlatıcılar başarıyla indirildi',
      'en': 'Reminders downloaded successfully',
    },
    'reminders_export_failed': {
      'tr': 'Hatırlatıcı export işlemi başarısız',
      'en': 'Reminders export failed',
    },
    'hemogram_data_filename_prefix': {
      'tr': 'Hemogram Verileri',
      'en': 'Hemogram Data',
    },
    'analysis_report': {
      'tr': 'Analiz Raporu',
      'en': 'Analysis Report',
    },
    'comprehensive_health_report': {
      'tr': 'Kapsamlı Sağlık Raporu',
      'en': 'Comprehensive Health Report',
    },
    // Export/PDF labels
    'hemogram_report': {
      'tr': 'Hemogram Raporu',
      'en': 'Hemogram Report',
    },
    'patient_name': {
      'tr': 'Hasta Adı',
      'en': 'Patient Name',
    },
    'report_date': {
      'tr': 'Rapor Tarihi',
      'en': 'Report Date',
    },
    'parameter': {
      'tr': 'Parametre',
      'en': 'Parameter',
    },
    'result': {
      'tr': 'Sonuç',
      'en': 'Result',
    },
    'reference_range': {
      'tr': 'Referans Aralığı',
      'en': 'Reference Range',
    },
    'normal_status': {
      'tr': 'Normal',
      'en': 'Normal',
    },
    'high_status': {
      'tr': 'Yüksek',
      'en': 'High',
    },
    'notes': {
      'tr': 'Notlar',
      'en': 'Notes',
    },
    'generated_by': {
      'tr': 'Oluşturan:',
      'en': 'Generated by:',
    },
    // Parameter code -> localized name/unit for exports
    'param_wbc': {
      'tr': 'Lökosit',
      'en': 'White Blood Cells',
    },
    'param_rbc': {
      'tr': 'Eritrosit',
      'en': 'Red Blood Cells',
    },
    'param_hgb': {
      'tr': 'Hemoglobin',
      'en': 'Hemoglobin',
    },
    'param_hct': {
      'tr': 'Hematokrit',
      'en': 'Hematocrit',
    },
    'param_mcv': {
      'tr': 'MCV',
      'en': 'MCV',
    },
    'param_mch': {
      'tr': 'MCH',
      'en': 'MCH',
    },
    'param_mchc': {
      'tr': 'MCHC',
      'en': 'MCHC',
    },
    'param_rdw': {
      'tr': 'RDW',
      'en': 'RDW',
    },
    'param_plt': {
      'tr': 'Trombosit',
      'en': 'Platelets',
    },
    'param_mpv': {
      'tr': 'MPV',
      'en': 'MPV',
    },
    // Generic statuses for UI scales
    'good_status': {
      'tr': 'İyi',
      'en': 'Good',
    },
    'low_status': {
      'tr': 'Düşük',
      'en': 'Low',
    },
    // Common UI labels used in legacy/backup screens
    'members': {
      'tr': 'Üyeler',
      'en': 'Members',
    },
    'close': {
      'tr': 'Kapat',
      'en': 'Close',
    },
    'total': {
      'tr': 'Toplam',
      'en': 'Total',
    },
    'no_test_history': {
      'tr': 'Henüz geçmiş test sonucu yok',
      'en': 'No test history yet',
    },
    'trend_analysis': {
      'tr': 'Trend Analizi',
      'en': 'Trend Analysis',
    },
    'last_3_months': {
      'tr': 'Son 3 ay',
      'en': 'Last 3 months',
    },
    'trending_up': {
      'tr': 'Yükselişte',
      'en': 'Rising',
    },
    'trending_down': {
      'tr': 'Düşüşte',
      'en': 'Falling',
    },
    'stable': {
      'tr': 'Stabil',
      'en': 'Stable',
    },
    'general_assessment': {
      'tr': 'Genel Değerlendirme',
      'en': 'General Assessment',
    },
    'family_health_status': {
      'tr': 'Aile Sağlık Durumu',
      'en': 'Family Health Status',
    },
    'family_members': {
      'tr': 'Aile Üyeleri',
      'en': 'Family Members',
    },
    'family_hemogram_comparison': {
      'tr': 'Aile Hemogram Karşılaştırması',
      'en': 'Family Hemogram Comparison',
    },
    'lab_reminders': {
      'tr': 'Tahlil Hatırlatıcıları',
      'en': 'Lab Reminders',
    },
    'family_lab_reminders_desc': {
      'tr': 'Aile üyelerinizin düzenli tahlil hatırlatıcılarını burada yönetebileceksiniz.',
      'en': 'You will be able to manage regular lab reminders for your family members here.',
    },
    'relation_label': {
      'tr': 'Yakınlık Derecesi',
      'en': 'Relation',
    },
    // 'family_member_added' defined later with parameterized variant
    'latest_hemogram_values': {
      'tr': 'Güncel Hemogram Değerleri',
      'en': 'Latest Hemogram Values',
    },
    'test_comparison': {
      'tr': 'Test Karşılaştırması',
      'en': 'Test Comparison',
    },
    // Comparison summary templates
    'comparison_stable': {
      'tr': 'Sağlık durumunuz {risk} risk seviyesinde stabil kalıyor. Mevcut tedavi ve beslenme planınıza devam edin.',
      'en': 'Your health status remains at {risk} risk level. Continue your current treatment and diet plan.',
    },
    'comparison_improved': {
      'tr': 'Tebrikler! Sağlık durumunuzda iyileşme var. {prev} riskten {curr} riske düştünüz. Programınıza devam edin.',
      'en': 'Congratulations! Your condition has improved. You went from {prev} risk to {curr} risk. Keep up your program.',
    },
    'comparison_worsened': {
      'tr': 'Dikkat! Risk seviyeniz {prev}’tan {curr}’a yükseldi. Doktor kontrolü ve plan revizyonu gerekebilir.',
      'en': 'Attention! Your risk level increased from {prev} to {curr}. A doctor check and plan revision may be needed.',
    },
    // Tabs and headings for legacy family panel dialog
    'current_status': {
      'tr': 'Son Durum',
      'en': 'Current Status',
    },
    'history': {
      'tr': 'Geçmiş',
      'en': 'History',
    },
    'hemogram_summary': {
      'tr': 'Hemogram Özeti',
      'en': 'Hemogram Summary',
    },
    'comparison_min_two_tests': {
      'tr': 'Karşılaştırma için en az 2 test sonucu gerekli',
      'en': 'At least 2 test results are required for comparison',
    },
  // Note: Do not close the map here; more keys continue below.
    'normal': {
      'tr': 'Normal',
      'en': 'Normal',
      'es': 'Normal',
      'fr': 'Normal',
      'de': 'Normal',
      'ar': 'طبيعي',
    },
    'high': {
      'tr': 'Yüksek',
      'en': 'High',
      'es': 'Alto',
      'fr': 'Élevé',
      'de': 'Hoch',
      'ar': 'مرتفع',
    },
    'low': {
      'tr': 'Düşük',
      'en': 'Low',
      'es': 'Bajo',
      'fr': 'Bas',
      'de': 'Niedrig',
      'ar': 'منخفض',
    },
    // export-related keys moved earlier; avoiding duplicates
    
    // smart_health_assistant already defined earlier
    'alternative_medicine_methods': {
      'tr': 'Alternatif Tıp & Yöresel Yöntemler',
      'en': 'Alternative Medicine & Local Methods',
      'es': 'Medicina Alternativa y Métodos Locales',
      'fr': 'Médecine Alternative et Méthodes Locales',
      'de': 'Alternativmedizin & Lokale Methoden',
      'ar': 'الطب البديل والطرق المحلية',
    },
    'hemogram_analysis': {
      'tr': 'Hemogram Analizi',
      'en': 'Hemogram Analysis',
      'es': 'Análisis de Hemograma',
      'fr': 'Analyse d\'Hémogramme',
      'de': 'Hämogramm-Analyse',
      'ar': 'تحليل الهيموجرام',
    },
    // Duplicate of 'personal_diet_program' removed (already declared earlier)
    // Diet program i18n (duplicates of existing keys removed)
    'age_suitability': {
      'tr': 'Yaşa Uygunluk',
      'en': 'Age Suitability',
    },
    'age_group_child': {
      'tr': 'Çocuk',
      'en': 'Child',
    },
    'age_group_teen': {
      'tr': 'Genç',
      'en': 'Teen',
    },
    'age_group_adult': {
      'tr': 'Yetişkin',
      'en': 'Adult',
    },
    'age_group_senior': {
      'tr': 'Yaşlı',
      'en': 'Senior',
    },
    // Duplicate of 'suitable_for_age' removed (already declared earlier)
    'diet_low_hemoglobin_title': {
      'tr': 'Hemoglobin Destek Diyeti',
      'en': 'Hemoglobin Support Diet',
    },
    'diet_low_hemoglobin_desc': {
      'tr': 'Hemoglobin değerlerini desteklemek için demir ve B12 açısından zengin beslenme.',
      'en': 'Rich in iron and B12 to support hemoglobin levels.',
    },
    'diet_low_hemoglobin_include': {
      'tr': '• Kırmızı et, karaciğer\n• Ispanak, pazı, brokoli\n• Mercimek, nohut\n• C vitamini ile birlikte tüketim',
      'en': '• Red meat, liver\n• Spinach, chard, broccoli\n• Lentils, chickpeas\n• Pair with vitamin C',
    },
    'diet_low_hemoglobin_limit': {
      'tr': '• Aşırı çay/kahve (demir emilimini azaltır)\n• Aşırı süt ürünleri',
      'en': '• Excess tea/coffee (reduces iron absorption)\n• Excess dairy',
    },
    'diet_low_hemoglobin_macros': {
      'tr': 'Makrolar: Protein %25 • Yağ %30 • Karbonhidrat %45',
      'en': 'Macros: Protein 25% • Fat 30% • Carbs 45%',
    },
    'diet_low_hemoglobin_menu': {
      'tr': 'Örnek Menü:\nKahvaltı: Yulaf + kuru üzüm + ceviz\nÖğle: Izgara kırmızı et + roka\nAkşam: Mercimek çorbası + yoğurt',
      'en': 'Sample Menu:\nBreakfast: Oats + raisins + walnuts\nLunch: Grilled red meat + arugula\nDinner: Lentil soup + yogurt',
    },
    'diet_low_iron_title': {
      'tr': 'Demir Takviye Diyeti',
      'en': 'Iron-Boost Diet',
    },
    'diet_low_iron_desc': {
      'tr': 'Demir eksikliğini gidermek için emilimi artıran kombinasyonlar.',
      'en': 'Combinations that enhance iron absorption to address deficiency.',
    },
    'diet_low_iron_include': {
      'tr': '• Yağsız kırmızı et\n• Pekmez, kuru üzüm\n• Tahin, kuruyemiş\n• Portakal, kivi (C vitamini)',
      'en': '• Lean red meat\n• Molasses, raisins\n• Tahini, nuts\n• Oranges, kiwi (vitamin C)',
    },
    'diet_low_iron_limit': {
      'tr': '• Yemekle birlikte çay/kahve\n• Aşırı lif takviyeleri',
      'en': '• Tea/coffee with meals\n• Excess fiber supplements',
    },
    'diet_low_iron_macros': {
      'tr': 'Makrolar: Protein %25 • Yağ %30 • Karbonhidrat %45',
      'en': 'Macros: Protein 25% • Fat 30% • Carbs 45%',
    },
    'diet_low_iron_menu': {
      'tr': 'Örnek Menü:\nKahvaltı: Pekmezli tahin + tam buğday ekmeği\nÖğle: Izgara et + C vitamini kaynağı salata\nAkşam: Nohut yemeği + limon',
      'en': 'Sample Menu:\nBreakfast: Molasses with tahini + whole wheat bread\nLunch: Grilled meat + vitamin C rich salad\nDinner: Chickpea stew + lemon',
    },
    // Regional overrides for diet content (examples)
    // Keys follow pattern: <base_key>__region__<code>
    // Turkish region-specific variations
    'diet_low_iron_menu__region__tr': {
      'tr': 'Örnek Menü (TR):\nKahvaltı: Pekmezli tahin + simit\nÖğle: Izgara köfte + çoban salata\nAkşam: Kuru fasulye + bulgur pilavı + limon',
      'en': 'Sample Menu (TR):\nBreakfast: Molasses & tahini + simit\nLunch: Grilled köfte + shepherd salad\nDinner: Beans stew + bulgur pilaf + lemon',
    },
    'diet_low_iron_include__region__tr': {
      'tr': '• Dana ciğer, kuzu eti\n• Pekmez, tahin-pekmez\n• Nohut, kuru fasulye\n• Biber, limon (C vitamini)'
    },
    // Arabic region example (Levant/Gulf inspired)
    'diet_low_hemoglobin_menu__region__ar': {
      'ar': 'قائمة مقترحة (المنطقة):\nالفطور: حمص بالطحينة + خبز عربي\nالغداء: لحم مشوي + تبولة\nالعشاء: عدس مطبوخ + لبن',
      'en': 'Sample Menu (AR):\nBreakfast: Hummus with tahini + Arabic bread\nLunch: Grilled meat + tabbouleh\nDinner: Cooked lentils + laban (yogurt)'
    },
    'diet_balanced_menu__region__tr': {
      'tr': 'Örnek Menü (TR):\nKahvaltı: Peynir-zeytin + domates-salatalık\nÖğle: Tavuklu bulgur pilavı + ayran\nAkşam: Zeytinyağlı taze fasulye + yoğurt',
    },
    'diet_high_wbc_title': {
      'tr': 'Anti-Enflamatuar Diyet',
      'en': 'Anti-Inflammatory Diet',
    },
    'diet_high_wbc_desc': {
      'tr': 'Olası enflamasyon için antioksidan ve omega-3 ağırlıklı menüler.',
      'en': 'Antioxidant and omega-3 focused menus for possible inflammation.',
    },
    'diet_high_wbc_include': {
      'tr': '• Zeytinyağı, avokado\n• Somon, uskumru (omega-3)\n• Yaban mersini, nar\n• Yeşil yapraklı sebzeler',
      'en': '• Olive oil, avocado\n• Salmon, mackerel (omega-3)\n• Blueberries, pomegranate\n• Leafy greens',
    },
    'diet_high_wbc_limit': {
      'tr': '• Rafine şeker\n• Aşırı işlenmiş gıdalar',
      'en': '• Refined sugar\n• Ultra-processed foods',
    },
    'diet_high_wbc_macros': {
      'tr': 'Makrolar: Protein %20 • Yağ %35 • Karbonhidrat %45',
      'en': 'Macros: Protein 20% • Fat 35% • Carbs 45%',
    },
    'diet_high_wbc_menu': {
      'tr': 'Örnek Menü:\nKahvaltı: Avokadolu tam tahıllı tost\nÖğle: Izgara somon + roka salata\nAkşam: Zeytinyağlı sebze yemeği + yoğurt',
      'en': 'Sample Menu:\nBreakfast: Wholegrain toast with avocado\nLunch: Grilled salmon + arugula salad\nDinner: Veggies in olive oil + yogurt',
    },
    'diet_balanced_title': {
      'tr': 'Dengeli Beslenme Programı',
      'en': 'Balanced Diet Program',
    },
    'diet_balanced_desc': {
      'tr': 'Genel sağlığı destekleyen dengeli ve sürdürülebilir öğünler.',
      'en': 'Balanced, sustainable meals that support overall health.',
    },
    'diet_balanced_include': {
      'tr': '• Tam tahıllar\n• Yağsız proteinler\n• Renkli sebze ve meyveler\n• Sağlıklı yağlar (zeytinyağı, fındık)',
      'en': '• Whole grains\n• Lean proteins\n• Colorful fruits and vegetables\n• Healthy fats (olive oil, nuts)',
    },
    'diet_balanced_limit': {
      'tr': '• Şekerli içecekler\n• Aşırı tuz ve işlenmiş gıdalar',
      'en': '• Sugary drinks\n• Excess salt and processed foods',
    },
    'diet_balanced_macros': {
      'tr': 'Makrolar: Protein %20 • Yağ %30 • Karbonhidrat %50',
      'en': 'Macros: Protein 20% • Fat 30% • Carbs 50%',
    },
    'diet_balanced_menu': {
      'tr': 'Örnek Menü:\nKahvaltı: Peynirli omlet + domates\nÖğle: Tavuklu bulgur pilavı + salata\nAkşam: Izgara sebzeler + yoğurt',
      'en': 'Sample Menu:\nBreakfast: Cheese omelet + tomatoes\nLunch: Chicken with bulgur + salad\nDinner: Grilled veggies + yogurt',
    },
    'family_health_panel': {
      'tr': 'Aile Sağlık Paneli',
      'en': 'Family Health Panel',
      'es': 'Panel de Salud Familiar',
      'fr': 'Panneau de Santé Familiale',
      'de': 'Familien-Gesundheitspanel',
      'ar': 'لوحة الصحة العائلية',
    },
    // Family Panel Additions
    'family_empty_title': {
      'tr': 'Henüz aile üyesi eklenmemiş',
      'en': 'No family members added yet',
      'es': 'Aún no se han añadido miembros de la familia',
      'fr': 'Aucun membre de la famille ajouté pour le moment',
      'de': 'Noch keine Familienmitglieder hinzugefügt',
      'ar': 'لم تتم إضافة أي أفراد للعائلة بعد',
    },
    'family_empty_subtitle': {
      'tr': 'Aile üyelerinizi ekleyerek sağlık durumlarını\ntakip edebilirsiniz',
      'en': 'Add your family members to track their health status',
      'es': 'Agrega a tus familiares para seguir su estado de salud',
      'fr': 'Ajoutez vos membres de famille pour suivre leur santé',
      'de': 'Fügen Sie Familienmitglieder hinzu, um ihre Gesundheit zu verfolgen',
      'ar': 'أضف أفراد عائلتك لتتبع حالتهم الصحية',
    },
    'family_add_first_member': {
      'tr': 'İlk Aile Üyesini Ekle',
      'en': 'Add First Family Member',
      'es': 'Agregar Primer Miembro de la Familia',
      'fr': 'Ajouter le Premier Membre de la Famille',
      'de': 'Erstes Familienmitglied hinzufügen',
      'ar': 'أضف أول فرد في العائلة',
    },
    'family_add_member': {
      'tr': 'Aile Üyesi Ekle',
      'en': 'Add Family Member',
      'es': 'Agregar Miembro de la Familia',
      'fr': 'Ajouter un Membre de la Famille',
      'de': 'Familienmitglied hinzufügen',
      'ar': 'أضف فرد عائلة',
    },
    'family_add_member_question': {
      'tr': 'Hangi yöntemi kullanmak istiyorsunuz?',
      'en': 'Which method would you like to use?',
      'es': '¿Qué método deseas usar?',
      'fr': 'Quelle méthode souhaitez-vous utiliser ?',
      'de': 'Welche Methode möchten Sie verwenden?',
      'ar': 'أي طريقة تود استخدامها؟',
    },
    'family_add_manual_entry': {
      'tr': 'Manuel Bilgi Girişi',
      'en': 'Manual Information Entry',
      'es': 'Entrada Manual de Información',
      'fr': 'Saisie Manuelle des Informations',
      'de': 'Manuelle Dateneingabe',
      'ar': 'إدخال معلومات يدوي',
    },
    'family_invite_real_user': {
      'tr': 'Gerçek Kullanıcı Davet Et',
      'en': 'Invite Real User',
      'es': 'Invitar Usuario Real',
      'fr': 'Inviter un Utilisateur Réel',
      'de': 'Echten Benutzer einladen',
      'ar': 'دعوة مستخدم حقيقي',
    },
    'family_member_added': {
      'tr': "{name} aile paneline eklendi",
      'en': "{name} added to family panel",
      'es': '{name} añadido al panel familiar',
      'fr': '{name} ajouté au panneau familial',
      'de': '{name} zum Familienpanel hinzugefügt',
      'ar': 'تمت إضافة {name} إلى لوحة العائلة',
    },
    'family_invite_sent': {
      'tr': '{name} kişisine davet gönderildi!',
      'en': 'Invitation sent to {name}!',
      'es': '¡Invitación enviada a {name}!',
      'fr': 'Invitation envoyée à {name} !',
      'de': 'Einladung an {name} gesendet!',
      'ar': 'تم إرسال دعوة إلى {name}!',
    },
    'family_invite_user_not_found': {
      'tr': 'Bu telefon numarası ile kayıtlı kullanıcı bulunamadı',
      'en': 'No user found with this phone number',
      'es': 'No se encontró un usuario con este número',
      'fr': 'Aucun utilisateur trouvé avec ce numéro',
      'de': 'Kein Benutzer mit dieser Telefonnummer gefunden',
      'ar': 'لم يتم العثور على مستخدم بهذا الرقم',
    },
    'family_invite_error': {
      'tr': 'Davet gönderilirken hata: {error}',
      'en': 'Error sending invitation: {error}',
      'es': 'Error al enviar la invitación: {error}',
      'fr': 'Erreur lors de l\'envoi de l\'invitation : {error}',
      'de': 'Fehler beim Senden der Einladung: {error}',
      'ar': 'خطأ أثناء إرسال الدعوة: {error}',
    },
    'family_pending_invitations': {
      'tr': 'Bekleyen Davetler ({count})',
      'en': 'Pending Invitations ({count})',
      'es': 'Invitaciones Pendientes ({count})',
      'fr': 'Invitations en Attente ({count})',
      'de': 'Ausstehende Einladungen ({count})',
      'ar': 'الدعوات المعلقة ({count})',
    },
    'family_unknown_user': {
      'tr': 'Bilinmeyen Kullanıcı',
      'en': 'Unknown User',
      'es': 'Usuario Desconocido',
      'fr': 'Utilisateur Inconnu',
      'de': 'Unbekannter Benutzer',
      'ar': 'مستخدم غير معروف',
    },
    'family_invited_as_relation': {
      'tr': '{relation} olarak davet etti',
      'en': 'invited as {relation}',
      'es': 'invitó como {relation}',
      'fr': 'a invité en tant que {relation}',
      'de': 'als {relation} eingeladen',
      'ar': 'دعا كـ {relation}',
    },
    'family_decline': {
      'tr': 'Reddet',
      'en': 'Decline',
      'es': 'Rechazar',
      'fr': 'Refuser',
      'de': 'Ablehnen',
      'ar': 'رفض',
    },
    'family_accept': {
      'tr': 'Kabul Et',
      'en': 'Accept',
      'es': 'Aceptar',
      'fr': 'Accepter',
      'de': 'Akzeptieren',
      'ar': 'قبول',
    },
    'family_invite_accepted': {
      'tr': 'Davet kabul edildi!',
      'en': 'Invitation accepted!',
      'es': '¡Invitación aceptada!',
      'fr': 'Invitation acceptée !',
      'de': 'Einladung angenommen!',
      'ar': 'تم قبول الدعوة!',
    },
    'family_invite_rejected': {
      'tr': 'Davet reddedildi.',
      'en': 'Invitation declined.',
      'es': 'Invitación rechazada.',
      'fr': 'Invitation refusée.',
      'de': 'Einladung abgelehnt.',
      'ar': 'تم رفض الدعوة.',
    },
    'family_invite_response_error': {
      'tr': 'Yanıt gönderilirken hata: {error}',
      'en': 'Error sending response: {error}',
      'es': 'Error al enviar la respuesta: {error}',
      'fr': 'Erreur lors de l\'envoi de la réponse : {error}',
      'de': 'Fehler beim Senden der Antwort: {error}',
      'ar': 'خطأ أثناء إرسال الرد: {error}',
    },
    'family_gender_male': {
      'tr': 'Erkek',
      'en': 'Male',
      'es': 'Hombre',
      'fr': 'Homme',
      'de': 'Männlich',
      'ar': 'ذكر',
    },
    'family_gender_female': {
      'tr': 'Kadın',
      'en': 'Female',
      'es': 'Mujer',
      'fr': 'Femme',
      'de': 'Weiblich',
      'ar': 'أنثى',
    },
    'family_name_unknown': {
      'tr': 'İsimsiz',
      'en': 'Unnamed',
      'es': 'Sin Nombre',
      'fr': 'Sans Nom',
      'de': 'Ohne Namen',
      'ar': 'بدون اسم',
    },
    'family_relation_unknown': {
      'tr': 'Bilinmiyor',
      'en': 'Unknown',
      'es': 'Desconocido',
      'fr': 'Inconnu',
      'de': 'Unbekannt',
      'ar': 'غير معروف',
    },
    'family_age_suffix': {
      'tr': 'yaş',
      'en': 'yrs',
      'es': 'años',
      'fr': 'ans',
      'de': 'Jahre',
      'ar': 'سنة',
    },
    'family_edit': {
      'tr': 'Düzenle',
      'en': 'Edit',
      'es': 'Editar',
      'fr': 'Modifier',
      'de': 'Bearbeiten',
      'ar': 'تعديل',
    },
    'family_delete': {
      'tr': 'Sil',
      'en': 'Delete',
      'es': 'Eliminar',
      'fr': 'Supprimer',
      'de': 'Löschen',
      'ar': 'حذف',
    },
    'family_hemogram_info': {
      'tr': 'Hemogram testleri henüz eklenmemiş. Test sonuçları eklemek için üyeye tıklayın.',
      'en': 'No hemogram tests added yet. Tap the member to add test results.',
      'es': 'Aún no se han añadido pruebas de hemograma. Toca el miembro para añadir resultados.',
      'fr': 'Aucun test d\'hémogramme ajouté. Touchez le membre pour ajouter des résultats.',
      'de': 'Noch keine Hämogrammtests hinzugefügt. Tippen Sie auf das Mitglied, um Ergebnisse hinzuzufügen.',
      'ar': 'لم تتم إضافة فحوصات الهيموجرام بعد. اضغط على العضو لإضافة النتائج.',
    },
    'family_member_updated': {
      'tr': 'Aile üyesi güncellendi',
      'en': 'Family member updated',
      'es': 'Miembro de la familia actualizado',
      'fr': 'Membre de la famille mis à jour',
      'de': 'Familienmitglied aktualisiert',
      'ar': 'تم تحديث فرد العائلة',
    },
    'family_member_delete_title': {
      'tr': 'Aile Üyesini Sil',
      'en': 'Delete Family Member',
      'es': 'Eliminar Miembro de la Familia',
      'fr': 'Supprimer le Membre de la Famille',
      'de': 'Familienmitglied löschen',
      'ar': 'حذف فرد العائلة',
    },
    'family_member_delete_confirm': {
      'tr': '{name} adlı aile üyesini silmek istediğinizden emin misiniz?',
      'en': 'Are you sure you want to delete family member {name}?',
      'es': '¿Seguro que deseas eliminar al miembro {name}?',
      'fr': 'Êtes-vous sûr de vouloir supprimer le membre {name} ?',
      'de': 'Sind Sie sicher, dass Sie {name} löschen möchten?',
      'ar': 'هل أنت متأكد أنك تريد حذف العضو {name}؟',
    },
    'family_member_deleted': {
      'tr': '{name} silindi',
      'en': '{name} deleted',
      'es': '{name} eliminado',
      'fr': '{name} supprimé',
      'de': '{name} gelöscht',
      'ar': 'تم حذف {name}',
    },
    'family_cancel': {
      'tr': 'İptal',
      'en': 'Cancel',
      'es': 'Cancelar',
      'fr': 'Annuler',
      'de': 'Abbrechen',
      'ar': 'إلغاء',
    },
    'family_add_action': {
      'tr': 'Ekle',
      'en': 'Add',
      'es': 'Agregar',
      'fr': 'Ajouter',
      'de': 'Hinzufügen',
      'ar': 'إضافة',
    },
    'family_update_action': {
      'tr': 'Güncelle',
      'en': 'Update',
      'es': 'Actualizar',
      'fr': 'Mettre à jour',
      'de': 'Aktualisieren',
      'ar': 'تحديث',
    },
    'family_name_label': {
      'tr': 'Ad Soyad',
      'en': 'Full Name',
      'es': 'Nombre Completo',
      'fr': 'Nom Complet',
      'de': 'Vollständiger Name',
      'ar': 'الاسم الكامل',
    },
    'family_name_required': {
      'tr': 'Ad soyad gerekli',
      'en': 'Full name required',
      'es': 'Nombre completo requerido',
      'fr': 'Nom complet requis',
      'de': 'Vollständiger Name erforderlich',
      'ar': 'الاسم الكامل مطلوب',
    },
    'family_age_label': {
      'tr': 'Yaş',
      'en': 'Age',
      'es': 'Edad',
      'fr': 'Âge',
      'de': 'Alter',
      'ar': 'العمر',
    },
    'family_age_required': {
      'tr': 'Yaş gerekli',
      'en': 'Age required',
      'es': 'Edad requerida',
      'fr': 'Âge requis',
      'de': 'Alter erforderlich',
      'ar': 'العمر مطلوب',
    },
    'family_age_invalid': {
      'tr': 'Geçerli bir yaş girin',
      'en': 'Enter a valid age',
      'es': 'Ingrese una edad válida',
      'fr': 'Entrez un âge valide',
      'de': 'Geben Sie ein gültiges Alter ein',
      'ar': 'أدخل عمرًا صالحًا',
    },
    'family_gender_label': {
      'tr': 'Cinsiyet',
      'en': 'Gender',
      'es': 'Género',
      'fr': 'Genre',
      'de': 'Geschlecht',
      'ar': 'الجنس',
    },
    'family_relation_label': {
      'tr': 'Yakınlık Derecesi',
      'en': 'Relation',
      'es': 'Relación',
      'fr': 'Relation',
      'de': 'Beziehung',
      'ar': 'صلة القرابة',
    },
    'family_relation_spouse': {
      'tr': 'Eş',
      'en': 'Spouse',
      'es': 'Cónyuge',
      'fr': 'Conjoint',
      'de': 'Ehepartner',
      'ar': 'الزوج/الزوجة',
    },
    'family_relation_child': {
      'tr': 'Çocuk',
      'en': 'Child',
      'es': 'Hijo',
      'fr': 'Enfant',
      'de': 'Kind',
      'ar': 'طفل',
    },
    'family_relation_father': {
      'tr': 'Baba',
      'en': 'Father',
      'es': 'Padre',
      'fr': 'Père',
      'de': 'Vater',
      'ar': 'أب',
    },
    'family_relation_mother': {
      'tr': 'Anne',
      'en': 'Mother',
      'es': 'Madre',
      'fr': 'Mère',
      'de': 'Mutter',
      'ar': 'أم',
    },
    'family_relation_sibling': {
      'tr': 'Kardeş',
      'en': 'Sibling',
      'es': 'Hermano',
      'fr': 'Frère/Sœur',
      'de': 'Geschwister',
      'ar': 'أخ/أخت',
    },
    'family_relation_grandmother': {
      'tr': 'Büyükanne',
      'en': 'Grandmother',
      'es': 'Abuela',
      'fr': 'Grand-mère',
      'de': 'Großmutter',
      'ar': 'جدة',
    },
    'family_relation_grandfather': {
      'tr': 'Büyükbaba',
      'en': 'Grandfather',
      'es': 'Abuelo',
      'fr': 'Grand-père',
      'de': 'Großvater',
      'ar': 'جد',
    },
    'family_relation_parent': {
      'tr': 'Ebeveyn',
      'en': 'Parent',
      'es': 'Padre/Madre',
      'fr': 'Parent',
      'de': 'Elternteil',
      'ar': 'أحد الوالدين',
    },
    'family_relation_grandparent': {
      'tr': 'Büyükanne/Büyükbaba',
      'en': 'Grandparent',
      'es': 'Abuelo/Abuela',
      'fr': 'Grand-parent',
      'de': 'Großelternteil',
      'ar': 'جد/جدة',
    },
    'family_relation_grandchild': {
      'tr': 'Torun',
      'en': 'Grandchild',
      'es': 'Nieto',
      'fr': 'Petit-enfant',
      'de': 'Enkelkind',
      'ar': 'حفيد',
    },
    'family_relation_other': {
      'tr': 'Diğer',
      'en': 'Other',
      'es': 'Otro',
      'fr': 'Autre',
      'de': 'Andere',
      'ar': 'آخر',
    },
    'family_invite_info': {
      'tr': 'Bu kişi HemoAI uygulamasını kullanıyor olmalıdır. Davet gönderilecek ve onaylaması beklenecek.',
      'en': 'This person must be using the HemoAI app. An invitation will be sent and must be accepted.',
      'es': 'Esta persona debe usar la aplicación HemoAI. Se enviará una invitación y debe aceptarla.',
      'fr': 'Cette personne doit utiliser l\'application HemoAI. Une invitation sera envoyée et devra être acceptée.',
      'de': 'Diese Person muss die HemoAI-App verwenden. Eine Einladung wird gesendet und muss akzeptiert werden.',
      'ar': 'يجب أن يستخدم هذا الشخص تطبيق HemoAI. سيتم إرسال دعوة ويجب قبولها.',
    },
    'family_invite_privacy_title': {
      'tr': 'Gizlilik ve Veri Paylaşımı',
      'en': 'Privacy & Data Sharing',
    },
    'family_invite_privacy_body': {
      'tr': 'Davet edilen kişi onayladığında:\n• Karşılıklı olarak temel profil bilgileri (ad, ilişki) görünür\n• Sınırlı sağlık özetleri (ör. su tüketimi toplamları, test var/yok bilgisi) görüntülenebilir\n• Detaylı raporlar sadece kişi özellikle paylaşmayı seçerse görünür\n• İstendiğinde Aile Paneli üzerinden bağlantı kaldırılabilir',
      'en': 'When the invited person accepts:\n• You will both see basic profile info (name, relation)\n• Limited health summaries (e.g., water intake totals, test presence) may be visible\n• Detailed reports are not shared unless the person explicitly chooses to share\n• You can remove the connection anytime from the Family Panel',
    },
    'family_phone_label': {
      'tr': 'Telefon Numarası',
      'en': 'Phone Number',
      'es': 'Número de Teléfono',
      'fr': 'Numéro de Téléphone',
      'de': 'Telefonnummer',
      'ar': 'رقم الهاتف',
    },
    'family_phone_hint': {
      'tr': '5551234567',
      'en': '5551234567',
      'es': '5551234567',
      'fr': '5551234567',
      'de': '5551234567',
      'ar': '5551234567',
    },
    'family_phone_required': {
      'tr': 'Telefon numarası gerekli',
      'en': 'Phone number required',
      'es': 'Número de teléfono requerido',
      'fr': 'Numéro de téléphone requis',
      'de': 'Telefonnummer erforderlich',
      'ar': 'رقم الهاتف مطلوب',
    },
    'family_phone_invalid': {
      'tr': 'Geçerli bir telefon numarası girin',
      'en': 'Enter a valid phone number',
      'es': 'Ingrese un número de teléfono válido',
      'fr': 'Entrez un numéro de téléphone valide',
      'de': 'Geben Sie eine gültige Telefonnummer ein',
      'ar': 'أدخل رقم هاتف صالحًا',
    },
    'family_invite_message_label': {
      'tr': 'Davet Mesajı',
      'en': 'Invitation Message',
      'es': 'Mensaje de Invitación',
      'fr': 'Message d\'Invitation',
      'de': 'Einladungstext',
      'ar': 'رسالة الدعوة',
    },
    'family_invite_message_required': {
      'tr': 'Davet mesajı gerekli',
      'en': 'Invitation message required',
      'es': 'Mensaje de invitación requerido',
      'fr': 'Message d\'invitation requis',
      'de': 'Einladungstext erforderlich',
      'ar': 'رسالة الدعوة مطلوبة',
    },
    'family_send_invite': {
      'tr': 'Davet Gönder',
      'en': 'Send Invitation',
      'es': 'Enviar Invitación',
      'fr': 'Envoyer l\'Invitation',
      'de': 'Einladung Senden',
      'ar': 'إرسال الدعوة',
    },
    'family_share_hemogram': {
      'tr': 'Hemogram Paylaş',
      'en': 'Share Hemogram',
    },
    'family_share_with_member': {
      'tr': '{name} ile hemogram paylaş',
      'en': 'Share hemogram with {name}',
    },
    'family_hemogram_summary': {
      'tr': 'Hemogram Özeti',
      'en': 'Hemogram Summary',
    },
    'family_and_more_values': {
      'tr': 've {count} değer daha...',
      'en': 'and {count} more values...',
    },
    'family_choose_share_method': {
      'tr': 'Paylaşım Yöntemini Seçin',
      'en': 'Choose Share Method',
    },
    'family_share_via_message': {
      'tr': 'Mesaj Gönder',
      'en': 'Send Message',
    },
    'family_share_message_desc': {
      'tr': 'SMS ile paylaş',
      'en': 'Share via SMS',
    },
    'family_share_via_pdf': {
      'tr': 'PDF Oluştur',
      'en': 'Create PDF',
    },
    'family_share_pdf_desc': {
      'tr': 'PDF raporu',
      'en': 'PDF report',
    },
    'family_health_overview': {
      'tr': 'Sağlık Genel Bakış',
      'en': 'Health Overview',
    },
    'family_stats_subtitle': {
      'tr': 'Aile üyelerinizin sağlık durumu',
      'en': 'Health status of your family members',
    },
    'family_health_actions': {
      'tr': 'Sağlık İşlemleri',
      'en': 'Health Actions',
    },
    'family_view_profile': {
      'tr': 'Profili Görüntüle',
      'en': 'View Profile',
    },
    'family_no_hemogram_to_share': {
      'tr': 'Paylaşılacak hemogram verisi bulunamadı',
      'en': 'No hemogram data found to share',
    },
    'family_hemogram_shared': {
      'tr': 'Hemogram başarıyla paylaşıldı',
      'en': 'Hemogram shared successfully',
    },
    'family_share_error': {
      'tr': 'Paylaşım sırasında bir hata oluştu',
      'en': 'An error occurred while sharing',
    },
    'family_default_invite_message': {
      'tr': 'Sizi aile sağlık panelime eklemek istiyorum.',
      'en': 'I would like to add you to my family health panel.',
      'es': 'Me gustaría agregarte a mi panel de salud familiar.',
      'fr': 'Je voudrais vous ajouter à mon panneau de santé familiale.',
      'de': 'Ich möchte Sie zu meinem Familien-Gesundheitspanel hinzufügen.',
      'ar': 'أرغب في إضافتك إلى لوحة الصحة العائلية الخاصة بي.',
    },
    'notifications_reminders': {
      'tr': 'Bildirimler & Hatırlatıcı',
      'en': 'Notifications & Reminders',
      'es': 'Notificaciones y Recordatorios',
      'fr': 'Notifications et Rappels',
      'de': 'Benachrichtigungen & Erinnerungen',
      'ar': 'الإشعارات والتذكيرات',
    },
    // 'help_support' defined earlier; 'continue_as_guest' defined earlier
    // 'about_hemoai' defined earlier in common section
    'app_description': {
      'tr': 'HemoAI - Akıllı Hemogram Analiz Asistanı',
      'en': 'HemoAI - Smart Hemogram Analysis Assistant',
      'es': 'HemoAI - Asistente Inteligente de Análisis de Hemograma',
      'fr': 'HemoAI - Assistant d\'Analyse d\'Hémogramme Intelligent',
      'de': 'HemoAI - Intelligenter Hämogramm-Analyse-Assistent',
      'ar': 'HemoAI - مساعد التحليل الذكي للهيموجرام',
    },
    'version': {
      'tr': 'Versiyon',
      'en': 'Version',
      'es': 'Versión',
      'fr': 'Version',
      'de': 'Version',
      'ar': 'الإصدار',
    },
    'development_date': {
      'tr': 'Geliştirilme Tarihi',
      'en': 'Development Date',
      'es': 'Fecha de Desarrollo',
      'fr': 'Date de Développement',
      'de': 'Entwicklungsdatum',
      'ar': 'تاريخ التطوير',
    },
    'september_2025': {
      'tr': 'Eylül 2025',
      'en': 'September 2025',
      'es': 'Septiembre 2025',
      'fr': 'Septembre 2025',
      'de': 'September 2025',
      'ar': 'سبتمبر 2025',
    },
    // Data Import
    'data_import_title': {
      'tr': 'Veri İçe Aktarma',
      'en': 'Data Import',
    },
    'data_import_welcome': {
      'tr': 'Tek tıkla kan tahlillerinizi içe aktarın',
      'en': 'Import your blood tests in one tap',
    },
    'data_import_subtitle': {
      'tr': 'e-Devlet, QR kodu veya dosyadan modern ve pratik içe aktarma',
      'en': 'Modern, quick imports from e-Government, QR code, or file',
    },
    'import_options_title': {
      'tr': 'İçe Aktarma Seçenekleri',
      'en': 'Import Options',
    },
    'import_from_edevlet': {
      'tr': 'e-Devlet ile İçe Aktar',
      'en': 'Import via e-Government',
    },
    'import_edevlet_description': {
      'tr': 'e-Devlet sağlık sonuçlarınızı güvenle içe aktarın',
      'en': 'Securely import your e-Government health results',
    },
    'import_from_qr': {
      'tr': 'QR Kod ile İçe Aktar',
      'en': 'Import via QR Code',
    },
    'import_qr_description': {
      'tr': 'Laboratuvar sonuç QR kodunu tarayın',
      'en': 'Scan your lab result QR code',
    },
    'import_from_file': {
      'tr': 'Dosyadan İçe Aktar',
      'en': 'Import from File',
    },
    'import_from_image': {
      'en': 'Import from image (OCR)',
      'tr': 'Görselden içe aktar (OCR)',
    },
    'import_image_description': {
      'en': 'Take a photo or choose an image of your lab report and extract values with on-device OCR.',
      'tr': 'Laboratuvar raporunuzun fotoğrafını çekin veya bir görsel seçin; cihaz içi OCR ile değerleri çıkarın.',
    },
    'image_processing': {
      'en': 'Processing image…',
      'tr': 'Görsel işleniyor…',
    },
    'image_import_failed': {
      'en': 'Image import failed',
      'tr': 'Görsel içe aktarma başarısız',
    },
    'image_processing_error': {
      'en': 'An error occurred while processing the image',
      'tr': 'Görsel işlenirken bir hata oluştu',
    },
    'import_file_description': {
      'tr': 'PDF/JSON/CSV/XML dosyalarından içe aktarın',
      'en': 'Import from PDF/JSON/CSV/XML files',
    },
    'import_manual_entry': {
      'tr': 'Manuel Giriş',
      'en': 'Manual Entry',
    },
    'import_manual_description': {
      'tr': 'Değerleri kendiniz girerek kaydedin',
      'en': 'Enter values yourself and save',
    },
    'import_from_text': {
      'tr': 'Metinden İçe Aktar',
      'en': 'Import from Text',
    },
    'import_text_description': {
      'tr': 'Herhangi bir platformdan kopyaladığınız metni yapıştırarak içe aktarın',
      'en': 'Paste text copied from any platform to import',
    },
    'paste_text_title': {
      'tr': 'Metin Yapıştırarak İçe Aktar',
      'en': 'Import by Pasting Text',
    },
    'paste_from_clipboard': {
      'tr': 'Panodan yapıştır',
      'en': 'Paste from clipboard',
    },
    'paste_text_instructions': {
      'tr': 'Lab sitesi, e-Devlet veya hastane uygulamalarından kopyaladığınız metni buraya yapıştırın. JSON, URL veya düz metin desteklenir.',
      'en': 'Paste text copied from lab portals, e-Government, or hospital apps. JSON, URL, or plain text supported.',
    },
    'paste_text_hint': {
      'tr': 'Buraya metin yapıştırın (ör. laboratuvar sonuçları)',
      'en': 'Paste text here (e.g., lab results)',
    },
    'parse_and_import': {
      'tr': 'Çözümle ve İçe Aktar',
      'en': 'Parse & Import',
    },
    'no_text_provided': {
      'tr': 'Metin bulunamadı',
      'en': 'No text provided',
    },
    'parsing_text': {
      'tr': 'Metin çözümlemesi yapılıyor...',
      'en': 'Parsing text...',
    },
    'edevlet_login_title': {
      'tr': 'e-Devlet Girişi',
      'en': 'e-Government Login',
    },
    'edevlet_login_description': {
      'tr': 'TC Kimlik No ve e-Devlet şifreniz ile giriş yaparak kan tahlili sonuçlarınızı içe aktarın. Verileriniz güvenle işlenir.',
      'en': 'Log in with your ID number and e-Government password to import blood test results. Your data is processed securely.',
    },
    'tc_kimlik_no': {
      'tr': 'TC Kimlik No',
      'en': 'National ID Number',
    },
    // use common 'password' key defined earlier
    'edevlet_security_notice': {
      'tr': 'Bilgileriniz yalnızca içe aktarma işlemi için kullanılır ve saklanmaz.',
      'en': 'Your credentials are used only for import and are not stored.',
    },
    // use common 'cancel' key defined earlier
    'connect_and_import': {
      'tr': 'Bağlan ve İçe Aktar',
      'en': 'Connect & Import',
    },
    'edevlet_or_paste_label': {
      'tr': 'Alternatif: e-Devlet metnini/HTML’yi buraya yapıştırın',
      'en': 'Alternative: Paste e-Government text/HTML here',
    },
    'edevlet_paste_hint': {
      'tr': 'e-Devlet kan tahlili sayfasından kopyaladığınız metni veya HTML’yi yapıştırın',
      'en': 'Paste text or HTML copied from e-Government lab results page',
    },
    'edevlet_import_snippet_button': {
      'tr': 'Metni İçe Aktar',
      'en': 'Import Text',
    },
    'edevlet_credentials_required': {
      'tr': 'TC Kimlik No ve şifre gereklidir',
      'en': 'ID number and password are required',
    },
    'edevlet_connecting': {
      'tr': 'e-Devlet bağlantısı kuruluyor...',
      'en': 'Connecting to e-Government...',
    },
    'import_success_count': {
      'tr': '{count} test başarıyla içe aktarıldı',
      'en': '{count} test(s) imported successfully',
    },
    'import_failed': {
      'tr': 'İçe aktarma başarısız',
      'en': 'Import failed',
    },
    'import_error': {
      'tr': 'İçe aktarma sırasında bir hata oluştu',
      'en': 'An error occurred during import',
    },
    'qr_scanning': {
      'tr': 'QR kod taranıyor...',
      'en': 'Scanning QR code...',
    },
    'qr_scan_failed': {
      'tr': 'QR kod içe aktarılamadı',
      'en': 'QR code import failed',
    },
    'file_processing': {
      'tr': 'Dosya işleniyor...',
      'en': 'Processing file...',
    },
    'file_import_failed': {
      'tr': 'Dosya içe aktarılamadı',
      'en': 'File import failed',
    },
    'file_processing_error': {
      'tr': 'Dosya işlenirken hata oluştu',
      'en': 'An error occurred while processing the file',
    },
    'login_required_for_save': {
      'tr': 'Kaydetmek için giriş yapmalısınız',
      'en': 'You must be logged in to save',
    },
    'features': {
      'tr': 'Özellikler:',
      'en': 'Features:',
      'es': 'Características:',
      'fr': 'Fonctionnalités:',
      'de': 'Funktionen:',
      'ar': 'الميزات:',
    },
    'ai_powered_hemogram_analysis': {
      'tr': 'AI destekli hemogram analizi',
      'en': 'AI-powered hemogram analysis',
      'es': 'Análisis de hemograma con IA',
      'fr': 'Analyse d\'hémogramme alimentée par l\'IA',
      'de': 'KI-gestützte Hämogramm-Analyse',
      'ar': 'تحليل الهيموجرام بالذكاء الاصطناعي',
    },
    'personalized_diet_recommendations': {
      'tr': 'Kişiselleştirilmiş diyet önerileri',
      'en': 'Personalized diet recommendations',
      'es': 'Recomendaciones de dieta personalizadas',
      'fr': 'Recommandations de régime personnalisées',
      'de': 'Personalisierte Diätempfehlungen',
      'ar': 'توصيات نظام غذائي مخصصة',
    },
    'family_health_tracking_system': {
      'tr': 'Aile sağlık takip sistemi',
      'en': 'Family health tracking system',
      'es': 'Sistema de seguimiento de salud familiar',
      'fr': 'Système de suivi de la santé familiale',
      'de': 'Familien-Gesundheitsverfolgungssystem',
      'ar': 'نظام تتبع الصحة العائلية',
    },
    'alternative_medicine_guide': {
      'tr': 'Alternatif tıp rehberi',
      'en': 'Alternative medicine guide',
      'es': 'Guía de medicina alternativa',
      'fr': 'Guide de médecine alternative',
      'de': 'Alternativmedizin-Leitfaden',
      'ar': 'دليل الطب البديل',
    },
    'smart_reminder_system': {
      'tr': 'Akıllı hatırlatıcı sistemi',
      'en': 'Smart reminder system',
      'es': 'Sistema de recordatorios inteligente',
      'fr': 'Système de rappel intelligent',
      'de': 'Intelligentes Erinnerungssystem',
      'ar': 'نظام التذكير الذكي',
    },
    'app_disclaimer': {
      'tr': 'HemoAI, hemogram sonuçlarınızı analiz ederek size kişiselleştirilmiş sağlık önerileri sunar. Bu uygulama tıbbi tanı koymaz, sadece bilgi amaçlıdır.',
      'en': 'HemoAI analyzes your hemogram results and provides personalized health recommendations. This application does not make medical diagnoses and is for informational purposes only.',
      'es': 'HemoAI analiza los resultados de su hemograma y proporciona recomendaciones de salud personalizadas. Esta aplicación no realiza diagnósticos médicos y es solo para fines informativos.',
      'fr': 'HemoAI analyse les résultats de votre hémogramme et fournit des recommandations de santé personnalisées. Cette application ne fait pas de diagnostic médical et est à des fins informatives seulement.',
      'de': 'HemoAI analysiert Ihre Hämogramm-Ergebnisse und bietet personalisierte Gesundheitsempfehlungen. Diese Anwendung stellt keine medizinischen Diagnosen und dient nur zu Informationszwecken.',
      'ar': 'يحلل HemoAI نتائج الهيموجرام الخاصة بك ويقدم توصيات صحية مخصصة. هذا التطبيق لا يقوم بالتشخيص الطبي وهو لأغراض إعلامية فقط.',
    },
    
    'medication_reminder': {
      'tr': 'İlaç Hatırlatıcısı',
      'en': 'Medication Reminder',
      'es': 'Recordatorio de Medicamentos',
      'fr': 'Rappel de Médicament',
      'de': 'Medikamenten-Erinnerung',
      'ar': 'تذكير الدواء',
    },
    'appointment': {
      'tr': 'Randevu',
      'en': 'Appointment',
      'es': 'Cita',
      'fr': 'Rendez-vous',
      'de': 'Termin',
      'ar': 'موعد',
    },
    'test_analysis': {
      'tr': 'Test/Tahlil',
      'en': 'Test/Analysis',
      'es': 'Prueba/Análisis',
      'fr': 'Test/Analyse',
      'de': 'Test/Analyse',
      'ar': 'فحص/تحليل',
    },
    'health_alert': {
      'tr': 'Sağlık Uyarısı',
      'en': 'Health Alert',
      'es': 'Alerta de Salud',
      'fr': 'Alerte Santé',
      'de': 'Gesundheitswarnung',
      'ar': 'تنبيه صحي',
    },
    'system': {
      'tr': 'Sistem',
      'en': 'System',
      'es': 'Sistema',
      'fr': 'Système',
      'de': 'System',
      'ar': 'النظام',
    },
    'general': {
      'tr': 'Genel',
      'en': 'General',
      'es': 'General',
      'fr': 'Général',
      'de': 'Allgemein',
      'ar': 'عام',
    },
    'just_now': {
      'tr': 'Az önce',
      'en': 'Just now',
      'es': 'Ahora mismo',
      'fr': 'À l\'instant',
      'de': 'Gerade jetzt',
      'ar': 'الآن',
    },
    'received_time': {
      'tr': 'Alındığı Zaman',
      'en': 'Received Time',
      'es': 'Hora de Recepción',
      'fr': 'Heure de Réception',
      'de': 'Empfangszeit',
      'ar': 'وقت الاستلام',
    },
    'details': {
      'tr': 'Detaylar',
      'en': 'Details',
      'es': 'Detalles',
      'fr': 'Détails',
      'de': 'Details',
      'ar': 'التفاصيل',
    },
    'quick_actions': {
      'tr': 'Hızlı İşlemler',
      'en': 'Quick Actions',
      'es': 'Acciones Rápidas',
      'fr': 'Actions Rapides',
      'de': 'Schnellaktionen',
      'ar': 'الإجراءات السريعة',
    },
    'add_new_medication': {
      'tr': 'Yeni ilaç ekle',
      'en': 'Add new medication',
      'es': 'Agregar nuevo medicamento',
      'fr': 'Ajouter un nouveau médicament',
      'de': 'Neues Medikament hinzufügen',
      'ar': 'إضافة دواء جديد',
    },
    'doctor_appointment': {
      'tr': 'Doktor randevusu',
      'en': 'Doctor appointment',
      'es': 'Cita médica',
      'fr': 'Rendez-vous médical',
      'de': 'Arzttermin',
      'ar': 'موعد طبي',
    },
    'test_reminder': {
      'tr': 'Test Hatırlatıcısı',
      'en': 'Test Reminder',
      'es': 'Recordatorio de Prueba',
      'fr': 'Rappel de Test',
      'de': 'Test-Erinnerung',
      'ar': 'تذكير الفحص',
    },
    'analysis_time': {
      'tr': 'Tahlil zamanı',
      'en': 'Analysis time',
      'es': 'Hora del análisis',
      'fr': 'Heure d\'analyse',
      'de': 'Analysezeit',
      'ar': 'وقت التحليل',
    },
    'hemogram_values': {
      'tr': 'Hemogram Değerleri',
      'en': 'Hemogram Values',
      'es': 'Valores del Hemograma',
      'fr': 'Valeurs de l\'Hémogramme',
      'de': 'Hämogramm Werte',
      'ar': 'قيم تحليل الدم',
    },
    'test_history': {
      'tr': 'Test Geçmişi',
      'en': 'Test History',
      'es': 'Historial de Pruebas',
      'fr': 'Historique des Tests',
      'de': 'Test-Verlauf',
      'ar': 'تاريخ الفحوصات',
    },
    'general_status_good': {
      'tr': 'Genel Durum İyi',
      'en': 'General Status Good',
      'es': 'Estado General Bueno',
      'fr': 'État Général Bon',
      'de': 'Allgemeinzustand Gut',
      'ar': 'الحالة العامة جيدة',
    },
    'attention_required': {
      'tr': 'Dikkat Gereken Alanlar Var',
      'en': 'Areas Requiring Attention',
      'es': 'Áreas que Requieren Atención',
      'fr': 'Zones Nécessitant une Attention',
      'de': 'Bereiche Benötigen Aufmerksamkeit',
      'ar': 'مناطق تتطلب الانتباه',
    },
    'detailed_recommendations': {
      'tr': 'Detaylı Tavsiyeler',
      'en': 'Detailed Recommendations',
      'es': 'Recomendaciones Detalladas',
      'fr': 'Recommandations Détaillées',
      'de': 'Detaillierte Empfehlungen',
      'ar': 'توصيات مفصلة',
    },
    'quick_excel': {
      'tr': 'Hızlı Excel',
      'en': 'Quick Excel',
      'es': 'Excel Rápido',
      'fr': 'Excel Rapide',
      'de': 'Schnelles Excel',
      'ar': 'إكسل سريع',
    },
    // Analysis Screen additions
    'share_report_button': {
      'en': 'Share Report',
      'tr': 'Raporu Paylaş',
    },
    // status_* keys defined earlier
    'normal_range_template': {
      'en': 'Normal: {min} - {max}',
      'tr': 'Normal: {min} - {max}',
    },
    'abnormal_values_heading': {
      'en': 'Values outside normal range:',
      'tr': 'Normalin dışında bulunan değerler:',
    },
    'all_values_normal_message': {
      'en': 'All your hemogram values are within normal ranges. Keep maintaining your health with regular check-ups.',
      'tr': 'Tüm hemogram değerleriniz normal aralıkta bulunuyor. Sağlığınızı korumak için düzenli kontroller yaptırmaya devam edin.',
    },
    'overall_assessment_normal': {
      'en': 'Your hemogram values are generally within normal ranges. Keep up the good habits!',
      'tr': 'Hemogram değerleriniz genel olarak normal aralıkta. Sağlığınızı korumaya devam edin!',
    },
    'overall_assessment_some_abnormal': {
      'en': 'Some values are noteworthy. Consider consulting your doctor.',
      'tr': 'Bazı değerleriniz dikkat çekici. Doktorunuzla görüşmenizi öneririz.',
    },
    'overall_assessment_many_abnormal': {
      'en': 'Several values are outside the normal range. A prompt medical consultation is recommended.',
      'tr': 'Birkaç değeriniz normal aralığın dışında. Acil doktor kontrolü önerilir.',
    },
    'hemoglobin_low_recommendation': {
      'en': 'Low hemoglobin: Consume iron-rich foods (red meat, spinach, lentils)',
      'tr': 'Hemoglobin düşük: Demir açısından zengin besinler tüketin (kırmızı et, ıspanak, mercimek)',
    },
    'iron_low_recommendation': {
      'en': 'Iron deficiency: Increase iron intake with vitamin C',
      'tr': 'Demir eksikliği: C vitamini ile birlikte demir alımını artırın',
    },
    'wbc_high_recommendation': {
      'en': 'High white blood cells: Watch for infection signs, drink plenty of fluids',
      'tr': 'Lökosit yüksek: Enfeksiyon belirtilerine dikkat edin, bol sıvı tüketin',
    },
    'recommendation_default_1': {
      'en': 'Exercise regularly and maintain a healthy diet',
      'tr': 'Düzenli egzersiz yapın ve sağlıklı beslenmeye devam edin',
    },
    'recommendation_default_2': {
      'en': 'Have a hemogram test at least twice a year',
      'tr': 'Yılda en az 2 kez hemogram kontrolü yaptırın',
    },
    'recommendation_default_3': {
      'en': 'Drink plenty of water and manage stress effectively',
      'tr': 'Bol su için ve stres yönetimini ihmal etmeyin',
    },
    'recommendation_follow_up_doctor': {
      'en': 'Discuss these results with your doctor',
      'tr': 'Doktorunuzla bu sonuçları değerlendirin',
    },
    'detailed_health_advice_title': {
      'en': 'Detailed Health Advice',
      'tr': 'Detaylı Sağlık Tavsiyeleri',
    },
    'general_health_tips_heading': {
      'en': 'General Health Tips:',
      'tr': 'Genel Sağlık Önerileri:',
    },
    'tip_water_intake': {
      'en': 'Drink at least 8 glasses of water daily',
      'tr': 'Günde en az 8 bardak su için',
    },
    'tip_exercise': {
      'en': 'Exercise 3-4 times a week',
      'tr': 'Haftada 3-4 kez egzersiz yapın',
    },
    'tip_balanced_diet': {
      'en': 'Follow a balanced diet program',
      'tr': 'Dengeli beslenme programı uygulayın',
    },
    'tip_sleep': {
      'en': 'Maintain a regular sleep routine (7-8 hours)',
      'tr': 'Düzenli uyku düzeni sağlayın (7-8 saat)',
    },
    'tip_stress_management': {
      'en': 'Learn stress management techniques',
      'tr': 'Stres yönetimi tekniklerini öğrenin',
    },
    'checks_heading': {
      'en': 'Checkups:',
      'tr': 'Kontroller:',
    },
    'check_semiannual_hemogram': {
      'en': 'Hemogram test every 6 months',
      'tr': '6 ayda bir hemogram kontrolü',
    },
    'check_annual_general': {
      'en': 'Annual general health checkup',
      'tr': 'Yılda bir genel sağlık checkup',
    },
    'check_follow_abnormal': {
      'en': 'Doctor follow-up for abnormal values',
      'tr': 'Anormal değerler için doktor takibi',
    },
    'report_share_dialog_title': {
      'en': 'Share Report',
      'tr': 'Rapor Paylaşımı',
    },
    'report_copied': {
      'en': 'Report copied!',
      'tr': 'Rapor kopyalandı!',
    },
    'copy': {
      'en': 'Copy',
      'tr': 'Kopyala',
    },
    'report_header': {
      'en': 'HemoAI - Hemogram Analysis Report',
      'tr': 'HemoAI - Hemogram Analiz Raporu',
    },
    'report_section_values': {
      'en': 'HEMOGRAM VALUES:',
      'tr': 'HEMOGRAM DEĞERLERİ:',
    },
    'report_section_evaluation': {
      'en': 'EVALUATION:',
      'tr': 'DEĞERLENDİRME:',
    },
    'pdf_report_dialog_title': {
      'en': 'Create PDF Report',
      'tr': 'PDF Rapor Oluştur',
    },
    'pdf_report_intro': {
      'en': 'Your hemogram analysis report will be generated as a PDF.',
      'tr': 'Hemogram analiz raporunuz PDF formatında oluşturulacak.',
    },
    'report_content_heading': {
      'en': 'Report Content:',
      'tr': 'Rapor İçeriği:',
    },
    'report_content_item_values': {
      'en': 'Hemogram values and results',
      'tr': 'Hemogram değerleri ve sonuçları',
    },
    'report_content_item_ai_analysis': {
      'en': 'AI analysis results',
      'tr': 'AI analiz sonuçları',
    },
    'report_content_item_health_tips': {
      'en': 'Health recommendations',
      'tr': 'Sağlık önerileri',
    },
    'report_content_item_risk_assessment': {
      'en': 'Risk assessment',
      'tr': 'Risk değerlendirmesi',
    },
    'report_content_item_date': {
      'en': 'Date',
      'tr': 'Tarih',
    },
    'create_pdf_button': {
      'en': 'Create PDF',
      'tr': 'PDF Oluştur',
    },
    'pdf_generating': {
      'en': 'Generating PDF report...',
      'tr': 'PDF raporu oluşturuluyor...',
    },
    'pdf_generated_success': {
      'en': 'PDF report successfully generated and downloaded!',
      'tr': 'PDF raporu başarıyla oluşturuldu ve indirildi!',
    },
    'excel_export_title': {
      'en': 'Export to Excel',
      'tr': 'Excel\'e Aktar',
    },
    'excel_export_intro': {
      'en': 'Your hemogram data will be exported as an Excel table.',
      'tr': 'Hemogram verileriniz Excel tablosu olarak dışa aktarılacak.',
    },
    'excel_content_heading': {
      'en': 'Excel Content:',
      'tr': 'Excel İçeriği:',
    },
    'excel_content_item_all_params': {
      'en': 'All hemogram parameters',
      'tr': 'Tüm hemogram parametreleri',
    },
    'excel_content_item_normal_ranges': {
      'en': 'Normal value ranges',
      'tr': 'Normal değer aralıkları',
    },
    'excel_content_item_status_analysis': {
      'en': 'Status analysis (Normal/High/Low)',
      'tr': 'Durum analizi (Normal/Yüksek/Düşük)',
    },
    'excel_content_item_test_history': {
      'en': 'Test history (if any)',
      'tr': 'Test geçmişi (varsa)',
    },
    'excel_content_item_charts': {
      'en': 'Charts and graphs',
      'tr': 'Grafik ve çizelgeler',
    },
    'create_excel_button': {
      'en': 'Create Excel',
      'tr': 'Excel Oluştur',
    },
    'excel_generating': {
      'en': 'Preparing Excel file...',
      'tr': 'Excel dosyası hazırlanıyor...',
    },
    'excel_generated_success': {
      'en': 'Excel file successfully generated!',
      'tr': 'Excel dosyası başarıyla oluşturuldu!',
    },
    'email_send_title': {
      'en': 'Send Email',
      'tr': 'E-posta Gönder',
    },
    'email_send_intro': {
      'en': 'Send your hemogram report via email:',
      'tr': 'Hemogram raporunuzu e-posta ile gönderin:',
    },
    'email_address_label': {
      'en': 'Email Address',
      'tr': 'E-posta Adresi',
    },
    'email_address_hint': {
      'en': 'example@email.com',
      'tr': 'ornek@email.com',
    },
    'email_content_heading': {
      'en': 'Content to be sent:',
      'tr': 'Gönderilecek İçerik:',
    },
    'email_content_item_pdf': {
      'en': 'PDF report (as attachment)',
      'tr': 'PDF rapor (ek dosya olarak)',
    },
    'email_content_item_analysis_summary': {
      'en': 'Analysis summary',
      'tr': 'Analiz sonuçları özeti',
    },
    'email_content_item_health_tips': {
      'en': 'Health recommendations',
      'tr': 'Sağlık önerileri',
    },
    'email_invalid': {
      'en': 'Please enter a valid email address',
      'tr': 'Lütfen geçerli bir e-posta adresi girin',
    },
    'email_send_button': {
      'en': 'Send',
      'tr': 'Gönder',
    },
    'email_sending': {
      'en': 'Sending email...',
      'tr': 'E-posta gönderiliyor...',
    },
    'email_sent_success': {
      'en': 'Report successfully sent to {email}!',
      'tr': 'Rapor {email} adresine başarıyla gönderildi!',
    },
    'patient_placeholder': {
      'en': 'Patient',
      'tr': 'Hasta',
    },
    'doctor_notes_generated_by_hemoai': {
      'en': 'Generated by HemoAI analysis.',
      'tr': 'HemoAI analizi ile oluşturulmuştur.',
    },
    'pdf_download_success': {
      'en': 'PDF report downloaded successfully!',
      'tr': 'PDF raporu başarıyla indirildi!',
    },
    'pdf_export_error_prefix': {
      'en': 'PDF export error: ',
      'tr': 'PDF export hatası: ',
    },
    'excel_download_success': {
      'en': 'Excel data downloaded successfully!',
      'tr': 'Excel verileri başarıyla indirildi!',
    },
    'excel_export_error_prefix': {
      'en': 'Excel export error: ',
      'tr': 'Excel export hatası: ',
    },
    'risk_level_low': {
      'en': 'Low',
      'tr': 'Düşük',
    },
    'risk_level_medium': {
      'en': 'Medium',
      'tr': 'Orta',
    },
    'risk_level_high': {
      'en': 'High',
      'tr': 'Yüksek',
    },
    'risk_level_very_high': {
      'en': 'Very High',
      'tr': 'Çok yüksek',
    },
    'mark_all_read': {
      'tr': 'Tümünü Okundu İşaretle',
      'en': 'Mark All as Read',
      'es': 'Marcar Todo como Leído',
      'fr': 'Marquer Tout comme Lu',
      'de': 'Alle als Gelesen Markieren',
      'ar': 'تحديد الكل كمقروء',
    },
    'unread_notifications_count': {
      'tr': '{count} okunmamış bildirim',
      'en': '{count} unread notifications',
      'es': '{count} notificaciones no leídas',
      'fr': '{count} notifications non lues',
      'de': '{count} ungelesene Benachrichtigungen',
      'ar': '{count} إشعارات غير مقروءة',
    },
    'clear_all': {
      'tr': 'Tümünü Temizle',
      'en': 'Clear All',
    },
    'all_notifications_cleared': {
      'tr': 'Tüm bildirimler temizlendi',
      'en': 'All notifications cleared',
    },
    'unread': {
      'tr': 'Okunmamış',
      'en': 'Unread',
    },
    'all': {
      'tr': 'Tümü',
      'en': 'All',
    },
    'scheduled': {
      'tr': 'Planlanan',
      'en': 'Scheduled',
    },
    'no_unread_notifications': {
      'tr': 'Okunmamış bildirim yok',
      'en': 'No unread notifications',
    },
    'no_notifications_yet': {
      'tr': 'Henüz bildirim yok',
      'en': 'No notifications yet',
      'es': 'Aún no hay notificaciones',
      'fr': 'Aucune notification pour le moment',
      'de': 'Noch keine Benachrichtigungen',
      'ar': 'لا توجد إشعارات بعد',
    },
    'no_scheduled_notifications': {
      'tr': 'Planlanan bildirim yok',
      'en': 'No scheduled notifications',
    },
    'scheduled_prefix': {
      'tr': 'Planlanan',
      'en': 'Scheduled for',
    },
    'notification_cancelled': {
      'tr': 'Bildirim iptal edildi',
      'en': 'Notification cancelled',
    },
    // Hydration weekly average
    'weekly_hydration_average': {
      'tr': '7 günlük ortalama: {avg} bardak',
      'en': '7-day average: {avg} glasses',
    },
    'your_doctor': {
      'tr': 'Doktorunuz',
      'en': 'Your Doctor',
    },
    'hemogram_test': {
      'tr': 'Hemogram Testi',
      'en': 'Hemogram Test',
    },
    'reminder_scheduled': {
      'tr': '{type} planlandı',
      'en': '{type} scheduled',
    },
    'minutes_ago': {
      'tr': '{count} dakika önce',
      'en': '{count} minutes ago',
    },
    'hours_ago': {
      'tr': '{count} saat önce',
      'en': '{count} hours ago',
    },
    'days_ago': {
      'tr': '{count} gün önce',
      'en': '{count} days ago',
    },
    'herbal_solutions_for_hemogram': {
      'tr': 'Hemogram Sorunları İçin Bitkisel Çözümler',
      'en': 'Herbal Solutions for Hemogram Issues',
      'es': 'Soluciones Herbales para Problemas del Hemograma',
      'fr': 'Solutions à Base de Plantes pour les Problèmes d\'Hémogramme',
      'de': 'Pflanzliche Lösungen für Hämogramm-Probleme',
      'ar': 'حلول عشبية لمشاكل تحليل الدم',
    },
    'support_blood_values_naturally': {
      'tr': 'Doğal bitkisel ürünlerle kan değerlerinizi destekleyin',
      'en': 'Support your blood values with natural herbal products',
      'es': 'Apoye sus valores sanguíneos con productos herbales naturales',
      'fr': 'Soutenez vos valeurs sanguines avec des produits à base de plantes naturelles',
      'de': 'Unterstützen Sie Ihre Blutwerte mit natürlichen Kräuterprodukten',
      'ar': 'ادعم قيم دمك بالمنتجات العشبية الطبيعية',
    },
    'how_to_use': {
      'tr': 'Nasıl Kullanılır?',
      'en': 'How to Use?',
      'es': '¿Cómo Usar?',
      'fr': 'Comment Utiliser?',
      'de': 'Wie zu Verwenden?',
      'ar': 'كيفية الاستخدام؟',
    },
    'step_1_register': {
      'tr': '1. Kayıt olun veya giriş yapın',
      'en': '1. Register or log in',
      'es': '1. Regístrate o inicia sesión',
      'fr': '1. Inscrivez-vous ou connectez-vous',
      'de': '1. Registrieren oder anmelden',
      'ar': '1. سجل أو قم بتسجيل الدخول',
    },
    'step_2_enter_values': {
      'tr': '2. Hemogram değerlerinizi girin',
      'en': '2. Enter your hemogram values',
      'es': '2. Ingrese sus valores de hemograma',
      'fr': '2. Saisissez vos valeurs d\'hémogramme',
      'de': '2. Geben Sie Ihre Hämogramm-Werte ein',
      'ar': '2. أدخل قيم تحليل الدم',
    },
    'step_3_view_analysis': {
      'tr': '3. AI analizinizi görüntüleyin',
      'en': '3. View your AI analysis',
      'es': '3. Vea su análisis de IA',
      'fr': '3. Consultez votre analyse IA',
      'de': '3. Betrachten Sie Ihre KI-Analyse',
      'ar': '3. اطلع على تحليل الذكاء الاصطناعي',
    },
    'step_4_diet_program': {
      'tr': '4. Kişisel diyet programınızı inceleyin',
      'en': '4. Review your personal diet program',
      'es': '4. Revise su programa de dieta personal',
      'fr': '4. Examinez votre programme de régime personnel',
      'de': '4. Überprüfen Sie Ihr persönliches Diätprogramm',
      'ar': '4. راجع برنامج النظام الغذائي الشخصي',
    },
    'step_5_family_tracking': {
      'tr': '5. Aile üyelerinizi ekleyin ve takip edin',
      'en': '5. Add and track your family members',
      'es': '5. Agregue y rastree a los miembros de su familia',
      'fr': '5. Ajoutez et suivez les membres de votre famille',
      'de': '5. Fügen Sie Familienmitglieder hinzu und verfolgen Sie sie',
      'ar': '5. أضف وتتبع أفراد عائلتك',
    },
    'important_reminders': {
      'tr': 'Önemli Hatırlatmalar:',
      'en': 'Important Reminders:',
      'es': 'Recordatorios Importantes:',
      'fr': 'Rappels Importants:',
      'de': 'Wichtige Erinnerungen:',
      'ar': 'تذكيرات مهمة:',
    },
    'not_medical_diagnosis': {
      'tr': '• Bu uygulama tıbbi tanı koymaz',
      'en': '• This app does not provide medical diagnosis',
      'es': '• Esta aplicación no proporciona diagnóstico médico',
      'fr': '• Cette application ne fournit pas de diagnostic médical',
      'de': '• Diese App stellt keine medizinische Diagnose',
      'ar': '• هذا التطبيق لا يقدم تشخيص طبي',
    },
    'not_doctor_advice': {
      'tr': '• Doktor tavsiyesi yerini tutmaz',
      'en': '• Does not replace doctor advice',
      'es': '• No reemplaza el consejo médico',
      'fr': '• Ne remplace pas les conseils du médecin',
      'de': '• Ersetzt nicht den Rat des Arztes',
      'ar': '• لا يحل محل نصائح الطبيب',
    },
    // Alternative medicine screen additional keys
    'personalized_recommendations': {
      'tr': 'Son testinize göre kişiselleştirilmiş öneriler',
      'en': 'Personalized recommendations based on your last test',
    },
    'recommended_for_you': {
      'tr': 'Size Önerilen',
      'en': 'Recommended for you',
    },
    'other_solutions': {
      'tr': 'Diğer bitkisel destekler',
      'en': 'Other herbal supports',
    },

    // Modern Settings & About section keys
    // Note: 'about_hemoai' already exists earlier with full translations; do not duplicate here.
    'app_version': {
      'tr': 'Uygulama Sürümü',
      'en': 'App Version',
    },
    'build_number': {
      'tr': 'Yapı Numarası',
      'en': 'Build Number',
    },
    'developed_by': {
      'tr': 'Geliştirici',
      'en': 'Developed by',
    },
    'developer_name': {
      'tr': 'HemoAI Team',
      'en': 'HemoAI Team',
    },
    'release_date': {
      'tr': 'Yayın Tarihi',
      'en': 'Release Date',
    },
    'app_description_detailed': {
      'tr': 'HemoAI, hemogram sonuçlarınızı yapay zeka ile analiz ederek kişiselleştirilmiş sağlık önerileri sunan modern bir sağlık uygulamasıdır. Verileriniz cihazınızda güvenle saklanır ve doktor konsültasyonlarınızı destekler.',
      'en': 'HemoAI is a modern health application that analyzes your hemogram results with artificial intelligence and provides personalized health recommendations. Your data is stored securely on your device and supports your doctor consultations.',
    },
    'key_features': {
      'tr': 'Temel Özellikler',
      'en': 'Key Features',
    },
    'feature_ai_analysis': {
      'tr': '• Yapay zeka destekli hemogram analizi',
      'en': '• AI-powered hemogram analysis',
    },
    'feature_diet_recommendations': {
      'tr': '• Kişiselleştirilmiş diyet önerileri',
      'en': '• Personalized diet recommendations',
    },
    'feature_family_tracking': {
      'tr': '• Aile sağlığı takibi',
      'en': '• Family health tracking',
    },
    'feature_secure_data': {
      'tr': '• Güvenli yerel veri saklama',
      'en': '• Secure local data storage',
    },
    'feature_export_reports': {
      'tr': '• PDF/Excel rapor dışa aktarma',
      'en': '• PDF/Excel report export',
    },
    'feature_multilingual': {
      'tr': '• Çoklu dil desteği',
      'en': '• Multi-language support',
    },
    'contact_support': {
      'tr': 'Destek İletişim',
      'en': 'Contact Support',
    },
    'support_email': {
      'tr': 'destek@hemoai.com',
      'en': 'support@hemoai.com',
    },
    'rate_app': {
      'tr': 'Uygulamayı Değerlendir',
      'en': 'Rate the App',
    },
    'share_app': {
      'tr': 'Uygulamayı Paylaş',
      'en': 'Share the App',
    },
    'licenses': {
      'tr': 'Lisanslar',
      'en': 'Licenses',
    },
    'open_source_licenses': {
      'tr': 'Açık Kaynak Lisansları',
      'en': 'Open Source Licenses',
    },
    'privacy_first': {
      'tr': 'Gizlilik Öncelikli',
      'en': 'Privacy First',
    },
    'data_stays_local': {
      'tr': 'Verileriniz cihazınızda kalır',
      'en': 'Your data stays on your device',
    },
    'no_cloud_upload': {
      'tr': 'Buluta veri gönderilmez',
      'en': 'No data uploaded to cloud',
    },
    'encrypted_backups': {
      'tr': 'Şifreli yedeklemeler',
      'en': 'Encrypted backups',
    },
    'performance_settings': {
      'tr': 'Performans Ayarları',
      'en': 'Performance Settings',
    },
    'enable_animations': {
      'tr': 'Animasyonları Etkinleştir',
      'en': 'Enable Animations',
    },
    'reduce_motion': {
      'tr': 'Hareket Azaltma',
      'en': 'Reduce Motion',
    },
    'cache_management': {
      'tr': 'Önbellek Yönetimi',
      'en': 'Cache Management',
    },
    'clear_cache': {
      'tr': 'Önbelleği Temizle',
      'en': 'Clear Cache',
    },
    'cache_cleared': {
      'tr': 'Önbellek temizlendi',
      'en': 'Cache cleared',
    },
    'auto_optimize': {
      'tr': 'Otomatik Optimizasyon',
      'en': 'Auto Optimize',
    },
    'performance_recommendations': {
      'tr': 'Performans Önerileri',
      'en': 'Performance Recommendations',
    },
    'apply_recommended_settings': {
      'tr': 'Önerilen Ayarları Uygula',
      'en': 'Apply Recommended Settings',
    },
    'performance_optimized': {
      'tr': 'Performans optimize edildi',
      'en': 'Performance optimized',
    },
    'cache_info': {
      'tr': 'Önbellek Bilgisi',
      'en': 'Cache Info',
    },
    'optimize_for_device': {
      'tr': 'Cihaz için Optimize Et',
      'en': 'Optimize for Device',
    },
    'preload_data': {
      'tr': 'Verileri Önceden Yükle',
      'en': 'Preload Data',
    },
    'advanced_performance': {
      'tr': 'Gelişmiş Performans Ayarları',
      'en': 'Advanced Performance Settings',
    },
    'detailed_performance_controls': {
      'tr': 'Detaylı performans kontrolleri ve izleme',
      'en': 'Detailed performance controls and monitoring',
    },
    'app_info': {
      'tr': 'Uygulama Bilgileri',
      'en': 'App Information',
    },
    'system_info': {
      'tr': 'Sistem Bilgileri',
      'en': 'System Information',
    },
    'emergency_see_doctor': {
      'tr': '• Acil durumlarda doktora başvurun',
      'en': '• Consult a doctor in emergencies',
      'es': '• Consulte a un médico en emergencias',
      'fr': '• Consultez un médecin en cas d\'urgence',
      'de': '• Konsultieren Sie einen Arzt in Notfällen',
      'ar': '• استشر طبيباً في حالات الطوارئ',
    },
    'regular_checkups': {
      'tr': '• Düzenli sağlık kontrollerinizi aksatmayın',
      'en': '• Do not skip regular health checkups',
      'es': '• No omita los chequeos de salud regulares',
      'fr': '• Ne sautez pas les examens de santé réguliers',
      'de': '• Verpassen Sie keine regelmäßigen Gesundheitsuntersuchungen',
      'ar': '• لا تتجاهل الفحوصات الصحية المنتظمة',
    },
    'for_support': {
      'tr': 'Destek İçin:',
      'en': 'For Support:',
      'es': 'Para Soporte:',
      'fr': 'Pour le Support:',
      'de': 'Für Support:',
      'ar': 'للدعم:',
    },
    'send_feedback': {
      'tr': '• Uygulama içi geri bildirim gönderin',
      'en': '• Send in-app feedback',
      'es': '• Envíe comentarios en la aplicación',
      'fr': '• Envoyer des commentaires dans l\'application',
      'de': '• Senden Sie In-App-Feedback',
      'ar': '• أرسل تعليقات داخل التطبيق',
    },
    'report_issues': {
      'tr': '• Sorunları bildirin',
      'en': '• Report issues',
      'es': '• Reportar problemas',
      'fr': '• Signaler les problèmes',
      'de': '• Probleme melden',
      'ar': '• أبلغ عن المشاكل',
    },
    // Alternative Medicine - Categories
    'herbal_cat_iron_deficiency': {
      'tr': 'Demir Eksikliği',
      'en': 'Iron Deficiency',
    },
    'herbal_cat_anemia': {
      'tr': 'Anemi',
      'en': 'Anemia',
    },
    'herbal_cat_immunity': {
      'tr': 'Bağışıklık',
      'en': 'Immunity',
    },
    'herbal_cat_platelets': {
      'tr': 'Trombosit',
      'en': 'Platelets',
    },
    'herbal_cat_ferritin_low': {
      'tr': 'Düşük Ferritin',
      'en': 'Low Ferritin',
    },
    'herbal_cat_rbc_support': {
      'tr': 'Eritrosit (RBC)',
      'en': 'Red Blood Cells (RBC)',
    },
    'herbal_cat_hematocrit_balance': {
      'tr': 'Hematokrit Dengesi',
      'en': 'Hematocrit Balance',
    },
    'herbal_cat_microcytosis_support': {
      'tr': 'Mikrositoz (Düşük MCV)',
      'en': 'Microcytosis (Low MCV)',
    },
    'herbal_cat_macrocytosis_support': {
      'tr': 'Makrositoz (Yüksek MCV)',
      'en': 'Macrocytosis (High MCV)',
    },
    'herbal_cat_hypochromia_support': {
      'tr': 'Hipokromi (Düşük MCH/MCHC)',
      'en': 'Hypochromia (Low MCH/MCHC)',
    },
    'herbal_cat_rdw_high_support': {
      'tr': 'Yüksek RDW',
      'en': 'High RDW',
    },
    'herbal_cat_neutrophil_support': {
      'tr': 'Nötrofil',
      'en': 'Neutrophil',
    },
    'herbal_cat_lymphocyte_support': {
      'tr': 'Lenfosit',
      'en': 'Lymphocyte',
    },
    'herbal_cat_allergy_support': {
      'tr': 'Alerji Eğilimi',
      'en': 'Allergy-Prone',
    },
    'herbal_cat_antiinflammatory_support': {
      'tr': 'Anti-enflamatuar',
      'en': 'Anti-inflammatory',
    },
    // Alternative Medicine - Herbs (names, usage, benefits, preparation, warning)
    'herb_stinging_nettle_name': {'tr': 'Isırgan Otu', 'en': 'Stinging Nettle'},
    'herb_stinging_nettle_usage': {'tr': 'Günde 2 kez çay olarak', 'en': 'Tea, twice daily'},
    'herb_stinging_nettle_benefits': {'tr': 'Doğal demir kaynağı, kan yapımını destekler', 'en': 'Natural iron source; supports blood formation'},
    'herb_stinging_nettle_preparation': {'tr': '1 çay kaşığı kurutulmuş yaprak, 1 bardak sıcak su ile demleyin', 'en': 'Infuse 1 tsp dried leaves in 1 cup hot water'},
    'herb_stinging_nettle_warning': {'tr': 'Hamilelikte doktor kontrolü gerekli', 'en': 'Consult doctor during pregnancy'},

    'herb_molasses_name': {'tr': 'Pekmez (Üzüm/Dut)', 'en': 'Molasses (Grape/Mulberry)'},
    'herb_molasses_usage': {'tr': 'Günde 1 yemek kaşığı', 'en': '1 tbsp daily'},
    'herb_molasses_benefits': {'tr': 'Yüksek demir içeriği, kolay emilim', 'en': 'High iron content; easy absorption'},
    'herb_molasses_preparation': {'tr': 'Kahvaltıda veya ara öğünde tüketin', 'en': 'Consume at breakfast or as a snack'},
    'herb_molasses_warning': {'tr': 'Şeker hastalığında dikkatli kullanın', 'en': 'Use with caution in diabetes'},

    'herb_thyme_tea_name': {'tr': 'Kekik Çayı', 'en': 'Thyme Tea'},
    'herb_thyme_tea_usage': {'tr': 'Günde 2-3 fincan', 'en': '2–3 cups daily'},
    'herb_thyme_tea_benefits': {'tr': 'Demir emilimini artırır, bağışıklığı güçlendirir', 'en': 'Improves iron absorption; boosts immunity'},
    'herb_thyme_tea_preparation': {'tr': '1 tatlı kaşığı kekik, 5 dakika demleyin', 'en': 'Steep 1 tsp thyme for 5 minutes'},
    'herb_thyme_tea_warning': {'tr': 'Tansiyon hastaları dikkat etsin', 'en': 'Use caution with hypertension'},

    'herb_carob_name': {'tr': 'Keçiboynuzu', 'en': 'Carob'},
    'herb_carob_usage': {'tr': 'Günde 1 bardak çay', 'en': '1 cup daily (tea)'},
    'herb_carob_benefits': {'tr': 'B12 ve folik asit içerir, kan yapımını destekler', 'en': 'Contains B12 and folate; supports hematopoiesis'},
    'herb_carob_preparation': {'tr': 'Tozunu süt veya suyla karıştırın', 'en': 'Mix the powder with milk or water'},
    'herb_carob_warning': {'tr': 'Alerji durumunda kullanmayın', 'en': 'Avoid if allergic'},

    'herb_pomegranate_juice_name': {'tr': 'Nar Suyu', 'en': 'Pomegranate Juice'},
    'herb_pomegranate_juice_usage': {'tr': 'Günde 1 bardak taze sıkılmış', 'en': '1 glass fresh daily'},
    'herb_pomegranate_juice_benefits': {'tr': 'Antioksidan, hemoglobin artırıcı', 'en': 'Antioxidant; may increase hemoglobin'},
    'herb_pomegranate_juice_preparation': {'tr': 'Taze sıkılmış tercih edin, aç karnına için', 'en': 'Prefer fresh; drink on an empty stomach'},
    'herb_pomegranate_juice_warning': {'tr': 'İlaç etkileşimi olabilir', 'en': 'Possible drug interactions'},

    'herb_beetroot_name': {'tr': 'Kırmızı Pancar', 'en': 'Beetroot'},
    'herb_beetroot_usage': {'tr': 'Haftada 3-4 kez salata olarak', 'en': 'Salad, 3–4 times weekly'},
    'herb_beetroot_benefits': {'tr': 'Nitrat içeriği yüksek, kan dolaşımını iyileştirir', 'en': 'High in nitrates; improves circulation'},
    'herb_beetroot_preparation': {'tr': 'Çiğ rendeleyin veya haşlayın', 'en': 'Grate raw or boil'},
    'herb_beetroot_warning': {'tr': 'Böbrek taşı riski olanlar dikkat etsin', 'en': 'Use caution if prone to kidney stones'},

    'herb_propolis_name': {'tr': 'Propolis', 'en': 'Propolis'},
    'herb_propolis_usage': {'tr': 'Günde 10-15 damla', 'en': '10–15 drops daily'},
    'herb_propolis_benefits': {'tr': 'Doğal antibiyotik, bağışıklık güçlendirici', 'en': 'Natural antibiotic; immune booster'},
    'herb_propolis_preparation': {'tr': 'Su veya bal ile karıştırarak alın', 'en': 'Take mixed with water or honey'},
    'herb_propolis_warning': {'tr': 'Arı ürünlerine alerjisi olanlarda dikkat', 'en': 'Caution if allergic to bee products'},

    'herb_echinacea_name': {'tr': 'Ekinezya', 'en': 'Echinacea'},
    'herb_echinacea_usage': {'tr': 'Günde 2-3 fincan çay', 'en': '2–3 cups tea daily'},
    'herb_echinacea_benefits': {'tr': 'Viral enfeksiyonlara karşı korur', 'en': 'May protect against viral infections'},
    'herb_echinacea_preparation': {'tr': 'Kurutulmuş kökü kaynatın', 'en': 'Boil dried root'},
    'herb_echinacea_warning': {'tr': 'Otoimmün hastalıklarda kullanmayın', 'en': 'Avoid in autoimmune disease'},

    'herb_ginger_name': {'tr': 'Zencefil', 'en': 'Ginger'},
    'herb_ginger_usage': {'tr': 'Günde 2-3 dilim taze', 'en': '2–3 fresh slices daily'},
    'herb_ginger_benefits': {'tr': 'Anti-enflamatuar, sindirim destekleyici', 'en': 'Anti-inflammatory; aids digestion'},
    'herb_ginger_preparation': {'tr': 'Çay olarak demleyin veya yemeğe ekleyin', 'en': 'Brew as tea or add to meals'},
    'herb_ginger_warning': {'tr': 'Kan sulandırıcı kullanıyorsanız dikkat', 'en': 'Use caution with blood thinners'},

    'herb_papaya_leaf_name': {'tr': 'Papaya Yaprağı', 'en': 'Papaya Leaf'},
    'herb_papaya_leaf_usage': {'tr': 'Günde 2 kez çay olarak', 'en': 'Tea, twice daily'},
    'herb_papaya_leaf_benefits': {'tr': 'Trombosit sayısını artırır', 'en': 'May increase platelet count'},
    'herb_papaya_leaf_preparation': {'tr': 'Taze yaprakları kaynatın, soğutarak için', 'en': 'Boil fresh leaves; drink after cooling'},
    'herb_papaya_leaf_warning': {'tr': 'Hamilelikte kullanmayın', 'en': 'Avoid during pregnancy'},

    'herb_ginkgo_biloba_name': {'tr': 'Ginkgo Biloba', 'en': 'Ginkgo Biloba'},
    'herb_ginkgo_biloba_usage': {'tr': 'Günde 1-2 fincan çay', 'en': '1–2 cups tea daily'},
    'herb_ginkgo_biloba_benefits': {'tr': 'Kan dolaşımını iyileştirir', 'en': 'Improves blood circulation'},
    'herb_ginkgo_biloba_preparation': {'tr': 'Kurutulmuş yaprakları demleyin', 'en': 'Brew dried leaves'},
    'herb_ginkgo_biloba_warning': {'tr': 'Ameliyat öncesi bırakın', 'en': 'Discontinue before surgery'},

    // Alternative Medicine - UI labels
    'reason_label': {
      'tr': 'Neden',
      'en': 'Reason',
    },
    'age_personalization_note': {
      'tr': '65+ yaş için doz ve kullanım sıklığını düşükten başlayın ve doktorunuza danışın.',
      'en': 'For 65+, start with lower dose/frequency and consult your doctor.',
    },
    'female_general_caution': {
      'tr': 'Hamilelik/Emzirme döneminde mutlaka doktorunuza danışın.',
      'en': 'If pregnant/breastfeeding, consult your doctor.',
    },

  // Newly added herbs
  'herb_rosehip_name': {'tr': 'Kuşburnu', 'en': 'Rosehip'},
  'herb_rosehip_usage': {'tr': 'Günde 2 fincan çay', 'en': 'Tea, 2 cups daily'},
  'herb_rosehip_benefits': {'tr': 'C vitamini kaynağı, demir emilimini artırır', 'en': 'Vitamin C source; improves iron absorption'},
  'herb_rosehip_preparation': {'tr': 'Kurutulmuş meyveleri 10 dk demleyin', 'en': 'Steep dried hips for 10 minutes'},
  'herb_rosehip_warning': {'tr': 'Böbrek taşı öyküsünde dikkat', 'en': 'Caution if kidney stone history'},

  'herb_spirulina_name': {'tr': 'Spirulina', 'en': 'Spirulina'},
  'herb_spirulina_usage': {'tr': 'Günde 1-2 tablet/toz', 'en': '1–2 tablets/scoop daily'},
  'herb_spirulina_benefits': {'tr': 'B12 ve protein kaynağı', 'en': 'Source of B12 and protein'},
  'herb_spirulina_preparation': {'tr': 'Su ile alın veya smoothieye ekleyin', 'en': 'Take with water or add to smoothies'},
  'herb_spirulina_warning': {'tr': 'Fenilketonüride kullanmayın', 'en': 'Avoid in phenylketonuria'},

  'herb_wheatgrass_name': {'tr': 'Buğday Çimi', 'en': 'Wheatgrass'},
  'herb_wheatgrass_usage': {'tr': 'Gün aşırı 1 shot', 'en': '1 shot every other day'},
  'herb_wheatgrass_benefits': {'tr': 'Klorofil ve antioksidan içerir', 'en': 'Rich in chlorophyll and antioxidants'},
  'herb_wheatgrass_preparation': {'tr': 'Taze sıkılmış tüketin', 'en': 'Consume freshly juiced'},
  'herb_wheatgrass_warning': {'tr': 'Gluten hassasiyetinde dikkat', 'en': 'Caution with gluten sensitivity'},

  'herb_moringa_name': {'tr': 'Moringa', 'en': 'Moringa'},
  'herb_moringa_usage': {'tr': 'Günde 1-2 çay', 'en': '1–2 cups tea daily'},
  'herb_moringa_benefits': {'tr': 'Vitamin-mineral yönünden zengin', 'en': 'Rich in vitamins and minerals'},
  'herb_moringa_preparation': {'tr': 'Yaprakları 5-7 dk demleyin', 'en': 'Steep leaves 5–7 minutes'},
  'herb_moringa_warning': {'tr': 'Hamilelikte doktorunuza danışın', 'en': 'Consult doctor during pregnancy'},

  'herb_bee_pollen_name': {'tr': 'Arı Poleni', 'en': 'Bee Pollen'},
  'herb_bee_pollen_usage': {'tr': 'Günde 1 tatlı kaşığı', 'en': '1 tsp daily'},
  'herb_bee_pollen_benefits': {'tr': 'Protein ve antioksidan kaynağı', 'en': 'Source of protein and antioxidants'},
  'herb_bee_pollen_preparation': {'tr': 'Yoğurt veya bala karıştırın', 'en': 'Mix with yogurt or honey'},
  'herb_bee_pollen_warning': {'tr': 'Arı ürünlerine alerjide kullanmayın', 'en': 'Avoid if allergic to bee products'},

  'herb_turmeric_name': {'tr': 'Zerdeçal', 'en': 'Turmeric'},
  'herb_turmeric_usage': {'tr': 'Günde 1 çay kaşığı (toz)', 'en': '1 tsp daily (powder)'},
  'herb_turmeric_benefits': {'tr': 'Güçlü anti-enflamatuar', 'en': 'Strong anti-inflammatory'},
  'herb_turmeric_preparation': {'tr': 'Sütle (golden milk) veya yemeklere ekleyin', 'en': 'With milk (golden milk) or add to meals'},
  'herb_turmeric_warning': {'tr': 'Safra taşında dikkat', 'en': 'Caution with gallstones'},

  'herb_green_tea_name': {'tr': 'Yeşil Çay', 'en': 'Green Tea'},
  'herb_green_tea_usage': {'tr': 'Günde 2 fincan', 'en': '2 cups daily'},
  'herb_green_tea_benefits': {'tr': 'Polifenoller ile bağışıklık desteği', 'en': 'Polyphenols support immunity'},
  'herb_green_tea_preparation': {'tr': '80°C suda 2-3 dk demleyin', 'en': 'Steep 2–3 min at ~80°C'},
  'herb_green_tea_warning': {'tr': 'Kafeine duyarlıysanız akşam tüketmeyin', 'en': 'Avoid late use if caffeine-sensitive'},

  'herb_chamomile_name': {'tr': 'Papatya', 'en': 'Chamomile'},
  'herb_chamomile_usage': {'tr': 'Günde 1-2 fincan', 'en': '1–2 cups daily'},
  'herb_chamomile_benefits': {'tr': 'Antialerjik ve sakinleştirici', 'en': 'Anti-allergic and calming'},
  'herb_chamomile_preparation': {'tr': '2-3 çiçek, 5 dk demleyin', 'en': 'Steep 2–3 flowers for 5 minutes'},
  'herb_chamomile_warning': {'tr': 'Papatyagiller alerjisinde kullanmayın', 'en': 'Avoid if allergic to Asteraceae'},

    // Alternative Medicine - Traditional methods
    'trad_cupping_title': {'tr': 'Hacamat Tedavisi', 'en': 'Cupping Therapy'},
    'trad_cupping_description': {'tr': 'Kan dolaşımını iyileştiren geleneksel yöntem', 'en': 'Traditional method to improve blood circulation'},
    'trad_cupping_benefits': {'tr': 'Kirli kanın çıkarılması, dolaşım iyileşmesi', 'en': 'Removes stagnant blood; improves circulation'},
    'trad_cupping_procedure': {'tr': 'Uzman tarafından steril ortamda uygulanmalı', 'en': 'Must be performed by a specialist in sterile conditions'},
    'trad_cupping_frequency': {'tr': 'Ayda 1-2 kez', 'en': '1–2 times per month'},
    'trad_cupping_warning': {'tr': 'Kan hastalığı varsa doktor onayı şart', 'en': 'Doctor approval required for blood disorders'},

    'trad_leech_title': {'tr': 'Sülük Tedavisi', 'en': 'Leech Therapy'},
    'trad_leech_description': {'tr': 'Doğal kan inceltici ve detoks yöntemi', 'en': 'Natural blood thinner and detox method'},
    'trad_leech_benefits': {'tr': 'Kan pıhtılaşmasını önler, toksin atılımı', 'en': 'Prevents clotting; aids toxin removal'},
    'trad_leech_procedure': {'tr': 'Tıbbi sülüklerle uzman gözetiminde', 'en': 'With medical leeches under specialist supervision'},
    'trad_leech_frequency': {'tr': '3 ayda 1 kez', 'en': 'Once every 3 months'},
    'trad_leech_warning': {'tr': 'Enfeksiyon riski, steril ortam şart', 'en': 'Infection risk; requires sterile conditions'},

    'trad_dry_cupping_title': {'tr': 'Kuru Kupa', 'en': 'Dry Cupping'},
    'trad_dry_cupping_description': {'tr': 'Vakum ile kan dolaşımını hızlandırma', 'en': 'Speeds blood circulation via vacuum'},
    'trad_dry_cupping_benefits': {'tr': 'Kas gevşemesi, dolaşım artışı', 'en': 'Muscle relaxation; increased circulation'},
    'trad_dry_cupping_procedure': {'tr': 'Cam kupa ile vakum oluşturulur', 'en': 'Creates vacuum with glass cups'},
    'trad_dry_cupping_frequency': {'tr': 'Haftada 1-2 kez', 'en': '1–2 times weekly'},
    'trad_dry_cupping_warning': {'tr': 'Deri hassasiyeti olanlarda dikkat', 'en': 'Use caution with skin sensitivity'},

    'trad_reflexology_title': {'tr': 'Refleksoloji', 'en': 'Reflexology'},
    'trad_reflexology_description': {'tr': 'Ayak masajı ile organ uyarımı', 'en': 'Stimulates organs via foot massage'},
    'trad_reflexology_benefits': {'tr': 'Dolaşımı artırır, organları uyarır', 'en': 'Increases circulation; stimulates organs'},
    'trad_reflexology_procedure': {'tr': 'Ayak tabanında belirli noktalara baskı', 'en': 'Applies pressure to specific points on feet'},
    'trad_reflexology_frequency': {'tr': 'Haftada 2-3 kez', 'en': '2–3 times weekly'},
    'trad_reflexology_warning': {'tr': 'Ayak yaraları varsa yapmayın', 'en': 'Avoid with foot wounds'},

    'trad_aromatherapy_title': {'tr': 'Aromaterapi', 'en': 'Aromatherapy'},
    'trad_aromatherapy_description': {'tr': 'Uçucu yağlarla tedavi', 'en': 'Treatment with essential oils'},
    'trad_aromatherapy_benefits': {'tr': 'Stres azalması, hormon dengelenmesi', 'en': 'Reduces stress; balances hormones'},
    'trad_aromatherapy_procedure': {'tr': 'Diffüzer ile soluma veya masaj yağı', 'en': 'Inhalation via diffuser or massage oil'},
    'trad_aromatherapy_frequency': {'tr': 'Günlük kullanım', 'en': 'Daily use'},
    'trad_aromatherapy_warning': {'tr': 'Hamilelikte bazı yağlar tehlikeli', 'en': 'Some oils are unsafe during pregnancy'},
    'share_suggestions': {
      'tr': '• Önerilerinizi paylaşın',
      'en': '• Share your suggestions',
      'es': '• Comparte tus sugerencias',
      'fr': '• Partagez vos suggestions',
      'de': '• Teilen Sie Ihre Vorschläge',
      'ar': '• شارك اقتراحاتك',
    },
    // 'close' defined earlier
    'feedback_received': {
      'tr': 'Geri bildiriminiz alındı, teşekkürler!',
      'en': 'Your feedback has been received, thank you!',
      'es': 'Se ha recibido su comentario, ¡gracias!',
      'fr': 'Vos commentaires ont été reçus, merci!',
      'de': 'Ihr Feedback wurde erhalten, danke!',
      'ar': 'تم استلام تعليقك، شكراً لك!',
    },
    'send_feedback_button': {
      'tr': 'Geri Bildirim Gönder',
      'en': 'Send Feedback',
      'es': 'Enviar Comentario',
      'fr': 'Envoyer Commentaire',
      'de': 'Feedback Senden',
      'ar': 'إرسال التعليق',
    },
    // Notification screen newly added keys
    // 'mark_read' and 'mark_read_long' defined earlier
    'daily_water_tracking': {
      'tr': 'Günlük Su Takibi',
      'en': 'Daily Water Tracking',
      'es': 'Seguimiento Diario de Agua',
      'fr': 'Suivi Quotidien de l\'Eau',
      'de': 'Tägliche Wasserverfolgung',
      'ar': 'متابعة الماء اليومية',
    },
    // Water tracking simple strings
    'water_goal_progress': {
      'tr': 'Bugün içilen bardak: {count} / {goal}',
      'en': 'Glasses today: {count} / {goal}',
    },
    'water_intake_logged': {
      'tr': 'Tebrikler! Bir bardak su içtiniz.',
      'en': 'Nice! You logged one glass of water.',
    },
    'log_one_glass': {
      'tr': 'Bir Bardak Su İçtim',
      'en': 'Log One Glass',
    },
    'keep_going': {
      'tr': 'Hedefe yaklaşıyorsunuz, devam edin!',
      'en': 'You’re close to your goal, keep going!',
    },
    'med_progress': {
      'tr': 'İlerleme: {completed}/{total} gün',
      'en': 'Progress: {completed}/{total} days',
      'es': 'Progreso: {completed}/{total} días',
      'fr': 'Progression : {completed}/{total} jours',
      'de': 'Fortschritt: {completed}/{total} Tage',
      'ar': 'التقدم: {completed}/{total} يوم',
    },
    'notification_settings_title': {
      'tr': 'Bildirim Ayarları',
      'en': 'Notification Settings',
      'es': 'Configuración de Notificaciones',
      'fr': 'Paramètres de Notification',
      'de': 'Benachrichtigungseinstellungen',
      'ar': 'إعدادات الإشعارات',
    },
    'notification_settings_saved': {
      'tr': 'Bildirim ayarları kaydedildi!',
      'en': 'Notification settings saved!',
      'es': '¡Configuración de notificaciones guardada!',
      'fr': 'Paramètres de notification enregistrés !',
      'de': 'Benachrichtigungseinstellungen gespeichert!',
      'ar': 'تم حفظ إعدادات الإشعارات!',
    },
    'save_settings': {
      'tr': 'Ayarları Kaydet',
      'en': 'Save Settings',
      'es': 'Guardar Configuración',
      'fr': 'Enregistrer les Paramètres',
      'de': 'Einstellungen Speichern',
      'ar': 'حفظ الإعدادات',
    },
    'notification_deleted': {
      'tr': 'Bildirim silindi',
      'en': 'Notification deleted',
      'es': 'Notificación eliminada',
      'fr': 'Notification supprimée',
      'de': 'Benachrichtigung gelöscht',
      'ar': 'تم حذف الإشعار',
    },
    'notifications_tab': {
      'tr': 'Bildirimler',
      'en': 'Notifications',
      'es': 'Notificaciones',
      'fr': 'Notifications',
      'de': 'Benachrichtigungen',
      'ar': 'الإشعارات',
    },
    'water_tracking_tab': {
      'tr': 'Su Takibi',
      'en': 'Water Tracking',
      'es': 'Seguimiento de Agua',
      'fr': 'Suivi de l\'Eau',
      'de': 'Wasserverfolgung',
      'ar': 'متابعة الماء',
    },
    'medications_tab': {
      'tr': 'İlaçlar',
      'en': 'Medications',
      'es': 'Medicamentos',
      'fr': 'Médicaments',
      'de': 'Medikamente',
      'ar': 'الأدوية',
    },
    'settings_tab': {
      'tr': 'Ayarlar',
      'en': 'Settings',
      'es': 'Configuración',
      'fr': 'Paramètres',
      'de': 'Einstellungen',
      'ar': 'الإعدادات',
    },
    'water_benefits_title': {
      'tr': '💧 Su İçmenin Faydaları',
      'en': '💧 Benefits of Drinking Water',
      'es': '💧 Beneficios de Beber Agua',
      'fr': '💧 Bienfaits de Boire de l\'Eau',
      'de': '💧 Vorteile des Wassertrinkens',
      'ar': '💧 فوائد شرب الماء',
    },
    'water_benefits_list': {
      'tr': '• Kan dolaşımını iyileştirir\n• Hemoglobin taşınmasına yardımcı olur\n• Demir emilimini artırır\n• Toksinleri vücuttan atar\n• Enerji seviyesini yükseltir',
      'en': '• Improves blood circulation\n• Supports hemoglobin transport\n• Enhances iron absorption\n• Flushes out toxins\n• Boosts energy levels',
      'es': '• Mejora la circulación sanguínea\n• Apoya el transporte de hemoglobina\n• Mejora la absorción de hierro\n• Elimina toxinas\n• Aumenta los niveles de energía',
      'fr': '• Améliore la circulation sanguine\n• Soutient le transport de l\'hémoglobine\n• Améliore l\'absorption du fer\n• Élimine les toxines\n• Augmente les niveaux d\'énergie',
      'de': '• Verbessert die Blutzirkulation\n• Unterstützt den Hämoglobintransport\n• Erhöht die Eisenaufnahme\n• Spült Toxine aus\n• Steigert das Energieniveau',
      'ar': '• يحسن الدورة الدموية\n• يدعم نقل الهيموجلوبين\n• يعزز امتصاص الحديد\n• يطرد السموم\n• يعزز مستويات الطاقة',
    },
    'daily_medication_tracking': {
      'tr': 'Günlük İlaç Takibi',
      'en': 'Daily Medication Tracking',
      'es': 'Seguimiento Diario de Medicación',
      'fr': 'Suivi Quotidien des Médicaments',
      'de': 'Tägliche Medikamentenverfolgung',
      'ar': 'متابعة الأدوية اليومية',
    },
    'med_name_label': {
      'tr': 'İlaç Adı *',
      'en': 'Medication Name *',
      'es': 'Nombre del Medicamento *',
      'fr': 'Nom du Médicament *',
      'de': 'Medikamentenname *',
      'ar': 'اسم الدواء *',
    },
    'dosage_hint': {
      'tr': 'Dozaj (örn: 1 tablet, 10mg)',
      'en': 'Dosage (e.g: 1 tablet, 10mg)',
      'es': 'Dosis (ej: 1 tableta, 10mg)',
      'fr': 'Dosage (ex: 1 comprimé, 10mg)',
      'de': 'Dosierung (z.B: 1 Tablette, 10mg)',
      'ar': 'الجرعة (مثال: 1 قرص، 10 ملغ)',
    },
    'frequency_hint': {
      'tr': 'Sıklık (örn: Günde 2 kez)',
      'en': 'Frequency (e.g: Twice daily)',
      'es': 'Frecuencia (ej: 2 veces al día)',
      'fr': 'Fréquence (ex: 2 fois par jour)',
      'de': 'Häufigkeit (z.B: 2x täglich)',
      'ar': 'التكرار (مثال: مرتين يومياً)',
    },
    'time_hint': {
      'tr': 'Saat (örn: 08:00)',
      'en': 'Time (e.g: 08:00)',
      'es': 'Hora (ej: 08:00)',
      'fr': 'Heure (ex: 08:00)',
      'de': 'Zeit (z.B: 08:00)',
      'ar': 'الوقت (مثال: 08:00)',
    },
    'med_added_success': {
      'tr': 'İlaç başarıyla eklendi!',
      'en': 'Medication added successfully!',
      'es': '¡Medicamento agregado con éxito!',
      'fr': 'Médicament ajouté avec succès !',
      'de': 'Medikament erfolgreich hinzugefügt!',
      'ar': 'تمت إضافة الدواء بنجاح!',
    },
    'new_medication_added': {
      'tr': 'Yeni İlaç Eklendi',
      'en': 'New Medication Added',
      'es': 'Nuevo Medicamento Agregado',
      'fr': 'Nouveau Médicament Ajouté',
      'de': 'Neues Medikament Hinzugefügt',
      'ar': 'تمت إضافة دواء جديد',
    },
    'medication_added_to_list': {
      'tr': '{name} ilacı takip listenize eklendi.',
      'en': '{name} has been added to your tracking list.',
      'es': '{name} se ha añadido a su lista de seguimiento.',
      'fr': '{name} a été ajouté à votre liste de suivi.',
      'de': '{name} wurde Ihrer Verfolgungsliste hinzugefügt.',
      'ar': 'تمت إضافة {name} إلى قائمة المتابعة الخاصة بك.',
    },
    'med_name_required': {
      'tr': 'İlaç adı zorunludur',
      'en': 'Medication name is required',
      'es': 'Se requiere el nombre del medicamento',
      'fr': 'Le nom du médicament est requis',
      'de': 'Medikamentenname ist erforderlich',
      'ar': 'اسم الدواء مطلوب',
    },
    // Water goal notifications
    'water_goal_completed_title': {
      'tr': 'Su Hedefi Tamamlandı!',
      'en': 'Water Goal Reached!',
      'es': '¡Objetivo de Agua Alcanzado!',
      'fr': 'Objectif d\'Eau Atteint !',
      'de': 'Wasserziel Erreicht!',
      'ar': 'تم الوصول إلى هدف الماء!',
    },
    'water_goal_completed_message': {
      'tr': 'Günlük {goal} bardak su hedefinizi başarıyla tamamladınız!',
      'en': 'You have successfully completed your daily goal of {goal} glasses of water!',
      'es': '¡Ha completado con éxito su objetivo diario de {goal} vasos de agua!',
      'fr': 'Vous avez atteint votre objectif quotidien de {goal} verres d\'eau !',
      'de': 'Sie haben Ihr tägliches Ziel von {goal} Gläsern Wasser erreicht!',
      'ar': 'لقد أكملت بنجاح هدفك اليومي البالغ {goal} أكواب من الماء!',
    },
    // Inline congratulation message used in banner
    'water_goal_completed_inline': {
      'tr': 'Tebrikler! Günlük su hedefinizi tamamladınız! 🎉',
      'en': 'Congratulations! You\'ve completed your daily water goal! 🎉',
      'es': '¡Felicidades! ¡Has completado tu objetivo diario de agua! 🎉',
      'fr': 'Félicitations ! Vous avez atteint votre objectif quotidien d\'eau ! 🎉',
      'de': 'Glückwunsch! Du hast dein tägliches Wasserziel erreicht! 🎉',
      'ar': 'تهانينا! لقد أكملت هدفك اليومي من الماء! 🎉',
    },
    // Hydration reminder (used by snooze actions in water-goal snackbar)
    'hydration_reminder_title': {
      'tr': 'Su Hatırlatması',
      'en': 'Hydration Reminder',
      'es': 'Recordatorio de Hidratación',
      'fr': 'Rappel d\'Hydratation',
      'de': 'Erinnerung ans Trinken',
      'ar': 'تذكير بالترطيب',
    },
    'hydration_reminder_body': {
      'tr': 'Küçük bir bardak su içmeyi unutmayın.',
      'en': 'Don\'t forget to drink a small glass of water.',
      'es': 'No olvides beber un vaso pequeño de agua.',
      'fr': 'N\'oubliez pas de boire un petit verre d\'eau.',
      'de': 'Vergiss nicht, ein kleines Glas Wasser zu trinken.',
      'ar': 'لا تنس شرب كأس صغير من الماء.',
    },
    'remind_tomorrow': {
      'tr': 'Yarın hatırlat',
      'en': 'Remind tomorrow',
      'es': 'Recordar mañana',
      'fr': 'Rappeler demain',
      'de': 'Morgen erinnern',
      'ar': 'ذكّرني غدًا',
    },
    'snoozed_for_tomorrow': {
      'tr': 'Yarın için hatırlatma ayarlandı',
      'en': 'Reminder set for tomorrow',
      'es': 'Recordatorio programado para mañana',
      'fr': 'Rappel programmé pour demain',
      'de': 'Erinnerung für morgen eingestellt',
      'ar': 'تم تعيين التذكير للغد',
    },
    // Water tracker action buttons
    'water_increase': {
      'tr': 'Artır',
      'en': 'Increase',
      'es': 'Aumentar',
      'fr': 'Augmenter',
      'de': 'Erhöhen',
      'ar': 'زيادة',
    },
    'water_decrease': {
      'tr': 'Azalt',
      'en': 'Decrease',
      'es': 'Disminuir',
      'fr': 'Diminuer',
      'de': 'Verringern',
      'ar': 'نقصان',
    },
    // Alternative Medicine - Tabs
    'herbal_solutions_tab': {
      'tr': 'Bitkisel',
      'en': 'Herbal',
    },
    'traditional_methods_tab': {
      'tr': 'Yöresel',
      'en': 'Traditional',
    },
    'general_info_tab': {
      'tr': 'Genel Bilgi',
      'en': 'General Info',
    },
    // Alternative Medicine - Labels
    'usage_label': {
      'tr': 'Kullanım',
      'en': 'Usage',
    },
    'benefits_label': {
      'tr': 'Faydaları',
      'en': 'Benefits',
    },
    'preparation_label': {
      'tr': 'Hazırlanış',
      'en': 'Preparation',
    },
    'warning_label': {
      'tr': 'Uyarı',
      'en': 'Warning',
    },
    'application_label': {
      'tr': 'Uygulama',
      'en': 'Application',
    },
    'frequency_label': {
      'tr': 'Sıklık',
      'en': 'Frequency',
    },
    'herbal_solutions_count': {
      'tr': '{count} bitkisel çözüm',
      'en': '{count} herbal solutions',
    },
    // Alternative Medicine - Traditional section
    'traditional_treatments_title': {
      'tr': 'Geleneksel Tedavi Yöntemleri',
      'en': 'Traditional Treatment Methods',
    },
    'traditional_treatments_subtitle': {
      'tr': 'Asırlar boyunca kullanılan geleneksel iyileştirme yöntemleri',
      'en': 'Traditional healing methods used for centuries',
    },
    // Alternative Medicine - General advice
    'important_reminder_title': {
      'tr': 'Önemli Hatırlatma',
      'en': 'Important Reminder',
    },
    'important_reminder_body': {
      'tr': 'Alternatif tıp yöntemleri tamamlayıcı tedavi amacıyla kullanılmalıdır. Ana tedavinizin yerini alamaz. Mutlaka doktorunuzla görüşerek uygulayın.',
      'en': 'Alternative medicine methods should be used as complementary treatments. They cannot replace your main treatment. Always consult your doctor before applying.',
    },
    'basic_rules_title': {
      'tr': 'Temel Kurallar',
      'en': 'Basic Rules',
    },
    'basic_rules_list': {
      'tr': 'Herhangi bir bitkisel ürünü kullanmadan önce doktorunuza danışın\nİlaçlarınızla etkileşim olup olmadığını kontrol ettirin\nHamilelik, emzirme döneminde ekstra dikkatli olun\nAlerjik reaksiyonlara karşı dikkatli olun, küçük dozlarla başlayın\nKaliteli, güvenilir kaynaklardan temin edin\nBelirtilen dozları aşmayın\nYan etki görürseniz hemen bırakın ve doktora başvurun',
      'en': 'Consult your doctor before using any herbal product\nCheck for possible interactions with your medications\nBe extra cautious during pregnancy and breastfeeding\nWatch for allergic reactions and start with small doses\nSource products from high-quality, trusted suppliers\nDo not exceed the stated dosages\nStop immediately and consult a doctor if side effects occur',
    },
    'expert_support_title': {
      'tr': 'Uzman Desteği',
      'en': 'Expert Support',
    },
    'expert_support_body': {
      'tr': 'Alternatif tıp yöntemlerini uygulamadan önce:\n\n• Fitoterapist veya geleneksel tıp uzmanına danışın\n• Hematoloji uzmanınızın onayını alın\n• Düzenli kan takibinizi aksatmayın\n• Tedavi sürecinizi doktorunuzla paylaşın',
      'en': 'Before applying alternative medicine methods:\n\n• Consult a phytotherapist or traditional medicine specialist\n• Obtain approval from your hematology specialist\n• Do not neglect regular blood monitoring\n• Share your treatment process with your doctor',
    },
    // Notification settings item titles
    'setting_title_test_reminders': {
      'tr': 'Tahlil Hatırlatıcıları',
      'en': 'Test Reminders',
    },
    'setting_title_critical_alerts': {
      'tr': 'Kritik Değer Uyarıları',
      'en': 'Critical Value Alerts',
    },
    'setting_title_medication_reminders': {
      'tr': 'İlaç Hatırlatıcıları',
      'en': 'Medication Reminders',
    },
    'setting_title_nutrition_tips': {
      'tr': 'Genel Beslenme Önerileri',
      'en': 'General Nutrition Tips',
    },
    'setting_title_personalized_diet': {
      'tr': 'Kişisel Diyet Önerileri',
      'en': 'Personalized Diet Suggestions',
    },
    'setting_title_motivational_messages': {
      'tr': 'Motive Edici Mesajlar',
      'en': 'Motivational Messages',
    },
    'setting_title_health_tips': {
      'tr': 'Günlük Sağlık İpuçları',
      'en': 'Daily Health Tips',
    },
    'setting_title_smart_meals': {
      'tr': 'Akıllı Yemek Önerileri',
      'en': 'Smart Meal Suggestions',
    },
    'setting_title_stress_management': {
      'tr': 'Stres Yönetimi İpuçları',
      'en': 'Stress Management Tips',
    },
    'setting_title_weekly_reports': {
      'tr': 'Haftalık Başarı Raporları',
      'en': 'Weekly Progress Reports',
    },
    'setting_title_appointment_reminders': {
      'tr': 'Randevu Hatırlatıcıları',
      'en': 'Appointment Reminders',
    },
    'setting_title_water_reminders': {
      'tr': 'Su İçme Hatırlatıcıları',
      'en': 'Water Intake Reminders',
    },
    'setting_title_exercise_reminders': {
      'tr': 'Egzersiz Hatırlatıcıları',
      'en': 'Exercise Reminders',
    },
    // Notification settings item subtitles
    'setting_subtitle_test_reminders': {
      'tr': 'Düzenli tahlil zamanlarını hatırlat',
      'en': 'Remind regular lab/test times',
    },
    'setting_subtitle_critical_alerts': {
      'tr': 'Anormal değerler için acil uyarılar',
      'en': 'Urgent alerts for abnormal values',
    },
    'setting_subtitle_medication_reminders': {
      'tr': 'İlaç alma zamanlarını hatırlat',
      'en': 'Remind medication times',
    },
    'setting_subtitle_nutrition_tips': {
      'tr': 'Günlük genel beslenme tavsiyeleri',
      'en': 'Daily general nutrition advice',
    },
    'setting_subtitle_personalized_diet': {
      'tr': 'Test sonuçlarınıza özel diyet menüleri',
      'en': 'Diet menus tailored to your test results',
    },
    'setting_subtitle_motivational_messages': {
      'tr': 'Günlük motivasyon ve cesaret verici mesajlar',
      'en': 'Daily motivational and encouraging messages',
    },
    'setting_subtitle_health_tips': {
      'tr': 'Sağlık bilgisi ve pratik yaşam ipuçları',
      'en': 'Health knowledge and practical life tips',
    },
    'setting_subtitle_smart_meals': {
      'tr': 'Besin kombinasyonları ve yemek önerileri',
      'en': 'Food combinations and meal suggestions',
    },
    'setting_subtitle_stress_management': {
      'tr': 'Stres azaltma teknikleri ve rahatlama egzersizleri',
      'en': 'Stress reduction techniques and relaxation exercises',
    },
    'setting_subtitle_weekly_reports': {
      'tr': 'Haftalık ilerleme ve başarı özetleri',
      'en': 'Weekly progress and achievement summaries',
    },
    'setting_subtitle_appointment_reminders': {
      'tr': 'Doktor randevularını hatırlat',
      'en': 'Remind doctor appointments',
    },
    'setting_subtitle_water_reminders': {
      'tr': 'Su içme zamanlarını hatırlat',
      'en': 'Remind water intake times',
    },
    'setting_subtitle_exercise_reminders': {
      'tr': 'Günlük aktivite hatırlatıcıları',
      'en': 'Daily activity reminders',
    },
    // Sample notification content keys
    'motivational_message': {
      'tr': 'Motivasyon Mesajı',
      'en': 'Motivational Message',
      'es': 'Mensaje Motivacional',
      'fr': 'Message Motivation',
      'de': 'Motivationsnachricht',
      'ar': 'رسالة تحفيزية',
    },
    'take_care_today': {
      'tr': 'Bugün Kendine İyi Bak',
      'en': 'Take Care of Yourself Today',
      'es': 'Cuida de Ti Hoy',
      'fr': 'Prends Soin de Toi Aujourd\'hui',
      'de': 'Kümmere dich Heute um dich',
      'ar': 'اعتن بنفسك اليوم',
    },
    'motivational_message_long': {
      'tr': 'Sağlığın için küçük adımlar büyük fark yaratır. Bugün bol su içmeyi, dengeli beslenmeyi ve hareket etmeyi unutma.',
      'en': 'Small steps make a big difference for your health. Remember to drink water, eat balanced meals and move today.',
      'es': 'Pequeños pasos marcan una gran diferencia para tu salud. Recuerda beber agua, comer equilibradamente y moverte hoy.',
      'fr': 'De petits pas font une grande différence pour ta santé. N\'oublie pas de boire de l\'eau, de manger équilibré et de bouger.',
      'de': 'Kleine Schritte machen einen großen Unterschied für deine Gesundheit. Trinke Wasser, iss ausgewogen und bewege dich heute.',
      'ar': 'الخطوات الصغيرة تصنع فرقاً كبيراً لصحتك. تذكر شرب الماء وتناول وجبات متوازنة والحركة اليوم.',
    },
    'motivational_rotating_title': {
      'tr': 'Günün Motivasyonu',
      'en': 'Motivation of the Day',
    },
    'share_quote': {
      'tr': 'Sözü Paylaş',
      'en': 'Share Quote',
    },
    'quote_copied': {
      'tr': 'Söz kopyalandı',
      'en': 'Quote copied',
    },
    'daily_motivation_time': {
      'tr': 'Günlük motivasyon bildirimi saati',
      'en': 'Daily motivation notification time',
    },
    'motivational_custom_quote': {
      'tr': 'Sabır zor koşullar altında ceserat ve metanetini yitirmeme duygusudur.Sabırlı insan uzun süreli gecikmelere ve tahriklere rağmen moralini bozmadan yoluna devam eder veya beklemesini sürdürür',
      'en': 'In difficult conditions, it is the feeling of not losing courage and fortitude. A patient person does not lose morale despite delays and provocations, continues on the right path or knows to wait.',
      'es': 'En condiciones difíciles, es el sentimiento de no perder el valor y la fortaleza. Una persona paciente no pierde la moral a pesar de los retrasos y las provocaciones, continúa por el camino correcto o sabe esperar.',
      'fr': "Dans des conditions difficiles, c'est le fait de ne pas perdre courage et endurance. Une personne patiente ne perd pas le moral malgré les retards et les provocations, continue sur la bonne voie ou sait attendre.",
      'de': 'Unter schwierigen Bedingungen ist es das Gefühl, Mut und Standhaftigkeit nicht zu verlieren. Eine geduldige Person verliert trotz Verzögerungen und Provokationen nicht den Mut, bleibt auf dem richtigen Weg oder weiß zu warten.',
      'ar': 'في الظروف الصعبة، هو الشعور بعدم فقدان الشجاعة والثبات. الشخص الصبور لا يفقد معنوياته رغم التأخيرات والاستفزازات، يواصل السير في الطريق الصحيح أو يعرف كيف ينتظر.',
    },
    'personal_diet_suggestion': {
      'tr': 'Kişisel Diyet Önerisi',
      'en': 'Personal Diet Suggestion',
      'es': 'Sugerencia de Dieta Personal',
      'fr': 'Suggestion de Régime Personnel',
      'de': 'Persönliche Diät Empfehlung',
      'ar': 'اقتراح نظام غذائي شخصي',
    },
    'hemoglobin_menu_subtitle': {
      'tr': 'Hemoglobin dengeniz için örnek menü',
      'en': 'Sample menu for your hemoglobin balance',
      'es': 'Menú de ejemplo para tu equilibrio de hemoglobina',
      'fr': 'Menu d\'exemple pour ton équilibre en hémoglobine',
      'de': 'Beispielmenü für dein Hämoglobin-Gleichgewicht',
      'ar': 'قائمة مثال لتوازن الهيموجلوبين لديك',
    },
    'personal_diet_plan_example': {
      'tr': 'Kahvaltı: Yulaf + Ceviz\nÖğle: Izgara tavuk + yeşil sebzeler\nAkşam: Mercimek çorbası + yoğurt. Gün boyu bol su içmeyi unutma.',
      'en': 'Breakfast: Oats + Walnuts\nLunch: Grilled chicken + greens\nDinner: Lentil soup + yogurt. Remember to stay hydrated.',
      'es': 'Desayuno: Avena + Nueces\nAlmuerzo: Pollo a la parrilla + vegetales verdes\nCena: Sopa de lentejas + yogur. Recuerda mantenerte hidratado.',
      'fr': 'Petit-déj: Flocons d\'avoine + Noix\nDéj: Poulet grillé + légumes verts\nDîner: Soupe de lentilles + yaourt. Reste hydraté.',
      'de': 'Frühstück: Hafer + Walnüsse\nMittag: Gegrilltes Hähnchen + Grünes Gemüse\nAbend: Linsensuppe + Joghurt. Bleib hydriert.',
      'ar': 'الإفطار: شوفان + جوز\nالغداء: دجاج مشوي + خضار خضراء\nالعشاء: شوربة عدس + زبادي. تذكر شرب الماء.',
    },
    'test_reminder_title': {
      'tr': 'Test Hatırlatıcısı',
      'en': 'Test Reminder',
      'es': 'Recordatorio de Prueba',
      'fr': 'Rappel de Test',
      'de': 'Test Erinnerung',
      'ar': 'تذكير فحص',
    },
    'monthly_check_subtitle': {
      'tr': 'Aylık hemogram kontrol zamanı',
      'en': 'Time for monthly hemogram check',
      'es': 'Hora del control mensual del hemograma',
      'fr': 'Temps pour le contrôle mensuel d\'hémogramme',
      'de': 'Zeit für die monatliche Hämogramm-Kontrolle',
      'ar': 'وقت فحص تعداد الدم الشهري',
    },
    'test_reminder_description': {
      'tr': 'Düzenli kontroller sağlığınızı korumanıza yardımcı olur. Bugün test için randevu alabilirsiniz.',
      'en': 'Regular checks help maintain your health. You can schedule a test today.',
      'es': 'Los controles regulares ayudan a mantener tu salud. Puedes programar una prueba hoy.',
      'fr': 'Les contrôles réguliers aident à maintenir ta santé. Tu peux planifier un test aujourd\'hui.',
      'de': 'Regelmäßige Kontrollen helfen, deine Gesundheit zu erhalten. Du kannst heute einen Test planen.',
      'ar': 'الفحوصات المنتظمة تساعد في الحفاظ على صحتك. يمكنك جدولة فحص اليوم.',
    },
    // Notification titles and bodies
    'medication_reminder_title': {
      'tr': 'İlaç Zamanı',
      'en': 'Medication Reminder',
      'es': 'Recordatorio de Medicación',
      'fr': 'Rappel de Médicament',
      'de': 'Medikamenten-Erinnerung',
      'ar': 'تذكير الدواء',
    },
    'appointment_reminder_title': {
      'tr': 'Randevu Hatırlatıcısı',
      'en': 'Appointment Reminder',
      'es': 'Recordatorio de Cita',
      'fr': 'Rappel de Rendez-vous',
      'de': 'Termin-Erinnerung',
      'ar': 'تذكير الموعد',
    },
    // Use dosage_text and location_text to optionally include parenthetical info like " (500mg)"
    'medication_reminder_body': {
      'tr': '{medication}{dosage_text} almanızın zamanı geldi',
      'en': 'It is time to take {medication}{dosage_text}',
      'es': 'Es hora de tomar {medication}{dosage_text}',
      'fr': 'Il est temps de prendre {medication}{dosage_text}',
      'de': 'Es ist Zeit, {medication}{dosage_text} einzunehmen',
      'ar': 'حان وقت تناول {medication}{dosage_text}',
    },
    'appointment_reminder_body': {
      'tr': 'Dr. {doctor} ile randevunuz{location_text} yaklaşıyor',
      'en': 'Your appointment with Dr. {doctor}{location_text} is approaching',
      'es': 'Tu cita con el Dr. {doctor}{location_text} se acerca',
      'fr': 'Votre rendez-vous avec le Dr {doctor}{location_text} approche',
      'de': 'Ihr Termin mit Dr. {doctor}{location_text} rückt näher',
      'ar': 'موعدك مع د. {doctor}{location_text} يقترب',
    },
    'test_reminder_body': {
      'tr': '{test} testinizi yaptırmanızın zamanı geldi{location_text}',
      'en': 'It is time for your {test} test{location_text}',
      'es': 'Es hora de tu prueba de {test}{location_text}',
      'fr': 'Il est temps pour votre test {test}{location_text}',
      'de': 'Es ist Zeit für Ihren {test}-Test{location_text}',
      'ar': 'حان وقت فحص {test}{location_text}',
    },
    // Enhanced error messaging
    'export_error_title': {
      'tr': 'Dışa Aktarma Hatası',
      'en': 'Export Error',
      'es': 'Error de Exportación',
      'fr': 'Erreur d\'Exportation',
      'de': 'Export-Fehler',
      'ar': 'خطأ في التصدير',
    },
    'export_error_message': {
      'tr': '{type} dışa aktarırken bir hata oluştu:',
      'en': 'An error occurred while exporting {type}:',
      'es': 'Se produjo un error al exportar {type}:',
      'fr': 'Une erreur s\'est produite lors de l\'exportation {type}:',
      'de': 'Ein Fehler ist beim Exportieren von {type} aufgetreten:',
      'ar': 'حدث خطأ أثناء تصدير {type}:',
    },
    // 'error_details' defined earlier
    'troubleshooting_tips': {
      'tr': 'Sorun Giderme İpuçları:',
      'en': 'Troubleshooting Tips:',
      'es': 'Consejos de Solución de Problemas:',
      'fr': 'Conseils de Dépannage:',
      'de': 'Fehlerbehebung-Tipps:',
      'ar': 'نصائح استكشاف الأخطاء:',
    },
    'export_troubleshooting': {
      'tr': '• Cihazınızda yeterli depolama alanı olduğundan emin olun\n• İnternet bağlantınızı kontrol edin\n• Uygulamayı yeniden başlatmayı deneyin\n• Sorun devam ederse, destek ekibimizle iletişime geçin',
      'en': '• Ensure you have sufficient storage space on your device\n• Check your internet connection\n• Try restarting the app\n• Contact our support team if the issue persists',
      'es': '• Asegúrate de tener suficiente espacio de almacenamiento en tu dispositivo\n• Verifica tu conexión a internet\n• Intenta reiniciar la aplicación\n• Contacta a nuestro equipo de soporte si el problema persiste',
      'fr': '• Assurez-vous d\'avoir suffisamment d\'espace de stockage sur votre appareil\n• Vérifiez votre connexion internet\n• Essayez de redémarrer l\'application\n• Contactez notre équipe de support si le problème persiste',
      'de': '• Stellen Sie sicher, dass Sie ausreichend Speicherplatz auf Ihrem Gerät haben\n• Überprüfen Sie Ihre Internetverbindung\n• Versuchen Sie, die App neu zu starten\n• Kontaktieren Sie unser Support-Team, wenn das Problem weiterhin besteht',
      'ar': '• تأكد من وجود مساحة تخزين كافية على جهازك\n• تحقق من اتصالك بالإنترنت\n• جرب إعادة تشغيل التطبيق\n• اتصل بفريق الدعم إذا استمرت المشكلة',
    },
    'try_again': {
      'tr': 'Tekrar Dene',
      'en': 'Try Again',
      'es': 'Intentar Nuevamente',
      'fr': 'Réessayer',
      'de': 'Erneut Versuchen',
      'ar': 'حاول مرة أخرى',
    },
    'refresh_data': {
      'tr': 'Verileri Yenile',
      'en': 'Refresh Data',
      'es': 'Actualizar Datos',
      'fr': 'Actualiser les Données',
      'de': 'Daten Aktualisieren',
      'ar': 'تحديث البيانات',
    },
    'trends_section_label': {
      'tr': 'Hemogram değerleri trend grafiği bölümü',
      'en': 'Hemogram values trend chart section',
      'es': 'Sección de gráfico de tendencias de valores de hemograma',
      'fr': 'Section du graphique de tendance des valeurs d\'hémogramme',
      'de': 'Bereich des Trend-Diagramms für Hämogramm-Werte',
      'ar': 'قسم مخطط اتجاه قيم تحليل الدم',
    },
  };

  // Static translate method for easy access
  static String translate(String key) {
    return _instance.getString(key);
  }

  // Check if a localization key exists in any dictionary
  bool hasKey(String key) {
    return _localizedStrings.containsKey(key);
  }

  // Get first available string from the provided keys (tries in order)
  String getStringPrefer(List<String> keys, {String? defaultValue}) {
    for (final k in keys) {
      if (hasKey(k)) {
        return getString(k, defaultValue: defaultValue);
      }
    }
    // Fallback to the last key as-is if nothing found
    if (keys.isNotEmpty) {
      return getString(keys.last, defaultValue: defaultValue);
    }
    return defaultValue ?? '';
  }

  // Get localized string
  String getString(String key, {String? defaultValue}) {
    final languageStrings = _localizedStrings[key];
    if (languageStrings != null) {
      return languageStrings[currentLanguageCode] ??
          languageStrings['en'] ??
          defaultValue ??
          key;
    }
    return defaultValue ?? key;
  }

  // Get localized string with parameters
  String getStringWithParams(String key, Map<String, String> params, {String? defaultValue}) {
    String result = getString(key, defaultValue: defaultValue);
    
    params.forEach((paramKey, paramValue) {
      result = result.replaceAll('{$paramKey}', paramValue);
    });
    
    return result;
  }

  // Format date based on locale
  String formatDate(DateTime date) {
    switch (currentLanguageCode) {
      case 'en':
        return '${date.month}/${date.day}/${date.year}';
      case 'de':
        return '${date.day}.${date.month}.${date.year}';
      case 'fr':
        return '${date.day}/${date.month}/${date.year}';
      case 'es':
        return '${date.day}/${date.month}/${date.year}';
      case 'ar':
        return '${date.year}/${date.month}/${date.day}';
      case 'tr':
      default:
        return '${date.day}/${date.month}/${date.year}';
    }
  }

  // Format time based on locale
  String formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    
    switch (currentLanguageCode) {
      case 'en':
        final period = time.hour >= 12 ? 'PM' : 'AM';
        final hour12 = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
        return '${hour12.toString().padLeft(2, '0')}:$minute $period';
      default:
        return '$hour:$minute';
    }
  }

  // Format number based on locale
  String formatNumber(double number, {int decimals = 1}) {
    switch (currentLanguageCode) {
      case 'de':
        return number.toStringAsFixed(decimals).replaceAll('.', ',');
      case 'fr':
        return number.toStringAsFixed(decimals).replaceAll('.', ',');
      default:
        return number.toStringAsFixed(decimals);
    }
  }
}