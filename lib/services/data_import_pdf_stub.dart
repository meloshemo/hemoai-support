import 'dart:typed_data';

/// Stub helper for platforms where PDF OCR is not available (e.g., Web)
class PdfOcrHelper {
  static Future<String> extractTextFromPdfBytes(Uint8List pdfBytes) async {
    throw UnsupportedError('PDF OCR not supported on this platform');
  }
}
