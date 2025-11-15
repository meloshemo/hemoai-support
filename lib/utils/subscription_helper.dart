import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../services/localization_service.dart';

class SubscriptionHelper {
  static Future<void> openManagePage(BuildContext context) async {
    final loc = Provider.of<LocalizationService>(context, listen: false);

    Uri? uri;
    if (!kIsWeb) {
      try {
        if (Platform.isAndroid) {
          // Generic subscriptions page
          uri = Uri.parse('https://play.google.com/store/account/subscriptions');
        } else if (Platform.isIOS) {
          // App Store subscriptions management
          uri = Uri.parse('https://apps.apple.com/account/subscriptions');
        } else {
          uri = null; // Fall through to unsupported
        }
      } catch (_) {
        uri = null;
      }
    }

    if (uri != null) {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }

    // Fallback: show info
    final message = loc.getString('manage_subscription_not_available');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }
}
