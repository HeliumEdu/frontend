import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/core/motion_service.dart';
import 'package:heliumapp/presentation/ui/layout/reveal_on_mount.dart';

void main() {
  late ScrollController controller;

  setUp(() {
    controller = ScrollController();
  });

  tearDown(() {
    controller.dispose();
    MotionService().init(false);
  });

  Widget buildForm({required bool showError}) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          height: 300,
          child: SingleChildScrollView(
            controller: controller,
            child: Column(
              children: [
                const SizedBox(height: 1000),
                if (showError)
                  const RevealOnMount(
                    key: ValueKey('error'),
                    child: SizedBox(height: 50, child: Text('Error')),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('scrolls new content into view', (tester) async {
    // GIVEN
    await tester.pumpWidget(buildForm(showError: false));

    // WHEN
    await tester.pumpWidget(buildForm(showError: true));
    await tester.pumpAndSettle();

    // THEN
    expect(controller.offset, controller.position.maxScrollExtent,
        reason: 'the error at the bottom should be scrolled into view');
  });

  testWidgets('jumps without animating under reduce motion', (tester) async {
    // GIVEN
    MotionService().init(true);
    await tester.pumpWidget(buildForm(showError: false));

    // WHEN
    await tester.pumpWidget(buildForm(showError: true));
    await tester.pump();

    // THEN
    expect(controller.offset, controller.position.maxScrollExtent,
        reason: 'reduce motion should reach the error on the first frame after mount');
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('leaves the scroll alone when the content is already visible', (tester) async {
    // GIVEN
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          controller: controller,
          child: const Column(
            children: [
              SizedBox(height: 100),
              RevealOnMount(child: SizedBox(height: 50, child: Text('Error'))),
              SizedBox(height: 2000),
            ],
          ),
        ),
      ),
    ));

    // WHEN
    await tester.pumpAndSettle();

    // THEN
    expect(controller.offset, 0, reason: 'already-visible content should not scroll the form');
  });
}
