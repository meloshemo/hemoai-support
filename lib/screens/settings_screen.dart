import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/app_drawer.dart';
import '../widgets/unified_app_bar.dart';
import '../services/localization_service.dart';
import '../services/preferences_service.dart';
import '../services/push_notification_service.dart';
import '../services/backup_service.dart';
import '../services/analytics_service.dart';
import '../utils/backup_encryption.dart';
import '../utils/performance_optimizer.dart';
import '../services/theme_service.dart';
import '../services/auto_backup_service.dart';
import '../services/cloud_sync_service.dart';
import '../services/premium_service.dart';
import '../services/database_helper.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:typed_data';
import 'restore_preview_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'emergency_contact_screen.dart';
import '../utils/app_constants.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<LocalizationService, ThemeService>(
      builder: (context, loc, themeService, _) {
        final isDark = themeService.isDarkMode;
        final supportEmail = AppConstants.supportEmail;
        final supportUrl = AppConstants.supportUrl;
        final supportHost = Uri.parse(supportUrl).host;
        final bool compact =
            MediaQuery.of(context).size.width < 1024; // responsive breakpoint

        if (compact) {
          return Directionality(
            textDirection: loc.textDirection,
            child: Scaffold(
              backgroundColor:
                  isDark ? const Color(0xFF0D1117) : const Color(0xFFF6F8FA),
              drawer: const AppDrawer(currentRoute: '/settings'),
              appBar: UnifiedAppBar(
                title: loc.getString('settings'),
                currentRoute: '/settings',
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Header(
                      isDark: isDark,
                      title: loc.getString('settings'),
                      subtitle: loc.getString('customize_your_experience'),
                    ),

                    // Account & Language
                    _Section(
                      icon: Icons.person,
                      title: loc.getString('settings_personal_data'),
                      isDark: isDark,
                      children: [
                        _Tile(
                          icon: Icons.account_circle,
                          title: loc.getString('edit_profile'),
                          subtitle: loc.getString('edit_profile_desc'),
                          isDark: isDark,
                          onTap: () =>
                              Navigator.pushNamed(context, '/personal_info'),
                        ),
                        _Tile(
                          icon: Icons.translate,
                          title: loc.getString('language_settings'),
                          subtitle:
                              '${loc.getString('change_language_desc')} • ${loc.currentLanguageName}',
                          isDark: isDark,
                          onTap: () => Navigator.pushNamed(
                              context, '/language_settings'),
                        ),
                      ],
                    ),

                    // Privacy & Data
                    _Section(
                      icon: Icons.privacy_tip,
                      title: loc.getString('settings_privacy'),
                      isDark: isDark,
                      children: [
                        _Tile(
                          icon: Icons.download_outlined,
                          title: loc.getString('export_data'),
                          subtitle: loc.getString('export_options_subtitle'),
                          isDark: isDark,
                          onTap: () =>
                              Navigator.pushNamed(context, '/export_options'),
                        ),
                        _Tile(
                          icon: Icons.upload_outlined,
                          title: loc.getString('import_data'),
                          subtitle: loc.getString('restore_from_backup'),
                          isDark: isDark,
                          onTap: () =>
                              Navigator.pushNamed(context, '/data_import'),
                        ),
                        _Tile(
                          icon: Icons.delete_forever_outlined,
                          title: 'Delete Account & Data',
                          subtitle: 'KVKK/GDPR compliant right to erasure',
                          isDark: isDark,
                          onTap: () => _confirmDeleteAccount(context),
                        ),
                        _Tile(
                          icon: Icons.policy,
                          title: loc.getString('privacy_policy'),
                          subtitle: loc.getString('privacy_policy_desc'),
                          isDark: isDark,
                          onTap: () async {
                            try {
                              final uri =
                                  Uri.parse(AppConstants.privacyPolicyUrl);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri,
                                    mode: LaunchMode.externalApplication);
                              } else {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(loc.getString(
                                            'could_not_open_privacy_policy'))),
                                  );
                                }
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          '${loc.getString('error_opening_privacy_policy')}: $e')),
                                );
                              }
                            }
                          },
                        ),
                        _Tile(
                          icon: Icons.gavel,
                          title: loc.getString('terms_of_use'),
                          subtitle: loc.getString('terms_of_use_desc'),
                          isDark: isDark,
                          onTap: () async {
                            try {
                              final uri = Uri.parse(AppConstants.termsOfUseUrl);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri,
                                    mode: LaunchMode.externalApplication);
                              } else {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(loc.getString(
                                            'could_not_open_terms_of_use'))),
                                  );
                                }
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          '${loc.getString('error_opening_terms_of_use')}: $e')),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),

                    // Motivation & Challenges
                    _Section(
                      icon: Icons.emoji_events_outlined,
                      title: loc.getString('motivation_challenges_title'),
                      isDark: isDark,
                      children: [
                        _Tile(
                          icon: Icons.workspace_premium,
                          title: loc.getString('open_challenges'),
                          subtitle:
                              loc.getString('progress_badges_shared_diets'),
                          isDark: isDark,
                          onTap: () =>
                              Navigator.pushNamed(context, '/challenges'),
                        ),
                        _ChallengeSwitchTile(
                          icon: Icons.directions_walk,
                          title: loc.getString('weekly_steps_challenge'),
                          subtitle: loc.getString('join_weekly_step_goal'),
                          isDark: isDark,
                          getValue: () async {
                            final prefs =
                                await PreferencesService.getInstance();
                            return prefs.getChallengeSteps();
                          },
                          setValue: (v) async {
                            final messenger = ScaffoldMessenger.of(context);
                            final prefs =
                                await PreferencesService.getInstance();
                            await prefs.setChallengeEnabled(steps: v);
                            if (!context.mounted) return;
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  v
                                      ? loc.getString(
                                          'steps_challenge_enabled',
                                          defaultValue:
                                              'Steps challenge enabled',
                                        )
                                      : loc.getString(
                                          'steps_challenge_disabled',
                                          defaultValue:
                                              'Steps challenge disabled',
                                        ),
                                ),
                              ),
                            );
                          },
                        ),
                        _ChallengeSwitchTile(
                          icon: Icons.water_drop,
                          title: loc.getString('weekly_water_challenge'),
                          subtitle: loc.getString('hydration_streak_badges'),
                          isDark: isDark,
                          getValue: () async {
                            final prefs =
                                await PreferencesService.getInstance();
                            return prefs.getChallengeWater();
                          },
                          setValue: (v) async {
                            final messenger = ScaffoldMessenger.of(context);
                            final prefs =
                                await PreferencesService.getInstance();
                            await prefs.setChallengeEnabled(water: v);
                            if (!context.mounted) return;
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  v
                                      ? loc.getString(
                                          'water_challenge_enabled',
                                          defaultValue:
                                              'Water challenge enabled',
                                        )
                                      : loc.getString(
                                          'water_challenge_disabled',
                                          defaultValue:
                                              'Water challenge disabled',
                                        ),
                                ),
                              ),
                            );
                          },
                        ),
                        _ChallengeSwitchTile(
                          icon: Icons.nightlight_round,
                          title: loc.getString('weekly_sleep_challenge'),
                          subtitle: loc.getString('consistent_sleep_schedule'),
                          isDark: isDark,
                          getValue: () async {
                            final prefs =
                                await PreferencesService.getInstance();
                            return prefs.getChallengeSleep();
                          },
                          setValue: (v) async {
                            final messenger = ScaffoldMessenger.of(context);
                            final prefs =
                                await PreferencesService.getInstance();
                            await prefs.setChallengeEnabled(sleep: v);
                            if (!context.mounted) return;
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  v
                                      ? loc.getString(
                                          'sleep_challenge_enabled',
                                          defaultValue:
                                              'Sleep challenge enabled',
                                        )
                                      : loc.getString(
                                          'sleep_challenge_disabled',
                                          defaultValue:
                                              'Sleep challenge disabled',
                                        ),
                                ),
                              ),
                            );
                          },
                        ),
                        _Tile(
                          icon: Icons.speaker_notes,
                          title: loc.getString('motivation_tone_title'),
                          subtitle: loc.getString('motivation_tone_subtitle'),
                          isDark: isDark,
                          onTap: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final prefs =
                                await PreferencesService.getInstance();
                            if (!context.mounted) return;
                            final tone = await showDialog<String>(
                              context: context,
                              builder: (ctx) => SimpleDialog(
                                title: Text(
                                  loc.getString('motivation_tone_title'),
                                ),
                                children: [
                                  SimpleDialogOption(
                                    onPressed: () =>
                                        Navigator.pop(ctx, 'gentle'),
                                    child: Text(loc.getString(
                                        'motivation_tone_option_gentle')),
                                  ),
                                  SimpleDialogOption(
                                    onPressed: () =>
                                        Navigator.pop(ctx, 'active'),
                                    child: Text(loc.getString(
                                        'motivation_tone_option_active')),
                                  ),
                                ],
                              ),
                            );
                            if (!context.mounted || tone == null) return;
                            await prefs.setMotivationTone(tone);
                            if (!context.mounted) return;
                            final toneLabel = tone == 'gentle'
                                ? loc.getString('motivation_tone_option_gentle')
                                : loc
                                    .getString('motivation_tone_option_active');
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  loc.getStringWithParams(
                                    'motivation_tone_set',
                                    {'tone': toneLabel},
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        _Tile(
                          icon: Icons.schedule,
                          title: loc.getString('daily_summary_time'),
                          subtitle:
                              loc.getString('set_daily_notification_summary'),
                          isDark: isDark,
                          onTap: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final materialLoc =
                                MaterialLocalizations.of(context);
                            final prefs =
                                await PreferencesService.getInstance();
                            final initial = TimeOfDay(
                              hour: prefs.getDailySummaryHour(),
                              minute: prefs.getDailySummaryMinute(),
                            );
                            if (!context.mounted) return;
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: initial,
                            );
                            if (!context.mounted || picked == null) return;
                            await prefs.setDailySummaryTime(
                              picked.hour,
                              picked.minute,
                            );
                            if (!context.mounted) return;
                            final formatted =
                                materialLoc.formatTimeOfDay(picked);
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  loc.getStringWithParams(
                                    'daily_summary_set',
                                    {'time': formatted},
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        _Tile(
                          icon: Icons.share,
                          title: loc.getString('share_weekly_progress'),
                          subtitle: loc.getString('badges_streaks_summary'),
                          isDark: isDark,
                          onTap: () async {
                            // Simple share payload; integrate with real stats if available
                            final text =
                                loc.getString('share_weekly_progress_message');
                            await Share.share(text);
                          },
                        ),
                      ],
                    ),

                    // Premium
                    _Section(
                      icon: Icons.star,
                      title: loc.getString('premium'),
                      isDark: isDark,
                      children: [
                        Consumer<PremiumService>(
                          builder: (context, premiumService, _) {
                            return _Tile(
                              icon: Icons.star_outline,
                              title: loc.getString('premium_features'),
                              subtitle: premiumService.getStatusText(loc),
                              isDark: isDark,
                              onTap: () =>
                                  Navigator.pushNamed(context, '/premium'),
                            );
                          },
                        ),
                      ],
                    ),

                    // About & Legal
                    _Section(
                      icon: Icons.info_outline,
                      title: loc.getString('about_hemoai'),
                      isDark: isDark,
                      children: [
                        _Tile(
                          icon: Icons.approval_outlined,
                          title: loc.getString('medical_disclaimer'),
                          subtitle: loc.getString('medical_disclaimer_desc'),
                          isDark: isDark,
                          onTap: () => _openDocument(
                            context,
                            url: AppConstants.medicalDisclaimerUrl,
                            title: loc.getString('medical_disclaimer'),
                            fallbackBody: [
                              loc.getString('medical_disclaimer_body'),
                              loc.getString('medical_consult_prompt'),
                              loc.getString('medical_emergency_cta'),
                            ].join('\n\n'),
                          ),
                        ),
                        _Tile(
                          icon: Icons.policy_outlined,
                          title: loc.getString('kvkk_gdpr_data_protection'),
                          subtitle: loc.getString('encryption_consent_purpose'),
                          isDark: isDark,
                          onTap: () => _openDocument(
                            context,
                            url: AppConstants.dataProtectionUrl,
                            title: loc.getString('kvkk_gdpr_data_protection'),
                            fallbackBody:
                                loc.getString('data_protection_details'),
                          ),
                        ),
                        FutureBuilder<PackageInfo>(
                          future: PackageInfo.fromPlatform(),
                          builder: (context, snap) {
                            final ver = snap.hasData
                                ? '${snap.data!.version} (${snap.data!.buildNumber})'
                                : '—';
                            return _Tile(
                              icon: Icons.new_releases_outlined,
                              title: 'Version',
                              subtitle: ver,
                              isDark: isDark,
                              onTap: () {},
                            );
                          },
                        ),
                        _Tile(
                          icon: Icons.support_agent_outlined,
                          title: 'Support & Contact',
                          subtitle: '$supportEmail • $supportHost',
                          isDark: isDark,
                          onTap: () => _openSupportPortal(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Directionality(
          textDirection: loc.textDirection,
          child: Scaffold(
            backgroundColor:
                isDark ? const Color(0xFF0D1117) : const Color(0xFFF6F8FA),
            drawer: const AppDrawer(currentRoute: '/settings'),
            appBar: UnifiedAppBar(
              title: loc.getString('settings'),
              currentRoute: '/settings',
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Header(
                    isDark: isDark,
                    title: loc.getString('settings'),
                    subtitle: loc.getString('customize_your_experience'),
                  ),

                  // Medical Records & History
                  _Section(
                    icon: Icons.medical_services_outlined,
                    title: loc.getString('medical_records_history'),
                    isDark: isDark,
                    children: [
                      _Tile(
                        icon: Icons.history_outlined,
                        title: loc.getString('medical_history_management'),
                        subtitle:
                            loc.getString('medical_history_management_desc'),
                        isDark: isDark,
                        onTap: () => _showInfo(
                            context,
                            loc.getString('medical_history_management'),
                            loc.getString('medical_history_management_body')),
                      ),
                      _Tile(
                        icon: Icons.file_copy_outlined,
                        title: loc.getString('lab_reports_archive'),
                        subtitle: loc.getString('lab_reports_archive_desc'),
                        isDark: isDark,
                        onTap: () => _showInfo(
                            context,
                            loc.getString('lab_reports_archive'),
                            loc.getString('lab_reports_archive_body')),
                      ),
                      _Tile(
                        icon: Icons.assignment_outlined,
                        title: loc.getString('prescription_tracking'),
                        subtitle: loc.getString('prescription_tracking_desc'),
                        isDark: isDark,
                        onTap: () => _showInfo(
                            context,
                            loc.getString('prescription_tracking'),
                            loc.getString('prescription_tracking_body')),
                      ),
                      _SwitchTile(
                        icon: Icons.access_time_outlined,
                        title: loc.getString('appointment_history'),
                        subtitle: loc.getString('appointment_history_desc'),
                        prefKey: 'appointment_history_enabled',
                        isDark: isDark,
                      ),
                      _Tile(
                        icon: Icons.health_and_safety_outlined,
                        title: loc.getString('allergies_conditions'),
                        subtitle: loc.getString('allergies_conditions_desc'),
                        isDark: isDark,
                        onTap: () => _showInfo(
                            context,
                            loc.getString('allergies_conditions'),
                            loc.getString('allergies_conditions_body')),
                      ),
                    ],
                  ),

                  // Premium & Subscription
                  _Section(
                    icon: Icons.star,
                    title: loc.getString('premium'),
                    isDark: isDark,
                    children: [
                      Consumer<PremiumService>(
                        builder: (context, premiumService, _) {
                          return _Tile(
                            icon: Icons.star_outline,
                            title: loc.getString('premium_features'),
                            subtitle: premiumService.getStatusText(loc),
                            isDark: isDark,
                            onTap: () =>
                                Navigator.pushNamed(context, '/premium'),
                          );
                        },
                      ),
                    ],
                  ),

                  // Personal data & language
                  _Section(
                    icon: Icons.person,
                    title: loc.getString('settings_personal_data'),
                    isDark: isDark,
                    children: [
                      _Tile(
                        icon: Icons.account_circle,
                        title: loc.getString('edit_profile'),
                        subtitle: loc.getString('edit_profile_desc'),
                        isDark: isDark,
                        onTap: () =>
                            Navigator.pushNamed(context, '/personal_info'),
                      ),
                      _Tile(
                        icon: Icons.login,
                        title: loc.getString('account_login'),
                        subtitle: loc.getString('account_login_desc'),
                        isDark: isDark,
                        onTap: () => Navigator.pushNamed(context, '/login'),
                      ),
                      _Tile(
                        icon: Icons.translate,
                        title: loc.getString('language_settings'),
                        subtitle:
                            '${loc.getString('change_language_desc')} • ${loc.currentLanguageName}',
                        isDark: isDark,
                        onTap: () =>
                            Navigator.pushNamed(context, '/language_settings'),
                      ),
                    ],
                  ),

                  // Privacy and analytics
                  _Section(
                    icon: Icons.privacy_tip,
                    title: loc.getString('settings_privacy'),
                    isDark: isDark,
                    children: [
                      _SwitchTile(
                        icon: Icons.notifications_active,
                        title: loc.getString('privacy_allow_in_app_reminders'),
                        subtitle: loc
                            .getString('privacy_allow_in_app_reminders_desc'),
                        prefKey: 'privacy_allow_in_app_reminders',
                        isDark: isDark,
                        onChanged: (v) async {
                          final prefs = await PreferencesService.getInstance();
                          await prefs.setPrivacyFlag(
                              'allow_in_app_reminders', v);
                        },
                      ),
                      _SwitchTile(
                        icon: Icons.notifications_none,
                        title:
                            loc.getString('privacy_allow_push_notifications'),
                        subtitle: loc
                            .getString('privacy_allow_push_notifications_desc'),
                        prefKey: 'privacy_allow_push_notifications',
                        isDark: isDark,
                        onChanged: (v) async {
                          final prefs = await PreferencesService.getInstance();
                          await prefs.setPrivacyFlag(
                              'allow_push_notifications', v);
                        },
                      ),
                      _SwitchTile(
                        icon: Icons.medication_outlined,
                        title: loc.getString('privacy_allow_medication_access'),
                        subtitle: loc
                            .getString('privacy_allow_medication_access_desc'),
                        prefKey: 'privacy_allow_medication_access',
                        isDark: isDark,
                        onChanged: (v) async {
                          final prefs = await PreferencesService.getInstance();
                          await prefs.setPrivacyFlag(
                              'allow_medication_access', v);
                        },
                      ),
                      _SwitchTile(
                        icon: Icons.group_outlined,
                        title: loc.getString('privacy_allow_family_features'),
                        subtitle:
                            loc.getString('privacy_allow_family_features_desc'),
                        prefKey: 'privacy_allow_family_features',
                        isDark: isDark,
                        onChanged: (v) async {
                          final prefs = await PreferencesService.getInstance();
                          await prefs.setPrivacyFlag(
                              'allow_family_features', v);
                        },
                      ),
                      _SwitchTile(
                        icon: Icons.analytics_outlined,
                        title: loc.getString('analytics_opt_in'),
                        subtitle: loc.getString('analytics_opt_in_desc'),
                        prefKey: 'analytics_opt_in',
                        isDark: isDark,
                        onChanged: (v) => Provider.of<AnalyticsService>(context,
                                listen: false)
                            .setOptIn(v),
                      ),
                      _Tile(
                        icon: Icons.verified_user,
                        title: loc.getString('secure_pii_title'),
                        subtitle: loc.getString('secure_pii_desc'),
                        isDark: isDark,
                        onTap: () async {
                          final prefs = await PreferencesService.getInstance();
                          await prefs.ensurePiiSecured();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      loc.getString('pii_migrated_success'))),
                            );
                          }
                        },
                      ),
                      _Tile(
                        icon: Icons.lock,
                        title: loc.getString('set_backup_password'),
                        subtitle: loc.getString('set_backup_password_desc'),
                        isDark: isDark,
                        onTap: () async {
                          final pwd =
                              await _askPassword(context, loc, confirm: true);
                          if (pwd == null || pwd.isEmpty) return;
                          final prefs = await PreferencesService.getInstance();
                          await prefs.setCloudBackupPassword(pwd);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text(loc.getString('password_saved'))),
                            );
                          }
                        },
                      ),
                      _Tile(
                        icon: Icons.lock_open,
                        title: loc.getString('clear_backup_password'),
                        subtitle: loc.getString('clear_backup_password_desc'),
                        isDark: isDark,
                        onTap: () async {
                          final prefs = await PreferencesService.getInstance();
                          await prefs.clearCloudBackupPassword();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text(loc.getString('password_cleared'))),
                            );
                          }
                        },
                      ),
                    ],
                  ),

                  // About HemoAI (Professional health app info)
                  _Section(
                    icon: Icons.info_outline,
                    title: 'About HemoAI',
                    isDark: isDark,
                    children: [
                      _Tile(
                        icon: Icons.approval_outlined,
                        title: 'Medical Disclaimer',
                        subtitle:
                            'HemoAI provides educational health insights and is not a substitute for professional medical diagnosis or treatment. Always consult a qualified physician for medical decisions.',
                        isDark: isDark,
                        onTap: () => _showInfo(context, 'Medical Disclaimer',
                            'HemoAI does not provide medical services. The insights and recommendations are generated for educational purposes based on your self-reported or synchronized health data. In urgent or severe cases, contact emergency services or your physician. Use of HemoAI constitutes acceptance of this disclaimer.'),
                      ),

                      // Motivation & Challenges
                      _Section(
                        icon: Icons.emoji_events_outlined,
                        title: loc.getString('motivation_challenges_title'),
                        isDark: isDark,
                        children: [
                          _SwitchTile(
                            icon: Icons.directions_walk,
                            title: loc.getString('weekly_steps_challenge'),
                            subtitle: loc.getString('join_weekly_step_goal'),
                            prefKey: 'challenge_steps',
                            isDark: isDark,
                            onChanged: (v) async {
                              final prefs =
                                  await PreferencesService.getInstance();
                              await prefs.setChallengeEnabled(steps: v);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                    v
                                        ? loc.getString(
                                            'steps_challenge_enabled')
                                        : loc.getString(
                                            'steps_challenge_disabled'),
                                  )),
                                );
                              }
                            },
                          ),
                          _SwitchTile(
                            icon: Icons.water_drop,
                            title: loc.getString('weekly_water_challenge'),
                            subtitle: loc.getString('hydration_streak_badges'),
                            prefKey: 'challenge_water',
                            isDark: isDark,
                            onChanged: (v) async {
                              final prefs =
                                  await PreferencesService.getInstance();
                              await prefs.setChallengeEnabled(water: v);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                    v
                                        ? loc.getString(
                                            'water_challenge_enabled')
                                        : loc.getString(
                                            'water_challenge_disabled'),
                                  )),
                                );
                              }
                            },
                          ),
                          _SwitchTile(
                            icon: Icons.nightlight_round,
                            title: loc.getString('weekly_sleep_challenge'),
                            subtitle:
                                loc.getString('consistent_sleep_schedule'),
                            prefKey: 'challenge_sleep',
                            isDark: isDark,
                            onChanged: (v) async {
                              final prefs =
                                  await PreferencesService.getInstance();
                              await prefs.setChallengeEnabled(sleep: v);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                    v
                                        ? loc.getString(
                                            'sleep_challenge_enabled')
                                        : loc.getString(
                                            'sleep_challenge_disabled'),
                                  )),
                                );
                              }
                            },
                          ),
                          _Tile(
                            icon: Icons.speaker_notes,
                            title: loc.getString('motivation_tone_title'),
                            subtitle: loc.getString('motivation_tone_subtitle'),
                            isDark: isDark,
                            onTap: () async {
                              final prefs =
                                  await PreferencesService.getInstance();
                              if (!context.mounted) return;
                              final tone = await showDialog<String>(
                                context: context,
                                builder: (ctx) => SimpleDialog(
                                  title: Text(
                                      loc.getString('motivation_tone_title')),
                                  children: [
                                    SimpleDialogOption(
                                        onPressed: () =>
                                            Navigator.pop(ctx, 'gentle'),
                                        child: Text(loc.getString(
                                            'motivation_tone_option_gentle'))),
                                    SimpleDialogOption(
                                        onPressed: () =>
                                            Navigator.pop(ctx, 'active'),
                                        child: Text(loc.getString(
                                            'motivation_tone_option_active'))),
                                  ],
                                ),
                              );
                              if (tone != null) {
                                await prefs.setMotivationTone(tone);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        Provider.of<LocalizationService>(
                                                context,
                                                listen: false)
                                            .getStringWithParams(
                                                'motivation_tone_set',
                                                {'tone': tone}),
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                          _Tile(
                            icon: Icons.schedule,
                            title: loc.getString('daily_summary_time'),
                            subtitle:
                                loc.getString('set_daily_notification_summary'),
                            isDark: isDark,
                            onTap: () async {
                              final prefs =
                                  await PreferencesService.getInstance();
                              if (!context.mounted) return;
                              final initial = TimeOfDay(
                                  hour: prefs.getDailySummaryHour(),
                                  minute: prefs.getDailySummaryMinute());
                              final picked = await showTimePicker(
                                  context: context, initialTime: initial);
                              if (picked != null) {
                                await prefs.setDailySummaryTime(
                                    picked.hour, picked.minute);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        Provider.of<LocalizationService>(
                                                context,
                                                listen: false)
                                            .getStringWithParams(
                                                'daily_summary_set', {
                                          'time': picked.format(context),
                                        }),
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                          _Tile(
                            icon: Icons.share,
                            title: loc.getString('share_weekly_progress'),
                            subtitle: loc.getString('badges_streaks_summary'),
                            isDark: isDark,
                            onTap: () async {
                              // Simple share payload; integrate with real stats if available
                              final text = loc
                                  .getString('share_weekly_progress_message');
                              await Share.share(text);
                            },
                          ),
                        ],
                      ),
                      _Tile(
                        icon: Icons.policy_outlined,
                        title: 'KVKK/GDPR & Data Protection',
                        subtitle:
                            'Your personal and health data are processed with your explicit consent and stored securely with encryption. You may request export or deletion at any time from Settings > Privacy.',
                        isDark: isDark,
                        onTap: () => _showInfo(
                            context,
                            'KVKK/GDPR & Data Protection',
                            'We apply data minimization, purpose limitation, and retention controls. Access is restricted and logged. Data is encrypted at rest and in transit. For detailed policy and DPO contact, visit ${AppConstants.privacyPolicyUrl}.'),
                      ),
                      FutureBuilder<PackageInfo>(
                        future: PackageInfo.fromPlatform(),
                        builder: (context, snap) {
                          final ver = snap.hasData
                              ? '${snap.data!.version} (${snap.data!.buildNumber})'
                              : '—';
                          return _Tile(
                            icon: Icons.new_releases_outlined,
                            title: 'Version',
                            subtitle: ver,
                            isDark: isDark,
                            onTap: () {},
                          );
                        },
                      ),
                      _Tile(
                        icon: Icons.support_agent_outlined,
                        title: 'Support & Contact',
                        subtitle: '$supportEmail • $supportHost',
                        isDark: isDark,
                        onTap: () => _openSupportPortal(context),
                      ),
                    ],
                  ),

                  // Health monitoring settings
                  _Section(
                    icon: Icons.favorite_outline,
                    title: loc.getString('settings_health_monitoring'),
                    isDark: isDark,
                    children: [
                      _SwitchTile(
                        icon: Icons.apple,
                        title: loc.getString('health_sync_apple_health'),
                        subtitle:
                            loc.getString('health_sync_apple_health_desc'),
                        prefKey: 'health_sync_apple_health',
                        isDark: isDark,
                      ),
                      _SwitchTile(
                        icon: Icons.fitness_center,
                        title: loc.getString('health_sync_google_fit'),
                        subtitle: loc.getString('health_sync_google_fit_desc'),
                        prefKey: 'health_sync_google_fit',
                        isDark: isDark,
                      ),
                      _SwitchTile(
                        icon: Icons.watch,
                        title: loc.getString('health_sync_samsung_health'),
                        subtitle:
                            loc.getString('health_sync_samsung_health_desc'),
                        prefKey: 'health_sync_samsung_health',
                        isDark: isDark,
                      ),
                      _Tile(
                        icon: Icons.straighten,
                        title: loc.getString('health_units_title'),
                        subtitle: loc.getString('health_units_title_desc'),
                        isDark: isDark,
                        onTap: () => _showUnitSelector(context, loc, isDark),
                      ),
                      _Tile(
                        icon: Icons.timeline,
                        title: loc.getString('health_test_frequency'),
                        subtitle: loc.getString('health_test_frequency_desc'),
                        isDark: isDark,
                        onTap: () =>
                            _showFrequencySelector(context, loc, isDark),
                      ),
                      _SwitchTile(
                        icon: Icons.warning_amber,
                        title: loc.getString('health_critical_alert'),
                        subtitle: loc.getString('health_critical_alert_desc'),
                        prefKey: 'health_critical_alert',
                        isDark: isDark,
                      ),
                      _SwitchTile(
                        icon: Icons.trending_up,
                        title: loc.getString('health_trend_analysis'),
                        subtitle: loc.getString('health_trend_analysis_desc'),
                        prefKey: 'health_trend_analysis',
                        isDark: isDark,
                      ),
                      _Tile(
                        icon: Icons.storage_outlined,
                        title: loc.getString('health_data_retention'),
                        subtitle: loc.getString('health_data_retention_desc'),
                        isDark: isDark,
                        onTap: () =>
                            _showRetentionSelector(context, loc, isDark),
                      ),
                      _SwitchTile(
                        icon: Icons.restaurant_menu,
                        title: loc.getString('health_diet_auto_sync'),
                        subtitle: loc.getString('health_diet_auto_sync_desc'),
                        prefKey: 'health_diet_auto_sync',
                        isDark: isDark,
                      ),
                      _Tile(
                        icon: Icons.share_outlined,
                        title: loc.getString('health_sharing'),
                        subtitle: loc.getString('health_sharing_desc'),
                        isDark: isDark,
                        onTap: () => _showSharingOptions(context, loc, isDark),
                      ),
                      _Tile(
                        icon: Icons.balance_outlined,
                        title: loc.getString('health_reference_ranges'),
                        subtitle: loc.getString('health_reference_ranges_desc'),
                        isDark: isDark,
                        onTap: () => _showReferenceRanges(context, loc, isDark),
                      ),
                      // Emergency & Medical Info
                      _Tile(
                        icon: Icons.emergency_outlined,
                        title: loc.getString('health_emergency_contact'),
                        subtitle:
                            loc.getString('health_emergency_contact_desc'),
                        isDark: isDark,
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const EmergencyContactScreen())),
                      ),
                      _Tile(
                        icon: Icons.history_outlined,
                        title: loc.getString('health_medical_history'),
                        subtitle: loc.getString('health_medical_history_desc'),
                        isDark: isDark,
                        onTap: () => _showInfo(
                            context,
                            loc.getString('health_medical_history'),
                            '${loc.getString('health_medical_history_desc')} ${loc.getString('coming_soon')}'),
                      ),
                      _Tile(
                        icon: Icons.bloodtype,
                        title: loc.getString('health_blood_type'),
                        subtitle: loc.getString('health_blood_type_desc'),
                        isDark: isDark,
                        onTap: () =>
                            _showBloodTypeSelector(context, loc, isDark),
                      ),
                      _SwitchTile(
                        icon: Icons.medication,
                        title: loc.getString('health_medications'),
                        subtitle: loc.getString('health_medications_desc'),
                        prefKey: 'health_medications_tracking',
                        isDark: isDark,
                      ),
                      _SwitchTile(
                        icon: Icons.directions_run,
                        title: loc.getString('health_activity_tracking'),
                        subtitle:
                            loc.getString('health_activity_tracking_desc'),
                        prefKey: 'health_activity_tracking',
                        isDark: isDark,
                      ),
                      _SwitchTile(
                        icon: Icons.bedtime_outlined,
                        title: loc.getString('health_sleep_tracking'),
                        subtitle: loc.getString('health_sleep_tracking_desc'),
                        prefKey: 'health_sleep_tracking',
                        isDark: isDark,
                      ),
                      _Tile(
                        icon: Icons.notifications_active_outlined,
                        title: loc.getString('health_reminder_sound'),
                        subtitle: loc.getString('health_reminder_sound_desc'),
                        isDark: isDark,
                        onTap: () => _showInfo(
                            context,
                            loc.getString('health_reminder_sound'),
                            '${loc.getString('health_reminder_sound_desc')} ${loc.getString('coming_soon')}'),
                      ),
                      _SwitchTile(
                        icon: Icons.backup_outlined,
                        title: loc.getString('health_auto_backup'),
                        subtitle: loc.getString('health_auto_backup_desc'),
                        prefKey: 'health_auto_backup_enabled',
                        isDark: isDark,
                      ),
                      _Tile(
                        icon: Icons.picture_as_pdf,
                        title: loc.getString('health_report_format'),
                        subtitle: loc.getString('health_report_format_desc'),
                        isDark: isDark,
                        onTap: () =>
                            _showReportFormatSelector(context, loc, isDark),
                      ),
                    ],
                  ),

                  // Advanced Health Analytics
                  _Section(
                    icon: Icons.insights_outlined,
                    title: loc.getString('advanced_health_analytics'),
                    isDark: isDark,
                    children: [
                      _Tile(
                        icon: Icons.timeline_outlined,
                        title: loc.getString('trend_prediction'),
                        subtitle: loc.getString('trend_prediction_desc'),
                        isDark: isDark,
                        onTap: () => _showInfo(
                            context,
                            loc.getString('trend_prediction'),
                            loc.getString('trend_prediction_body')),
                      ),
                      _SwitchTile(
                        icon: Icons.warning_outlined,
                        title: loc.getString('smart_alert_thresholds'),
                        subtitle: loc.getString('smart_alert_thresholds_desc'),
                        prefKey: 'smart_alert_thresholds_enabled',
                        isDark: isDark,
                      ),
                      _Tile(
                        icon: Icons.compare_arrows_outlined,
                        title: loc.getString('comparative_analysis'),
                        subtitle: loc.getString('comparative_analysis_desc'),
                        isDark: isDark,
                        onTap: () => _showInfo(
                            context,
                            loc.getString('comparative_analysis'),
                            loc.getString('comparative_analysis_body')),
                      ),
                      _SwitchTile(
                        icon: Icons.auto_graph,
                        title: loc.getString('ai_recommendations'),
                        subtitle: loc.getString('ai_recommendations_desc'),
                        prefKey: 'ai_recommendations_enabled',
                        isDark: isDark,
                      ),
                      _Tile(
                        icon: Icons.assessment_outlined,
                        title: loc.getString('health_score_calculation'),
                        subtitle:
                            loc.getString('health_score_calculation_desc'),
                        isDark: isDark,
                        onTap: () => _showInfo(
                            context,
                            loc.getString('health_score_calculation'),
                            loc.getString('health_score_calculation_body')),
                      ),
                    ],
                  ),

                  // Data Sharing & Export
                  _Section(
                    icon: Icons.share_outlined,
                    title: loc.getString('data_sharing_export'),
                    isDark: isDark,
                    children: [
                      _Tile(
                        icon: Icons.medical_information_outlined,
                        title: loc.getString('export_to_doctor'),
                        subtitle: loc.getString('export_to_doctor_desc'),
                        isDark: isDark,
                        onTap: () => _showInfo(
                            context,
                            loc.getString('export_to_doctor'),
                            loc.getString('export_to_doctor_body')),
                      ),
                      _Tile(
                        icon: Icons.cloud_upload_outlined,
                        title: loc.getString('cloud_storage_integration'),
                        subtitle:
                            loc.getString('cloud_storage_integration_desc'),
                        isDark: isDark,
                        onTap: () => _showInfo(
                            context,
                            loc.getString('cloud_storage_integration'),
                            loc.getString('cloud_storage_integration_body')),
                      ),
                      _Tile(
                        icon: Icons.folder_shared_outlined,
                        title: loc.getString('family_sharing'),
                        subtitle: loc.getString('family_sharing_desc'),
                        isDark: isDark,
                        onTap: () => _showInfo(
                            context,
                            loc.getString('family_sharing'),
                            loc.getString('family_sharing_body')),
                      ),
                      _SwitchTile(
                        icon: Icons.autorenew_outlined,
                        title: loc.getString('auto_sync_enabled'),
                        subtitle: loc.getString('auto_sync_enabled_desc'),
                        prefKey: 'auto_sync_enabled',
                        isDark: isDark,
                      ),
                    ],
                  ),

                  // Automatic Backup Section
                  _Section(
                    icon: Icons.cloud_upload_outlined,
                    title: loc.getString('automatic_backup'),
                    isDark: isDark,
                    children: [
                      _SwitchTile(
                        icon: Icons.cloud_sync_outlined,
                        title: loc.getString('auto_backup_enabled'),
                        subtitle: loc.getString('auto_backup_enabled_desc'),
                        prefKey: 'auto_backup_enabled',
                        isDark: isDark,
                        onChanged: (enabled) async {
                          final autoBackup = AutoBackupService();
                          await autoBackup.setEnabled(enabled);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(enabled
                                    ? loc.getString(
                                        'auto_backup_enabled_success')
                                    : loc.getString(
                                        'auto_backup_disabled_success')),
                                backgroundColor: enabled
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors
                                        .orange, // Warning color - keep semantic
                              ),
                            );
                          }
                        },
                      ),
                      _Tile(
                        icon: Icons.schedule_outlined,
                        title: loc.getString('backup_interval'),
                        subtitle: loc.getString('backup_interval_desc'),
                        isDark: isDark,
                        onTap: () =>
                            _showBackupIntervalSelector(context, loc, isDark),
                      ),
                      _Tile(
                        icon: Icons.backup_outlined,
                        title: loc.getString('backup_now'),
                        subtitle: loc.getString('backup_now_desc'),
                        isDark: isDark,
                        onTap: () => _triggerManualBackup(context, loc),
                      ),
                      _Tile(
                        icon: Icons.restore_outlined,
                        title: loc.getString('restore_from_cloud'),
                        subtitle: loc.getString('restore_from_cloud_desc'),
                        isDark: isDark,
                        onTap: () => _triggerCloudRestore(context, loc),
                      ),
                    ],
                  ),

                  // Security & notifications
                  _Section(
                    icon: Icons.security,
                    title: loc.getString('settings_security'),
                    isDark: isDark,
                    children: [
                      _Tile(
                        icon: Icons.notifications_active_outlined,
                        title: loc.getString('notification_settings_title'),
                        subtitle: Provider.of<PushNotificationService>(context)
                                .permissionGranted
                            ? loc.getString('permission_granted')
                            : loc.getString('allow_notifications_desc'),
                        isDark: isDark,
                        onTap: () async {
                          final svc = Provider.of<PushNotificationService>(
                              context,
                              listen: false);
                          await svc.requestPermissions();
                          if (!context.mounted) return;
                          final granted = svc.permissionGranted;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(granted
                                    ? loc.getString('done')
                                    : loc.getString('permission_denied'))),
                          );
                        },
                      ),
                      _Tile(
                        icon: Icons.settings_outlined,
                        title: loc.getString('open_system_settings'),
                        subtitle: loc.getString('open_system_settings_desc'),
                        isDark: isDark,
                        onTap: () => Provider.of<PushNotificationService>(
                                context,
                                listen: false)
                            .openSystemSettings(),
                      ),
                      _Tile(
                        icon: Icons.privacy_tip_outlined,
                        title: loc.getString('privacy_summary_title'),
                        subtitle: loc.getString('privacy_summary_desc'),
                        isDark: isDark,
                        onTap: () => _showInfo(
                          context,
                          loc.getString('privacy_summary_title'),
                          loc.getString('privacy_summary_body'),
                        ),
                      ),
                      _SwitchTile(
                        icon: Icons.lock_outline,
                        title: loc.getString('app_lock'),
                        subtitle: loc.getString('app_lock_desc'),
                        prefKey: 'app_lock_enabled',
                        isDark: isDark,
                      ),
                      _Tile(
                        icon: Icons.notifications_off,
                        title: loc.getString('clear_notifications'),
                        subtitle: loc.getString('clear_notifications_desc'),
                        isDark: isDark,
                        onTap: () {
                          Provider.of<PushNotificationService>(context,
                                  listen: false)
                              .clearAllNotifications();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(loc.getString('done'))),
                          );
                        },
                      ),
                      _Tile(
                        icon: Icons.bug_report_outlined,
                        title: loc.getString('notification_debug_title'),
                        subtitle: loc.getString('notification_debug_desc'),
                        isDark: isDark,
                        onTap: () =>
                            Navigator.pushNamed(context, '/notification_debug'),
                      ),
                    ],
                  ),

                  // Backup & restore
                  _Section(
                    icon: Icons.storage,
                    title: loc.getString('settings_data_backup'),
                    isDark: isDark,
                    children: [
                      _Tile(
                        icon: Icons.verified_outlined,
                        title: loc.getString('trial_backup_title'),
                        subtitle: loc.getString('trial_backup_desc'),
                        isDark: isDark,
                        onTap: () async {
                          final analytics = Provider.of<AnalyticsService>(
                              context,
                              listen: false);
                          final navigator = Navigator.of(context);
                          final theme = Theme.of(context);
                          final messenger = ScaffoldMessenger.of(context);
                          final errSnack = SnackBar(
                            content: Text(loc.getString('export_failed')),
                            backgroundColor: theme.colorScheme.error,
                          );
                          analytics.trackEvent('trial_backup_start');
                          try {
                            final backup = await BackupService().exportAll();
                            analytics.trackEvent('trial_backup_ready',
                                parameters: {'bytes': backup.length});
                            await navigator.push<bool>(
                              MaterialPageRoute(
                                builder: (_) => RestorePreviewScreen(
                                  backupBytes: Uint8List.fromList(backup),
                                ),
                              ),
                            );
                          } catch (e) {
                            analytics.trackEvent('trial_backup_failed',
                                parameters: {'error': e.toString()});
                            messenger.showSnackBar(errSnack);
                          }
                        },
                      ),
                      _Tile(
                        icon: Icons.insights_outlined,
                        title: loc.getString('stats_overview_title'),
                        subtitle: loc.getString('stats_overview_desc'),
                        isDark: isDark,
                        onTap: () => Navigator.pushNamed(context, '/stats'),
                      ),
                      _Tile(
                        icon: Icons.backup,
                        title: loc.getString('backup_data'),
                        subtitle: loc.getString('backup_data_desc'),
                        isDark: isDark,
                        onTap: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final navigator = Navigator.of(context);
                          final okText = loc.getString('export_success');
                          final errText = loc.getString('export_failed');
                          final backupReady = loc.getString('backup_ready');
                          final errorColor =
                              Theme.of(context).colorScheme.error;
                          final analytics = Provider.of<AnalyticsService>(
                              context,
                              listen: false);
                          // Create JSON backup and share
                          final backup = await BackupService().exportAll();
                          final name =
                              'hemoai_backup_${DateTime.now().millisecondsSinceEpoch}.json';
                          try {
                            final x = XFile.fromData(
                              Uint8List.fromList(backup),
                              name: name,
                              mimeType: 'application/json',
                            );
                            await Share.shareXFiles([x], text: backupReady);
                            // Analytics: backup shared
                            analytics.trackEvent('backup_shared',
                                parameters: {'bytes': backup.length});
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(okText),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } catch (e) {
                            analytics.trackEvent('backup_share_failed',
                                parameters: {'error': e.toString()});
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(errText),
                                backgroundColor: errorColor,
                                action: SnackBarAction(
                                  label: loc.getString('details'),
                                  onPressed: () => _showErrorDetails(
                                    navigator.context,
                                    loc.getString('error_details'),
                                    e.toString(),
                                  ),
                                ),
                              ),
                            );
                          }
                        },
                      ),
                      _Tile(
                        icon: Icons.lock_outline,
                        title: loc.getString('encrypted_backup'),
                        subtitle: loc.getString('encrypted_backup_desc'),
                        isDark: isDark,
                        onTap: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final navigator = Navigator.of(context);
                          final okText = loc.getString('export_success');
                          final errText = loc.getString('export_failed');
                          final errorColor =
                              Theme.of(context).colorScheme.error;
                          final analytics = Provider.of<AnalyticsService>(
                              context,
                              listen: false);
                          // Ask for password + confirm
                          final pwd = await _askPassword(navigator.context, loc,
                              confirm: true);
                          if (pwd == null) return;
                          try {
                            final backup = await BackupService().exportAll();
                            final enc = await BackupEncryption.encryptBytes(
                              Uint8List.fromList(backup),
                              pwd,
                            );
                            final name =
                                'hemoai_backup_${DateTime.now().millisecondsSinceEpoch}.hemoenc';
                            final x = XFile.fromData(
                              enc,
                              name: name,
                              mimeType: 'application/octet-stream',
                            );
                            await Share.shareXFiles(
                              [x],
                              text: loc.getString('encryption_enabled'),
                            );
                            analytics.trackEvent('backup_encrypted_shared',
                                parameters: {'bytes': enc.length});
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(okText),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } catch (e) {
                            analytics.trackEvent('backup_encrypted_failed',
                                parameters: {'error': e.toString()});
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(errText),
                                backgroundColor: errorColor,
                                action: SnackBarAction(
                                  label: loc.getString('details'),
                                  onPressed: () => _showErrorDetails(
                                    navigator.context,
                                    loc.getString('error_details'),
                                    e.toString(),
                                  ),
                                ),
                              ),
                            );
                          }
                        },
                      ),
                      _Tile(
                        icon: Icons.restore,
                        title: loc.getString('restore_data'),
                        subtitle: loc.getString('restore_data_desc'),
                        isDark: isDark,
                        onTap: () async {
                          // Pick JSON backup and restore
                          final messenger = ScaffoldMessenger.of(context);
                          final errorColor =
                              Theme.of(context).colorScheme.error;
                          final analytics = Provider.of<AnalyticsService>(
                              context,
                              listen: false);
                          final navigator = Navigator.of(context);
                          final noFileText = loc.getString('no_file_selected');
                          final okText = loc.getString('export_success');
                          final errText = loc.getString('export_failed');
                          try {
                            final res = await FilePicker.platform.pickFiles(
                              allowMultiple: false,
                              withData: true,
                              type: FileType.custom,
                              allowedExtensions: const ['json', 'hemoenc'],
                            );
                            if (res == null ||
                                res.files.isEmpty ||
                                res.files.single.bytes == null) {
                              analytics.trackEvent('restore_cancelled');
                              messenger.showSnackBar(
                                  SnackBar(content: Text(noFileText)));
                              return;
                            }
                            final file = res.files.single;
                            Uint8List bytes = file.bytes!;
                            if (file.name.endsWith('.hemoenc')) {
                              if (!navigator.mounted) return;
                              final pwd = await _askPassword(
                                navigator.context,
                                loc,
                                confirm: false,
                              );
                              if (pwd == null) return;
                              try {
                                bytes = await BackupEncryption.decryptBytes(
                                    bytes, pwd);
                              } catch (_) {
                                analytics
                                    .trackEvent('restore_decryption_failed');
                                if (!navigator.mounted) return;
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        loc.getString('decryption_failed')),
                                    backgroundColor: errorColor,
                                    action: SnackBarAction(
                                      label: loc.getString('details'),
                                      onPressed: () => _showErrorDetails(
                                        navigator.context,
                                        loc.getString('error_details'),
                                        loc.getString('decryption_failed'),
                                      ),
                                    ),
                                  ),
                                );
                                return;
                              }
                            }
                            if (!navigator.mounted) return;
                            final ok = await navigator.push<bool>(
                              MaterialPageRoute(
                                builder: (_) =>
                                    RestorePreviewScreen(backupBytes: bytes),
                              ),
                            );
                            if (ok == true && navigator.mounted) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(okText),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            analytics.trackEvent('restore_failed',
                                parameters: {'error': e.toString()});
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(errText),
                                backgroundColor: errorColor,
                                action: SnackBarAction(
                                  label: loc.getString('details'),
                                  onPressed: () => _showErrorDetails(
                                    navigator.context,
                                    loc.getString('error_details'),
                                    e.toString(),
                                  ),
                                ),
                              ),
                            );
                          }
                        },
                      ),
                      _Tile(
                        icon: Icons.delete_forever,
                        title: loc.getString('delete_all_data'),
                        subtitle: loc.getString('delete_all_data_desc'),
                        isDark: isDark,
                        onTap: () async {
                          final title = loc.getString('delete_all_data');
                          final confirmText =
                              loc.getString('delete_all_data_confirm');
                          final deletedText = loc.getString('data_deleted');
                          final analytics = Provider.of<AnalyticsService>(
                              context,
                              listen: false);
                          final messenger = ScaffoldMessenger.of(context);
                          final ok =
                              await _confirm(context, title, confirmText);
                          if (ok) {
                            final prefs =
                                await PreferencesService.getInstance();
                            await prefs.clearAllData();
                            analytics.trackEvent('data_cleared');
                            messenger.showSnackBar(
                                SnackBar(content: Text(deletedText)));
                          }
                        },
                      ),
                    ],
                  ),

                  // Performance
                  _Section(
                    icon: Icons.tune,
                    title: loc.getString('performance_settings'),
                    isDark: isDark,
                    children: [
                      _Tile(
                        icon: Icons.color_lens_outlined,
                        title: loc.getString('theme'),
                        subtitle: isDark
                            ? loc.getString('dark_theme')
                            : loc.getString('light_theme'),
                        isDark: isDark,
                        onTap: () => themeService.toggleTheme(),
                      ),
                      _PerformanceAnimationTile(isDark: isDark),
                      _PerformanceMotionTile(isDark: isDark),
                      _Tile(
                        icon: Icons.cleaning_services,
                        title: loc.getString('clear_cache'),
                        subtitle: loc.getString('cache_management'),
                        isDark: isDark,
                        onTap: () async {
                          final analytics = Provider.of<AnalyticsService>(
                              context,
                              listen: false);
                          analytics.trackEvent('cache_cleared_from_settings');
                          try {
                            await PerformanceOptimizer().clearAllCaches();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text(loc.getString('cache_cleared'))),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text('${loc.getString('error')}: $e'),
                                  backgroundColor:
                                      Theme.of(context).colorScheme.error,
                                ),
                              );
                            }
                          }
                        },
                      ),
                      _Tile(
                        icon: Icons.speed,
                        title: loc.getString('apply_recommended_settings'),
                        subtitle: loc.getString('optimize_for_device'),
                        isDark: isDark,
                        onTap: () async {
                          final analytics = Provider.of<AnalyticsService>(
                              context,
                              listen: false);
                          analytics
                              .trackEvent('performance_optimization_applied');
                          try {
                            await PerformanceOptimizer()
                                .applyRecommendedSettings();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      loc.getString('performance_optimized')),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text('${loc.getString('error')}: $e'),
                                  backgroundColor:
                                      Theme.of(context).colorScheme.error,
                                ),
                              );
                            }
                          }
                        },
                      ),
                      _Tile(
                        icon: Icons.settings_applications,
                        title: loc.getString('advanced_performance'),
                        subtitle:
                            loc.getString('detailed_performance_controls'),
                        isDark: isDark,
                        onTap: () {
                          final analytics = Provider.of<AnalyticsService>(
                              context,
                              listen: false);
                          analytics.trackEvent('performance_screen_opened');
                          Navigator.pushNamed(context, '/performance');
                        },
                      ),
                    ],
                  ),

                  // Legal and about
                  _Section(
                    icon: Icons.description_outlined,
                    title: loc.getString('settings_legal'),
                    isDark: isDark,
                    children: [
                      _Tile(
                        icon: Icons.policy,
                        title:
                            loc.getString('privacy_policy') == 'privacy_policy'
                                ? 'Privacy Policy'
                                : loc.getString('privacy_policy'),
                        subtitle: loc.getString('privacy_policy_desc') ==
                                'privacy_policy_desc'
                            ? 'View our privacy policy'
                            : loc.getString('privacy_policy_desc'),
                        isDark: isDark,
                        onTap: () async {
                          try {
                            final uri =
                                Uri.parse(AppConstants.privacyPolicyUrl);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri,
                                  mode: LaunchMode.externalApplication);
                            } else {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Could not open Privacy Policy')),
                                );
                              }
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        'Error opening Privacy Policy: $e')),
                              );
                            }
                          }
                        },
                      ),
                      _Tile(
                        icon: Icons.gavel,
                        title: loc.getString('terms_of_use') == 'terms_of_use'
                            ? 'Terms of Use'
                            : loc.getString('terms_of_use'),
                        subtitle: loc.getString('terms_of_use_desc') ==
                                'terms_of_use_desc'
                            ? 'View terms and conditions'
                            : loc.getString('terms_of_use_desc'),
                        isDark: isDark,
                        onTap: () async {
                          try {
                            final uri = Uri.parse(AppConstants.termsOfUseUrl);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri,
                                  mode: LaunchMode.externalApplication);
                            } else {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Could not open Terms of Use')),
                                );
                              }
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text('Error opening Terms of Use: $e')),
                              );
                            }
                          }
                        },
                      ),
                      _Tile(
                        icon: Icons.ios_share,
                        title: loc.getString('export_options_title'),
                        subtitle: loc.getString('export_options_subtitle'),
                        isDark: isDark,
                        onTap: () =>
                            Navigator.pushNamed(context, '/export_options'),
                      ),
                      _Tile(
                        icon: Icons.info_outline,
                        title: loc.getString('about_hemoai'),
                        subtitle: loc
                                    .getString('app_description_detailed')
                                    .length >
                                60
                            ? '${loc.getString('app_description_detailed').substring(0, 60)}...'
                            : loc.getString('app_description_detailed'),
                        isDark: isDark,
                        onTap: () => Navigator.pushNamed(context, '/about'),
                      ),
                      _Tile(
                        icon: Icons.medical_information_outlined,
                        title: loc.getString('medical_disclaimer'),
                        subtitle: loc.getString('medical_disclaimer_desc'),
                        isDark: isDark,
                        onTap: () => _openDocument(
                          context,
                          url: AppConstants.medicalDisclaimerUrl,
                          title: loc.getString('medical_disclaimer'),
                          fallbackBody: [
                            loc.getString('medical_disclaimer_body'),
                            loc.getString('medical_consult_prompt'),
                            loc.getString('medical_emergency_cta'),
                          ].join('\n\n'),
                        ),
                      ),
                      _Tile(
                        icon: Icons.support_agent,
                        title: loc.getString('help_support'),
                        subtitle: loc.getString('help_support_desc'),
                        isDark: isDark,
                        onTap: () => _openSupportPortal(context),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  FutureBuilder<PackageInfo>(
                    future: PackageInfo.fromPlatform(),
                    builder: (context, snapshot) {
                      final version = snapshot.data?.version ?? '—';
                      final build = snapshot.data?.buildNumber ?? '—';
                      return Align(
                        alignment: Alignment.center,
                        child: Text(
                          '${loc.getString('app_version')}: $version ($build) • ${loc.getString('release_name')}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _confirmDeleteAccount(BuildContext context) async {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account & Data'),
        content: const Text(
            'This will remove your account and all stored data on this device. This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: cs.error, foregroundColor: cs.onError),
            onPressed: () async {
              try {
                await DatabaseHelper.instance.clearDatabase();
                final prefs = await PreferencesService.getInstance();
                await prefs.clearAllLocal();
              } catch (_) {}
              if (context.mounted) {
                Navigator.pop(ctx);
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/login', (r) => false);
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showInfo(BuildContext context, String title, String body) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(body)),
        actions: [
          Consumer<LocalizationService>(
            builder: (_, loc, __) => TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(loc.getString('close')),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openSupportPortal(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final supportUri = Uri.parse(AppConstants.supportUrl);
    try {
      final launched =
          await launchUrl(supportUri, mode: LaunchMode.externalApplication);
      if (!launched) {
        throw Exception('unable to launch support url');
      }
    } catch (_) {
      final mailUri = Uri(scheme: 'mailto', path: AppConstants.supportEmail);
      if (!await launchUrl(mailUri)) {
        messenger
            .showSnackBar(SnackBar(content: Text(AppConstants.supportEmail)));
      }
    }
  }

  Future<void> _openDocument(
    BuildContext context, {
    required String url,
    required String title,
    required String fallbackBody,
  }) async {
    try {
      final uri = Uri.parse(url);
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (launched) return;
    } catch (_) {
      // Ignore and fallback
    }
    if (!context.mounted) return;
    _showInfo(context, title, fallbackBody);
  }

  void _showErrorDetails(BuildContext context, String title, String details) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(details)),
        actions: [
          Consumer<LocalizationService>(
            builder: (_, loc, __) => TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(loc.getString('close')),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirm(
      BuildContext context, String title, String message) async {
    final loc = Provider.of<LocalizationService>(context, listen: false);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(loc.getString('cancel'))),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(loc.getString('ok'))),
        ],
      ),
    );
    return result ?? false;
  }

  Future<String?> _askPassword(BuildContext context, LocalizationService loc,
      {required bool confirm}) async {
    final controller = TextEditingController();
    final controller2 = TextEditingController();
    String? error;
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(confirm
                  ? loc.getString('set_backup_password')
                  : loc.getString('enter_backup_password')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    obscureText: true,
                    decoration:
                        InputDecoration(labelText: loc.getString('password')),
                  ),
                  if (confirm) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: controller2,
                      obscureText: true,
                      decoration: InputDecoration(
                          labelText: loc.getString('confirm_password')),
                    ),
                  ],
                  if (error != null) ...[
                    const SizedBox(height: 8),
                    Text(error!, style: const TextStyle(color: Colors.red)),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(loc.getString('cancel')),
                ),
                ElevatedButton(
                  onPressed: () {
                    final p1 = controller.text;
                    final p2 = controller2.text;
                    if (confirm && p1 != p2) {
                      setState(
                          () => error = loc.getString('password_mismatch'));
                      return;
                    }
                    Navigator.pop(context, p1);
                  },
                  child: Text(loc.getString('ok')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showUnitSelector(
      BuildContext context, LocalizationService loc, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.getString('health_units_title')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.straighten),
              title: Text(loc.getString('health_units_metric')),
              onTap: () async {
                final prefs = await PreferencesService.getInstance();
                await prefs.saveCustomSettings('health_units', 'metric');
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(loc.getString('done'))),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.straighten),
              title: Text(loc.getString('health_units_imperial')),
              onTap: () async {
                final prefs = await PreferencesService.getInstance();
                await prefs.saveCustomSettings('health_units', 'imperial');
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(loc.getString('done'))),
                  );
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.getString('cancel')),
          ),
        ],
      ),
    );
  }

  void _showFrequencySelector(
      BuildContext context, LocalizationService loc, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.getString('health_test_frequency')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(loc.getString('health_frequency_weekly')),
              onTap: () async {
                final prefs = await PreferencesService.getInstance();
                await prefs.saveCustomSettings(
                    'health_test_frequency', 'weekly');
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(loc.getString('done'))),
                  );
                }
              },
            ),
            ListTile(
              title: Text(loc.getString('health_frequency_monthly')),
              onTap: () async {
                final prefs = await PreferencesService.getInstance();
                await prefs.saveCustomSettings(
                    'health_test_frequency', 'monthly');
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(loc.getString('done'))),
                  );
                }
              },
            ),
            ListTile(
              title: Text(loc.getString('health_frequency_quarterly')),
              onTap: () async {
                final prefs = await PreferencesService.getInstance();
                await prefs.saveCustomSettings(
                    'health_test_frequency', 'quarterly');
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(loc.getString('done'))),
                  );
                }
              },
            ),
            ListTile(
              title: Text(loc.getString('health_frequency_biannual')),
              onTap: () async {
                final prefs = await PreferencesService.getInstance();
                await prefs.saveCustomSettings(
                    'health_test_frequency', 'biannual');
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(loc.getString('done'))),
                  );
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.getString('cancel')),
          ),
        ],
      ),
    );
  }

  void _showRetentionSelector(
      BuildContext context, LocalizationService loc, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.getString('health_data_retention')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(loc.getString('health_retention_1_year')),
              onTap: () async {
                final prefs = await PreferencesService.getInstance();
                await prefs.saveCustomSettings(
                    'health_data_retention', '1_year');
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(loc.getString('done'))),
                  );
                }
              },
            ),
            ListTile(
              title: Text(loc.getString('health_retention_3_years')),
              onTap: () async {
                final prefs = await PreferencesService.getInstance();
                await prefs.saveCustomSettings(
                    'health_data_retention', '3_years');
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(loc.getString('done'))),
                  );
                }
              },
            ),
            ListTile(
              title: Text(loc.getString('health_retention_unlimited')),
              onTap: () async {
                final prefs = await PreferencesService.getInstance();
                await prefs.saveCustomSettings(
                    'health_data_retention', 'unlimited');
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(loc.getString('done'))),
                  );
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.getString('cancel')),
          ),
        ],
      ),
    );
  }

  void _showSharingOptions(
      BuildContext context, LocalizationService loc, bool isDark) {
    _showInfo(
      context,
      loc.getString('health_sharing'),
      loc.getString('coming_soon'),
    );
  }

  void _showReferenceRanges(
      BuildContext context, LocalizationService loc, bool isDark) {
    _showInfo(
      context,
      loc.getString('health_reference_ranges'),
      loc.getString('coming_soon'),
    );
  }

  void _showBloodTypeSelector(
      BuildContext context, LocalizationService loc, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.getString('health_blood_type')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('A+'),
              onTap: () async {
                final prefs = await PreferencesService.getInstance();
                await prefs.saveCustomSettings('health_blood_type', 'A+');
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(loc.getString('done'))),
                  );
                }
              },
            ),
            ListTile(
              title: const Text('A-'),
              onTap: () async {
                final prefs = await PreferencesService.getInstance();
                await prefs.saveCustomSettings('health_blood_type', 'A-');
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(loc.getString('done'))),
                  );
                }
              },
            ),
            ListTile(
              title: const Text('B+'),
              onTap: () async {
                final prefs = await PreferencesService.getInstance();
                await prefs.saveCustomSettings('health_blood_type', 'B+');
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(loc.getString('done'))),
                  );
                }
              },
            ),
            ListTile(
              title: const Text('B-'),
              onTap: () async {
                final prefs = await PreferencesService.getInstance();
                await prefs.saveCustomSettings('health_blood_type', 'B-');
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(loc.getString('done'))),
                  );
                }
              },
            ),
            ListTile(
              title: const Text('AB+'),
              onTap: () async {
                final prefs = await PreferencesService.getInstance();
                await prefs.saveCustomSettings('health_blood_type', 'AB+');
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(loc.getString('done'))),
                  );
                }
              },
            ),
            ListTile(
              title: const Text('AB-'),
              onTap: () async {
                final prefs = await PreferencesService.getInstance();
                await prefs.saveCustomSettings('health_blood_type', 'AB-');
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(loc.getString('done'))),
                  );
                }
              },
            ),
            ListTile(
              title: const Text('O+'),
              onTap: () async {
                final prefs = await PreferencesService.getInstance();
                await prefs.saveCustomSettings('health_blood_type', 'O+');
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(loc.getString('done'))),
                  );
                }
              },
            ),
            ListTile(
              title: const Text('O-'),
              onTap: () async {
                final prefs = await PreferencesService.getInstance();
                await prefs.saveCustomSettings('health_blood_type', 'O-');
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(loc.getString('done'))),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showReportFormatSelector(
      BuildContext context, LocalizationService loc, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.getString('health_report_format')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('PDF'),
              leading: const Icon(Icons.picture_as_pdf),
              onTap: () async {
                final prefs = await PreferencesService.getInstance();
                await prefs.saveCustomSettings('health_report_format', 'pdf');
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(loc.getString('done'))),
                  );
                }
              },
            ),
            ListTile(
              title: const Text('Excel'),
              leading: const Icon(Icons.table_chart),
              onTap: () async {
                final prefs = await PreferencesService.getInstance();
                await prefs.saveCustomSettings('health_report_format', 'excel');
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(loc.getString('done'))),
                  );
                }
              },
            ),
            ListTile(
              title: const Text('JSON'),
              leading: const Icon(Icons.code),
              onTap: () async {
                final prefs = await PreferencesService.getInstance();
                await prefs.saveCustomSettings('health_report_format', 'json');
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(loc.getString('done'))),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // Auto Backup Methods
  void _showBackupIntervalSelector(
      BuildContext context, LocalizationService loc, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.getString('backup_interval')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Every 1 hour'),
              onTap: () async {
                final autoBackup = AutoBackupService();
                await autoBackup.setBackupInterval(1);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(loc.getString('done'))),
                  );
                }
              },
            ),
            ListTile(
              title: const Text('Every 6 hours'),
              onTap: () async {
                final autoBackup = AutoBackupService();
                await autoBackup.setBackupInterval(6);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(loc.getString('done'))),
                  );
                }
              },
            ),
            ListTile(
              title: const Text('Every 12 hours'),
              onTap: () async {
                final autoBackup = AutoBackupService();
                await autoBackup.setBackupInterval(12);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(loc.getString('done'))),
                  );
                }
              },
            ),
            ListTile(
              title: const Text('Every 24 hours'),
              onTap: () async {
                final autoBackup = AutoBackupService();
                await autoBackup.setBackupInterval(24);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(loc.getString('done'))),
                  );
                }
              },
            ),
            ListTile(
              title: const Text('Every 7 days'),
              onTap: () async {
                final autoBackup = AutoBackupService();
                await autoBackup.setBackupInterval(168); // 7 days = 168 hours
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(loc.getString('done'))),
                  );
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.getString('cancel')),
          ),
        ],
      ),
    );
  }

  Future<void> _triggerManualBackup(
      BuildContext context, LocalizationService loc) async {
    final password = await _askPassword(context, loc, confirm: false);
    if (password == null || password.isEmpty) return;

    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final autoBackup = AutoBackupService();
      final success = await autoBackup.backupNow(password);

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? loc.getString('export_success')
                : loc.getString('export_failed')),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${loc.getString('error')}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _triggerCloudRestore(
      BuildContext context, LocalizationService loc) async {
    final password = await _askPassword(context, loc, confirm: false);
    if (password == null || password.isEmpty) return;

    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final cloudSync = CloudSyncService();
      await cloudSync.signInAnonymously();
      final success =
          await cloudSync.restoreLatest(password, strategy: 'merge');

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? loc.getString('export_success')
                : loc.getString('export_failed')),
            backgroundColor: success ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${loc.getString('error')}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _Header extends StatelessWidget {
  final bool isDark;
  final String title;
  final String subtitle;
  const _Header(
      {required this.isDark, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF30363D) : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;
  final bool isDark;
  const _Section(
      {required this.icon,
      required this.title,
      required this.children,
      required this.isDark});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF21262D) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF30363D) : Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE53E3E).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFFE53E3E),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Semantics(
                header: true,
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDark;
  const _Tile(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.onTap,
      required this.isDark});
  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: title,
      hint: subtitle,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF30363D) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF30363D) : Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE53E3E).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: const Color(0xFFE53E3E),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SwitchTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String prefKey;
  final ValueChanged<bool>? onChanged;
  final bool isDark;
  const _SwitchTile(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.prefKey,
      this.onChanged,
      required this.isDark});
  @override
  State<_SwitchTile> createState() => _SwitchTileState();
}

class _SwitchTileState extends State<_SwitchTile> {
  bool _value = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await PreferencesService.getInstance();
    setState(() {
      _value = prefs.getCustomSetting<bool>(widget.prefKey) ?? false;
      _loaded = true;
    });
  }

  Future<void> _toggle(bool v) async {
    final prefs = await PreferencesService.getInstance();
    await prefs.saveCustomSettings(widget.prefKey, v);
    if (mounted) setState(() => _value = v);
    // Side-effect callback (e.g., analytics opt-in)
    widget.onChanged?.call(v);
  }

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Semantics(
        container: true,
        label: widget.title,
        hint: widget.subtitle,
        toggled: _value,
        enabled: _loaded,
        onTap: _loaded ? () => _toggle(!_value) : null,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color:
                widget.isDark ? const Color(0xFF30363D) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isDark
                  ? const Color(0xFF30363D)
                  : Colors.grey.shade200,
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _loaded ? () => _toggle(!_value) : null,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE53E3E).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        widget.icon,
                        color: const Color(0xFFE53E3E),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color:
                                  widget.isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.subtitle,
                            style: TextStyle(
                              fontSize: 13,
                              color: widget.isDark
                                  ? Colors.white60
                                  : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _value,
                      onChanged: _loaded ? _toggle : null,
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
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PerformanceAnimationTile extends StatefulWidget {
  final bool isDark;
  const _PerformanceAnimationTile({required this.isDark});
  @override
  State<_PerformanceAnimationTile> createState() =>
      _PerformanceAnimationTileState();
}

class _PerformanceAnimationTileState extends State<_PerformanceAnimationTile> {
  bool _value = true;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final enabled = await PerformanceOptimizer().areAnimationsEnabled();
    if (mounted) {
      setState(() {
        _value = enabled;
        _loaded = true;
      });
    }
  }

  Future<void> _toggle(bool v) async {
    await PerformanceOptimizer().setAnimationsEnabled(v);
    if (mounted) setState(() => _value = v);
  }

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LocalizationService>(context, listen: false);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF30363D) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isDark ? const Color(0xFF30363D) : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _loaded ? () => _toggle(!_value) : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53E3E).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.animation,
                    color: Color(0xFFE53E3E),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.getString('enable_animations'),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: widget.isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _value,
                  onChanged: _loaded ? _toggle : null,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChallengeSwitchTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Future<bool> Function() getValue;
  final Future<void> Function(bool) setValue;
  final bool isDark;
  const _ChallengeSwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.getValue,
    required this.setValue,
    required this.isDark,
  });

  @override
  State<_ChallengeSwitchTile> createState() => _ChallengeSwitchTileState();
}

class _ChallengeSwitchTileState extends State<_ChallengeSwitchTile> {
  bool _value = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final v = await widget.getValue();
    if (mounted) {
      setState(() {
        _value = v;
        _loaded = true;
      });
    }
  }

  Future<void> _toggle(bool v) async {
    await widget.setValue(v);
    if (mounted) {
      setState(() => _value = v);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isDark ? const Color(0xFF30363D) : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _loaded ? () => _toggle(!_value) : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.isDark
                        ? const Color(0xFF30363D)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    widget.icon,
                    color: widget.isDark ? Colors.white70 : Colors.black87,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: widget.isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              widget.isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _value,
                  onChanged: _loaded ? _toggle : null,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PerformanceMotionTile extends StatefulWidget {
  final bool isDark;
  const _PerformanceMotionTile({required this.isDark});
  @override
  State<_PerformanceMotionTile> createState() => _PerformanceMotionTileState();
}

class _PerformanceMotionTileState extends State<_PerformanceMotionTile> {
  bool _value = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final reduce = await PerformanceOptimizer().shouldReduceMotion();
    if (mounted) {
      setState(() {
        _value = reduce;
        _loaded = true;
      });
    }
  }

  Future<void> _toggle(bool v) async {
    await PerformanceOptimizer().setReduceMotion(v);
    if (mounted) setState(() => _value = v);
  }

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LocalizationService>(context, listen: false);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF30363D) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isDark ? const Color(0xFF30363D) : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _loaded ? () => _toggle(!_value) : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53E3E).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.accessibility,
                    color: Color(0xFFE53E3E),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.getString('reduce_motion'),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: widget.isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        loc.getString('auto_optimize'),
                        style: TextStyle(
                          fontSize: 13,
                          color:
                              widget.isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _value,
                  onChanged: _loaded ? _toggle : null,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
