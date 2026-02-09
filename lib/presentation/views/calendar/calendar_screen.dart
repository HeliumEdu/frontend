// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:heliumapp/config/app_routes.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/config/route_args.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/data/models/auth/user_model.dart';
import 'package:heliumapp/data/models/planner/calendar_item_base_model.dart';
import 'package:heliumapp/data/models/planner/category_model.dart';
import 'package:heliumapp/data/models/planner/course_group_model.dart';
import 'package:heliumapp/data/models/planner/course_model.dart';
import 'package:heliumapp/data/models/planner/course_schedule_event_model.dart';
import 'package:heliumapp/data/models/planner/event_model.dart';
import 'package:heliumapp/data/models/planner/request/event_request_model.dart';
import 'package:heliumapp/data/models/planner/external_calendar_event_model.dart';
import 'package:heliumapp/data/models/planner/homework_model.dart';
import 'package:heliumapp/data/models/planner/request/homework_request_model.dart';
import 'package:heliumapp/data/repositories/category_repository_impl.dart';
import 'package:heliumapp/data/repositories/course_repository_impl.dart';
import 'package:heliumapp/data/repositories/course_schedule_event_repository_impl.dart';
import 'package:heliumapp/data/repositories/event_repository_impl.dart';
import 'package:heliumapp/data/repositories/external_calendar_repository_impl.dart';
import 'package:heliumapp/data/repositories/homework_repository_impl.dart';
import 'package:heliumapp/data/sources/calendar_item_data_source.dart';
import 'package:heliumapp/data/sources/category_remote_data_source.dart';
import 'package:heliumapp/data/sources/course_remote_data_source.dart';
import 'package:heliumapp/data/sources/course_schedule_remote_data_source.dart';
import 'package:heliumapp/data/sources/event_remote_data_source.dart';
import 'package:heliumapp/data/sources/external_calendar_remote_data_source.dart';
import 'package:heliumapp/data/sources/homework_remote_data_source.dart';
import 'package:heliumapp/presentation/bloc/calendar/calendar_bloc.dart';
import 'package:heliumapp/presentation/bloc/calendar/calendar_event.dart';
import 'package:heliumapp/presentation/bloc/calendar/calendar_state.dart';
import 'package:heliumapp/presentation/bloc/calendaritem/calendaritem_bloc.dart';
import 'package:heliumapp/presentation/bloc/calendaritem/calendaritem_event.dart';
import 'package:heliumapp/presentation/bloc/calendaritem/calendaritem_state.dart';
import 'package:heliumapp/presentation/bloc/category/category_bloc.dart';
import 'package:heliumapp/presentation/bloc/core/base_event.dart';
import 'package:heliumapp/presentation/bloc/core/provider_helpers.dart';
import 'package:heliumapp/presentation/dialogs/confirm_delete_dialog.dart';
import 'package:heliumapp/presentation/views/calendar/todos_table_controller.dart';
import 'package:heliumapp/presentation/views/core/base_page_screen_state.dart';
import 'package:heliumapp/presentation/widgets/error_card.dart';
import 'package:heliumapp/presentation/widgets/helium_icon_button.dart';
import 'package:heliumapp/presentation/widgets/loading_indicator.dart';
import 'package:heliumapp/presentation/widgets/shadow_container.dart';
import 'package:heliumapp/presentation/widgets/todos_table.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/date_time_helpers.dart';
import 'package:heliumapp/utils/planner_helper.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:logging/logging.dart';
import 'package:nested/nested.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:timezone/standalone.dart' as tz;
import 'package:url_launcher/url_launcher.dart';

final _log = Logger('presentation.views');

class CalendarScreen extends StatelessWidget {
  final DioClient _dioClient = DioClient();
  final ProviderHelpers _providerHelpers = ProviderHelpers();

  CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: _providerHelpers.createCalendarItemBloc()),
        BlocProvider(
          create: (context) => CalendarBloc(
            courseRepository: CourseRepositoryImpl(
              remoteDataSource: CourseRemoteDataSourceImpl(
                dioClient: _dioClient,
              ),
            ),
            categoryRepository: CategoryRepositoryImpl(
              remoteDataSource: CategoryRemoteDataSourceImpl(
                dioClient: _dioClient,
              ),
            ),
          ),
        ),
        BlocProvider(
          create: (context) => CategoryBloc(
            categoryRepository: CategoryRepositoryImpl(
              remoteDataSource: CategoryRemoteDataSourceImpl(
                dioClient: _dioClient,
              ),
            ),
          ),
        ),
      ],
      child: const CalendarProvidedScreen(),
    );
  }
}

class CalendarProvidedScreen extends StatefulWidget {
  const CalendarProvidedScreen({super.key});

  @override
  State<CalendarProvidedScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends BasePageScreenState<CalendarProvidedScreen> {
  static const _agendaHeightMobile = 53.0;
  static const _agendaHeightDesktop = 57.0;

  @override
  // TODO: Cleanup: have the shell pass down its label here instead
  String get screenTitle => 'Planner';

  @override
  List<SingleChildWidget>? get inheritableProviders => [
    BlocProvider<CalendarItemBloc>.value(
      value: context.read<CalendarItemBloc>(),
    ),
  ];

  @override
  VoidCallback get actionButtonCallback => () {
    // For Todos and Schedule views, use today as initial date since we don't
    // have a confident selection. For calendar views, use the selected date.
    final now = DateTime.now();
    final truncatedNow = DateTime(now.year, now.month, now.day, now.hour);
    final initialDate =
        (_currentView == HeliumView.todos || _currentView == HeliumView.agenda)
        ? truncatedNow
        : _calendarController.selectedDate;

    context.push(
      AppRoutes.plannerItemAddScreen,
      extra: CalendarItemAddArgs(
        calendarItemBloc: context.read<CalendarItemBloc>(),
        initialDate: initialDate,
        isFromMonthView: _calendarController.view == CalendarView.month,
        isEdit: false,
      ),
    );
  };

  @override
  bool get showActionButton => true;

  late final CalendarController _calendarController;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _searchTypingTimer;
  final ScrollController _monthViewScrollController = ScrollController();

  final GlobalKey _todayButtonKey = GlobalKey();
  late final TodosTableController _todosController;

  final List<CalendarView> _allowedViews = [
    CalendarView.month,
    CalendarView.week,
    CalendarView.day,
    CalendarView.schedule,
  ];

  // State
  List<CourseGroupModel> _courseGroups = [];
  List<CourseModel> _courses = [];
  final Map<int, CategoryModel> _categoriesMap = {};
  final List<CategoryModel> _deduplicatedCategories = [];
  bool _isSearchExpanded = false;
  bool _isFilterExpanded = false;
  HeliumView _currentView = PlannerHelper.mapApiViewToHeliumView(
    FallbackConstants.defaultViewIndex,
  );
  HeliumView? _previousView;

  // Remember state when user switches to Todos view
  DateTime? _storedSelectedDate;
  DateTime? _storedDisplayDate;

  // Remember selectedDate on mobile (allows restoring null selection when
  // leaving month view on mobile)
  DateTime? _selectedDateBeforeMobileMonth;
  bool _mobileMonthAutoSelectApplied = false;

  CalendarItemDataSource? _calendarItemDataSource;

  @override
  void initState() {
    super.initState();

    _calendarController = CalendarController()
      ..view = PlannerHelper.mapHeliumViewToSfCalendarView(_currentView);
    _todosController = TodosTableController();

    context.read<CalendarBloc>().add(FetchCalendarScreenDataEvent());

    _calendarController.addPropertyChangedListener((value) {
      if (value == 'calendarView') {
        _calendarViewChanged();
      } else if (value == 'displayDate' && _currentView == HeliumView.agenda) {
        _log.fine('Display date change: $value');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {});
          }
        });
      }
    });

    _goToToday();

    _searchFocusNode.addListener(() {
      if (!_searchFocusNode.hasFocus && _isSearchExpanded) {
        setState(() {
          _isSearchExpanded = false;
          _searchFocusNode.unfocus();
        });
      }
    });
  }

  @override
  void dispose() {
    _calendarItemDataSource?.dispose();
    _todosController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _searchTypingTimer?.cancel();
    _monthViewScrollController.dispose();
    super.dispose();
  }

  @override
  Future<UserSettingsModel?> loadSettings() {
    return super.loadSettings().then((settings) {
      if (mounted && settings != null) {
        setState(() {
          final defaultView = PlannerHelper.mapApiViewToHeliumView(
            settings.defaultView,
          );
          _changeView(defaultView);

          _calendarItemDataSource = CalendarItemDataSource(
            homeworkRepository: HomeworkRepositoryImpl(
              remoteDataSource: HomeworkRemoteDataSourceImpl(
                dioClient: dioClient,
              ),
            ),
            eventRepository: EventRepositoryImpl(
              remoteDataSource: EventRemoteDataSourceImpl(dioClient: dioClient),
            ),
            courseScheduleRepository: CourseScheduleRepositoryImpl(
              remoteDataSource: CourseScheduleRemoteDataSourceImpl(
                dioClient: dioClient,
              ),
            ),
            externalCalendarRepository: ExternalCalendarRepositoryImpl(
              remoteDataSource: ExternalCalendarRemoteDataSourceImpl(
                dioClient: dioClient,
              ),
            ),
            userSettings: settings,
          );
          _calendarItemDataSource!.restoreFiltersIfEnabled();
          _todosController.itemsPerPage =
              _calendarItemDataSource!.todosItemsPerPage;
        });
      }

      return settings;
    });
  }

  @override
  List<BlocListener<dynamic, dynamic>> buildListeners(BuildContext context) {
    return [
      BlocListener<CalendarBloc, CalendarState>(
        listener: (context, state) {
          if (state is CalendarScreenDataFetched) {
            _populateInitialCalendarStateData(state);
          }
        },
      ),
      BlocListener<CalendarItemBloc, CalendarItemState>(
        listener: (context, state) {
          if (_calendarItemDataSource == null) return;

          if (state is EventCreated) {
            _calendarItemDataSource!.addCalendarItem(state.event);
          } else if (state is EventUpdated) {
            if (state.origin == EventOrigin.screen) {
              showSnackBar(context, 'Event saved');
            }
            _calendarItemDataSource!.updateCalendarItem(state.event);
          } else if (state is EventDeleted) {
            showSnackBar(context, 'Event deleted');
            _calendarItemDataSource!.removeCalendarItem(state.id);
          } else if (state is HomeworkCreated) {
            _calendarItemDataSource!.addCalendarItem(state.homework);
          } else if (state is HomeworkUpdated) {
            if (state.origin == EventOrigin.screen) {
              showSnackBar(context, 'Assignment saved');
            }
            _calendarItemDataSource!.updateCalendarItem(state.homework);
          } else if (state is HomeworkDeleted) {
            showSnackBar(context, 'Assignment deleted');
            _calendarItemDataSource!.removeCalendarItem(state.id);
          }
        },
      ),
    ];
  }

  @override
  Widget buildMainArea(BuildContext context) {
    return BlocBuilder<CalendarBloc, CalendarState>(
      builder: (context, state) {
        if (state is CalendarLoading) {
          return const LoadingIndicator();
        }

        if (state is CalendarError) {
          return ErrorCard(
            message: state.message!,
            onReload: () {
              FetchCalendarScreenDataEvent();
            },
          );
        }

        return _buildCalendarPage();
      },
    );
  }

  Widget _buildCalendarPage() {
    return Expanded(
      child: Column(
        children: [
          _buildCalendarHeader(),

          Expanded(
            child: _currentView == HeliumView.todos
                ? _buildTodosView()
                : _buildCalendarView(context),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarView(BuildContext context) {
    return ListenableBuilder(
      listenable: _calendarItemDataSource!.changeNotifier,
      builder: (context, _) {
        // For month view, wrap to make it scrollable if the view height is too small
        if (_calendarController.view == CalendarView.month) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final double calendarHeight = _calculateCalendarHeight(
                constraints.maxHeight,
              );

              return SingleChildScrollView(
                controller: _monthViewScrollController,
                child: SizedBox(
                  height: calendarHeight,
                  child: _buildCalendar(),
                ),
              );
            },
          );
        } else {
          return _buildCalendar();
        }
      },
    );
  }

  int _calculateCalendarItemDisplayCount(double availableHeight) {
    const double dayHeaderHeight = 45;
    const double dayNumberHeight = 30;
    const double calendarItemHeight = 21;
    const int monthRows = 6;
    const int minCount = 3;

    final cellHeight = (availableHeight - dayHeaderHeight) / monthRows;
    final availableForCalendarItems = cellHeight - dayNumberHeight;
    final count = (availableForCalendarItems / calendarItemHeight).floor();

    return count.clamp(minCount, 10);
  }

  double _calculateCalendarHeight(double maxHeight) {
    const double minCalendarHeight = 600;
    return maxHeight < minCalendarHeight ? minCalendarHeight : maxHeight;
  }

  Widget _buildCalendar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final calendarItemsDisplayCount = _calculateCalendarItemDisplayCount(
          constraints.maxHeight,
        );

        final agendaHeight = Responsive.isMobile(context)
            ? _agendaHeightMobile
            : _agendaHeightDesktop;

        return SfCalendar(
          backgroundColor: context.colorScheme.surface,
          controller: _calendarController,
          headerHeight: 0,
          showCurrentTimeIndicator: true,
          showWeekNumber: !Responsive.isMobile(context),
          allowDragAndDrop: true,
          dragAndDropSettings: DragAndDropSettings(
            timeIndicatorStyle: AppStyles.smallSecondaryText(
              context,
            ).copyWith(color: context.colorScheme.primary),
          ),
          allowAppointmentResize: true,
          allowedViews: _allowedViews,
          dataSource: _calendarItemDataSource,
          timeZone: userSettings!.timeZone.name,
          firstDayOfWeek:
              PlannerHelper.weekStartsOnRemap[userSettings!.weekStartsOn],
          todayTextStyle: AppStyles.standardBodyText(
            context,
          ).copyWith(color: context.colorScheme.onPrimary),
          viewHeaderStyle: ViewHeaderStyle(
            dayTextStyle: AppStyles.standardBodyText(context),
            dateTextStyle: AppStyles.standardBodyText(context),
          ),
          weekNumberStyle: WeekNumberStyle(
            textStyle: AppStyles.smallSecondaryTextLight(context),
          ),
          scheduleViewSettings: ScheduleViewSettings(
            hideEmptyScheduleWeek: true,
            appointmentItemHeight: agendaHeight,
            placeholderTextStyle: AppStyles.smallSecondaryText(context),
            monthHeaderSettings: MonthHeaderSettings(
              monthTextStyle: AppStyles.headingText(context),
              backgroundColor: context.colorScheme.primary,
              height: 90,
            ),
            weekHeaderSettings: WeekHeaderSettings(
              weekTextStyle: AppStyles.standardBodyText(context).copyWith(
                color: context.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            dayHeaderSettings: DayHeaderSettings(
              dateTextStyle: AppStyles.smallSecondaryText(
                context,
              ).copyWith(color: context.colorScheme.onSurface),
              dayTextStyle: AppStyles.smallSecondaryText(
                context,
              ).copyWith(color: context.colorScheme.onSurface),
            ),
          ),
          monthViewSettings: MonthViewSettings(
            appointmentDisplayCount: calendarItemsDisplayCount,
            showAgenda: Responsive.isMobile(context),
            agendaItemHeight: agendaHeight,
            monthCellStyle: MonthCellStyle(
              textStyle: AppStyles.smallSecondaryText(context),
              leadingDatesTextStyle: AppStyles.smallSecondaryText(context)
                  .copyWith(
                    color: context.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
              trailingDatesTextStyle: AppStyles.smallSecondaryText(context)
                  .copyWith(
                    color: context.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
            ),
            agendaStyle: AgendaStyle(
              dateTextStyle: AppStyles.smallSecondaryText(
                context,
              ).copyWith(color: context.colorScheme.onSurface),
              dayTextStyle: AppStyles.smallSecondaryText(
                context,
              ).copyWith(color: context.colorScheme.onSurface),
              placeholderTextStyle: AppStyles.smallSecondaryText(context),
            ),
            appointmentDisplayMode: Responsive.isMobile(context)
                ? MonthAppointmentDisplayMode.indicator
                : MonthAppointmentDisplayMode.appointment,
            dayFormat: 'EEE',
          ),
          timeSlotViewSettings: TimeSlotViewSettings(
            minimumAppointmentDuration: const Duration(minutes: 32),
            timeTextStyle: AppStyles.smallSecondaryText(context).copyWith(
              color: context.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            dayFormat: 'EEE',
            timeIntervalHeight: 50,
            // TODO: Enhancement: use this field and dynamically set it to null (full week), 3, or 1, to enable a new "3-day" view
            // numberOfDaysInView: 3
          ),
          loadMoreWidgetBuilder: _loadMoreWidgetBuilder,
          appointmentBuilder: _buildCalendarItem,
          onTap: _openCalendarItemFromSfCalendar,
          onDragEnd: _dropCalendarItemFromSfCalendar,
          onAppointmentResizeEnd: _resizeCalendarItemFromSfCalendar,
          onSelectionChanged: _onCalendarSelectionChanged,
          onViewChanged: (ViewChangedDetails details) {
            if (mounted) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  // Ensure the date header is updated
                  setState(() {});
                }
              });
            }
          },
        );
      },
    );
  }

  bool _openCalendarItem(CalendarItemBaseModel calendarItem) {
    if (calendarItem is CourseScheduleEventModel) {
      // TODO: High Value, Low Effort: add an action button this snack bar to take the user to the page to edit the course schedule
      showSnackBar(
        context,
        "You can't open this on the Planner",
        isError: true,
      );

      return false;
    } else if (calendarItem is ExternalCalendarEventModel) {
      showSnackBar(
        context,
        "You can't open this on the Planner",
        isError: true,
      );

      return false;
    }

    final int? eventId = calendarItem is EventModel ? calendarItem.id : null;
    final int? homeworkId = calendarItem is HomeworkModel
        ? calendarItem.id
        : null;

    context.push(
      AppRoutes.plannerItemAddScreen,
      extra: CalendarItemAddArgs(
        calendarItemBloc: context.read<CalendarItemBloc>(),
        eventId: eventId,
        homeworkId: homeworkId,
        isEdit: true,
      ),
    );

    return true;
  }

  Widget _buildCalendarHeader() {
    final isMobile = Responsive.isMobile(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ShadowContainer(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SizedBox(
              height: 48,
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildTodayButton(
                          showLabel: !isMobile,
                          key: _todayButtonKey,
                        ),
                        _buildCalendarDateArea(),
                      ],
                    ),
                  ),
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: _buildFilterArea(
                        containerWidth: constraints.maxWidth,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTodayButton({required bool showLabel, Key? key}) {
    final icon = Icon(
      Icons.calendar_today,
      size: Responsive.getIconSize(
        context,
        mobile: 20,
        tablet: 22,
        desktop: 24,
      ),
    );

    final button = _buildTodayButtonWidget(icon, showLabel, key);

    return Padding(padding: const EdgeInsets.only(top: 3), child: button);
  }

  Widget _buildTodayButtonWidget(Icon icon, bool showLabel, Key? key) {
    if (showLabel) {
      return OutlinedButton.icon(
        key: key,
        onPressed: _goToToday,
        icon: icon,
        style: ButtonStyle(
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          ),
          // Pin the min/max size to ensure matches filter buttons on other side of header
          minimumSize: WidgetStateProperty.all(const Size(0, 48)),
          maximumSize: WidgetStateProperty.all(const Size(double.infinity, 48)),
          side: WidgetStateProperty.all(
            BorderSide(color: context.colorScheme.primary),
          ),
        ),
        label: Text(
          'Today',
          style: AppStyles.buttonText(
            context,
          ).copyWith(color: context.colorScheme.primary),
        ),
      );
    } else {
      return IconButton.outlined(
        key: key,
        onPressed: _goToToday,
        icon: icon,
        style: ButtonStyle(
          side: WidgetStateProperty.all(
            BorderSide(color: context.colorScheme.primary),
          ),
        ),
      );
    }
  }

  Widget _buildCalendarDateArea() {
    if (_currentView == HeliumView.todos) {
      return Expanded(
        child: Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              CalendarConstants
                  .defaultViews[PlannerHelper.mapHeliumViewToApiView(
                _currentView,
              )],
              style: AppStyles.headingText(
                context,
              ).copyWith(color: context.colorScheme.onSurface),
            ),
          ),
        ),
      );
    }

    final String headerText = _buildHeaderDate();

    final showNavButtons = _currentView != HeliumView.agenda;

    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(width: 4),
          if (showNavButtons) ...[
            IconButton(
              icon: Icon(
                Icons.chevron_left,
                color: context.colorScheme.primary,
              ),
              onPressed: _calendarController.backward,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 4),
          ],
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                _openDatePicker();
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.only(left: 8, top: 8, bottom: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      headerText,
                      style: AppStyles.headingText(
                        context,
                      ).copyWith(color: context.colorScheme.onSurface),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.arrow_drop_down,
                      color: context.colorScheme.primary,
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (showNavButtons && !Responsive.isMobile(context))
            const SizedBox(width: 4),
          if (showNavButtons)
            IconButton(
              icon: Icon(
                Icons.chevron_right,
                color: context.colorScheme.primary,
              ),
              onPressed: _calendarController.forward,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterArea({double? containerWidth}) {
    final isMobile = Responsive.isMobile(context);

    final isExpanded = _isFilterExpanded || _isSearchExpanded;
    final double expandedToolbarWidth;
    if (containerWidth == null || !isExpanded) {
      expandedToolbarWidth = 300;
    } else {
      final todayButtonContext = _todayButtonKey.currentContext;
      final calculatedWidth = todayButtonContext != null
          ? containerWidth -
                (todayButtonContext.findRenderObject() as RenderBox)
                    .size
                    .width -
                8
          : containerWidth - 8;
      expandedToolbarWidth = isMobile
          ? calculatedWidth
          : calculatedWidth.clamp(200, 300);
    }

    if (!isMobile) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: expandedToolbarWidth,
        child: Stack(
          alignment: Alignment.centerRight,
          children: [
            AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _isSearchExpanded ? 0.0 : 1.0,
              child: IgnorePointer(
                ignoring: _isSearchExpanded,
                child: _buildFilterAndSearchButtons(),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              right: 0,
              width: _isSearchExpanded ? expandedToolbarWidth : 46,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _isSearchExpanded ? 1.0 : 0.0,
                child: IgnorePointer(
                  ignoring: !_isSearchExpanded,
                  child: _buildSearchField(),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: isExpanded ? expandedToolbarWidth : 46,
        child: Stack(
          alignment: Alignment.centerRight,
          children: [
            AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: (_isFilterExpanded || _isSearchExpanded) ? 0.0 : 1.0,
              child: IgnorePointer(
                ignoring: _isFilterExpanded || _isSearchExpanded,
                child: _buildCollapsedFilterButton(),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              right: 0,
              width: _isFilterExpanded ? expandedToolbarWidth : 46,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _isFilterExpanded ? 1.0 : 0.0,
                child: IgnorePointer(
                  ignoring: !_isFilterExpanded,
                  child: _buildExpandedFilterButtons(),
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              right: 0,
              width: _isSearchExpanded ? expandedToolbarWidth : 46,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _isSearchExpanded ? 1.0 : 0.0,
                child: IgnorePointer(
                  ignoring: !_isSearchExpanded,
                  child: _buildSearchField(),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildCollapsedFilterButton() {
    return IconButton.outlined(
      onPressed: () {
        setState(() {
          _isFilterExpanded = true;
        });
      },
      icon: const Icon(Icons.menu_open),
      style: ButtonStyle(
        side: WidgetStateProperty.all(
          BorderSide(color: context.colorScheme.primary),
        ),
      ),
    );
  }

  Widget _buildExpandedFilterButtons() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Only show content when width is large enough (during/after animation)
        final showContent = constraints.maxWidth > 200;

        return ClipRect(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: context.colorScheme.surface,
            ),
            child: showContent
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: _buildFilterAndSearchButtons(),
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _isFilterExpanded = false;
                            _searchFocusNode.unfocus();
                          });
                        },
                        icon: Icon(
                          Icons.close,
                          color: context.colorScheme.primary,
                          size: Responsive.getIconSize(
                            context,
                            mobile: 20,
                            tablet: 22,
                            desktop: 24,
                          ),
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        );
      },
    );
  }

  Widget _buildSearchField() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Only show content when width is large enough (during/after animation)
        final showContent = constraints.maxWidth > 200;

        return ClipRect(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: context.colorScheme.surface,
            ),
            child: showContent
                ? Row(
                    children: [
                      Icon(
                        Icons.search,
                        color: context.colorScheme.primary,
                        size: Responsive.getIconSize(
                          context,
                          mobile: 20,
                          tablet: 22,
                          desktop: 24,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minWidth: 0),
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            onChanged: _onSearchTextFieldChanged,
                            style: AppStyles.headingText(context),
                            decoration: InputDecoration(
                              hintText: 'Search ...',
                              hintStyle: AppStyles.formLabel(context),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              focusedErrorBorder: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _isSearchExpanded = false;
                            _searchFocusNode.unfocus();
                          });
                        },
                        icon: Icon(
                          Icons.close,
                          color: context.colorScheme.primary,
                          size: Responsive.getIconSize(
                            context,
                            mobile: 20,
                            tablet: 22,
                            desktop: 24,
                          ),
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        );
      },
    );
  }

  Widget _buildFilterAndSearchButtons() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 200) {
          return const SizedBox.shrink();
        }

        // Wrap in ListenableBuilder to rebuild when filters change
        if (_calendarItemDataSource == null) {
          return _buildFilterButtonsRow();
        }

        return ListenableBuilder(
          listenable: _calendarItemDataSource!.changeNotifier,
          builder: (context, _) => _buildFilterButtonsRow(),
        );
      },
    );
  }

  Widget _buildFilterButtonsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Builder(
          builder: (context) {
            return IconButton.outlined(
              onPressed: () => _openViewMenu(context),
              tooltip: 'Change view',
              icon: const Icon(Icons.calendar_month),
              style: ButtonStyle(
                side: WidgetStateProperty.all(
                  BorderSide(color: context.colorScheme.primary),
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 8),
        Builder(
          builder: (context) {
            final hasCoursesFilter = _hasCoursesFilter();
            return IconButton.outlined(
              onPressed: _courses.isEmpty
                  ? null
                  : () => _openCoursesMenu(context, _courses),
              tooltip: 'Filter by class',
              icon: const Icon(Icons.school),
              style: IconButton.styleFrom(
                backgroundColor: hasCoursesFilter
                    ? context.colorScheme.primary
                    : null,
                foregroundColor: hasCoursesFilter
                    ? context.colorScheme.onPrimary
                    : null,
                side: BorderSide(color: context.colorScheme.primary),
              ),
            );
          },
        ),
        const SizedBox(width: 8),
        Builder(
          builder: (context) {
            final hasStatusFilters = _hasStatusFilters();
            return IconButton.outlined(
              onPressed: _courses.isEmpty
                  ? null
                  : () => _openFilterMenu(context),
              tooltip: 'Filter by category and status',
              icon: const Icon(Icons.filter_alt),
              style: IconButton.styleFrom(
                backgroundColor: hasStatusFilters
                    ? context.colorScheme.primary
                    : null,
                foregroundColor: hasStatusFilters
                    ? context.colorScheme.onPrimary
                    : null,
                side: BorderSide(color: context.colorScheme.primary),
              ),
            );
          },
        ),
        const SizedBox(width: 8),
        Builder(
          builder: (context) {
            final hasSearchQuery = _hasSearchQuery();
            return IconButton.outlined(
              onPressed: () {
                setState(() {
                  _isFilterExpanded = false;
                  _isSearchExpanded = true;
                  _searchFocusNode.requestFocus();
                });
              },
              icon: const Icon(Icons.search),
              style: IconButton.styleFrom(
                backgroundColor: hasSearchQuery
                    ? context.colorScheme.primary
                    : null,
                foregroundColor: hasSearchQuery
                    ? context.colorScheme.onPrimary
                    : null,
                side: _isSearchExpanded
                    ? BorderSide.none
                    : BorderSide(color: context.colorScheme.primary),
              ),
            );
          },
        ),
      ],
    );
  }

  String _buildHeaderDate() {
    final displayDate = _calendarController.displayDate!;
    final abbreviateMonth = Responsive.isMobile(context);

    switch (_calendarController.view) {
      case CalendarView.day:
        return HeliumDateTime.formatDate(
          displayDate,
          abbreviateMonth: abbreviateMonth,
        );
      case CalendarView.month:
      case CalendarView.week:
      case CalendarView.schedule:
      default:
        return HeliumDateTime.formatMonthAndYear(
          displayDate,
          abbreviateMonth: abbreviateMonth,
        );
    }
  }

  bool _hasCoursesFilter() {
    if (_calendarItemDataSource == null) return false;

    final filteredCourses = _calendarItemDataSource!.filteredCourses;

    if (filteredCourses.isEmpty) return false;

    return filteredCourses.values.any((isSelected) => isSelected);
  }

  List<CategoryModel> _deduplicateCategoriesByTitle(
    Iterable<CategoryModel> categories,
  ) {
    final uniqueCategories = <String, CategoryModel>{};
    for (final category in categories) {
      if (!uniqueCategories.containsKey(category.title)) {
        uniqueCategories[category.title] = category;
      }
    }
    return uniqueCategories.values.toList();
  }

  List<CategoryModel> _getVisibleCategories() {
    if (!_hasCoursesFilter()) {
      return _deduplicatedCategories;
    }

    final filteredCourseIds = _calendarItemDataSource!.filteredCourses.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toSet();

    final filteredCategories = _categoriesMap.values.where(
      (cat) => filteredCourseIds.contains(cat.course),
    );

    return _deduplicateCategoriesByTitle(filteredCategories);
  }

  bool _hasStatusFilters() {
    if (_calendarItemDataSource == null) return false;

    final categories = _calendarItemDataSource!.filterCategories;
    final types = _calendarItemDataSource!.filterTypes;
    final statuses = _calendarItemDataSource!.filterStatuses;

    if (types.isNotEmpty) return true;

    if (categories.isNotEmpty) return true;

    if (statuses.isNotEmpty) return true;

    return false;
  }

  bool _hasSearchQuery() {
    if (_calendarItemDataSource == null) return false;

    final searchQuery = _calendarItemDataSource!.searchQuery;
    return searchQuery.isNotEmpty;
  }

  Future<void> _openDatePicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _calendarController.displayDate!,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 10)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );

    if (picked != null) {
      _jumpToDate(picked, setSelectedDate: true);
    }
  }

  void _changeView(HeliumView newView) {
    _log.info('View changed: $_currentView -> $newView');
    final isEnteringNonCalendarView = (newView == HeliumView.todos);
    final wasInNonCalendarView =
        _previousView != null && _previousView == HeliumView.todos;
    final isEnteringCalendarView =
        (newView == HeliumView.month ||
        newView == HeliumView.week ||
        newView == HeliumView.day);
    final isLeavingMonthView = _currentView == HeliumView.month;

    // Unset selectedDate when leaving month view on mobile (if it wasn't set
    // before month view was entered)
    if (isLeavingMonthView && _mobileMonthAutoSelectApplied) {
      _calendarController.selectedDate = _selectedDateBeforeMobileMonth;
      _mobileMonthAutoSelectApplied = false;
      _selectedDateBeforeMobileMonth = null;
    }

    // Store calendar view state when entering Todos
    if (isEnteringNonCalendarView && !wasInNonCalendarView) {
      _storedSelectedDate = _calendarController.selectedDate;
      _storedDisplayDate = _calendarController.displayDate;
    }

    // Restore calendar view state when leaving Todos
    if (isEnteringCalendarView && wasInNonCalendarView) {
      if (_storedSelectedDate != null) {
        _calendarController.selectedDate = _storedSelectedDate;
      }
      if (_storedDisplayDate != null) {
        _calendarController.displayDate = _storedDisplayDate;
      }
    }

    // When switching between calendar views (Month/Week/Day), sync displayDate
    // to selectedDate so the view navigates to the selected date
    if (isEnteringCalendarView &&
        !wasInNonCalendarView &&
        _calendarController.selectedDate != null) {
      _calendarController.displayDate = _calendarController.selectedDate;
    }

    _previousView = _currentView;
    _currentView = newView;

    // Only update the calendar controller's view if not switching to Todos
    // (Todos is a custom view that doesn't exist in SfCalendar)
    if (newView != HeliumView.todos) {
      _calendarController.view = PlannerHelper.mapHeliumViewToSfCalendarView(
        newView,
      );
    }

    // On mobile, select a date on month view so the agenda is always shown
    if (Responsive.isMobile(context) &&
        newView == HeliumView.month &&
        _calendarController.selectedDate == null) {
      _selectedDateBeforeMobileMonth = _calendarController.selectedDate;
      _mobileMonthAutoSelectApplied = true;
      final now = DateTime.now();
      _calendarController.selectedDate = DateTime(
        now.year,
        now.month,
        now.day,
        now.hour,
      );
    }
  }

  void _calendarViewChanged() {
    final newView = PlannerHelper.mapSfCalendarViewToHeliumView(
      _calendarController.view!,
    );
    if (newView != _currentView) {
      setState(() {
        _changeView(newView);
      });
    }
  }

  void _onCalendarSelectionChanged(CalendarSelectionDetails details) {
    if (details.date == null) return;

    _log.info('Selection changed: ${details.date}');

    // User made a manual selection, clear any mobile-specific paths as that
    // logic now follows all standard paths (since a selection can't be undone
    // unless page is reloaded)
    if (_mobileMonthAutoSelectApplied) {
      _mobileMonthAutoSelectApplied = false;
      _selectedDateBeforeMobileMonth = null;
    }

    // In month view, include the current hour in the date selection so
    // created items don't populate with midnight
    if (_currentView == HeliumView.month) {
      final now = DateTime.now();
      final selectedWithTime = DateTime(
        details.date!.year,
        details.date!.month,
        details.date!.day,
        now.hour,
      );
      _calendarController.selectedDate = selectedWithTime;
    }
  }

  FutureBuilder<void> _loadMoreWidgetBuilder(
    BuildContext context,
    LoadMoreCallback loadMoreCalendarItems,
  ) {
    return FutureBuilder<void>(
      future: loadMoreCalendarItems(),
      builder: (context, snapShot) {
        return Container(
          height: double.infinity,
          width: double.infinity,
          alignment: Alignment.center,
          child: const CircularProgressIndicator(),
        );
      },
    );
  }

  void _onSearchTextFieldChanged(String value) {
    if (_searchTypingTimer?.isActive ?? false) {
      _searchTypingTimer!.cancel();
    }

    _searchTypingTimer = Timer(const Duration(milliseconds: 500), () {
      _calendarItemDataSource!.setSearchQuery(value);
    });
  }

  void _openCalendarItemFromSfCalendar(CalendarTapDetails tapDetails) {
    if (tapDetails.appointments == null ||
        tapDetails.appointments!.isEmpty ||
        tapDetails.targetElement != CalendarElement.appointment) {
      return;
    }

    final CalendarItemBaseModel calendarItem =
        tapDetails.appointments![0] as CalendarItemBaseModel;

    if (_currentView == HeliumView.agenda &&
        PlannerHelper.shouldShowEditButton(context)) {
      return;
    }

    Feedback.forTap(context);

    _openCalendarItem(calendarItem);
  }

  void _dropCalendarItemFromSfCalendar(AppointmentDragEndDetails dropDetails) {
    if (dropDetails.appointment == null || dropDetails.droppingTime == null) {
      return;
    }

    final CalendarItemBaseModel calendarItem =
        dropDetails.appointment as CalendarItemBaseModel;

    if (calendarItem is HomeworkModel || calendarItem is EventModel) {
      final startDateTime = tz.TZDateTime.from(
        calendarItem.start,
        userSettings!.timeZone,
      );
      final Duration duration = tz.TZDateTime.from(
        calendarItem.end,
        userSettings!.timeZone,
      ).difference(startDateTime);

      final roundedMinute =
          ((dropDetails.droppingTime!.minute + 15) ~/ 30) * 30;

      final DateTime start = tz.TZDateTime(
        userSettings!.timeZone,
        dropDetails.droppingTime!.year,
        dropDetails.droppingTime!.month,
        dropDetails.droppingTime!.day,
        _currentView == HeliumView.month
            ? startDateTime.hour
            : dropDetails.droppingTime!.hour,
        _currentView == HeliumView.month ? startDateTime.minute : roundedMinute,
      );
      final DateTime end = start.add(duration);

      // Set optimistic override immediately for instant visual feedback
      _calendarItemDataSource!.setTimeOverride(
        calendarItem.id,
        start.toIso8601String(),
        end.toIso8601String(),
      );

      if (calendarItem is HomeworkModel) {
        final request = HomeworkRequestModel(
          start: start.toIso8601String(),
          end: end.toIso8601String(),
          course: calendarItem.course.id,
        );

        context.read<CalendarItemBloc>().add(
          UpdateHomeworkEvent(
            origin: EventOrigin.screen,
            courseGroupId: _courses
                .firstWhere((c) => c.id == calendarItem.course.id)
                .courseGroup,
            courseId: calendarItem.course.id,
            homeworkId: calendarItem.id,
            request: request,
          ),
        );
      } else {
        final request = EventRequestModel(
          start: start.toIso8601String(),
          end: end.toIso8601String(),
        );

        context.read<CalendarItemBloc>().add(
          UpdateEventEvent(
            origin: EventOrigin.screen,
            id: calendarItem.id,
            request: request,
          ),
        );
      }
    } else if (calendarItem is CourseScheduleEventModel) {
      showSnackBar(
        context,
        "You can't edit this on the Planner",
        isError: true,
      );
    } else if (calendarItem is ExternalCalendarEventModel) {
      showSnackBar(
        context,
        "You can't edit this on the Planner",
        isError: true,
      );
    }
  }

  void _resizeCalendarItemFromSfCalendar(
    AppointmentResizeEndDetails resizeDetails,
  ) {
    if (resizeDetails.appointment == null ||
        resizeDetails.startTime == null ||
        resizeDetails.endTime == null) {
      return;
    }

    final CalendarItemBaseModel calendarItem =
        resizeDetails.appointment as CalendarItemBaseModel;

    if (calendarItem is HomeworkModel || calendarItem is EventModel) {
      final originalStart = tz.TZDateTime.from(
        calendarItem.start,
        userSettings!.timeZone,
      );

      // Determine which edge was dragged by comparing to original start
      final startWasDragged =
          resizeDetails.startTime!.year != originalStart.year ||
          resizeDetails.startTime!.month != originalStart.month ||
          resizeDetails.startTime!.day != originalStart.day ||
          resizeDetails.startTime!.hour != originalStart.hour ||
          resizeDetails.startTime!.minute != originalStart.minute;

      // Only round the dragged edge's time
      final startMinute = startWasDragged
          ? ((resizeDetails.startTime!.minute + 15) ~/ 30) * 30
          : resizeDetails.startTime!.minute;
      final endMinute = startWasDragged
          ? resizeDetails.endTime!.minute
          : ((resizeDetails.endTime!.minute + 15) ~/ 30) * 30;

      final DateTime start = tz.TZDateTime(
        userSettings!.timeZone,
        resizeDetails.startTime!.year,
        resizeDetails.startTime!.month,
        resizeDetails.startTime!.day,
        resizeDetails.startTime!.hour,
        startMinute,
      );

      DateTime end = tz.TZDateTime(
        userSettings!.timeZone,
        resizeDetails.endTime!.year,
        resizeDetails.endTime!.month,
        resizeDetails.endTime!.day,
        resizeDetails.endTime!.hour,
        endMinute,
      );
      if (calendarItem.allDay) {
        end = end.add(const Duration(days: 1));
      }

      // Set optimistic override immediately for instant visual feedback
      _calendarItemDataSource!.setTimeOverride(
        calendarItem.id,
        start.toIso8601String(),
        end.toIso8601String(),
      );

      if (calendarItem is HomeworkModel) {
        final request = HomeworkRequestModel(
          start: start.toIso8601String(),
          end: end.toIso8601String(),
          course: calendarItem.course.id,
        );

        context.read<CalendarItemBloc>().add(
          UpdateHomeworkEvent(
            origin: EventOrigin.screen,
            courseGroupId: _courses
                .firstWhere((c) => c.id == calendarItem.course.id)
                .courseGroup,
            courseId: calendarItem.course.id,
            homeworkId: calendarItem.id,
            request: request,
          ),
        );
      } else {
        final request = EventRequestModel(
          start: start.toIso8601String(),
          end: end.toIso8601String(),
        );

        context.read<CalendarItemBloc>().add(
          UpdateEventEvent(
            origin: EventOrigin.screen,
            id: calendarItem.id,
            request: request,
          ),
        );
      }
    } else if (calendarItem is CourseScheduleEventModel) {
      showSnackBar(
        context,
        "You can't edit this on the Planner",
        isError: true,
      );
    } else if (calendarItem is ExternalCalendarEventModel) {
      showSnackBar(
        context,
        "You can't edit this on the Planner",
        isError: true,
      );
    }
  }

  void _deleteCalendarItem(
    BuildContext context,
    CalendarItemBaseModel calendarItem,
  ) {
    final CourseModel? course;
    if (calendarItem is HomeworkModel) {
      course = _courses.firstWhere((c) => c.id == calendarItem.course.id);
    } else {
      course = null;
    }

    final Function(CalendarItemBaseModel) onDelete;
    if (calendarItem is HomeworkModel) {
      onDelete = (h) {
        context.read<CalendarItemBloc>().add(
          DeleteHomeworkEvent(
            origin: EventOrigin.screen,
            courseGroupId: course!.courseGroup,
            courseId: course.id,
            homeworkId: h.id,
          ),
        );
      };
    } else if (calendarItem is EventModel) {
      onDelete = (e) {
        context.read<CalendarItemBloc>().add(
          DeleteEventEvent(origin: EventOrigin.screen, id: e.id),
        );
      };
    } else {
      return;
    }

    showConfirmDeleteDialog(
      parentContext: context,
      item: calendarItem,
      onDelete: onDelete,
    );
  }

  Widget _buildCalendarItem(
    BuildContext context,
    CalendarAppointmentDetails details,
  ) {
    if (details.isMoreAppointmentRegion) {
      return _buildMoreIndicator(context, details);
    }

    final calendarItem = details.appointments.first as CalendarItemBaseModel;
    final isInAgenda =
        _currentView == HeliumView.agenda ||
        (_currentView == HeliumView.month &&
            (details.bounds.height > 40 ||
                (Responsive.isMobile(context) && calendarItem.allDay)));
    final homeworkId = calendarItem is HomeworkModel ? calendarItem.id : null;

    // Use KeyedSubtree to help preserve widget state across rebuilds, prevents
    // flickers for drag-and-drop and similar operations
    return KeyedSubtree(
      key: ValueKey('calendar_item_${calendarItem.id}'),
      child: _buildCalendarItemWidget(
        calendarItem: calendarItem,
        width: details.bounds.width,
        height: details.bounds.height,
        isInAgenda: isInAgenda,
        completedOverride: homeworkId != null
            ? _calendarItemDataSource!.completedOverrides[homeworkId]
            : null,
      ),
    );
  }

  Widget _buildCalendarItemLeftForAgenda({
    required CalendarItemBaseModel calendarItem,
    bool? completedOverride,
  }) {
    Widget? iconWidget;

    final isCheckbox = PlannerHelper.shouldShowCheckbox(
      context,
      calendarItem,
      _currentView,
    );

    if (isCheckbox) {
      iconWidget = _buildCheckboxWidget(
        homework: calendarItem as HomeworkModel,
        completedOverride: completedOverride,
      );
    } else if (PlannerHelper.shouldShowSchoolIcon(
      context,
      calendarItem,
      _currentView,
    )) {
      iconWidget = _buildSchoolIconWidget();
    }

    if (iconWidget == null) {
      return const SizedBox.shrink();
    }

    final rowWidget = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(child: iconWidget),
        const SizedBox(width: 8),
      ],
    );

    // On mobile, make the entire left area tappable for checkboxes
    if (Responsive.isMobile(context) && isCheckbox) {
      final homework = calendarItem as HomeworkModel;
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            final newValue = !(completedOverride ?? homework.completed);
            _onToggleCompleted(homework, newValue);
          },
          child: rowWidget,
        ),
      );
    }

    return rowWidget;
  }

  Widget? _getInlineIconWidget({
    required CalendarItemBaseModel calendarItem,
    bool? completedOverride,
  }) {
    // TODO: Known Issues (2/Low): when the text wraps before even one letter can fit on the row, the prefix icon/checkbox gets pushed down a few pixels; fix here, and also for the .school icon (same behavior)
    if (PlannerHelper.shouldShowCheckbox(context, calendarItem, _currentView)) {
      return _buildCheckboxWidget(
        homework: calendarItem as HomeworkModel,
        completedOverride: completedOverride,
      );
    } else if (PlannerHelper.shouldShowSchoolIcon(
      context,
      calendarItem,
      _currentView,
    )) {
      return _buildSchoolIconWidget();
    }
    return null;
  }

  Widget _buildCalendarItemCenterForAgenda({
    required CalendarItemBaseModel calendarItem,
    String? location,
    bool? completedOverride,
  }) {
    final contentColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCalendarItemTitle(
          calendarItem,
          completedOverride: completedOverride,
        ),
        if (PlannerHelper.shouldShowTimeBelowTitle(
          context,
          calendarItem,
          true,
          _currentView,
        ))
          _buildCalendarItemTimeBelowTitleRow(calendarItem),
        if (PlannerHelper.shouldShowLocationBelowTitle(
              context,
              calendarItem,
              true,
              _currentView,
            ) &&
            location != null &&
            location.isNotEmpty)
          _buildCalendarItemLocationRow(location),
      ],
    );

    return Flexible(child: contentColumn);
  }

  Widget _buildCalendarItemCenterForTimeline({
    required CalendarItemBaseModel calendarItem,
    String? location,
    Widget? inlineIcon,
    bool? completedOverride,
  }) {
    final showTimeBeforeTitle = PlannerHelper.shouldShowTimeBeforeTitle(
      context,
      calendarItem,
      false,
      _currentView,
    );

    Widget titleRowWidget;
    if (inlineIcon != null || showTimeBeforeTitle) {
      final spans = <InlineSpan>[];

      if (inlineIcon != null) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: inlineIcon,
            ),
          ),
        );
      }

      if (showTimeBeforeTitle) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: EdgeInsets.only(
                right: Responsive.isMobile(context) ? 2 : 4,
              ),
              child: _buildCalendarItemTime(calendarItem),
            ),
          ),
        );
      }

      final isCompleted =
          completedOverride ??
          (calendarItem is HomeworkModel && calendarItem.completed);

      spans.add(
        TextSpan(
          text: calendarItem.title,
          style: AppStyles.smallSecondaryTextLight(context).copyWith(
            // TODO: Known Issues (4/Medium): Use dynamic text color based on background luminance to prevent visibility issues with light user-selected colors
            color: Colors.white,
            decoration: isCompleted
                ? TextDecoration.lineThrough
                : TextDecoration.none,
            decorationColor: Colors.white,
            decorationThickness: 2.0,
          ),
        ),
      );

      titleRowWidget = Text.rich(
        TextSpan(children: spans),
        maxLines: _currentView == HeliumView.month || calendarItem.allDay
            ? 1
            : null,
        overflow: _currentView == HeliumView.month || calendarItem.allDay
            ? TextOverflow.ellipsis
            : null,
      );
    } else {
      titleRowWidget = _buildCalendarItemTitle(
        calendarItem,
        completedOverride: completedOverride,
      );
    }

    final contentColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        titleRowWidget,
        if (PlannerHelper.shouldShowTimeBelowTitle(
          context,
          calendarItem,
          false,
          _currentView,
        ))
          _buildCalendarItemTimeBelowTitleRow(calendarItem),
        if (PlannerHelper.shouldShowLocationBelowTitle(
              context,
              calendarItem,
              false,
              _currentView,
            ) &&
            location != null &&
            location.isNotEmpty)
          _buildCalendarItemLocationRow(location),
      ],
    );

    return Align(alignment: Alignment.topLeft, child: contentColumn);
  }

  Widget _buildCalendarItemRight({
    required CalendarItemBaseModel calendarItem,
    CourseModel? course,
  }) {
    final buttons = <Widget>[];

    if (course?.teacherEmail.isNotEmpty ?? false) {
      buttons.add(
        HeliumIconButton(
          onPressed: () {
            launchUrl(Uri.parse('mailto:${course!.teacherEmail}'));
          },
          icon: Icons.email_outlined,
          tooltip: 'Email teacher',
          // TODO: Known Issues (7/Low): Use dynamic icon color based on calendar item background luminance to prevent visibility issues with light user-selected colors
          color: Colors.white,
        ),
      );
    }

    if (course?.website.isNotEmpty ?? false) {
      buttons.add(
        HeliumIconButton(
          onPressed: () {
            launchUrl(
              Uri.parse(course!.website),
              mode: LaunchMode.externalApplication,
            );
          },
          icon: Icons.link_outlined,
          tooltip: 'Launch class website',
          color: Colors.white,
        ),
      );
    }

    if (PlannerHelper.shouldShowEditButtonForCalendarItem(
      context,
      calendarItem,
    )) {
      buttons.add(
        HeliumIconButton(
          onPressed: () => _openCalendarItem(calendarItem),
          icon: Icons.edit_outlined,
          // TODO: Known Issues (4/Medium): Use dynamic text color based on background luminance to prevent visibility issues with light user-selected colors
          color: Colors.white,
        ),
      );
    }

    if (PlannerHelper.shouldShowDeleteButton(calendarItem)) {
      buttons.add(
        HeliumIconButton(
          onPressed: () => _deleteCalendarItem(context, calendarItem),
          icon: Icons.delete_outline,
          // TODO: Known Issues (4/Medium): Use dynamic text color based on background luminance to prevent visibility issues with light user-selected colors
          color: Colors.white,
        ),
      );
    }

    if (buttons.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        for (int i = 0; i < buttons.length; i++) ...[
          buttons[i],
          if (i < buttons.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }

  Widget _buildCalendarItemWidget({
    required CalendarItemBaseModel calendarItem,
    required double width,
    double? height,
    required bool isInAgenda,
    bool? completedOverride,
  }) {
    if (isInAgenda) {
      return _buildCalendarItemWidgetForAgenda(
        calendarItem: calendarItem,
        width: width,
        completedOverride: completedOverride,
      );
    } else {
      return _buildCalendarItemWidgetForTimeline(
        calendarItem: calendarItem,
        width: width,
        height: height,
        completedOverride: completedOverride,
      );
    }
  }

  Widget _buildCalendarItemWidgetForAgenda({
    required CalendarItemBaseModel calendarItem,
    required double width,
    bool? completedOverride,
  }) {
    final color = _calendarItemDataSource!.getColorForItem(calendarItem);
    final location = _calendarItemDataSource!.getLocationForItem(calendarItem);
    final course = _getCourseForCalendarItem(calendarItem);

    final leftWidget = _buildCalendarItemLeftForAgenda(
      calendarItem: calendarItem,
      completedOverride: completedOverride,
    );

    final centerWidget = _buildCalendarItemCenterForAgenda(
      calendarItem: calendarItem,
      location: location,
      completedOverride: completedOverride,
    );

    final rightWidget = _buildCalendarItemRight(
      calendarItem: calendarItem,
      course: course,
    );

    return Container(
      width: width,
      constraints: BoxConstraints(
        minHeight: Responsive.isMobile(context)
            ? _agendaHeightMobile
            : _agendaHeightDesktop,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      clipBehavior: Clip.hardEdge,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            leftWidget,
            centerWidget,
            const SizedBox(width: 8),
            rightWidget,
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarItemWidgetForTimeline({
    required CalendarItemBaseModel calendarItem,
    required double width,
    double? height,
    bool? completedOverride,
  }) {
    final color = _calendarItemDataSource!.getColorForItem(calendarItem);
    final location = _calendarItemDataSource!.getLocationForItem(calendarItem);

    final inlineIcon = _getInlineIconWidget(
      calendarItem: calendarItem,
      completedOverride: completedOverride,
    );

    final centerWidget = _buildCalendarItemCenterForTimeline(
      calendarItem: calendarItem,
      location: location,
      inlineIcon: inlineIcon,
      completedOverride: completedOverride,
    );

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      clipBehavior: Clip.hardEdge,
      child: UnconstrainedBox(
        constrainedAxis: Axis.horizontal,
        alignment: PlannerHelper.getAlignmentForView(
          context,
          false,
          _currentView,
        ),
        clipBehavior: Clip.hardEdge,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: centerWidget,
        ),
      ),
    );
  }

  CourseModel? _getCourseForCalendarItem(CalendarItemBaseModel calendarItem) {
    if (calendarItem is HomeworkModel) {
      return _courses.firstWhere((c) => c.id == calendarItem.course.id);
    } else if (calendarItem is CourseScheduleEventModel) {
      return _courses.firstWhere(
        (c) => c.id.toString() == calendarItem.ownerId,
      );
    }
    return null;
  }

  Widget _buildMoreIndicator(
    BuildContext context,
    CalendarAppointmentDetails details,
  ) {
    return GestureDetector(
      onTap: () {
        _openDayPopOutDialog(
          details.date,
          (details.appointments.cast<CalendarItemBaseModel>()).toList(),
        );
      },
      child: Container(
        width: details.bounds.width,
        height: details.bounds.height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          '...',
          style: AppStyles.standardBodyTextLight(context).copyWith(
            color: context.colorScheme.onPrimaryContainer.withValues(
              alpha: 0.9,
            ),
          ),
        ),
      ),
    );
  }

  void _openDayPopOutDialog(
    DateTime? date,
    List<CalendarItemBaseModel> calendarItems,
  ) {
    // TODO: Cleanup: migrate this out to its own file
    if (date == null || Responsive.isMobile(context)) return;

    showDialog(
      context: context,
      builder: (dialogContext) =>
          _buildDayPopOut(dialogContext, date, calendarItems),
    );
  }

  Widget _buildDayPopOut(
    BuildContext dialogContext,
    DateTime date,
    List<CalendarItemBaseModel> calendarItems,
  ) {
    return ListenableBuilder(
      listenable: _calendarItemDataSource!.changeNotifier,
      builder: (context, _) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            width: 360,
            constraints: const BoxConstraints(maxHeight: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          HeliumDateTime.formatDateWithDay(date),
                          style: AppStyles.headingText(
                            context,
                          ).copyWith(color: context.colorScheme.onSurface),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.close,
                          size: 20,
                          color: context.colorScheme.primary,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(8),
                    itemCount: calendarItems.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 6),
                    itemBuilder: (_, index) {
                      final staleCalendarItems = calendarItems[index];
                      final calendarItem =
                          _calendarItemDataSource!.allCalendarItems
                              .firstWhereOrNull(
                                (item) => item.id == staleCalendarItems.id,
                              ) ??
                          staleCalendarItems;
                      final homeworkId = calendarItem is HomeworkModel
                          ? calendarItem.id
                          : null;
                      final completedOverride = homeworkId != null
                          ? _calendarItemDataSource!
                                .completedOverrides[homeworkId]
                          : null;

                      return GestureDetector(
                        onTap: () {
                          if (PlannerHelper.shouldShowEditButtonForCalendarItem(
                            context,
                            calendarItem,
                          )) {
                            return;
                          }

                          Feedback.forTap(context);
                          if (_openCalendarItem(calendarItem)) {
                            Navigator.of(context).pop();
                          }
                        },
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxHeight: _agendaHeightDesktop,
                          ),
                          child: _buildCalendarItemWidget(
                            calendarItem: calendarItem,
                            width: double.infinity,
                            isInAgenda: true,
                            completedOverride: completedOverride,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _populateInitialCalendarStateData(CalendarScreenDataFetched state) {
    _log.info(
      'Planner screen data loaded: ${state.courses.length} courses, '
      '${state.categories.length} categories',
    );
    setState(() {
      _courseGroups = state.courseGroups;
      _courses = state.courses;
      for (final category in state.categories) {
        _categoriesMap[category.id] = category;
      }

      if (_calendarItemDataSource != null) {
        _calendarItemDataSource!.courses = _courses;
        _calendarItemDataSource!.categoriesMap = _categoriesMap;
      }

      _deduplicatedCategories.addAll(
        _deduplicateCategoriesByTitle(state.categories),
      );

      isLoading = false;
    });
  }

  void _goToToday() {
    _log.info('Today button pressed (view: $_currentView)');
    if (_currentView == HeliumView.todos) {
      if (_calendarItemDataSource != null) {
        _todosController.goToToday(_calendarItemDataSource!.filteredHomeworks);
      }
    } else {
      _jumpToDate(DateTime.now(), offsetForVisibility: true);
    }
  }

  void _jumpToDate(
    DateTime date, {
    bool setSelectedDate = false,
    bool offsetForVisibility = false,
  }) {
    _log.fine('Jumping to date: $date (setSelected: $setSelectedDate)');
    // Truncate to nearest hour (remove minutes/seconds)
    final truncatedDate = DateTime(date.year, date.month, date.day, date.hour);
    // Optionally offset by 2 hours so current time is visible (used for "today")
    final displayDate = offsetForVisibility
        ? truncatedDate.subtract(const Duration(hours: 2))
        : truncatedDate;

    setState(() {
      _calendarController.displayDate = displayDate;
      _storedDisplayDate = displayDate;

      if (setSelectedDate || _calendarController.selectedDate != null) {
        _calendarController.selectedDate = truncatedDate;
        _storedSelectedDate = truncatedDate;
      }

      // TODO: Known Issues (1/Medium): when jumping to a date that isn't within the loaded data source on "Schedule" view, the view shows the single specified date, but doesn't also trigger the "load more" behavior for that date window
    });
  }

  void _onToggleCompleted(HomeworkModel homework, bool value) {
    // TODO: Enhancement: show confetti when Homework is completed

    Feedback.forTap(context);

    _log.info('Homework ${homework.id} completion toggled: $value');

    // Set optimistic override immediately for instant visual feedback
    _calendarItemDataSource!.setCompletedOverride(homework.id, value);

    final request = HomeworkRequestModel(
      completed: !homework.completed,
      course: homework.course.id,
    );

    final course = _courses.firstWhere((c) => c.id == homework.course.id);

    context.read<CalendarItemBloc>().add(
      UpdateHomeworkEvent(
        origin: EventOrigin.screen,
        courseGroupId: course.courseGroup,
        courseId: course.id,
        homeworkId: homework.id,
        request: request,
      ),
    );
  }

  void _openCoursesMenu(BuildContext context, List<CourseModel> courses) {
    // TODO: Enhancement: consider migrating this in to the "Filters" menu, but cleaning it up (maybe making sections collapsible)
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    final List<CourseModel> displayCourses =
        PlannerHelper.sortByGroupStartThenByTitle(courses, _courseGroups);

    showMenu(
      context: context,
      position: position,
      color: context.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      items: [
        PopupMenuItem(
          enabled: false,
          padding: EdgeInsets.zero,
          child: StatefulBuilder(
            builder: (context, setMenuState) {
              return Material(
                color: context.colorScheme.surface,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                _calendarItemDataSource!.setFilteredCourses({});
                                setMenuState(() {});
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                child: Text(
                                  'Show All Classes',
                                  style: AppStyles.formText(context),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const Divider(height: 20),

                      Column(
                        children: [
                          for (int i = 0; i < displayCourses.length; i++) ...[
                            if (i > 0 &&
                                displayCourses[i].courseGroup !=
                                    displayCourses[i - 1].courseGroup)
                              const Divider(height: 20),
                            Builder(
                              builder: (context) {
                                final course = displayCourses[i];
                                final isSelected =
                                    _calendarItemDataSource!
                                        .filteredCourses[course.id] ??
                                    false;

                                return CheckboxListTile(
                                  title: Row(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: course.color,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              course.title,
                                              style: AppStyles.formText(
                                                context,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  value: isSelected,
                                  onChanged: (value) {
                                    final currentFilters = Map<int, bool>.from(
                                      _calendarItemDataSource!.filteredCourses,
                                    );
                                    if (value == true) {
                                      currentFilters[course.id] = true;
                                    } else {
                                      currentFilters.remove(course.id);
                                    }
                                    _calendarItemDataSource!.setFilteredCourses(
                                      currentFilters,
                                    );
                                    setMenuState(() {});
                                  },
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _openFilterMenu(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    showMenu(
      context: context,
      position: position,
      color: context.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      items: [
        PopupMenuItem(
          enabled: false,
          padding: EdgeInsets.zero,
          child: StatefulBuilder(
            builder: (context, setMenuState) {
              return Material(
                color: context.colorScheme.surface,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                _calendarItemDataSource!.clearFilters();
                                setMenuState(() {});
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                child: Text(
                                  'Clear Filters',
                                  style: AppStyles.formText(context),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const Divider(height: 20),

                      if (_currentView != HeliumView.todos) ...[
                        Column(
                          children: [
                            CheckboxListTile(
                              title: Text(
                                'Assignments',
                                style: AppStyles.menuItem(context),
                              ),
                              value: _calendarItemDataSource!.filterTypes
                                  .contains('Assignments'),
                              onChanged: (value) {
                                final currentTypes = List<String>.from(
                                  _calendarItemDataSource!.filterTypes,
                                );
                                if (value == true) {
                                  if (!currentTypes.contains('Assignments')) {
                                    currentTypes.add('Assignments');
                                  }
                                } else {
                                  currentTypes.remove('Assignments');
                                }
                                _calendarItemDataSource!.setFilterTypes(
                                  currentTypes,
                                );
                                setMenuState(() {});
                              },
                              controlAffinity: ListTileControlAffinity.leading,
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            CheckboxListTile(
                              title: Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: userSettings!.eventsColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Events',
                                    style: AppStyles.menuItem(context),
                                  ),
                                ],
                              ),
                              value: _calendarItemDataSource!.filterTypes
                                  .contains('Events'),
                              onChanged: (value) {
                                final currentTypes = List<String>.from(
                                  _calendarItemDataSource!.filterTypes,
                                );
                                if (value == true) {
                                  if (!currentTypes.contains('Events')) {
                                    currentTypes.add('Events');
                                  }
                                } else {
                                  currentTypes.remove('Events');
                                }
                                _calendarItemDataSource!.setFilterTypes(
                                  currentTypes,
                                );
                                setMenuState(() {});
                              },
                              controlAffinity: ListTileControlAffinity.leading,
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            CheckboxListTile(
                              title: Row(
                                children: [
                                  Icon(
                                    Icons.school,
                                    size: 12,
                                    color: context.colorScheme.onSurface,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Class Schedules',
                                    style: AppStyles.menuItem(context),
                                  ),
                                ],
                              ),
                              value: _calendarItemDataSource!.filterTypes
                                  .contains('Class Schedules'),
                              onChanged: (value) {
                                final currentTypes = List<String>.from(
                                  _calendarItemDataSource!.filterTypes,
                                );
                                if (value == true) {
                                  if (!currentTypes.contains(
                                    'Class Schedules',
                                  )) {
                                    currentTypes.add('Class Schedules');
                                  }
                                } else {
                                  currentTypes.remove('Class Schedules');
                                }
                                _calendarItemDataSource!.setFilterTypes(
                                  currentTypes,
                                );
                                setMenuState(() {});
                              },
                              controlAffinity: ListTileControlAffinity.leading,
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            CheckboxListTile(
                              title: Text(
                                'External Calendars',
                                style: AppStyles.menuItem(context),
                              ),
                              value: _calendarItemDataSource!.filterTypes
                                  .contains('External Calendars'),
                              onChanged: (value) {
                                final currentTypes = List<String>.from(
                                  _calendarItemDataSource!.filterTypes,
                                );
                                if (value == true) {
                                  if (!currentTypes.contains(
                                    'External Calendars',
                                  )) {
                                    currentTypes.add('External Calendars');
                                  }
                                } else {
                                  currentTypes.remove('External Calendars');
                                }
                                _calendarItemDataSource!.setFilterTypes(
                                  currentTypes,
                                );
                                setMenuState(() {});
                              },
                              controlAffinity: ListTileControlAffinity.leading,
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ],
                        ),

                        const Divider(height: 20),
                      ],

                      StatefulBuilder(
                        builder: (context, setStatusMenuState) {
                          Widget buildStatusTile(String label) {
                            final isChecked = _calendarItemDataSource!
                                .filterStatuses
                                .contains(label);
                            return CheckboxListTile(
                              title: Text(
                                label,
                                style: AppStyles.formText(context),
                              ),
                              value: isChecked,
                              onChanged: (value) {
                                final currentStatuses = Set<String>.from(
                                  _calendarItemDataSource!.filterStatuses,
                                );
                                if (value == true) {
                                  currentStatuses.add(label);
                                } else {
                                  currentStatuses.remove(label);
                                }
                                _calendarItemDataSource!.setFilterStatuses(
                                  currentStatuses,
                                );
                                setStatusMenuState(() {});
                              },
                              controlAffinity: ListTileControlAffinity.leading,
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            );
                          }

                          return Column(
                            children: [
                              // TODO: Enhancement: add another filter state called "Graded"
                              // TODO: Enhancement: ensure mutually exclusive filter states can't be checked at the same time (complete/incomplete, graded/ungraded)
                              // TODO: Enhancement: Combine opposite filter states (complete/incomplete, graded/ungraded) in to one, and put a switch toggle to the right of them—so checkbox "enables" the filter, switch toggle determines their true/false status when applying the filter
                              buildStatusTile('Complete'),
                              buildStatusTile('Incomplete'),
                              buildStatusTile('Overdue'),
                            ],
                          );
                        },
                      ),
                      if (_getVisibleCategories().isNotEmpty) ...[
                        const Divider(height: 20),

                        StatefulBuilder(
                          builder: (context, setCategoryMenuState) {
                            final visibleCategories = _getVisibleCategories();
                            return Column(
                              children: visibleCategories.map((category) {
                                return CheckboxListTile(
                                  title: Row(
                                    children: [
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          category.title,
                                          style: AppStyles.formText(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                  value: _calendarItemDataSource!
                                      .filterCategories
                                      .contains(category.title),
                                  onChanged: (value) {
                                    final currentCategories = List<String>.from(
                                      _calendarItemDataSource!.filterCategories,
                                    );
                                    if (value == true) {
                                      if (!currentCategories.contains(
                                        category.title,
                                      )) {
                                        currentCategories.add(category.title);
                                      }
                                    } else {
                                      currentCategories.remove(category.title);
                                    }
                                    _calendarItemDataSource!
                                        .setFilterCategories(currentCategories);
                                    setCategoryMenuState(() {});
                                  },
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _openViewMenu(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    showMenu(
      context: context,
      position: position,
      color: context.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      items: [
        PopupMenuItem(
          enabled: false,
          padding: EdgeInsets.zero,
          child: Material(
            color: context.colorScheme.surface,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  StatefulBuilder(
                    builder: (innerContext, setMenuState) {
                      return RadioGroup<HeliumView>(
                        groupValue: _currentView,
                        onChanged: (value) {
                          setState(() {
                            _changeView(value!);
                          });

                          Navigator.pop(context);

                          if (Responsive.isMobile(context)) {
                            setState(() {
                              _isFilterExpanded = false;
                            });
                          }
                        },
                        child: Column(
                          children: List.generate(HeliumView.values.length, (
                            index,
                          ) {
                            return RadioListTile<HeliumView>(
                              title: Text(
                                CalendarConstants
                                    .defaultViews[PlannerHelper.mapHeliumViewToApiView(
                                  HeliumView.values[index],
                                )],
                                style: AppStyles.formText(context),
                              ),
                              value: HeliumView.values[index],
                              controlAffinity: ListTileControlAffinity.leading,
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            );
                          }),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTodosView() {
    return ListenableBuilder(
      listenable: _calendarItemDataSource!.changeNotifier,
      builder: (context, _) {
        return TodosTable(
          dataSource: _calendarItemDataSource!,
          controller: _todosController,
          onTap: _openCalendarItem,
          onToggleCompleted: _onToggleCompleted,
          onDelete: _deleteCalendarItem,
        );
      },
    );
  }

  Widget _buildCalendarItemTitle(
    CalendarItemBaseModel calendarItem, {
    bool? completedOverride,
  }) {
    final isCompleted =
        completedOverride ??
        (calendarItem is HomeworkModel && calendarItem.completed);

    return Text(
      calendarItem.title,
      style: AppStyles.smallSecondaryTextLight(context).copyWith(
        // TODO: Known Issues (4/Medium): Use dynamic text color based on background luminance to prevent visibility issues with light user-selected colors
        color: Colors.white,
        decoration: isCompleted
            ? TextDecoration.lineThrough
            : TextDecoration.none,
        decorationColor: Colors.white,
        decorationThickness: 2.0,
      ),
      maxLines: _currentView == HeliumView.month || _currentView == HeliumView.agenda ? 1 : null,
      overflow: _currentView == HeliumView.month || _currentView == HeliumView.agenda ? TextOverflow.ellipsis : null,
    );
  }

  Widget _buildCheckboxWidget({
    required HomeworkModel homework,
    bool? completedOverride,
  }) {
    // If UI override exists, use that, to avoid a flicker
    final isCompleted =
        _calendarItemDataSource?.isHomeworkCompleted(homework) ??
        completedOverride ??
        homework.completed;

    return SizedBox(
      width: 16,
      height: 16,
      child: Transform.scale(
        scale: AppStyles.calendarItemPrefixScale(context),
        child: Checkbox(
          value: isCompleted,
          onChanged: (value) {
            _onToggleCompleted(homework, value!);
          },
          activeColor: context.colorScheme.primary,
          side: BorderSide(
            // TODO: Known Issues (8/Low): Use dynamic colors based on calendar item background luminance for checkbox, school icon, time icons, and location icons to prevent visibility issues with light user-selected colors
            color: Colors.white.withValues(alpha: 0.7),
            width: 2.5,
          ),
        ),
      ),
    );
  }

  Widget _buildSchoolIconWidget() {
    return SizedBox(
      width: 16,
      height: 16,
      child: Transform.scale(
        scale: AppStyles.calendarItemPrefixScale(context),
        child: Icon(
          Icons.school,
          size: 16,
          // TODO: Known Issues (4/Medium): Use dynamic text color based on background luminance to prevent visibility issues with light user-selected colors
          color: Colors.white.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  Widget _buildCalendarItemTime(CalendarItemBaseModel calendarItem) {
    return Text(
      HeliumDateTime.formatTime(
        HeliumDateTime.toLocal(calendarItem.start, userSettings!.timeZone),
      ),
      style: AppStyles.smallSecondaryTextLight(
        context,
        // TODO: Known Issues (4/Medium): Use dynamic text color based on background luminance to prevent visibility issues with light user-selected colors
      ).copyWith(color: Colors.white.withValues(alpha: 0.7)),
    );
  }

  Widget _buildCalendarItemTimeBelowTitleRow(
    CalendarItemBaseModel calendarItem,
  ) {
    return Row(
      children: [
        Expanded(
          child: Text(
            HeliumDateTime.formatTimeRange(
              HeliumDateTime.toLocal(calendarItem.start, userSettings!.timeZone),
              HeliumDateTime.toLocal(calendarItem.end, userSettings!.timeZone),
              calendarItem.showEndTime,
            ),
            style: AppStyles.smallSecondaryTextLight(
              context,
              // TODO: Known Issues (4/Medium): Use dynamic text color based on background luminance to prevent visibility issues with light user-selected colors
            ).copyWith(color: Colors.white.withValues(alpha: 0.7)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarItemLocationRow(String location) {
    return Row(
      children: [
        Icon(
          Icons.pin_drop_outlined,
          size: 10,
          // TODO: Known Issues (4/Medium): Use dynamic text color based on background luminance to prevent visibility issues with light user-selected colors
          color: Colors.white.withValues(alpha: 0.4),
        ),
        const SizedBox(width: 2),
        Expanded(
          child: Text(
            location,
            style: AppStyles.smallSecondaryTextLight(
              context,
              // TODO: Known Issues (4/Medium): Use dynamic text color based on background luminance to prevent visibility issues with light user-selected colors
            ).copyWith(color: Colors.white.withValues(alpha: 0.7)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
