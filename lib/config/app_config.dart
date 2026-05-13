class AppConfig {
  const AppConfig._();

  static const ngrokScheme = 'https://';
  static const ngrokHostSuffix = '.ngrok-free.app';
  static const translationPath = '/translate/';
  static const defaultTranslationApiUrl =
      'http://127.0.0.1:8000/translate/';

  static const translationApiUrl = String.fromEnvironment(
    'TRANSLATION_API_URL',
    defaultValue: defaultTranslationApiUrl,
  );

  static Uri get translationUri => Uri.parse(translationApiUrl);

  static Uri get translationBatchUri =>
      translationUri.resolve('/translate/batch/');
}
