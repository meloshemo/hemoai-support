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
            print('⚠️ Failed to detect system locale, using fallback en. Error: $e');
          }
        }
      }
      
      notifyListeners();
      
      if (kDebugMode) {
        print('🌍 LocalizationService initialized with locale: ${_currentLocale.languageCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing LocalizationService: $e');
      }
    }
  }

  // Change language
  Future<void> changeLanguage(String languageCode) async {
    try {
      final newLocale = Locale(languageCode, '');
      
      if (supportedLocales.contains(newLocale)) {
        _currentLocale = newLocale;
        
        // Save to preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('selected_language', languageCode);
        
        notifyListeners();
        
        if (kDebugMode) {
          print('🌍 Language changed to: $languageCode');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error changing language: $e');
      }
    }
  }

  // Get current language code
  String get currentLanguageCode => _currentLocale.languageCode;

  // Get current language name
  String get currentLanguageName => languageNames[currentLanguageCode] ?? 'Unknown';

  // Get current language flag
  String get currentLanguageFlag => languageFlags[currentLanguageCode] ?? '🌐';

  // Check if current language is RTL
  bool get isRTL => currentLanguageCode == 'ar';

  // Get text direction
  TextDirection get textDirection => isRTL ? TextDirection.rtl : TextDirection.ltr;

  // Localized strings - Main translations
  // Removed const to avoid constant evaluation issues with large map & escaped quotes
  static final Map<String, Map<String, String>> _localizedStrings = {
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
    'no_hemogram_data': {
      'en': 'No hemogram data found',
      'tr': 'Hemogram verileri bulunamadı',
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
    'register': {
      'tr': 'Kayıt Ol',
      'en': 'Register',
      'es': 'Registrarse',
      'fr': 'S\'inscrire',
      'de': 'Registrieren',
      'ar': 'تسجيل حساب',
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
    // Parameterized info labels for reminders
    'weekly_reminders_scheduled': {
      'en': 'Scheduled {count} weekly reminders',
      'tr': '{count} haftalık hatırlatıcı planlandı',
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
    'diet_program': {
      'tr': 'Diyet Programı',
      'en': 'Diet Program',
      'es': 'Programa de Dieta',
      'fr': 'Programme de Régime',
      'de': 'Diätprogramm',
      'ar': 'برنامج الحمية',
    },
    'family_panel': {
      'tr': 'Aile Paneli',
      'en': 'Family Panel',
      'es': 'Panel Familiar',
      'fr': 'Panneau Familial',
      'de': 'Familien Panel',
      'ar': 'لوحة العائلة',
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
    'customize_your_experience': {
      'tr': 'Deneyiminizi özelleştirin',
      'en': 'Customize your experience',
      'es': 'Personaliza tu experiencia',
      'fr': 'Personnalisez votre expérience',
      'de': 'Passen Sie Ihre Erfahrung an',
      'ar': 'خصص تجربتك',
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
    'favorites': {
      'tr': 'Favoriler',
      'en': 'Favorites',
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
    'export_options': {
      'tr': 'Dışa Aktarma Seçenekleri',
      'en': 'Export Options',
    },
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
    'gender': {
      'tr': 'Cinsiyet',
      'en': 'Gender',
      'es': 'Género',
      'fr': 'Genre',
      'de': 'Geschlecht',
      'ar': 'الجنس',
    },
    'male': {
      'tr': 'Erkek',
      'en': 'Male',
      'es': 'Masculino',
      'fr': 'Homme',
      'de': 'Männlich',
      'ar': 'ذكر',
    },
    'female': {
      'tr': 'Kadın',
      'en': 'Female',
      'es': 'Femenino',
      'fr': 'Femme',
      'de': 'Weiblich',
      'ar': 'أنثى',
    },
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
    'change_language_desc': {
      'en': 'Choose app language',
      'tr': 'Uygulama dilini seçin',
    },
    'diet_share_button': {
      'en': 'Share',
      'tr': 'Paylaş',
    },
    'diet_share_message_prefix': {
      'en': 'My personalized diet suggestions from HemoAI:',
      'tr': 'HemoAI’den kişisel diyet önerilerim:',
    },
    'share_day_menu': {
      'tr': 'Günün Menüsünü Paylaş',
      'en': 'Share Day Menu',
    },
    'share_day_menu_title': {
      'tr': 'Kişisel Günlük Menü',
      'en': 'Personal Daily Menu',
    },
    'copy_day_menu': {
      'tr': 'Günün Menüsünü Kopyala',
      'en': 'Copy Day Menu',
    },
    'day_menu_copied': {
      'tr': 'Günlük menü kopyalandı',
      'en': 'Daily menu copied',
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
    'personal_info': {
      'tr': 'Kişisel Bilgiler',
      'en': 'Personal Information',
      'es': 'Información Personal',
      'fr': 'Informations Personnelles',
      'de': 'Persönliche Informationen',
      'ar': 'المعلومات الشخصية',
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
    'calculate_bmi': {
      'tr': 'VKİ Hesapla',
      'en': 'Calculate BMI',
      'es': 'Calcular IMC',
      'fr': 'Calculer l\'IMC',
      'de': 'BMI Berechnen',
      'ar': 'احسب مؤشر كتلة الجسم',
    },
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
    // Hemogram specific extended translations
    'red_blood_cells': {
      'tr': 'Eritrosit',
      'en': 'Red Blood Cells',
      'es': 'Glóbulos Rojos',
      'fr': 'Globules Rouges',
      'de': 'Rote Blutkörperchen',
      'ar': 'خلايا الدم الحمراء',
    },
    'mcv': {
      'tr': 'MCV',
      'en': 'MCV',
      'es': 'VCM',
      'fr': 'VGM',
      'de': 'MCV',
      'ar': 'متوسط حجم الكرية',
    },
    'mch': {
      'tr': 'MCH',
      'en': 'MCH',
      'es': 'HCM',
      'fr': 'TCMH',
      'de': 'MCH',
      'ar': 'متوسط هيموجلوبين الكرية',
    },
    'mchc': {
      'tr': 'MCHC',
      'en': 'MCHC',
      'es': 'CHCM',
      'fr': 'CCMH',
      'de': 'MCHC',
      'ar': 'متوسط تركيز الهيموجلوبين',
    },
    'rdw': {
      'tr': 'RDW',
      'en': 'RDW',
      'es': 'ADE',
      'fr': 'IDE',
      'de': 'RDW',
      'ar': 'عرض توزيع كريات الدم الحمراء',
    },
    'neutrophil': {
      'tr': 'Nötrofil',
      'en': 'Neutrophil',
      'es': 'Neutrófilo',
      'fr': 'Neutrophile',
      'de': 'Neutrophil',
      'ar': 'العدلات',
    },
    'lymphocyte': {
      'tr': 'Lenfosit',
      'en': 'Lymphocyte',
      'es': 'Linfocito',
      'fr': 'Lymphocyte',
      'de': 'Lymphozyt',
      'ar': 'الخلايا اللمفاوية',
    },
    'monocyte': {
      'tr': 'Monosit',
      'en': 'Monocyte',
      'es': 'Monocito',
      'fr': 'Monocyte',
      'de': 'Monozyt',
      'ar': 'الوحيدات',
    },
    'eosinophil': {
      'tr': 'Eozinofil',
      'en': 'Eosinophil',
      'es': 'Eosinófilo',
      'fr': 'Éosinophile',
      'de': 'Eosinophil',
      'ar': 'الحمضات',
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
    // Smart Summary & Risk Score
    'smart_summary_title': {
      'tr': 'Akıllı Özet',
      'en': 'Smart Summary',
    },
    'risk_score_label': {
      'tr': 'Risk Skoru',
      'en': 'Risk Score',
    },
    'top_flags_label': {
      'tr': 'Öne Çıkan Bulgular',
      'en': 'Top Flags',
    },
    'next_steps_label': {
      'tr': 'Sonraki Adımlar',
      'en': 'Next Steps',
    },
    'maintain_healthy_habits': {
      'tr': 'Sağlıklı alışkanlıklara devam edin',
      'en': 'Maintain healthy habits',
    },
    'consider_follow_up': {
      'tr': '1-2 hafta içinde takip testi düşünün',
      'en': 'Consider a follow-up test in 1-2 weeks',
    },
    'multiple_abnormalities': {
      'tr': 'Birden fazla anormallik tespit edildi',
      'en': 'Multiple abnormalities detected',
    },
    // Reminder streaks & actions
    'mark_as_done': {
      'tr': 'Tamamlandı',
      'en': 'Mark as Done',
    },
    'snooze_10m': {
      'tr': '10 dk ertele',
      'en': 'Snooze 10m',
    },
    'current_streak_label': {
      'tr': 'Seri',
      'en': 'Streak',
    },
    'longest_streak_label': {
      'tr': 'Rekor',
      'en': 'Best',
    },
    'days_suffix': {
      'tr': 'gün',
      'en': 'days',
    },
    // Release branding
    'release_name': {
      'tr': 'OS 4 HemoAI',
      'en': 'OS 4 HemoAI',
    },
    'release_label': {
      'tr': 'Sürüm',
      'en': 'Release',
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
    'about_hemoai_title': {
      'tr': 'HemoAI Hakkında',
      'en': 'About HemoAI',
    },
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
    'health_assistant': {
      'tr': 'Sağlık Asistanı',
      'en': 'Health Assistant',
    },
    'ai_analysis': {
      'tr': 'AI Analizi',
      'en': 'AI Analysis',
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
    'reminders': {
      'tr': 'Hatırlatıcılar',
      'en': 'Reminders',
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
    'details': {
      'tr': 'Detaylar',
      'en': 'Details',
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
    'family_member_added': {
      'tr': 'Aile üyesi başarıyla eklendi!',
      'en': 'Family member added successfully!',
    },
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
    // =====================
    // Export / Restore
    // =====================
    'restore_data': {
      'en': 'Restore Data',
      'tr': 'Verileri Geri Yükle',
    },
    'restore_data_desc': {
      'en': 'Restore your backup file to this device',
      'tr': 'Yedek dosyanızı bu cihaza geri yükleyin',
    },
    'export_success': {
      'en': 'Export completed successfully',
      'tr': 'Dışa aktarma başarıyla tamamlandı',
    },
    'export_failed': {
      'en': 'Export failed',
      'tr': 'Dışa aktarma başarısız',
    },
    'no_file_selected': {
      'en': 'No file selected',
      'tr': 'Dosya seçilmedi',
    },
    'export_error_title': {
      'en': 'Export Error',
      'tr': 'Dışa Aktarma Hatası',
    },
    'export_error_message': {
      'en': 'An error occurred while exporting your data.',
      'tr': 'Veriler dışa aktarılırken bir hata oluştu.',
    },
    'troubleshooting_tips': {
      'en': 'Troubleshooting Tips',
      'tr': 'Sorun Giderme İpuçları',
    },
    'export_troubleshooting': {
      'en': '• Check file permissions\n• Ensure enough storage space\n• Try another format',
      'tr': '• Dosya izinlerini kontrol edin\n• Yeterli depolama alanı olduğundan emin olun\n• Başka bir format deneyin',
    },
    'try_again': {
      'en': 'Try Again',
      'tr': 'Tekrar Dene',
    },
    // =====================
    // Full Results
    // =====================
    'full_results_title': {
      'en': 'Full Results',
      'tr': 'Tüm Sonuçlar',
    },
    'no_results_available': {
      'en': 'No results available',
      'tr': 'Sonuç bulunmuyor',
    },
    // =====================
    // Guest
    // =====================
    'guest_mode_description': {
      'en': 'Use basic features without creating an account.',
      'tr': 'Hesap oluşturmadan temel özellikleri kullanın.',
    },
    'edit_profile': {
      'en': 'Edit Profile',
      'tr': 'Profili Düzenle',
    },
    // Generic simple values
    'good': {
      'en': 'Good',
      'tr': 'İyi',
    },
    'value': {
      'en': 'Value',
      'tr': 'Değer',
    },
    // =====================
    // OCR
    // =====================
    'ocr_reader': {
      'en': 'OCR Reader',
      'tr': 'OCR Okuyucu',
    },
    'ocr_desktop_placeholder': {
      'en': 'On desktop, select an image file to scan',
      'tr': 'Masaüstünde, taramak için bir görsel dosyası seçin',
    },
    'scan_document': {
      'en': 'Scan Document',
      'tr': 'Belgeyi Tara',
    },
    'ocr_review_title': {
      'en': 'Review Extracted Values',
      'tr': 'Çıkarılan Değerleri İncele',
    },
    'view_source_image': {
      'en': 'View source image',
      'tr': 'Kaynak görseli görüntüle',
    },
    'ocr_review_instructions': {
      'en': 'Please confirm or correct the values below before saving.',
      'tr': 'Kaydetmeden önce aşağıdaki değerleri onaylayın veya düzeltin.',
    },
    'ocr_review_description': {
      'en': 'We parsed key hemogram parameters from your image.',
      'tr': 'Görselinizden temel hemogram parametreleri çıkarıldı.',
    },
    'ocr_review_warnings': {
      'en': 'Some values may be uncertain due to image quality.',
      'tr': 'Görsel kalitesi nedeniyle bazı değerler belirsiz olabilir.',
    },
    'processing': {
      'en': 'Processing...',
      'tr': 'İşleniyor...',
    },
    'confirm_values': {
      'en': 'Confirm Values',
      'tr': 'Değerleri Onayla',
    },
    'enter_value': {
      'en': 'Enter value',
      'tr': 'Değer girin',
    },
    'value_outside_normal_range': {
      'en': 'Value is outside the normal range',
      'tr': 'Değer normal aralığın dışında',
    },
    // =====================
    // Notification Debug
    // =====================
    'notification_debug_title': {
      'en': 'Notification Debug',
      'tr': 'Bildirim Hata Ayıklama',
    },
    'notification_debug_scheduled': {
      'en': 'Scheduled notifications',
      'tr': 'Planlanan bildirimler',
    },
    'notification_debug_received': {
      'en': 'Recently received',
      'tr': 'Son alınanlar',
    },
    'why_did_i_get_this': {
      'en': 'Why did I get this?',
      'tr': 'Bu neden geldi?',
    },
    'reason_scheduled_time': {
      'en': 'Scheduled time',
      'tr': 'Planlanan saat',
    },
    'reason_received_at': {
      'en': 'Received at',
      'tr': 'Alındığı zaman',
    },
    'reason_repeat': {
      'en': 'Repeat',
      'tr': 'Tekrar',
    },
    'reason_reminder_id': {
      'en': 'Reminder ID',
      'tr': 'Hatırlatıcı ID',
    },
    'reason_category': {
      'en': 'Category',
      'tr': 'Kategori',
    },
    'reason_hour': {
      'en': 'Hour',
      'tr': 'Saat',
    },
    'reason_minute': {
      'en': 'Minute',
      'tr': 'Dakika',
    },
    'reason_device_token': {
      'en': 'Device token',
      'tr': 'Cihaz anahtarı',
    },
    'reason_permission_granted': {
      'en': 'Permission granted',
      'tr': 'İzin verildi',
    },
    'notification_debug_logs': {
      'en': 'Debug logs',
      'tr': 'Hata ayıklama kayıtları',
    },
    'none': {
      'en': 'None',
      'tr': 'Yok',
    },
    // =====================
    // Performance
    // =====================
    'performance_settings': {
      'en': 'Performance Settings',
      'tr': 'Performans Ayarları',
    },
    'enable_animations': {
      'en': 'Enable animations',
      'tr': 'Animasyonları etkinleştir',
    },
    'reduce_motion': {
      'en': 'Reduce motion',
      'tr': 'Hareketi azalt',
    },
    'clear_cache': {
      'en': 'Clear cache',
      'tr': 'Önbelleği temizle',
    },
    'apply_recommended_settings': {
      'en': 'Apply recommended settings',
      'tr': 'Önerilen ayarları uygula',
    },
    'cache_info': {
      'en': 'Cache helps speed up the app but may take storage.',
      'tr': 'Önbellek uygulamayı hızlandırır ancak depolama kullanabilir.',
    },
    'performance_recommendations': {
      'en': 'Performance recommendations',
      'tr': 'Performans önerileri',
    },
    // =====================
    // Restore Preview
    // =====================
    'restore_preview': {
      'en': 'Restore Preview',
      'tr': 'Geri Yükleme Önizlemesi',
    },
    'backup_overview': {
      'en': 'Backup Overview',
      'tr': 'Yedek Özeti',
    },
    'backup_platform': {
      'en': 'Platform',
      'tr': 'Platform',
    },
    'preferences': {
      'en': 'Preferences',
      'tr': 'Tercihler',
    },
    'diet_entries': {
      'en': 'Diet Entries',
      'tr': 'Diyet Kayıtları',
    },
    'users': {
      'en': 'Users',
      'tr': 'Kullanıcılar',
    },
    'hemogram_tests': {
      'en': 'Hemogram Tests',
      'tr': 'Hemogram Testleri',
    },
    'family_invitations': {
      'en': 'Family Invitations',
      'tr': 'Aile Davetleri',
    },
    'water': {
      'en': 'Water',
      'tr': 'Su',
    },
    'restore_strategy': {
      'en': 'Restore Strategy',
      'tr': 'Geri Yükleme Stratejisi',
    },
    'restore_merge': {
      'en': 'Merge (keep existing + add from backup)',
      'tr': 'Birleştir (mevcut kalsın + yedekten ekle)',
    },
    'restore_replace': {
      'en': 'Replace (wipe current and load backup)',
      'tr': 'Değiştir (mevcut silinsin, yedek yüklensin)',
    },
    'restore_merge_desc': {
      'en': 'Adds backup items without removing your current data.',
      'tr': 'Mevcut verilerinizi silmeden yedek öğeleri ekler.',
    },
    'restore_replace_desc': {
      'en': 'Erases current data and replaces everything with backup.',
      'tr': 'Mevcut verileri siler ve her şeyi yedekle değiştirir.',
    },
    'apply_restore': {
      'en': 'Apply Restore',
      'tr': 'Geri Yüklemeyi Uygula',
    },
    'error_details': {
      'en': 'Error details',
      'tr': 'Hata detayları',
    },
    // =====================
    // Settings
    // =====================
    'settings_personal_data': {
      'en': 'Personal Data',
      'tr': 'Kişisel Veriler',
    },
    'edit_profile_desc': {
      'en': 'Update your personal information',
      'tr': 'Kişisel bilgilerinizi güncelleyin',
    },
    'account_login': {
      'en': 'Account & Login',
      'tr': 'Hesap ve Giriş',
    },
    'account_login_desc': {
      'en': 'Manage your account and login preferences',
      'tr': 'Hesap ve giriş tercihlerini yönetin',
    },
    'settings_privacy': {
      'en': 'Privacy',
      'tr': 'Gizlilik',
    },
    'privacy_policy': {
      'en': 'Privacy Policy',
      'tr': 'Gizlilik Politikası',
    },
    'privacy_policy_desc': {
      'en': 'How we handle your data',
      'tr': 'Verilerinizi nasıl işlediğimiz',
    },
    'privacy_policy_body': {
      'en': 'We store your data locally and respect your privacy.',
      'tr': 'Verilerinizi yerel olarak saklarız ve gizliliğinize saygı duyarız.',
    },
    'terms_of_use': {
      'en': 'Terms of Use',
      'tr': 'Kullanım Şartları',
    },
    'terms_of_use_desc': {
      'en': 'Rules for using the app',
      'tr': 'Uygulamanın kullanım kuralları',
    },
    'terms_of_use_body': {
      'en': 'Use at your own responsibility. Not a medical device.',
      'tr': 'Kullanım sorumluluğu size aittir. Tıbbi cihaz değildir.',
    },
    'analytics_opt_in': {
      'en': 'Allow anonymous analytics',
      'tr': 'Anonim analizlere izin ver',
    },
    'analytics_opt_in_desc': {
      'en': 'Help us improve by sharing anonymous usage data',
      'tr': 'Anonim kullanım verileri paylaşarak gelişime yardımcı olun',
    },
    'settings_security': {
      'en': 'Security',
      'tr': 'Güvenlik',
    },
    'privacy_summary_title': {
      'en': 'Privacy Summary',
      'tr': 'Gizlilik Özeti',
    },
    'privacy_summary_desc': {
      'en': 'Key points about your data privacy',
      'tr': 'Veri gizliliğiniz hakkında önemli noktalar',
    },
    'privacy_summary_body': {
      'en': 'Your data stays on your device unless you export it.',
      'tr': 'Verileriniz, dışa aktarmadığınız sürece cihazınızda kalır.',
    },
    'app_lock': {
      'en': 'App Lock',
      'tr': 'Uygulama Kilidi',
    },
    'app_lock_desc': {
      'en': 'Protect HemoAI with a passcode',
      'tr': 'HemoAI uygulamasını bir şifre ile koruyun',
    },
    'clear_notifications': {
      'en': 'Clear notifications',
      'tr': 'Bildirimleri temizle',
    },
    'clear_notifications_desc': {
      'en': 'Remove all in-app notifications',
      'tr': 'Uygulama içi tüm bildirimleri kaldırın',
    },
    'done': {
      'en': 'Done',
      'tr': 'Bitti',
    },
    'notification_debug_desc': {
      'en': 'Inspect scheduled and received notifications',
      'tr': 'Planlanan ve alınan bildirimleri inceleyin',
    },
    'settings_data_backup': {
      'en': 'Data Backup',
      'tr': 'Veri Yedeği',
    },
    'trial_backup_title': {
      'en': 'Try Backup',
      'tr': 'Yedeği Dene',
    },
    'trial_backup_desc': {
      'en': 'Create a quick backup to see how it works',
      'tr': 'Nasıl çalıştığını görmek için hızlı bir yedek oluşturun',
    },
    'stats_overview_title': {
      'en': 'Statistics Overview',
      'tr': 'İstatistiklere Genel Bakış',
    },
    'stats_overview_desc': {
      'en': 'See your app usage and health stats',
      'tr': 'Uygulama kullanımı ve sağlık istatistiklerinizi görün',
    },
    'backup_data': {
      'en': 'Backup Data',
      'tr': 'Verileri Yedekle',
    },
    'backup_data_desc': {
      'en': 'Create a backup file of your data',
      'tr': 'Verilerinizin bir yedek dosyasını oluşturun',
    },
    'backup_ready': {
      'en': 'Backup is ready',
      'tr': 'Yedek hazır',
    },
    'encrypted_backup': {
      'en': 'Encrypted Backup',
      'tr': 'Şifreli Yedek',
    },
    'encrypted_backup_desc': {
      'en': 'Protect your backup with a password (AES-GCM)',
      'tr': 'Yedeğinizi bir şifre ile koruyun (AES-GCM)',
    },
    'encryption_enabled': {
      'en': 'Encryption enabled',
      'tr': 'Şifreleme etkin',
    },
    'decryption_failed': {
      'en': 'Decryption failed',
      'tr': 'Şifre çözme başarısız',
    },
    'delete_all_data': {
      'en': 'Delete all data',
      'tr': 'Tüm verileri sil',
    },
    'delete_all_data_desc': {
      'en': 'This will permanently remove all app data',
      'tr': 'Bu işlem tüm uygulama verilerini kalıcı olarak silecek',
    },
    'delete_all_data_confirm': {
      'en': 'Are you sure you want to delete all data?',
      'tr': 'Tüm verileri silmek istediğinize emin misiniz?',
    },
    'data_deleted': {
      'en': 'All data deleted',
      'tr': 'Tüm veriler silindi',
    },
    'cache_management': {
      'en': 'Cache Management',
      'tr': 'Önbellek Yönetimi',
    },
    'cache_cleared': {
      'en': 'Cache cleared',
      'tr': 'Önbellek temizlendi',
    },
    'optimize_for_device': {
      'en': 'Optimize for this device',
      'tr': 'Bu cihaz için optimize et',
    },
    'performance_optimized': {
      'en': 'Performance optimized',
      'tr': 'Performans optimize edildi',
    },
    'advanced_performance': {
      'en': 'Advanced Performance',
      'tr': 'Gelişmiş Performans',
    },
    'detailed_performance_controls': {
      'en': 'Detailed performance controls',
      'tr': 'Detaylı performans kontrolleri',
    },
    'settings_legal': {
      'en': 'Legal',
      'tr': 'Yasal',
    },
    'app_description_detailed': {
      'en': 'HemoAI helps you track hemogram values, analyze trends, and manage reminders for a healthier life.',
      'tr': 'HemoAI, hemogram değerlerinizi takip etmenize, trendleri analiz etmenize ve daha sağlıklı bir yaşam için hatırlatıcıları yönetmenize yardımcı olur.',
    },
    'medical_disclaimer': {
      'en': 'Medical Disclaimer',
      'tr': 'Tıbbi Uyarı',
    },
    'medical_disclaimer_desc': {
      'en': 'This app is not a substitute for professional medical advice.',
      'tr': 'Bu uygulama profesyonel tıbbi tavsiyenin yerine geçmez.',
    },
    'medical_disclaimer_body': {
      'en': 'Always consult your doctor for medical questions and decisions.',
      'tr': 'Tıbbi sorular ve kararlar için daima doktorunuza danışın.',
    },
    'help_support_desc': {
      'en': 'How to get help and support',
      'tr': 'Yardım ve desteğe nasıl ulaşılır',
    },
    'help_support_body': {
      'en': 'Contact us via feedback form or check documentation.',
      'tr': 'Geri bildirim formundan bize ulaşın veya dokümantasyonu inceleyin.',
    },
    'set_backup_password': {
      'en': 'Set backup password',
      'tr': 'Yedek şifresi belirle',
    },
    'enter_backup_password': {
      'en': 'Enter backup password',
      'tr': 'Yedek şifresini girin',
    },
    'password': {
      'en': 'Password',
      'tr': 'Şifre',
    },
    'confirm_password': {
      'en': 'Confirm Password',
      'tr': 'Şifreyi Doğrula',
    },
    'auto_optimize': {
      'en': 'Auto optimize on startup',
      'tr': 'Açılışta otomatik optimize et',
    },
    // =====================
    // Stats
    // =====================
    'stats_total_tests': {
      'en': 'Total tests',
      'tr': 'Toplam test',
    },
    'stats_family_members': {
      'en': 'Family members',
      'tr': 'Aile üyeleri',
    },
    'stats_active_medications': {
      'en': 'Active medications',
      'tr': 'Aktif ilaçlar',
    },
    'stats_unread_notifications': {
      'en': 'Unread notifications',
      'tr': 'Okunmamış bildirimler',
    },
    'privacy_local_analytics_note': {
      'en': 'Analytics are processed locally and never leave your device.',
      'tr': 'Analizler yerel olarak işlenir ve cihazınızdan dışarı çıkmaz.',
    },
    // =====================
    // Export service headings
    // =====================
    'diet_programs': {
      'en': 'Diet Programs',
      'tr': 'Diyet Programları',
    },
    'weekly_plan': {
      'en': 'Weekly Plan',
      'tr': 'Haftalık Plan',
    },
    'weeks_completed': {
      'en': 'Weeks Completed',
      'tr': 'Tamamlanan Hafta',
    },
    'analysis_details_heading': {
      'en': 'Analysis Details',
      'tr': 'Analiz Detayları',
    },
    'recommendations_heading': {
      'en': 'Recommendations',
      'tr': 'Öneriler',
    },
    'key_parameters_heading': {
      'en': 'Key Parameters',
      'tr': 'Anahtar Parametreler',
    },
    // =====================
    // About Screen
    // =====================
    'key_features': {
      'en': 'Key Features',
      'tr': 'Öne Çıkan Özellikler',
    },
    'feature_ai_analysis': {
      'en': 'AI-powered analysis',
      'tr': 'Yapay zeka destekli analiz',
    },
    'feature_diet_recommendations': {
      'en': 'Diet recommendations',
      'tr': 'Diyet önerileri',
    },
    'feature_family_tracking': {
      'en': 'Family tracking',
      'tr': 'Aile takibi',
    },
    'feature_secure_data': {
      'en': 'Secure data storage',
      'tr': 'Güvenli veri saklama',
    },
    'feature_export_reports': {
      'en': 'Exportable reports',
      'tr': 'Dışa aktarılabilir raporlar',
    },
    'feature_multilingual': {
      'en': 'Multilingual support',
      'tr': 'Çok dilli destek',
    },
    'privacy_first': {
      'en': 'Privacy First',
      'tr': 'Önce Gizlilik',
    },
    'data_stays_local': {
      'en': 'Your data stays on this device',
      'tr': 'Verileriniz bu cihazda kalır',
    },
    'no_cloud_upload': {
      'en': 'No cloud uploads by default',
      'tr': 'Varsayılan olarak buluta yükleme yok',
    },
    'encrypted_backups': {
      'en': 'Encrypted backups',
      'tr': 'Şifreli yedekler',
    },
    'app_info': {
      'en': 'App Info',
      'tr': 'Uygulama Bilgisi',
    },
    'app_version': {
      'en': 'App Version',
      'tr': 'Uygulama Sürümü',
    },
    'build_number': {
      'en': 'Build Number',
      'tr': 'Yapı Numarası',
    },
    'developed_by': {
      'en': 'Developed by',
      'tr': 'Geliştiren',
    },
    'developer_name': {
      'en': 'Developer',
      'tr': 'Geliştirici',
    },
    'release_date': {
      'en': 'Release Date',
      'tr': 'Yayın Tarihi',
    },
    'rate_app': {
      'en': 'Rate App',
      'tr': 'Uygulamayı Puanla',
    },
    'share_app': {
      'en': 'Share App',
      'tr': 'Uygulamayı Paylaş',
    },
    'contact_support': {
      'en': 'Contact Support',
      'tr': 'Destek ile İletişim',
    },
    'open_source_licenses': {
      'en': 'Open Source Licenses',
      'tr': 'Açık Kaynak Lisansları',
    },
    'system_info': {
      'en': 'System Info',
      'tr': 'Sistem Bilgisi',
    },
    'support_email': {
      'en': 'Support Email',
      'tr': 'Destek E-postası',
    },
    // =====================
    // Alternative Medicine extras
    // =====================
    'reason_label': {
      'en': 'Reason',
      'tr': 'Neden',
    },
    'toggle_favorite': {
      'en': 'Toggle favorite',
      'tr': 'Favoriye al/çıkar',
    },
    'age_personalization_note': {
      'en': 'Recommendations are personalized by age and condition.',
      'tr': 'Öneriler yaş ve duruma göre kişiselleştirilir.',
    },
    'female_general_caution': {
      'en': 'Consult your doctor during pregnancy and breastfeeding.',
      'tr': 'Hamilelik ve emzirme döneminde doktorunuza danışın.',
    },
    // =====================
    // Data Import Flow
    // =====================
    'data_import_title': {
      'en': 'Import Data',
      'tr': 'Veri İçe Aktarma',
    },
    'data_import_welcome': {
      'en': 'Welcome to data import',
      'tr': 'Veri içe aktarmaya hoş geldiniz',
    },
    'data_import_subtitle': {
      'en': 'Bring your results from various sources',
      'tr': 'Sonuçlarınızı çeşitli kaynaklardan içe aktarın',
    },
    'import_options_title': {
      'en': 'Import Options',
      'tr': 'İçe Aktarma Seçenekleri',
    },
    'import_from_edevlet': {
      'en': 'Import from e-Devlet',
      'tr': 'e-Devlet’ten içe aktar',
    },
    'import_edevlet_description': {
      'en': 'Paste your e-Devlet hemogram snippet or connect',
      'tr': 'e-Devlet hemogram metnini yapıştırın veya bağlanın',
    },
    'import_from_qr': {
      'en': 'Import from QR',
      'tr': 'QR’dan içe aktar',
    },
    'import_qr_description': {
      'en': 'Scan a QR code that contains your results',
      'tr': 'Sonuçlarınızı içeren bir QR kodunu tarayın',
    },
    'import_from_text': {
      'en': 'Import from Text',
      'tr': 'Metinden içe aktar',
    },
    'import_text_description': {
      'en': 'Paste hemogram values from text',
      'tr': 'Metinden hemogram değerlerini yapıştırın',
    },
    'import_from_image': {
      'en': 'Import from Image',
      'tr': 'Görüntüden içe aktar',
    },
    'import_image_description': {
      'en': 'Use OCR to parse values from an image',
      'tr': 'Görüntüden değerleri almak için OCR kullanın',
    },
    'import_from_file': {
      'en': 'Import from File',
      'tr': 'Dosyadan içe aktar',
    },
    'import_file_description': {
      'en': 'Upload a file that includes your test results',
      'tr': 'Test sonuçlarınızı içeren bir dosyayı yükleyin',
    },
    'import_manual_entry': {
      'en': 'Manual Entry',
      'tr': 'Manuel Giriş',
    },
    'import_manual_description': {
      'en': 'Enter your values by hand',
      'tr': 'Değerleri elle girin',
    },
    'paste_text_title': {
      'en': 'Paste Text',
      'tr': 'Metni Yapıştır',
    },
    'paste_from_clipboard': {
      'en': 'Paste from clipboard',
      'tr': 'Panodan yapıştır',
    },
    'paste_text_instructions': {
      'en': 'Paste your hemogram text below to parse the values.',
      'tr': 'Hemogram metninizi aşağıya yapıştırın; değerler çözümlenecektir.',
    },
    'paste_text_hint': {
      'en': 'Paste text here...',
      'tr': 'Metni buraya yapıştırın...',
    },
    'parse_and_import': {
      'en': 'Parse & Import',
      'tr': 'Çözümle ve İçe Aktar',
    },
    'no_text_provided': {
      'en': 'No text provided',
      'tr': 'Metin girilmedi',
    },
    'parsing_text': {
      'en': 'Parsing text...',
      'tr': 'Metin çözümleniyor...',
    },
    'import_success_count': {
      'en': '{count} values imported',
      'tr': '{count} değer içe aktarıldı',
    },
    'import_failed': {
      'en': 'Import failed',
      'tr': 'İçe aktarma başarısız',
    },
    'import_error': {
      'en': 'Import error',
      'tr': 'İçe aktarma hatası',
    },
    'file_import_failed': {
      'en': 'File import failed',
      'tr': 'Dosya içe aktarma başarısız',
    },
    'qr_scan_failed': {
      'en': 'QR scan failed',
      'tr': 'QR tarama başarısız',
    },
    'view_full_results': {
      'en': 'View full results',
      'tr': 'Tüm sonuçları görüntüle',
    },
    'edevlet_login_title': {
      'en': 'e-Devlet Login',
      'tr': 'e-Devlet Girişi',
    },
    'edevlet_login_description': {
      'en': 'Connect with your e-Devlet to import records',
      'tr': 'Kayıtları içe aktarmak için e-Devlet ile bağlanın',
    },
    'tc_kimlik_no': {
      'en': 'T.C. Identity No',
      'tr': 'T.C. Kimlik No',
    },
    'edevlet_security_notice': {
      'en': 'Your credentials are only used locally.',
      'tr': 'Kimlik bilgileriniz yalnızca yerelde kullanılır.',
    },
    'edevlet_or_paste_label': {
      'en': 'Or paste the snippet below',
      'tr': 'Veya aşağıya metni yapıştırın',
    },
    'edevlet_paste_hint': {
      'en': 'Paste the e-Devlet results text here...',
      'tr': 'e-Devlet sonuç metnini buraya yapıştırın...',
    },
    'connect_and_import': {
      'en': 'Connect & Import',
      'tr': 'Bağlan ve İçe Aktar',
    },
    'edevlet_import_snippet_button': {
      'en': 'Use Pasted Text',
      'tr': 'Yapıştırılan Metni Kullan',
    },
    'edevlet_credentials_required': {
      'en': 'Credentials required',
      'tr': 'Kimlik bilgileri gerekli',
    },
    'edevlet_connecting': {
      'en': 'Connecting to e-Devlet...',
      'tr': 'e-Devlet’e bağlanılıyor...',
    },
    'qr_scanning': {
      'en': 'Scanning QR...',
      'tr': 'QR taranıyor...',
    },
    'file_processing': {
      'en': 'Processing file...',
      'tr': 'Dosya işleniyor...',
    },
    'file_processing_error': {
      'en': 'File processing error',
      'tr': 'Dosya işleme hatası',
    },
    'image_processing': {
      'en': 'Processing image...',
      'tr': 'Görsel işleniyor...',
    },
    'ocr_not_available_web': {
      'en': 'OCR is not available on web',
      'tr': 'OCR web üzerinde kullanılamıyor',
    },
    'image_import_failed': {
      'en': 'Image import failed',
      'tr': 'Görsel içe aktarma başarısız',
    },
    'image_processing_error': {
      'en': 'Image processing error',
      'tr': 'Görsel işleme hatası',
    },
    'login_required_for_save': {
      'en': 'Please log in to save imported results',
      'tr': 'İçe aktarılan sonuçları kaydetmek için giriş yapın',
    },
    // =====================
    // Enhanced Notification Snooze
    // =====================
    'snoozed_for_30': {
      'en': 'Snoozed for 30 minutes',
      'tr': '30 dakika ertelendi',
    },
    'snooze_30m': {
      'en': 'Snooze 30m',
      'tr': '30 dk ertele',
    },
    'snoozed_for_60': {
      'en': 'Snoozed for 60 minutes',
      'tr': '60 dakika ertelendi',
    },
    'snooze_60m': {
      'en': 'Snooze 60m',
      'tr': '60 dk ertele',
    },
    'custom_snooze': {
      'en': 'Custom snooze',
      'tr': 'Özel ertele',
    },
    'snooze_15m': {
      'en': 'Snooze 15m',
      'tr': '15 dk ertele',
    },
    'snoozed_for_n_minutes': {
      'en': 'Snoozed for {minutes} minutes',
      'tr': '{minutes} dakika ertelendi',
    },
    'snooze_2h': {
      'en': 'Snooze 2h',
      'tr': '2 sa ertele',
    },
    'enter_minutes': {
      'en': 'Enter minutes',
      'tr': 'Dakika girin',
    },
    'invalid_minutes': {
      'en': 'Please enter a valid number of minutes',
      'tr': 'Lütfen geçerli bir dakika değeri girin',
    },
    'snoozed_for_tomorrow': {
      'en': 'Snoozed until tomorrow morning',
      'tr': 'Yarın sabaha kadar ertelendi',
    },
    'tomorrow_morning': {
      'en': 'Tomorrow morning',
      'tr': 'Yarın sabah',
    },
    // =====================
    // Export Options defaults
    // =====================
    'patient_name_default': {
      'en': 'Unknown Patient',
      'tr': 'Bilinmeyen Hasta',
    },
    'no_analysis_available': {
      'en': 'No analysis available',
      'tr': 'Analiz mevcut değil',
    },
    // =====================
    // Register success (shortcut key)
    // =====================
    'register_success': {
      'en': 'Registration successful!',
      'tr': 'Kayıt başarılı!',
    },
  };

  // Hemogram specific translations
  static const Map<String, Map<String, String>> _hemogramStrings = {
    'hemoglobin': {
      'tr': 'Hemoglobin',
      'en': 'Hemoglobin',
      'es': 'Hemoglobina',
      'fr': 'Hémoglobine',
      'de': 'Hämoglobin',
      'ar': 'الهيموجلوبين',
    },
    'iron': {
      'tr': 'Demir',
      'en': 'Iron',
      'es': 'Hierro',
      'fr': 'Fer',
      'de': 'Eisen',
      'ar': 'الحديد',
    },
    'white_blood_cells': {
      'tr': 'Lökosit',
      'en': 'White Blood Cells',
      'es': 'Glóbulos Blancos',
      'fr': 'Globules Blancs',
      'de': 'Weiße Blutkörperchen',
      'ar': 'خلايا الدم البيضاء',
    },
    'platelets': {
      'tr': 'Trombosit',
      'en': 'Platelets',
      'es': 'Plaquetas',
      'fr': 'Plaquettes',
      'de': 'Thrombozyten',
      'ar': 'الصفائح الدموية',
    },
    'ferritin': {
      'tr': 'Ferritin',
      'en': 'Ferritin',
      'es': 'Ferritina',
      'fr': 'Ferritine',
      'de': 'Ferritin',
      'ar': 'الفيريتين',
    },
    'hematocrit': {
      'tr': 'Hematokrit',
      'en': 'Hematocrit',
      'es': 'Hematocrito',
      'fr': 'Hématocrite',
      'de': 'Hämatokrit',
      'ar': 'الهيماتوكريت',
    },
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
    'risk_level': {
      'tr': 'Risk Seviyesi',
      'en': 'Risk Level',
      'es': 'Nivel de Riesgo',
      'fr': 'Niveau de Risque',
      'de': 'Risikostufe',
      'ar': 'مستوى المخاطر',
    },
    'recommendations': {
      'tr': 'Öneriler',
      'en': 'Recommendations',
      'es': 'Recomendaciones',
      'fr': 'Recommandations',
      'de': 'Empfehlungen',
      'ar': 'التوصيات',
    },
    'export_options': {
      'tr': 'Export Seçenekleri',
      'en': 'Export Options',
      'es': 'Opciones de Exportación',
      'fr': 'Options d\'Exportation',
      'de': 'Export-Optionen',
      'ar': 'خيارات التصدير',
    },
    'loading_data': {
      'tr': 'Veriler yükleniyor...',
      'en': 'Loading data...',
      'es': 'Cargando datos...',
      'fr': 'Chargement des données...',
      'de': 'Daten werden geladen...',
      'ar': 'جاري تحميل البيانات...',
    },
    'no_hemogram_data': {
      'tr': 'Hemogram verileri bulunamadı',
      'en': 'No hemogram data found',
      'es': 'No se encontraron datos de hemograma',
      'fr': 'Aucune donnée d\'hémogramme trouvée',
      'de': 'Keine Hämogramm-Daten gefunden',
      'ar': 'لم يتم العثور على بيانات الهيموجرام',
    },
    'generated_by_hemoai': {
      'tr': 'HemoAI analizi ile oluşturulmuştur.',
      'en': 'Generated by HemoAI analysis.',
      'es': 'Generado por el análisis de HemoAI.',
      'fr': 'Généré par l\'analyse HemoAI.',
      'de': 'Generiert durch HemoAI-Analyse.',
      'ar': 'تم إنشاؤه بواسطة تحليل HemoAI.',
    },
    'pdf_export_success': {
      'tr': 'Hemogram PDF raporu başarıyla indirildi',
      'en': 'Hemogram PDF report downloaded successfully',
      'es': 'Informe PDF de hemograma descargado exitosamente',
      'fr': 'Rapport PDF d\'hémogramme téléchargé avec succès',
      'de': 'Hämogramm PDF-Bericht erfolgreich heruntergeladen',
      'ar': 'تم تنزيل تقرير الهيموجرام PDF بنجاح',
    },
    'pdf_export_failed': {
      'tr': 'PDF export işlemi başarısız',
      'en': 'PDF export failed',
      'es': 'Falló la exportación a PDF',
      'fr': 'Échec de l\'exportation PDF',
      'de': 'PDF-Export fehlgeschlagen',
      'ar': 'فشل تصدير PDF',
    },
    'excel_export_success': {
      'tr': 'Hemogram Excel verileri başarıyla indirildi',
      'en': 'Hemogram Excel data downloaded successfully',
      'es': 'Datos de hemograma Excel descargados exitosamente',
      'fr': 'Données Excel d\'hémogramme téléchargées avec succès',
      'de': 'Hämogramm Excel-Daten erfolgreich heruntergeladen',
      'ar': 'تم تنزيل بيانات الهيموجرام Excel بنجاح',
    },
    'excel_export_failed': {
      'tr': 'Excel export işlemi başarısız',
      'en': 'Excel export failed',
      'es': 'Falló la exportación a Excel',
      'fr': 'Échec de l\'exportation Excel',
      'de': 'Excel-Export fehlgeschlagen',
      'ar': 'فشل تصدير Excel',
    },
    'error_loading_data': {
      'tr': 'Veri yükleme hatası',
      'en': 'Error loading data',
      'es': 'Error al cargar datos',
      'fr': 'Erreur de chargement des données',
      'de': 'Fehler beim Laden der Daten',
      'ar': 'خطأ في تحميل البيانات',
    },
    'normal_values': {
      'tr': 'Değerler normal aralıkta',
      'en': 'Values are in normal range',
      'es': 'Los valores están en rango normal',
      'fr': 'Les valeurs sont dans la plage normale',
      'de': 'Werte sind im normalen Bereich',
      'ar': 'القيم في النطاق الطبيعي',
    },
    'abnormal_wbc': {
      'tr': 'Beyaz kan hücresi sayısı anormal',
      'en': 'White blood cell count is abnormal',
      'es': 'El recuento de glóbulos blancos es anormal',
      'fr': 'Le nombre de globules blancs est anormal',
      'de': 'Die Anzahl der weißen Blutkörperchen ist abnormal',
      'ar': 'عدد خلايا الدم البيضاء غير طبيعي',
    },
    'abnormal_hemoglobin': {
      'tr': 'Hemoglobin düzeyi anormal',
      'en': 'Hemoglobin level is abnormal',
      'es': 'El nivel de hemoglobina es anormal',
      'fr': 'Le niveau d\'hémoglobine est anormal',
      'de': 'Der Hämoglobinwert ist abnormal',
      'ar': 'مستوى الهيموجلوبين غير طبيعي',
    },
    'abnormal_platelets': {
      'tr': 'Trombosit sayısı anormal',
      'en': 'Platelet count is abnormal',
      'es': 'El recuento de plaquetas es anormal',
      'fr': 'Le nombre de plaquettes est anormal',
      'de': 'Die Thrombozytenzahl ist abnormal',
      'ar': 'عدد الصفائح الدموية غير طبيعي',
    },
    'consult_doctor': {
      'tr': 'Doktor ile görüşün',
      'en': 'Consult with doctor',
      'es': 'Consulte con el médico',
      'fr': 'Consultez un médecin',
      'de': 'Konsultieren Sie einen Arzt',
      'ar': 'استشر الطبيب',
    },
    'check_iron_levels': {
      'tr': 'Demir seviyelerini kontrol edin',
      'en': 'Check iron levels',
      'es': 'Verifique los niveles de hierro',
      'fr': 'Vérifiez les niveaux de fer',
      'de': 'Überprüfen Sie die Eisenwerte',
      'ar': 'تحقق من مستويات الحديد',
    },
    'monitor_bleeding': {
      'tr': 'Kanama durumunu takip edin',
      'en': 'Monitor bleeding condition',
      'es': 'Monitoree la condición de sangrado',
      'fr': 'Surveillez la condition de saignement',
      'de': 'Überwachen Sie die Blutungsneigung',
      'ar': 'راقب حالة النزيف',
    },
    'maintain_healthy_lifestyle': {
      'tr': 'Sağlıklı yaşam tarzını sürdürün',
      'en': 'Maintain healthy lifestyle',
      'es': 'Mantenga un estilo de vida saludable',
      'fr': 'Maintenez un mode de vie sain',
      'de': 'Führen Sie einen gesunden Lebensstil',
      'ar': 'حافظ على نمط حياة صحي',
    },
    'analysis_error': {
      'tr': 'Analiz hatası',
      'en': 'Analysis error',
      'es': 'Error de análisis',
      'fr': 'Erreur d\'analyse',
      'de': 'Analysefehler',
      'ar': 'خطأ في التحليل',
    },
    'unknown_risk': {
      'tr': 'Bilinmeyen risk',
      'en': 'Unknown risk',
      'es': 'Riesgo desconocido',
      'fr': 'Risque inconnu',
      'de': 'Unbekanntes Risiko',
      'ar': 'مخاطر غير معروفة',
    },
    'consult_healthcare_provider': {
      'tr': 'Sağlık sağlayıcısı ile görüşün',
      'en': 'Consult healthcare provider',
      'es': 'Consulte al proveedor de atención médica',
      'fr': 'Consultez un professionnel de la santé',
      'de': 'Konsultieren Sie einen Gesundheitsdienstleister',
      'ar': 'استشر مقدم الرعاية الصحية',
    },
    'hemogram_report': {
      'tr': 'HEMOGRAM TEST RAPORU',
      'en': 'HEMOGRAM TEST REPORT',
      'es': 'INFORME DE PRUEBA DE HEMOGRAMA',
      'fr': 'RAPPORT DE TEST D\'HÉMOGRAMME',
      'de': 'HÄMOGRAMM-TESTBERICHT',
      'ar': 'تقرير فحص الهيموجرام',
    },
    'patient_name': {
      'tr': 'Hasta Adı',
      'en': 'Patient Name',
      'es': 'Nombre del Paciente',
      'fr': 'Nom du Patient',
      'de': 'Patientenname',
      'ar': 'اسم المريض',
    },
    'test_date': {
      'tr': 'Test Tarihi',
      'en': 'Test Date',
      'es': 'Fecha de Prueba',
      'fr': 'Date du Test',
      'de': 'Testdatum',
      'ar': 'تاريخ الفحص',
    },
    'report_date': {
      'tr': 'Rapor Tarihi',
      'en': 'Report Date',
      'es': 'Fecha del Informe',
      'fr': 'Date du Rapport',
      'de': 'Berichtsdatum',
      'ar': 'تاريخ التقرير',
    },
    'test_results': {
      'tr': 'TEST SONUÇLARI',
      'en': 'TEST RESULTS',
      'es': 'RESULTADOS DE LA PRUEBA',
      'fr': 'RÉSULTATS DU TEST',
      'de': 'TESTERGEBNISSE',
      'ar': 'نتائج الفحص',
    },
    'parameter': {
      'tr': 'Parametre',
      'en': 'Parameter',
      'es': 'Parámetro',
      'fr': 'Paramètre',
      'de': 'Parameter',
      'ar': 'المعامل',
    },
    'result': {
      'tr': 'Sonuç',
      'en': 'Result',
      'es': 'Resultado',
      'fr': 'Résultat',
      'de': 'Ergebnis',
      'ar': 'النتيجة',
    },
    'reference_range': {
      'tr': 'Referans Aralığı',
      'en': 'Reference Range',
      'es': 'Rango de Referencia',
      'fr': 'Plage de Référence',
      'de': 'Referenzbereich',
      'ar': 'النطاق المرجعي',
    },
    'status': {
      'tr': 'Durum',
      'en': 'Status',
      'es': 'Estado',
      'fr': 'Statut',
      'de': 'Status',
      'ar': 'الحالة',
    },
    'normal_status': {
      'tr': 'Normal',
      'en': 'Normal',
      'es': 'Normal',
      'fr': 'Normal',
      'de': 'Normal',
      'ar': 'طبيعي',
    },
    'high_status': {
      'tr': 'Yüksek',
      'en': 'High',
      'es': 'Alto',
      'fr': 'Élevé',
      'de': 'Hoch',
      'ar': 'مرتفع',
    },
    'notes': {
      'tr': 'Notlar',
      'en': 'Notes',
      'es': 'Notas',
      'fr': 'Notes',
      'de': 'Notizen',
      'ar': 'ملاحظات',
    },
    'generated_by': {
      'tr': 'Oluşturan',
      'en': 'Generated by',
      'es': 'Generado por',
      'fr': 'Généré par',
      'de': 'Generiert von',
      'ar': 'تم إنشاؤه بواسطة',
    },
    'health_assistant': {
      'tr': 'Sağlık Asistanınız',
      'en': 'Your Health Assistant',
      'es': 'Su Asistente de Salud',
      'fr': 'Votre Assistant Santé',
      'de': 'Ihr Gesundheitsassistent',
      'ar': 'مساعدك الصحي',
    },
    'ai_analysis': {
      'tr': 'AI Analiz',
      'en': 'AI Analysis',
      'es': 'Análisis IA',
      'fr': 'Analyse IA',
      'de': 'KI-Analyse',
      'ar': 'تحليل الذكاء الاصطناعي',
    },
    'light_theme': {
      'tr': 'Açık Tema',
      'en': 'Light Theme',
      'es': 'Tema Claro',
      'fr': 'Thème Clair',
      'de': 'Helles Thema',
      'ar': 'المظهر الفاتح',
    },
    'dark_theme': {
      'tr': 'Koyu Tema',
      'en': 'Dark Theme',
      'es': 'Tema Oscuro',
      'fr': 'Thème Sombre',
      'de': 'Dunkles Thema',
      'ar': 'المظهر المظلم',
    },
    'about': {
      'tr': 'Hakkında',
      'en': 'About',
      'es': 'Acerca de',
      'fr': 'À propos',
      'de': 'Über',
      'ar': 'حول',
    },
    'logout': {
      'tr': 'Çıkış Yap',
      'en': 'Logout',
      'es': 'Cerrar Sesión',
      'fr': 'Déconnexion',
      'de': 'Abmelden',
      'ar': 'تسجيل الخروج',
    },
    'menu': {
      'tr': 'Menü',
      'en': 'Menu',
      'es': 'Menú',
      'fr': 'Menu',
      'de': 'Menü',
      'ar': 'القائمة',
    },
    'smart_health_assistant': {
      'tr': 'Akıllı Sağlık Asistanı',
      'en': 'Smart Health Assistant',
      'es': 'Asistente Inteligente de Salud',
      'fr': 'Assistant Santé Intelligent',
      'de': 'Intelligenter Gesundheitsassistent',
      'ar': 'مساعد الصحة الذكي',
    },
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
    'personal_diet_program': {
      'tr': 'Kişisel Diyet Programı',
      'en': 'Personal Diet Program',
      'es': 'Programa de Dieta Personal',
      'fr': 'Programme de Régime Personnel',
      'de': 'Persönliches Diätprogramm',
      'ar': 'برنامج النظام الغذائي الشخصي',
    },
    // Diet program i18n
    'diet_program_description': {
      'tr': 'Hemogram sonuçlarınıza göre seçilen planlar. Aşağıda günlük makro hedefleri ve örnek menüyü görebilirsiniz.',
      'en': 'Plans tailored to your hemogram results. See daily macro targets and a sample menu below.',
    },
    'diet_today_tab': {
      'tr': 'Bugün',
      'en': 'Today',
      'es': 'Hoy',
      'fr': 'Aujourd\'hui',
      'de': 'Heute',
    },
    'diet_week_tab': {
      'tr': 'Hafta',
      'en': 'Week',
      'es': 'Semana',
      'fr': 'Semaine',
      'de': 'Woche',
    },
    'weekly_plan': {
      'tr': 'Haftalık Plan',
      'en': 'Weekly Plan',
      'es': 'Plan Semanal',
      'fr': 'Plan Hebdomadaire',
      'de': 'Wochenplan',
      'ar': 'الخطة الأسبوعية',
    },
    'hemoglobin_support_diet': {
      'tr': 'Hemoglobin Destek Diyeti',
      'en': 'Hemoglobin Support Diet',
      'es': 'Dieta de Apoyo a la Hemoglobina',
      'fr': 'Régime de Soutien à l\'Hémoglobine',
      'de': 'Hämoglobin-Unterstützungsdiät',
      'ar': 'نظام غذائي لدعم الهيموجلوبين',
    },
    'diet_recommendations': {
      'tr': 'Diyet Önerileri',
      'en': 'Diet Recommendations',
      'es': 'Recomendaciones Dietéticas',
      'fr': 'Recommandations Diététiques',
      'de': 'Diätempfehlungen',
      'ar': 'التوصيات الغذائية',
    },
    'diet_recommendations_title': {
      'tr': 'Hemoglobin Desteği İçin Diyet Önerileri',
      'en': 'Diet Recommendations for Hemoglobin Support',
      'es': 'Recomendaciones Dietéticas para el Apoyo de la Hemoglobina',
      'fr': 'Recommandations Diététiques pour le Soutien de l\'Hémoglobine',
      'de': 'Diätempfehlungen zur Hämoglobin-Unterstützung',
      'ar': 'التوصيات الغذائية لدعم الهيموجلوبين',
    },
    'hemoglobin_diet_description': {
      'tr': 'Hemoglobin değerlerinizi desteklemek için demir ve B12 açısından zengin beslenme planı.',
      'en': 'A nutrition plan rich in iron and B12 to support your hemoglobin values.',
      'es': 'Un plan nutricional rico en hierro y B12 para apoyar sus valores de hemoglobina.',
      'fr': 'Un plan nutritionnel riche en fer et B12 pour soutenir vos valeurs d\'hémoglobine.',
      'de': 'Ein Ernährungsplan reich an Eisen und B12 zur Unterstützung Ihrer Hämoglobinwerte.',
      'ar': 'خطة تغذية غنية بالحديد وفيتامين ب12 لدعم قيم الهيموجلوبين.',
    },
    'hemogram_based_nutrition_plan': {
      'tr': 'Hemogram değerlerinize ve yaş grubunuza göre önerilen beslenme planı.',
      'en': 'Recommended nutrition plan based on your hemogram values and age group.',
      'es': 'Plan nutricional recomendado basado en sus valores de hemograma y grupo de edad.',
      'fr': 'Plan nutritionnel recommandé basé sur vos valeurs d\'hémogramme et votre groupe d\'âge.',
      'de': 'Empfohlener Ernährungsplan basierend auf Ihren Hämogrammwerten und Altersgruppe.',
      'ar': 'خطة التغذية الموصى بها بناءً على قيم تعداد الدم وفئتك العمرية.',
    },
    'for_you': {
      'tr': 'Sizin için uygun',
      'en': 'Suitable for you',
      'es': 'Adecuado para ti',
      'fr': 'Adapté pour vous',
      'de': 'Für Sie geeignet',
      'ar': 'مناسب لك',
    },
    'increase_consumption': {
      'tr': 'Kırmızı et, karaciğer',
      'en': 'Red meat, liver',
      'es': 'Carne roja, hígado',
      'fr': 'Viande rouge, foie',
      'de': 'Rotes Fleisch, Leber',
      'ar': 'اللحوم الحمراء، الكبد',
    },
    'iron_rich_foods_list': {
      'tr': '• Ispanak, pazı, brokoli\n• Mercimek, nohut\n• C vitamini ile birlikte tüketin',
      'en': '• Spinach, chard, broccoli\n• Lentils, chickpeas\n• Consume with vitamin C',
      'es': '• Espinacas, acelgas, brócoli\n• Lentejas, garbanzos\n• Consumir con vitamina C',
      'fr': '• Épinards, blettes, brocoli\n• Lentilles, pois chiches\n• Consommer avec vitamine C',
      'de': '• Spinat, Mangold, Brokkoli\n• Linsen, Kichererbsen\n• Mit Vitamin C konsumieren',
      'ar': '• السبانخ، السلق، البروكلي\n• العدس، الحمص\n• تناول مع فيتامين ج',
    },
    'limit_consumption': {
      'tr': 'Aşırı çay/kahve (demir emilimini azaltır)',
      'en': 'Excessive tea/coffee (reduces iron absorption)',
      'es': 'Exceso de té/café (reduce la absorción de hierro)',
      'fr': 'Excès de thé/café (réduit l\'absorption du fer)',
      'de': 'Übermäßiger Tee/Kaffee (reduziert Eisenaufnahme)',
      'ar': 'الإفراط في الشاي/القهوة (يقلل امتصاص الحديد)',
    },
    'iron_inhibiting_foods_list': {
      'tr': '• Aşırı süt ürünleri',
      'en': '• Excessive dairy products',
      'es': '• Exceso de productos lácteos',
      'fr': '• Excès de produits laitiers',
      'de': '• Übermäßige Milchprodukte',
      'ar': '• الإفراط في منتجات الألبان',
    },
    'daily_menu': {
      'tr': 'Günlük Menü',
      'en': 'Daily Menu',
      'es': 'Menú Diario',
      'fr': 'Menu Quotidien',
      'de': 'Tagesmenü',
      'ar': 'القائمة اليومية',
    },
    'sunday': {
      'tr': 'Pazar',
      'en': 'Sunday',
      'es': 'Domingo',
      'fr': 'Dimanche',
      'de': 'Sonntag',
      'ar': 'الأحد',
    },
    'monday': {
      'tr': 'Pazartesi',
      'en': 'Monday',
      'es': 'Lunes',
      'fr': 'Lundi',
      'de': 'Montag',
      'ar': 'الاثنين',
    },
    'tuesday': {
      'tr': 'Salı',
      'en': 'Tuesday',
      'es': 'Martes',
      'fr': 'Mardi',
      'de': 'Dienstag',
      'ar': 'الثلاثاء',
    },
    'wednesday': {
      'tr': 'Çarşamba',
      'en': 'Wednesday',
      'es': 'Miércoles',
      'fr': 'Mercredi',
      'de': 'Mittwoch',
      'ar': 'الأربعاء',
    },
    'thursday': {
      'tr': 'Perşembe',
      'en': 'Thursday',
      'es': 'Jueves',
      'fr': 'Jeudi',
      'de': 'Donnerstag',
      'ar': 'الخميس',
    },
    'friday': {
      'tr': 'Cuma',
      'en': 'Friday',
      'es': 'Viernes',
      'fr': 'Vendredi',
      'de': 'Freitag',
      'ar': 'الجمعة',
    },
    'saturday': {
      'tr': 'Cumartesi',
      'en': 'Saturday',
      'es': 'Sábado',
      'fr': 'Samedi',
      'de': 'Samstag',
      'ar': 'السبت',
    },
    // Sunday menus
    'breakfast_menu_sunday': {
      'tr': '• Pekmez yulaf (1 yemek kaşığı)\n• Haşlanmış yumurta\n• Taze portakal veya kivi\n• Bir avuç ceviz',
      'en': '• Molasses oat (1 tablespoon)\n• Boiled egg\n• Fresh orange or kiwi\n• A handful of walnuts',
    },
    'lunch_menu_sunday': {
      'tr': '• Ispanak yoğurt kırmızı et veya tavuk ciğeri (haftada 2x)\n• Yeşil salata + limon\n• Kinoa veya bulgur',
      'en': '• Spinach yogurt with red meat or chicken liver (2x per week)\n• Green salad + lemon\n• Quinoa or bulgur',
    },
    'snack_menu_sunday': {
      'tr': '• Kuru kayısı + kabak çekirdeği\n• Pekmez süt (küçük bardak) haftada 2-3x',
      'en': '• Dried apricots + pumpkin seeds\n• Molasses milk (small glass) 2-3x per week',
    },
    'dinner_menu_sunday': {
      'tr': '• Baklagil yemeği (mercimek/kuru fasulye)\n• Pancar veya ıspanak salatası\n• Tam tahıllı ekmek (1 dilim)',
      'en': '• Legume dish (lentils/dried beans)\n• Beet or spinach salad\n• Whole grain bread (1 slice)',
    },
    // Monday menus  
    'breakfast_menu_monday': {
      'tr': '• Çilek Muesli\n• Organik süt + kuru üzüm + ceviz\n• Taze meyve sürekli verir + yoğurt',
      'en': '• Strawberry Muesli\n• Organic milk + raisins + walnuts\n• Fresh fruit continuously provides + yogurt',
    },
    'lunch_menu_monday': {
      'tr': '• Pekmez yulaf (1 yemek kaşığı)\n• Haşlanmış yumurta\n• Taze portakal veya kivi',
      'en': '• Molasses oat (1 tablespoon)\n• Boiled egg\n• Fresh orange or kiwi',
    },
    'snack_menu_monday': {
      'tr': '• Ispanak yoğurt kırmızı et veya tavuk ciğeri (haftada 2x)',
      'en': '• Spinach yogurt with red meat or chicken liver (2x per week)',
    },
    'dinner_menu_monday': {
      'tr': '• Kuru kayısı + kabak çekirdeği\n• Pekmez süt (küçük bardak) haftada 2-3x',
      'en': '• Dried apricots + pumpkin seeds\n• Molasses milk (small glass) 2-3x per week',
    },
    // Tuesday menus
    'breakfast_menu_tuesday': {
      'tr': '• Pekmez yulaf (1 yemek kaşığı)\n• Haşlanmış yumurta\n• Taze portakal veya kivi\n• Bir avuç ceviz',
      'en': '• Molasses oat (1 tablespoon)\n• Boiled egg\n• Fresh orange or kiwi\n• A handful of walnuts',
    },
    'lunch_menu_tuesday': {
      'tr': '• Ispanak yoğurt kırmızı et veya tavuk ciğeri (haftada 2x)\n• Yeşil salata + limon\n• Kinoa veya bulgur',
      'en': '• Spinach yogurt with red meat or chicken liver (2x per week)\n• Green salad + lemon\n• Quinoa or bulgur',
    },
    'snack_menu_tuesday': {
      'tr': '• Kuru kayısı + kabak çekirdeği\n• Pekmez süt (küçük bardak) haftada 2-3x',
      'en': '• Dried apricots + pumpkin seeds\n• Molasses milk (small glass) 2-3x per week',
    },
    'dinner_menu_tuesday': {
      'tr': '• Baklagil yemeği (mercimek/kuru fasulye)\n• Pancar veya ıspanak salatası\n• Tam tahıllı ekmek (1 dilim)',
      'en': '• Legume dish (lentils/dried beans)\n• Beet or spinach salad\n• Whole grain bread (1 slice)',
    },
    // Wednesday menus
    'breakfast_menu_wednesday': {
      'tr': '• Pekmez yulaf (1 yemek kaşığı)\n• Haşlanmış yumurta\n• Taze portakal veya kivi\n• Bir avuç ceviz',
      'en': '• Molasses oat (1 tablespoon)\n• Boiled egg\n• Fresh orange or kiwi\n• A handful of walnuts',
    },
    'lunch_menu_wednesday': {
      'tr': '• Ispanak yoğurt kırmızı et veya tavuk ciğeri (haftada 2x)\n• Yeşil salata + limon\n• Kinoa veya bulgur',
      'en': '• Spinach yogurt with red meat or chicken liver (2x per week)\n• Green salad + lemon\n• Quinoa or bulgur',
    },
    'snack_menu_wednesday': {
      'tr': '• Kuru kayısı + kabak çekirdeği\n• Pekmez süt (küçük bardak) haftada 2-3x',
      'en': '• Dried apricots + pumpkin seeds\n• Molasses milk (small glass) 2-3x per week',
    },
    'dinner_menu_wednesday': {
      'tr': '• Baklagil yemeği (mercimek/kuru fasulye)\n• Pancar veya ıspanak salatası\n• Tam tahıllı ekmek (1 dilim)',
      'en': '• Legume dish (lentils/dried beans)\n• Beet or spinach salad\n• Whole grain bread (1 slice)',
    },
    // Thursday menus
    'breakfast_menu_thursday': {
      'tr': '• Pekmez yulaf (1 yemek kaşığı)\n• Haşlanmış yumurta\n• Taze portakal veya kivi\n• Bir avuç ceviz',
      'en': '• Molasses oat (1 tablespoon)\n• Boiled egg\n• Fresh orange or kiwi\n• A handful of walnuts',
    },
    'lunch_menu_thursday': {
      'tr': '• Ispanak yoğurt kırmızı et veya tavuk ciğeri (haftada 2x)\n• Yeşil salata + limon\n• Kinoa veya bulgur',
      'en': '• Spinach yogurt with red meat or chicken liver (2x per week)\n• Green salada + lemon\n• Quinoa or bulgur',
    },
    'snack_menu_thursday': {
      'tr': '• Kuru kayısı + kabak çekirdeği\n• Pekmez süt (küçük bardak) haftada 2-3x',
      'en': '• Dried apricots + pumpkin seeds\n• Molasses milk (small glass) 2-3x per week',
    },
    'dinner_menu_thursday': {
      'tr': '• Baklagil yemeği (mercimek/kuru fasulye)\n• Pancar veya ıspanak salatası\n• Tam tahıllı ekmek (1 dilim)',
      'en': '• Legume dish (lentils/dried beans)\n• Beet or spinach salad\n• Whole grain bread (1 slice)',
    },
    // Friday menus
    'breakfast_menu_friday': {
      'tr': '• Pekmez yulaf (1 yemek kaşığı)\n• Haşlanmış yumurta\n• Taze portakal veya kivi\n• Bir avuç ceviz',
      'en': '• Molasses oat (1 tablespoon)\n• Boiled egg\n• Fresh orange or kiwi\n• A handful of walnuts',
    },
    'lunch_menu_friday': {
      'tr': '• Ispanak yoğurt kırmızı et veya tavuk ciğeri (haftada 2x)\n• Yeşil salata + limon\n• Kinoa veya bulgur',
      'en': '• Spinach yogurt with red meat or chicken liver (2x per week)\n• Green salad + lemon\n• Quinoa or bulgur',
    },
    'snack_menu_friday': {
      'tr': '• Kuru kayısı + kabak çekirdeği\n• Pekmez süt (küçük bardak) haftada 2-3x',
      'en': '• Dried apricots + pumpkin seeds\n• Molasses milk (small glass) 2-3x per week',
    },
    'dinner_menu_friday': {
      'tr': '• Baklagil yemeği (mercimek/kuru fasulye)\n• Pancar veya ıspanak salatası\n• Tam tahıllı ekmek (1 dilim)',
      'en': '• Legume dish (lentils/dried beans)\n• Beet or spinach salad\n• Whole grain bread (1 slice)',
    },
    // Saturday menus
    'breakfast_menu_saturday': {
      'tr': '• Pekmez yulaf (1 yemek kaşığı)\n• Haşlanmış yumurta\n• Taze portakal veya kivi\n• Bir avuç ceviz',
      'en': '• Molasses oat (1 tablespoon)\n• Boiled egg\n• Fresh orange or kiwi\n• A handful of walnuts',
    },
    'lunch_menu_saturday': {
      'tr': '• Ispanak yoğurt kırmızı et veya tavuk ciğeri (haftada 2x)\n• Yeşil salata + limon\n• Kinoa veya bulgur',
      'en': '• Spinach yogurt with red meat or chicken liver (2x per week)\n• Green salad + lemon\n• Quinoa or bulgur',
    },
    'snack_menu_saturday': {
      'tr': '• Kuru kayısı + kabak çekirdeği\n• Pekmez süt (küçük bardak) haftada 2-3x',
      'en': '• Dried apricots + pumpkin seeds\n• Molasses milk (small glass) 2-3x per week',
    },
    'dinner_menu_saturday': {
      'tr': '• Baklagil yemeği (mercimek/kuru fasulye)\n• Pancar veya ıspanak salatası\n• Tam tahıllı ekmek (1 dilim)',
      'en': '• Legume dish (lentils/dried beans)\n• Beet or spinach salad\n• Whole grain bread (1 slice)',
    },
    // Default fallback menus
    'default_breakfast_menu': {
      'tr': '• Pekmez yulaf\n• Haşlanmış yumurta\n• Taze meyve\n• Bir avuç kuruyemiş',
      'en': '• Molasses oat\n• Boiled egg\n• Fresh fruit\n• A handful of nuts',
      'es': '• Avena con melaza\n• Huevo hervido\n• Fruta fresca\n• Un puñado de frutos secos',
      'fr': '• Avoine à la mélasse\n• Œuf bouilli\n• Fruit frais\n• Une poignée de noix',
      'de': '• Melasse Hafer\n• Gekochtes Ei\n• Frisches Obst\n• Eine Handvoll Nüsse',
      'ar': '• الشوفان بالدبس\n• بيضة مسلوقة\n• فاكهة طازجة\n• حفنة من المكسرات',
    },
    'default_lunch_menu': {
      'tr': '• Demir açısından zengin et/tavuk\n• Yeşil salata\n• Tam tahıllı pirinç/bulgur',
      'en': '• Iron-rich meat/chicken\n• Green salad\n• Whole grain rice/bulgur',
      'es': '• Carne/pollo rico en hierro\n• Ensalada verde\n• Arroz/bulgur integral',
      'fr': '• Viande/poulet riche en fer\n• Salade verte\n• Riz/boulgour complet',
      'de': '• Eisenreiches Fleisch/Hähnchen\n• Grüner Salat\n• Vollkorn Reis/Bulgur',
      'ar': '• لحم/دجاج غني بالحديد\n• سلطة خضراء\n• أرز/برغل كامل الحبة',
    },
    'default_snack_menu': {
      'tr': '• Kuru meyve ve kuruyemiş karışımı\n• C vitamini açısından zengin meyve',
      'en': '• Dried fruit and nut mix\n• Vitamin C rich fruit',
      'es': '• Mezcla de frutos secos y fruta seca\n• Fruta rica en vitamina C',
      'fr': '• Mélange de fruits secs et noix\n• Fruit riche en vitamine C',
      'de': '• Trockenobst und Nuss-Mix\n• Vitamin C reiche Frucht',
      'ar': '• خليط الفواكه المجففة والمكسرات\n• فاكهة غنية بفيتامين ج',
    },
    'default_dinner_menu': {
      'tr': '• Baklagil yemeği\n• Demir emilimini artıran salata\n• Tam tahıllı ekmek',
      'en': '• Legume dish\n• Iron absorption enhancing salad\n• Whole grain bread',
      'es': '• Plato de legumbres\n• Ensalada que mejora la absorción de hierro\n• Pan integral',
      'fr': '• Plat de légumineuses\n• Salade améliorant l\'absorption du fer\n• Pain complet',
      'de': '• Hülsenfrucht Gericht\n• Eisenaufnahme fördernder Salat\n• Vollkornbrot',
      'ar': '• طبق البقوليات\n• سلطة تعزز امتصاص الحديد\n• خبز الحبة الكاملة',
    },
    'meal_breakfast': {
      'tr': 'Kahvaltı',
      'en': 'Breakfast',
      'es': 'Desayuno',
      'fr': 'Petit-déjeuner',
      'de': 'Frühstück',
    },
    'meal_lunch': {
      'tr': 'Öğle',
      'en': 'Lunch',
      'es': 'Almuerzo',
      'fr': 'Déjeuner',
      'de': 'Mittagessen',
    },
    'meal_dinner': {
      'tr': 'Akşam',
      'en': 'Dinner',
      'es': 'Cena',
      'fr': 'Dîner',
      'de': 'Abendessen',
    },
    'meal_snack': {
      'tr': 'Ara öğün',
      'en': 'Snack',
      'es': 'Snack',
      'fr': 'Collation',
      'de': 'Snack',
    },
    'diet_weekly_progress': {
      'tr': 'Haftalık ilerleme',
      'en': 'Weekly progress',
      'es': 'Progreso semanal',
      'fr': 'Progrès hebdomadaire',
      'de': 'Wöchentlicher Fortschritt',
    },
    'diet_toggle_hint': {
      'tr': 'Öğünleri tamamladıkça işaretleyin',
      'en': 'Check meals as you complete them',
      'es': 'Marca las comidas a medida que las completes',
      'fr': 'Cochez les repas au fur et à mesure',
      'de': 'Mahlzeiten abhaken, wenn erledigt',
    },
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
    'suitable_for_age': {
      'tr': '{age_group} için uygun',
      'en': 'Suitable for {age_group}',
    },
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
    // Login prompt for Family Panel when user is not authenticated
    'family_login_required_title': {
      'tr': 'Giriş gerekli',
      'en': 'Sign in required',
      'es': 'Se requiere iniciar sesión',
      'fr': "Connexion requise",
      'de': 'Anmeldung erforderlich',
      'ar': 'يلزم تسجيل الدخول',
    },
    'family_login_required_desc': {
      'tr': 'Aile üyelerini görüntülemek ve yönetmek için oturum açın.',
      'en': 'Sign in to view and manage your family members.',
      'es': 'Inicia sesión para ver y gestionar a tus familiares.',
      'fr': 'Connectez-vous pour voir et gérer vos membres de famille.',
      'de': 'Melden Sie sich an, um Familienmitglieder zu sehen und zu verwalten.',
      'ar': 'سجّل الدخول لعرض أفراد عائلتك وإدارتهم.',
    },
    'go_to_login': {
      'tr': 'Girişe git',
      'en': 'Go to login',
      'es': 'Ir a iniciar sesión',
      'fr': 'Aller à la connexion',
      'de': 'Zum Login',
      'ar': 'الانتقال إلى تسجيل الدخول',
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
    'family_default_invite_message': {
      'tr': 'Sizi aile sağlık panelime eklemek istiyorum.',
      'en': 'I would like to add you to my family health panel.',
      'es': 'Me gustaría agregarte a mi panel de salud familiar.',
      'fr': 'Je voudrais vous ajouter à mon panneau de santé familiale.',
      'de': 'Ich möchte Sie zu meinem Familien-Gesundheitspanel hinzufügen.',
      'ar': 'أرغب في إضافتك إلى لوحة الصحة العائلية الخاصة بي.',
    },
    // Family panel search/sort/filter
    'family_search_hint': {
      'tr': 'İsim ile ara...',
      'en': 'Search by name...',
      'es': 'Buscar por nombre...',
      'fr': 'Rechercher par nom...',
      'de': 'Nach Namen suchen...',
      'ar': 'ابحث بالاسم...'
    },
    'family_filter_all': {
      'tr': 'Tümü',
      'en': 'All',
      'es': 'Todos',
      'fr': 'Tous',
      'de': 'Alle',
      'ar': 'الكل'
    },
    'family_sort_name': {
      'tr': 'İsme göre',
      'en': 'By Name',
      'es': 'Por nombre',
      'fr': 'Par nom',
      'de': 'Nach Name',
      'ar': 'حسب الاسم'
    },
    'family_sort_age': {
      'tr': 'Yaşa göre',
      'en': 'By Age',
      'es': 'Por edad',
      'fr': 'Par âge',
      'de': 'Nach Alter',
      'ar': 'حسب العمر'
    },
    'family_sort_toggle': {
      'tr': 'Sıralama yönünü değiştir',
      'en': 'Toggle sort order',
      'es': 'Cambiar orden',
      'fr': 'Inverser l’ordre',
      'de': 'Sortierreihenfolge umkehren',
      'ar': 'تبديل الترتيب'
    },
    'notifications_reminders': {
      'tr': 'Bildirimler & Hatırlatıcı',
      'en': 'Notifications & Reminders',
      'es': 'Notificaciones y Recordatorios',
      'fr': 'Notifications et Rappels',
      'de': 'Benachrichtigungen & Erinnerungen',
      'ar': 'الإشعارات والتذكيرات',
    },
    'help_support': {
      'tr': 'Yardım & Destek',
      'en': 'Help & Support',
      'es': 'Ayuda y Soporte',
      'fr': 'Aide et Support',
      'de': 'Hilfe & Support',
      'ar': 'المساعدة والدعم',
    },
    'continue_as_guest': {
      'tr': 'Misafir olarak devam et',
      'en': 'Continue as guest',
      'es': 'Continuar como invitado',
      'fr': 'Continuer en tant qu\'invité',
      'de': 'Als Gast fortfahren',
      'ar': 'متابعة كضيف',
    },
    'about_hemoai': {
      'tr': 'HemoAI Hakkında',
      'en': 'About HemoAI',
      'es': 'Acerca de HemoAI',
      'fr': 'À propos d\'HemoAI',
      'de': 'Über HemoAI',
      'ar': 'حول HemoAI',
    },
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
    'status_normal': {
      'en': 'Normal',
      'tr': 'Normal',
    },
    'status_low': {
      'en': 'Low',
      'tr': 'Düşük',
    },
    'status_high': {
      'en': 'High',
      'tr': 'Yüksek',
    },
    'status_very_high': {
      'en': 'Very High',
      'tr': 'Çok yüksek',
    },
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
    'close': {
      'tr': 'Kapat',
      'en': 'Close',
      'es': 'Cerrar',
      'fr': 'Fermer',
      'de': 'Schließen',
      'ar': 'إغلاق',
    },
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
    'mark_read': {
      'tr': 'Okundu',
      'en': 'Read',
      'es': 'Leído',
      'fr': 'Lu',
      'de': 'Gelesen',
      'ar': 'مقروء',
    },
    'mark_read_long': {
      'tr': 'Okundu Olarak İşaretle',
      'en': 'Mark as Read',
      'es': 'Marcar como Leído',
      'fr': 'Marquer comme Lu',
      'de': 'Als Gelesen Markieren',
      'ar': 'وضع علامة كمقروء',
    },
    'daily_water_tracking': {
      'tr': 'Günlük Su Takibi',
      'en': 'Daily Water Tracking',
      'es': 'Seguimiento Diario de Agua',
      'fr': 'Suivi Quotidien de l\'Eau',
      'de': 'Tägliche Wasserverfolgung',
      'ar': 'متابعة الماء اليومية',
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
    'share_favorites': {
      'tr': 'Favorileri Paylaş',
      'en': 'Share Favorites',
    },
    'share_favorites_title': {
      'tr': 'HemoAI Favori Bitkisel Desteklerim',
      'en': 'My Favorite Herbal Supports from HemoAI',
    },
    'no_favorites_yet': {
      'tr': 'Henüz favori eklenmemiş',
      'en': 'No favorites yet',
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
  };

  // Static translate method for easy access
  static String translate(String key) {
    return _instance.getString(key);
  }

  // Get localized string
  String getString(String key, {String? defaultValue}) {
    // First check localizedStrings, then hemogramStrings
    Map<String, String>? languageStrings = _localizedStrings[key];
    
    if (languageStrings == null) {
      languageStrings = _hemogramStrings[key];
    }
    
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