import 'package:flutter/material.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _currentLocale = const Locale('en');
  Map<String, String> _translations = {};

  Locale get currentLocale => _currentLocale;
  Map<String, String> get translations => _translations;

  void changeLocale(Locale locale) {
    _currentLocale = locale;
    notifyListeners();
  }

  void updateTranslations(Map<String, String> newTranslations) {
    _translations = newTranslations;
    notifyListeners();
  }
}