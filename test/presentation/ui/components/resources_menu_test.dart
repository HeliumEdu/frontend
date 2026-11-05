import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/presentation/ui/components/resource_title_label.dart';
import 'package:heliumapp/presentation/ui/components/resources_menu.dart';

import '../../../mocks/mock_models.dart';

void main() {
  testWidgets('lists each resource under the title, with a website button only when it has one',
      (tester) async {
    // GIVEN
    final resources = [
      MockModels.createResource(id: 1, title: 'Lab Manual', website: null),
      MockModels.createResource(id: 2, title: 'Textbook', website: 'https://example.com/book'),
    ];

    // WHEN
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: ResourcesMenuContent(
            resources: resources,
            userSettings: MockModels.createUserSettings(),
          ),
        ),
      ),
    );

    // THEN
    expect(find.text('Resources'), findsOneWidget);
    expect(find.text('Lab Manual'), findsOneWidget);
    expect(find.text('Textbook'), findsOneWidget);
    expect(find.byTooltip("Launch resource's website"), findsOneWidget);
    expect(find.byType(ResourceTitleLabel), findsNWidgets(2),
        reason: 'resources show as the resource label, as everywhere else');
  });

  testWidgets('a resource\'s label and website button are the same height', (tester) async {
    // GIVEN
    final resources = [
      MockModels.createResource(id: 2, title: 'Textbook', website: 'https://example.com/book'),
    ];

    // WHEN
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: ResourcesMenuContent(
            resources: resources,
            userSettings: MockModels.createUserSettings(),
          ),
        ),
      ),
    );

    // THEN
    final labelHeight = tester.getSize(find.byType(ResourceTitleLabel)).height;
    final buttonSize = tester.getSize(find.byType(IconButton));
    expect(buttonSize.width, buttonSize.height, reason: 'the button stays square');
    expect(labelHeight, moreOrLessEquals(buttonSize.height, epsilon: 2),
        reason: 'the label and its website button line up, as on resource cards');
  });
}
