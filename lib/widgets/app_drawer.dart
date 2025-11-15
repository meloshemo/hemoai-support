import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';
import '../services/localization_service.dart';
import '../utils/responsive_helper.dart';
import '../screens/family_panel_screen.dart';
import '../screens/reminder_list_screen.dart';
import '../screens/add_reminder_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/hemogram_entry_screen.dart';
import '../screens/analysis_screen.dart';
import '../screens/diet_program_screen.dart';
import '../screens/alternative_medicine_screen.dart';
import '../screens/personal_info_screen_new.dart' as personal_info;
import '../screens/enhanced_notification_screen.dart';
import '../screens/settings_screen.dart';

class AppDrawer extends StatelessWidget {
  final String? currentRoute;

  const AppDrawer({super.key, this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationService>(
      builder: (context, localizationService, child) {
        return Drawer(
          width: ResponsiveHelper.getDrawerWidth(context),
          child: Column(
        children: [
          // Drawer Header
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFE53E3E), 
                  Theme.of(context).brightness == Brightness.dark 
                    ? const Color(0xFFD32F2F)
                    : const Color(0xFFFF6B6B)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Image.asset(
                      'assets/hemoai pic 1.O.jpg',
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.local_hospital,
                          color: Color(0xFFE53E3E),
                          size: 30,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'HemoAI',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      LocalizationService.translate('health_assistant'),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Menu Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  context,
                  icon: Icons.dashboard,
                  title: LocalizationService.translate('dashboard'),
                  route: '/dashboard',
                  isSelected: currentRoute == '/dashboard',
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.bloodtype,
                  title: LocalizationService.translate('hemogram_entry'),
                  route: '/hemogram_entry',
                  isSelected: currentRoute == '/hemogram_entry',
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.analytics,
                  title: LocalizationService.translate('ai_analysis'),
                  route: '/analysis',
                  isSelected: currentRoute == '/analysis',
                ),
                const Divider(),
                _buildDrawerItem(
                  context,
                  icon: Icons.restaurant_menu,
                  title: LocalizationService.translate('diet_program'),
                  route: '/diet_program',
                  isSelected: currentRoute == '/diet_program',
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.family_restroom,
                  title: LocalizationService.translate('family_panel'),
                  route: '/family_panel',
                  isSelected: currentRoute == '/family_panel',
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.nature_people,
                  title: LocalizationService.translate('alternative_medicine'),
                  route: '/alternative_medicine',
                  isSelected: currentRoute == '/alternative_medicine',
                ),
                const Divider(),
                _buildDrawerItem(
                  context,
                  icon: Icons.person,
                  title: LocalizationService.translate('personal_info'),
                  route: '/personal_info',
                  isSelected: currentRoute == '/personal_info',
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.notifications,
                  title: LocalizationService.translate('notifications'),
                  route: '/notifications',
                  isSelected: currentRoute == '/notifications',
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.settings,
                  title: LocalizationService.translate('settings'),
                  route: '/settings',
                  isSelected: currentRoute == '/settings',
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.alarm,
                  title: LocalizationService.translate('reminders'),
                  route: '/reminders',
                  isSelected: currentRoute == '/reminders',
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.alarm_add,
                  title: LocalizationService.translate('add_reminder'),
                  route: '/add_reminder',
                  isSelected: currentRoute == '/add_reminder',
                ),
              ],
            ),
          ),
          
          // Footer
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Divider(),
                
                // Dark Mode Toggle
                Consumer<ThemeService>(
                  builder: (context, themeService, child) {
                    return ListTile(
                      leading: Icon(
                        themeService.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                        color: const Color(0xFFE53E3E),
                      ),
                      title: Text(themeService.isDarkMode ? LocalizationService.translate('light_theme') : LocalizationService.translate('dark_theme')),
                      trailing: Switch(
                        value: themeService.isDarkMode,
                        onChanged: (value) {
                          themeService.toggleTheme();
                        },
                        thumbColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return const Color(0xFFE53E3E);
                          }
                          return Theme.of(context).colorScheme.outlineVariant;
                        }),
                        trackColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return const Color(0xFFE53E3E).withValues(alpha: 0.5);
                          }
                          return Theme.of(context).colorScheme.outlineVariant;
                        }),
                      ),
                      onTap: () {
                        themeService.toggleTheme();
                      },
                    );
                  },
                ),
                
                ListTile(
                  leading: const Icon(Icons.info_outline, color: Color(0xFFE53E3E)),
                  title: Text(LocalizationService.translate('about')),
                  onTap: () {
                    Navigator.pop(context);
                    _showAboutDialog(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: Text(LocalizationService.translate('logout')),
                  onTap: () {
                    Navigator.pop(context);
                    _showLogoutDialog(context);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
        );
      },
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
    bool isSelected = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
  color: isSelected ? const Color(0xFFE53E3E).withValues(alpha: 0.1) : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected 
            ? const Color(0xFFE53E3E) 
            : (Theme.of(context).brightness == Brightness.dark 
                ? Colors.grey[300] 
                : Colors.grey[600]),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected 
              ? const Color(0xFFE53E3E) 
              : (Theme.of(context).brightness == Brightness.dark 
                  ? Colors.white.withValues(alpha: 0.87) 
                  : Colors.black.withValues(alpha: 0.87)),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        onTap: () {
          // Close the drawer first
          Navigator.of(context).pop();
          // Navigate by pushing concrete pages directly to avoid named-route generator issues
          if (!isSelected) {
            Widget? target;
            switch (route) {
              case '/dashboard':
                target = DashboardScreen();
                break;
              case '/hemogram_entry':
                target = HemogramEntryScreen();
                break;
              case '/analysis':
                target = AnalysisScreen(hemogramValues: const {});
                break;
              case '/diet_program':
                target = const DietProgramScreen();
                break;
              case '/family_panel':
                target = const FamilyPanelScreen();
                break;
              case '/alternative_medicine':
                target = const AlternativeMedicineScreen();
                break;
              case '/personal_info':
                target = const personal_info.PersonalInfoScreen();
                break;
              case '/notifications':
                target = const EnhancedNotificationScreen();
                break;
              case '/settings':
                target = const SettingsScreen();
                break;
              case '/reminders':
                target = const ReminderListScreen();
                break;
              case '/add_reminder':
                target = const AddReminderScreen();
                break;
            }
            if (target != null) {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => target!));
            }
          }
        },
        selected: isSelected,
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Consumer<LocalizationService>(
            builder: (context, localizationService, _) => Row(
              children: [
                Icon(Icons.local_hospital, color: const Color(0xFFE53E3E)),
                const SizedBox(width: 8),
                Text(localizationService.getString('about_hemoai_title')),
              ],
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Consumer<LocalizationService>(
                builder: (context, localizationService, _) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizationService.getString('about_hemoai_full'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text('${localizationService.getString('version_label')} 1.0.0'),
                    const SizedBox(height: 8),
                    Text(localizationService.getString('developer_team_label')),
                    const SizedBox(height: 8),
                    Text(localizationService.getString('about_hemoai_description')),
                    const SizedBox(height: 12),
                    Text(
                      localizationService.getString('medical_disclaimer_short'),
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            Consumer<LocalizationService>(
              builder: (context, localizationService, _) => TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(localizationService.getString('ok')),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(LocalizationService.translate('logout')),
          content: Text(LocalizationService.translate('logout_confirmation')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(LocalizationService.translate('cancel')),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(LocalizationService.translate('logout')),
            ),
          ],
        );
      },
    );
  }
}