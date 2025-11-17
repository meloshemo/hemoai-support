import 'package:flutter/foundation.dart';
import 'localization_service.dart';

class DailyAdviceService extends ChangeNotifier {
  static final DailyAdviceService _instance = DailyAdviceService._internal();
  factory DailyAdviceService() => _instance;
  DailyAdviceService._internal();

  void initialize() {
    // Reserved for future persistence/config.
  }

  // All quotes for current locale
  List<String> getAllQuotes(LocalizationService loc) {
    final baseRaw = loc.getString('daily_quotes_list');
    final enrichedRaw = loc.getString('daily_quotes_list_enriched');
    final combined = <String>[];
    if (baseRaw.isNotEmpty) {
      combined.addAll(baseRaw.split('\n'));
    }
    if (enrichedRaw.isNotEmpty) {
      combined.addAll(enrichedRaw.split('\n'));
    }
    return combined
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList(growable: false);
  }

  // Deterministic index for a specific calendar date (local)
  int _indexForDate(DateTime date, int length) {
    if (length <= 0) return 0;
    final seed = date.year * 1000 + date.month * 50 + date.day;
    return seed % length;
  }

  // Quote for a specific date
  String getQuoteForDate(LocalizationService loc, DateTime date) {
    final lines = getAllQuotes(loc);
    if (lines.isEmpty) return '';
    final idx = _indexForDate(date, lines.length);
    return lines[idx];
  }

  // Deterministic pick for the current day
  String getTodayQuoteText(LocalizationService loc) {
    return getQuoteForDate(loc, DateTime.now());
  }
}
