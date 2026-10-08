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
}
