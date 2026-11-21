import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/data/models/planner/homework_model.dart';
import 'package:heliumapp/data/sources/planner_item_data_source.dart';
import 'package:heliumapp/presentation/features/planner/widgets/todos_data_grid.dart';
import 'package:mocktail/mocktail.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

import '../../../../mocks/mock_models.dart';

class _MockBuildContext extends Mock implements BuildContext {}

class _MockPlannerItemDataSource extends Mock implements PlannerItemDataSource {
  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      'MockPlannerItemDataSource';
}

void main() {
  late _MockPlannerItemDataSource plannerItems;

  setUp(() {
    plannerItems = _MockPlannerItemDataSource();
    when(() => plannerItems.courses).thenReturn([MockModels.createCourse()]);
    when(() => plannerItems.categoriesMap).thenReturn({});
    when(() => plannerItems.isHomeworkCompleted(any())).thenReturn(false);
    when(() => plannerItems.visibleResourcesFor(any())).thenReturn([]);
  });

  setUpAll(() {
    registerFallbackValue(MockModels.createHomework());
  });

  TodosDataSource givenTodos(List<HomeworkModel> homeworks) {
    return TodosDataSource(
      homeworks: homeworks,
      context: _MockBuildContext(),
      dataSource: plannerItems,
      onTap: (_) {},
      onToggleCompleted: (_, _) {},
    );
  }

  group('TodosDataSource.homeworksInSortOrder', () {
    final early = MockModels.createHomework(
      id: 1,
      title: 'Zebra essay',
      start: DateTime.utc(2026, 11, 2, 17),
    );
    final later = MockModels.createHomework(
      id: 2,
      title: 'Algebra quiz',
      start: DateTime.utc(2026, 11, 20, 17),
    );

    test('lists every todo in the default due-date order', () {
      // GIVEN
      final todos = givenTodos([later, early]);

      // WHEN
      final ordered = todos.homeworksInSortOrder;

      // THEN
      expect(ordered.map((h) => h.id), [1, 2]);
    });

    test('follows the sort the table is showing', () async {
      // GIVEN
      final todos = givenTodos([early, later]);
      todos.sortedColumns
        ..clear()
        ..add(
          const SortColumnDetails(
            name: 'title',
            sortDirection: DataGridSortDirection.ascending,
          ),
        );
      await todos.performSorting(todos.rows);

      // WHEN
      final ordered = todos.homeworksInSortOrder;

      // THEN
      expect(ordered.map((h) => h.title), ['Algebra quiz', 'Zebra essay']);
    });
  });
}
