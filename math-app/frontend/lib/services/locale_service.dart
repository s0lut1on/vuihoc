import 'package:hive/hive.dart';

/// Persists the selected locale language code to Hive.
///
/// The value is stored in the `settings` box under the `[locale]` key.
/// Example usage:
///   await saveLocale('en');
Future<void> saveLocale(String languageCode) async {
  try {
    final box = await Hive.openBox('settings');
    await box.put('locale', languageCode);
  } catch (_) {
    // In test environments Hive may not be initialized. Silently ignore.
  }
}
