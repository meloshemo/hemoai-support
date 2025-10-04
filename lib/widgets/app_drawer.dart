import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';
import '../services/localization_service.dart';
import '../utils/responsive_helper.dart';
import '../services/active_profile_service.dart';

class AppDrawer extends StatelessWidget {
  final String? currentRoute;

  const AppDrawer({super.key, this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationService>(
      builder: (context, localizationService, child) {
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;
        return Drawer(
          width: ResponsiveHelper.getDrawerWidth(context),
          child: Column(
        children: [
          // Drawer Header
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  scheme.primary,
                  theme.brightness == Brightness.dark 
                    ? Color.alphaBlend(scheme.primary.withValues(alpha: 0.4), scheme.surface)
                    : scheme.primary.withValues(alpha: 0.8),
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
                    color: scheme.onPrimary,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: theme.shadowColor.withValues(alpha: 0.1),
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
                        final scheme = Theme.of(context).colorScheme;
                        return Icon(
                          Icons.local_hospital,
                          color: scheme.error,
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
                    Text(
                      'HemoAI',
                      style: TextStyle(
                        color: scheme.onPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      LocalizationService.translate('health_assistant'),
                      style: TextStyle(
                        color: scheme.onPrimary.withValues(alpha: 0.7),
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
                _buildDrawerItem(
                  context,
                  icon: Icons.view_list,
                  title: LocalizationService.translate('full_results_title'),
                  route: '/full_results',
                  isSelected: currentRoute == '/full_results',
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
                _buildDrawerItem(
                  context,
                  icon: Icons.language,
                  title: LocalizationService.translate('language_settings'),
                  route: '/language_settings',
                  isSelected: currentRoute == '/language_settings',
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
                  icon: Icons.login,
                  title: LocalizationService.translate('login'),
                  route: '/login',
                  isSelected: currentRoute == '/login',
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
                  icon: Icons.new_releases,
                  title: LocalizationService.translate('enhanced_notifications'),
                  route: '/enhanced_notifications',
                  isSelected: currentRoute == '/enhanced_notifications',
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.query_stats,
                  title: LocalizationService.translate('stats_overview_title'),
                  route: '/stats',
                  isSelected: currentRoute == '/stats',
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
                _buildDrawerItem(
                  context,
                  icon: Icons.find_in_page,
                  title: LocalizationService.translate('ocr_reader'),
                  route: '/ocr_reader',
                  isSelected: currentRoute == '/ocr_reader',
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.file_download,
                  title: LocalizationService.translate('export_options'),
                  route: '/export_options',
                  isSelected: currentRoute == '/export_options',
                ),
                const Divider(),
                _buildDrawerItem(
                  context,
                  icon: Icons.settings,
                  title: LocalizationService.translate('settings'),
                  route: '/settings',
                  isSelected: currentRoute == '/settings',
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.speed,
                  title: LocalizationService.translate('performance_settings'),
                  route: '/performance',
                  isSelected: currentRoute == '/performance',
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.info_outline,
                  title: LocalizationService.translate('about'),
                  route: '/about',
                  isSelected: currentRoute == '/about',
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
                // Active Profile Indicator / Switcher
                Consumer<ActiveProfileService>(
                  builder: (context, profile, _) {
                    final title = LocalizationService.translate('switch_profile');
                    final subtitle = profile.displayName;
                    return ListTile(
                      leading: Icon(Icons.switch_account, color: scheme.primary),
                      title: Text(title),
                      subtitle: Text(subtitle),
                      onTap: () async {
                        // Minimal switcher: prompt for a numeric user id
                        final controller = TextEditingController();
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: Text(LocalizationService.translate('select_profile')),
                              content: TextField(
                                controller: controller,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: LocalizationService.translate('user_id'),
                                  hintText: '1',
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: Text(LocalizationService.translate('cancel')),
                                ),
                                ElevatedButton(
                                  onPressed: () async {
                                    final id = int.tryParse(controller.text);
                                    if (id != null) {
                                      await profile.setActiveUser(id);
                                      // ignore: use_build_context_synchronously
                                      Navigator.of(context).pop();
                                    }
                                  },
                                  child: Text(LocalizationService.translate('ok')),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    );
                  },
                ),
                
                // Dark Mode Toggle
                Consumer<ThemeService>(
                  builder: (context, themeService, child) {
                    return ListTile(
                      leading: Icon(
                        themeService.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                        color: scheme.primary,
                      ),
                      title: Text(themeService.isDarkMode ? LocalizationService.translate('light_theme') : LocalizationService.translate('dark_theme')),
                      trailing: Switch(
                        value: themeService.isDarkMode,
                        onChanged: (value) {
                          themeService.toggleTheme();
                        },
                        activeThumbColor: scheme.primary,
                        activeTrackColor: scheme.primary.withValues(alpha: 0.3),
                      ),
                      onTap: () {
                        themeService.toggleTheme();
                      },
                    );
                  },
                ),
                
                ListTile(
                  leading: Icon(Icons.info_outline, color: scheme.primary),
                  title: Text(LocalizationService.translate('about')),
                  onTap: () {
                    Navigator.pop(context);
                    _showAboutDialog(context);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.logout, color: scheme.error),
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
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
  color: isSelected ? scheme.primary.withValues(alpha: 0.12) : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected 
            ? scheme.primary 
            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected 
              ? scheme.primary 
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.87),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        onTap: () {
          Navigator.pop(context); // Close drawer
          if (!isSelected) {
            Navigator.pushNamed(context, route);
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
        final scheme = Theme.of(context).colorScheme;
        return AlertDialog(
          title: Consumer<LocalizationService>(
            builder: (context, localizationService, _) => Row(
              children: [
                Icon(Icons.local_hospital, color: scheme.primary),
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
                      style: TextStyle(color: scheme.tertiary, fontWeight: FontWeight.w600),
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
        final scheme = Theme.of(context).colorScheme;
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
                backgroundColor: scheme.error,
                foregroundColor: scheme.onError,
              ),
              child: Text(LocalizationService.translate('logout')),
            ),
          ],
        );
      },
    );
  }
}