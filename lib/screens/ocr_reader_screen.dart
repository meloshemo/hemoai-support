import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/localization_service.dart';
import 'data_import_screen.dart';

/// OCR Reader Screen - redirects to Data Import's OCR feature
/// This is a better UX than showing a placeholder
class OcrReaderScreen extends StatelessWidget {
  const OcrReaderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Redirect to Data Import screen with OCR focus
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const DataImportScreen(),
          ),
        );
      }
    });

    // Show loading during redirect
    return Consumer<LocalizationService>(
      builder: (context, loc, child) => Scaffold(
        appBar: AppBar(
          title: Text('${loc.getString('loading')} OCR...'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}

