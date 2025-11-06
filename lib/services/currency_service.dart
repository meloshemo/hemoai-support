
/// Currency conversion service based on language/locale
/// Base prices are in USD, converted to local currency
class CurrencyService {
  static final CurrencyService _instance = CurrencyService._internal();
  factory CurrencyService() => _instance;
  CurrencyService._internal();

  // Base prices in USD
  static const double _basePriceMonthly = 4.99;
  static const double _basePriceYearly = 39.99;
  static const double _basePriceLifetime = 99.99;

  // Currency exchange rates (approximate, can be updated from API)
  // Format: {'currency_code': rate}
  static const Map<String, double> _exchangeRates = {
    'USD': 1.0,
    'TRY': 32.0,  // 1 USD = 32 TRY (approximate)
    'EUR': 0.92,  // 1 USD = 0.92 EUR
    'GBP': 0.79,  // 1 USD = 0.79 GBP
    'JPY': 150.0, // 1 USD = 150 JPY
    'CNY': 7.2,   // 1 USD = 7.2 CNY
    'INR': 83.0,  // 1 USD = 83 INR
    'RUB': 90.0,  // 1 USD = 90 RUB
    'BRL': 5.0,   // 1 USD = 5 BRL
    'MXN': 17.0,  // 1 USD = 17 MXN
    'KRW': 1300.0, // 1 USD = 1300 KRW
    'AUD': 1.52,  // 1 USD = 1.52 AUD
    'CAD': 1.35,  // 1 USD = 1.35 CAD
  };

  // Currency symbols
  static const Map<String, String> _currencySymbols = {
    'USD': '\$',
    'TRY': '₺',
    'EUR': '€',
    'GBP': '£',
    'JPY': '¥',
    'CNY': '¥',
    'INR': '₹',
    'RUB': '₽',
    'BRL': 'R\$',
    'MXN': '\$',
    'KRW': '₩',
    'AUD': 'A\$',
    'CAD': 'C\$',
  };

  /// Get currency code based on language
  String _getCurrencyCode(String languageCode) {
    switch (languageCode.toLowerCase()) {
      case 'tr':
        return 'TRY';
      case 'en':
        return 'USD';
      case 'es':
        return 'EUR'; // Spain uses EUR
      case 'fr':
        return 'EUR';
      case 'de':
        return 'EUR';
      case 'it':
        return 'EUR';
      case 'pt':
        return 'EUR'; // Portugal uses EUR
      case 'ru':
        return 'RUB';
      case 'ar':
        return 'USD'; // Arabic countries vary, default to USD
      default:
        return 'USD';
    }
  }

  /// Get currency symbol based on language
  String getCurrencySymbol(String languageCode) {
    final currencyCode = _getCurrencyCode(languageCode);
    return _currencySymbols[currencyCode] ?? '\$';
  }

  /// Convert USD price to local currency
  double convertPrice(double usdPrice, String languageCode) {
    final currencyCode = _getCurrencyCode(languageCode);
    final rate = _exchangeRates[currencyCode] ?? 1.0;
    return usdPrice * rate;
  }

  /// Format price with currency symbol
  String formatPrice(double price, String languageCode, {int decimals = 2}) {
    final symbol = getCurrencySymbol(languageCode);
    final convertedPrice = convertPrice(price, languageCode);
    
    // For some currencies, round to whole numbers
    if (languageCode == 'tr' || languageCode == 'ru' || languageCode == 'ja') {
      return '$symbol${convertedPrice.toStringAsFixed(0)}';
    }
    
    return '$symbol${convertedPrice.toStringAsFixed(decimals)}';
  }

  /// Get monthly price formatted for current language
  String getMonthlyPrice(String languageCode) {
    return formatPrice(_basePriceMonthly, languageCode);
  }

  /// Get yearly price formatted for current language
  String getYearlyPrice(String languageCode) {
    return formatPrice(_basePriceYearly, languageCode);
  }

  /// Get lifetime price formatted for current language
  String getLifetimePrice(String languageCode) {
    return formatPrice(_basePriceLifetime, languageCode);
  }

  /// Get raw price (converted) without symbol
  double getMonthlyPriceRaw(String languageCode) {
    return convertPrice(_basePriceMonthly, languageCode);
  }

  double getYearlyPriceRaw(String languageCode) {
    return convertPrice(_basePriceYearly, languageCode);
  }

  double getLifetimePriceRaw(String languageCode) {
    return convertPrice(_basePriceLifetime, languageCode);
  }
}

