import 'translation_service.dart';

class LocalizationService {
  final TranslationService _translationService = TranslationService();

  Future<Map<String, String>> translateScreenStrings(
    Map<String, String> originalStrings, 
    String targetLanguage
  ) async {
    Map<String, String> translatedStrings = {};

    for (var entry in originalStrings.entries) {
      translatedStrings[entry.key] = await _translationService.translateText(
        entry.value, 
        targetLanguage
      );
    }

    return translatedStrings;
  }
}
