import 'package:flutter/widgets.dart';
import '../services/localization_service.dart';

extension LocalizationContextX on BuildContext {
  LocalizationService get loc => LocalizationService();
  String t(String key, {String? defaultValue}) => loc.getString(key, defaultValue: defaultValue);
  String tParams(String key, Map<String, String> params, {String? defaultValue}) =>
      loc.getStringWithParams(key, params, defaultValue: defaultValue);
}
