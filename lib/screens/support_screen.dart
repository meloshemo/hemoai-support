import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/localization_service.dart';
import '../services/premium_service.dart';
import '../utils/subscription_helper.dart';
import '../utils/app_constants.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LocalizationService>(context);
    final premium = Provider.of<PremiumService>(context, listen: false);

    final email = AppConstants.supportEmail;
    final portal = AppConstants.supportUrl;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.getString('support_center_title')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            loc.getString('support_overview'),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),

          // SLA
          _Section(
            icon: Icons.schedule,
            title: loc.getString('support_sla_title'),
            child: Text(loc.getString('support_sla_body')),
          ),

          // Onboarding quick steps
          _Section(
            icon: Icons.rocket_launch_outlined,
            title: loc.getString('onboarding_section_title'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: loc
                  .getString('onboarding_quick_steps')
                  .split('\n')
                  .map((e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• '),
                            Expanded(child: Text(e)),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),

          // FAQ
          _Section(
            icon: Icons.help_outline,
            title: loc.getString('faq_section_title'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(loc.getString('faq_section_intro')),
                ),
                ...loc
                    .getString('faq_entries')
                    .split('\n')
                    .map((e) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• '),
                              Expanded(child: Text(e)),
                            ],
                          ),
                        ))
                    ,
              ],
            ),
          ),

          // Subscription management
          _Section(
            icon: Icons.manage_accounts_outlined,
            title: loc.getString('subscription_management_title'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Builder(builder: (context) {
                  final expiry = premium.subscriptionExpiry;
                  final status = premium.isPremium && !premium.isSubscriptionExpired
                      ? loc.getStringWithParams('premium_status_active', {
                          'date': expiry != null ? loc.formatDate(expiry) : '-'
                        })
                      : loc.getString('premium_status_expired');
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(status),
                  );
                }),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(loc.getString('subscription_cancel_steps')),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton.icon(
                    onPressed: () => SubscriptionHelper.openManagePage(context),
                    icon: const Icon(Icons.open_in_new),
                    label: Text(loc.getString('open_subscription_management')),
                  ),
                ),
              ],
            ),
          ),

          // Refund policy
          _Section(
            icon: Icons.receipt_long_outlined,
            title: loc.getString('refund_policy_title'),
            child: Text(loc.getString('refund_policy_overview')),
          ),

          // Contact
          _Section(
            icon: Icons.support_agent_outlined,
            title: loc.getString('support_contact'),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    final uri = Uri.parse(portal);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  icon: const Icon(Icons.open_in_new),
                  label: Text(loc.getString('open_support_portal')),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    final uri = Uri(scheme: 'mailto', path: email);
                    await launchUrl(uri);
                  },
                  icon: const Icon(Icons.email_outlined),
                  label: Text('${loc.getString('support_email')}: $email'),
                ),
              ],
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
  final Widget child;

  const _Section({required this.icon, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
