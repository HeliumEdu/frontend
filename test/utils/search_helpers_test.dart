import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/utils/search_helpers.dart';

// Mirrors platform/helium/common/tests/utils/testcasesearchutils.py. Keep the
// cases in step so a query means the same thing on both sides.
void main() {
  group('SearchHelper.normalize', () {
    test('lowercases and folds diacritics', () {
      expect(SearchHelper.normalize('Café Naïve Über'), 'cafe naive uber');
    });

    test('folds typographic double quotes to straight quotes', () {
      expect(SearchHelper.normalize('\u201Cquoted\u201D \u201Elow\u201F'), '"quoted" "low"');
    });

    test('folds letters that expand to several', () {
      expect(SearchHelper.normalize('Ærø Łódź Œuvre Þing'), 'aero lodz oeuvre thing');
    });

    test('folds sharp s to a single s', () {
      expect(SearchHelper.normalize('Straße'), 'strase');
    });

    test('drops combining marks and keeps unmapped characters', () {
      expect(SearchHelper.normalize('é 日本 🎓'), 'e 日本 🎓');
    });
  });

  group('SearchHelper.matches', () {
    test('every whitespace-separated term must appear', () {
      expect(SearchHelper.matches('Krebs cycle overview', 'krebs overview'), isTrue);
      expect(SearchHelper.matches('Krebs quiz prep', 'krebs overview'), isFalse);
    });

    test('is case- and accent-insensitive', () {
      expect(SearchHelper.matches('Café Notes', 'CAFE'), isTrue);
    });

    test('strips edge punctuation but keeps internal punctuation', () {
      expect(SearchHelper.matches('read p.42-50', 'p.42-50 read.'), isTrue);
      expect(SearchHelper.matches('c', 'c++'), isTrue);
    });

    test('double-quoted span must match as a contiguous phrase', () {
      expect(SearchHelper.matches('Lab Report Draft', '"lab report"'), isTrue);
      expect(SearchHelper.matches('Report on the lab', '"lab report"'), isFalse);
      expect(SearchHelper.matches('Report on the lab', 'lab report'), isTrue);
    });

    test('typographic double quotes delimit a phrase like straight quotes', () {
      expect(SearchHelper.matches('Study Session Template', '\u201Cstudy template\u201D'), isFalse);
      expect(SearchHelper.matches('Lab Report Draft', '\u201Clab report\u201D'), isTrue);
    });

    test('phrase collapses internal whitespace and strips edge punctuation', () {
      expect(SearchHelper.matches('weekend plan', '"Weekend   plan."'), isTrue);
    });

    test('unmatched and single quotes are ordinary characters', () {
      expect(SearchHelper.matches("don't forget", "don't 'forget'"), isTrue);
      expect(SearchHelper.matches('draft', 'draft"'), isTrue);
    });

    test('blank or punctuation-only query matches everything', () {
      expect(SearchHelper.matches('anything', '   '), isTrue);
      expect(SearchHelper.matches('anything', '"" ,'), isTrue);
    });
  });

  group('SearchHelper.normalizeQuery', () {
    test('trims, folds typographic double quotes, and normalizes like haystacks', () {
      expect(SearchHelper.normalizeQuery('  \u201CLab Report\u201D Caf\u00e9 '), '"lab report" cafe');
    });

    test('leaves straight quotes and single quotes untouched', () {
      expect(SearchHelper.normalizeQuery('"lab" don\'t'), '"lab" don\'t');
    });
  });

  group('SearchHelper.matchesAny', () {
    test('terms may be satisfied across different fields', () {
      expect(SearchHelper.matchesAny(['Meeting', 'Project Alpha'], 'alpha meeting'), isTrue);
    });

    test('skips null and empty fields', () {
      expect(SearchHelper.matchesAny(['', null, 'Café Notes'], 'cafe'), isTrue);
    });
  });
}
