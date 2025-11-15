import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/app_drawer.dart';
import '../widgets/unified_app_bar.dart';
import '../utils/responsive_helper.dart';
import '../services/push_notification_service.dart';
import '../services/localization_service.dart';
import '../services/daily_advice_service.dart';
import '../services/water_service.dart';
import '../services/notification_service.dart' as inapp;
import '../services/analysis_service.dart';
import '../services/database_helper.dart';
import '../services/preferences_service.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

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
            appBar: UnifiedAppBar(
              title:
                  '${localizationService.getString('app_name')} ${localizationService.getString('dashboard')}',
              currentRoute: '/dashboard',
              actions: [
                // Settings shortcut
                IconButton(
                  tooltip: localizationService.getString('settings'),
                  icon: Icon(
                    Icons.settings,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFFF0F6FC)
                        : Colors.white,
                  ),
                  onPressed: () => Navigator.pushNamed(context, '/settings'),
                ),
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
                  const _DashboardHero(),
                  const SizedBox(height: 24),

                  // Daily Advice Card
                  _DailyAdviceCard(),

                  const SizedBox(height: 16),

                  // Water Progress Card
                  _WaterProgressCard(),

                  const SizedBox(height: 24),

                  // Pillbox (Medications & Vitamins)
                  _PillboxCard(),

                  const SizedBox(height: 16),

                  // Upcoming Tests
                  _UpcomingTestsCard(),

                  const SizedBox(height: 16),

                  // Last Hemogram Summary + Trend sparkline
                  _HemogramSummaryCard(),

                  // Main Features
                  Text(
                    localizationService.getString('main_features'),
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getFontSize(context, 20),
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount:
                        ResponsiveHelper.getDashboardGridCount(context),
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
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount:
                        ResponsiveHelper.getDashboardGridCount(context),
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
                        localizationService.getString('settings'),
                        Icons.settings,
                        Colors.grey[700]!,
                        '/settings',
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
          final localizationService =
              Provider.of<LocalizationService>(context, listen: false);
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
              color: Colors.grey.withValues(alpha: 0.1),
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
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      size: ResponsiveHelper.getIconSize(context, 32),
                      color: color,
                    ),
                  ),
                  SizedBox(
                      height: ResponsiveHelper.responsiveValue(
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
    final localizationService =
        Provider.of<LocalizationService>(context, listen: false);

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

class _DashboardHero extends StatelessWidget {
  const _DashboardHero();

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LocalizationService>(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return FutureBuilder<Map<String, dynamic>?>(
      future: PreferencesService.getInstance()
          .then((prefs) => prefs.getUserInfoAsync()),
      builder: (context, snapshot) {
        final data = snapshot.data ?? const {};
        final rawName =
            (data['display_name'] ?? data['full_name'] ?? data['name'] ?? '')
                .toString()
                .trim();
        final firstName = rawName.isEmpty
            ? loc.getString('dashboard_generic_user')
            : rawName.split(' ').first;
        final greeting =
            loc.getStringWithParams('dashboard_greeting', {'name': firstName});
        final dateLabel = loc.formatDate(DateTime.now());

        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveHelper.responsiveValue(context,
                mobile: 20.0, tablet: 28.0, desktop: 32.0),
            vertical: ResponsiveHelper.responsiveValue(context,
                mobile: 20.0, tablet: 26.0, desktop: 30.0),
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                scheme.primaryContainer.withValues(
                    alpha: theme.brightness == Brightness.dark ? 0.55 : 0.8),
                scheme.secondaryContainer.withValues(
                    alpha: theme.brightness == Brightness.dark ? 0.55 : 0.75),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: scheme.primary.withValues(alpha: 0.15)),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withValues(alpha: 0.16),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: TextStyle(
                  fontSize: ResponsiveHelper.responsiveValue(context,
                      mobile: 22.0, tablet: 26.0, desktop: 28.0),
                  fontWeight: FontWeight.w800,
                  color: scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${loc.getString('dashboard_tagline')} â€¢ $dateLabel',
                style: TextStyle(
                  color: scheme.onPrimaryContainer.withValues(alpha: 0.78),
                  fontSize: ResponsiveHelper.responsiveValue(context,
                      mobile: 14.0, tablet: 15.0, desktop: 16.0),
                ),
              ),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 640;
                  final spacing = isNarrow ? 14.0 : 18.0;

                  final unreadChip = Consumer<PushNotificationService>(
                    builder: (context, push, _) {
                      final unread = push.unreadCount;
                      final helper = unread == 0
                          ? loc.getString('dashboard_stat_unread_clear')
                          : loc.getString('dashboard_stat_unread_action');
                      return _HeroStatChip(
                        color: scheme.primary,
                        icon: Icons.notifications_active,
                        label: loc.getString('dashboard_stat_unread'),
                        value: unread.toString(),
                        helper: helper,
                      );
                    },
                  );

                  final upcomingChip = Consumer<inapp.NotificationService>(
                    builder: (context, ns, _) {
                      DateTime? nextTestDate;
                      String? nextTestTitle;
                      final upcoming = ns.upcomingNotifications
                          .where((n) => n.type == inapp.NotificationType.test)
                          .toList()
                        ..sort((a, b) =>
                            a.scheduledTime.compareTo(b.scheduledTime));
                      if (upcoming.isNotEmpty) {
                        final first = upcoming.first;
                        nextTestDate = first.scheduledTime;
                        nextTestTitle = first.title;
                      }
                      final helper = nextTestDate == null
                          ? loc.getString('dashboard_stat_no_tests')
                          : '${loc.formatDate(nextTestDate)} â€¢ ${loc.formatTime(nextTestDate)}';
                      return _HeroStatChip(
                        color: scheme.secondary,
                        icon: Icons.science_outlined,
                        label: loc.getString('dashboard_stat_upcoming'),
                        value: nextTestTitle ??
                            loc.getString('dashboard_stat_ready'),
                        helper: helper,
                        isValueDense: nextTestTitle == null,
                      );
                    },
                  );

                  final hydrationChip = Consumer<WaterService>(
                    builder: (context, water, _) {
                      final goal = water.goal;
                      final today = water.todayCount;
                      final percent = goal <= 0
                          ? 0
                          : (today / goal * 100).clamp(0, 100).round();
                      final helper = goal <= 0
                          ? loc.getString('dashboard_stat_set_goal')
                          : loc
                              .getString('dashboard_stat_goal')
                              .replaceFirst('{goal}', goal.toString());
                      return _HeroStatChip(
                        color: scheme.tertiary,
                        icon: Icons.water_drop,
                        label: loc.getString('dashboard_stat_hydration'),
                        value: '$percent%',
                        helper: helper,
                      );
                    },
                  );

                  if (isNarrow) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        unreadChip,
                        SizedBox(height: spacing),
                        upcomingChip,
                        SizedBox(height: spacing),
                        hydrationChip,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: unreadChip),
                      SizedBox(width: spacing),
                      Expanded(child: upcomingChip),
                      SizedBox(width: spacing),
                      Expanded(child: hydrationChip),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeroStatChip extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final String value;
  final String helper;
  final bool isValueDense;

  const _HeroStatChip({
    required this.color,
    required this.icon,
    required this.label,
    required this.value,
    required this.helper,
    this.isValueDense = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final background = color.withValues(
        alpha: theme.brightness == Brightness.dark ? 0.28 : 0.16);
    final foreground =
        theme.brightness == Brightness.dark ? scheme.onSurface : Colors.black87;
    final surface = theme.brightness == Brightness.dark
        ? scheme.surface.withValues(alpha: 0.75)
        : scheme.surfaceContainerHighest.withValues(alpha: 0.9);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              color: foreground.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
              fontSize: 13,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: foreground,
              fontWeight: FontWeight.w800,
              fontSize: isValueDense ? 18 : 22,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            helper,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: foreground.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyAdviceCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LocalizationService>(context);
    final cs = Theme.of(context).colorScheme;

    return FutureBuilder<Map<String, dynamic>?>(
      future: _getPersonalizedAdvice(context),
      builder: (context, snapshot) {
        final advice = snapshot.data;
        if (advice == null || advice.isEmpty) {
          final fallback = DailyAdviceService().getTodayQuoteText(loc);
          if (fallback.isEmpty) return const SizedBox.shrink();
          return _buildAdviceCard(context, loc, cs, Icons.lightbulb,
              loc.getString('daily_advice_title'), fallback, null);
        }

        final icon = advice['icon'] as IconData? ?? Icons.psychology;
        final title = advice['title'] as String;
        final message = advice['message'] as String;
        final action = advice['action'] as String?;

        return _buildAdviceCard(context, loc, cs, icon, title, message, action);
      },
    );
  }

  Future<Map<String, dynamic>?> _getPersonalizedAdvice(
      BuildContext context) async {
    try {
      final loc = LocalizationService();
      final prefs = await PreferencesService.getInstance();
      final userId = prefs.getCurrentUserId();
      if (userId == null) return null;

      Map<String, double>? latestValues = prefs.getLastHemogramValues();
      if (latestValues == null || latestValues.isEmpty) {
        latestValues = await prefs.loadActiveHemogramValues();
      }
      if (latestValues == null || latestValues.isEmpty) return null;

      final analysisService = AnalysisService();
      final result = await analysisService.analyze(
        userId: userId,
        currentValues: latestValues,
      );

      // Generate AI-powered personalized advice based on analysis
      final topFlag = result.flags.isNotEmpty ? result.flags.first : null;
      ParamTrend? topTrend;
      try {
        topTrend = result.trends
            .firstWhere((t) => t.direction != TrendDirection.stable);
      } catch (_) {
        if (result.trends.isNotEmpty) topTrend = result.trends.first;
      }

      // Priority-based advice
      if (result.riskScore > 60) {
        return {
          'icon': Icons.warning,
          'title': loc.getString('ai_high_risk_advice'),
          'message':
              '${result.summary}. ${result.recommendations.isNotEmpty ? result.recommendations.first : loc.getString('recommendation_follow_up_doctor')}',
          'action': loc.getString('view_full_analysis'),
        };
      } else if (topFlag != null) {
        final key = topFlag.key;
        final dir = topFlag.direction;
        IconData iconKey = Icons.info;
        String adviceKey = '';

        if (key == 'hemoglobin' && dir == 'low') {
          iconKey = Icons.bloodtype;
          adviceKey = loc.getString('ai_low_hemoglobin_tip');
        } else if (key == 'glucose' && dir == 'high') {
          iconKey = Icons.monitor_heart;
          adviceKey = loc.getString('ai_high_glucose_tip');
        } else if (key == 'vitamin_d3' && dir == 'low') {
          iconKey = Icons.wb_sunny;
          adviceKey = loc.getString('ai_low_vitd_tip');
        }

        return {
          'icon': iconKey,
          'title': loc.getString('ai_targeted_advice'),
          'message': adviceKey.isNotEmpty
              ? adviceKey
              : (result.recommendations.isNotEmpty
                  ? result.recommendations.first
                  : ''),
          'action': loc.getString('learn_more'),
        };
      } else if (topTrend != null &&
          (topTrend.direction == TrendDirection.up ||
              topTrend.direction == TrendDirection.down)) {
        final improving = topTrend.direction == TrendDirection.up;
        return {
          'icon': improving ? Icons.trending_up : Icons.trending_down,
          'title': loc.getString(
              improving ? 'ai_improving_trend' : 'ai_declining_trend'),
          'message': loc.getStringWithParams(
            'ai_trend_advice',
            {
              'param': loc.getString(topTrend.key, defaultValue: topTrend.key),
              'change': '${topTrend.percentChange.abs().toStringAsFixed(1)}%',
            },
          ),
          'action': loc.getString('view_trends'),
        };
      }

      return null;
    } catch (e) {
      debugPrint('Error generating personalized advice: $e');
      return null;
    }
  }

  Widget _buildAdviceCard(
      BuildContext context,
      LocalizationService loc,
      ColorScheme cs,
      IconData icon,
      String title,
      String message,
      String? action) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cs.secondaryContainer.withValues(alpha: 0.4),
            cs.primaryContainer.withValues(alpha: 0.2)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.secondaryContainer.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cs.secondaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: cs.onSecondaryContainer, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: cs.onSurface)),
                const SizedBox(height: 6),
                Text(message,
                    style: TextStyle(
                        color: cs.onSurface.withValues(alpha: .85),
                        fontSize: 14,
                        height: 1.4)),
                if (action != null) ...[
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () {
                      // Navigate to relevant screen based on action
                      if (action == loc.getString('view_full_analysis')) {
                        Navigator.pushNamed(context, '/advanced_analytics');
                      } else if (action == loc.getString('view_trends')) {
                        Navigator.pushNamed(context, '/stats');
                      } else {
                        Navigator.pushNamed(context, '/analysis');
                      }
                    },
                    icon: const Icon(Icons.arrow_forward, size: 16),
                    label: Text(action, style: const TextStyle(fontSize: 13)),
                    style: TextButton.styleFrom(
                      foregroundColor: cs.primary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WaterProgressCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LocalizationService>(context);
    final cs = Theme.of(context).colorScheme;
    return Consumer<WaterService>(
      builder: (context, water, _) {
        final today = water.todayCount;
        final goal = water.goal;
        final streak = water.streak;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.primaryContainer.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: cs.primaryContainer.withValues(alpha: 0.6)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.local_drink, color: cs.onPrimaryContainer),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      loc.getString('drink_water_title'),
                      style: TextStyle(
                          fontWeight: FontWeight.w700, color: cs.onSurface),
                    ),
                  ),
                  if (streak > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: cs.tertiaryContainer.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$streakðŸ”¥',
                        style: TextStyle(
                            color: cs.onTertiaryContainer,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${loc.getString('water_today')}: $today/$goal ${loc.getString('glasses_suffix')}',
                          style: TextStyle(
                              color: cs.onSurface.withValues(alpha: .8)),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            minHeight: 10,
                            value:
                                goal <= 0 ? 0 : (today.clamp(0, goal)) / goal,
                            backgroundColor: cs.surfaceContainerHighest
                                .withValues(alpha: 0.4),
                            valueColor:
                                AlwaysStoppedAnimation<Color>(cs.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async {
                          await Provider.of<WaterService>(context,
                                  listen: false)
                              .addGlass(1);
                        },
                        icon: const Icon(Icons.add),
                        label: Text(loc.getString('add_glass')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () => _showSetGoalDialog(context, loc),
                        child: Text(loc.getString('set_goal')),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSetGoalDialog(BuildContext context, LocalizationService loc) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(loc.getString('set_goal')),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(hintText: '8'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(loc.getString('cancel')),
            ),
            ElevatedButton(
              onPressed: () async {
                final val = int.tryParse(controller.text.trim());
                if (val != null && val > 0) {
                  await Provider.of<WaterService>(context, listen: false)
                      .setGoal(val);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(loc.getString('goal_updated'))),
                    );
                    Navigator.of(context).pop();
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              child: Text(loc.getString('save')),
            ),
          ],
        );
      },
    );
  }
}

class _PillboxCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LocalizationService>(context);
    final cs = Theme.of(context).colorScheme;
    return FutureBuilder<int?>(
      future:
          PreferencesService.getInstance().then((p) => p.getCurrentUserId()),
      builder: (context, snap) {
        final userId = snap.data;
        if (userId == null) {
          return _SectionContainer(
            title: loc.getString('pillbox_title'),
            child: _EmptyState(text: loc.getString('no_items')),
          );
        }
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: DatabaseHelper.instance.getMedications(userId),
          builder: (context, medsSnap) {
            final meds = medsSnap.data ?? const [];
            if (meds.isEmpty) {
              return _SectionContainer(
                title: loc.getString('pillbox_title'),
                child: _EmptyState(text: loc.getString('no_items')),
              );
            }
            return _SectionContainer(
              title: loc.getString('pillbox_title'),
              trailing: TextButton(
                onPressed: () => Navigator.pushNamed(context, '/reminders'),
                child: Text(loc.getString('details')),
              ),
              child: SizedBox(
                height: 90,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: meds.length.clamp(0, 10),
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, i) {
                    final m = meds[i];
                    final name = (m['name'] ?? '').toString();
                    final time =
                        (m['time_to_take'] ?? m['time'] ?? '').toString();
                    final active = (m['is_active'] ?? 1) == 1;
                    return Container(
                      width: 220,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: cs.outline.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: cs.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.medication, color: cs.primary),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: cs.onSurface)),
                                const SizedBox(height: 2),
                                Text(time.isEmpty ? '-' : time,
                                    style: TextStyle(
                                        color:
                                            cs.onSurface.withValues(alpha: 0.7),
                                        fontSize: 12)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(active ? Icons.check_circle : Icons.pause_circle,
                              color: active ? cs.primary : cs.outline)
                        ],
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _UpcomingTestsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LocalizationService>(context);
    final cs = Theme.of(context).colorScheme;
    return Consumer<inapp.NotificationService>(
      builder: (context, ns, _) {
        final all = ns.upcomingNotifications
            .where((n) => n.type == inapp.NotificationType.test)
            .toList()
          ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
        final items = all.take(3).toList();
        return _SectionContainer(
          title: loc.getString('upcoming_tests_title'),
          trailing: TextButton(
              onPressed: () => Navigator.pushNamed(context, '/notifications'),
              child: Text(loc.getString('details'))),
          child: items.isEmpty
              ? _EmptyState(text: loc.getString('no_items'))
              : Column(
                  children: [
                    for (final it in items)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Icon(Icons.biotech, color: cs.primary),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text(it.title,
                                    style: TextStyle(color: cs.onSurface))),
                            const SizedBox(width: 8),
                            Text(
                              '${loc.formatDate(it.scheduledTime)} ${loc.formatTime(it.scheduledTime)}',
                              style: TextStyle(
                                  color: cs.onSurface.withValues(alpha: 0.7),
                                  fontSize: 12),
                            ),
                          ],
                        ),
                      )
                  ],
                ),
        );
      },
    );
  }
}

class _HemogramSummaryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LocalizationService>(context);
    final cs = Theme.of(context).colorScheme;
    return FutureBuilder<int?>(
      future:
          PreferencesService.getInstance().then((p) => p.getCurrentUserId()),
      builder: (context, snap) {
        final userId = snap.data;
        if (userId == null) {
          return _SectionContainer(
              title: loc.getString('last_hemogram_title'),
              child: _EmptyState(text: loc.getString('no_items')));
        }
        return FutureBuilder<Map<String, dynamic>?>(
          future: DatabaseHelper.instance.getLatestHemogramTest(userId),
          builder: (context, latestSnap) {
            final last = latestSnap.data;
            if (last == null) {
              return _SectionContainer(
                  title: loc.getString('last_hemogram_title'),
                  child: _EmptyState(text: loc.getString('no_items')));
            }
            final values = <String, double>{};
            final rawJson = last['values_json'];
            if (rawJson is String && rawJson.isNotEmpty) {
              try {
                final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
                decoded.forEach((key, value) {
                  if (value is num) {
                    values[key] = value.toDouble();
                  } else if (value is String) {
                    final parsed = double.tryParse(value);
                    if (parsed != null) {
                      values[key] = parsed;
                    }
                  }
                });
              } catch (_) {
                // ignore malformed json entries
              }
            }
            void add(String k) {
              final v = last[k];
              if (v is num) {
                values[k] = v.toDouble();
              } else if (v is String) {
                final parsed = double.tryParse(v);
                if (parsed != null) {
                  values[k] = parsed;
                }
              }
            }

            for (final k in const [
              'hemoglobin',
              'iron',
              'erythrocyte',
              'hematocrit',
              'platelet',
              'mcv',
              'mch',
              'mchc',
              'rdw',
              'neutrophil',
              'lymphocyte',
              'monocyte',
              'eosinophil',
              'basophil'
            ]) {
              add(k);
            }
            final dateStr = (last['test_date'] ?? '').toString();
            final date = DateTime.tryParse(dateStr);
            return FutureBuilder<List<Map<String, dynamic>>>(
              future: DatabaseHelper.instance.getHemogramTestsByUser(userId),
              builder: (context, allSnap) {
                final all = (allSnap.data ?? const [])
                    .map((r) {
                      final d =
                          DateTime.tryParse((r['test_date'] ?? '').toString());
                      return (d, (r['hemoglobin'] as num?)?.toDouble());
                    })
                    .where((p) => p.$1 != null && p.$2 != null)
                    .map((p) => (p.$1 as DateTime, p.$2 as double))
                    .toList()
                  ..sort((a, b) => a.$1.compareTo(b.$1));
                final series = all.takeLast(8).toList(growable: false);
                return FutureBuilder<AnalysisResult>(
                  future: AnalysisService()
                      .analyze(userId: userId, currentValues: values),
                  builder: (context, resSnap) {
                    final res = resSnap.data;
                    return _SectionContainer(
                      title: loc.getString('last_hemogram_title'),
                      trailing: TextButton(
                        onPressed: () {
                          final args = <String, dynamic>{
                            'values': Map<String, double>.from(values),
                          };
                          if (date != null) {
                            args['testDate'] = date;
                          }
                          Navigator.pushNamed(
                            context,
                            '/analysis',
                            arguments: args,
                          );
                        },
                        child: Text(loc.getString('details')),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (date != null)
                            Text(
                              loc.formatDate(date),
                              style: TextStyle(
                                  color: cs.onSurface.withValues(alpha: 0.7),
                                  fontSize: 12),
                            ),
                          const SizedBox(height: 6),
                          if (res != null)
                            Text(res.summary,
                                style: TextStyle(
                                    color: cs.onSurface,
                                    fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          if (res != null)
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _riskColor(cs, res.riskLabel)
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                      '${loc.getString('risk_label')}: ${res.riskLabel}',
                                      style: TextStyle(
                                          color: _riskColor(cs, res.riskLabel),
                                          fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                          const SizedBox(height: 12),
                          if (series.isNotEmpty)
                            SizedBox(
                                height: 80,
                                child: _Sparkline(
                                    points: series, color: cs.primary)),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Color _riskColor(ColorScheme cs, String label) {
    switch (label) {
      case 'low':
        return Colors.teal;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.red;
      case 'very_high':
        return Colors.red.shade900;
      default:
        return cs.primary;
    }
  }
}

class _Sparkline extends StatelessWidget {
  final List<(DateTime, double)> points;
  final Color color;
  const _Sparkline({required this.points, required this.color});
  @override
  Widget build(BuildContext context) {
    if (points.length < 2) return const SizedBox.shrink();
    final xs = List<double>.generate(points.length, (i) => i.toDouble());
    final ys = points.map((p) => p.$2).toList();
    final minY = ys.reduce((a, b) => a < b ? a : b);
    final maxY = ys.reduce((a, b) => a > b ? a : b);
    return LineChart(LineChartData(
      gridData: const FlGridData(show: false),
      titlesData: const FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: (points.length - 1).toDouble(),
      minY: minY * 0.98,
      maxY: maxY * 1.02,
      lineBarsData: [
        LineChartBarData(
          spots: [for (var i = 0; i < points.length; i++) FlSpot(xs[i], ys[i])],
          isCurved: true,
          color: color,
          barWidth: 2,
          dotData: const FlDotData(show: false),
          belowBarData:
              BarAreaData(show: true, color: color.withValues(alpha: 0.15)),
        ),
      ],
    ));
  }
}

class _SectionContainer extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;
  const _SectionContainer(
      {required this.title, required this.child, this.trailing});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.w700, color: cs.onSurface))),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String text;
  const _EmptyState({required this.text});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(Icons.inbox_outlined, color: cs.outline),
          const SizedBox(width: 8),
          Text(text,
              style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7))),
        ],
      ),
    );
  }
}

extension _TakeLast<T> on List<T> {
  Iterable<T> takeLast(int n) {
    if (n <= 0) return const [];
    if (length <= n) return this;
    return sublist(length - n);
  }
}
