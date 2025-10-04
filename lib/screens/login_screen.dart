import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'register_screen.dart';
import 'login_form_screen.dart';
import '../services/localization_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark 
        ? const Color(0xFF0D1117) 
        : Colors.white,
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(
              Icons.menu,
              color: Theme.of(context).brightness == Brightness.dark 
                ? const Color(0xFFF0F6FC) 
                : Colors.white,
              size: 24,
            ),
            onPressed: () => Scaffold.of(context).openDrawer(),
            tooltip: LocalizationService.translate('menu'),
          ),
        ),
        title: const Text(
          'HEMOAI',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Theme.of(context).brightness == Brightness.dark 
          ? const Color(0xFF161B22) 
          : const Color(0xFFE53E3E),
        elevation: 0,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFE53E3E), Color(0xFFFF6B6B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: Image.asset(
                        'assets/hemoai pic 1.O.jpg',
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.bloodtype, color: Color(0xFFE53E3E), size: 30);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'HemoAI',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    LocalizationService.translate('smart_health_assistant'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.local_florist, color: Color(0xFFE53E3E)),
              title: Text(LocalizationService.translate('alternative_medicine_methods')),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/alternative_medicine');
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics, color: Color(0xFFE53E3E)),
              title: Text(LocalizationService.translate('hemogram_analysis')),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/analysis');
              },
            ),
            ListTile(
              leading: const Icon(Icons.restaurant_menu, color: Color(0xFFE53E3E)),
              title: Text(LocalizationService.translate('personal_diet_program')),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/diet_program');
              },
            ),
            ListTile(
              leading: const Icon(Icons.family_restroom, color: Color(0xFFE53E3E)),
              title: Text(LocalizationService.translate('family_health_panel')),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/family_panel');
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications, color: Color(0xFFE53E3E)),
              title: Text(LocalizationService.translate('notifications_reminders')),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/notifications');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info, color: Color(0xFFE53E3E)),
              title: Text(LocalizationService.translate('about')),
              onTap: () {
                Navigator.pop(context);
                _showAboutDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.help, color: Color(0xFFE53E3E)),
              title: Text(LocalizationService.translate('help_support')),
              onTap: () {
                Navigator.pop(context);
                _showHelpDialog(context);
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                // Logo - Daha büyük
                Container(
                  margin: const EdgeInsets.only(bottom: 48),
                  child: Image.asset(
                    'assets/hemoai pic 1.O.jpg',
                    width: 180,
                    height: 180,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(90),
                          border: Border.all(color: const Color(0xFFE53E3E), width: 3),
                        ),
                        child: const Icon(
                          Icons.local_hospital,
                          size: 80,
                          color: Color(0xFFE53E3E),
                        ),
                      );
                    },
                  ),
                ),
                // Ana Butonlar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    children: [
                      // Giriş Yap Butonu
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginFormScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE53E3E), // Kırmızı
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 3,
                          ),
                          child: Text(
                            LocalizationService.translate('login'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Üye Ol Butonu
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const RegisterScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFFE53E3E),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: Color(0xFFE53E3E), width: 2),
                            ),
                            elevation: 1,
                          ),
                          child: Text(
                            LocalizationService.translate('register'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                // Misafir Girişi
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/guest'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFE53E3E),
                    ),
                    child: Text(
                      LocalizationService.translate('continue_as_guest'),
                      style: const TextStyle(
                        fontSize: 16,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Consumer<LocalizationService>(
          builder: (context, localization, child) => Text(localization.getString('about_hemoai')),
        ),
        content: Consumer<LocalizationService>(
          builder: (context, localization, child) => SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  localization.getString('app_description'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFFE53E3E),
                  ),
                ),
                const SizedBox(height: 16),
                Text('${localization.getString('version')}: 1.0.0'),
                const SizedBox(height: 8),
                Text('${localization.getString('development_date')}: ${localization.getString('september_2025')}'),
                const SizedBox(height: 16),
                Text(
                  localization.getString('features'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('• ${localization.getString('ai_powered_hemogram_analysis')}'),
                Text('• ${localization.getString('personalized_diet_recommendations')}'),
                Text('• ${localization.getString('family_health_tracking_system')}'),
                Text('• ${localization.getString('alternative_medicine_guide')}'),
                Text('• ${localization.getString('smart_reminder_system')}'),
                const SizedBox(height: 16),
                Text(
                  localization.getString('app_disclaimer'),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
        actions: [
          Consumer<LocalizationService>(
            builder: (context, localization, child) => TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(localization.getString('close')),
            ),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Consumer<LocalizationService>(
        builder: (context, localizationService, child) => AlertDialog(
          title: Text(localizationService.getString('help_support')),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  localizationService.getString('how_to_use'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFFE53E3E),
                  ),
                ),
                const SizedBox(height: 12),
                Text(localizationService.getString('step_1_register')),
                Text(localizationService.getString('step_2_enter_values')),
                Text(localizationService.getString('step_3_view_analysis')),
                Text(localizationService.getString('step_4_diet_program')),
                Text(localizationService.getString('step_5_family_tracking')),
                const SizedBox(height: 16),
                Text(
                  localizationService.getString('important_reminders'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(localizationService.getString('not_medical_diagnosis')),
                Text(localizationService.getString('not_doctor_advice')),
                Text(localizationService.getString('emergency_see_doctor')),
                Text(localizationService.getString('regular_checkups')),
                const SizedBox(height: 16),
                Text(
                  localizationService.getString('for_support'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(localizationService.getString('send_feedback')),
                Text(localizationService.getString('report_issues')),
                Text(localizationService.getString('share_suggestions')),
            ],
          ),
        ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(localizationService.getString('close')),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(localizationService.getString('feedback_received')),
                    backgroundColor: const Color(0xFFE53E3E),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE53E3E)),
              child: Text(localizationService.getString('send_feedback_button'), style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
