import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/utils/print_service.dart';

void main() {
  group('PrintService', () {
    final printed = <String>[];
    late PrintHandler screen;
    late PrintHandler overlay;

    setUp(() {
      printed.clear();
      screen = () async => printed.add('screen');
      overlay = () async => printed.add('overlay');
    });

    tearDown(() {
      PrintService().unregister(screen);
      PrintService().unregister(overlay);
    });

    test(
      'an overlay prints even when the screen behind it registered later',
      () async {
        // GIVEN
        PrintService().register(overlay, isOverlay: true);
        PrintService().register(screen);

        // WHEN
        final handled = await PrintService().printCurrent();

        // THEN
        expect(handled, isTrue);
        expect(printed, ['overlay']);
      },
    );

    test('the screen prints once the overlay is gone', () async {
      // GIVEN
      PrintService().register(screen);
      PrintService().register(overlay, isOverlay: true);
      PrintService().unregister(overlay);

      // WHEN
      await PrintService().printCurrent();

      // THEN
      expect(printed, ['screen']);
    });

    test('nothing prints without a handler', () async {
      // WHEN
      final handled = await PrintService().printCurrent();

      // THEN
      expect(handled, isFalse);
      expect(PrintService().hasHandler, isFalse);
    });
  });
}
