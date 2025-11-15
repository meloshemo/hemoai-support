import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/localization_service.dart';
import '../../services/preferences_service.dart';
import '../../utils/app_constants.dart';
import '../../widgets/medical_disclaimer_banner.dart';

class MedicalConsentScreen extends StatefulWidget {
  const MedicalConsentScreen({super.key});

  @override
  State<MedicalConsentScreen> createState() => _MedicalConsentScreenState();
}

class _MedicalConsentScreenState extends State<MedicalConsentScreen> {
  bool _accepted = false;
  bool _saving = false;
  String? _nextRoute;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args['nextRoute'] is String) {
      _nextRoute = args['nextRoute'] as String;
    }
  }

  Future<void> _openExternalUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      final loc = Provider.of<LocalizationService>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.getString('open_link_failed'))),
      );
    }
  }

  Future<void> _complete() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final prefs = await PreferencesService.getInstance();
      await prefs.setMedicalConsentAccepted(true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Provider.of<LocalizationService>(context, listen: false)
                .getString('medical_consent_saved'),
          ),
        ),
      );
      final target = _nextRoute ?? '/dashboard';
      Navigator.of(context).pushReplacementNamed(target);
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LocalizationService>(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.getString('medical_consent_title')),
        automaticallyImplyLeading: Navigator.of(context).canPop(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const MedicalDisclaimerBanner(
                margin: EdgeInsets.only(bottom: 20),
              ),
              Text(
                loc.getString('medical_consent_intro'),
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.8),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              _ConsentBullet(text: loc.getString('medical_consent_point_clinical')),
              _ConsentBullet(text: loc.getString('medical_consent_point_emergency')),
              _ConsentBullet(text: loc.getString('medical_consent_point_privacy')),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  TextButton.icon(
                    onPressed: () => _openExternalUrl(AppConstants.termsOfUseUrl),
                    icon: const Icon(Icons.gavel_outlined),
                    label: Text(loc.getString('medical_consent_view_terms')),
                  ),
                  TextButton.icon(
                    onPressed: () => _openExternalUrl(AppConstants.privacyPolicyUrl),
                    icon: const Icon(Icons.privacy_tip_outlined),
                    label: Text(loc.getString('medical_consent_view_privacy')),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: _accepted,
                onChanged: (value) => setState(() => _accepted = value ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: Text(loc.getString('medical_consent_checkbox')),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                width: double.infinity,
                child: FilledButton(
                  onPressed: !_accepted || _saving ? null : _complete,
                  child: _saving
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: scheme.onPrimary,
                          ),
                        )
                      : Text(loc.getString('medical_consent_accept')),
                ),
              ),
              if (Navigator.of(context).canPop()) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _saving ? null : () => Navigator.of(context).maybePop(),
                  child: Text(loc.getString('medical_consent_cancel')),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ConsentBullet extends StatelessWidget {
  const _ConsentBullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline, color: scheme.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.75),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


