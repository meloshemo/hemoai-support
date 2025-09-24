import 'package:flutter/material.dart';
import 'register_screen.dart';
import 'login_form_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Beyaz arka plan
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
                  const Text(
                    'Akıllı Sağlık Asistanı',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.local_florist, color: Color(0xFFE53E3E)),
              title: const Text('Alternatif Tıp & Yöresel Yöntemler'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/alternative_medicine');
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics, color: Color(0xFFE53E3E)),
              title: const Text('Hemogram Analizi'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/analysis');
              },
            ),
            ListTile(
              leading: const Icon(Icons.restaurant_menu, color: Color(0xFFE53E3E)),
              title: const Text('Kişisel Diyet Programı'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/diet_program');
              },
            ),
            ListTile(
              leading: const Icon(Icons.family_restroom, color: Color(0xFFE53E3E)),
              title: const Text('Aile Sağlık Paneli'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/family_panel');
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications, color: Color(0xFFE53E3E)),
              title: const Text('Bildirimler & Hatırlatıcı'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/notifications');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info, color: Color(0xFFE53E3E)),
              title: const Text('Hakkında'),
              onTap: () {
                Navigator.pop(context);
                _showAboutDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.help, color: Color(0xFFE53E3E)),
              title: const Text('Yardım & Destek'),
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
                          child: const Text(
                            'Giriş Yap',
                            style: TextStyle(
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
                          child: const Text(
                            'Üye Ol',
                            style: TextStyle(
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
                    child: const Text(
                      'Misafir olarak devam et',
                      style: TextStyle(
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
        title: const Text('HemoAI Hakkında'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'HemoAI - Akıllı Hemogram Analiz Asistanı',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFFE53E3E),
                ),
              ),
              SizedBox(height: 16),
              Text('Versiyon: 1.0.0'),
              SizedBox(height: 8),
              Text('Geliştirilme Tarihi: Eylül 2025'),
              SizedBox(height: 16),
              Text(
                'Özellikler:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• AI destekli hemogram analizi'),
              Text('• Kişiselleştirilmiş diyet önerileri'),
              Text('• Aile sağlık takip sistemi'),
              Text('• Alternatif tıp rehberi'),
              Text('• Akıllı hatırlatıcı sistemi'),
              SizedBox(height: 16),
              Text(
                'HemoAI, hemogram sonuçlarınızı analiz ederek size kişiselleştirilmiş sağlık önerileri sunar. Bu uygulama tıbbi tanı koymaz, sadece bilgi amaçlıdır.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yardım & Destek'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Nasıl Kullanılır?',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFFE53E3E),
                ),
              ),
              SizedBox(height: 12),
              Text('1. Kayıt olun veya giriş yapın'),
              Text('2. Hemogram değerlerinizi girin'),
              Text('3. AI analizinizi görüntüleyin'),
              Text('4. Kişisel diyet programınızı inceleyin'),
              Text('5. Aile üyelerinizi ekleyin ve takip edin'),
              SizedBox(height: 16),
              Text(
                'Önemli Hatırlatmalar:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Bu uygulama tıbbi tanı koymaz'),
              Text('• Doktor tavsiyesi yerini tutmaz'),
              Text('• Acil durumlarda doktora başvurun'),
              Text('• Düzenli sağlık kontrollerinizi aksatmayın'),
              SizedBox(height: 16),
              Text(
                'Destek İçin:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Uygulama içi geri bildirim gönderin'),
              Text('• Sorunları bildirin'),
              Text('• Önerilerinizi paylaşın'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Geri bildiriminiz alındı, teşekkürler!'),
                  backgroundColor: Color(0xFFE53E3E),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE53E3E)),
            child: const Text('Geri Bildirim Gönder', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
