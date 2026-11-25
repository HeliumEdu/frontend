import 'dart:ui';

import 'package:heliumapp/l10n/app_localizations.dart';
import 'package:heliumapp/utils/date_time_helpers.dart';

class HeliumLocale {
  HeliumLocale._();

  static const fallback = Locale('en');

  /// Each language's name in itself, shown untranslated wherever a student
  /// picks a language; every translated language needs one.
  static const nativeNames = {
    'en': 'English',
  };

  static List<String> languagesIn(Iterable<Locale> supported) =>
      supported.map((locale) => locale.languageCode).toSet().toList();

  static List<String> get supportedLanguages => languagesIn(AppLocalizations.supportedLocales);

  /// Whether a student can pick a language among [languages]: only with a
  /// real choice, and never over a [stored] language this build can't offer,
  /// so saving leaves that language alone.
  static bool offersLanguageChoice({
    required List<String> languages,
    required String stored,
  }) =>
      languages.length > 1 && languages.contains(stored);

  /// The first of the device's [preferred] languages the app is translated
  /// into, matched exactly or else by language code (Mexican Spanish gets
  /// `es`); English when none is.
  static Locale resolve(List<Locale>? preferred, Iterable<Locale> supported) {
    for (final locale in preferred ?? const <Locale>[]) {
      final match = supported.where((candidate) => candidate == locale).firstOrNull ??
          supported
              .where((candidate) => candidate.languageCode == locale.languageCode && candidate.countryCode == null)
              .firstOrNull;
      if (match != null) return match;
    }
    return fallback;
  }

  /// The language code of [resolve], which is what the app displays and the
  /// API stores, never the device's own language.
  static String languageFor(List<Locale>? preferred, Iterable<Locale> supported) =>
      resolve(preferred, supported).languageCode;

  static Future<({String timeZone, String language})> detect() async =>
      (timeZone: await HeliumDateTime.detectTimeZone(), language: detectLanguage());

  static String detectLanguage() =>
      languageFor(PlatformDispatcher.instance.locales, AppLocalizations.supportedLocales);
}
