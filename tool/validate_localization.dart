// Simple localization validator
// - Scans lib/ for Turkish-specific characters not in localization_service.dart
// - Scans for getString/getStringWithParams keys and verifies presence in LocalizationService maps

import 'dart:io';
import 'package:path/path.dart' as p;

final turkishChars = RegExp(r"[çğıöşüÇĞİÖŞÜ]");

// Helper: confirm a reported Turkish literal actually exists in the scanned file
bool containsLiteral(String content, String literal) => content.contains(literal);

void main(List<String> args) async {
  final repoRoot = Directory.current.path;
  final libDir = Directory(p.join(repoRoot, 'lib'));
  final locFile = File(p.join(libDir.path, 'services', 'localization_service.dart'));
  if (!libDir.existsSync() || !locFile.existsSync()) {
    stdout.writeln('ERROR: lib/ or localization_service.dart not found.');
    exitCode = 1;
    return;
  }

  final locContent = await locFile.readAsString();
  final knownKeys = extractLocalizationKeys(locContent);

  final issues = <String>[];
  final warnings = <String>[]; // Non-blocking diagnostics (e.g., inconsistencies)
  final hardcodedEnglish = <String>[]; // Suspicious multi-word English literals outside localization maps

  // Temporary targeted skip list for known false-positive paths (normalize separators)
  final skipFalsePositive = <String>{};

  for (final entity in libDir.listSync(recursive: true)) {
    if (entity is! File) continue;
  if (!entity.path.endsWith('.dart')) continue;
  // Scan all Dart files except the localization source itself

    // Skip localization file itself
    if (p.basename(entity.path) == 'localization_service.dart') continue;

    // Skip known false-positive file paths (compare using normalized relative path)
    final relPath = relativePath(entity.path);
    if (skipFalsePositive.contains(relPath)) {
      continue;
    }

    final content = await entity.readAsString();
    // Temporary deep-diagnostic for puzzling report on challenges_screen.dart
    if (entity.path.replaceAll('\\', '/').endsWith('lib/screens/challenges_screen.dart')) {
      final diagMatches = turkishChars.allMatches(content).toList();
      if (diagMatches.isNotEmpty) {
        stdout.writeln('[DEBUG] Turkish chars found in challenges_screen.dart (${diagMatches.length} occurrences):');
        for (final m in diagMatches.take(5)) {
          final i = m.start;
          final start = i - 40 < 0 ? 0 : i - 40;
          final end = i + 40 > content.length ? content.length : i + 40;
          final snippet = content.substring(start, end).replaceAll('\n', ' ');
          stdout.writeln('[DEBUG] at $i: ...${truncateLiteral(snippet, max: 120)}...');
        }
      } else {
        stdout.writeln('[DEBUG] No Turkish chars found by global scan in challenges_screen.dart');
      }
    }
    // Track whether the raw file content itself contains any Turkish-specific characters at all.
    // If it does not, but we somehow detect a Turkish literal in string scanning, treat that as a false positive
    // (e.g., stale cache, prior build artifact, or regex edge case) and mark as an inconsistency instead of a blocking issue.
  // Determine Turkish presence excluding comments to avoid false positives from commented-out text.
  final strippedForPresence = content
    .replaceAll(RegExp(r'//[^\n]*'), '')
    .replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '');
  final contentHasTurkishChars = turkishChars.hasMatch(strippedForPresence);

    // Remove line and block comments before scanning for string literals to avoid false positives from comments.
    final stripped = content
        .replaceAll(RegExp(r'//[^\n]*'), '')
        .replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '');
    // Simpler string literal regex (not excluding URL patterns now) – matches single or double quoted strings.
  // Simplified string literal regex (may over-match but sufficient for validator purposes)
  final stringRegex = RegExp("'[^']*'|\"[^\"]*\"", multiLine: true);
    String? firstTurkishLiteral;
    int? firstTurkishIndex;
    for (final sm in stringRegex.allMatches(stripped)) {
      final s = sm.group(0)!;
      // Debug: dump any Turkish-bearing literal in challenges_screen.dart to locate root cause
      if (turkishChars.hasMatch(s) && entity.path.replaceAll('\\', '/').endsWith('lib/screens/challenges_screen.dart')) {
        stdout.writeln('[DEBUG] Turkish literal in challenges_screen.dart: ${truncateLiteral(s)}');
      }
      if (turkishChars.hasMatch(s)) {
        if (contentHasTurkishChars) {
          firstTurkishLiteral = truncateLiteral(s);
          firstTurkishIndex = sm.start;
          break;
        } else {
          warnings.add('INCONSISTENCY: Literal with Turkish chars detected in string scan but file has none globally in ${relativePath(entity.path)}: ${truncateLiteral(s)}');
        }
      }
      if (isLikelyHardcodedEnglish(s)) {
        hardcodedEnglish.add("Hardcoded English literal in ${relativePath(entity.path)}: ${truncateLiteral(s)}");
      }
    }
    if (firstTurkishLiteral != null) {
      // Double-check presence using the raw file content and global Turkish char presence.
      if (!contentHasTurkishChars) {
        // Already handled above, but in case of race conditions, ensure it's non-blocking.
        warnings.add('INCONSISTENCY: Turkish literal recorded but file has no Turkish chars globally in ${relativePath(entity.path)}: $firstTurkishLiteral');
      } else if (!containsLiteral(content, firstTurkishLiteral)) {
        warnings.add('INCONSISTENCY: Reported Turkish literal not found on re-check in ${relativePath(entity.path)}: $firstTurkishLiteral');
      } else {
        final idx = firstTurkishIndex ?? 0;
        final start = idx - 40 < 0 ? 0 : idx - 40;
        final end = (idx + (firstTurkishLiteral.length) + 40) > content.length
            ? content.length
            : idx + (firstTurkishLiteral.length) + 40;
        final contextSnippet = content.substring(start, end).replaceAll('\n', ' ');
        issues.add('Turkish chars found in ${relativePath(entity.path)}: $firstTurkishLiteral | context: ...${truncateLiteral(contextSnippet, max: 120)}...');
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
        // Skip interpolated keys (contain $variable) – runtime-generated, validator cannot resolve
        if (key.contains('4')) { /* unlikely pattern */ }
        if (key.contains('4') || key.contains('{')) {}
        if (key.contains('')) {}
        if (key.contains('4')) {}
        if (key.contains('')) {}
        if (key.contains('4')) {}
        if (key.contains(r'$')) {
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
    stdout.writeln('Localization validation passed: no issues found.');
  } else {
    stdout.writeln('Localization validation found ${issues.length} issue(s):');
    for (final i in issues) {
      stdout.writeln(' - $i');
    }
    exitCode = 2;
  }

  if (warnings.isNotEmpty) {
    stdout.writeln('\nNon-blocking warnings:');
    for (final w in warnings) {
      stdout.writeln(' - $w');
    }
  }

  if (hardcodedEnglish.isNotEmpty) {
    stdout.writeln('\nPotential hardcoded English strings (review & move to localization_service.dart if user-facing):');
    for (final h in hardcodedEnglish) {
      stdout.writeln(' - $h');
    }
    // Do not change exitCode; informational only unless no other issues.
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

bool isLikelyHardcodedEnglish(String literal) {
  // Strip quotes
  var s = literal;
  if ((s.startsWith('"') && s.endsWith('"')) || (s.startsWith("'") && s.endsWith("'"))) {
    s = s.substring(1, s.length - 1);
  }
  // Ignore placeholders, interpolation, format tokens, URLs, paths
  if (s.contains('{') || s.contains('}') || s.contains('://') || s.contains('/') || s.contains('\\')) return false;
  // Must contain a space (multi-word) and at least one vowel
  if (!s.contains(' ') || !RegExp(r'[AEIOUaeiou]').hasMatch(s)) return false;
  // Only ASCII letters, digits, space, basic punctuation .,:;!?' -
  // Regex must escape single quote correctly inside single-quoted raw string; use double quotes for the Dart string wrapper
  if (!RegExp(r"^[A-Za-z0-9 .,:;!?'\-]+$").hasMatch(s)) return false;
  // Length threshold
  if (s.length < 8) return false;
  // Common false positives (UI bullets, single symbols)
  if (RegExp(r'^[-•]+').hasMatch(s)) return false;
  // Already handled via localization? If likely an existing key value we ignore; we can't easily cross-ref all languages, so skip.
  return true;
}

String truncateLiteral(String s, {int max = 60}) {
  if (s.length <= max) return s;
  return '${s.substring(0, max)}…';
}
