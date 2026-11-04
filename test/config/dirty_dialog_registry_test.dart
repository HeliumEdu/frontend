import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/config/dirty_dialog_registry.dart';

void main() {
  tearDown(DirtyDialogRegistry.releaseActive);

  group('isWithin', () {
    test('a dialog owns its own path and its steps', () {
      // WHEN
      final ownPath = DirtyDialogRegistry.isWithin(
        '/classes/73947',
        '/classes/73947',
      );
      final ownStep = DirtyDialogRegistry.isWithin(
        '/classes/73947/schedule',
        '/classes/73947',
      );

      // THEN
      expect(ownPath, isTrue);
      expect(ownStep, isTrue);
    });

    test('a dialog does not own another dialog that shares its id prefix', () {
      // WHEN
      final within = DirtyDialogRegistry.isWithin(
        '/classes/73947/schedule',
        '/classes/7394',
      );

      // THEN
      expect(within, isFalse);
    });

    test('a new-course dialog does not own an existing course', () {
      // WHEN
      final within = DirtyDialogRegistry.isWithin(
        '/classes/73947/schedule',
        '/classes/new',
      );

      // THEN
      expect(within, isFalse);
    });
  });

  group('hasUnsavedChanges', () {
    test('follows the registered dialog\'s dirty check', () {
      // GIVEN
      var isDirty = false;
      DirtyDialogRegistry.register(
        prefix: '/classes/7394',
        fullPath: '/classes/7394/details',
        isDirty: () => isDirty,
      );

      // WHEN
      final whileClean = DirtyDialogRegistry.hasUnsavedChanges();
      isDirty = true;
      final whileDirty = DirtyDialogRegistry.hasUnsavedChanges();

      // THEN
      expect(whileClean, isFalse);
      expect(whileDirty, isTrue);
    });

    test('is false once the dialog is released', () {
      // GIVEN
      DirtyDialogRegistry.register(
        prefix: '/classes/7394',
        fullPath: '/classes/7394/details',
        isDirty: () => true,
      );

      // WHEN
      DirtyDialogRegistry.releaseActive();

      // THEN
      expect(DirtyDialogRegistry.hasUnsavedChanges(), isFalse);
    });
  });

  test(
    'guard stops leaving a dirty dialog for another whose id shares its prefix',
    () {
      // GIVEN
      DirtyDialogRegistry.register(
        prefix: '/classes/7394',
        fullPath: '/classes/7394/details',
        isDirty: () => true,
        deferNavigation: () => true,
      );

      // WHEN
      final revertTo = DirtyDialogRegistry.guard('/classes/73947/details');

      // THEN
      expect(revertTo, '/classes/7394/details');
    },
  );
}
