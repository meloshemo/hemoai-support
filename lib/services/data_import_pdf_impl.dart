import 'dart:typed_data';
import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';

/// IO-platform helper to rasterize PDF pages and extract text via ML Kit OCR.
class PdfOcrHelper {
  /// Rasterizes up to [maxPages] pages (for performance) and runs OCR.
  /// Returns a concatenated text of recognized content.
  static Future<String> extractTextFromPdfBytes(Uint8List pdfBytes, {int maxPages = 5}) async {
    final buffer = StringBuffer();

    // Create recognizer once for all pages
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      int pageCount = 0;
      // printing's raster returns a stream of PdfRaster pages
      final rasterStream = Printing.raster(pdfBytes, dpi: 144);
      await for (final page in rasterStream) {
        if (pageCount >= maxPages) break;
        pageCount++;
        final pngBytes = await page.toPng();

        // Write PNG to a temp file for ML Kit input
        final tempDir = await getTemporaryDirectory();
        final tmpFile = File('${tempDir.path}/hemoai_pdf_ocr_${DateTime.now().microsecondsSinceEpoch}_$pageCount.png');
        await tmpFile.writeAsBytes(pngBytes, flush: true);

        try {
          final inputImage = InputImage.fromFilePath(tmpFile.path);
          final recognized = await recognizer.processImage(inputImage);
          final text = recognized.text.trim();
          if (text.isNotEmpty) {
            buffer.writeln(text);
            buffer.writeln('\n');
          }
        } finally {
          // Clean up temp image
          if (await tmpFile.exists()) {
            try { await tmpFile.delete(); } catch (_) {}
          }
        }
      }
    } finally {
      await recognizer.close();
    }

    return buffer.toString();
  }
}
