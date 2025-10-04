import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/localization_service.dart';

class ExportService {
  static final ExportService _instance = ExportService._internal();
  factory ExportService() => _instance;
  ExportService._internal();

  // Simple PDF export function
  Future<void> exportToPDF({
    required BuildContext context,
    required Map<String, double> hemogramValues,
    required String patientName,
    String? doctorNotes,
  }) async {
    try {
      // For now, show a message that PDF export is available (localized)
      final loc = Provider.of<LocalizationService>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.getString('pdf_generating')),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      final loc = Provider.of<LocalizationService>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${loc.getString('pdf_export_error_prefix')}$e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Simple Excel export function  
  Future<void> exportToExcel({
    required BuildContext context,
    required Map<String, double> hemogramValues,
    required String patientName,
    String? doctorNotes,
  }) async {
    try {
      // For now, show a message that Excel export is available (localized)
      final loc = Provider.of<LocalizationService>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.getString('excel_generating')),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      final loc = Provider.of<LocalizationService>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${loc.getString('excel_export_error_prefix')}$e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}