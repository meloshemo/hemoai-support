import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
// import '../services/database_helper.dart';
import '../services/notification_service.dart';
import '../services/localization_service.dart';
import '../models/diet_program.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
// Conditional import for web HTML support
import 'export_service_web_stub.dart' if (dart.library.html) 'export_service_web_impl.dart';
import 'dart:typed_data';
import 'package:open_filex/open_filex.dart';
import '../services/diet_menu_service.dart';

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
      } else if (Platform.isIOS) {
        final name = '${LocalizationService.translate('hemogram_report').toLowerCase().replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
        final xfile = XFile.fromData(pdfBytes, name: name, mimeType: 'application/pdf');
        await Share.shareXFiles([xfile], text: LocalizationService.translate('hemogram_report'));
      } else if (Platform.isAndroid) {
        final savedPath = await _savePdfToDocuments(bytes: pdfBytes, filenamePrefix: LocalizationService.translate('hemogram_report').toLowerCase().replaceAll(' ', '_'));
        await OpenFilex.open(savedPath);
      } else {
        // Desktop: save to Documents/HemoAI and open
        final savedPath = await _savePdfToDocuments(bytes: pdfBytes, filenamePrefix: LocalizationService.translate('hemogram_report').toLowerCase().replaceAll(' ', '_'));
        await OpenFilex.open(savedPath);
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
    debugPrint('PDF export error: $e');
      }
      return false;
    }
  }

  // Export Diet Programs as PDF
  Future<bool> exportDietProgramsToPdf({
    required List<DietProgram> programs,
  }) async {
    try {
      final pdfBytes = await _generateDietProgramsPdf(programs: programs);
      if (kIsWeb) {
        _downloadWebFileBinary(
          bytes: pdfBytes,
          filename: 'diet_programs_${DateTime.now().millisecondsSinceEpoch}.pdf',
          contentType: 'application/pdf',
        );
      } else if (Platform.isIOS) {
        final name = 'diet_programs_${DateTime.now().millisecondsSinceEpoch}.pdf';
        final xfile = XFile.fromData(pdfBytes, name: name, mimeType: 'application/pdf');
        await Share.shareXFiles([xfile], text: LocalizationService.translate('export_pdf'));
      } else if (Platform.isAndroid) {
        final savedPath = await _savePdfToDocuments(bytes: pdfBytes, filenamePrefix: 'diet_programs');
        await OpenFilex.open(savedPath);
      } else {
        final savedPath = await _savePdfToDocuments(bytes: pdfBytes, filenamePrefix: 'diet_programs');
        await OpenFilex.open(savedPath);
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
    debugPrint('Diet PDF export error: $e');
      }
      return false;
    }
  }

  // Export Weekly Diet Plan as PDF (7 days + progress)
  Future<bool> exportWeeklyDietPlanToPdf({
    required List<DietProgram> weeklyPlan7, // length 7
    required int daysCompleted, // 0..7
    required int weeksCompleted, // total historical weeks completed
  }) async {
    try {
      if (weeklyPlan7.isEmpty) return false;
      final bytes = await _generateWeeklyDietPlanPdf(
        weeklyPlan7: weeklyPlan7,
        daysCompleted: daysCompleted,
        weeksCompleted: weeksCompleted,
      );
      if (kIsWeb) {
        _downloadWebFileBinary(
          bytes: bytes,
          filename: 'weekly_diet_plan_${DateTime.now().millisecondsSinceEpoch}.pdf',
          contentType: 'application/pdf',
        );
      } else if (Platform.isIOS) {
        final name = 'weekly_diet_plan_${DateTime.now().millisecondsSinceEpoch}.pdf';
        final xfile = XFile.fromData(bytes, name: name, mimeType: 'application/pdf');
        await Share.shareXFiles([xfile], text: LocalizationService.translate('weekly_plan'));
      } else if (Platform.isAndroid) {
        final savedPath = await _savePdfToDocuments(bytes: bytes, filenamePrefix: 'weekly_diet_plan');
        await OpenFilex.open(savedPath);
      } else {
        final savedPath = await _savePdfToDocuments(bytes: bytes, filenamePrefix: 'weekly_diet_plan');
        await OpenFilex.open(savedPath);
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
    debugPrint('Weekly plan PDF export error: $e');
      }
      return false;
    }
  }

  // Share Diet Programs PDF (placeholder implementation for desktop/web)
  Future<bool> shareDietProgramsPdf({
    required List<DietProgram> programs,
  }) async {
    try {
      final bytes = await _generateDietProgramsPdf(programs: programs);
      if (kIsWeb) {
        _downloadWebFileBinary(
          bytes: bytes,
          filename: 'diet_programs_${DateTime.now().millisecondsSinceEpoch}.pdf',
          contentType: 'application/pdf',
        );
        return true;
      }
      // iOS share, Android/Desktop: save+open
      if (Platform.isIOS) {
        final name = 'diet_programs_${DateTime.now().millisecondsSinceEpoch}.pdf';
        final xfile = XFile.fromData(bytes, name: name, mimeType: 'application/pdf');
        await Share.shareXFiles([xfile], text: LocalizationService.translate('diet_programs'));
      } else if (Platform.isAndroid) {
        final savedPath = await _savePdfToDocuments(bytes: bytes, filenamePrefix: 'diet_programs');
        await OpenFilex.open(savedPath);
      } else {
        final savedPath = await _savePdfToDocuments(bytes: bytes, filenamePrefix: 'diet_programs');
        await OpenFilex.open(savedPath);
      }
      return true;
    } catch (e) {
      // Web fallback: try download if share API not available
      if (kIsWeb) {
        try {
          final bytes = await _generateDietProgramsPdf(programs: programs);
          _downloadWebFileBinary(
            bytes: bytes,
            filename: 'diet_programs_${DateTime.now().millisecondsSinceEpoch}.pdf',
            contentType: 'application/pdf',
          );
          return true;
        } catch (_) {}
      }
      if (kDebugMode) {
    debugPrint('Diet PDF share error: $e');
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
      } else {
        final name = '${LocalizationService.translate('hemogram_data_filename_prefix').toLowerCase().replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.csv';
        final xfile = XFile.fromData(Uint8List.fromList(excelContent.codeUnits), name: name, mimeType: 'text/csv');
        await Share.shareXFiles([xfile], text: LocalizationService.translate('export_excel'));
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
    debugPrint('Excel export error: $e');
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
      final bytes = await _generateAnalysisReportPdf(
          hemogramValues: hemogramValues,
          patientName: patientName,
          analysisResult: analysisResult,
          recommendations: recommendations,
          riskLevel: riskLevel);

      if (kIsWeb) {
        _downloadWebFileBinary(
          bytes: bytes,
          filename: '${LocalizationService.translate('analysis_report').toLowerCase().replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf',
          contentType: 'application/pdf',
        );
      } else if (Platform.isIOS) {
        final name = '${LocalizationService.translate('analysis_report').toLowerCase().replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
        final xfile = XFile.fromData(bytes, name: name, mimeType: 'application/pdf');
        await Share.shareXFiles([xfile], text: LocalizationService.translate('analysis_report'));
      } else if (Platform.isAndroid) {
        final savedPath = await _savePdfToDocuments(bytes: bytes, filenamePrefix: LocalizationService.translate('analysis_report').toLowerCase().replaceAll(' ', '_'));
        await OpenFilex.open(savedPath);
      } else {
        final savedPath = await _savePdfToDocuments(bytes: bytes, filenamePrefix: LocalizationService.translate('analysis_report').toLowerCase().replaceAll(' ', '_'));
        await OpenFilex.open(savedPath);
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
    debugPrint('Analysis PDF export error: $e');
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
      } else if (!(Platform.isAndroid || Platform.isIOS)) {
        final dir = await getApplicationDocumentsDirectory();
        final outDir = Directory('${dir.path}${Platform.pathSeparator}HemoAI');
        if (!await outDir.exists()) {
          await outDir.create(recursive: true);
        }
        final path = '${outDir.path}${Platform.pathSeparator}${LocalizationService.translate('reminders').toLowerCase().replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.csv';
        final file = File(path);
        await file.writeAsString(excelContent);
        await OpenFilex.open(path);
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
    debugPrint('Reminders Excel export error: $e');
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
    debugPrint('Comprehensive report export error: $e');
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

                  String statusKey = 'status_normal';
                  PdfColor statusColor = PdfColors.green700;

                  if (range != null) {
                    final minValue = (range['min'] as num).toDouble();
                    final maxValue = (range['max'] as num).toDouble();
                    if (value < minValue) {
                      statusKey = 'status_low';
                      statusColor = PdfColors.orange700;
                    } else if (value > maxValue) {
                      // Very high threshold: > 1.5x upper bound
                      if (value > maxValue * 1.5) {
                        statusKey = 'status_very_high';
                        statusColor = PdfColors.red900;
                      } else {
                        statusKey = 'status_high';
                        statusColor = PdfColors.red700;
                      }
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
                          range != null
                              ? '${(range['min'] as num).toStringAsFixed(1)} - ${(range['max'] as num).toStringAsFixed(1)}'
                              : '-',
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          LocalizationService.translate(statusKey),
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

  // Generate Diet Programs PDF
  Future<Uint8List> _generateDietProgramsPdf({
    required List<DietProgram> programs,
  }) async {
    final pdf = pw.Document();
    final loc = LocalizationService();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            pw.Text(
              loc.getString('diet_programs'),
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              loc.getString('diet_program_description'),
              style: const pw.TextStyle(fontSize: 12),
            ),
            pw.SizedBox(height: 20),
            ...programs.expand((p) => [
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey200,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Text(
                  loc.getString(p.titleKey),
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(loc.getString(p.descriptionKey)),
              pw.SizedBox(height: 6),
              if (p.macrosKey != null) pw.Text(loc.getString(p.macrosKey!)),
              pw.SizedBox(height: 6),
              pw.Bullet(text: loc.getString(p.includeKey)),
              pw.SizedBox(height: 4),
              pw.Bullet(text: loc.getString(p.limitKey)),
              if (p.sampleMenuKey != null) ...[
                pw.SizedBox(height: 6),
                pw.Text(loc.getString(p.sampleMenuKey!)),
              ],
              pw.SizedBox(height: 14),
            ]),
          ];
        },
      ),
    );

    return pdf.save();
  }

  Future<Uint8List> _generateWeeklyDietPlanPdf({
    required List<DietProgram> weeklyPlan7,
    required int daysCompleted,
    required int weeksCompleted,
  }) async {
    final pdf = pw.Document();
    final loc = LocalizationService();
    const dayKeys = ['sunday','monday','tuesday','wednesday','thursday','friday','saturday'];
    final dayLabels = [
      for (final k in dayKeys) loc.getString(k),
    ];
    String l(String key, String en) { final v = loc.getString(key); return v == key ? en : v; }
    final menuService = DietMenuService();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          pw.Text(
            loc.getString('weekly_plan'),
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text('${loc.getString('weeks_completed')}: $weeksCompleted'),
          pw.SizedBox(height: 12),
          pw.LinearProgressIndicator(
            value: (daysCompleted.clamp(0, 7)) / 7.0,
            backgroundColor: PdfColors.grey300,
            valueColor: PdfColors.blue600,
          ),
          pw.SizedBox(height: 16),
          ...List.generate(weeklyPlan7.length, (i) {
            final p = weeklyPlan7[i];
            final menu = menuService.buildMenu(riskTag: p.riskTag, dayIndex: i);
            return pw.Column(children: [
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(color: PdfColors.grey200, borderRadius: pw.BorderRadius.circular(6)),
                child: pw.Text('${dayLabels[i]} — ${loc.getString(p.titleKey)}', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 6),
              pw.Text(loc.getString(p.descriptionKey)),
              if (p.macrosKey != null) ...[
                pw.SizedBox(height: 4),
                pw.Text(loc.getString(p.macrosKey!)),
              ],
              pw.SizedBox(height: 6),
              pw.Bullet(text: loc.getString(p.includeKey)),
              pw.Bullet(text: loc.getString(p.limitKey)),
              if (p.sampleMenuKey != null) ...[
                pw.SizedBox(height: 4),
                pw.Text(loc.getString(p.sampleMenuKey!)),
              ],
              pw.SizedBox(height: 8),
              // Daily menu section
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(l('daily_menu_heading','Daily Menu'), style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 6),
                    if ((menu['breakfast'] ?? const []).isNotEmpty) ...[
                      pw.Text(l('breakfast_label','Breakfast'), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                      pw.SizedBox(height: 2),
                      ...menu['breakfast']!.map((item) => pw.Bullet(text: _t(loc, item))),
                      pw.SizedBox(height: 6),
                    ],
                    if ((menu['lunch'] ?? const []).isNotEmpty) ...[
                      pw.Text(l('lunch_label','Lunch'), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                      pw.SizedBox(height: 2),
                      ...menu['lunch']!.map((item) => pw.Bullet(text: _t(loc, item))),
                      pw.SizedBox(height: 6),
                    ],
                    if ((menu['snack'] ?? const []).isNotEmpty) ...[
                      pw.Text(l('snack_label','Snack'), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                      pw.SizedBox(height: 2),
                      ...menu['snack']!.map((item) => pw.Bullet(text: _t(loc, item))),
                      pw.SizedBox(height: 6),
                    ],
                    if ((menu['dinner'] ?? const []).isNotEmpty) ...[
                      pw.Text(l('dinner_label','Dinner'), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                      pw.SizedBox(height: 2),
                      ...menu['dinner']!.map((item) => pw.Bullet(text: _t(loc, item))),
                    ],
                  ],
                ),
              ),
              pw.SizedBox(height: 10),
            ]);
          }),
          pw.SizedBox(height: 12),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text('${loc.getString('generated_by')} HemoAI', style: const pw.TextStyle(fontSize: 10)),
          ),
        ],
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

  Future<Uint8List> _generateAnalysisReportPdf({
    required Map<String, double> hemogramValues,
    required String patientName,
    required String analysisResult,
    required List<String> recommendations,
    required String riskLevel,
  }) async {
    final pdf = pw.Document();
    final loc = LocalizationService();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          pw.Text(
            loc.getString('analysis_report'),
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.Text('${loc.getString('patient_name')}: $patientName'),
          pw.SizedBox(height: 10),
          pw.Text('${loc.getString('risk_level')}: $riskLevel', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 20),
          pw.Text(loc.getString('analysis_details_heading'), style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Text(analysisResult),
          pw.SizedBox(height: 16),
          if (recommendations.isNotEmpty) ...[
            pw.Text(loc.getString('recommendations_heading'), style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            ...recommendations.map((r) => pw.Bullet(text: r)),
            pw.SizedBox(height: 16),
          ],
          if (hemogramValues.isNotEmpty) ...[
            pw.Text(loc.getString('key_parameters_heading'), style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(3),
                3: const pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(loc.getString('parameter'))),
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(loc.getString('result'))),
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(loc.getString('reference_range'))),
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(loc.getString('status'))),
                  ],
                ),
                ...hemogramValues.entries.map((e) {
                  // Define lightweight ranges for common keys (fallbacks)
                  final Map<String, Map<String, double>> ranges = {
                    'hemoglobin': {'min': 12.0, 'max': 17.0},
                    'iron': {'min': 60.0, 'max': 170.0},
                    'white_blood_cells': {'min': 4.0, 'max': 11.0},
                    'platelets': {'min': 150.0, 'max': 450.0},
                    'hematocrit': {'min': 35.0, 'max': 50.0},
                    'mcv': {'min': 80.0, 'max': 100.0},
                    'mch': {'min': 27.0, 'max': 32.0},
                    'mchc': {'min': 32.0, 'max': 36.0},
                    'rdw': {'min': 11.5, 'max': 14.5},
                    'ferritin': {'min': 15.0, 'max': 150.0},
                  };

                  final key = e.key;
                  final value = e.value;
                  final range = ranges[key];
                  String statusKey = 'status_normal';
                  PdfColor statusColor = PdfColors.green700;
                  String rangeText = '-';
                  if (range != null) {
                    final min = range['min']!;
                    final max = range['max']!;
                    rangeText = '${min.toStringAsFixed(1)} - ${max.toStringAsFixed(1)}';
                    if (value < min) {
                      statusKey = 'status_low';
                      statusColor = PdfColors.orange700;
                    } else if (value > max) {
                      if (value > max * 1.5) {
                        statusKey = 'status_very_high';
                        statusColor = PdfColors.red900;
                      } else {
                        statusKey = 'status_high';
                        statusColor = PdfColors.red700;
                      }
                    }
                  }

                  return pw.TableRow(children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(key.toUpperCase())),
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(value.toString())),
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(rangeText)),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        loc.getString(statusKey),
                        style: pw.TextStyle(color: statusColor, fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                  ]);
                }),
              ],
            ),
          ],
          pw.SizedBox(height: 20),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text('${loc.getString('generated_by')} HemoAI', style: const pw.TextStyle(fontSize: 10)),
          ),
        ],
      ),
    );

    return pdf.save();
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
    if (!kIsWeb) {
      if (kDebugMode) {
        debugPrint('Download ($filename) skipped: not running on web.');
      }
    } else {
      // Web implementation via conditional import
      if (kDebugMode) {
        debugPrint('Downloading text file on web: $filename');
      }
      downloadWebFile(content: content, filename: filename, contentType: contentType);
    }
  }

  void _downloadWebFileBinary({
    required Uint8List bytes,
    required String filename,
    required String contentType,
  }) {
    if (!kIsWeb) {
      if (kDebugMode) {
        debugPrint('Binary download ($filename) skipped: not running on web.');
      }
    } else {
      // Web implementation via conditional import
      if (kDebugMode) {
        debugPrint('Downloading file on web: $filename');
      }
      downloadWebFileBinary(bytes: bytes, filename: filename, contentType: contentType);
    }
  }

  // Save PDF bytes to user's Documents/HemoAI (or app documents) and return full path
  Future<String> _savePdfToDocuments({required Uint8List bytes, required String filenamePrefix}) async {
    final dir = await getApplicationDocumentsDirectory();
    final outDir = Directory('${dir.path}${Platform.pathSeparator}HemoAI');
    if (!await outDir.exists()) {
      await outDir.create(recursive: true);
    }
    final path = '${outDir.path}${Platform.pathSeparator}${filenamePrefix}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);
    if (kDebugMode) {
      debugPrint('Saved PDF to: $path');
    }
    return path;
  }
}

String _t(LocalizationService loc, String keyOrText) {
  final v = loc.getString(keyOrText);
  return v == keyOrText ? keyOrText : v;
}

