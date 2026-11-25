import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/l10n/app_localizations.dart';
import 'package:heliumapp/utils/locale_helpers.dart';

void main() {
  const supported = [Locale('en'), Locale('es'), Locale('en', 'XA')];

  group('HeliumLocale.resolve', () {
    test('resolves a regional variant to its language', () {
      // WHEN
      final resolved = HeliumLocale.resolve([const Locale('es', 'MX')], supported);

      // THEN
      expect(resolved, const Locale('es'));
    });

    test('picks the first preference the app is translated into', () {
      // WHEN
      final resolved = HeliumLocale.resolve([const Locale('fr', 'FR'), const Locale('es', 'ES')], supported);

      // THEN
      expect(resolved, const Locale('es'), reason: 'French is untranslated, so the next preference applies');
    });

    test('falls back to English when no preference is translated', () {
      // WHEN
      final resolved = HeliumLocale.resolve([const Locale('ja', 'JP'), const Locale('de')], supported);

      // THEN
      expect(resolved, const Locale('en'));
    });

    test('falls back to English without preferences', () {
      // WHEN
      final resolved = HeliumLocale.resolve(null, supported);

      // THEN
      expect(resolved, const Locale('en'));
    });

    test('resolves regional English to plain English', () {
      // WHEN
      final resolved = HeliumLocale.resolve([const Locale('en', 'GB')], supported);

      // THEN
      expect(resolved, const Locale('en'), reason: 'A regional entry is only chosen by an exact match');
    });

    test('picks a regional entry on an exact match', () {
      // WHEN
      final resolved = HeliumLocale.resolve([const Locale('en', 'XA')], supported);

      // THEN
      expect(resolved, const Locale('en', 'XA'));
    });
  });

  group('HeliumLocale.languageFor', () {
    test('reports an exactly matched language', () {
      // WHEN
      final language = HeliumLocale.languageFor([const Locale('es')], supported);

      // THEN
      expect(language, 'es');
    });

    test('reports a regional variant as its language code', () {
      // WHEN
      final language = HeliumLocale.languageFor([const Locale('es', 'MX')], supported);

      // THEN
      expect(language, 'es');
    });

    test('reports English for a language the app is not translated into', () {
      // WHEN
      final language = HeliumLocale.languageFor([const Locale('es', 'ES')], const [Locale('en')]);

      // THEN
      expect(language, 'en', reason: 'A Spanish device on an English-only build reports the displayed language');
    });

    test('reports the language code of a regional entry, never its region', () {
      // WHEN
      final language = HeliumLocale.languageFor([const Locale('en', 'XA')], supported);

      // THEN
      expect(language, 'en');
    });
  });

  group('HeliumLocale.languagesIn', () {
    test('lists each language once, in order', () {
      // WHEN
      final languages = HeliumLocale.languagesIn(supported);

      // THEN
      expect(languages, ['en', 'es']);
    });

    test('names every translated language in itself', () {
      // WHEN
      final unnamed = HeliumLocale.languagesIn(AppLocalizations.supportedLocales)
          .where((language) => !HeliumLocale.nativeNames.containsKey(language));

      // THEN
      expect(unnamed, isEmpty, reason: 'Add each new language to HeliumLocale.nativeNames');
    });
  });

  group('HeliumLocale.offersLanguageChoice', () {
    test('shows the choice with two languages and an offered stored language', () {
      // WHEN
      final offered = HeliumLocale.offersLanguageChoice(languages: ['en', 'es'], stored: 'es');

      // THEN
      expect(offered, isTrue);
    });

    test('hides the choice with one language', () {
      // WHEN
      final offered = HeliumLocale.offersLanguageChoice(languages: ['en'], stored: 'en');

      // THEN
      expect(offered, isFalse);
    });

    test('hides the choice when the stored language is not offered', () {
      // WHEN
      final offered = HeliumLocale.offersLanguageChoice(languages: ['en', 'es'], stored: 'fr');

      // THEN
      expect(offered, isFalse, reason: 'Saving must leave a language set on another build alone');
    });
  });
}
