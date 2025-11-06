// Web implementation using dart:html
import 'dart:html' as html show AnchorElement, Blob, Url;
import 'dart:typed_data';

void downloadWebFile({
  required String content,
  required String filename,
  required String contentType,
}) {
  final blob = html.Blob([content], contentType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
}

void downloadWebFileBinary({
  required List<int> bytes,
  required String filename,
  required String contentType,
}) {
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
}

