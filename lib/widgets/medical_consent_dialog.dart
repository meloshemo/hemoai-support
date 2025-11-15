import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/localization_service.dart';
import 'medical_disclaimer_banner.dart';

Future<bool> showMedicalConsentDialog(BuildContext context) async {
  final loc = Provider.of<LocalizationService>(context, listen: false);
  bool accepted = false;

  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            title: Text(loc.getString('medical_consent_dialog_title')),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.getString('medical_consent_dialog_body'),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
                  const MedicalDisclaimerBanner(padding: EdgeInsets.all(12)),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    value: accepted,
                    onChanged: (value) {
                      setState(() => accepted = value ?? false);
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    title: Text(loc.getString('medical_consent_checkbox')),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(loc.getString('medical_consent_decline')),
              ),
              FilledButton(
                onPressed: accepted
                    ? () => Navigator.of(dialogContext).pop(true)
                    : null,
                child: Text(loc.getString('medical_consent_accept')),
              ),
            ],
          );
        },
      );
    },
  );

  return result ?? false;
}
