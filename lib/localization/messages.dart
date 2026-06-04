import 'package:get/get.dart';
import 'package:ride_sharing_user_app/helper/dynamic_translation_helper.dart';

class Messages extends Translations {
  final Map<String, Map<String, String>> languages;
  Messages({required this.languages});

  @override
  Map<String, Map<String, String>> get keys {
    final Map<String, Map<String, String>> merged = {};
    languages.forEach((locale, values) {
      merged[locale] = Map<String, String>.from(values);
      if (locale.toLowerCase().startsWith('fr')) {
        merged[locale]!.addAll(DynamicTranslationHelper.frenchTranslations);
      }
    });
    return merged;
  }
}
