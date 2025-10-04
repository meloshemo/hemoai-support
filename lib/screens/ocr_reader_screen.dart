import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/localization_service.dart';

// Safe placeholder screen: legacy OCR is embedded in Hemogram Entry now.
// This avoids platform-specific imports and is web-friendly.
class OcrReaderScreen extends StatelessWidget {
  const OcrReaderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final loc = Provider.of<LocalizationService>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.getString('ocr_reader') == 'ocr_reader' ? 'OCR Reader' : loc.getString('ocr_reader')),
      ),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.document_scanner, size: 40, color: scheme.primary),
              const SizedBox(height: 12),
              Text(
                loc.getString('ocr_desktop_placeholder') == 'ocr_desktop_placeholder'
                    ? 'OCR is available inside Hemogram Entry on supported devices.'
                    : loc.getString('ocr_desktop_placeholder'),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

