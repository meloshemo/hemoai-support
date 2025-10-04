import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/app_drawer.dart';
import '../utils/responsive_helper.dart';
import '../services/push_notification_service.dart';
import '../services/localization_service.dart';

class DashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationService>(
      builder: (context, localizationService, child) {
        return Directionality(
          textDirection: localizationService.textDirection,
          child: Scaffold(
            backgroundColor: Theme.of(context).brightness == Brightness.dark 
              ? const Color(0xFF0D1117) 
              : Colors.grey[50],
            drawer: const AppDrawer(currentRoute: '/dashboard'),
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
                  tooltip: localizationService.getString('menu'),
                ),
              ),
              title: Text(
                '${localizationService.getString('app_name')} ${localizationService.getString('dashboard')}',
                style: TextStyle(
                  fontWeight: FontWeight.bold, 
                  color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.white 
                    : Colors.white,
                ),
              ),
              backgroundColor: Theme.of(context).brightness == Brightness.dark 
                ? const Color(0xFF161B22) 
                : const Color(0xFFE53E3E),
              elevation: 0,
              actions: [
                Consumer<PushNotificationService>(
                  builder: (context, pushService, child) {
                    final unreadCount = pushService.unreadCount;
                    return IconButton(
                      icon: Badge(
                        isLabelVisible: unreadCount > 0,
                        label: Text(unreadCount.toString()),
                        child: Icon(
                          Icons.notifications, 
                          color: Theme.of(context).brightness == Brightness.dark 
                            ? const Color(0xFFF0F6FC) 
                            : Colors.white,
                        ),
                      ),
                      onPressed: () {
                        Navigator.pushNamed(context, '/notifications');
                      },
                    );
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.logout, 
                    color: Theme.of(context).brightness == Brightness.dark 
                      ? const Color(0xFFF0F6FC) 
                      : Colors.white,
                  ),
                  onPressed: () {
                    _showLogoutDialog(context);
                  },
                ),
              ],
            ),
            body: SingleChildScrollView(
              padding: ResponsiveHelper.getScreenPadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Card with Language Info
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(
                      ResponsiveHelper.responsiveValue(
                        context,
                        mobile: 16.0,
                        tablet: 20.0,
                        desktop: 24.0,
                      ),
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE53E3E), Color(0xFFFF6B6B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE53E3E).withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.favorite,
                              color: Colors.white,
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              localizationService.getString('welcome'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          localizationService.getString('health_tracking_ai'),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Language Info
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Text(
                                localizationService.currentLanguageFlag,
                                style: const TextStyle(fontSize: 20),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                localizationService.currentLanguageName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                localizationService.isRTL ? 'RTL' : 'LTR',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Main Features
                  Text(
                    localizationService.getString('main_features'),
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getFontSize(context, 20),
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFE53E3E),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: ResponsiveHelper.getDashboardGridCount(context),
                    childAspectRatio: ResponsiveHelper.responsiveValue(
                      context,
                      mobile: 1.0,
                      tablet: 1.1,
                      desktop: 1.2,
                    ),
                    crossAxisSpacing: ResponsiveHelper.getCardSpacing(context),
                    mainAxisSpacing: ResponsiveHelper.getCardSpacing(context),
                    children: [
                      _buildFeatureCard(
                        context,
                        localizationService.getString('hemogram_entry'),
                        Icons.bloodtype,
                        Colors.red[600]!,
                        '/hemogram_entry',
                      ),
                      _buildFeatureCard(
                        context,
                        localizationService.getString('analysis'),
                        Icons.analytics,
                        Colors.blue[600]!,
                        '/analysis',
                      ),
                      _buildFeatureCard(
                        context,
                        localizationService.getString('diet_program'),
                        Icons.restaurant_menu,
                        Colors.green[600]!,
                        '/diet_program',
                      ),
                      _buildFeatureCard(
                        context,
                        localizationService.getString('family_panel'),
                        Icons.family_restroom,
                        Colors.purple[600]!,
                        '/family_panel',
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Additional Features
                  Text(
                    localizationService.getString('additional_features'),
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getFontSize(context, 20),
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFE53E3E),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: ResponsiveHelper.getDashboardGridCount(context),
                    childAspectRatio: ResponsiveHelper.responsiveValue(
                      context,
                      mobile: 1.0,
                      tablet: 1.1,
                      desktop: 1.2,
                    ),
                    crossAxisSpacing: ResponsiveHelper.getCardSpacing(context),
                    mainAxisSpacing: ResponsiveHelper.getCardSpacing(context),
                    children: [
                      _buildFeatureCard(
                        context,
                        localizationService.getString('alternative_medicine'),
                        Icons.nature_people,
                        Colors.teal[600]!,
                        '/alternative_medicine',
                      ),
                      _buildFeatureCard(
                        context,
                        localizationService.getString('notifications'),
                        Icons.notifications,
                        Colors.orange[600]!,
                        '/notifications',
                      ),
                      _buildFeatureCard(
                        context,
                        localizationService.getString('profile'),
                        Icons.person,
                        Colors.indigo[600]!,
                        '/personal_info',
                      ),
                      _buildFeatureCard(
                        context,
                        localizationService.getString('export'),
                        Icons.file_download,
                        Colors.green[700]!,
                        '/export_options',
                      ),
                      _buildFeatureCard(
                        context,
                        localizationService.getString('language'),
                        Icons.language,
                        Colors.teal[600]!,
                        '/language_settings',
                      ),
                      _buildFeatureCard(
                        context,
                        localizationService.getString('advanced_analytics'),
                        Icons.analytics,
                        Colors.deepPurple[600]!,
                        '/advanced_analytics',
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    String? route, {
    bool isComingSoon = false,
  }) {
    return GestureDetector(
      onTap: () {
        if (isComingSoon) {
          final localizationService = Provider.of<LocalizationService>(context, listen: false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localizationService.getString('coming_soon')),
              backgroundColor: const Color(0xFFE53E3E),
            ),
          );
        } else if (route != null) {
          Navigator.pushNamed(context, route);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark 
            ? const Color(0xFF21262D)
            : Colors.white,
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.responsiveValue(
              context,
              mobile: 12.0,
              tablet: 16.0,
              desktop: 20.0,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.all(
                ResponsiveHelper.responsiveValue(
                  context,
                  mobile: 12.0,
                  tablet: 16.0,
                  desktop: 20.0,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(
                      ResponsiveHelper.responsiveValue(
                        context,
                        mobile: 12.0,
                        tablet: 16.0,
                        desktop: 20.0,
                      ),
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      size: ResponsiveHelper.getIconSize(context, 32),
                      color: color,
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.responsiveValue(
                    context,
                    mobile: 8.0,
                    tablet: 12.0,
                    desktop: 16.0,
                  )),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getFontSize(context, 14),
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.white 
                        : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            if (isComingSoon)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Consumer<LocalizationService>(
                    builder: (context, localizationService, child) {
                      return Text(
                        localizationService.getString('soon_badge'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final localizationService = Provider.of<LocalizationService>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(localizationService.getString('logout')),
          content: Text(localizationService.getString('logout_confirmation')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(localizationService.getString('cancel')),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacementNamed(context, '/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(localizationService.getString('logout')),
            ),
          ],
        );
      },
    );
  }
}