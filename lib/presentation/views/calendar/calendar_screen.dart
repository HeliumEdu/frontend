// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:async';

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
import 'package:heliumapp/data/models/planner/course_model.dart';
import 'package:heliumapp/data/models/planner/course_schedule_event_model.dart';
import 'package:heliumapp/data/models/planner/event_model.dart';
import 'package:heliumapp/data/models/planner/event_request_model.dart';
import 'package:heliumapp/data/models/planner/external_calendar_event_model.dart';
import 'package:heliumapp/data/models/planner/homework_model.dart';
import 'package:heliumapp/data/models/planner/homework_request_model.dart';
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
import 'package:heliumapp/presentation/views/core/base_page_screen_state.dart';
import 'package:heliumapp/presentation/widgets/helium_icon_button.dart';
import 'package:heliumapp/presentation/widgets/loading_indicator.dart';
import 'package:heliumapp/presentation/widgets/shadow_container.dart';
import 'package:heliumapp/presentation/widgets/todos_table.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/date_time_helpers.dart';
import 'package:heliumapp/utils/planner_helper.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:timezone/standalone.dart' as tz;
import 'package:url_launcher/url_launcher.dart';

final log = Logger('HeliumLogger');

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
  @override
  String get screenTitle => 'Calendar';

  @override
  NotificationArgs? get notificationNavArgs =>
      NotificationArgs(calendarItemBloc: context.read<CalendarItemBloc>());

  @override
  VoidCallback get navPopCallback => loadSettings;

  @override
  VoidCallback get actionButtonCallback => () {
    context.push(
      AppRoutes.calendarItemAddScreen,
      extra: CalendarItemAddArgs(
        calendarItemBloc: context.read<CalendarItemBloc>(),
        initialDate: _calendarController.selectedDate,
        isFromMonthView: _calendarController.view == CalendarView.month,
        isEdit: false,
      ),
    );
  };

  @override
  bool get showActionButton => true;

  late final CalendarController _calendarController;
  final List<CalendarView> _allowedViews = [
    CalendarView.month,
    CalendarView.week,
    CalendarView.day,
    CalendarView.schedule,
  ];

  // State
  List<CourseModel> _courses = [];
  final Map<int, CategoryModel> _categoriesMap = {};
  final List<CategoryModel> _deduplicatedCategories = [];
  bool _isSearchExpanded = false;
  bool _isFilterExpanded = false;
  HeliumView _currentView = HeliumView.day;

  CalendarItemDataSource? _calendarItemDataSource;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _searchTypingTimer;
  final ScrollController _monthViewScrollController = ScrollController();

  final GlobalKey calendarKey = GlobalKey();
  final GlobalKey todosTableKey = GlobalKey();
  final GlobalKey _todayButtonKey = GlobalKey();
  int _scheduleViewRebuildCounter = 0;

  @override
  void initState() {
    super.initState();

    _calendarController = CalendarController()
      ..view = PlannerHelper.mapHeliumViewToSfCalendarView(_currentView);

    context.read<CalendarBloc>().add(FetchCalendarScreenDataEvent());

    _calendarController.addPropertyChangedListener((value) {
      if (value == 'calendarView') {
        _calendarViewChanged();
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
    _searchController.dispose();
    _searchFocusNode.dispose();
    _searchTypingTimer?.cancel();
    _monthViewScrollController.dispose();
    super.dispose();
  }

  @override
  Future<UserSettingsModel> loadSettings() {
    return super.loadSettings().then((settings) {
      if (mounted) {
        setState(() {
          _changeView(PlannerHelper.mapApiViewToHeliumView(
            userSettings.defaultView,
          ));

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
          return buildReload(state.message!, () {
            FetchCalendarScreenDataEvent();
          });
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
    if (_calendarItemDataSource == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListenableBuilder(
      listenable: _calendarItemDataSource!.changeNotifier,
      builder: (context, _) {
        // For month view, wrap to make it scrollable if the view height is too small
        if (_calendarController.view == CalendarView.month) {
          return LayoutBuilder(
            builder: (context, constraints) {
              const double minCalendarHeight = 600;
              final double calendarHeight =
                  constraints.maxHeight < minCalendarHeight
                  ? minCalendarHeight
                  : constraints.maxHeight;

              return Stack(
                children: [
                  SingleChildScrollView(
                    controller: _monthViewScrollController,
                    child: SizedBox(
                      height: calendarHeight,
                      child: _buildCalendar(),
                    ),
                  ),
                  if (!_calendarItemDataSource!.hasLoadedInitialData)
                    Positioned.fill(
                      child: Container(
                        color: context.colorScheme.surface,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                    ),
                ],
              );
            },
          );
        }

        return Stack(
          children: [
            _buildCalendar(),
            if (!_calendarItemDataSource!.hasLoadedInitialData)
              Positioned.fill(
                child: Container(
                  color: context.colorScheme.surface,
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        );
      },
    );
  }

  int _calculateAppointmentDisplayCount(double availableHeight) {
    const double dayHeaderHeight = 45;
    const double dayNumberHeight = 30;
    const double appointmentHeight = 21;
    const int monthRows = 6;
    const int minCount = 3;

    final cellHeight = (availableHeight - dayHeaderHeight) / monthRows;
    final availableForAppointments = cellHeight - dayNumberHeight;
    final count = (availableForAppointments / appointmentHeight).floor();

    return count.clamp(minCount, 10);
  }

  Widget _buildCalendar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final appointmentDisplayCount = _calculateAppointmentDisplayCount(
          constraints.maxHeight,
        );

        // Use unique key for schedule view to force rebuild and reset
        // SfCalendar's internal state (workaround for Syncfusion bug)
        final effectiveKey = _currentView == HeliumView.agenda
            ? ValueKey('schedule_$_scheduleViewRebuildCounter')
            : calendarKey;

        final agendaHeight = Responsive.isMobile(context) ? 50.0 : 53.0;

        return SfCalendar(
          key: effectiveKey,
          backgroundColor: context.colorScheme.surface,
          controller: _calendarController,
          headerHeight: 0,
          showCurrentTimeIndicator: true,
          showWeekNumber: !Responsive.isMobile(context),
          allowDragAndDrop: true,
          dragAndDropSettings: DragAndDropSettings(
            timeIndicatorStyle: context.formText.copyWith(
              color: context.colorScheme.primary,
            ),
          ),
          allowAppointmentResize: true,
          allowedViews: _allowedViews,
          dataSource: _calendarItemDataSource,
          timeZone: userSettings.timeZone.name,
          firstDayOfWeek:
              PlannerHelper.weekStartsOnRemap[userSettings.weekStartsOn],
          scheduleViewSettings: ScheduleViewSettings(
            hideEmptyScheduleWeek: true,
            appointmentItemHeight: agendaHeight,
          ),
          monthViewSettings: MonthViewSettings(
            appointmentDisplayCount: appointmentDisplayCount,
            showAgenda: Responsive.isMobile(context),
            agendaItemHeight: agendaHeight,
            appointmentDisplayMode: Responsive.isMobile(context)
                ? MonthAppointmentDisplayMode.indicator
                : MonthAppointmentDisplayMode.appointment,
            dayFormat: 'EEE',
          ),
          timeSlotViewSettings: const TimeSlotViewSettings(
            minimumAppointmentDuration: Duration(minutes: 32),
            dayFormat: 'EEE',
          ),
          loadMoreWidgetBuilder: _loadMoreWidgetBuilder,
          appointmentBuilder: _buildCalendarItem,
          onTap: _openCalendarItemFromSfCalendar,
          onDragEnd: _dropCalendarItemFromSfCalendar,
          onAppointmentResizeEnd: _resizeCalendarItemFromSfCalendar,
        );
      },
    );
  }

  bool _openCalendarItem(CalendarItemBaseModel calendarItem) {
    if (calendarItem is CourseScheduleEventModel) {
      showSnackBar(
        context,
        'Items from schedules can\'t be edited on the Calendar',
        isError: true,
      );

      return false;
    } else if (calendarItem is ExternalCalendarEventModel) {
      showSnackBar(
        context,
        "Items from external calendars can't be edited on the Calendar",
        isError: true,
      );

      return false;
    }

    final int? eventId = calendarItem is EventModel ? calendarItem.id : null;
    final int? homeworkId = calendarItem is HomeworkModel
        ? calendarItem.id
        : null;

    context.push(
      AppRoutes.calendarItemAddScreen,
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
    final showTodayButton =
        _currentView != HeliumView.agenda && _currentView != HeliumView.todos;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ShadowContainer(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Stack(
                children: [
                  Row(
                    children: [
                      if (showTodayButton)
                        _buildTodayButton(
                          showLabel: !isMobile,
                          key: _todayButtonKey,
                        ),
                      _buildCalendarDateArea(),
                      // Spacer for collapsed filter area (single button on mobile, 4 buttons on desktop)
                      SizedBox(width: isMobile ? 46 : 220),
                    ],
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: _buildFilterArea(containerWidth: constraints.maxWidth),
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

    if (showLabel) {
      return OutlinedButton.icon(
        key: key,
        onPressed: _goToToday,
        icon: icon,
        style: ButtonStyle(
          padding: WidgetStateProperty.all(
            EdgeInsets.symmetric(
              horizontal: 12,
              vertical: Responsive.isMobile(context) ? 12 : 16,
            ),
          ),
          side: WidgetStateProperty.all(
            BorderSide(color: context.colorScheme.primary),
          ),
        ),
        label: Text(
          'Today',
          style: context.buttonText.copyWith(
            color: context.colorScheme.primary,
          ),
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
    if (_currentView == HeliumView.agenda || _currentView == HeliumView.todos) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.only(left: 12, top: 10),
          child: Text(
            CalendarConstants.defaultViews[PlannerHelper.mapHeliumViewToApiView(
              _currentView,
            )],
            style: context.calendarDate,
          ),
        ),
      );
    }

    final String headerText = _buildHeaderDate();

    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(Icons.chevron_left, color: context.colorScheme.primary),
            onPressed: () => _changeCalendarPeriod(false),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 4),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                _openDatePicker();
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.only(left: 8, top: 2, bottom: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(headerText, style: context.calendarDate),
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
          if (!Responsive.isMobile(context)) const SizedBox(width: 4),
          IconButton(
            icon: Icon(Icons.chevron_right, color: context.colorScheme.primary),
            onPressed: () => _changeCalendarPeriod(true),
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
              (todayButtonContext.findRenderObject() as RenderBox).size.width -
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
            // Filter icons
            AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _isSearchExpanded ? 0.0 : 1.0,
              child: IgnorePointer(
                ignoring: _isSearchExpanded,
                child: _buildFilterAndSearchButtons(),
              ),
            ),
            // Search field
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
            // Single filter button (collapsed state)
            AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: (_isFilterExpanded || _isSearchExpanded) ? 0.0 : 1.0,
              child: IgnorePointer(
                ignoring: _isFilterExpanded || _isSearchExpanded,
                child: _buildCollapsedFilterButton(),
              ),
            ),
            // All filter buttons (expanded state)
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
            // Search field
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
                            style: TextStyle(
                              fontSize: Responsive.getFontSize(
                                context,
                                mobile: 14,
                                tablet: 15,
                                desktop: 16,
                              ),
                              color: context.colorScheme.onSurface,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search ...',
                              hintStyle: TextStyle(
                                color: context.colorScheme.outline,
                                fontSize: Responsive.getFontSize(
                                  context,
                                  mobile: 14,
                                  tablet: 15,
                                  desktop: 16,
                                ),
                              ),
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
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Builder(
              builder: (context) {
                return IconButton.outlined(
                  onPressed: () => _openViewMenu(context),
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
            SizedBox(
              width: 50,
              child: Builder(
                builder: (context) {
                  return IconButton.outlined(
                    onPressed: _courses.isEmpty
                        ? null
                        : () => _openCoursesMenu(context, _courses),
                    icon: const Icon(Icons.school),
                    style: ButtonStyle(
                      side: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.disabled)) {
                          return BorderSide(
                            color: context.colorScheme.onSurface.withValues(
                              alpha: 0.12,
                            ),
                          );
                        }
                        return BorderSide(color: context.colorScheme.primary);
                      }),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            Builder(
              builder: (context) {
                return IconButton.outlined(
                  onPressed: _courses.isEmpty
                      ? null
                      : () => _openFilterMenu(context),
                  icon: const Icon(Icons.filter_alt),
                  style: ButtonStyle(
                    side: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.disabled)) {
                        return BorderSide(
                          color: context.colorScheme.onSurface.withValues(
                            alpha: 0.12,
                          ),
                        );
                      }
                      return BorderSide(color: context.colorScheme.primary);
                    }),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            IconButton.outlined(
              onPressed: () {
                setState(() {
                  _isFilterExpanded = false;
                  _isSearchExpanded = true;
                  _searchFocusNode.requestFocus();
                });
              },
              icon: Icon(Icons.search, color: context.colorScheme.primary),
              style: ButtonStyle(
                side: _isSearchExpanded
                    ? null
                    : WidgetStateProperty.all(
                        BorderSide(color: context.colorScheme.primary),
                      ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _buildHeaderDate() {
    final displayDate = _calendarController.displayDate!;
    final monthFormat = Responsive.isMobile(context) ? 'MMM' : 'MMMM';

    switch (_calendarController.view) {
      case CalendarView.day:
        return DateFormat('$monthFormat d, yyyy').format(displayDate);
      case CalendarView.month:
      case CalendarView.week:
      case CalendarView.schedule:
      default:
        return DateFormat('$monthFormat yyyy').format(displayDate);
    }
  }

  void _changeCalendarPeriod(bool forward) {
    final displayDate = _calendarController.displayDate!;
    DateTime newDate;

    switch (_calendarController.view) {
      case CalendarView.month:
      case CalendarView.schedule:
        newDate = DateTime(
          displayDate.year,
          displayDate.month + (forward ? 1 : -1),
          1,
        );
        break;
      case CalendarView.week:
      case CalendarView.timelineWeek:
        newDate = displayDate.add(Duration(days: forward ? 7 : -7));
        break;
      case CalendarView.day:
        newDate = displayDate.add(Duration(days: forward ? 1 : -1));
        break;
      default:
        newDate = displayDate;
    }

    setState(() {
      _calendarController.displayDate = newDate;
    });
  }

  Future<void> _openDatePicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _calendarController.displayDate!,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 10)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );

    if (picked != null) {
      setState(() {
        _calendarController.displayDate = picked;
      });
    }
  }

  /// Centralized helper to change the current view and keep both state variables in sync
  void _changeView(HeliumView newView) {
    _currentView = newView;
    // Only update the calendar controller's view if not switching to Todos
    // (Todos is a custom view that doesn't exist in SfCalendar)
    if (newView != HeliumView.todos) {
      _calendarController.view =
          PlannerHelper.mapHeliumViewToSfCalendarView(newView);
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

    // FIXME: double-check that this logic is intuitive to the user, and works with "schedule" view
    if ((_calendarController.view == CalendarView.month ||
            _calendarController.view == CalendarView.schedule) &&
        _calendarController.selectedDate == null) {
      _calendarController.selectedDate = DateTime.now();
    } else {
      _calendarController.selectedDate = null;
    }

    // Force schedule view to rebuild when entering it
    // This resets SfCalendar's internal state which can get corrupted
    if (_calendarController.view == CalendarView.schedule) {
      _scheduleViewRebuildCounter++;
    }
  }

  FutureBuilder<void> _loadMoreWidgetBuilder(
    BuildContext context,
    LoadMoreCallback loadMoreAppointments,
  ) {
    return FutureBuilder<void>(
      future: loadMoreAppointments(),
      builder: (context, snapShot) {
        if (snapShot.connectionState == ConnectionState.done) {
          return const SizedBox.shrink();
        }
        return Container(
          height: _calendarController.view == CalendarView.schedule
              ? 50
              : double.infinity,
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
        DateTime.parse(calendarItem.start),
        userSettings.timeZone,
      );
      final Duration duration = tz.TZDateTime.from(
        DateTime.parse(calendarItem.end),
        userSettings.timeZone,
      ).difference(startDateTime);

      final roundedMinute =
          ((dropDetails.droppingTime!.minute + 15) ~/ 30) * 30;

      final DateTime start = tz.TZDateTime(
        userSettings.timeZone,
        dropDetails.droppingTime!.year,
        dropDetails.droppingTime!.month,
        dropDetails.droppingTime!.day,
        _currentView == HeliumView.month
            ? startDateTime.hour
            : dropDetails.droppingTime!.hour,
        _currentView == HeliumView.month ? startDateTime.minute : roundedMinute,
      );
      final DateTime end = start.add(duration);

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
        'Items from schedules can\'t be edited on the Calendar',
        isError: true,
      );
    } else if (calendarItem is ExternalCalendarEventModel) {
      showSnackBar(
        context,
        "Items from external calendars can't be edited on the Calendar",
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
        DateTime.parse(calendarItem.start),
        userSettings.timeZone,
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
        userSettings.timeZone,
        resizeDetails.startTime!.year,
        resizeDetails.startTime!.month,
        resizeDetails.startTime!.day,
        resizeDetails.startTime!.hour,
        startMinute,
      );

      DateTime end = tz.TZDateTime(
        userSettings.timeZone,
        resizeDetails.endTime!.year,
        resizeDetails.endTime!.month,
        resizeDetails.endTime!.day,
        resizeDetails.endTime!.hour,
        endMinute,
      );
      if (calendarItem.allDay) {
        end = end.add(const Duration(days: 1));
      }

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
        'Items from schedules can\'t be edited on the Calendar',
        isError: true,
      );
    } else if (calendarItem is ExternalCalendarEventModel) {
      showSnackBar(
        context,
        "Items from external calendars can't be edited on the Calendar",
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
      return _buildMoreAppointmentsIndicator(context, details);
    }

    final calendarItem = details.appointments.first as CalendarItemBaseModel;
    final isInAgenda =
        _currentView == HeliumView.agenda ||
        (_currentView == HeliumView.month &&
            (details.bounds.height > 40 ||
                (Responsive.isMobile(context) && calendarItem.allDay)));
    final homeworkId = calendarItem is HomeworkModel ? calendarItem.id : null;

    return _buildCalendarItemWidget(
      calendarItem: calendarItem,
      width: details.bounds.width,
      height: details.bounds.height,
      isInAgenda: isInAgenda,
      completedOverride: homeworkId != null
          ? _calendarItemDataSource!.completedOverrides[homeworkId]
          : null,
    );
  }

  Widget _buildCalendarItemLeft({
    required CalendarItemBaseModel calendarItem,
    required bool isInAgenda,
    VoidCallback? onCheckboxToggled,
    bool? completedOverride,
  }) {
    if (Responsive.isMobile(context) && !isInAgenda) {
      return const SizedBox.shrink();
    }

    Widget? iconWidget;

    if (PlannerHelper.shouldShowCheckbox(context, calendarItem, _currentView)) {
      calendarItem as HomeworkModel;
      iconWidget = SizedBox(
        width: 16,
        height: 16,
        child: Transform.scale(
          scale: AppTextStyles.calendarCheckboxScale(context),
          child: Checkbox(
            value: completedOverride ?? calendarItem.completed,
            onChanged: (value) {
              Feedback.forTap(context);
              _toggleHomeworkCompleted(calendarItem, value!);
              onCheckboxToggled?.call();
            },
            activeColor: context.colorScheme.primary,
          ),
        ),
      );
    } else if (PlannerHelper.shouldShowSchoolIcon(
      context,
      calendarItem,
      _currentView,
    )) {
      iconWidget = SizedBox(
        width: 16,
        height: 16,
        child: Transform.scale(
          scale: AppTextStyles.calendarCheckboxScale(context),
          child: const Icon(Icons.school, size: 16, color: Colors.white),
        ),
      );
    }

    if (iconWidget == null) {
      return const SizedBox.shrink();
    }

    final paddedIcon = isInAgenda
        ? iconWidget
        : Padding(padding: const EdgeInsets.only(top: 1.5), child: iconWidget);

    final alignedIcon = isInAgenda
        ? Center(child: paddedIcon) // Centered for agenda/schedule
        : Align(
            alignment: Alignment.topLeft,
            child: paddedIcon,
          ); // Top-left for other views

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        alignedIcon,
        SizedBox(width: Responsive.isMobile(context) && !isInAgenda ? 2 : 8),
      ],
    );
  }

  Widget _buildCalendarItemCenter({
    required CalendarItemBaseModel calendarItem,
    required bool isInAgenda,
    String? location,
  }) {
    final contentColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isInAgenda &&
            PlannerHelper.shouldShowTimeBeforeTitle(
              context,
              calendarItem,
              false,
              _currentView,
            ))
          Row(
            children: [
              Text(
                HeliumDateTime.formatTimeForDisplay(
                  HeliumDateTime.parse(
                    calendarItem.start,
                    userSettings.timeZone,
                  ),
                ),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12.0,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(width: Responsive.isMobile(context) ? 2 : 4),
              Expanded(
                child: Text(
                  calendarItem.title,
                  style: context.calendarData.copyWith(
                    fontSize: AppTextStyles.calendarDataFontSize(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          )
        else
          Text(
            calendarItem.title,
            style: context.calendarData.copyWith(
              fontSize: AppTextStyles.calendarDataFontSize(context),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

        if (PlannerHelper.shouldShowTimeBelowTitle(
          context,
          calendarItem,
          isInAgenda,
          _currentView,
        ))
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 10,
                color: Colors.white.withValues(alpha: 0.4),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: Text(
                  HeliumDateTime.formatTimeRangeForDisplay(
                    HeliumDateTime.parse(
                      calendarItem.start,
                      userSettings.timeZone,
                    ),
                    HeliumDateTime.parse(
                      calendarItem.end,
                      userSettings.timeZone,
                    ),
                    calendarItem.showEndTime,
                  ),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12.0,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

        if (PlannerHelper.shouldShowLocationBelowTitle(
              context,
              calendarItem,
              isInAgenda,
              _currentView,
            ) &&
            location != null)
          Row(
            children: [
              Icon(
                Icons.pin_drop_outlined,
                size: 10,
                color: Colors.white.withValues(alpha: 0.4),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: Text(
                  location,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12.0,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
      ],
    );

    return Flexible(
      child: Align(
        alignment: Alignment.topLeft,
        child: isInAgenda
            ? OverflowBox(
                alignment: Alignment.topLeft,
                maxHeight: double.infinity,
                child: contentColumn,
              )
            : contentColumn,
      ),
    );
  }

  Widget _buildCalendarItemRight({
    required CalendarItemBaseModel calendarItem,
    required bool isInAgenda,
    CourseModel? course,
  }) {
    if (!isInAgenda) {
      return const SizedBox.shrink();
    }

    final buttons = <Widget>[];

    if (course?.teacherEmail.isNotEmpty ?? false) {
      buttons.add(
        HeliumIconButton(
          onPressed: () {
            launchUrl(Uri.parse('mailto:${course!.teacherEmail}'));
          },
          icon: Icons.email_outlined,
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
          color: Colors.white,
        ),
      );
    }

    if (PlannerHelper.shouldShowEditAndDeleteButtons(calendarItem)) {
      buttons.add(
        HeliumIconButton(
          onPressed: () => _openCalendarItem(calendarItem),
          icon: Icons.edit_outlined,
          color: Colors.white,
        ),
      );
    }

    if (PlannerHelper.shouldShowEditAndDeleteButtons(calendarItem)) {
      buttons.add(
        HeliumIconButton(
          onPressed: () => _deleteCalendarItem(context, calendarItem),
          icon: Icons.delete_outline,
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
    VoidCallback? onCheckboxToggled,
    bool? completedOverride,
  }) {
    final color = _calendarItemDataSource!.getColorForItem(calendarItem);
    final location = _calendarItemDataSource!.getLocationForItem(calendarItem);

    CourseModel? course;
    if (calendarItem is HomeworkModel) {
      course = _courses.firstWhere((c) => c.id == calendarItem.course.id);
    } else if (calendarItem is CourseScheduleEventModel) {
      course = _courses.firstWhere(
        (c) => c.id.toString() == calendarItem.ownerId,
      );
    }

    final leftWidget = _buildCalendarItemLeft(
      calendarItem: calendarItem,
      isInAgenda: isInAgenda,
      onCheckboxToggled: onCheckboxToggled,
      completedOverride: completedOverride,
    );

    final centerWidget = _buildCalendarItemCenter(
      calendarItem: calendarItem,
      isInAgenda: isInAgenda,
      location: location,
    );

    final rightWidget = _buildCalendarItemRight(
      calendarItem: calendarItem,
      isInAgenda: isInAgenda,
      course: course,
    );

    return Container(
      width: width,
      height: isInAgenda ? null : height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      clipBehavior: Clip.hardEdge,
      child: isInAgenda
          ? Padding(
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
            )
          : UnconstrainedBox(
              constrainedAxis: Axis.horizontal,
              alignment: PlannerHelper.getAlignmentForView(
                context,
                isInAgenda,
                _currentView,
              ),
              clipBehavior: Clip.hardEdge,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [leftWidget, centerWidget],
                ),
              ),
            ),
    );
  }

  Widget _buildMoreAppointmentsIndicator(
    BuildContext context,
    CalendarAppointmentDetails details,
  ) {
    return GestureDetector(
      onTap: () {
        _showDayAppointmentsDialog(
          details.date,
          (details.appointments as List<CalendarItemBaseModel>).toList(),
        );
      },
      child: Container(
        width: details.bounds.width,
        height: details.bounds.height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          '...',
          style: TextStyle(
            color: context.colorScheme.onSurfaceVariant,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  void _showDayAppointmentsDialog(
    DateTime? date,
    List<CalendarItemBaseModel> appointments,
  ) {
    // TODO: migrate this out to its own file
    if (date == null || Responsive.isMobile(context)) return;

    showDialog(
      context: context,
      builder: (dialogContext) =>
          _buildDayAppointmentsDialog(dialogContext, date, appointments),
    );
  }

  Widget _buildDayAppointmentsDialog(
    BuildContext dialogContext,
    DateTime date,
    List<CalendarItemBaseModel> appointments,
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
                // Header with date and close button
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          DateFormat('EEEE, MMMM d').format(date),
                          style: context.calendarDate.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
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
                // Appointments list
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(8),
                    itemCount: appointments.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 6),
                    itemBuilder: (_, index) {
                      // Use current item from data source, not stale appointments list
                      final staleAppointment = appointments[index];
                      final appointment =
                          _calendarItemDataSource!.allCalendarItems
                              .cast<CalendarItemBaseModel?>()
                              .firstWhere(
                                (item) => item?.id == staleAppointment.id,
                                orElse: () => null,
                              ) ??
                          staleAppointment;
                      final homeworkId = appointment is HomeworkModel
                          ? appointment.id
                          : null;
                      final completedOverride = homeworkId != null
                          ? _calendarItemDataSource!
                                .completedOverrides[homeworkId]
                          : null;

                      return GestureDetector(
                        onTap: () {
                          Feedback.forTap(context);
                          if (_openCalendarItem(appointment)) {
                            Navigator.of(context).pop();
                          }
                        },
                        child: _buildCalendarItemWidget(
                          calendarItem: appointment,
                          width: double.infinity,
                          isInAgenda: true,
                          completedOverride: completedOverride,
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
    setState(() {
      _courses = state.courses;
      for (final category in state.categories) {
        _categoriesMap[category.id] = category;
      }

      // Only update data source if it's been initialized (settings loaded)
      if (_calendarItemDataSource != null) {
        _calendarItemDataSource!.courses = _courses;
        _calendarItemDataSource!.categoriesMap = _categoriesMap;
      }

      final uniqueCategories = <String, CategoryModel>{};
      for (var category in state.categories) {
        if (!uniqueCategories.containsKey(category.title)) {
          uniqueCategories[category.title] = category;
        }
      }

      _deduplicatedCategories.addAll(uniqueCategories.values.toList());

      isLoading = false;
    });
  }

  void _goToToday() {
    setState(() {
      _calendarController.selectedDate = null;
      _calendarController.displayDate = DateTime.now().subtract(
        const Duration(hours: 2),
      );
    });
  }

  void _toggleHomeworkCompleted(HomeworkModel homework, bool value) {
    // Set optimistic UI state
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

    final Map<String, CourseModel> uniqueCourseMap = {};
    for (final course in courses) {
      final title = course.title.trim();
      if (title.isEmpty) continue;
      final normalized = title.toLowerCase();
      uniqueCourseMap.putIfAbsent(normalized, () => course);
    }
    final List<CourseModel> displayCourses = uniqueCourseMap.values.toList();

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
                                  vertical: 8,
                                ),
                                child: Text(
                                  'Show All Classes',
                                  style: context.cTextStyle.copyWith(
                                    color: context.colorScheme.onSurface,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const Divider(height: 20),

                      Column(
                        children: displayCourses.map((course) {
                          final isSelected =
                              _calendarItemDataSource!.filteredCourses[course
                                  .title] ??
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
                                        style: context.cTextStyle.copyWith(
                                          color: context.colorScheme.onSurface,
                                          fontWeight: FontWeight.w600,
                                          fontSize: Responsive.getFontSize(
                                            context,
                                            mobile: 13,
                                            tablet: 14,
                                            desktop: 15,
                                          ),
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
                              final currentFilters = Map<String, bool>.from(
                                _calendarItemDataSource!.filteredCourses,
                              );
                              if (value == true) {
                                currentFilters[course.title] = true;
                              } else {
                                currentFilters.remove(course.title);
                              }
                              _calendarItemDataSource!.setFilteredCourses(
                                currentFilters,
                              );
                              setMenuState(() {});
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          );
                        }).toList(),
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
                                  vertical: 8,
                                ),
                                child: Text(
                                  'Clear Filters',
                                  style: context.cTextStyle.copyWith(
                                    color: context.colorScheme.onSurface,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const Divider(height: 20),

                      Column(
                        children: [
                          CheckboxListTile(
                            title: Text(
                              'Assignments',
                              style: context.eTextStyle.copyWith(
                                color: context.colorScheme.onSurface,
                              ),
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
                                    color: userSettings.eventsColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Events',
                                  style: context.eTextStyle.copyWith(
                                    color: context.colorScheme.onSurface,
                                  ),
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
                                  style: context.eTextStyle.copyWith(
                                    color: context.colorScheme.onSurface,
                                  ),
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
                                if (!currentTypes.contains('Class Schedules')) {
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
                              style: context.eTextStyle.copyWith(
                                color: context.colorScheme.onSurface,
                              ),
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

                      StatefulBuilder(
                        builder: (context, setStatusMenuState) {
                          Widget buildStatusTile(String label) {
                            final isChecked = _calendarItemDataSource!
                                .filterStatuses
                                .contains(label);
                            return CheckboxListTile(
                              title: Text(
                                label,
                                style: context.eTextStyle.copyWith(
                                  color: context.colorScheme.onSurface,
                                ),
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
                              buildStatusTile('Complete'),
                              buildStatusTile('Incomplete'),
                              buildStatusTile('Overdue'),
                            ],
                          );
                        },
                      ),
                      if (_deduplicatedCategories.isNotEmpty) ...[
                        const Divider(height: 20),

                        StatefulBuilder(
                          builder: (context, setCategoryMenuState) {
                            return Column(
                              children: _deduplicatedCategories.map((category) {
                                return CheckboxListTile(
                                  title: Row(
                                    children: [
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          category.title,
                                          style: context.eTextStyle.copyWith(
                                            color:
                                                context.colorScheme.onSurface,
                                          ),
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
                                style: context.cTextStyle.copyWith(
                                  color: context.colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                  fontSize: Responsive.getFontSize(
                                    context,
                                    mobile: 13,
                                    tablet: 14,
                                    desktop: 15,
                                  ),
                                ),
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
    if (_calendarItemDataSource == null) {
      return const LoadingIndicator();
    }

    return TodosTable(
      key: todosTableKey,
      dataSource: _calendarItemDataSource!,
      onTap: _openCalendarItem,
      onToggleCompleted: _toggleHomeworkCompleted,
    );
  }
}
