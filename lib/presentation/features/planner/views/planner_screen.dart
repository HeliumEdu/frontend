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
import 'package:heliumapp/config/app_route.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/data/models/auth/user_model.dart';
import 'package:heliumapp/data/models/id_or_entity.dart';
import 'package:heliumapp/data/models/planner/attachment_model.dart';
import 'package:heliumapp/data/models/planner/category_model.dart';
import 'package:heliumapp/data/models/planner/course_group_model.dart';
import 'package:heliumapp/data/models/planner/course_model.dart';
import 'package:heliumapp/data/models/planner/course_schedule_event_model.dart';
import 'package:heliumapp/data/models/planner/event_model.dart';
import 'package:heliumapp/data/models/planner/external_calendar_event_model.dart';
import 'package:heliumapp/data/models/planner/external_calendar_model.dart';
import 'package:heliumapp/data/models/planner/homework_model.dart';
import 'package:heliumapp/data/models/planner/planner_item_base_model.dart';
import 'package:heliumapp/data/models/planner/request/event_request_model.dart';
import 'package:heliumapp/data/models/planner/request/homework_request_model.dart';
import 'package:heliumapp/data/repositories/category_repository_impl.dart';
import 'package:heliumapp/data/repositories/course_repository_impl.dart';
import 'package:heliumapp/data/repositories/course_schedule_event_repository_impl.dart';
import 'package:heliumapp/data/repositories/event_repository_impl.dart';
import 'package:heliumapp/data/repositories/external_calendar_repository_impl.dart';
import 'package:heliumapp/data/repositories/homework_repository_impl.dart';
import 'package:heliumapp/data/sources/category_remote_data_source.dart';
import 'package:heliumapp/data/sources/course_remote_data_source.dart';
import 'package:heliumapp/data/sources/course_schedule_builder_source.dart';
import 'package:heliumapp/data/sources/course_schedule_remote_data_source.dart';
import 'package:heliumapp/data/sources/event_remote_data_source.dart';
import 'package:heliumapp/data/sources/external_calendar_remote_data_source.dart';
import 'package:heliumapp/data/sources/homework_remote_data_source.dart';
import 'package:heliumapp/data/sources/planner_item_data_source.dart';
import 'package:heliumapp/presentation/core/views/base_page_screen_state.dart';
import 'package:heliumapp/presentation/core/views/notification_screen.dart';
import 'package:heliumapp/presentation/features/auth/bloc/auth_bloc.dart';
import 'package:heliumapp/presentation/features/auth/bloc/auth_state.dart';
import 'package:heliumapp/presentation/features/courses/bloc/category_bloc.dart';
import 'package:heliumapp/presentation/features/planner/bloc/attachment_bloc.dart';
import 'package:heliumapp/presentation/features/planner/bloc/attachment_state.dart';
import 'package:heliumapp/presentation/features/planner/bloc/external_calendar_bloc.dart';
import 'package:heliumapp/presentation/features/planner/bloc/external_calendar_state.dart';
import 'package:heliumapp/presentation/features/planner/bloc/planner_bloc.dart';
import 'package:heliumapp/presentation/features/planner/bloc/planner_event.dart';
import 'package:heliumapp/presentation/features/planner/bloc/planner_state.dart';
import 'package:heliumapp/presentation/features/planner/bloc/planneritem_bloc.dart';
import 'package:heliumapp/presentation/features/planner/bloc/planneritem_event.dart';
import 'package:heliumapp/presentation/features/planner/bloc/planneritem_state.dart';
import 'package:heliumapp/presentation/features/planner/controllers/todos_table_controller.dart';
import 'package:heliumapp/presentation/features/planner/dialogs/confirm_delete_dialog.dart';
import 'package:heliumapp/presentation/features/planner/views/planner_item_add_screen.dart';
import 'package:heliumapp/presentation/features/planner/widgets/day_popout_dialog.dart';
import 'package:heliumapp/presentation/features/planner/widgets/todos_table.dart';
import 'package:heliumapp/presentation/features/settings/views/settings_screen.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/base_event.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/provider_helpers.dart';
import 'package:heliumapp/presentation/ui/components/helium_icon_button.dart';
import 'package:heliumapp/presentation/ui/feedback/error_card.dart';
import 'package:heliumapp/presentation/ui/feedback/loading_indicator.dart';
import 'package:heliumapp/presentation/ui/layout/shadow_container.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/date_time_helpers.dart';
import 'package:heliumapp/utils/grade_helpers.dart';
import 'package:heliumapp/utils/planner_helper.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:logging/logging.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:timezone/standalone.dart' as tz;
import 'package:url_launcher/url_launcher.dart';

final _log = Logger('presentation.views');

class PlannerScreen extends StatelessWidget {
  final DioClient _dioClient = DioClient();
  final ProviderHelpers _providerHelpers = ProviderHelpers();

  PlannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: _providerHelpers.createAttachmentBloc()),
        BlocProvider(
          create: (context) => PlannerBloc(
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
      child: const _CalendarProvidedScreen(),
    );
  }
}

class _CalendarProvidedScreen extends StatefulWidget {
  const _CalendarProvidedScreen();

  @override
  State<_CalendarProvidedScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState
    extends BasePageScreenState<_CalendarProvidedScreen> {
  static const _agendaHeightMobile = 53.0;
  static const _agendaHeightDesktop = 57.0;
  static const _uiAnimationDuration = Duration(milliseconds: 300);
  static const _tooltipWaitDuration = Duration(milliseconds: 500);
  static const _tooltipShowDuration = Duration(seconds: 8);

  @override
  String get screenTitle => 'Planner';

  @override
  List<BlocProvider>? get inheritableProviders => [
    BlocProvider<AttachmentBloc>.value(value: context.read<AttachmentBloc>()),
  ];

  @override
  VoidCallback get actionButtonCallback => () {
    // For Todos and Schedule views, use today as initial date since we don't
    // have a confident selection. For calendar views, use the selected date.
    final now = DateTime.now();
    final truncatedNow = DateTime(now.year, now.month, now.day, now.hour);
    final initialDate =
        (_currentView == PlannerView.todos ||
            _currentView == PlannerView.agenda)
        ? truncatedNow
        : _calendarController.selectedDate;

    final attachmentBloc = context.read<AttachmentBloc>();

    showPlannerItemAdd(
      context,
      initialDate: initialDate,
      isFromMonthView: _calendarController.view == CalendarView.month,
      isEdit: false,
      isNew: true,
      attachmentBloc: attachmentBloc,
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
  PlannerView _currentView = PlannerHelper.mapApiViewToHeliumView(
    FallbackConstants.defaultViewIndex,
  );
  PlannerView? _previousView;

  // Remember state when user switches to Todos view
  DateTime? _storedSelectedDate;
  DateTime? _storedDisplayDate;

  // Remember selectedDate on mobile (allows restoring null selection when
  // leaving month view on mobile)
  DateTime? _selectedDateBeforeMobileMonth;
  bool _mobileMonthAutoSelectApplied = false;

  List<DateTime> _visibleDates = [];
  bool _allowCalendarDragAndDrop = true;
  bool _isCalendarInteractionInProgress = false;

  PlannerItemDataSource? _plannerItemDataSource;
  final Map<int, ExternalCalendarModel> _externalCalendarsById = {};

  @override
  void initState() {
    super.initState();

    _calendarController = CalendarController()
      ..view = PlannerHelper.mapHeliumViewToSfCalendarView(_currentView);
    _todosController = TodosTableController();

    context.read<PlannerBloc>().add(FetchPlannerScreenDataEvent());

    _calendarController.addPropertyChangedListener((value) {
      if (value == 'calendarView') {
        _calendarViewChanged();
      } else if (value == 'displayDate' && _currentView == PlannerView.agenda) {
        _log.fine('Display date change: $value');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;

          setState(() {});
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
    _plannerItemDataSource?.dispose();
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

          _plannerItemDataSource = PlannerItemDataSource(
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
              builderSource: CourseScheduleBuilderSource(),
            ),
            externalCalendarRepository: ExternalCalendarRepositoryImpl(
              remoteDataSource: ExternalCalendarRemoteDataSourceImpl(
                dioClient: dioClient,
              ),
            ),
            userSettings: settings,
          );
          _plannerItemDataSource!.restoreFiltersIfEnabled();
          _todosController.itemsPerPage =
              _plannerItemDataSource!.todosItemsPerPage;
        });

        unawaited(_refreshExternalCalendarsMap());
      }

      return settings;
    });
  }

  @override
  List<BlocListener<dynamic, dynamic>> buildListeners(BuildContext context) {
    return [
      BlocListener<PlannerBloc, PlannerState>(
        listener: (context, state) {
          if (state is PlannerScreenDataFetched) {
            _populateInitialCalendarStateData(state);

            // Check if we should open a dialog based on query parameters
            final openDialog = GoRouterState.of(
              context,
            ).uri.queryParameters['dialog'];
            if (openDialog != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;

                // Clear the query parameter from URL
                context.go(
                  GoRouterState.of(
                    context,
                  ).uri.replace(queryParameters: {}).toString(),
                );

                // Open the appropriate dialog
                if (openDialog == 'notifications') {
                  showNotifications(context);
                } else if (openDialog == 'settings') {
                  showSettings(context);
                }
              });
            }
          }
        },
      ),
      BlocListener<PlannerItemBloc, PlannerItemState>(
        listener: (context, state) {
          if (_plannerItemDataSource == null) return;

          if (state is EventCreated) {
            _plannerItemDataSource!.addPlannerItem(state.event);
          } else if (state is EventUpdated) {
            // No snackbar on updates
            _plannerItemDataSource!.updatePlannerItem(state.event);
          } else if (state is EventDeleted) {
            showSnackBar(context, 'Event deleted');
            _plannerItemDataSource!.removePlannerItem(state.id);
          } else if (state is AllEventsDeleted) {
            _log.info('All Events deleted, refreshing calendar sources');

            final visibleStart = _visibleDates.isNotEmpty
                ? _visibleDates.first
                : null;
            final visibleEnd = _visibleDates.isNotEmpty
                ? _visibleDates.last
                : null;

            _plannerItemDataSource!.refreshCalendarSources(
              visibleStart: visibleStart,
              visibleEnd: visibleEnd,
            );
            unawaited(_refreshExternalCalendarsMap());
          } else if (state is HomeworkCreated) {
            _plannerItemDataSource!.addPlannerItem(state.homework);
          } else if (state is HomeworkUpdated) {
            // No snackbar on updates
            _plannerItemDataSource!.updatePlannerItem(state.homework);
          } else if (state is HomeworkDeleted) {
            showSnackBar(context, 'Assignment deleted');
            _plannerItemDataSource!.removePlannerItem(state.id);
          }
        },
      ),
      BlocListener<ExternalCalendarBloc, ExternalCalendarState>(
        listener: (context, state) {
          if (_plannerItemDataSource == null) return;

          if (state is ExternalCalendarCreated ||
              state is ExternalCalendarUpdated ||
              state is ExternalCalendarDeleted) {
            _log.info('External calendar changed, refreshing calendar sources');

            final visibleStart = _visibleDates.isNotEmpty
                ? _visibleDates.first
                : null;
            final visibleEnd = _visibleDates.isNotEmpty
                ? _visibleDates.last
                : null;

            _plannerItemDataSource!.refreshCalendarSources(
              visibleStart: visibleStart,
              visibleEnd: visibleEnd,
            );
            unawaited(_refreshExternalCalendarsMap());
          }
        },
      ),
      BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthProfileUpdated) {
            _log.info('User settings changed, repainting calendar');

            _plannerItemDataSource?.userSettings = state.user.settings;

            setState(() {
              userSettings = state.user.settings;
            });
          }
        },
      ),
      BlocListener<AttachmentBloc, AttachmentState>(
        listener: (context, state) {
          if (_plannerItemDataSource == null) return;

          if (state is AttachmentsCreated) {
            final attachment = state.attachments.firstOrNull;
            if (attachment == null) return;

            final isHomework = attachment.homework != null;
            final itemId = isHomework
                ? attachment.homework!
                : attachment.event!;

            _updatePlannerItemAttachments(
              itemId,
              state.attachments,
              isAdd: true,
              isHomework: isHomework,
            );
          } else if (state is AttachmentDeleted) {
            final isHomework = state.homeworkId != null;
            final itemId = isHomework ? state.homeworkId! : state.eventId!;

            _updatePlannerItemAttachments(
              itemId,
              state.id,
              isAdd: false,
              isHomework: isHomework,
            );
          }
        },
      ),
    ];
  }

  @override
  Widget buildMainArea(BuildContext context) {
    return BlocBuilder<PlannerBloc, PlannerState>(
      builder: (context, state) {
        if (state is PlannerLoading) {
          return const LoadingIndicator();
        }

        if (state is PlannerError) {
          return ErrorCard(
            message: state.message!,
            onReload: () {
              FetchPlannerScreenDataEvent();
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
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: context.colorScheme.outlineVariant.withValues(
                    alpha: 0.5,
                  ),
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: ListenableBuilder(
                  listenable: _plannerItemDataSource!.changeNotifier,
                  builder: (context, _) {
                    return Stack(
                      children: [
                        _currentView == PlannerView.todos
                            ? _buildTodosView()
                            : _buildCalendarView(context),
                        if (_plannerItemDataSource!.isRefreshing)
                          Positioned.fill(
                            child: Container(
                              color: context.colorScheme.surface.withValues(
                                alpha: 0.7,
                              ),
                              child: const Center(
                                child: LoadingIndicator(expanded: false),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarView(BuildContext context) {
    // For month view, wrap to make it scrollable if the view height is too small
    if (_calendarController.view == CalendarView.month) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final double calendarHeight = _calculateCalendarHeight(
            constraints.maxHeight,
          );

          return SingleChildScrollView(
            controller: _monthViewScrollController,
            child: SizedBox(height: calendarHeight, child: _buildCalendar()),
          );
        },
      );
    } else {
      return _buildCalendar();
    }
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
    final double minCalendarHeight = Responsive.isMobile(context) ? 480 : 600;
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
          allowDragAndDrop:
              _allowCalendarDragAndDrop &&
              (!Responsive.isTouchDevice(context) ||
                  (userSettings?.dragAndDropOnMobile ?? true)),
          dragAndDropSettings: DragAndDropSettings(
            timeIndicatorStyle: AppStyles.smallSecondaryText(
              context,
            ).copyWith(color: context.colorScheme.primary),
          ),
          allowAppointmentResize: true,
          allowedViews: _allowedViews,
          dataSource: _plannerItemDataSource,
          timeZone: userSettings!.timeZone.name,
          firstDayOfWeek:
              PlannerHelper.weekStartsOnRemap[userSettings!.weekStartsOn],
          todayTextStyle: AppStyles.standardBodyText(
            context,
          ).copyWith(color: context.colorScheme.onPrimary),
          viewHeaderHeight: _currentView == PlannerView.month ? 28 : -1,
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
            timeIntervalHeight: Responsive.isMobile(context) ? 43 : 60,
          ),
          loadMoreWidgetBuilder: _loadMoreWidgetBuilder,
          appointmentBuilder: _buildCalendarItem,
          onTap: _openCalendarItem,
          onDragStart: _onCalendarDragStart,
          onDragEnd: _dropCalendarItem,
          onAppointmentResizeEnd: _resizeCalendarItem,
          onSelectionChanged: _onCalendarSelectionChanged,
          onViewChanged: (ViewChangedDetails details) {
            _visibleDates = details.visibleDates;
            if (!mounted) return;

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;

              // Ensure the date header is updated
              setState(() {});
            });
          },
        );
      },
    );
  }

  bool _openPlannerItem(PlannerItemBaseModel plannerItem) {
    if (plannerItem is CourseScheduleEventModel) {
      _showEditClassScheduleEventSnackBar(plannerItem.ownerId);
      return false;
    } else if (plannerItem is ExternalCalendarEventModel) {
      _showEditExternalCalendarEventSnackBar();
      return false;
    }

    final int? eventId = plannerItem is EventModel ? plannerItem.id : null;
    final int? homeworkId = plannerItem is HomeworkModel
        ? plannerItem.id
        : null;

    final attachmentBloc = context.read<AttachmentBloc>();

    showPlannerItemAdd(
      context,
      eventId: eventId,
      homeworkId: homeworkId,
      isEdit: true,
      isNew: false,
      attachmentBloc: attachmentBloc,
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
    if (_currentView == PlannerView.todos) {
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

    final showNavButtons = _currentView != PlannerView.agenda;

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
        duration: _uiAnimationDuration,
        width: expandedToolbarWidth,
        child: Stack(
          alignment: Alignment.centerRight,
          children: [
            AnimatedOpacity(
              duration: _uiAnimationDuration,
              opacity: _isSearchExpanded ? 0.0 : 1.0,
              child: IgnorePointer(
                ignoring: _isSearchExpanded,
                child: _buildFilterAndSearchButtons(),
              ),
            ),
            AnimatedPositioned(
              duration: _uiAnimationDuration,
              curve: Curves.easeInOut,
              right: 0,
              width: _isSearchExpanded ? expandedToolbarWidth : 46,
              child: AnimatedOpacity(
                duration: _uiAnimationDuration,
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
        duration: _uiAnimationDuration,
        width: isExpanded ? expandedToolbarWidth : 46,
        child: Stack(
          alignment: Alignment.centerRight,
          children: [
            AnimatedOpacity(
              duration: _uiAnimationDuration,
              opacity: (_isFilterExpanded || _isSearchExpanded) ? 0.0 : 1.0,
              child: IgnorePointer(
                ignoring: _isFilterExpanded || _isSearchExpanded,
                child: _buildCollapsedFilterButton(),
              ),
            ),
            AnimatedPositioned(
              duration: _uiAnimationDuration,
              curve: Curves.easeInOut,
              right: 0,
              width: _isFilterExpanded ? expandedToolbarWidth : 46,
              child: AnimatedOpacity(
                duration: _uiAnimationDuration,
                opacity: _isFilterExpanded ? 1.0 : 0.0,
                child: IgnorePointer(
                  ignoring: !_isFilterExpanded,
                  child: _buildExpandedFilterButtons(),
                ),
              ),
            ),
            AnimatedPositioned(
              duration: _uiAnimationDuration,
              curve: Curves.easeInOut,
              right: 0,
              width: _isSearchExpanded ? expandedToolbarWidth : 46,
              child: AnimatedOpacity(
                duration: _uiAnimationDuration,
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
                            style: AppStyles.formText(context),
                            decoration: InputDecoration(
                              hintText: 'Search ...',
                              hintStyle: AppStyles.formLabel(context).copyWith(
                                color: context.colorScheme.onSurface.withValues(
                                  alpha: 0.3,
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
                        tooltip: 'Close',
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
        if (_plannerItemDataSource == null) {
          return _buildFilterButtonsRow();
        }

        return ListenableBuilder(
          listenable: _plannerItemDataSource!.changeNotifier,
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
            final hasFilters = _hasCoursesFilter() || _hasStatusFilters();
            return IconButton.outlined(
              onPressed: _courses.isEmpty
                  ? null
                  : () => _openFilterSheet(context),
              tooltip: 'Filters',
              icon: const Icon(Icons.filter_alt),
              style: IconButton.styleFrom(
                backgroundColor: hasFilters
                    ? context.colorScheme.primary
                    : null,
                foregroundColor: hasFilters
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
    if (_plannerItemDataSource == null) return false;

    final filteredCourses = _plannerItemDataSource!.filteredCourses;

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

    final filteredCourseIds = _plannerItemDataSource!.filteredCourses.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toSet();

    final filteredCategories = _categoriesMap.values.where(
      (cat) => filteredCourseIds.contains(cat.course),
    );

    return _deduplicateCategoriesByTitle(filteredCategories);
  }

  bool _hasStatusFilters() {
    if (_plannerItemDataSource == null) return false;

    final categories = _plannerItemDataSource!.filterCategories;
    final types = _plannerItemDataSource!.filterTypes;
    final statuses = _plannerItemDataSource!.filterStatuses;

    if (types.isNotEmpty) return true;

    if (categories.isNotEmpty) return true;

    if (statuses.isNotEmpty) return true;

    return false;
  }

  bool _hasSearchQuery() {
    if (_plannerItemDataSource == null) return false;

    final searchQuery = _plannerItemDataSource!.searchQuery;
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

  void _changeView(PlannerView newView) {
    _log.info('View changed: $_currentView --> $newView');
    final isEnteringNonCalendarView = (newView == PlannerView.todos);
    final wasInNonCalendarView =
        _previousView != null && _previousView == PlannerView.todos;
    final isEnteringCalendarView =
        (newView == PlannerView.month ||
        newView == PlannerView.week ||
        newView == PlannerView.day);
    final isLeavingMonthView = _currentView == PlannerView.month;

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
    if (newView != PlannerView.todos) {
      _calendarController.view = PlannerHelper.mapHeliumViewToSfCalendarView(
        newView,
      );
    }

    // On mobile, select a date on month view so the agenda is always shown
    if (Responsive.isMobile(context) &&
        newView == PlannerView.month &&
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
    if (_currentView == PlannerView.month) {
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
    LoadMoreCallback loadMorePlannerItems,
  ) {
    return FutureBuilder<void>(
      future: loadMorePlannerItems(),
      builder: (context, snapShot) {
        return const Center(child: LoadingIndicator(expanded: false));
      },
    );
  }

  void _onSearchTextFieldChanged(String value) {
    if (_searchTypingTimer?.isActive ?? false) {
      _searchTypingTimer!.cancel();
    }

    _searchTypingTimer = Timer(const Duration(milliseconds: 500), () {
      _plannerItemDataSource!.setSearchQuery(value);
    });
  }

  void _openCalendarItem(CalendarTapDetails tapDetails) {
    if (tapDetails.appointments == null ||
        tapDetails.appointments!.isEmpty ||
        tapDetails.targetElement != CalendarElement.appointment) {
      return;
    }

    final PlannerItemBaseModel plannerItem =
        tapDetails.appointments![0] as PlannerItemBaseModel;

    if (_currentView == PlannerView.agenda &&
        PlannerHelper.shouldShowEditButton(context)) {
      return;
    }

    Feedback.forTap(context);

    _openPlannerItem(plannerItem);
  }

  void _dropCalendarItem(AppointmentDragEndDetails dropDetails) {
    _setCalendarInteractionInProgress(false);

    if (dropDetails.appointment == null || dropDetails.droppingTime == null) {
      return;
    }

    final PlannerItemBaseModel plannerItem =
        dropDetails.appointment as PlannerItemBaseModel;

    if (plannerItem is HomeworkModel || plannerItem is EventModel) {
      final startDateTime = tz.TZDateTime.from(
        plannerItem.start,
        userSettings!.timeZone,
      );
      final Duration duration = tz.TZDateTime.from(
        plannerItem.end,
        userSettings!.timeZone,
      ).difference(startDateTime);

      final roundedMinute = PlannerHelper.roundMinute(
        dropDetails.droppingTime!.minute,
      );

      final DateTime start = tz.TZDateTime(
        userSettings!.timeZone,
        dropDetails.droppingTime!.year,
        dropDetails.droppingTime!.month,
        dropDetails.droppingTime!.day,
        _currentView == PlannerView.month
            ? startDateTime.hour
            : dropDetails.droppingTime!.hour,
        _currentView == PlannerView.month
            ? startDateTime.minute
            : roundedMinute,
      );
      final DateTime end = start.add(duration);

      // Set optimistic override immediately for instant visual feedback
      _plannerItemDataSource!.setTimeOverride(
        plannerItem.id,
        start.toIso8601String(),
        end.toIso8601String(),
      );

      if (plannerItem is HomeworkModel) {
        final request = HomeworkRequestModel(
          start: start.toIso8601String(),
          end: end.toIso8601String(),
          course: plannerItem.course.id,
        );

        context.read<PlannerItemBloc>().add(
          UpdateHomeworkEvent(
            origin: EventOrigin.screen,
            courseGroupId: _courses
                .firstWhere((c) => c.id == plannerItem.course.id)
                .courseGroup,
            courseId: plannerItem.course.id,
            homeworkId: plannerItem.id,
            request: request,
          ),
        );
      } else {
        final request = EventRequestModel(
          start: start.toIso8601String(),
          end: end.toIso8601String(),
        );

        context.read<PlannerItemBloc>().add(
          UpdateEventEvent(
            origin: EventOrigin.screen,
            id: plannerItem.id,
            request: request,
          ),
        );
      }
    } else if (plannerItem is CourseScheduleEventModel) {
      _showEditClassScheduleEventSnackBar(plannerItem.ownerId);
    } else if (plannerItem is ExternalCalendarEventModel) {
      _showEditExternalCalendarEventSnackBar();
    }
  }

  void _onCalendarDragStart(AppointmentDragStartDetails dragDetails) {
    _setCalendarInteractionInProgress(true);
  }

  void _resizeCalendarItem(AppointmentResizeEndDetails resizeDetails) {
    if (resizeDetails.appointment == null ||
        resizeDetails.startTime == null ||
        resizeDetails.endTime == null) {
      return;
    }

    final PlannerItemBaseModel plannerItem =
        resizeDetails.appointment as PlannerItemBaseModel;

    if (plannerItem is HomeworkModel || plannerItem is EventModel) {
      final DateTime start = tz.TZDateTime(
        userSettings!.timeZone,
        resizeDetails.startTime!.year,
        resizeDetails.startTime!.month,
        resizeDetails.startTime!.day,
        resizeDetails.startTime!.hour,
        PlannerHelper.roundMinute(resizeDetails.startTime!.minute),
      );

      DateTime end = tz.TZDateTime(
        userSettings!.timeZone,
        resizeDetails.endTime!.year,
        resizeDetails.endTime!.month,
        resizeDetails.endTime!.day,
        resizeDetails.endTime!.hour,
        PlannerHelper.roundMinute(resizeDetails.endTime!.minute),
      );
      if (plannerItem.allDay) {
        end = end.add(const Duration(days: 1));
      }

      // Set optimistic override immediately for instant visual feedback
      _plannerItemDataSource!.setTimeOverride(
        plannerItem.id,
        start.toIso8601String(),
        end.toIso8601String(),
      );

      if (plannerItem is HomeworkModel) {
        final request = HomeworkRequestModel(
          start: start.toIso8601String(),
          end: end.toIso8601String(),
          showEndTime: true,
          course: plannerItem.course.id,
        );

        context.read<PlannerItemBloc>().add(
          UpdateHomeworkEvent(
            origin: EventOrigin.screen,
            courseGroupId: _courses
                .firstWhere((c) => c.id == plannerItem.course.id)
                .courseGroup,
            courseId: plannerItem.course.id,
            homeworkId: plannerItem.id,
            request: request,
          ),
        );
      } else {
        final request = EventRequestModel(
          start: start.toIso8601String(),
          end: end.toIso8601String(),
          showEndTime: true,
        );

        context.read<PlannerItemBloc>().add(
          UpdateEventEvent(
            origin: EventOrigin.screen,
            id: plannerItem.id,
            request: request,
          ),
        );
      }
    } else if (plannerItem is CourseScheduleEventModel) {
      _showEditClassScheduleEventSnackBar(plannerItem.ownerId);
    } else if (plannerItem is ExternalCalendarEventModel) {
      _showEditExternalCalendarEventSnackBar();
    }
  }

  void _deletePlannerItem(
    BuildContext context,
    PlannerItemBaseModel plannerItem,
  ) {
    final CourseModel? course;
    if (plannerItem is HomeworkModel) {
      course = _courses.firstWhere((c) => c.id == plannerItem.course.id);
    } else {
      course = null;
    }

    final Function(PlannerItemBaseModel) onDelete;
    if (plannerItem is HomeworkModel) {
      onDelete = (h) {
        context.read<PlannerItemBloc>().add(
          DeleteHomeworkEvent(
            origin: EventOrigin.screen,
            courseGroupId: course!.courseGroup,
            courseId: course.id,
            homeworkId: h.id,
          ),
        );
      };
    } else if (plannerItem is EventModel) {
      onDelete = (e) {
        context.read<PlannerItemBloc>().add(
          DeleteEventEvent(origin: EventOrigin.screen, id: e.id),
        );
      };
    } else {
      return;
    }

    showConfirmDeleteDialog(
      parentContext: context,
      item: plannerItem,
      additionalWarning: 'Attachments will also be deleted.',
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

    final plannerItem = details.appointments.first as PlannerItemBaseModel;
    final isInAgenda =
        _currentView == PlannerView.agenda ||
        (_currentView == PlannerView.month &&
            (details.bounds.height > 40 ||
                (Responsive.isMobile(context) && plannerItem.allDay)));
    final homeworkId = plannerItem is HomeworkModel ? plannerItem.id : null;

    // Use KeyedSubtree to help preserve widget state across rebuilds, prevents
    // flickers for drag-and-drop and similar operations
    Widget calendarItemWidget = _buildCalendarItemWidget(
      plannerItem: plannerItem,
      width: details.bounds.width,
      height: details.bounds.height,
      isInAgenda: isInAgenda,
      completedOverride: homeworkId != null
          ? _plannerItemDataSource!.completedOverrides[homeworkId]
          : null,
    );
    if (_isLockedCalendarInteractionItem(plannerItem)) {
      calendarItemWidget = Listener(
        onPointerDown: (_) => _temporarilyDisableCalendarDragAndDrop(),
        child: calendarItemWidget,
      );
    }

    // In month view on touch devices like iPad, SfCalendar incorrectly reports
    // calendarCell instead of appointment for taps on calendar items.
    // Handle taps directly on the widget to bypass this SfCalendar quirk.
    if (_currentView == PlannerView.month &&
        Responsive.isTouchDevice(context)) {
      calendarItemWidget = GestureDetector(
        onTap: () {
          _openPlannerItem(plannerItem);
        },
        child: calendarItemWidget,
      );
    }

    return KeyedSubtree(
      key: ValueKey('planner_item_${plannerItem.id}'),
      child: _buildPlannerItemTooltip(
        plannerItem: plannerItem,
        child: calendarItemWidget,
      ),
    );
  }

  bool _isLockedCalendarInteractionItem(PlannerItemBaseModel item) {
    return item is CourseScheduleEventModel ||
        item is ExternalCalendarEventModel;
  }

  void _setCalendarInteractionInProgress(bool isInProgress) {
    if (!mounted || _isCalendarInteractionInProgress == isInProgress) {
      return;
    }

    if (isInProgress) {
      Tooltip.dismissAllToolTips();
    }

    setState(() {
      _isCalendarInteractionInProgress = isInProgress;
    });
  }

  void _temporarilyDisableCalendarDragAndDrop() {
    if (!_allowCalendarDragAndDrop || !mounted) {
      return;
    }
    setState(() {
      _allowCalendarDragAndDrop = false;
      _isCalendarInteractionInProgress = true;
    });
    Tooltip.dismissAllToolTips();
    Future.delayed(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      setState(() {
        _allowCalendarDragAndDrop = true;
        _isCalendarInteractionInProgress = false;
      });
    });
  }

  Widget _buildPlannerItemTooltip({
    required PlannerItemBaseModel plannerItem,
    required Widget child,
    bool hideLocation = false,
  }) {
    if (_isCalendarInteractionInProgress ||
        Responsive.isTouchDevice(context) ||
        !(userSettings?.showPlannerTooltips ?? true)) {
      return child;
    }

    final tooltipMessage = _buildPlannerItemTooltipMessage(
      plannerItem,
      hideLocation: hideLocation,
    );
    if (tooltipMessage == null) {
      return child;
    }

    return Tooltip(
      richMessage: tooltipMessage,
      waitDuration: _tooltipWaitDuration,
      showDuration: _tooltipShowDuration,
      preferBelow: false,
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: child,
    );
  }

  InlineSpan? _buildPlannerItemTooltipMessage(
    PlannerItemBaseModel plannerItem, {
    bool hideLocation = false,
  }) {
    final titleStyle = AppStyles.formText(context).copyWith(
      color: context.colorScheme.onSurface,
      fontWeight: FontWeight.w600,
    );
    final bodyStyle = AppStyles.formText(
      context,
    ).copyWith(color: context.colorScheme.onSurface);
    final mutedIconColor = context.colorScheme.onSurface.withValues(
      alpha: 0.75,
    );
    final rows = <_PlannerTooltipRow>[
      _PlannerTooltipRow.text(
        icon: _isRecurringPlannerItem(plannerItem)
            ? Icons.repeat
            : Icons.access_time,
        text: _buildTooltipWhenLine(plannerItem),
      ),
    ];
    final location = _plannerItemDataSource?.getLocationForItem(plannerItem);

    if (!hideLocation &&
        _currentView != PlannerView.agenda &&
        location != null &&
        location.isNotEmpty) {
      rows.add(
        _PlannerTooltipRow.text(icon: Icons.pin_drop_outlined, text: location),
      );
    }

    if (plannerItem is HomeworkModel) {
      final course = _courses.firstWhereOrNull(
        (c) => c.id == plannerItem.course.id,
      );
      final categoryTitle =
          plannerItem.category.entity?.title ??
          _categoriesMap[plannerItem.category.id]?.title;

      if (course != null) {
        rows.add(
          _PlannerTooltipRow.text(
            icon: Icons.school_outlined,
            text: course.title,
            color: course.color,
          ),
        );
      }
      if (categoryTitle != null && categoryTitle.isNotEmpty) {
        rows.add(
          _PlannerTooltipRow.text(
            icon: Icons.category_outlined,
            text: categoryTitle,
            color: _categoriesMap[plannerItem.category.id]?.color,
          ),
        );
      }
      if (GradeHelper.parseGrade(plannerItem.currentGrade) != null) {
        rows.add(
          _PlannerTooltipRow.text(
            icon: Icons.assignment_turned_in_outlined,
            text: GradeHelper.gradeForDisplay(plannerItem.currentGrade),
            color: context.colorScheme.primary,
          ),
        );
      }
    } else if (plannerItem is EventModel) {
      rows.add(
        _PlannerTooltipRow.text(
          icon: Icons.source_outlined,
          text: 'Source: Events',
          color: userSettings?.eventsColor,
        ),
      );
    } else if (plannerItem is ExternalCalendarEventModel) {
      final calendarId = int.tryParse(plannerItem.ownerId);
      final externalCalendar = calendarId != null
          ? _externalCalendarsById[calendarId]
          : null;
      rows.add(
        _PlannerTooltipRow.text(
          icon: Icons.source_outlined,
          text: 'Source: ${externalCalendar?.title ?? 'External Calendar'}',
          color: externalCalendar?.color ?? plannerItem.color,
        ),
      );
    }

    final hasResources =
        plannerItem is HomeworkModel && plannerItem.resources.isNotEmpty;
    final hasAttachments = plannerItem.attachments.isNotEmpty;
    final hasReminders = plannerItem.reminders.isNotEmpty;
    if (hasResources || hasAttachments || hasReminders) {
      rows.add(
        _PlannerTooltipRow.widget(
          widget: Container(
            width: 50,
            height: 1,
            color: context.colorScheme.outlineVariant.withValues(alpha: 0.7),
          ),
        ),
      );
      rows.add(
        _PlannerTooltipRow.widget(
          widget: _buildTooltipMetaCountsRow(plannerItem),
        ),
      );
    }

    if (rows.isEmpty) {
      return null;
    }

    final typeIcon = plannerItem is HomeworkModel
        ? AppConstants.assignmentIcon
        : plannerItem is EventModel
        ? AppConstants.eventIcon
        : plannerItem is CourseScheduleEventModel
        ? AppConstants.courseScheduleIcon
        : AppConstants.externalCalendarIcon;
    final typeIconColor = plannerItem is CourseScheduleEventModel
        ? plannerItem.color
        : mutedIconColor;

    final children = <InlineSpan>[
      WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Icon(typeIcon, size: 14, color: typeIconColor),
      ),
      const TextSpan(text: ' '),
      TextSpan(text: plannerItem.title, style: titleStyle),
      const TextSpan(text: '\n'),
      WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Container(
          width: 50,
          height: 1,
          color: context.colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      const TextSpan(text: '\n'),
    ];

    for (int i = 0; i < rows.length; i++) {
      final row = rows[i];
      if (row.widget != null) {
        children.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: row.widget!,
          ),
        );
      } else {
        children.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Icon(
              row.icon!,
              size: 14,
              color: row.color ?? mutedIconColor,
            ),
          ),
        );
        children.add(TextSpan(text: ' ${row.text}', style: bodyStyle));
      }
      if (i != rows.length - 1) {
        children.add(const TextSpan(text: '\n'));
      }
    }

    return TextSpan(children: children);
  }

  String _buildTooltipWhenLine(PlannerItemBaseModel plannerItem) {
    final localStart = HeliumDateTime.toLocal(
      plannerItem.start,
      userSettings!.timeZone,
    );
    final localEnd = HeliumDateTime.toLocal(
      plannerItem.end,
      userSettings!.timeZone,
    );
    final formattedDate = HeliumDateTime.formatDate(localStart);

    if (plannerItem.allDay) {
      return '$formattedDate • All day';
    }

    return '$formattedDate • ${HeliumDateTime.formatTimeRange(localStart, localEnd, plannerItem.showEndTime)}';
  }

  Widget _buildTooltipMetaCountsRow(PlannerItemBaseModel plannerItem) {
    final rowTextStyle = AppStyles.formText(
      context,
    ).copyWith(color: context.colorScheme.onSurface);
    final statWidgets = <Widget>[];

    void addStat({
      required IconData icon,
      required int count,
      required Color color,
    }) {
      statWidgets.addAll([
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text('$count', style: rowTextStyle.copyWith(color: color)),
      ]);
    }

    if (plannerItem is HomeworkModel && plannerItem.resources.isNotEmpty) {
      addStat(
        icon: Icons.book_outlined,
        count: plannerItem.resources.length,
        color: userSettings!.resourceColor.withValues(alpha: 0.9),
      );
    }
    if (plannerItem.attachments.isNotEmpty) {
      if (statWidgets.isNotEmpty) {
        statWidgets.add(const SizedBox(width: 12));
      }
      addStat(
        icon: Icons.attachment,
        count: plannerItem.attachments.length,
        color: context.semanticColors.success.withValues(alpha: 0.9),
      );
    }
    if (plannerItem.reminders.isNotEmpty) {
      if (statWidgets.isNotEmpty) {
        statWidgets.add(const SizedBox(width: 12));
      }
      addStat(
        icon: Icons.notifications_outlined,
        count: plannerItem.reminders.length,
        color: context.colorScheme.primary.withValues(alpha: 0.9),
      );
    }

    return Row(mainAxisSize: MainAxisSize.min, children: statWidgets);
  }

  Future<void> _refreshExternalCalendarsMap() async {
    if (_plannerItemDataSource == null) {
      return;
    }

    try {
      final externalCalendars = await _plannerItemDataSource!
          .externalCalendarRepository
          .getExternalCalendars();
      if (!mounted) {
        return;
      }
      setState(() {
        _externalCalendarsById
          ..clear()
          ..addEntries(externalCalendars.map((c) => MapEntry(c.id, c)));
      });
    } catch (e, s) {
      _log.warning(
        'Failed to load external calendar metadata for tooltips',
        e,
        s,
      );
    }
  }

  Widget _buildCalendarItemLeftForAgenda({
    required PlannerItemBaseModel plannerItem,
    bool? completedOverride,
  }) {
    Widget? iconWidget;

    final isCheckbox = PlannerHelper.shouldShowCheckbox(
      context,
      plannerItem,
      _currentView,
    );

    if (isCheckbox) {
      iconWidget = _buildCheckboxWidget(
        homework: plannerItem as HomeworkModel,
        completedOverride: completedOverride,
      );
    } else if (PlannerHelper.shouldShowSchoolIcon(
      context,
      plannerItem,
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
    if (Responsive.isTouchDevice(context) && isCheckbox) {
      final homework = plannerItem as HomeworkModel;
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
    required PlannerItemBaseModel plannerItem,
    bool? completedOverride,
  }) {
    if (PlannerHelper.shouldShowCheckbox(context, plannerItem, _currentView)) {
      return _buildCheckboxWidget(
        homework: plannerItem as HomeworkModel,
        completedOverride: completedOverride,
      );
    } else if (PlannerHelper.shouldShowSchoolIcon(
      context,
      plannerItem,
      _currentView,
    )) {
      return _buildSchoolIconWidget();
    }
    return null;
  }

  Widget _buildCalendarItemCenterForAgenda({
    required PlannerItemBaseModel plannerItem,
    String? location,
    bool? completedOverride,
  }) {
    final contentColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCalendarItemTitle(
          plannerItem,
          completedOverride: completedOverride,
        ),
        if (PlannerHelper.shouldShowTimeBelowTitle(
          context,
          plannerItem,
          true,
          _currentView,
        ))
          _buildCalendarItemTimeBelowTitleRow(plannerItem, isInAgenda: true),
        if (PlannerHelper.shouldShowLocationBelowTitle(
              context,
              plannerItem,
              true,
              _currentView,
            ) &&
            location != null &&
            location.isNotEmpty)
          _buildCalendarItemLocationRow(location),
      ],
    );

    return Expanded(
      child: Padding(
        padding: _recurringContentPadding(plannerItem),
        child: contentColumn,
      ),
    );
  }

  Widget _buildCalendarItemCenterForTimeline({
    required PlannerItemBaseModel plannerItem,
    String? location,
    Widget? inlineIcon,
    bool? completedOverride,
  }) {
    final showTimeBeforeTitle = PlannerHelper.shouldShowTimeBeforeTitle(
      context,
      plannerItem,
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
              child: _buildCalendarItemTime(plannerItem, isInAgenda: false),
            ),
          ),
        );
      }

      final isCompleted =
          completedOverride ??
          (plannerItem is HomeworkModel && plannerItem.completed);

      spans.add(
        TextSpan(
          text: plannerItem.title,
          style: AppStyles.smallSecondaryTextLight(context).copyWith(
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
        maxLines: _currentView == PlannerView.month || plannerItem.allDay
            ? 1
            : null,
        overflow: _currentView == PlannerView.month || plannerItem.allDay
            ? TextOverflow.ellipsis
            : null,
      );
    } else {
      titleRowWidget = _buildCalendarItemTitle(
        plannerItem,
        completedOverride: completedOverride,
      );
    }

    final contentColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        titleRowWidget,
        if (PlannerHelper.shouldShowTimeBelowTitle(
          context,
          plannerItem,
          false,
          _currentView,
        ))
          _buildCalendarItemTimeBelowTitleRow(plannerItem, isInAgenda: false),
        if (PlannerHelper.shouldShowLocationBelowTitle(
              context,
              plannerItem,
              false,
              _currentView,
            ) &&
            location != null &&
            location.isNotEmpty)
          _buildCalendarItemLocationRow(location),
      ],
    );

    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: _recurringContentPadding(plannerItem),
        child: contentColumn,
      ),
    );
  }

  Widget _buildCalendarItemRight({
    required PlannerItemBaseModel plannerItem,
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

    if (PlannerHelper.shouldShowEditButtonForPlannerItem(
      context,
      plannerItem,
    )) {
      buttons.add(
        HeliumIconButton(
          onPressed: () => _openPlannerItem(plannerItem),
          icon: Icons.edit_outlined,
          color: Colors.white,
        ),
      );
    }

    if (PlannerHelper.shouldShowDeleteButton(plannerItem)) {
      buttons.add(
        HeliumIconButton(
          onPressed: () => _deletePlannerItem(context, plannerItem),
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
    required PlannerItemBaseModel plannerItem,
    required double width,
    double? height,
    required bool isInAgenda,
    bool? completedOverride,
  }) {
    if (isInAgenda) {
      return _buildCalendarItemWidgetForAgenda(
        plannerItem: plannerItem,
        width: width,
        completedOverride: completedOverride,
      );
    } else {
      return _buildCalendarItemWidgetForTimeline(
        plannerItem: plannerItem,
        width: width,
        height: height,
        completedOverride: completedOverride,
      );
    }
  }

  Widget _buildCalendarItemWidgetForAgenda({
    required PlannerItemBaseModel plannerItem,
    required double width,
    bool? completedOverride,
  }) {
    final color = _plannerItemDataSource!.getColorForItem(plannerItem);
    final location = _plannerItemDataSource!.getLocationForItem(plannerItem);
    final course = _getCourseForPlannerItem(plannerItem);

    final leftWidget = _buildCalendarItemLeftForAgenda(
      plannerItem: plannerItem,
      completedOverride: completedOverride,
    );

    final centerWidget = _buildCalendarItemCenterForAgenda(
      plannerItem: plannerItem,
      location: location,
      completedOverride: completedOverride,
    );

    final rightWidget = _buildCalendarItemRight(
      plannerItem: plannerItem,
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
    required PlannerItemBaseModel plannerItem,
    required double width,
    double? height,
    bool? completedOverride,
  }) {
    final color = _plannerItemDataSource!.getColorForItem(plannerItem);
    final location = _plannerItemDataSource!.getLocationForItem(plannerItem);

    final inlineIcon = _getInlineIconWidget(
      plannerItem: plannerItem,
      completedOverride: completedOverride,
    );

    final centerWidget = _buildCalendarItemCenterForTimeline(
      plannerItem: plannerItem,
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
      child: _buildRecurringIndicatorOverlay(
        plannerItem: plannerItem,
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
      ),
    );
  }

  CourseModel? _getCourseForPlannerItem(PlannerItemBaseModel plannerItem) {
    if (plannerItem is HomeworkModel) {
      return _courses.firstWhere((c) => c.id == plannerItem.course.id);
    } else if (plannerItem is CourseScheduleEventModel) {
      return _courses.firstWhere((c) => c.id.toString() == plannerItem.ownerId);
    }
    return null;
  }

  void _showEditExternalCalendarEventSnackBar() {
    showSnackBar(
      context,
      "You can't edit External Calendars in Helium",
      seconds: 4,
      isError: true,
    );
  }

  void _showEditClassScheduleEventSnackBar(String courseId) {
    showSnackBar(
      context,
      'Edit the Class to change its Schedule',
      seconds: 4,
      action: SnackBarAction(
        label: 'Go',
        textColor: context.colorScheme.onPrimary,
        onPressed: () {
          context.go('${AppRoute.coursesScreen}?id=$courseId&step=1');
        },
      ),
      isError: true,
    );
  }

  Widget _buildMoreIndicator(
    BuildContext context,
    CalendarAppointmentDetails details,
  ) {
    return GestureDetector(
      onTap: () {
        _openDayPopOutDialog(details.date);
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

  void _openDayPopOutDialog(DateTime? date) {
    if (date == null || Responsive.isMobile(context)) return;

    showDialog(
      context: context,
      builder: (_) => PlannerDayPopOutDialog(
        date: date,
        dataSource: _plannerItemDataSource!,
        onPlannerItemTap: (context, plannerItem) {
          if (!PlannerHelper.shouldShowEditButtonForPlannerItem(
            context,
            plannerItem,
          )) {
            return false;
          }
          return _openPlannerItem(plannerItem);
        },
        itemBuilder: (context, plannerItem, completedOverride) {
          return _buildPlannerItemTooltip(
            plannerItem: plannerItem,
            hideLocation: true,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxHeight: _agendaHeightDesktop,
              ),
              child: _buildCalendarItemWidget(
                plannerItem: plannerItem,
                width: double.infinity,
                isInAgenda: true,
                completedOverride: completedOverride,
              ),
            ),
          );
        },
      ),
    );
  }

  void _populateInitialCalendarStateData(PlannerScreenDataFetched state) {
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

      if (_plannerItemDataSource != null) {
        _plannerItemDataSource!.courses = _courses;
        _plannerItemDataSource!.categoriesMap = _categoriesMap;
      }

      _deduplicatedCategories.addAll(
        _deduplicateCategoriesByTitle(state.categories),
      );

      isLoading = false;
    });
  }

  void _goToToday() {
    _log.info('Today button pressed (view: $_currentView)');
    if (_currentView == PlannerView.todos) {
      if (_plannerItemDataSource != null) {
        _todosController.goToToday(_plannerItemDataSource!.filteredHomeworks);
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
    });
  }

  void _onToggleCompleted(HomeworkModel homework, bool value) {
    Feedback.forTap(context);

    _log.info('Homework ${homework.id} completion toggled: $value');

    // Set optimistic override immediately for instant visual feedback
    _plannerItemDataSource!.setCompletedOverride(homework.id, value);

    final request = HomeworkRequestModel(
      completed: !homework.completed,
      course: homework.course.id,
    );

    final course = _courses.firstWhere((c) => c.id == homework.course.id);

    context.read<PlannerItemBloc>().add(
      UpdateHomeworkEvent(
        origin: EventOrigin.screen,
        courseGroupId: course.courseGroup,
        courseId: course.id,
        homeworkId: homework.id,
        request: request,
      ),
    );
  }

  void _updatePlannerItemAttachments(
    int itemId,
    dynamic attachmentData, {
    required bool isAdd,
    required bool isHomework,
  }) {
    final PlannerItemBaseModel? plannerItem = isHomework
        ? _plannerItemDataSource!.allHomeworks.firstWhereOrNull(
            (h) => h.id == itemId,
          )
        : _plannerItemDataSource!.allEvents.firstWhereOrNull(
            (e) => e.id == itemId,
          );

    if (plannerItem == null) return;

    final updatedAttachments = List<IdOrEntity<AttachmentModel>>.from(
      plannerItem.attachments,
    );

    if (isAdd) {
      final newAttachments = attachmentData as List<AttachmentModel>;
      for (final attachment in newAttachments) {
        updatedAttachments.add(
          IdOrEntity<AttachmentModel>(id: attachment.id, entity: attachment),
        );
      }
    } else {
      final attachmentId = attachmentData as int;
      updatedAttachments.removeWhere((a) => a.id == attachmentId);
    }

    final PlannerItemBaseModel updatedItem = isHomework
        ? (plannerItem as HomeworkModel).copyWith(
            attachments: updatedAttachments,
          )
        : (plannerItem as EventModel).copyWith(attachments: updatedAttachments);

    _plannerItemDataSource!.updatePlannerItem(updatedItem);
  }

  void _openFilterSheet(BuildContext context) {
    final List<CourseModel> displayCourses =
        PlannerHelper.sortByGroupStartThenByTitle(_courses, _courseGroups);

    final isMobile = Responsive.isMobile(context);

    Widget buildContent(BuildContext context, StateSetter setSheetState) {
      final statuses = _plannerItemDataSource!.filterStatuses;
      final isCompleteFilterEnabled =
          statuses.contains(PlannerFilterStatus.complete.value) ||
          statuses.contains(PlannerFilterStatus.incomplete.value);
      final showCompletedOnly = statuses.contains(
        PlannerFilterStatus.complete.value,
      );
      final isGradedFilterEnabled =
          statuses.contains(PlannerFilterStatus.graded.value) ||
          statuses.contains(PlannerFilterStatus.ungraded.value);
      final showGradedOnly = statuses.contains(
        PlannerFilterStatus.graded.value,
      );

      void setCompleteFilterMode({
        required bool enabled,
        required bool completeOnly,
      }) {
        final currentStatuses = Set<String>.from(
          _plannerItemDataSource!.filterStatuses,
        );
        currentStatuses.remove(PlannerFilterStatus.complete.value);
        currentStatuses.remove(PlannerFilterStatus.incomplete.value);
        if (enabled) {
          currentStatuses.add(
            completeOnly
                ? PlannerFilterStatus.complete.value
                : PlannerFilterStatus.incomplete.value,
          );
        }
        _plannerItemDataSource!.setFilterStatuses(currentStatuses);
        setSheetState(() {});
      }

      void setGradedFilterMode({
        required bool enabled,
        required bool gradedOnly,
      }) {
        final currentStatuses = Set<String>.from(
          _plannerItemDataSource!.filterStatuses,
        );
        currentStatuses.remove(PlannerFilterStatus.graded.value);
        currentStatuses.remove(PlannerFilterStatus.ungraded.value);
        if (enabled) {
          currentStatuses.add(
            gradedOnly
                ? PlannerFilterStatus.graded.value
                : PlannerFilterStatus.ungraded.value,
          );
        }
        _plannerItemDataSource!.setFilterStatuses(currentStatuses);
        setSheetState(() {});
      }

      Widget buildStatusTile(String label) {
        final isChecked = _plannerItemDataSource!.filterStatuses.contains(
          label,
        );
        return CheckboxListTile(
          title: Text(label, style: AppStyles.formText(context)),
          value: isChecked,
          onChanged: (value) {
            final currentStatuses = Set<String>.from(
              _plannerItemDataSource!.filterStatuses,
            );
            if (value == true) {
              currentStatuses.add(label);
            } else {
              currentStatuses.remove(label);
            }
            _plannerItemDataSource!.setFilterStatuses(currentStatuses);
            setSheetState(() {});
          },
          controlAffinity: ListTileControlAffinity.leading,
          dense: true,
          contentPadding: EdgeInsets.zero,
        );
      }

      final visibleCategories = _getVisibleCategories();

      return ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header row
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Filters',
                      style: AppStyles.formText(
                        context,
                      ).copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      _plannerItemDataSource!.clearFilters();
                      setSheetState(() {});
                    },
                    child: const Text('Clear All'),
                  ),
                ],
              ),

              // CLASSES section
              _buildSheetSectionHeader(context, 'CLASSES'),
              for (int i = 0; i < displayCourses.length; i++) ...[
                if (i > 0 &&
                    displayCourses[i].courseGroup !=
                        displayCourses[i - 1].courseGroup)
                  const Divider(height: 20),
                Builder(
                  builder: (context) {
                    final course = displayCourses[i];
                    final isSelected =
                        _plannerItemDataSource!.filteredCourses[course.id] ??
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
                            child: Text(
                              course.title,
                              style: AppStyles.formText(context),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      value: isSelected,
                      onChanged: (value) {
                        final currentFilters = Map<int, bool>.from(
                          _plannerItemDataSource!.filteredCourses,
                        );
                        if (value == true) {
                          currentFilters[course.id] = true;
                        } else {
                          currentFilters.remove(course.id);
                        }
                        _plannerItemDataSource!.setFilteredCourses(
                          currentFilters,
                        );
                        setSheetState(() {});
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    );
                  },
                ),
              ],

              // TYPES section (hidden in todos view)
              if (_currentView != PlannerView.todos) ...[
                _buildSheetSectionHeader(context, 'TYPES'),
                CheckboxListTile(
                  title: Row(
                    children: [
                      Icon(
                        AppConstants.assignmentIcon,
                        size: 12,
                        color: context.colorScheme.onSurface,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        PlannerFilterType.assignments.value,
                        style: AppStyles.formText(context),
                      ),
                    ],
                  ),
                  value: _plannerItemDataSource!.filterTypes.contains(
                    PlannerFilterType.assignments.value,
                  ),
                  onChanged: (value) {
                    final currentTypes = List<String>.from(
                      _plannerItemDataSource!.filterTypes,
                    );
                    if (value == true) {
                      if (!currentTypes.contains(
                        PlannerFilterType.assignments.value,
                      )) {
                        currentTypes.add(PlannerFilterType.assignments.value);
                      }
                    } else {
                      currentTypes.remove(PlannerFilterType.assignments.value);
                    }
                    _plannerItemDataSource!.setFilterTypes(currentTypes);
                    setSheetState(() {});
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                CheckboxListTile(
                  title: Row(
                    children: [
                      Icon(
                        AppConstants.eventIcon,
                        size: 12,
                        color: userSettings!.eventsColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        PlannerFilterType.events.value,
                        style: AppStyles.formText(context),
                      ),
                    ],
                  ),
                  value: _plannerItemDataSource!.filterTypes.contains(
                    PlannerFilterType.events.value,
                  ),
                  onChanged: (value) {
                    final currentTypes = List<String>.from(
                      _plannerItemDataSource!.filterTypes,
                    );
                    if (value == true) {
                      if (!currentTypes.contains(
                        PlannerFilterType.events.value,
                      )) {
                        currentTypes.add(PlannerFilterType.events.value);
                      }
                    } else {
                      currentTypes.remove(PlannerFilterType.events.value);
                    }
                    _plannerItemDataSource!.setFilterTypes(currentTypes);
                    setSheetState(() {});
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                CheckboxListTile(
                  title: Row(
                    children: [
                      Icon(
                        AppConstants.courseScheduleIcon,
                        size: 12,
                        color: context.colorScheme.onSurface,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        PlannerFilterType.classSchedules.value,
                        style: AppStyles.formText(context),
                      ),
                    ],
                  ),
                  value: _plannerItemDataSource!.filterTypes.contains(
                    PlannerFilterType.classSchedules.value,
                  ),
                  onChanged: (value) {
                    final currentTypes = List<String>.from(
                      _plannerItemDataSource!.filterTypes,
                    );
                    if (value == true) {
                      if (!currentTypes.contains(
                        PlannerFilterType.classSchedules.value,
                      )) {
                        currentTypes.add(
                          PlannerFilterType.classSchedules.value,
                        );
                      }
                    } else {
                      currentTypes.remove(
                        PlannerFilterType.classSchedules.value,
                      );
                    }
                    _plannerItemDataSource!.setFilterTypes(currentTypes);
                    setSheetState(() {});
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                CheckboxListTile(
                  title: Row(
                    children: [
                      Icon(
                        AppConstants.externalCalendarIcon,
                        size: 12,
                        color: context.colorScheme.onSurface,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        PlannerFilterType.externalCalendars.value,
                        style: AppStyles.formText(context),
                      ),
                    ],
                  ),
                  value: _plannerItemDataSource!.filterTypes.contains(
                    PlannerFilterType.externalCalendars.value,
                  ),
                  onChanged: (value) {
                    final currentTypes = List<String>.from(
                      _plannerItemDataSource!.filterTypes,
                    );
                    if (value == true) {
                      if (!currentTypes.contains(
                        PlannerFilterType.externalCalendars.value,
                      )) {
                        currentTypes.add(
                          PlannerFilterType.externalCalendars.value,
                        );
                      }
                    } else {
                      currentTypes.remove(
                        PlannerFilterType.externalCalendars.value,
                      );
                    }
                    _plannerItemDataSource!.setFilterTypes(currentTypes);
                    setSheetState(() {});
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ],

              // STATUS section
              _buildSheetSectionHeader(context, 'STATUS'),
              _CheckboxToggle(
                isChecked: isCompleteFilterEnabled,
                isToggleOn: showCompletedOnly,
                baseLabel: PlannerFilterStatus.complete.value,
                toggleOnLabel: PlannerFilterStatus.complete.value,
                toggleOffLabel: PlannerFilterStatus.incomplete.value,
                onCheckedChanged: (value) {
                  setCompleteFilterMode(
                    enabled: value ?? false,
                    // Default to complete-only when enabling via checkbox.
                    completeOnly: true,
                  );
                },
                onToggleChanged: (value) {
                  setCompleteFilterMode(enabled: true, completeOnly: value);
                },
                onToggleTapWhenDisabled: () {
                  setCompleteFilterMode(
                    enabled: true,
                    // If switch is tapped first, enable and show complete-only.
                    completeOnly: true,
                  );
                },
              ),
              _CheckboxToggle(
                isChecked: isGradedFilterEnabled,
                isToggleOn: showGradedOnly,
                baseLabel: PlannerFilterStatus.graded.value,
                toggleOnLabel: PlannerFilterStatus.graded.value,
                toggleOffLabel: PlannerFilterStatus.ungraded.value,
                onCheckedChanged: (value) {
                  setGradedFilterMode(
                    enabled: value ?? false,
                    // Default to graded-only when enabling via checkbox.
                    gradedOnly: true,
                  );
                },
                onToggleChanged: (value) {
                  setGradedFilterMode(enabled: true, gradedOnly: value);
                },
                onToggleTapWhenDisabled: () {
                  setGradedFilterMode(
                    enabled: true,
                    // If switch is tapped first, enable and show graded-only.
                    gradedOnly: true,
                  );
                },
              ),
              buildStatusTile(PlannerFilterStatus.overdue.value),

              // CATEGORIES section (conditional)
              if (visibleCategories.isNotEmpty) ...[
                _buildSheetSectionHeader(context, 'CATEGORIES'),
                ...visibleCategories.map((category) {
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
                    value: _plannerItemDataSource!.filterCategories.contains(
                      category.title,
                    ),
                    onChanged: (value) {
                      final currentCategories = List<String>.from(
                        _plannerItemDataSource!.filterCategories,
                      );
                      if (value == true) {
                        if (!currentCategories.contains(category.title)) {
                          currentCategories.add(category.title);
                        }
                      } else {
                        currentCategories.remove(category.title);
                      }
                      _plannerItemDataSource!.setFilterCategories(
                        currentCategories,
                      );
                      setSheetState(() {});
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  );
                }),
              ],
            ],
          ),
        ),
      );
    }

    if (isMobile) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: context.colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (context) => StatefulBuilder(builder: buildContent),
      );
    } else {
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
            child: StatefulBuilder(builder: buildContent),
          ),
        ],
      );
    }
  }

  Widget _buildSheetSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 4),
      child: Text(title, style: AppStyles.smallSecondaryTextLight(context)),
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
                      return RadioGroup<PlannerView>(
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
                          children: List.generate(PlannerView.values.length, (
                            index,
                          ) {
                            return RadioListTile<PlannerView>(
                              title: Text(
                                CalendarConstants
                                    .defaultViews[PlannerHelper.mapHeliumViewToApiView(
                                  PlannerView.values[index],
                                )],
                                style: AppStyles.formText(context),
                              ),
                              value: PlannerView.values[index],
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
    return TodosTable(
      dataSource: _plannerItemDataSource!,
      controller: _todosController,
      onTap: _openPlannerItem,
      onToggleCompleted: _onToggleCompleted,
      onDelete: _deletePlannerItem,
    );
  }

  Widget _buildCalendarItemTitle(
    PlannerItemBaseModel plannerItem, {
    bool? completedOverride,
  }) {
    final isCompleted =
        completedOverride ??
        (plannerItem is HomeworkModel && plannerItem.completed);

    final titleStyle = AppStyles.smallSecondaryTextLight(context).copyWith(
      color: Colors.white,
      decoration: isCompleted
          ? TextDecoration.lineThrough
          : TextDecoration.none,
      decorationColor: Colors.white,
      decorationThickness: 2.0,
    );

    return Text(
      plannerItem.title,
      style: titleStyle,
      maxLines:
          _currentView == PlannerView.month ||
              _currentView == PlannerView.agenda
          ? 1
          : null,
      overflow:
          _currentView == PlannerView.month ||
              _currentView == PlannerView.agenda
          ? TextOverflow.ellipsis
          : null,
    );
  }

  bool _isRecurringPlannerItem(PlannerItemBaseModel plannerItem) {
    return plannerItem is CourseScheduleEventModel &&
        (plannerItem.recurrenceRule?.isNotEmpty ?? false);
  }

  Widget _buildRecurringIndicatorIcon({Color? color}) {
    return Icon(
      Icons.repeat,
      size: 12,
      color: color ?? Colors.white.withValues(alpha: 0.75),
    );
  }

  Widget _buildRecurringIndicatorOverlay({
    required PlannerItemBaseModel plannerItem,
    required Widget child,
  }) {
    if (!_isRecurringPlannerItem(plannerItem) ||
        _currentView == PlannerView.agenda ||
        _currentView == PlannerView.week ||
        _currentView == PlannerView.day) {
      return child;
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        Positioned.fill(
          child: Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 3),
              child: IgnorePointer(child: _buildRecurringIndicatorIcon()),
            ),
          ),
        ),
      ],
    );
  }

  EdgeInsets _recurringContentPadding(PlannerItemBaseModel plannerItem) {
    if (!_isRecurringPlannerItem(plannerItem)) {
      return EdgeInsets.zero;
    }

    if (_currentView == PlannerView.agenda ||
        _currentView == PlannerView.week ||
        _currentView == PlannerView.day) {
      return EdgeInsets.zero;
    }

    return const EdgeInsets.only(right: 11);
  }

  Widget _buildCheckboxWidget({
    required HomeworkModel homework,
    bool? completedOverride,
  }) {
    // If UI override exists, use that, to avoid a flicker
    final isCompleted =
        _plannerItemDataSource?.isHomeworkCompleted(homework) ??
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
          color: Colors.white.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  Widget _buildCalendarItemTime(
    PlannerItemBaseModel plannerItem, {
    bool isInAgenda = false,
  }) {
    final timeText = Text(
      HeliumDateTime.formatTime(
        HeliumDateTime.toLocal(plannerItem.start, userSettings!.timeZone),
      ),
      style: AppStyles.smallSecondaryTextLight(
        context,
      ).copyWith(color: Colors.white.withValues(alpha: 0.7)),
    );

    if (!_shouldShowRecurringIconWithTime(
      plannerItem,
      isInAgenda: isInAgenda,
    )) {
      return timeText;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildRecurringTimePrefixIcon(),
        const SizedBox(width: 2),
        timeText,
      ],
    );
  }

  Widget _buildCalendarItemTimeBelowTitleRow(
    PlannerItemBaseModel plannerItem, {
    bool isInAgenda = false,
  }) {
    return Row(
      children: [
        if (_shouldShowRecurringIconWithTime(
          plannerItem,
          isInAgenda: isInAgenda,
        )) ...[
          _buildRecurringTimePrefixIcon(),
          const SizedBox(width: 2),
        ],
        Expanded(
          child: Text(
            HeliumDateTime.formatTimeRange(
              HeliumDateTime.toLocal(plannerItem.start, userSettings!.timeZone),
              HeliumDateTime.toLocal(plannerItem.end, userSettings!.timeZone),
              plannerItem.showEndTime,
            ),
            style: AppStyles.smallSecondaryTextLight(
              context,
            ).copyWith(color: Colors.white.withValues(alpha: 0.7)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  bool _shouldShowRecurringIconWithTime(
    PlannerItemBaseModel plannerItem, {
    bool isInAgenda = false,
  }) {
    return _isRecurringPlannerItem(plannerItem) &&
        (isInAgenda ||
            _currentView == PlannerView.week ||
            _currentView == PlannerView.day);
  }

  Widget _buildRecurringTimePrefixIcon() {
    return Icon(
      Icons.repeat,
      size: 10,
      color: Colors.white.withValues(alpha: 0.4),
    );
  }

  Widget _buildCalendarItemLocationRow(String location) {
    return Row(
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
            style: AppStyles.smallSecondaryTextLight(
              context,
            ).copyWith(color: Colors.white.withValues(alpha: 0.7)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _PlannerTooltipRow {
  final IconData? icon;
  final String? text;
  final Color? color;
  final Widget? widget;

  const _PlannerTooltipRow.text({
    required this.icon,
    required this.text,
    this.color,
  }) : widget = null;

  const _PlannerTooltipRow.widget({required this.widget})
    : icon = null,
      text = null,
      color = null;
}

class _CheckboxToggle extends StatelessWidget {
  final bool isChecked;
  final bool isToggleOn;
  final String baseLabel;
  final String toggleOnLabel;
  final String toggleOffLabel;
  final ValueChanged<bool?> onCheckedChanged;
  final ValueChanged<bool> onToggleChanged;
  final VoidCallback onToggleTapWhenDisabled;

  const _CheckboxToggle({
    required this.isChecked,
    required this.isToggleOn,
    required this.baseLabel,
    required this.toggleOnLabel,
    required this.toggleOffLabel,
    required this.onCheckedChanged,
    required this.onToggleChanged,
    required this.onToggleTapWhenDisabled,
  });

  @override
  Widget build(BuildContext context) {
    final label = isChecked
        ? (isToggleOn ? toggleOnLabel : toggleOffLabel)
        : baseLabel;

    return CheckboxListTile(
      title: Text(label, style: AppStyles.formText(context)),
      value: isChecked,
      onChanged: onCheckedChanged,
      controlAffinity: ListTileControlAffinity.leading,
      dense: true,
      contentPadding: EdgeInsets.zero,
      secondary: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Only',
            style: AppStyles.smallSecondaryTextLight(
              context,
            ).copyWith(color: Theme.of(context).colorScheme.onSurface),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: !isChecked ? onToggleTapWhenDisabled : null,
            child: Switch(
              value: isToggleOn,
              onChanged: isChecked ? onToggleChanged : null,
            ),
          ),
        ],
      ),
    );
  }
}
