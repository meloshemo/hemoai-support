// Stub for non-web platforms
export 'export_service_web_stub.dart' show downloadWebFile, downloadWebFileBinary;

void downloadWebFile({
  required String content,
  required String filename,
  required String contentType,
}) {
  // Stub - no-op on non-web
}

void downloadWebFileBinary({
  required List<int> bytes,
  required String filename,
  required String contentType,
}) {
  // Stub - no-op on non-web
}

