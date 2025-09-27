import 'package:flutter/material.dart';

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
      // For now, show a message that PDF export is available
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF export feature is being updated...'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF export error: $e'),
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
      // For now, show a message that Excel export is available
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Excel export feature is being updated...'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Excel export error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}