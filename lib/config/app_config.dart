class AppConfig {
  const AppConfig._();

  static const defaultTranslationApiUrl =
      'http://100.119.152.32:8000/translate/';

  static const translationApiUrl = String.fromEnvironment(
    'TRANSLATION_API_URL',
    defaultValue: defaultTranslationApiUrl,
  );

  static Uri get translationUri => Uri.parse(translationApiUrl);

  static Uri get translationBatchUri =>
      translationUri.resolve('/translate/batch/');
}
