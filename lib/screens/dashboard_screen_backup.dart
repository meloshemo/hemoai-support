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
            tooltip: LocalizationService.translate('menu'),
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
            // Welcome card
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
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.waving_hand, 
                        color: Colors.white, 
                        size: ResponsiveHelper.getIconSize(context, 28),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        localizationService.getString('welcome_title_hemoai'),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: ResponsiveHelper.getFontSize(context, 22),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    localizationService.getString('welcome_subtitle'),
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: ResponsiveHelper.getFontSize(context, 16),
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
                  localizationService.getString('ai_analysis'),
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
                  localizationService.getString('personal_info'),
                  Icons.person,
                  Colors.indigo[600]!,
                  '/personal_info',
                ),
                _buildFeatureCard(
                  context,
                  localizationService.getString('export_options'),
                  Icons.file_download,
                  Colors.green[700]!,
                  '/export_options',
                ),
                _buildFeatureCard(
                  context,
                  localizationService.getString('language_settings'),
                  Icons.language,
                  Colors.teal[600]!,
                  '/language_settings',
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Health Goals Widget
            _buildHealthGoalsWidget(context),
          ],
        ),
      ),
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(LocalizationService.translate('coming_soon')),
              backgroundColor: const Color(0xFFE53E3E),
            ),
          );
        } else if (route != null) {
          Navigator.pushNamed(context, route);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
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
                      color: isComingSoon ? Colors.grey[600] : Colors.black87,
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
                    color: Colors.orange[600],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    LocalizationService.translate('soon_badge'),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthGoalsWidget(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LocalizationService.translate('health_goals_achievements'),
          style: TextStyle(
            fontSize: ResponsiveHelper.getFontSize(context, 20),
            fontWeight: FontWeight.bold,
            color: const Color(0xFFE53E3E),
          ),
        ),
        const SizedBox(height: 16),
        
        // Hedefler Container
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 2,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Bu Ay Hedefleri
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    LocalizationService.translate('this_month_goals'),
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getFontSize(context, 16),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _showGoalSettings(context),
                    icon: Icon(
                      Icons.edit, 
                      size: ResponsiveHelper.getIconSize(context, 16),
                    ),
                    label: Text(
                      LocalizationService.translate('edit'), 
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getFontSize(context, 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Hedef 1: Düzenli Test
              _buildGoalProgress(
                context,
                LocalizationService.translate('goal_monthly_hemogram'),
                Icons.bloodtype,
                Colors.red[600]!,
                0.7,
                LocalizationService.translate('goal_progress_monthly_test_1'),
              ),
              const SizedBox(height: 12),
              
              // Hedef 2: Sağlıklı Beslenme
              _buildGoalProgress(
                context,
                LocalizationService.translate('goal_daily_water'),
                Icons.local_drink,
                Colors.blue[600]!,
                0.85,
                LocalizationService.translate('goal_progress_water_avg_2_1l'),
              ),
              const SizedBox(height: 12),
              
              // Hedef 3: Egzersiz
              _buildGoalProgress(
                context,
                LocalizationService.translate('goal_weekly_exercise'),
                Icons.fitness_center,
                Colors.orange[600]!,
                0.4,
                LocalizationService.translate('goal_progress_exercise_3_days'),
              ),
              const SizedBox(height: 16),
              
              // Rozetler Bölümü
              const Divider(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.emoji_events, 
                    color: Colors.amber, 
                    size: ResponsiveHelper.getIconSize(context, 20),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    LocalizationService.translate('badges_earned'),
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getFontSize(context, 16),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Rozet Grid'i
              SizedBox(
                height: ResponsiveHelper.responsiveValue(
                  context,
                  mobile: 70.0,
                  tablet: 80.0,
                  desktop: 90.0,
                ),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildBadge(context, LocalizationService.translate('badge_first_test'), Icons.science, Colors.green, true),
                    const SizedBox(width: 8),
                    _buildBadge(context, LocalizationService.translate('badge_water_drinker'), Icons.local_drink, Colors.blue, true),
                    const SizedBox(width: 8),
                    _buildBadge(context, LocalizationService.translate('badge_regular_tracking'), Icons.schedule, Colors.purple, false),
                    const SizedBox(width: 8),
                    _buildBadge(context, LocalizationService.translate('badge_health_expert'), Icons.local_hospital, Colors.red, false),
                    const SizedBox(width: 8),
                    _buildBadge(context, LocalizationService.translate('badge_nutrition_guru'), Icons.restaurant, Colors.orange, false),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGoalProgress(BuildContext context, String title, IconData icon, Color color, double progress, String description) {
    return Container(
      padding: EdgeInsets.all(
        ResponsiveHelper.responsiveValue(
          context,
          mobile: 8.0,
          tablet: 12.0,
          desktop: 16.0,
        ),
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(
                  ResponsiveHelper.responsiveValue(
                    context,
                    mobile: 6.0,
                    tablet: 8.0,
                    desktop: 10.0,
                  ),
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon, 
                  color: color, 
                  size: ResponsiveHelper.getIconSize(context, 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: ResponsiveHelper.getFontSize(context, 14),
                      ),
                    ),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getFontSize(context, 12),
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: ResponsiveHelper.getFontSize(context, 14),
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(BuildContext context, String title, IconData icon, Color color, bool earned) {
    final badgeSize = ResponsiveHelper.responsiveValue(
      context,
      mobile: 40.0,
      tablet: 50.0,
      desktop: 60.0,
    );
    
    return Column(
      children: [
        Container(
          width: badgeSize,
          height: badgeSize,
          decoration: BoxDecoration(
            color: earned ? color : Colors.grey[300],
            borderRadius: BorderRadius.circular(badgeSize / 2),
            boxShadow: earned ? [
              BoxShadow(
                color: color.withOpacity(0.3),
                spreadRadius: 1,
                blurRadius: 4,
              ),
            ] : null,
          ),
          child: Icon(
            icon,
            color: earned ? Colors.white : Colors.grey[500],
            size: ResponsiveHelper.getIconSize(context, 24),
          ),
        ),
        SizedBox(height: ResponsiveHelper.responsiveValue(
          context,
          mobile: 2.0,
          tablet: 4.0,
          desktop: 6.0,
        )),
        Text(
          title,
          style: TextStyle(
            fontSize: ResponsiveHelper.getFontSize(context, 10),
            fontWeight: FontWeight.w600,
            color: earned ? Colors.black87 : Colors.grey[500],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _showGoalSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.flag, color: Color(0xFFE53E3E)),
              SizedBox(width: 8),
              Text(LocalizationService.translate('goal_settings_title')),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(LocalizationService.translate('customize_health_goals')),
                const SizedBox(height: 16),
                
                CheckboxListTile(
                  title: Text(LocalizationService.translate('goal_monthly_hemogram')),
                  subtitle: Text(LocalizationService.translate('goal_monthly_hemogram_sub')),
                  value: true,
                  onChanged: (bool? value) {},
                ),
                CheckboxListTile(
                  title: Text(LocalizationService.translate('goal_daily_water')),
                  subtitle: Text(LocalizationService.translate('goal_daily_water_sub')),
                  value: true,
                  onChanged: (bool? value) {},
                ),
                CheckboxListTile(
                  title: Text(LocalizationService.translate('goal_weekly_exercise')),
                  subtitle: Text(LocalizationService.translate('goal_weekly_exercise_sub')),
                  value: true,
                  onChanged: (bool? value) {},
                ),
                CheckboxListTile(
                  title: Text(LocalizationService.translate('goal_healthy_nutrition')),
                  subtitle: Text(LocalizationService.translate('goal_healthy_nutrition_sub')),
                  value: false,
                  onChanged: (bool? value) {},
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(LocalizationService.translate('cancel')),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(LocalizationService.translate('goals_updated')),
                    backgroundColor: const Color(0xFFE53E3E),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53E3E),
                foregroundColor: Colors.white,
              ),
              child: Text(LocalizationService.translate('save')),
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
            ),
          ),
        );
      },
    );
  }
}