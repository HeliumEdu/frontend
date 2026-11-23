import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/core/cache_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CacheService cacheService;
  late int quickResumes;
  late int inactivityResumes;

  setUp(() {
    cacheService = CacheService();
    quickResumes = 0;
    inactivityResumes = 0;
    cacheService.addQuickResumeListener(() => quickResumes++);
    cacheService.addInactivityResumeListener(() => inactivityResumes++);
  });

  group('CacheService lifecycle', () {
    test('returning to a hidden web tab notifies quick-resume listeners', () {
      // GIVEN
      cacheService.didChangeAppLifecycleState(AppLifecycleState.inactive);
      cacheService.didChangeAppLifecycleState(AppLifecycleState.hidden);

      // WHEN
      cacheService.didChangeAppLifecycleState(AppLifecycleState.inactive);
      cacheService.didChangeAppLifecycleState(AppLifecycleState.resumed);

      // THEN
      expect(quickResumes, 1, reason: 'Web reports a hidden tab as hidden, never paused');
      expect(inactivityResumes, 0);
    });

    test('a native background round trip notifies quick-resume listeners once', () {
      // GIVEN
      for (final state in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
      ]) {
        cacheService.didChangeAppLifecycleState(state);
      }

      // WHEN
      for (final state in [
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        cacheService.didChangeAppLifecycleState(state);
      }

      // THEN
      expect(quickResumes, 1);
      expect(inactivityResumes, 0, reason: 'A quick return stays under the inactivity threshold');
    });

    test('regaining focus without hiding notifies nothing', () {
      // WHEN
      cacheService.didChangeAppLifecycleState(AppLifecycleState.inactive);
      cacheService.didChangeAppLifecycleState(AppLifecycleState.resumed);

      // THEN
      expect(quickResumes, 0, reason: 'Losing focus without hiding is not a return');
    });
  });

  group('CacheService in-place refresh', () {
    late DateTime now;
    late CacheService clockedService;
    late int inPlaceRefreshes;
    late int clockedQuickResumes;
    late int clockedInactivityResumes;

    void returnAfter(Duration away, {bool hide = true}) {
      clockedService.didChangeAppLifecycleState(AppLifecycleState.inactive);
      if (hide) {
        clockedService.didChangeAppLifecycleState(AppLifecycleState.hidden);
      }
      now = now.add(away);
      if (hide) {
        clockedService.didChangeAppLifecycleState(AppLifecycleState.inactive);
      }
      clockedService.didChangeAppLifecycleState(AppLifecycleState.resumed);
    }

    setUp(() {
      now = DateTime(2026, 11, 22, 9);
      clockedService = CacheService(now: () => now);
      inPlaceRefreshes = 0;
      clockedQuickResumes = 0;
      clockedInactivityResumes = 0;
      clockedService.addInPlaceRefreshListener(() => inPlaceRefreshes++);
      clockedService.addQuickResumeListener(() => clockedQuickResumes++);
      clockedService.addInactivityResumeListener(
        () => clockedInactivityResumes++,
      );
    });

    test('regaining focus after a minute refreshes in place', () {
      // WHEN
      returnAfter(const Duration(minutes: 1), hide: false);

      // THEN
      expect(
        inPlaceRefreshes,
        1,
        reason: 'A window beside another app never hides',
      );
      expect(clockedInactivityResumes, 0);
    });

    test('regaining focus within a minute refreshes nothing', () {
      // WHEN
      returnAfter(const Duration(seconds: 59), hide: false);

      // THEN
      expect(inPlaceRefreshes, 0);
      expect(clockedQuickResumes, 0);
    });

    test(
      'returning to a tab hidden for a few minutes refreshes in place and the cheap state',
      () {
        // WHEN
        returnAfter(const Duration(minutes: 5));

        // THEN
        expect(inPlaceRefreshes, 1);
        expect(clockedQuickResumes, 1);
        expect(clockedInactivityResumes, 0);
      },
    );

    test(
      'returning after the inactivity threshold reloads instead of refreshing in place',
      () {
        // WHEN
        returnAfter(const Duration(minutes: 11));

        // THEN
        expect(clockedInactivityResumes, 1);
        expect(inPlaceRefreshes, 0);
      },
    );

    test(
      'a second return within a minute of a refresh only refreshes the cheap state',
      () {
        // GIVEN
        returnAfter(const Duration(minutes: 2));

        // WHEN
        returnAfter(const Duration(seconds: 30));

        // THEN
        expect(
          inPlaceRefreshes,
          1,
          reason: 'The minute counts from the last refresh',
        );
        expect(clockedQuickResumes, 2);
      },
    );
  });
}
