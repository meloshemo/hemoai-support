// Simple localization validator
// - Scans lib/ for Turkish-specific characters not in localization_service.dart
// - Scans for getString/getStringWithParams keys and verifies presence in LocalizationService maps

import 'dart:io';
import 'package:path/path.dart' as p;

final turkishChars = RegExp(r"[çğıöşüÇĞİÖŞÜ]");

void main(List<String> args) async {
  final repoRoot = Directory.current.path;
  final libDir = Directory(p.join(repoRoot, 'lib'));
  final locFile = File(p.join(libDir.path, 'services', 'localization_service.dart'));
  if (!libDir.existsSync() || !locFile.existsSync()) {
    print('ERROR: lib/ or localization_service.dart not found.');
    exitCode = 1;
    return;
  }

  final locContent = await locFile.readAsString();
  final knownKeys = extractLocalizationKeys(locContent);

  final issues = <String>[];

  for (final entity in libDir.listSync(recursive: true)) {
    if (entity is! File) continue;
    if (!entity.path.endsWith('.dart')) continue;

    // Skip localization file itself
    if (p.basename(entity.path) == 'localization_service.dart') continue;

    final content = await entity.readAsString();

    // 1) Turkish char scan inside string literals only
  final stringRegex = RegExp(r'''('(?:[^'\\]|\\.)*'|"(?:[^"\\]|\\.)*")''', multiLine: true);
    for (final sm in stringRegex.allMatches(content)) {
      final s = sm.group(0)!;
      if (turkishChars.hasMatch(s)) {
        issues.add('Turkish chars found in ${relativePath(entity.path)}');
        break;
      }
    }

    // 2) Key usage scan only if file imports localization_service.dart
    final importsLocalization = content.contains("services/localization_service.dart");
    if (importsLocalization) {
      // Patterns to match:
      // - loc.getString('key') or LocalizationService().getString('key')
      // - loc.getStringWithParams('key', ...) or LocalizationService().getStringWithParams
      // - LocalizationService.translate('key')
      // - context.t('key') and context.tParams('key', ...)
      // Pattern 1: X.getString('key') or X.getStringWithParams('key', ...)
      final pGetString = RegExp(r"([A-Za-z0-9_\.\)]+)\.getString(?:WithParams)?\(\s*'([^']+)'", multiLine: true);
      for (final m in pGetString.allMatches(content)) {
        final receiver = m.group(1)!;
        final key = m.group(2)!;
        // Filter out SharedPreferences usages like prefs.getString('...')
        final receiverLower = receiver.toLowerCase();
        if (receiverLower.contains('prefs') || receiverLower.contains('sharedpreferences')) {
          continue;
        }
        if (!knownKeys.contains(key)) {
          issues.add("Missing key '$key' referenced in ${relativePath(entity.path)}");
        }
      }

      // Pattern 2: LocalizationService.translate('key')
      final pTranslate = RegExp(r"translate\(\s*'([^']+)'", multiLine: true);
      for (final m in pTranslate.allMatches(content)) {
        final key = m.group(1)!;
        if (!knownKeys.contains(key)) {
          issues.add("Missing key '$key' referenced in ${relativePath(entity.path)}");
        }
      }

      // Pattern 3: context.t('key') / context.tParams('key', ...)
      final pContextT = RegExp(r"\.t(?:Params)?\(\s*'([^']+)'", multiLine: true);
      for (final m in pContextT.allMatches(content)) {
        final key = m.group(1)!;
        if (!knownKeys.contains(key)) {
          issues.add("Missing key '$key' referenced in ${relativePath(entity.path)}");
        }
      }
    }
  }

  if (issues.isEmpty) {
    print('Localization validation passed: no issues found.');
  } else {
    print('Localization validation found ${issues.length} issue(s):');
    for (final i in issues) {
      print(' - ' + i);
    }
    exitCode = 2;
  }
}

Set<String> extractLocalizationKeys(String content) {
  final keys = <String>{};
  // Basic pattern: '<key>': {
  final keyRegex = RegExp(r"\n\s*'([^']+)'\s*:\s*\{", multiLine: true);
  for (final m in keyRegex.allMatches(content)) {
    keys.add(m.group(1)!);
  }
  return keys;
}

String relativePath(String path) {
  final root = Directory.current.path;
  if (path.startsWith(root)) return path.substring(root.length + 1).replaceAll('\\', '/');
  return path.replaceAll('\\', '/');
}
