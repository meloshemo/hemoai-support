import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
// import '../services/database_helper.dart';
import '../services/notification_service.dart';
import '../services/localization_service.dart';

// Export Service for PDF and Excel generation
class ExportService {
  static final ExportService _instance = ExportService._internal();
  factory ExportService() => _instance;
  ExportService._internal();

  // Export hemogram results as PDF
  Future<bool> exportHemogramToPdf({
    required Map<String, double> hemogramValues,
    required String patientName,
    required String testDate,
    String? doctorNotes,
  }) async {
    try {
      final pdfBytes = await _generateHemogramPdf(
        hemogramValues: hemogramValues,
        patientName: patientName,
        testDate: testDate,
        doctorNotes: doctorNotes,
      );

      if (kIsWeb) {
        _downloadWebFileBinary(
          bytes: pdfBytes,
          filename: '${LocalizationService.translate('hemogram_report').toLowerCase().replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf',
          contentType: 'application/pdf',
        );
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('PDF export error: $e');
      }
      return false;
    }
  }

  // Export hemogram results as Excel
  Future<bool> exportHemogramToExcel({
    required Map<String, double> hemogramValues,
    required String patientName,
    required String testDate,
    List<Map<String, dynamic>>? historicalData,
  }) async {
    try {
      final excelContent = _generateHemogramExcelContent(
        hemogramValues: hemogramValues,
        patientName: patientName,
        testDate: testDate,
        historicalData: historicalData,
      );

      if (kIsWeb) {
        _downloadWebFile(
          content: excelContent,
          filename: '${LocalizationService.translate('hemogram_data_filename_prefix').toLowerCase().replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.csv',
          contentType: 'text/csv',
        );
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Excel export error: $e');
      }
      return false;
    }
  }

  // Export analysis report as PDF
  Future<bool> exportAnalysisReportToPdf({
    required Map<String, double> hemogramValues,
    required String patientName,
    required String analysisResult,
    required List<String> recommendations,
    required String riskLevel,
  }) async {
    try {
      final pdfContent = _generateAnalysisReportPdfContent(
        hemogramValues: hemogramValues,
        patientName: patientName,
        analysisResult: analysisResult,
        recommendations: recommendations,
        riskLevel: riskLevel,
      );

      if (kIsWeb) {
        _downloadWebFile(
          content: pdfContent,
          filename: '${LocalizationService.translate('analysis_report').toLowerCase().replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf',
          contentType: 'application/pdf',
        );
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Analysis PDF export error: $e');
      }
      return false;
    }
  }

  // Export reminders as Excel
  Future<bool> exportRemindersToExcel({
    required List<NotificationItem> reminders,
    required String patientName,
  }) async {
    try {
      final excelContent = _generateRemindersExcelContent(
        reminders: reminders,
        patientName: patientName,
      );

      if (kIsWeb) {
        _downloadWebFile(
          content: excelContent,
          filename: '${LocalizationService.translate('reminders').toLowerCase().replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.csv',
          contentType: 'text/csv',
        );
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Reminders Excel export error: $e');
      }
      return false;
    }
  }

  // Generate comprehensive health report
  Future<bool> exportComprehensiveReport({
    required String patientName,
    required Map<String, double> latestHemogram,
    required List<Map<String, dynamic>> historicalData,
    required List<NotificationItem> reminders,
    required String analysisResult,
    required List<String> recommendations,
  }) async {
    try {
      final reportContent = _generateComprehensiveReportContent(
        patientName: patientName,
        latestHemogram: latestHemogram,
        historicalData: historicalData,
        reminders: reminders,
        analysisResult: analysisResult,
        recommendations: recommendations,
      );

      if (kIsWeb) {
        _downloadWebFile(
          content: reportContent,
          filename: '${LocalizationService.translate('comprehensive_health_report').toLowerCase().replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf',
          contentType: 'application/pdf',
        );
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Comprehensive report export error: $e');
      }
      return false;
    }
  }

  // Generate Hemogram PDF Content (Simulated)
  Future<Uint8List> _generateHemogramPdf({
    required Map<String, double> hemogramValues,
    required String patientName,
    required String testDate,
    String? doctorNotes,
  }) async {
    final pdf = pw.Document();
    
    final referenceRanges = {
      'wbc': {
        'min': 4000.0,
        'max': 11000.0,
        'name': LocalizationService.translate('param_wbc'),
        'unit': 'K/uL'
      },
      'rbc': {
        'min': 4.2,
        'max': 5.4,
        'name': LocalizationService.translate('param_rbc'),
        'unit': 'M/uL'
      },
      'hgb': {
        'min': 12.0,
        'max': 17.0,
        'name': LocalizationService.translate('param_hgb'),
        'unit': 'g/dL'
      },
      'hct': {
        'min': 35.0,
        'max': 50.0,
        'name': LocalizationService.translate('param_hct'),
        'unit': '%'
      },
      'mcv': {
        'min': 80.0,
        'max': 100.0,
        'name': LocalizationService.translate('param_mcv'),
        'unit': 'fL'
      },
      'mch': {
        'min': 27.0,
        'max': 32.0,
        'name': LocalizationService.translate('param_mch'),
        'unit': 'pg'
      },
      'mchc': {
        'min': 32.0,
        'max': 36.0,
        'name': LocalizationService.translate('param_mchc'),
        'unit': 'g/dL'
      },
      'rdw': {
        'min': 11.5,
        'max': 14.5,
        'name': LocalizationService.translate('param_rdw'),
        'unit': '%'
      },
      'plt': {
        'min': 150000.0,
        'max': 450000.0,
        'name': LocalizationService.translate('param_plt'),
        'unit': 'K/uL'
      },
      'mpv': {
        'min': 7.0,
        'max': 11.0,
        'name': LocalizationService.translate('param_mpv'),
        'unit': 'fL'
      },
    };

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            // Header
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                border: pw.Border.all(color: PdfColors.blue200),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    LocalizationService.translate('hemogram_report'),
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue800,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    '${LocalizationService.translate('patient_name')}: $patientName',
                    style: const pw.TextStyle(fontSize: 14),
                  ),
                  pw.Text(
                    '${LocalizationService.translate('test_date')}: $testDate',
                    style: const pw.TextStyle(fontSize: 14),
                  ),
                  pw.Text(
                    '${LocalizationService.translate('report_date')}: ${LocalizationService().formatDate(DateTime.now())}',
                    style: const pw.TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            
            pw.SizedBox(height: 30),
            
            // Test Results Header
            pw.Text(
              LocalizationService.translate('test_results'),
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey800,
              ),
            ),
            
            pw.SizedBox(height: 15),
            
            // Results Table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(3),
                3: const pw.FlexColumnWidth(2),
              },
              children: [
                // Table Header
                pw.TableRow(
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.grey200,
                  ),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        LocalizationService.translate('parameter'),
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        LocalizationService.translate('result'),
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        LocalizationService.translate('reference_range'),
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        LocalizationService.translate('status'),
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                
                // Data Rows
                ...hemogramValues.entries.map((entry) {
                  final key = entry.key;
                  final value = entry.value;
                  final range = referenceRanges[key];
                  
                  String status = LocalizationService.translate('normal_status');
                  PdfColor statusColor = PdfColors.green;
                  
                  if (range != null) {
                    double minValue = (range['min'] as num).toDouble();
                    double maxValue = (range['max'] as num).toDouble();
                    if (value < minValue) {
                      status = LocalizationService.translate('low');
                      statusColor = PdfColors.blue;
                    } else if (value > maxValue) {
                      status = LocalizationService.translate('high_status');
                      statusColor = PdfColors.red;
                    }
                  }
                  
                  return pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          '${range?['name'] ?? key} (${range?['unit'] ?? ''})',
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          value.toString(),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          range != null ? '${(range['min'] as num).toStringAsFixed(1)} - ${(range['max'] as num).toStringAsFixed(1)}' : '-',
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          status,
                          style: pw.TextStyle(
                            color: statusColor,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
            
            pw.SizedBox(height: 30),
            
            // Doctor Notes
            if (doctorNotes != null && doctorNotes.isNotEmpty) ...[
              pw.Text(
                LocalizationService.translate('notes'),
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Text(
                  doctorNotes,
                  style: const pw.TextStyle(fontSize: 12),
                ),
              ),
              pw.SizedBox(height: 20),
            ],
            
            // Footer
            pw.Container(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                '${LocalizationService.translate('generated_by')} HemoAI',
                style: pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey600,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  // Helper methods for simple functionality
  String _generateHemogramExcelContent({
    required Map<String, double> hemogramValues,
    required String patientName,
    required String testDate,
    List<Map<String, dynamic>>? historicalData,
  }) {
    return 'Simple Excel content for $patientName';
  }

  String _generateAnalysisReportPdfContent({
    required Map<String, double> hemogramValues,
    required String patientName,
    required String analysisResult,
    required List<String> recommendations,
    required String riskLevel,
  }) {
    return 'Analysis report for $patientName';
  }

  String _generateRemindersExcelContent({
    required List<NotificationItem> reminders,
    required String patientName,
  }) {
    return 'Reminders for $patientName';
  }

  String _generateComprehensiveReportContent({
    required String patientName,
    required Map<String, double> latestHemogram,
    required List<Map<String, dynamic>> historicalData,
    required List<NotificationItem> reminders,
    required String analysisResult,
    required List<String> recommendations,
  }) {
    return 'Comprehensive report for $patientName';
  }

  void _downloadWebFile({
    required String content,
    required String filename,
    required String contentType,
  }) {
    // No-op on non-web. On web this will be replaced by proper implementation.
    if (!kIsWeb) {
      if (kDebugMode) {
        print('Download ($filename) skipped: not running on web.');
      }
    } else {
      // Web implementation moved out to avoid dart:html import on desktop.
      if (kDebugMode) {
        print('Web download logic not implemented in this build context.');
      }
    }
  }

  void _downloadWebFileBinary({
    required Uint8List bytes,
    required String filename,
    required String contentType,
  }) {
    if (!kIsWeb) {
      if (kDebugMode) {
        print('Binary download ($filename) skipped: not running on web.');
      }
    } else {
      if (kDebugMode) {
        print('Web binary download logic not implemented in this build context.');
      }
    }
  }
}

