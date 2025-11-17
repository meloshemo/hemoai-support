import 'dart:typed_data';

/// Placeholder generator returning null to keep build stable.
/// (Previous implementation used unsupported image APIs in current version.)
Future<Uint8List?> generateMotivationImage({
  required String quote,
  String? tagline,
  int width = 1200,
  int height = 630,
  int padding = 48,
  int fontSize = 40,
}) async {
  // Returning null triggers text-only sharing fallback.
  return null;
}
