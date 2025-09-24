import 'package:flutter/material.dart';

class GuestScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Misafir Modu'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFFE53E3E),
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  margin: const EdgeInsets.only(bottom: 32),
                  child: Image.asset(
                    'assets/hemoai pic 1.O.jpg',
                    width: 120,
                    height: 120,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(60),
                          border: Border.all(color: const Color(0xFFE53E3E), width: 2),
                        ),
                        child: const Icon(
                          Icons.local_hospital,
                          size: 50,
                          color: Color(0xFFE53E3E),
                        ),
                      );
                    },
                  ),
                ),
                
                // Başlık
                const Text(
                  'HemoAI Misafir Modu',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE53E3E),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                
                // Açıklama
                Container(
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.only(bottom: 32),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: const Text(
                    'Kayıt olmadan uygulamanın temel özelliklerini deneyimleyebilirsiniz.\n\nKişisel bilgilerinizi girip hemogram sonuçlarınızı analiz ettirebilir, AI destekli tavsiye ve diyet programı alabilirsiniz.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                ),
                
                // Butonlar
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.person),
                    label: const Text('Kişisel Bilgi Gir', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    onPressed: () {
                      Navigator.pushNamed(context, '/personal_info');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE53E3E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.bloodtype),
                    label: const Text('Hemogram Sonucu Gir', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    onPressed: () {
                      Navigator.pushNamed(context, '/hemogram_entry');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFFE53E3E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFFE53E3E), width: 2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.analytics),
                    label: const Text('AI Analiz ve Tavsiye Al', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    onPressed: () {
                      Navigator.pushNamed(context, '/analysis');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFFE53E3E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFFE53E3E), width: 2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
