// Parses integration_test output logs and reconstructs screenshots from
// SCREENSHOT_BASE64_CHUNK/END markers into PNG files.
// Usage:
//   dart run tool/reconstruct_screenshots.dart <path-to-log.txt>
// Output files are written to build/reconstructed_screenshots/.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

final chunkPrefix = 'SCREENSHOT_BASE64_CHUNK:'; // format: PREFIX:<id>:<offset>:<data>
final endPrefix = 'SCREENSHOT_BASE64_END:';     // format: PREFIX:<id>

void main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('Usage: dart run tool/reconstruct_screenshots.dart <path-to-log.txt>');
    exit(64);
  }
  final logPath = args[0];
  final logFile = File(logPath);
  if (!await logFile.exists()) {
    stderr.writeln('Log file not found: $logPath');
    exit(66);
  }

  final outputDir = Directory('build/reconstructed_screenshots');
  if (!await outputDir.exists()) {
    await outputDir.create(recursive: true);
  }

  // Map of screenshotId -> map of offset -> chunk
  final Map<String, Map<int, String>> chunks = {};
  // Track the order of IDs encountered
  final Set<String> seenIds = {};

  // Read potentially non-UTF8-safe log (may include escape sequences) robustly.
  final rawBytes = await logFile.readAsBytes();
  String content;
  if (rawBytes.length >= 2) {
    final b0 = rawBytes[0];
    final b1 = rawBytes[1];
    // UTF-16 LE BOM 0xFF 0xFE
    if (b0 == 0xFF && b1 == 0xFE) {
      content = _decodeUtf16(rawBytes.sublist(2), Endian.little);
    } else if (b0 == 0xFE && b1 == 0xFF) { // UTF-16 BE
      content = _decodeUtf16(rawBytes.sublist(2), Endian.big);
    } else {
      try {
        content = utf8.decode(rawBytes, allowMalformed: true);
      } catch (_) {
        content = latin1.decode(rawBytes); // fallback
      }
    }
  } else {
    content = '';
  }
  final lines = content.split(RegExp(r'\r?\n'));
  String? activeId;
  int? activeOffset;
  for (final rawLine in lines) {
    final line = rawLine; // keep original for sanitization
    if (line.isEmpty) continue;
    if (line.contains(chunkPrefix)) {
      final startIndex = line.indexOf(chunkPrefix);
      final restLine = line.substring(startIndex + chunkPrefix.length);
      // Reset active chunk context
      final c1 = restLine.indexOf(':');
      if (c1 == -1) continue;
      final id = restLine.substring(0, c1);
      final rest2 = restLine.substring(c1 + 1);
      final c2 = rest2.indexOf(':');
      if (c2 == -1) continue;
      final offsetStr = rest2.substring(0, c2);
      final dataFirstRaw = rest2.substring(c2 + 1); // may include spaces / ANSI wraps
      final dataFirst = _sanitizeBase64(dataFirstRaw);
      final offset = int.tryParse(offsetStr) ?? 0;
      chunks.putIfAbsent(id, () => {});
      chunks[id]![offset] = dataFirst;
      activeId = id;
      activeOffset = offset;
      seenIds.add(id);
    } else if (line.contains(endPrefix)) {
      final startIndex = line.indexOf(endPrefix);
      final id = line.substring(startIndex + endPrefix.length).trim();
      seenIds.add(id);
      activeId = null;
      activeOffset = null;
    } else if (activeId != null && activeOffset != null) {
      final appended = _sanitizeBase64(line);
      if (appended.isNotEmpty) {
        chunks[activeId]![activeOffset] = (chunks[activeId]![activeOffset] ?? '') + appended;
      }
    }
  }

  int written = 0;
  final manifest = StringBuffer();
  manifest.writeln('# Screenshot Manifest');
  manifest.writeln('# fields: id, filename, bytes, sha256, base64_head(80)');
  for (final id in seenIds) {
    final map = chunks[id];
    if (map == null || map.isEmpty) {
      stderr.writeln('No chunks found for id $id, skipping.');
      continue;
    }
    final orderedOffsets = map.keys.toList()..sort();
    final base64Buffer = StringBuffer();
    for (final o in orderedOffsets) {
      base64Buffer.write(map[o]);
    }
    final b64 = base64Buffer.toString();
    try {
      final bytes = base64.decode(b64);
      // Give a helpful default name mapping
      final filename = _suggestNameForId(id);
      final outFile = File('${outputDir.path}/$filename');
      await outFile.writeAsBytes(bytes);
      stdout.writeln('Wrote ${outFile.path} (${bytes.length} bytes)');
      written++;
      final sha256 = _sha256Hex(bytes);
      final head = b64.length > 80 ? b64.substring(0, 80) : b64;
      manifest.writeln('$id,$filename,${bytes.length},$sha256,$head');
    } catch (e) {
      stderr.writeln('Failed to decode id $id: $e');
    }
  }

  if (written == 0) {
    stderr.writeln('No screenshots reconstructed. Ensure the log contains SCREENSHOT_BASE64_CHUNK lines.');
    exit(1);
  }

  // Write manifest file near outputs
  final manifestFile = File('build/reconstructed_screenshots/manifest.csv');
  await manifestFile.writeAsString(manifest.toString());
  stdout.writeln('Manifest: ${manifestFile.path}');
}

String _decodeUtf16(List<int> bytes, Endian endian) {
  final data = Uint8List.fromList(bytes);
  final bd = ByteData.view(data.buffer, data.offsetInBytes, data.lengthInBytes);
  final codeUnits = <int>[];
  for (int i = 0; i + 1 < bd.lengthInBytes; i += 2) {
    final unit = endian == Endian.little ? bd.getUint16(i, Endian.little) : bd.getUint16(i, Endian.big);
    codeUnits.add(unit);
  }
  return String.fromCharCodes(codeUnits);
}

String _suggestNameForId(String id) {
  // Map known IDs to human-friendly filenames used in the test flow
  switch (id) {
    case '01':
      return '01_notifications.png';
    case '02':
      return '02_dashboard.png';
    case '03':
      return '03_analysis.png';
    case '04':
      return '04_alternative_medicine.png';
    default:
      return 'screenshot_$id.png';
  }
}

String _sha256Hex(List<int> bytes) {
  final d = sha256.convert(bytes);
  return d.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}

String _sanitizeBase64(String s) {
  // Keep only base64 charset characters
  final buf = StringBuffer();
  for (final code in s.codeUnits) {
    final ch = code;
    final isAZ = ch >= 65 && ch <= 90;
    final isaz = ch >= 97 && ch <= 122;
    final is09 = ch >= 48 && ch <= 57;
    final isPlus = ch == 43;
    final isSlash = ch == 47;
    final isEq = ch == 61;
    if (isAZ || isaz || is09 || isPlus || isSlash || isEq) {
      buf.writeCharCode(ch);
    }
  }
  return buf.toString();
}
