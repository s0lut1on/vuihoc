# Bilingual UI

The app supports Vietnamese and English. Almost every user-facing string is localized, and the user can switch languages on most screens.

## Files

- `math-app/frontend/lib/l10n/app_localizations.dart`
- `math-app/frontend/lib/l10n/` (ARB files)
- `math-app/frontend/lib/widgets/language_switcher.dart`
- `math-app/frontend/lib/providers/app_providers.dart`
- `math-app/frontend/lib/main.dart`

## Supported Locales

- `vi_VN` — Vietnamese (default)
- `en_GB` — English

## Locale Switching

- `localeProvider` is a Riverpod `StateProvider<Locale>`.
- `LanguageSwitcher` toggles between `vi` and `en`.
- The selected locale is saved to Hive (`settings` box, key `locale`) on startup load.
- `MaterialApp.router` uses the watched locale and delegates to `AppLocalizations` plus Flutter's built-in Material/Cupertino localizations.

## Exercise Translations

- Most exercises have both `question_vi` / `question_en` and `hint_vi` / `hint_en`.
- Screens choose text based on `locale.languageCode`.

## TTS Language

- The TTS service passes `vi-VN` or `en-GB` to the Web Speech API depending on the active locale.
