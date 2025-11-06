import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:xml/xml.dart' as xml;
import 'package:html/parser.dart' as html;
// Conditional helper for PDF OCR (IO platforms only)
import 'data_import_pdf_stub.dart' if (dart.library.io) 'data_import_pdf_impl.dart';
import '../models/blood_test_model.dart';

/// Data import service for one-click blood test data import from various sources
class DataImportService {
  // Placeholder for future networking timeouts
  // ignore: unused_field
  static const Duration _timeoutDuration = Duration(seconds: 30);

  /// Import from Turkish e-Devlet (Government) system
  /// 
  /// Note: Official e-Devlet API integration requires:
  /// - Official developer account with e-Devlet Gateway
  /// - OAuth2 authentication setup
  /// - Government approval for health data access
  /// 
  /// Current implementation: Enhanced OCR-based import
  /// Users can copy-paste e-Devlet HTML/text content for automatic parsing
  /// 
  /// For production: Integrate with e-Devlet Gateway API when available
  Future<ImportResult> importFromEDevlet({
    required String tcKimlik,
    required String password,
    String? sessionToken,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('🏛️ e-Devlet API import requested for TC: ${tcKimlik.substring(0, 3)}***');
        debugPrint('⚠️ Note: Official API integration requires e-Devlet Gateway setup');
      }
      
      // Real API integration would go here:
      // 1. Authenticate with e-Devlet OAuth2
      // 2. Navigate to health services via API
      // 3. Access blood test results endpoint
      // 4. Parse JSON/XML response
      // 5. Extract and map blood test values
      
      // For now, guide users to use OCR/text import instead
      // This is more reliable and doesn't require API credentials
      return ImportResult.error(
        message: 'e-Devlet API entegrasyonu için resmi izin gereklidir. '
            'Lütfen e-Devlet sayfasından kan testi sonuçlarını kopyalayıp '
            '"Metin Yapıştır" seçeneğini kullanın.',
        source: 'e-devlet',
      );
    } catch (e) {
      return ImportResult.error(
        message: 'e-Devlet bağlantısı başarısız: $e\n\n'
            'Alternatif: e-Devlet sayfasından metni kopyalayıp "Metin Yapıştır" seçeneğini kullanın.',
        source: 'e-devlet',
      );
    }
  }

  /// Import from e-Devlet by pasting exported text/HTML (no network)
  /// Robust flow: HTML strip -> JSON-first -> boilerplate cleanup -> structured text
  Future<ImportResult> importFromEDevletSnippet(String raw) async {
    try {
      String text = raw.trim();
      if (text.isEmpty) {
        return ImportResult.error(message: 'No text provided', source: 'e-devlet-snippet');
      }

      // If user pasted HTML, strip tags to get readable text
      if (text.startsWith('<') && text.contains('</')) {
        text = _stripHtmlTags(text);
      }

      // Try JSON first (some systems export JSON blobs)
      if (text.startsWith('{') || text.startsWith('[')) {
        final parsed = _parseJSONResults(text, 'e-devlet-snippet');
        if (parsed.isSuccess && parsed.testResults.isNotEmpty) {
          return parsed;
        }
      }

      // Clean common e-Devlet or ministry boilerplate to boost signal
      final cleaned = text
          .replaceAll(RegExp(r'e-devlet\s*kapis[iı]', caseSensitive: false), '')
          .replaceAll(RegExp(r'sa[ğg]lik\s*bakanli[gğ]i', caseSensitive: false), '')
          .replaceAll(RegExp(r't\.c\.', caseSensitive: false), '')
          .replaceAll(RegExp(r'\s{2,}'), ' ')
          .trim();

      return _parseStructuredText(cleaned.isNotEmpty ? cleaned : text, 'e-devlet-snippet');
    } catch (e) {
      return ImportResult.error(message: 'Text import failed: $e', source: 'e-devlet-snippet');
    }
  }

  /// Import from QR code (many labs provide QR codes on results)
  Future<ImportResult> importFromQR(String qrData) async {
    try {
      if (kDebugMode) {
        debugPrint('📱 Processing QR code data...');
      }

      // Try to parse as JSON first
      if (qrData.startsWith('{') || qrData.startsWith('[')) {
        return _parseJSONResults(qrData, 'qr-scan');
      }
      
      // Try to parse as URL (lab results link)
      if (qrData.startsWith('http')) {
        return await _importFromURL(qrData);
      }
      
      // Try to parse as structured text
      return _parseStructuredText(qrData, 'qr-scan');
      
    } catch (e) {
      return ImportResult.error(
        message: 'QR code could not be read: $e',
        source: 'qr-scan',
      );
    }
  }

  /// Import from file (PDF, JSON, CSV, XML)
  Future<ImportResult> importFromFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'json', 'csv', 'xml', 'txt'],
        allowMultiple: false,
        withData: true, // ensure bytes available for parsing across formats
      );

      if (result == null || result.files.isEmpty) {
        return ImportResult.error(
          message: 'No file selected',
          source: 'file-import',
        );
      }

      final file = result.files.first;
      final extension = file.extension?.toLowerCase();
      
      if (kDebugMode) {
        debugPrint('📄 Importing from file: ${file.name} ($extension)');
      }

      switch (extension) {
        case 'json':
          return await _parseJSONFile(file);
        case 'csv':
          return await _parseCSVFile(file);
        case 'xml':
          return await _parseXMLFile(file);
        case 'pdf':
          return await _parsePDFFile(file);
        case 'txt':
          return await _parseTextFile(file);
        default:
          return ImportResult.error(
            message: 'Unsupported file format: $extension',
            source: 'file-import',
          );
      }
    } catch (e) {
      return ImportResult.error(
        message: 'File read error: $e',
        source: 'file-import',
      );
    }
  }

  /// Import from URL (lab website results)
  Future<ImportResult> _importFromURL(String url) async {
    // Networking is not implemented in this offline stub to avoid extra deps
    return ImportResult.error(
      message: 'URL import not supported yet',
      source: 'url-import',
    );
  }

  /// Import from raw pasted text (any platform)
  Future<ImportResult> importFromText(String input) async {
    try {
      final text = input.trim();
      if (text.isEmpty) {
        return ImportResult.error(message: 'No text provided', source: 'pasted-text');
      }
      if (text.startsWith('{') || text.startsWith('[')) {
        return _parseJSONResults(text, 'pasted-text');
      }
      if (text.startsWith('http')) {
        return await _importFromURL(text);
      }
      return _parseStructuredText(text, 'pasted-text');
    } catch (e) {
      return ImportResult.error(message: 'Text import failed: $e', source: 'pasted-text');
    }
  }

  /// Import from an image file (photo of lab report) using on-device OCR
  Future<ImportResult> importFromImageFile(PlatformFile file) async {
    try {
      if (kIsWeb) {
        return ImportResult.error(
          message: 'OCR is not supported on web yet',
          source: 'image-ocr',
        );
      }

      final path = file.path;
      if (path == null || path.isEmpty) {
        return ImportResult.error(
          message: 'Image import failed: missing file path',
          source: 'image-ocr',
        );
      }

      final inputImage = InputImage.fromFilePath(path);
      final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final recognized = await recognizer.processImage(inputImage);
      await recognizer.close();

      final text = recognized.text.trim();
      if (text.isEmpty) {
        return ImportResult.error(
          message: 'No text recognized in image',
          source: 'image-ocr',
        );
      }

      // Reuse structured-text parser to extract values
      final parsed = _parseStructuredText(text, 'image-ocr');
      return parsed;
    } catch (e) {
      return ImportResult.error(
        message: 'OCR failed: $e',
        source: 'image-ocr',
      );
    }
  }

  /// Parse JSON format results
  ImportResult _parseJSONResults(String jsonData, String source) {
    try {
      final data = json.decode(jsonData);
      final List<BloodTestResult> results = [];

      if (data is List) {
        for (final item in data) {
          if (item is Map) {
            results.add(_mapJSONToBloodTest(item.cast<String, dynamic>(), source));
          }
        }
      } else if (data is Map) {
        results.add(_mapJSONToBloodTest(data.cast<String, dynamic>(), source));
      }

      return ImportResult.success(
        source: source,
        testResults: results,
      );
    } catch (e) {
      return ImportResult.error(
        message: 'JSON parse error: $e',
        source: source,
      );
    }
  }

  /// Parse structured text (common in Turkish labs)
  ImportResult _parseStructuredText(String textData, String source) {
    try {
      final lines = textData.split('\n');
      final Map<String, double> values = {};
      String? testDate;
      String? labName;

      for (String line in lines) {
        line = line.trim();
        final normalized = _normalizeTurkish(line.toLowerCase());
        if (line.isEmpty) continue;

        // Extract test date
        if (normalized.contains('tarih:') || normalized.contains('date:')) {
          testDate = _extractDateFromLine(line);
          continue;
        }

        // Extract lab name
        if (normalized.contains('laboratuvar:') || normalized.contains('laboratory:')) {
          labName = line.split(':').last.trim();
          continue;
        }

        // Extract blood values
        final value = _extractValueFromLine(line);
        if (value != null) {
          values.addAll(value);
        }
      }

      if (values.isEmpty) {
        return ImportResult.error(
          message: 'Blood values not found',
          source: source,
        );
      }

      final result = BloodTestResult(
        userId: 0,
        testDate: testDate ?? DateTime.now().toIso8601String().split('T')[0],
        laboratoryName: labName,
  testType: 'Imported Test',
        importSource: source,
        hemoglobin: values['hemoglobin'],
        hematocrit: values['hematocrit'],
        whiteBloodCells: values['white_blood_cells'],
        platelets: values['platelets'],
        iron: values['iron'],
        glucose: values['glucose'],
        creatinine: values['creatinine'],
        alt: values['alt'],
        ast: values['ast'],
        // Additional mapped fields if present
        redBloodCells: values['red_blood_cells'],
        mcv: values['mcv'],
        mch: values['mch'],
        mchc: values['mchc'],
        rdw: values['rdw'],
        mpv: values['mpv'],
        neutrophils: values['neutrophils'],
        lymphocytes: values['lymphocytes'],
        monocytes: values['monocytes'],
        eosinophils: values['eosinophils'],
        basophils: values['basophils'],
        ferritin: values['ferritin'],
        transferrin: values['transferrin'],
        tibc: values['tibc'],
        transferrinSaturation: values['transferrin_saturation'],
        alp: values['alp'],
        ggt: values['ggt'],
        bilirubin: values['bilirubin'],
        directBilirubin: values['direct_bilirubin'],
        albumin: values['albumin'],
        totalProtein: values['total_protein'],
        urea: values['urea'],
        uricAcid: values['uric_acid'],
        gfr: values['gfr'],
        totalCholesterol: values['total_cholesterol'],
        ldlCholesterol: values['ldl_cholesterol'],
        hdlCholesterol: values['hdl_cholesterol'],
        triglycerides: values['triglycerides'],
        nonHdlCholesterol: values['non_hdl_cholesterol'],
        hba1c: values['hba1c'],
        fructosamine: values['fructosamine'],
        tsh: values['tsh'],
        t3: values['t3'],
        t4: values['t4'],
        freeT3: values['free_t3'],
        freeT4: values['free_t4'],
        sodium: values['sodium'],
        potassium: values['potassium'],
        chloride: values['chloride'],
        calcium: values['calcium'],
        magnesium: values['magnesium'],
        phosphorus: values['phosphorus'],
        vitaminB12: values['vitamin_b12'],
        vitaminD: values['vitamin_d'],
        folate: values['folate'],
        vitaminA: values['vitamin_a'],
        vitaminE: values['vitamin_e'],
        vitaminC: values['vitamin_c'],
        cea: values['cea'],
        afp: values['afp'],
        ca125: values['ca125'],
        ca199: values['ca199'],
        ca153: values['ca153'],
        psa: values['psa'],
        troponin: values['troponin'],
        ckMb: values['ck_mb'],
        ldh: values['ldh'],
        bnp: values['bnp'],
        crp: values['crp'],
        esr: values['esr'],
        procalcitonin: values['procalcitonin'],
        insulin: values['insulin'],
        cortisol: values['cortisol'],
        testosterone: values['testosterone'],
        estradiol: values['estradiol'],
        progesterone: values['progesterone'],
        prolactin: values['prolactin'],
        fsh: values['fsh'],
        lh: values['lh'],
        createdAt: DateTime.now(),
      );

      return ImportResult.success(
        source: source,
        testResults: [result],
      );
    } catch (e) {
      return ImportResult.error(
        message: 'Text parse error: $e',
        source: source,
      );
    }
  }

  /// Parse CSV file
  Future<ImportResult> _parseCSVFile(PlatformFile file) async {
    try {
      final bytes = file.bytes;
      if (bytes == null) {
        return ImportResult.error(message: 'File content could not be read', source: 'csv-import');
      }

      final content = utf8.decode(bytes);
      final lines = content.split('\n');
      
      if (lines.length < 2) {
        return ImportResult.error(message: 'Invalid CSV format', source: 'csv-import');
      }

      final headers = lines[0].split(',').map((h) => h.trim().toLowerCase()).toList();
      final List<BloodTestResult> results = [];

      for (int i = 1; i < lines.length; i++) {
        if (lines[i].trim().isEmpty) continue;
        
        final values = lines[i].split(',');
        if (values.length != headers.length) continue;

        final testData = <String, String>{};
        for (int j = 0; j < headers.length; j++) {
          testData[headers[j]] = values[j].trim();
        }

        results.add(_mapCSVToBloodTest(testData));
      }

      return ImportResult.success(
        source: 'csv-import',
        testResults: results,
      );
    } catch (e) {
      return ImportResult.error(
        message: 'CSV file could not be read: $e',
        source: 'csv-import',
      );
    }
  }

  /// Parse JSON file
  Future<ImportResult> _parseJSONFile(PlatformFile file) async {
    try {
      final bytes = file.bytes;
      if (bytes == null) {
        return ImportResult.error(message: 'File content could not be read', source: 'json-import');
      }
      final content = utf8.decode(bytes);
      return _parseJSONResults(content, 'json-import');
    } catch (e) {
      return ImportResult.error(
        message: 'JSON file could not be read: $e',
        source: 'json-import',
      );
    }
  }

  /// Parse XML file (common in hospital systems)
  Future<ImportResult> _parseXMLFile(PlatformFile file) async {
    try {
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        return ImportResult.error(
          message: 'File content could not be read',
          source: 'xml-import',
        );
      }

      final content = utf8.decode(bytes);
      return _parseXMLResults(content, 'xml-import');
    } catch (e) {
      return ImportResult.error(
        message: 'XML file could not be read: $e',
        source: 'xml-import',
      );
    }
  }

  /// Parse PDF file (using OCR)
  Future<ImportResult> _parsePDFFile(PlatformFile file) async {
    try {
      if (kIsWeb) {
        return ImportResult.error(
          message: 'PDF import is not supported on web',
          source: 'pdf-import',
        );
      }

      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        return ImportResult.error(
          message: 'File content could not be read',
          source: 'pdf-import',
        );
      }

      // Use platform helper to OCR PDF pages into text
      final extractedText = await PdfOcrHelper.extractTextFromPdfBytes(bytes);
      final text = extractedText.trim();
      if (text.isEmpty) {
        return ImportResult.error(
          message: 'No readable text found in PDF',
          source: 'pdf-import',
        );
      }

      // Reuse structured text parser
      return _parseStructuredText(text, 'pdf-import');
    } catch (e) {
      return ImportResult.error(
        message: 'PDF processing failed: $e',
        source: 'pdf-import',
      );
    }
  }

  /// Parse plain text file
  Future<ImportResult> _parseTextFile(PlatformFile file) async {
    try {
      final bytes = file.bytes;
      if (bytes == null) {
        return ImportResult.error(message: 'File content could not be read', source: 'txt-import');
      }

      final content = utf8.decode(bytes);
      return _parseStructuredText(content, 'txt-import');
    } catch (e) {
      return ImportResult.error(
        message: 'Text file could not be read: $e',
        source: 'txt-import',
      );
    }
  }

  /// Parse HTML results (for web scraping)
  ImportResult _parseHTMLResults(String htmlData, String source) {
    try {
      // Parse HTML document
      final document = html.parse(htmlData);
      
      // Extract text content
      final textContent = document.body?.text ?? '';
      
      if (textContent.trim().isEmpty) {
        return ImportResult.error(
          message: 'No readable content found in HTML',
          source: source,
        );
      }

      // Try to find structured data in tables
      final tables = document.querySelectorAll('table');
      if (tables.isNotEmpty) {
        final results = <BloodTestResult>[];
        
        for (final table in tables) {
          final rows = table.querySelectorAll('tr');
          for (final row in rows) {
            final cells = row.querySelectorAll('td, th');
            if (cells.length >= 2) {
              final paramName = cells[0].text.trim().toLowerCase();
              final paramValue = cells[1].text.trim();
              
              // Try to parse as number
              final value = double.tryParse(paramValue.replaceAll(',', '.'));
              if (value != null && _isKnownParameter(paramName)) {
                results.add(_mapCSVToBloodTest({paramName: paramValue}));
              }
            }
          }
        }
        
        if (results.isNotEmpty) {
          return ImportResult.success(
            source: source,
            testResults: results,
          );
        }
      }

      // Fallback: strip HTML and parse as structured text
      final cleanText = _stripHtmlTags(htmlData);
      return _parseStructuredText(cleanText, source);
    } catch (e) {
      return ImportResult.error(
        message: 'HTML parsing failed: $e',
        source: source,
      );
    }
  }

  // Strip basic HTML tags to extract text content for simple parsing
  String _stripHtmlTags(String html) {
    // Replace <br> and <p> with newlines to preserve structure a bit
    String t = html
        .replaceAll(RegExp(r'<\s*br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<\s*/p\s*>', caseSensitive: false), '\n');
    // Remove all other tags
    t = t.replaceAll(RegExp(r'<[^>]+>'), ' ');
    // Decode common HTML entities minimally
    t = t
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");
    // Collapse multiple whitespaces
    t = t.replaceAll(RegExp(r'[ \t\x0B\f\r]+'), ' ');
    // Normalize newlines
    t = t.replaceAll(RegExp(r'\n\s*\n+'), '\n');
    return t.trim();
  }

  /// Parse XML results
  ImportResult _parseXMLResults(String xmlData, String source) {
    try {
      // Parse XML document
      final document = xml.XmlDocument.parse(xmlData);
      
      // Common XML patterns for lab results
      // Pattern 1: <test name="hemoglobin" value="14.5"/>
      // Pattern 2: <result><parameter>Hemoglobin</parameter><value>14.5</value></result>
      // Pattern 3: <lab_results><test><name>Hemoglobin</name><value>14.5</value></test></lab_results>
      
      final results = <BloodTestResult>[];
      
      // Try Pattern 1: Attributes
      final testElements = document.findAllElements('test');
      for (final element in testElements) {
        final name = element.getAttribute('name') ?? element.getAttribute('parameter');
        final valueStr = element.getAttribute('value') ?? element.text;
        
        if (name != null && valueStr.isNotEmpty) {
          final value = double.tryParse(valueStr.replaceAll(',', '.'));
          if (value != null) {
            final normalizedName = _normalizeParameterName(name);
            if (_isKnownParameter(normalizedName)) {
              results.add(_mapCSVToBloodTest({normalizedName: valueStr}));
            }
          }
        }
      }
      
      // Try Pattern 2: Nested elements
      if (results.isEmpty) {
        final resultElements = document.findAllElements('result');
        for (final element in resultElements) {
          final parameterElements = element.findElements('parameter');
          final nameElements = element.findElements('name');
          final nameElement = parameterElements.isNotEmpty 
              ? parameterElements.first 
              : (nameElements.isNotEmpty ? nameElements.first : null);
          final valueElements = element.findElements('value');
          final valueElement = valueElements.isNotEmpty ? valueElements.first : null;
          
          if (nameElement != null && valueElement != null) {
            final name = nameElement.text.trim();
            final valueStr = valueElement.text.trim();
            final value = double.tryParse(valueStr.replaceAll(',', '.'));
            
            if (value != null) {
              final normalizedName = _normalizeParameterName(name);
              if (_isKnownParameter(normalizedName)) {
                results.add(_mapCSVToBloodTest({normalizedName: valueStr}));
              }
            }
          }
        }
      }
      
      // Try Pattern 3: Generic key-value pairs
      if (results.isEmpty) {
        final allElements = document.findAllElements('*');
        for (final element in allElements) {
          if (element.children.isEmpty && element.text.trim().isNotEmpty) {
            final name = element.localName.toLowerCase();
            final valueStr = element.text.trim();
            final value = double.tryParse(valueStr.replaceAll(',', '.'));
            
            if (value != null) {
              final normalizedName = _normalizeParameterName(name);
              if (_isKnownParameter(normalizedName)) {
                results.add(_mapCSVToBloodTest({normalizedName: valueStr}));
              }
            }
          }
        }
      }
      
      if (results.isEmpty) {
        // Fallback: extract all text and parse as structured text
        final textContent = document.innerText;
        return _parseStructuredText(textContent, source);
      }
      
      return ImportResult.success(
        source: source,
        testResults: results,
      );
    } catch (e) {
      return ImportResult.error(
        message: 'XML parsing failed: $e',
        source: source,
      );
    }
  }
  
  /// Normalize parameter name to canonical format
  String _normalizeParameterName(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }
  
  /// Check if parameter is known
  bool _isKnownParameter(String name) {
    final knownParams = [
      'hemoglobin', 'glucose', 'calcium', 'sodium', 'potassium',
      'chloride', 'alt', 'ast', 'ggt', 'total_bilirubin',
      'direct_bilirubin', 'crp', 'iron', 'uibc', 'tibc',
      'tsh', 'free_t3', 'free_t4', 'vitamin_d3', 'vitamin_b12',
      'white_blood_cells', 'red_blood_cells', 'platelets',
      'hematocrit', 'mcv', 'mch', 'mchc', 'rdw',
    ];
    return knownParams.contains(name);
  }

  /// Helper methods for data extraction
  String? _extractDateFromLine(String line) {
    final regex = RegExp(r'(\d{1,2})[./](\d{1,2})[./](\d{4})');
    final match = regex.firstMatch(line);
    if (match != null) {
      final day = match.group(1)!.padLeft(2, '0');
      final month = match.group(2)!.padLeft(2, '0');
      final year = match.group(3)!;
      return '$year-$month-$day';
    }
    return null;
  }

  Map<String, double>? _extractValueFromLine(String line) {
    final normalized = _normalizeTurkish(line.toLowerCase());
    final patterns = <String, RegExp>{
      // Core hemogram
      'hemoglobin': RegExp(r'(?:hemoglobin|hgb)[:\s]*(\d+[.,]\d+)'),
      'hematocrit': RegExp(r'(?:hematokrit|hct)[:\s]*(\d+[.,]\d+)'),
      'white_blood_cells': RegExp(r'(?:lokosit|wbc|beyaz kan)[:\s]*(\d+[.,]\d+)'),
      'platelets': RegExp(r'(?:trombosit|plt)[:\s]*(\d+[.,]\d+)'),
      'red_blood_cells': RegExp(r'(?:eritrosit|rbc|kirmizi kan)[:\s]*(\d+[.,]\d+)'),
      'mcv': RegExp(r'mcv[:\s]*(\d+[.,]\d+)'),
      'mch': RegExp(r'mch[:\s]*(\d+[.,]\d+)'),
      'mchc': RegExp(r'mchc[:\s]*(\d+[.,]\d+)'),
      'rdw': RegExp(r'rdw[:\s]*(\d+[.,]\d+)'),
      'mpv': RegExp(r'mpv[:\s]*(\d+[.,]\d+)'),

      // Differential
      'neutrophils': RegExp(r'(?:notrofil|neutrofil|neu)[:\s]*(\d+[.,]\d+)'),
      'lymphocytes': RegExp(r'(?:lenfosit|lym)[:\s]*(\d+[.,]\d+)'),
      'monocytes': RegExp(r'(?:monosit|mono)[:\s]*(\d+[.,]\d+)'),
      'eosinophils': RegExp(r'(?:eozinofil|eos)[:\s]*(\d+[.,]\d+)'),
      'basophils': RegExp(r'(?:bazofil|baso)[:\s]*(\d+[.,]\d+)'),

      // Iron studies
      'iron': RegExp(r'(?:demir|iron)[:\s]*(\d+[.,]\d+)'),
      'ferritin': RegExp(r'ferritin[:\s]*(\d+[.,]\d+)'),
      'transferrin': RegExp(r'transferrin[:\s]*(\d+[.,]\d+)'),
      'tibc': RegExp(r'(?:tibc|total iron binding capacity)[:\s]*(\d+[.,]\d+)'),
      'transferrin_saturation': RegExp(r'(?:transferrin saturasyon|saturation)[:\s]*(\d+[.,]\d+)'),

      // Liver
      'alt': RegExp(r'\balt[:\s]*(\d+[.,]\d+)'),
      'ast': RegExp(r'\bast[:\s]*(\d+[.,]\d+)'),
      'alp': RegExp(r'\balp[:\s]*(\d+[.,]\d+)'),
      'ggt': RegExp(r'\bggt[:\s]*(\d+[.,]\d+)'),
      'bilirubin': RegExp(r'(?:bilirubin|total bilirubin)[:\s]*(\d+[.,]\d+)'),
      'direct_bilirubin': RegExp(r'(?:direct bilirubin|direk bilirubin)[:\s]*(\d+[.,]\d+)'),
      'albumin': RegExp(r'albumin[:\s]*(\d+[.,]\d+)'),
      'total_protein': RegExp(r'(?:total protein|tp)[:\s]*(\d+[.,]\d+)'),

      // Kidney
      'creatinine': RegExp(r'(?:kreatinin|creatinine)[:\s]*(\d+[.,]\d+)'),
      'urea': RegExp(r'(?:ure|urea|bun)[:\s]*(\d+[.,]\d+)'),
      'uric_acid': RegExp(r'(?:urik asit|uric acid)[:\s]*(\d+[.,]\d+)'),
      'gfr': RegExp(r'(?:gfr|egfr)[:\s]*(\d+[.,]\d+)'),

      // Lipids
      'total_cholesterol': RegExp(r'(?:total kolesterol|total cholesterol|tkol)[:\s]*(\d+[.,]\d+)'),
      'ldl_cholesterol': RegExp(r'(?:ldl|kotu kolesterol)[:\s]*(\d+[.,]\d+)'),
      'hdl_cholesterol': RegExp(r'(?:hdl|iyi kolesterol)[:\s]*(\d+[.,]\d+)'),
      'triglycerides': RegExp(r'(?:trigliserid|triglycerid(?:e)?s?)[:\s]*(\d+[.,]\d+)'),
      'non_hdl_cholesterol': RegExp(r'(?:non[- ]?hdl)[:\s]*(\d+[.,]\d+)'),

      // Diabetes
      'glucose': RegExp(r'(?:glukoz|glucose)[:\s]*(\d+[.,]\d+)'),
      'hba1c': RegExp(r'(?:hba1c|a1c)[:\s]*(\d+[.,]\d+)'),
      'fructosamine': RegExp(r'fructosamine[:\s]*(\d+[.,]\d+)'),

      // Thyroid
      'tsh': RegExp(r'\btsh[:\s]*(\d+[.,]\d+)'),
      't3': RegExp(r'\bt3[:\s]*(\d+[.,]\d+)'),
      't4': RegExp(r'\bt4[:\s]*(\d+[.,]\d+)'),
      'free_t3': RegExp(r'(?:ft3|free t3|serbest t3)[:\s]*(\d+[.,]\d+)'),
      'free_t4': RegExp(r'(?:ft4|free t4|serbest t4)[:\s]*(\d+[.,]\d+)'),

      // Electrolytes
      'sodium': RegExp(r'(?:sodyum|sodium|na)[:\s]*(\d+[.,]\d+)'),
      'potassium': RegExp(r'(?:potasyum|potassium|k)[:\s]*(\d+[.,]\d+)'),
      'chloride': RegExp(r'(?:klor|chloride|cl)[:\s]*(\d+[.,]\d+)'),
      'calcium': RegExp(r'(?:kalsiyum|calcium|ca)[:\s]*(\d+[.,]\d+)'),
      'magnesium': RegExp(r'(?:magnezyum|magnesium|mg)[:\s]*(\d+[.,]\d+)'),
      'phosphorus': RegExp(r'(?:fosfor|fosfat|phosphor(?:us)?|p)[:\s]*(\d+[.,]\d+)'),

      // Vitamins
      'vitamin_b12': RegExp(r'(?:b12|vitamin b12)[:\s]*(\d+[.,]\d+)'),
      'vitamin_d': RegExp(r'(?:vit d|vitamin d|25\(oh\)d)[:\s]*(\d+[.,]\d+)'),
      'folate': RegExp(r'(?:folat|folate)[:\s]*(\d+[.,]\d+)'),
      'vitamin_a': RegExp(r'(?:vitamin a|retinol)[:\s]*(\d+[.,]\d+)'),
      'vitamin_e': RegExp(r'(?:vitamin e|alpha[- ]?tocopherol)[:\s]*(\d+[.,]\d+)'),
      'vitamin_c': RegExp(r'(?:vitamin c|ascorbic acid)[:\s]*(\d+[.,]\d+)'),

      // Inflammatory
      'crp': RegExp(r'\bcrp[:\s]*(\d+[.,]\d+)'),
      'esr': RegExp(r'(?:sedimentasyon|esr)[:\s]*(\d+[.,]\d+)'),
      'procalcitonin': RegExp(r'(?:prokalsitonin|procalcitonin|pct)[:\s]*(\d+[.,]\d+)'),

      // Tumor markers
      'cea': RegExp(r'\bcea[:\s]*(\d+[.,]\d+)'),
      'afp': RegExp(r'\bafp[:\s]*(\d+[.,]\d+)'),
      'ca125': RegExp(r'\bca\s*125[:\s]*(\d+[.,]\d+)'),
      'ca199': RegExp(r'\bca\s*19[- ]?9[:\s]*(\d+[.,]\d+)'),
      'ca153': RegExp(r'\bca\s*15[- ]?3[:\s]*(\d+[.,]\d+)'),
      'psa': RegExp(r'\bpsa[:\s]*(\d+[.,]\d+)'),

      // Cardiac markers
      'troponin': RegExp(r'(?:troponin(?:[ -]?i)?)[:\s]*(\d+[.,]\d+)'),
      'ck_mb': RegExp(r'(?:ck[- ]?mb|creatine kinase[- ]?mb)[:\s]*(\d+[.,]\d+)'),
      'ldh': RegExp(r'\bldh[:\s]*(\d+[.,]\d+)'),
      'bnp': RegExp(r'\bbnp[:\s]*(\d+[.,]\d+)'),

      // Hormones
      'insulin': RegExp(r'(?:insulin|insulin)[:\s]*(\d+[.,]\d+)'),
      'cortisol': RegExp(r'\bcortisol[:\s]*(\d+[.,]\d+)'),
      'testosterone': RegExp(r'\btestosterone[:\s]*(\d+[.,]\d+)'),
      'estradiol': RegExp(r'(?:estradiol|e2)[:\s]*(\d+[.,]\d+)'),
      'progesterone': RegExp(r'\bprogesterone[:\s]*(\d+[.,]\d+)'),
      'prolactin': RegExp(r'\bprolactin[:\s]*(\d+[.,]\d+)'),
      'fsh': RegExp(r'\bfsh[:\s]*(\d+[.,]\d+)'),
      'lh': RegExp(r'\blh[:\s]*(\d+[.,]\d+)'),
    };

    for (final entry in patterns.entries) {
      final match = entry.value.firstMatch(normalized);
      if (match != null) {
        final valueStr = match.group(1)!.replaceAll(',', '.');
        final value = double.tryParse(valueStr);
        if (value != null) {
          return {entry.key: value};
        }
      }
    }
    return null;
  }

  BloodTestResult _mapJSONToBloodTest(Map<String, dynamic> data, String source) {
    return BloodTestResult(
      userId: 0,
      testDate: data['testDate'] ?? data['test_date'] ?? DateTime.now().toIso8601String().split('T')[0],
      laboratoryName: data['laboratoryName'] ?? data['laboratory_name'],
      doctorName: data['doctorName'] ?? data['doctor_name'],
      testType: data['testType'] ?? data['test_type'],
      importSource: source,
      hemoglobin: _parseDouble(data['hemoglobin']),
      hematocrit: _parseDouble(data['hematocrit']),
      redBloodCells: _parseDouble(data['redBloodCells'] ?? data['red_blood_cells']),
      whiteBloodCells: _parseDouble(data['whiteBloodCells'] ?? data['white_blood_cells']),
      platelets: _parseDouble(data['platelets']),
      mcv: _parseDouble(data['mcv']),
      mch: _parseDouble(data['mch']),
      mchc: _parseDouble(data['mchc']),
      rdw: _parseDouble(data['rdw']),
      mpv: _parseDouble(data['mpv']),
      neutrophils: _parseDouble(data['neutrophils']),
      lymphocytes: _parseDouble(data['lymphocytes']),
      monocytes: _parseDouble(data['monocytes']),
      eosinophils: _parseDouble(data['eosinophils']),
      basophils: _parseDouble(data['basophils']),
      iron: _parseDouble(data['iron']),
      ferritin: _parseDouble(data['ferritin']),
      transferrin: _parseDouble(data['transferrin']),
      tibc: _parseDouble(data['tibc']),
      transferrinSaturation: _parseDouble(data['transferrinSaturation'] ?? data['transferrin_saturation']),
      glucose: _parseDouble(data['glucose']),
      creatinine: _parseDouble(data['creatinine']),
      alt: _parseDouble(data['alt']),
      ast: _parseDouble(data['ast']),
      alp: _parseDouble(data['alp']),
      ggt: _parseDouble(data['ggt']),
      bilirubin: _parseDouble(data['bilirubin']),
      directBilirubin: _parseDouble(data['directBilirubin'] ?? data['direct_bilirubin']),
      albumin: _parseDouble(data['albumin']),
      totalProtein: _parseDouble(data['totalProtein'] ?? data['total_protein']),
      urea: _parseDouble(data['urea'] ?? data['bun']),
      uricAcid: _parseDouble(data['uricAcid'] ?? data['uric_acid']),
      gfr: _parseDouble(data['gfr'] ?? data['egfr']),
      totalCholesterol: _parseDouble(data['totalCholesterol'] ?? data['total_cholesterol']),
      ldlCholesterol: _parseDouble(data['ldlCholesterol'] ?? data['ldl_cholesterol']),
      hdlCholesterol: _parseDouble(data['hdlCholesterol'] ?? data['hdl_cholesterol']),
      triglycerides: _parseDouble(data['triglycerides']),
      nonHdlCholesterol: _parseDouble(data['nonHdlCholesterol'] ?? data['non_hdl_cholesterol']),
      hba1c: _parseDouble(data['hba1c']),
      fructosamine: _parseDouble(data['fructosamine']),
      tsh: _parseDouble(data['tsh']),
      t3: _parseDouble(data['t3']),
      t4: _parseDouble(data['t4']),
      freeT3: _parseDouble(data['freeT3'] ?? data['free_t3']),
      freeT4: _parseDouble(data['freeT4'] ?? data['free_t4']),
      sodium: _parseDouble(data['sodium'] ?? data['na']),
      potassium: _parseDouble(data['potassium'] ?? data['k']),
      chloride: _parseDouble(data['chloride'] ?? data['cl']),
      calcium: _parseDouble(data['calcium'] ?? data['ca']),
      magnesium: _parseDouble(data['magnesium'] ?? data['mg']),
      phosphorus: _parseDouble(data['phosphorus'] ?? data['p']),
      vitaminB12: _parseDouble(data['vitaminB12'] ?? data['vitamin_b12']),
      vitaminD: _parseDouble(data['vitaminD'] ?? data['vitamin_d']),
      folate: _parseDouble(data['folate']),
      vitaminA: _parseDouble(data['vitaminA'] ?? data['vitamin_a']),
      vitaminE: _parseDouble(data['vitaminE'] ?? data['vitamin_e']),
      vitaminC: _parseDouble(data['vitaminC'] ?? data['vitamin_c']),
      cea: _parseDouble(data['cea']),
      afp: _parseDouble(data['afp']),
      ca125: _parseDouble(data['ca125'] ?? data['ca_125']),
      ca199: _parseDouble(data['ca199'] ?? data['ca_19_9']),
      ca153: _parseDouble(data['ca153'] ?? data['ca_15_3']),
      psa: _parseDouble(data['psa']),
      troponin: _parseDouble(data['troponin'] ?? data['troponin_i']),
      ckMb: _parseDouble(data['ckMb'] ?? data['ck_mb']),
      ldh: _parseDouble(data['ldh']),
      bnp: _parseDouble(data['bnp']),
      crp: _parseDouble(data['crp']),
      esr: _parseDouble(data['esr']),
      procalcitonin: _parseDouble(data['procalcitonin'] ?? data['pct']),
      insulin: _parseDouble(data['insulin']),
      cortisol: _parseDouble(data['cortisol']),
      testosterone: _parseDouble(data['testosterone']),
      estradiol: _parseDouble(data['estradiol'] ?? data['e2']),
      progesterone: _parseDouble(data['progesterone']),
      prolactin: _parseDouble(data['prolactin']),
      fsh: _parseDouble(data['fsh']),
      lh: _parseDouble(data['lh']),
      createdAt: DateTime.now(),
    );
  }

  BloodTestResult _mapCSVToBloodTest(Map<String, String> data) {
    // Normalize keys for robust matching (handles Turkish diacritics)
    final norm = <String, String>{};
    data.forEach((k, v) => norm[_normalizeTurkish(k.toLowerCase())] = v);

    String? s(List<String> keys) {
      for (final k in keys.map(_normalizeTurkish)) {
        if (norm.containsKey(k)) return norm[k];
      }
      return null;
    }

    return BloodTestResult(
      userId: 0,
      testDate: s(['test_date', 'tarih']) ?? DateTime.now().toIso8601String().split('T')[0],
      laboratoryName: s(['laboratory', 'laboratuvar']),
      testType: s(['test_type', 'test_tipi']),
      importSource: 'csv-import',
      hemoglobin: _parseDouble(s(['hemoglobin'])),
      hematocrit: _parseDouble(s(['hematocrit', 'hematokrit'])),
      redBloodCells: _parseDouble(s(['red_blood_cells', 'eritrosit', 'rbc'])),
      whiteBloodCells: _parseDouble(s(['white_blood_cells', 'lokosit', 'wbc'])),
      platelets: _parseDouble(s(['platelets', 'trombosit', 'plt'])),
      mcv: _parseDouble(s(['mcv'])),
      mch: _parseDouble(s(['mch'])),
      mchc: _parseDouble(s(['mchc'])),
      rdw: _parseDouble(s(['rdw'])),
      mpv: _parseDouble(s(['mpv'])),
      neutrophils: _parseDouble(s(['neutrophils', 'notrofil', 'neu'])),
      lymphocytes: _parseDouble(s(['lymphocytes', 'lenfosit', 'lym'])),
      monocytes: _parseDouble(s(['monocytes', 'monosit', 'mono'])),
      eosinophils: _parseDouble(s(['eosinophils', 'eozinofil', 'eos'])),
      basophils: _parseDouble(s(['basophils', 'bazofil', 'baso'])),
      iron: _parseDouble(s(['iron', 'demir'])),
      ferritin: _parseDouble(s(['ferritin'])),
      transferrin: _parseDouble(s(['transferrin'])),
      tibc: _parseDouble(s(['tibc', 'total iron binding capacity'])),
      transferrinSaturation: _parseDouble(s(['transferrin_saturation', 'saturation'])),
      glucose: _parseDouble(s(['glucose', 'glukoz'])),
      creatinine: _parseDouble(s(['creatinine', 'kreatinin'])),
      alt: _parseDouble(s(['alt'])),
      ast: _parseDouble(s(['ast'])),
      alp: _parseDouble(s(['alp'])),
      ggt: _parseDouble(s(['ggt'])),
      bilirubin: _parseDouble(s(['bilirubin'])),
      directBilirubin: _parseDouble(s(['direct_bilirubin'])),
      albumin: _parseDouble(s(['albumin'])),
      totalProtein: _parseDouble(s(['total_protein'])),
      urea: _parseDouble(s(['urea', 'bun', 'ure'])),
      uricAcid: _parseDouble(s(['uric_acid'])),
      gfr: _parseDouble(s(['gfr', 'egfr'])),
      totalCholesterol: _parseDouble(s(['total_cholesterol'])),
      ldlCholesterol: _parseDouble(s(['ldl_cholesterol'])),
      hdlCholesterol: _parseDouble(s(['hdl_cholesterol'])),
      triglycerides: _parseDouble(s(['triglycerides', 'trigliserid'])),
      nonHdlCholesterol: _parseDouble(s(['non_hdl_cholesterol'])),
      hba1c: _parseDouble(s(['hba1c', 'a1c'])),
      fructosamine: _parseDouble(s(['fructosamine'])),
      tsh: _parseDouble(s(['tsh'])),
      t3: _parseDouble(s(['t3'])),
      t4: _parseDouble(s(['t4'])),
      freeT3: _parseDouble(s(['free_t3', 'ft3'])),
      freeT4: _parseDouble(s(['free_t4', 'ft4'])),
      sodium: _parseDouble(s(['sodium', 'na', 'sodyum'])),
      potassium: _parseDouble(s(['potassium', 'k', 'potasyum'])),
      chloride: _parseDouble(s(['chloride', 'cl', 'klor'])),
      calcium: _parseDouble(s(['calcium', 'ca', 'kalsiyum'])),
      magnesium: _parseDouble(s(['magnesium', 'mg', 'magnezyum'])),
      phosphorus: _parseDouble(s(['phosphorus', 'p', 'fosfor', 'fosfat'])),
      vitaminB12: _parseDouble(s(['vitamin_b12', 'b12'])),
      vitaminD: _parseDouble(s(['vitamin_d', 'vit d'])),
      folate: _parseDouble(s(['folate', 'folat'])),
      vitaminA: _parseDouble(s(['vitamin_a', 'retinol'])),
      vitaminE: _parseDouble(s(['vitamin_e', 'alpha_tocopherol', 'alpha-tocopherol'])),
      vitaminC: _parseDouble(s(['vitamin_c', 'ascorbic_acid', 'ascorbic acid'])),
      cea: _parseDouble(s(['cea'])),
      afp: _parseDouble(s(['afp'])),
      ca125: _parseDouble(s(['ca125', 'ca_125'])),
      ca199: _parseDouble(s(['ca199', 'ca_19_9'])),
      ca153: _parseDouble(s(['ca153', 'ca_15_3'])),
      psa: _parseDouble(s(['psa'])),
      troponin: _parseDouble(s(['troponin', 'troponin_i'])),
      ckMb: _parseDouble(s(['ck_mb', 'ckmb'])),
      ldh: _parseDouble(s(['ldh'])),
      bnp: _parseDouble(s(['bnp'])),
      crp: _parseDouble(s(['crp'])),
      esr: _parseDouble(s(['esr', 'sedimentasyon'])),
      procalcitonin: _parseDouble(s(['procalcitonin', 'pct'])),
      insulin: _parseDouble(s(['insulin'])),
      cortisol: _parseDouble(s(['cortisol'])),
      testosterone: _parseDouble(s(['testosterone'])),
      estradiol: _parseDouble(s(['estradiol', 'e2'])),
      progesterone: _parseDouble(s(['progesterone'])),
      prolactin: _parseDouble(s(['prolactin'])),
      fsh: _parseDouble(s(['fsh'])),
      lh: _parseDouble(s(['lh'])),
      createdAt: DateTime.now(),
    );
  }

  String _normalizeTurkish(String input) {
    return input
        .replaceAll('\u0131', 'i') // ı
        .replaceAll('\u011f', 'g') // ğ
        .replaceAll('\u015f', 's') // ş
        .replaceAll('\u00f6', 'o') // ö
        .replaceAll('\u00e7', 'c') // ç
        .replaceAll('\u00fc', 'u'); // ü
  }

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '.'));
    }
    return null;
  }
}

/// Result of data import operation
class ImportResult {
  final bool isSuccess;
  final String? errorMessage;
  final String source;
  final List<BloodTestResult> testResults;
  final Map<String, dynamic>? metadata;

  const ImportResult({
    required this.isSuccess,
    this.errorMessage,
    required this.source,
    this.testResults = const [],
    this.metadata,
  });

  factory ImportResult.success({
    required String source,
    required List<BloodTestResult> testResults,
    Map<String, dynamic>? metadata,
  }) {
    return ImportResult(
      isSuccess: true,
      source: source,
      testResults: testResults,
      metadata: metadata,
    );
  }

  factory ImportResult.error({
    required String message,
    required String source,
    Map<String, dynamic>? metadata,
  }) {
    return ImportResult(
      isSuccess: false,
      errorMessage: message,
      source: source,
      metadata: metadata,
    );
  }

  @override
  String toString() {
    if (isSuccess) {
      return 'ImportResult.success(source: $source, results: ${testResults.length})';
    } else {
      return 'ImportResult.error(source: $source, message: $errorMessage)';
    }
  }
}