import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';
import '../services/localization_service.dart';

class GuestScreen extends StatelessWidget {
  const GuestScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark 
        ? const Color(0xFF0D1117) 
        : Colors.white,
      drawer: const AppDrawer(currentRoute: '/guest'),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(
              Icons.menu,
              color: Theme.of(context).brightness == Brightness.dark 
                ? const Color(0xFFF0F6FC) 
                : const Color(0xFFE53E3E),
              size: 24,
            ),
            onPressed: () => Scaffold.of(context).openDrawer(),
            tooltip: LocalizationService.translate('menu'),
          ),
        ),
        title: Text(LocalizationService.translate('guest_mode')),
        backgroundColor: Theme.of(context).brightness == Brightness.dark 
          ? const Color(0xFF161B22) 
          : Colors.white,
        foregroundColor: Theme.of(context).brightness == Brightness.dark 
          ? Colors.white 
          : const Color(0xFFE53E3E),
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
                Text(
                  "HemoAI ${LocalizationService.translate('guest_mode')}",
                  style: const TextStyle(
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
                  child: Text(
                    LocalizationService.translate('guest_description'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                ),
                
                // Butonlar
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.person),
                    label: Text(LocalizationService.translate('enter_personal_info_short'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
                    label: Text(LocalizationService.translate('enter_hemogram_result'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
                    label: Text(LocalizationService.translate('get_ai_analysis_advice'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
                const SizedBox(height: 24),
                
                // Diğer Özellikler Başlığı
                Text(
                  LocalizationService.translate('additional_features'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE53E3E),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Ek Özellikler Grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  childAspectRatio: 1.1,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: [
                    _buildFeatureCard(
                      context,
                      LocalizationService.translate('diet_program'),
                      Icons.restaurant_menu,
                      Colors.green[600]!,
                      '/diet_program',
                    ),
                    _buildFeatureCard(
                      context,
                      LocalizationService.translate('family_panel'),
                      Icons.family_restroom,
                      Colors.purple[600]!,
                      '/family_panel',
                    ),
                    _buildFeatureCard(
                      context,
                      LocalizationService.translate('alternative_medicine'),
                      Icons.nature_people,
                      Colors.teal[600]!,
                      '/alternative_medicine',
                    ),
                    _buildFeatureCard(
                      context,
                      LocalizationService.translate('notifications'),
                      Icons.notifications,
                      Colors.orange[600]!,
                      '/notifications',
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Ana Panel Butonu
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.dashboard),
                    label: Text(LocalizationService.translate('dashboard'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    onPressed: () {
                      Navigator.pushNamed(context, '/dashboard');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    String route,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, route);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
