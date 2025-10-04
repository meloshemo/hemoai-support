import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/localization_service.dart';
import '../services/analytics_service.dart';
import '../services/cache_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final loc = Provider.of<LocalizationService>(context, listen: false);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(loc.getString('about_hemoai')),
        backgroundColor: theme.appBarTheme.backgroundColor ?? scheme.surface,
        foregroundColor: theme.appBarTheme.foregroundColor ?? scheme.onSurface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Header Card
            _buildHeaderCard(context, loc, theme, scheme),
            
            const SizedBox(height: 24),
            
            // Key Features
            _buildFeaturesCard(context, loc, theme, scheme),
            
            const SizedBox(height: 24),
            
            // Privacy & Security
            _buildPrivacyCard(context, loc, theme, scheme),
            
            const SizedBox(height: 24),
            
            // App Information
            _buildAppInfoCard(context, loc, theme, scheme),
            
            const SizedBox(height: 24),
            
            // Actions
            _buildActionsCard(context, loc, theme, scheme),
            
            const SizedBox(height: 24),
            
            // System Information (Debug)
            if (kDebugMode) _buildSystemInfoCard(context, loc, theme, scheme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, LocalizationService loc, ThemeData theme, ColorScheme scheme) {
    return Card(
      elevation: 2,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.primaryContainer,
              scheme.primaryContainer.withValues(alpha: 0.7),
            ],
          ),
        ),
        child: Column(
          children: [
            // App Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                Icons.biotech,
                size: 40,
                color: scheme.onPrimary,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // App Name
            Text(
              'HemoAI',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: scheme.onPrimaryContainer,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // App Description
            Text(
              loc.getString('app_description_detailed'),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onPrimaryContainer.withValues(alpha: 0.8),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesCard(BuildContext context, LocalizationService loc, ThemeData theme, ColorScheme scheme) {
    final features = [
      {'icon': Icons.psychology, 'text': loc.getString('feature_ai_analysis')},
      {'icon': Icons.restaurant_menu, 'text': loc.getString('feature_diet_recommendations')},
      {'icon': Icons.family_restroom, 'text': loc.getString('feature_family_tracking')},
      {'icon': Icons.security, 'text': loc.getString('feature_secure_data')},
      {'icon': Icons.file_download, 'text': loc.getString('feature_export_reports')},
      {'icon': Icons.language, 'text': loc.getString('feature_multilingual')},
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.star, color: scheme.primary),
                const SizedBox(width: 8),
                Text(
                  loc.getString('key_features'),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: scheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...features.map((feature) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(
                    feature['icon'] as IconData,
                    size: 20,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      feature['text'] as String,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyCard(BuildContext context, LocalizationService loc, ThemeData theme, ColorScheme scheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.privacy_tip, color: scheme.primary),
                const SizedBox(width: 8),
                Text(
                  loc.getString('privacy_first'),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: scheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildPrivacyItem(context, Icons.smartphone, loc.getString('data_stays_local'), theme, scheme),
            _buildPrivacyItem(context, Icons.cloud_off, loc.getString('no_cloud_upload'), theme, scheme),
            _buildPrivacyItem(context, Icons.lock, loc.getString('encrypted_backups'), theme, scheme),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyItem(BuildContext context, IconData icon, String text, ThemeData theme, ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: scheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  Widget _buildAppInfoCard(BuildContext context, LocalizationService loc, ThemeData theme, ColorScheme scheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info, color: scheme.primary),
                const SizedBox(width: 8),
                Text(
                  loc.getString('app_info'),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: scheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(loc.getString('app_version'), '1.0.0', theme),
            _buildInfoRow(loc.getString('build_number'), '1', theme),
            _buildInfoRow(loc.getString('developed_by'), loc.getString('developer_name'), theme),
            _buildInfoRow(loc.getString('release_date'), 'October 2025', theme),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsCard(BuildContext context, LocalizationService loc, ThemeData theme, ColorScheme scheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildActionTile(
              context,
              Icons.star_rate,
              loc.getString('rate_app'),
              () => _rateApp(context, loc),
              theme,
              scheme,
            ),
            _buildActionTile(
              context,
              Icons.share,
              loc.getString('share_app'),
              () => _shareApp(context, loc),
              theme,
              scheme,
            ),
            _buildActionTile(
              context,
              Icons.email,
              loc.getString('contact_support'),
              () => _contactSupport(context, loc),
              theme,
              scheme,
            ),
            _buildActionTile(
              context,
              Icons.article,
              loc.getString('open_source_licenses'),
              () => showLicensePage(context: context),
              theme,
              scheme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(BuildContext context, IconData icon, String title, VoidCallback onTap, ThemeData theme, ColorScheme scheme) {
    return Semantics(
      button: true,
      label: title,
      child: ListTile(
        leading: Icon(icon, color: scheme.primary),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildSystemInfoCard(BuildContext context, LocalizationService loc, ThemeData theme, ColorScheme scheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.developer_mode, color: scheme.primary),
                const SizedBox(width: 8),
                Text(
                  loc.getString('system_info'),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: scheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Platform', defaultTargetPlatform.name, theme),
            _buildInfoRow('Debug Mode', kDebugMode.toString(), theme),
            _buildInfoRow('Release Mode', kReleaseMode.toString(), theme),
            _buildInfoRow('Profile Mode', kProfileMode.toString(), theme),
            if (kIsWeb) _buildInfoRow('Is Web', 'true', theme),
            _buildActionTile(
              context,
              Icons.cleaning_services,
              loc.getString('clear_cache'),
              () => _clearCache(context, loc),
              theme,
              scheme,
            ),
          ],
        ),
      ),
    );
  }

  void _rateApp(BuildContext context, LocalizationService loc) {
    final analytics = Provider.of<AnalyticsService>(context, listen: false);
    analytics.trackEvent('rate_app_clicked');
    
    // Show info that rating is not available in debug/development
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(loc.getString('coming_soon')),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _shareApp(BuildContext context, LocalizationService loc) {
    final analytics = Provider.of<AnalyticsService>(context, listen: false);
    analytics.trackEvent('share_app_clicked');
    
    final shareText = '${loc.getString('app_name')} - ${loc.getString('app_description_detailed')}';
    Share.share(shareText);
  }

  void _contactSupport(BuildContext context, LocalizationService loc) {
    final analytics = Provider.of<AnalyticsService>(context, listen: false);
    analytics.trackEvent('contact_support_clicked');
    
    // Copy email to clipboard
    Clipboard.setData(ClipboardData(text: loc.getString('support_email')));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${loc.getString('support_email')} ${loc.getString('copy')}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _clearCache(BuildContext context, LocalizationService loc) {
    final analytics = Provider.of<AnalyticsService>(context, listen: false);
    analytics.trackEvent('cache_cleared_from_about');
    
  // Clear HemoAI cache
  HemoAICache().clearAll();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(loc.getString('cache_cleared')),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}