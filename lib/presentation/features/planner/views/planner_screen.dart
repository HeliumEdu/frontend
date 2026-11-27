import 'dart:async';
import 'dart:ui' as ui;

import 'package:collection/collection.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:heliumapp/config/analytics_event.dart';
import 'package:heliumapp/config/app_route.dart';
import 'package:heliumapp/config/app_router.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/core/analytics_service.dart';
import 'package:heliumapp/core/cache_service.dart';
import 'package:heliumapp/core/day_change_service.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/core/feedback_service.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/core/motion_service.dart';
import 'package:heliumapp/data/models/auth/user_settings_model.dart';
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
import 'package:heliumapp/data/models/planner/resource_model.dart';
import 'package:heliumapp/data/models/planner/request/event_request_model.dart';
import 'package:heliumapp/data/models/planner/reminder_model.dart';
import 'package:heliumapp/data/models/planner/request/homework_request_model.dart';
import 'package:heliumapp/data/repositories/attachment_repository_impl.dart';
import 'package:heliumapp/data/repositories/category_repository_impl.dart';
import 'package:heliumapp/data/repositories/course_repository_impl.dart';
import 'package:heliumapp/data/repositories/course_schedule_event_repository_impl.dart';
import 'package:heliumapp/data/repositories/event_repository_impl.dart';
import 'package:heliumapp/data/repositories/external_calendar_repository_impl.dart';
import 'package:heliumapp/data/repositories/homework_repository_impl.dart';
import 'package:heliumapp/data/repositories/resource_repository_impl.dart';
import 'package:heliumapp/data/sources/attachment_remote_data_source.dart';
import 'package:heliumapp/data/sources/category_remote_data_source.dart';
import 'package:heliumapp/data/sources/course_remote_data_source.dart';
import 'package:heliumapp/data/sources/course_schedule_builder_source.dart';
import 'package:heliumapp/data/sources/course_schedule_remote_data_source.dart';
import 'package:heliumapp/data/sources/event_remote_data_source.dart';
import 'package:heliumapp/data/sources/external_calendar_remote_data_source.dart';
import 'package:heliumapp/data/sources/homework_remote_data_source.dart';
import 'package:heliumapp/data/sources/planner_item_data_source.dart';
import 'package:heliumapp/data/sources/resource_remote_data_source.dart';
import 'package:heliumapp/l10n/app_localizations.dart';
import 'package:heliumapp/presentation/core/views/base_page_screen_state.dart';
import 'package:heliumapp/presentation/features/auth/bloc/auth_bloc.dart';
import 'package:heliumapp/presentation/features/auth/bloc/auth_state.dart';
import 'package:heliumapp/presentation/features/notebook/bloc/note_bloc.dart';
import 'package:heliumapp/presentation/features/notebook/bloc/note_state.dart';
import 'package:heliumapp/presentation/features/planner/bloc/attachment_bloc.dart';
import 'package:heliumapp/presentation/features/planner/bloc/attachment_state.dart';
import 'package:heliumapp/presentation/features/planner/bloc/reminder_bloc.dart';
import 'package:heliumapp/presentation/features/planner/bloc/reminder_state.dart';
import 'package:heliumapp/presentation/features/planner/bloc/external_calendar_bloc.dart';
import 'package:heliumapp/presentation/features/planner/bloc/external_calendar_state.dart';
import 'package:heliumapp/presentation/features/planner/bloc/planner_bloc.dart';
import 'package:heliumapp/presentation/features/planner/bloc/planner_event.dart';
import 'package:heliumapp/presentation/features/planner/bloc/planner_state.dart';
import 'package:heliumapp/presentation/features/planner/bloc/planneritem_bloc.dart';
import 'package:heliumapp/presentation/features/planner/bloc/planneritem_event.dart';
import 'package:heliumapp/presentation/features/planner/bloc/planneritem_state.dart';
import 'package:heliumapp/presentation/features/planner/dialogs/confirm_delete_dialog.dart';
import 'package:heliumapp/presentation/features/planner/dialogs/recurrence_scope_dialog.dart';
import 'package:heliumapp/presentation/features/planner/dialogs/course_schedule_event_dialog.dart';
import 'package:heliumapp/presentation/features/planner/dialogs/external_calendar_event_dialog.dart';
import 'package:heliumapp/presentation/features/planner/views/planner_item_add_screen.dart';
import 'package:heliumapp/presentation/features/planner/widgets/day_popout_dialog.dart';
import 'package:heliumapp/presentation/features/planner/widgets/planner_agenda_print_list.dart';
import 'package:heliumapp/presentation/features/planner/widgets/planner_date_navigator.dart';
import 'package:heliumapp/presentation/features/planner/widgets/planner_filter_menu.dart';
import 'package:heliumapp/presentation/features/planner/widgets/planner_item_calendar_tile.dart';
import 'package:heliumapp/presentation/features/planner/widgets/planner_item_tooltip.dart';
import 'package:heliumapp/presentation/features/planner/widgets/planner_mobile_month_cell.dart';
import 'package:heliumapp/presentation/features/planner/widgets/todos_data_grid.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/base_event.dart';
import 'package:heliumapp/presentation/navigation/shell/navigation_shell.dart';
import 'package:heliumapp/presentation/ui/components/helium_search_field.dart';
import 'package:heliumapp/presentation/ui/dialogs/helium_menu.dart';
import 'package:heliumapp/presentation/ui/feedback/error_card.dart';
import 'package:heliumapp/presentation/ui/feedback/loading_indicator.dart';
import 'package:heliumapp/presentation/ui/layout/shadow_container.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/color_helpers.dart';
import 'package:heliumapp/utils/course_group_helpers.dart';
import 'package:heliumapp/utils/date_time_helpers.dart';
import 'package:heliumapp/presentation/features/planner/widgets/week_column.dart';
import 'package:heliumapp/utils/planner_helper.dart';
import 'package:heliumapp/utils/planner_month_layout.dart';
import 'package:heliumapp/utils/platform_behavior.dart';
import 'package:heliumapp/utils/print_helpers.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:logging/logging.dart';
import 'package:syncfusion_flutter_core/localizations.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

final _log = Logger('presentation.views');

class PlannerScreen extends StatelessWidget {
  static const String todayButtonKey = 'planner_today_button';
  static const String viewSwitcherButtonKey = 'planner_view_switcher_button';

  static String viewOptionKey(PlannerView view) =>
      'planner_view_option_${view.name}';
  static const String filterButtonKey = 'planner_filter_button';
  static const String searchButtonKey = 'planner_search_button';

  const PlannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => PlannerBloc(
            courseRepository: CourseRepositoryImpl(
              remoteDataSource: CourseRemoteDataSourceImpl(
                dioClient: DioClient(),
              ),
            ),
            courseScheduleRepository: CourseScheduleRepositoryImpl(
              remoteDataSource: CourseScheduleRemoteDataSourceImpl(
                dioClient: DioClient(),
              ),
              builderSource: CourseScheduleBuilderSource(),
            ),
            categoryRepository: CategoryRepositoryImpl(
              remoteDataSource: CategoryRemoteDataSourceImpl(
                dioClient: DioClient(),
              ),
            ),
            resourceRepository: ResourceRepositoryImpl(
              remoteDataSource: ResourceRemoteDataSourceImpl(
                dioClient: DioClient(),
              ),
            ),
            attachmentRepository: AttachmentRepositoryImpl(
              remoteDataSource: AttachmentRemoteDataSourceImpl(
                dioClient: DioClient(),
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

class _CalendarScreenState extends BasePageScreenState<_CalendarProvidedScreen> {

  static const _monthViewHeaderHeight = 28.0;

  // How long to suppress tooltips after any intentional user action (drag,
  // drop, resize, pointer-down anywhere). Resets on each new action so rapid
  // interactions don't produce stray tooltips.
  static const _tooltipSuppressDelay = Duration(seconds: 2);

  @override
  bool get enablePrint => true;

  @override
  bool get enablePrintFlexColumn => true;

  @override
  Widget buildHeaderArea(BuildContext context) => _buildCalendarHeader();


  @override
  VoidCallback get actionButtonCallback => () {
    final initialDate = PlannerHelper.initialDateForNewItem(
      view: _currentView,
      selectedDate: _calendarController.selectedDate,
      now: DateTime.now(),
      timeZone: userSettings.timeZone,
    );

    showPlannerItemAdd(
      context,
      initialDate: initialDate,
      isFromMonthView: _calendarController.view == CalendarView.month,
      isEdit: false,
      isNew: true,
    );
  };

  @override
  bool get showActionButton => true;

  late final CalendarController _calendarController;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _monthViewScrollController = ScrollController();

  final GlobalKey _todayButtonKey = GlobalKey();
  final GlobalKey<TodosDataGridState> _todosDataGridKey = GlobalKey();

  final List<CalendarView> _allowedViews = [
    CalendarView.month,
    CalendarView.week,
    CalendarView.day,
    CalendarView.schedule,
  ];

  List<CourseGroupModel> _courseGroups = [];
  List<CourseModel> _courses = [];

  Map<int, CourseGroupModel> get _courseGroupsById => {
    for (final g in _courseGroups) g.id: g,
  };
  final Map<int, CategoryModel> _categoriesMap = {};
  final Map<int, ResourceModel> _resourcesMap = {};
  final List<AttachmentModel> _attachments = [];
  final List<CategoryModel> _deduplicatedCategories = [];
  bool _isSearchExpanded = false;
  bool _isFilterExpanded = false;
  bool _searchLogged = false;
  final Set<String> _loggedFilterKinds = {};
  bool _wasDesktop = false;
  PlannerView _currentView = PlannerView.month;
  PlannerView? _previousView;

  DateTime? _storedSelectedDate;
  DateTime? _storedDisplayDate;

  bool _mobileMonthAutoSelectApplied = false;

  List<DateTime> _visibleDates = [];
  bool _isCalendarInteractionInProgress = false;
  bool _dragRejected = false;
  Timer? _tooltipSuppressTimer;
  final Stopwatch _sinceLastInput = Stopwatch()..start();
  DateTime? _endedDayToLeave;
  Timer? _newDayJumpTimer;

  // Workaround for SfCalendar reporting the wrong appointment in onDragStart.
  // _lastHoveredItem tracks hover via MouseRegion; _pointerDownHoveredItem
  // snapshots it at pointer-down (before SfCalendar's rebuild clears hover).
  // If onDragStart disagrees, the drag is rejected.
  // https://github.com/syncfusion/flutter-widgets/issues/2523
  PlannerItemBaseModel? _lastHoveredItem;
  PlannerItemBaseModel? _pointerDownHoveredItem;

  PlannerItemBaseModel? _pointerDownItem;

  // Debounces rapid checkbox taps so fast toggling doesn't fire a network
  // request per tap. We update the optimistic override immediately on each
  // tap for instant visual feedback, but defer the actual bloc dispatch
  // until the user stops tapping.
  final Map<int, Timer> _pendingToggleTimers = {};
  final Map<int, bool> _pendingToggleValues = {};

  // Completion updates dispatched to the BLoC and awaiting a response, per
  // homework ID. A response is stale while the count is above zero.
  final Map<int, int> _inFlightCompletionCounts = {};

  final Set<(int, int)> _completingOccurrences = {};

  PlannerItemBaseModel? _deferredOpenItem;
  VoidCallback? _deferredOpenAction;

  int _calendarItemsDisplayCount =
      PlannerMonthLayout.monthMinItemDisplayCount;
  PlannerItemDataSource? _plannerItemDataSource;
  DateTime? _agendaLoadedWeek;
  final Map<int, ExternalCalendarModel> _externalCalendarsById = {};

  @override
  void initState() {
    super.initState();

    _calendarController = CalendarController()
      ..view = PlannerHelper.mapHeliumViewToSfCalendarView(_currentView);

    _calendarController.addPropertyChangedListener((value) {
      if (value == 'calendarView') {
        _calendarViewChanged();
      } else if (value == 'displayDate' && _currentView == PlannerView.agenda) {
        _log.fine('Display date change: $value');
        // Defer setState because the property-changed listener fires during
        // SfCalendar's internal layout pass; calling setState synchronously
        // would trigger a build during build error
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;

          setState(() {});
        });
      }
    });

    // An optional ?date=YYYY-MM-DD deep link. NavigationShell caches
    // screens, so PlannerScreen mounts once and re-uses the same instance on
    // every revisit — initState alone wouldn't catch later navigations to
    // /planner?date=X. Listening to the routerDelegate handles both the
    // first mount and subsequent in-shell navigations.
    router.routerDelegate.addListener(_onRouterChanged);
    if (!_applyDateDeepLink()) {
      _goToToday();
    }
    DayChangeService().addDeviceDayEndedListener(_onDeviceDayEnded);
    HardwareKeyboard.instance.addHandler(_onKeyInput);
    GestureBinding.instance.pointerRouter.addGlobalRoute(_onPointerInput);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_warmSearchGlyphs());
    });
  }

  @override
  void loadScreenData({required bool forceRefresh, bool keepPlace = false}) {
    if (forceRefresh && !keepPlace) _goToToday();
    context.read<PlannerBloc>().add(
      FetchPlannerScreenDataEvent(
        origin: EventOrigin.screen,
        forceRefresh: forceRefresh,
        background: keepPlace,
      ),
    );
  }

  @override
  bool get defersInPlaceRefresh =>
      super.defersInPlaceRefresh ||
      (_plannerItemDataSource?.changeNotificationsFrozen ?? false) ||
      _pendingToggleTimers.isNotEmpty ||
      _inFlightCompletionCounts.isNotEmpty;

  bool _onKeyInput(KeyEvent event) {
    _sinceLastInput.reset();
    return false;
  }

  void _onPointerInput(PointerEvent event) {
    if (event is PointerDownEvent) _sinceLastInput.reset();
  }

  void _onDeviceDayEnded(DateTime dayEnded) {
    _endedDayToLeave = dayEnded;
    _jumpToNewDayOnceIdle();
  }

  void _jumpToNewDayOnceIdle() {
    _newDayJumpTimer?.cancel();
    final untilIdle =
        CacheService.inactivityThreshold - _sinceLastInput.elapsed;
    if (untilIdle > Duration.zero) {
      _newDayJumpTimer = Timer(untilIdle, _jumpToNewDayOnceIdle);
      return;
    }
    final dayEnded = _endedDayToLeave!;
    _endedDayToLeave = null;
    if (_currentView != PlannerView.todos &&
        PlannerHelper.isShowingDay(_visibleDates, dayEnded)) {
      _jumpToDate(DateTime.now(), offsetForVisibility: true);
    }
  }

  /// Reads the `?date=` query param when the current location is /planner
  /// and jumps the calendar to that date. Returns true when a jump happened.
  bool _applyDateDeepLink() {
    final uri = router.routerDelegate.currentConfiguration.uri;
    if (uri.path != AppRoute.plannerScreen) return false;
    final dateParam = uri.queryParameters[DeepLinkParam.date];
    if (dateParam == null) return false;
    final parsed = DateTime.tryParse('${dateParam}T00:00:00');
    if (parsed == null) return false;
    _jumpToDate(parsed, offsetForVisibility: true);
    return true;
  }

  void _applyViewDeepLink(Uri uri) {
    final view = PlannerView.values.asNameMap()[uri.queryParameters[DeepLinkParam.view]];
    final statusNames = PlannerFilterStatus.values.asNameMap();
    final statuses = (uri.queryParameters[DeepLinkParam.status]?.split(',') ?? const <String>[])
        .map((name) => statusNames[name.trim()]?.value)
        .nonNulls
        .toSet();
    if (view == null && statuses.isEmpty) return;
    final courseId = int.tryParse(uri.queryParameters[DeepLinkParam.course] ?? '');
    final categories = uri.queryParametersAll[DeepLinkParam.category] ?? const <String>[];
    setState(() {
      if (view != null) _changeView(view);
      if (statuses.isNotEmpty) {
        _plannerItemDataSource!.showOnly(statuses, courseId: courseId, categories: categories);
      }
    });
  }

  /// Applies a /planner link's query params, then drops them from the URL so
  /// they apply once and a repeat of the same link applies again.
  void _consumeDeepLink() {
    final uri = router.routerDelegate.currentConfiguration.uri;
    if (uri.path != AppRoute.plannerScreen || uri.queryParameters.isEmpty) return;
    _applyDateDeepLink();
    _applyViewDeepLink(uri);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && router.routerDelegate.currentConfiguration.uri == uri) {
        router.replace(AppRoute.plannerScreen);
      }
    });
  }

  void _onRouterChanged() {
    if (!mounted) return;
    if (_plannerItemDataSource == null) {
      _applyDateDeepLink();
    } else {
      _consumeDeepLink();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final isDesktop = Responsive.isDesktop(context);
    if (_wasDesktop && !isDesktop && _isSearchExpanded) {
      // Defer setState because didChangeDependencies runs during the build
      // pipeline; calling setState here directly would cause a nested rebuild
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isSearchExpanded = false;
          });
        }
      });
    }
    _wasDesktop = isDesktop;
  }

  /// Raises the keyboard once the expand animation settles so its relayout
  /// stays off the animating frames. No-op on collapse.
  void _onSearchExpandEnd() {
    if (!mounted || !_isSearchExpanded) return;
    _searchFocusNode.requestFocus();
  }

  /// Warms the search icon glyphs at idle so the first expand skips the cold
  /// glyph-atlas cost. Off-tree raster, so layout is untouched.
  Future<void> _warmSearchGlyphs() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    for (final icon in const [Icons.search, Icons.close]) {
      final painter = TextPainter(
        textDirection: TextDirection.ltr,
        text: TextSpan(
          text: String.fromCharCode(icon.codePoint),
          style: TextStyle(
            fontFamily: icon.fontFamily,
            package: icon.fontPackage,
            fontSize: 24,
          ),
        ),
      )..layout();
      painter.paint(canvas, Offset.zero);
      painter.dispose();
    }
    final picture = recorder.endRecording();
    try {
      final image = await picture.toImage(48, 48);
      image.dispose();
    } catch (e) {
      _log.fine('Glyph warm-up unavailable', e);
    } finally {
      picture.dispose();
    }
  }

  @override
  void dispose() {
    router.routerDelegate.removeListener(_onRouterChanged);
    DayChangeService().removeDeviceDayEndedListener(_onDeviceDayEnded);
    HardwareKeyboard.instance.removeHandler(_onKeyInput);
    GestureBinding.instance.pointerRouter.removeGlobalRoute(_onPointerInput);
    _newDayJumpTimer?.cancel();
    _tooltipSuppressTimer?.cancel();
    for (final timer in _pendingToggleTimers.values) {
      timer.cancel();
    }
    _pendingToggleTimers.clear();
    _pendingToggleValues.clear();
    _inFlightCompletionCounts.clear();
    _deferredOpenItem = null;
    _deferredOpenAction = null;
    _plannerItemDataSource?.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
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

          // Dispose the previous instance before replacing it.
          _plannerItemDataSource?.dispose();

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
            todosItemsPerPage: Responsive.defaultRowsPerPage(context),
          );

          _plannerItemDataSource!.onLoadError = (message) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && !isShowingErrorCard) {
                showSnackBar(context, message, type: SnackType.error);
              }
            });
          };

          _plannerItemDataSource!.isMonthView =
              _currentView == PlannerView.month;

          if (!isLoading) {
            _applyScreenDataToDataSource();
          }

          _plannerItemDataSource!.restoreFiltersIfEnabled();
        });
        _consumeDeepLink();

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
            setState(() => screenError = null);
            _populateScreenData(state);

            // The range cache short-circuits handleLoadMore, so an
            // invalidated Dio cache alone refetches nothing.
            if (state.background) {
              unawaited(_plannerItemDataSource?.refreshLoadedDaysQuietly());
            } else if (state.forceRefresh) {
              _agendaLoadedWeek = null;
              unawaited(
                _plannerItemDataSource?.refreshCalendarSources(
                  visibleStart: _visibleDates.isNotEmpty
                      ? _visibleDates.first
                      : null,
                  visibleEnd: _visibleDates.isNotEmpty
                      ? _visibleDates.last
                      : null,
                ),
              );
            }
          } else if (state
              case CourseOccurrenceSkipped(:final updatedCourse) ||
                  CourseScheduleOccurrenceSkipped(:final updatedCourse)) {
            setState(() {
              _courses = [
                for (final c in _courses)
                  if (c.id == updatedCourse.id) updatedCourse else c,
              ];
            });
            _plannerItemDataSource?.courses = _courses;
            unawaited(
              _plannerItemDataSource?.refreshCalendarSources(
                visibleStart: _visibleDates.isNotEmpty
                    ? _visibleDates.first
                    : null,
                visibleEnd: _visibleDates.isNotEmpty
                    ? _visibleDates.last
                    : null,
              ),
            );
          } else if (state is PlannerError && !state.background) {
            setState(() {
              isLoading = false;
              if (state.origin == EventOrigin.screen) {
                screenError = state.message ?? HeliumException.unexpectedErrorMessage;
              }
            });
            if (state.origin != EventOrigin.screen) {
              if (!isShowingErrorCard) {
                showSnackBar(context, state.message!, type: SnackType.error);
              }
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
            if (state.seriesId case final seriesId?) {
              _showDetachedOccurrence(state.event, seriesId: seriesId, series: state.series);
            } else {
              _plannerItemDataSource!.updatePlannerItem(state.event);
            }
            _executeDeferredOpen(state.event);
          } else if (state is EventDeleted) {
            showSnackBar(context, AppLocalizations.of(context).plannerEventDeletedMessage);
            _updateOrRemove(PlannerItemType.event, state.id, series: state.series);
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
          } else if (state is PlannerItemScreenDataFetched &&
              state.plannerItem != null) {
            final plannerItem = state.plannerItem!;
            _plannerItemDataSource!.updatePlannerItem(
              plannerItem,
              hasPendingCompletionWrite: _hasPendingCompletionWrite(
                plannerItem.id,
              ),
            );
          } else if (state is PlannerItemsError) {
            if (state.origin == EventOrigin.screen && !isShowingErrorCard) {
              showSnackBar(context, state.message!, type: SnackType.error);
            }
            for (final id in _inFlightCompletionCounts.keys) {
              _plannerItemDataSource!.clearCompletedOverride(id);
            }
            _inFlightCompletionCounts.clear();
            _completingOccurrences.clear();
            _deferredOpenItem = null;
            _deferredOpenAction = null;
          } else if (state is HomeworkUpdated) {
            _decrementInFlightCompletion(state.homework.id);
            final previousHomework =
                state.previousHomework ??
                _plannerItemDataSource!.allHomeworks.firstWhereOrNull(
                  (h) => h.id == state.homework.id,
                );
            if (state.seriesId case final seriesId?) {
              if (previousHomework != null) {
                _completingOccurrences.remove(_occurrenceKey(previousHomework));
              }
              _showDetachedOccurrence(state.homework, seriesId: seriesId, series: state.series);
            } else {
              _plannerItemDataSource!.updatePlannerItem(
                state.homework,
                hasPendingCompletionWrite: _hasPendingCompletionWrite(
                  state.homework.id,
                ),
              );
            }
            _executeDeferredOpen(state.homework);
            if (state.homework.completed &&
                previousHomework?.completed == false) {
              if (!_isAwaitingConflictResolution(state)) {
                FeedbackService().scheduleReviewRequest();
              }
              unawaited(
                AnalyticsService().logEvent(
                  name: AnalyticsEvent.homeworkComplete,
                  parameters: {
                    'category': AnalyticsCategory.featureInteraction.value,
                    'on_time': (!DateTime.now().isAfter(
                      state.homework.end,
                    )).toString(),
                    'days_since_due': DateTime.now()
                        .difference(state.homework.start)
                        .inDays
                        .toString(),
                    'term_week': ?_termWeekOf(state.homework),
                  },
                ),
              );
            }
            final prevGrade = previousHomework?.currentGrade;
            final prevIsEmpty =
                prevGrade == null ||
                prevGrade.isEmpty ||
                prevGrade.startsWith('-1/');
            final newGrade = state.homework.currentGrade;
            final newIsValid =
                newGrade != null &&
                newGrade.isNotEmpty &&
                !newGrade.startsWith('-1/');
            if (prevIsEmpty && newIsValid) {
              final daysSinceDue = DateTime.now()
                  .difference(state.homework.start)
                  .inDays;
              unawaited(
                AnalyticsService().logEvent(
                  name: AnalyticsEvent.homeworkGrade,
                  parameters: {
                    'category': AnalyticsCategory.featureInteraction.value,
                    'days_since_due': daysSinceDue.toString(),
                    'term_week': ?_termWeekOf(state.homework),
                  },
                ),
              );
            }
          } else if (state is HomeworkDeleted) {
            showSnackBar(context, AppLocalizations.of(context).plannerAssignmentDeletedMessage);
            _updateOrRemove(PlannerItemType.homework, state.id, series: state.series);
          }
        },
      ),
      BlocListener<ExternalCalendarBloc, ExternalCalendarState>(
        listener: (context, state) async {
          if (_plannerItemDataSource == null) return;

          if (state is ExternalCalendarCreated ||
              state is ExternalCalendarUpdated ||
              state is ExternalCalendarDeleted) {
            _log.info('External calendar changed, refreshing external events');

            await _plannerItemDataSource!.refreshExternalCalendarEvents();
            await _refreshExternalCalendarsMap();
          }
        },
      ),
      BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthProfileUpdated) {
            _log.info('User settings changed, repainting calendar');

            final oldTimeZone = settingsLoaded ? userSettings.timeZone : null;

            _plannerItemDataSource?.userSettings = state.user.settings;

            setState(() {
              userSettings = state.user.settings;
            });

            if (oldTimeZone != state.user.settings.timeZone) {
              context.read<PlannerBloc>().add(
                FetchPlannerScreenDataEvent(
                  origin: EventOrigin.screen,
                  forceRefresh: true,
                ),
              );
            }
          }
        },
      ),
      BlocListener<NoteBloc, NoteState>(
        listenWhen: (previous, current) =>
            current is NoteCreated || current is NoteUpdated || current is NoteDeleted,
        listener: (context, state) {
          if (state is NoteCreated) {
            _plannerItemDataSource?.syncLinkedNote(state.note.id, note: state.note);
          } else if (state is NoteUpdated) {
            _plannerItemDataSource?.syncLinkedNote(state.note.id, note: state.note);
          } else if (state is NoteDeleted) {
            _plannerItemDataSource?.syncLinkedNote(state.noteId);
          }
        },
      ),
      BlocListener<AttachmentBloc, AttachmentState>(
        listener: (context, state) {
          if (_plannerItemDataSource == null) return;

          if (state is AttachmentsCreated) {
            final attachment = state.attachments.firstOrNull;
            if (attachment == null) return;

            if (attachment.homework case final homeworkId?) {
              _updatePlannerItemAttachments(
                homeworkId,
                state.attachments,
                isAdd: true,
                isHomework: true,
              );
            } else if (attachment.event case final eventId?) {
              _updatePlannerItemAttachments(
                eventId,
                state.attachments,
                isAdd: true,
                isHomework: false,
              );
            }
            _attachments.addAll(state.attachments);
            _pushAttachments();
          } else if (state is AttachmentDeleted) {
            if (state.homeworkId case final homeworkId?) {
              _updatePlannerItemAttachments(
                homeworkId,
                state.id,
                isAdd: false,
                isHomework: true,
              );
            } else if (state.eventId case final eventId?) {
              _updatePlannerItemAttachments(
                eventId,
                state.id,
                isAdd: false,
                isHomework: false,
              );
            }
            _attachments.removeWhere((a) => a.id == state.id);
            _pushAttachments();
          }
        },
      ),
      BlocListener<ReminderBloc, ReminderState>(
        listener: (context, state) {
          if (_plannerItemDataSource == null) return;

          if (state is ReminderCreated || state is ReminderUpdated) {
            final reminder = state is ReminderCreated
                ? state.reminder
                : (state as ReminderUpdated).reminder;
            final homeworkId = reminder.homework?.id;
            final eventId = reminder.event?.id;
            if (homeworkId == null && eventId == null) return;

            final isHomework = homeworkId != null;
            final itemId = isHomework ? homeworkId : eventId!;

            _updatePlannerItemReminders(
              itemId,
              reminder,
              isAdd: true,
              isHomework: isHomework,
            );
          } else if (state is ReminderDeleted) {
            final owner = _findReminderOwner(state.id);
            if (owner == null) return;

            _updatePlannerItemReminders(
              owner.id,
              state.id,
              isAdd: false,
              isHomework: owner is HomeworkModel,
            );
          }
        },
      ),
    ];
  }


  @override
  Widget buildMainArea(BuildContext context) {
    return Listener(
      onPointerDown: (event) {
        _pointerDownHoveredItem = _lastHoveredItem;
        if (_currentView == PlannerView.month) {
          // Freeze at pointer-down (not drag-start) because SfCalendar's
          // internal hit-test runs between these two events. A mid-flight
          // reset between pointer-down and drag-start invalidates its Rect
          // cache and causes it to pick up the wrong appointment.
          _plannerItemDataSource?.freezeChangeNotifications();
        }
        Tooltip.dismissAllToolTips();
      },
      onPointerUp: (_) => _plannerItemDataSource?.thawChangeNotifications(),
      onPointerCancel: (_) => _plannerItemDataSource?.thawChangeNotifications(),
      child: BlocBuilder<PlannerBloc, PlannerState>(
        builder: (context, state) {
          if (state is PlannerLoading) {
            return const Center(child: LoadingIndicator(expanded: false));
          }

          if (screenError != null) {
            return ErrorCard(
              message: screenError!,
              source: 'planner_screen',
              expanded: false,
              onReload: reloadPage,
            );
          }

          // Flexible instead of toggling Expanded/bare child; keeping the
          // widget type constant prevents SfCalendar from being disposed
          // and remounted when isCapturing changes.
          return _buildTodosContent();
        },
      ),
    );
  }

  Widget _buildTodosContent() {
    final decoration = BoxDecoration(
      border: Border.all(
        color: context.colorScheme.outlineVariant.withValues(alpha: 0.5),
      ),
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(8),
        topRight: Radius.circular(8),
      ),
    );
    return Container(
      decoration: decoration,
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
                  PrintHidden(
                    child: Positioned.fill(
                      child: Container(
                        color: context.colorScheme.surface.withValues(
                          alpha: 0.7,
                        ),
                        child: const Center(
                          child: LoadingIndicator(expanded: false),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCalendarView(BuildContext context) {
    // For month view, wrap in SingleChildScrollView so the calendar can expand
    // beyond the viewport when items don't fit.
    //
    // Known SfCalendar bug (debug-mode only): after a resize of this scroll
    // container, SfCalendar's hit-test may use a stale globalToLocal offset,
    // picking up an appointment from the wrong row. The mismatch detection in
    // _onCalendarDragStart rejects these drags harmlessly. The stale-offset
    // window is negligible in release mode — only exploitable under debug lag.
    // https://github.com/syncfusion/flutter-widgets/issues/2523
    if (_calendarController.view == CalendarView.month) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final bool noCollapse =
              !userSettings.collapseBusyDays &&
              !Responsive.isMobile(context);

          int? noCollapseCount;
          double calendarHeight;

          if (noCollapse) {
            // Collapse disabled: show all items at natural height, but fill
            // the viewport on tall screens rather than leaving empty space.
            final maxItems =
                PlannerMonthLayout.calculateMaxItemsForVisibleDates(
                  _plannerItemDataSource,
                  _visibleDates,
                );
            final int displayCount =
                maxItems > PlannerMonthLayout.monthMinItemDisplayCount
                ? maxItems
                : PlannerMonthLayout.monthMinItemDisplayCount;
            final expandedHeight =
                PlannerMonthLayout.calculateExpandedCalendarHeight(
                  displayCount,
                );
            final fillHeight = PlannerMonthLayout.calculateCalendarHeight(
              constraints.maxHeight,
              isMobile: Responsive.isMobile(this.context),
            );
            calendarHeight = expandedHeight > fillHeight
                ? expandedHeight
                : fillHeight;
            // Set display count to the number of fixed-height slots that fit
            // so items stack at their natural height (empty space at cell
            // bottom) instead of stretching to fill the cell.
            final slotsAtFixedHeight =
                PlannerMonthLayout.calculateCalendarItemDisplayCount(
                  calendarHeight,
                );
            noCollapseCount = maxItems > slotsAtFixedHeight
                ? maxItems
                : slotsAtFixedHeight;
          } else {
            // Collapse enabled: fill viewport dynamically, down to minimum.
            calendarHeight = PlannerMonthLayout.calculateCalendarHeight(
              constraints.maxHeight,
              isMobile: Responsive.isMobile(this.context),
            );
          }

          return SingleChildScrollView(
            controller: _monthViewScrollController,
            child: SizedBox(
              height: calendarHeight,
              child: _buildCalendar(noCollapseCount: noCollapseCount),
            ),
          );
        },
      );
    } else {
      return _buildCalendar();
    }
  }

  Widget _buildCalendar({int? noCollapseCount}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _calendarItemsDisplayCount =
            noCollapseCount ??
            PlannerMonthLayout.calculateCalendarItemDisplayCount(
              constraints.maxHeight,
            );

        final agendaHeight = Responsive.isMobile(context)
            ? PlannerItemCalendarTile.agendaHeightMobile
            : PlannerItemCalendarTile.agendaHeightDesktop;

        final showWeekNumbers =
            userSettings.showWeekNumbers;

        // Every other view keeps SfCalendar's own week number column, which is
        // only oversized enough to matter in month view.
        final usesCustomWeekColumn =
            showWeekNumbers &&
            _currentView == PlannerView.month &&
            !Responsive.isMobile(context);

        final calendar = SfCalendar(
          backgroundColor: context.colorScheme.surface,
          cellBorderColor:
              (Responsive.isMobile(context) &&
                  _currentView == PlannerView.month)
              ? Colors.transparent
              : null,
          controller: _calendarController,
          headerHeight: 0,
          selectionDecoration: PrintableArea.capturing.value
              ? const BoxDecoration()
              : null,
          showCurrentTimeIndicator: true,
          showWeekNumber:
              _currentView != PlannerView.threeDay &&
              !usesCustomWeekColumn &&
              showWeekNumbers,
          allowDragAndDrop:
              PlatformBehavior.allowsDragAndDropByDefault ||
              userSettings.dragAndDropOnMobile,
          dragAndDropSettings: DragAndDropSettings(
            timeIndicatorStyle: AppStyles.smallSecondaryText(
              context,
            ).copyWith(color: context.colorScheme.primary),
          ),
          allowAppointmentResize: true,
          allowedViews: _allowedViews,
          dataSource: _plannerItemDataSource,
          timeZone: userSettings.timeZone.name,
          firstDayOfWeek:
              PlannerHelper.weekStartsOnRemap[userSettings.weekStartsOn],
          todayTextStyle: AppStyles.standardBodyText(
            context,
          ).copyWith(color: context.colorScheme.onPrimary),
          viewHeaderHeight: _currentView == PlannerView.month
              ? _monthViewHeaderHeight
              : -1,
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
              monthTextStyle: AppStyles.headingText(context).copyWith(
                color: HeliumColors.highestContrastTextColor(
                  context.colorScheme.primary,
                ),
              ),
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
            appointmentDisplayCount: _calendarItemsDisplayCount,
            showAgenda: Responsive.isMobile(context),
            agendaItemHeight: agendaHeight,
            monthCellStyle: MonthCellStyle(
              textStyle: AppStyles.smallSecondaryText(context),
              leadingDatesTextStyle: AppStyles.smallSecondaryText(context)
                  .copyWith(
                    color: context.colorScheme.onSurface.withValues(alpha: AppStyles.mutedTextAlpha),
                  ),
              trailingDatesTextStyle: AppStyles.smallSecondaryText(context)
                  .copyWith(
                    color: context.colorScheme.onSurface.withValues(alpha: AppStyles.mutedTextAlpha),
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
                ? MonthAppointmentDisplayMode.none
                : MonthAppointmentDisplayMode.appointment,
            dayFormat: HeliumDateTime.dayNameShortPattern,
          ),
          timeSlotViewSettings: TimeSlotViewSettings(
            minimumAppointmentDuration: const Duration(minutes: 32),
            timeTextStyle: AppStyles.smallSecondaryText(context).copyWith(
              color: context.colorScheme.onSurface.withValues(alpha: AppStyles.mutedTextAlpha),
            ),
            dayFormat: HeliumDateTime.dayNameShortPattern,
            timeFormat: HeliumTime.timeRulerPattern,
            timeIntervalHeight: Responsive.isMobile(context) ? 43 : 60,
            numberOfDaysInView: _currentView == PlannerView.threeDay ? 3 : -1,
          ),
          loadMoreWidgetBuilder: _loadMoreWidgetBuilder,
          monthCellBuilder: Responsive.isMobile(context)
              ? _buildMobileMonthCell
              : null,
          appointmentBuilder: _buildCalendarItem,
          onDragStart: _onCalendarDragStart,
          onDragEnd: _dropCalendarItem,
          onAppointmentResizeEnd: _resizeCalendarItem,
          onSelectionChanged: _onCalendarSelectionChanged,
          onTap: _onCalendarTap,
          onViewChanged: (ViewChangedDetails details) {
            _visibleDates = details.visibleDates;
            if (!mounted) return;

            // Defer setState because onViewChanged fires during SfCalendar's
            // internal rendering; calling setState mid-paint would crash
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              setState(() {});
            });
          },
        );

        final weekNumberTextStyle = AppStyles.smallSecondaryTextLight(context);
        final weekNumberLabel = SfLocalizations.of(context).weeknumberLabel;
        final plannerCalendar = usesCustomWeekColumn
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: WeekColumn.widthFor(
                      context,
                      label: weekNumberLabel,
                      textStyle: weekNumberTextStyle,
                    ),
                    child: WeekColumn(
                      visibleDates: _visibleDates,
                      headerHeight: _monthViewHeaderHeight,
                      label: weekNumberLabel,
                      textStyle: weekNumberTextStyle,
                    ),
                  ),
                  Expanded(child: calendar),
                ],
              )
            : calendar;

        if (constraints.maxHeight.isInfinite) {
          if (_currentView == PlannerView.agenda) {
            return _buildAgendaPrintList(agendaHeight);
          }

          // During capture the OverflowBox removes the height constraint.
          // Size week/day to one Portrait Letter content area (720pt ×
          // 540pt = 4:3), then subtract the calendar header height so that
          // header + calendar together fill exactly one page.
          // Header breakdown: SizedBox(48) + ShadowContainer(top:4, bottom:4)
          //                   + Padding(bottom:12) = 68px.
          const double letterPortraitContentAspect = 720.0 / 540.0;
          const double calendarHeaderHeight = 68.0;
          return SizedBox(
            height:
                constraints.maxWidth * letterPortraitContentAspect -
                calendarHeaderHeight,
            child: ScrollbarTheme(
              data: const ScrollbarThemeData(
                thumbColor: WidgetStatePropertyAll(Colors.transparent),
                trackColor: WidgetStatePropertyAll(Colors.transparent),
                trackBorderColor: WidgetStatePropertyAll(Colors.transparent),
              ),
              child: plannerCalendar,
            ),
          );
        }

        if (_currentView == PlannerView.agenda) {
          _loadAgendaWeek();
        }

        return plannerCalendar;
      },
    );
  }

  String? _agendaPrintLabel() {
    if (_currentView != PlannerView.agenda || !PrintableArea.capturing.value) {
      return null;
    }
    final (firstDay, lastDay) = _agendaWeek(_calendarController.displayDate!);
    return HeliumDateTime.formatDateRange(firstDay, lastDay);
  }

  Widget _buildAgendaPrintList(double itemHeight) {
    final (firstDay, lastDay) = _agendaWeek(_calendarController.displayDate!);
    return PlannerAgendaPrintList(
      firstDay: firstDay,
      lastDay: lastDay,
      today: DateTime.now(),
      itemHeight: itemHeight,
      itemsForDay: _plannerItemDataSource!.getItemsForDay,
      itemBuilder: (item, day, width) => _buildCalendarItemWidget(
        plannerItem: item,
        width: width,
        height: itemHeight,
        isInAgenda: true,
        completedOverride: item is HomeworkModel
            ? _plannerItemDataSource!.completedOverrides[item.id]
            : null,
        occurrenceDate: day,
      ),
    );
  }

  (DateTime, DateTime) _agendaWeek(DateTime displayDate) {
    final firstDay = HeliumDateTime.startOfWeek(
      displayDate,
      userSettings.weekStartsOn,
    );
    return (
      firstDay,
      DateTime(firstDay.year, firstDay.month, firstDay.day + 6),
    );
  }

  void _loadAgendaWeek() {
    final displayDate = _calendarController.displayDate;
    if (displayDate == null) return;

    final (firstDay, lastDay) = _agendaWeek(displayDate);
    if (firstDay == _agendaLoadedWeek) return;
    _agendaLoadedWeek = firstDay;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _plannerItemDataSource?.handleLoadMore(firstDay, lastDay);
    });
  }

  bool _openPlannerItem(
    PlannerItemBaseModel plannerItem, {
    DateTime? occurrenceDate,
    bool? hideWebsiteLink,
  }) {
    // Clear any Syncfusion slot selection that may have been triggered by the
    // tap so a calendar item tap never leaves a visible selection highlight.
    // Exception: mobile month view relies on the selected day to render the
    // day's item list below the grid — clearing it would leave the user
    // staring at an empty-state after closing the dialog.
    final isMobileMonthView =
        _currentView == PlannerView.month && Responsive.isMobile(context);
    if (!isMobileMonthView) {
      _calendarController.selectedDate = null;
    }

    if (_isLockedCalendarInteractionItem(plannerItem)) {
      _showLockedItemActions(
        plannerItem,
        occurrenceDate ?? plannerItem.start,
        hideWebsiteLink: hideWebsiteLink,
      );
      return false;
    }

    final int? eventId = plannerItem is EventModel ? plannerItem.id : null;
    final occurrenceStart = PlannerHelper.isRepeatingItem(plannerItem)
        ? _occurrenceOf(plannerItem, occurrenceDate ?? plannerItem.start).start
        : null;
    final int? homeworkId = plannerItem is HomeworkModel
        ? plannerItem.id
        : null;

    _deferredOpenItem = null;
    _deferredOpenAction = null;

    final hasPendingWrite =
        (homeworkId != null && _hasPendingCompletionWrite(homeworkId)) ||
        _plannerItemDataSource!.hasTimeOverride(plannerItem);

    if (hasPendingWrite) {
      _deferredOpenItem = plannerItem;
      _deferredOpenAction = () {
        if (!mounted) return;
        showPlannerItemAdd(
          context,
          eventId: eventId,
          homeworkId: homeworkId,
          occurrenceStart: occurrenceStart,
          isEdit: true,
          isNew: false,
        );
      };
      return false;
    }

    showPlannerItemAdd(
      context,
      eventId: eventId,
      homeworkId: homeworkId,
      occurrenceStart: occurrenceStart,
      isEdit: true,
      isNew: false,
    );

    return true;
  }

  Widget _buildCalendarHeader() {
    final isMobile = Responsive.isMobile(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ShadowContainer(
        padding: EdgeInsets.only(
          left: isMobile
              ? AppConstants.denseContainerContentInset
              : AppConstants.containerContentInset,
          right: isMobile
              ? AppConstants.denseContainerContentInset
              : AppConstants.containerContentInset,
          top: 4,
          bottom: 4,
        ),
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
                        PrintHidden(
                          child: KeyedSubtree(
                            key: const Key(PlannerScreen.todayButtonKey),
                            child: PlannerTodayButton(
                              showLabel: !isMobile,
                              buttonKey: _todayButtonKey,
                              onPressed: _goToToday,
                            ),
                          ),
                        ),
                        PlannerDateNavigator(
                          currentView: _currentView,
                          calendarController: _calendarController,
                          onOpenDatePicker: _openDatePicker,
                          labelOverride: _agendaPrintLabel(),
                        ),
                      ],
                    ),
                  ),
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: PrintHidden(
                        child: _buildFilterArea(
                          containerWidth: constraints.maxWidth,
                        ),
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

  Widget _buildFilterArea({double? containerWidth}) {
    final isMobile = Responsive.isMobile(context);
    final isDesktop = Responsive.isDesktop(context);

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

    if (isDesktop) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildFilterAndSearchButtons(hideSearchButton: true),
          const SizedBox(width: 8),
          SizedBox(
            width: 250,
            child: _buildSearchField(showCloseButton: false),
          ),
        ],
      );
    }

    return AnimatedContainer(
      duration: MotionService().effectiveDuration(
        AppConstants.uiAnimationDuration,
      ),
      width: expandedToolbarWidth,
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          AnimatedOpacity(
            duration: MotionService().effectiveDuration(
              AppConstants.uiAnimationDuration,
            ),
            opacity: _isSearchExpanded ? 0.0 : 1.0,
            child: IgnorePointer(
              ignoring: _isSearchExpanded,
              child: _buildFilterAndSearchButtons(),
            ),
          ),
          AnimatedPositioned(
            duration: MotionService().effectiveDuration(
              AppConstants.uiAnimationDuration,
            ),
            curve: Curves.easeInOut,
            onEnd: _onSearchExpandEnd,
            right: 0,
            width: _isSearchExpanded ? expandedToolbarWidth : 46,
            child: AnimatedOpacity(
              duration: MotionService().effectiveDuration(
                AppConstants.uiAnimationDuration,
              ),
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

  Widget _buildSearchField({bool showCloseButton = true}) {
    return TapRegion(
      onTapOutside: showCloseButton
          ? (_) {
              if (_isSearchExpanded) {
                setState(() {
                  _isSearchExpanded = false;
                  _searchFocusNode.unfocus();
                });
              }
            }
          : null,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Only show content when width is large enough (during/after animation)
          final showContent = constraints.maxWidth > 200;

          return ClipRect(
            child: showContent
                ? Row(
                    children: [
                      Expanded(
                        child: HeliumSearchField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          onChanged: _onSearchTextFieldChanged,
                          onTapOutside: (_) {},
                        ),
                      ),
                      if (showCloseButton) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _isSearchExpanded = false;
                              _searchFocusNode.unfocus();
                            });
                          },
                          icon: Icon(
                            Icons.keyboard_arrow_right,
                            color: context.colorScheme.primary,
                            size: Responsive.getIconSize(
                              context,
                              mobile: 20,
                              tablet: 22,
                              desktop: 24,
                            ),
                          ),
                          tooltip: AppLocalizations.of(context).plannerCollapseTooltip,
                          padding: EdgeInsets.zero,
                          style: IconButton.styleFrom(
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ],
                  )
                : const SizedBox.shrink(),
          );
        },
      ),
    );
  }

  Widget _buildFilterAndSearchButtons({bool hideSearchButton = false}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 200) {
          return const SizedBox.shrink();
        }

        // Wrap in ListenableBuilder to rebuild when filters change
        if (_plannerItemDataSource == null) {
          return _buildFilterButtonsRow(hideSearchButton: hideSearchButton);
        }

        return ListenableBuilder(
          listenable: _plannerItemDataSource!.changeNotifier,
          builder: (context, _) =>
              _buildFilterButtonsRow(hideSearchButton: hideSearchButton),
        );
      },
    );
  }

  Widget _buildFilterButtonsRow({bool hideSearchButton = false}) {
    final double buttonGap = Responsive.isSlimMobile(context)
        ? 2
        : (Responsive.isMobile(context) ? 4 : 8);
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Builder(
          builder: (context) {
            return IconButton.outlined(
              key: const Key(PlannerScreen.viewSwitcherButtonKey),
              onPressed: () => _openViewMenu(context),
              tooltip: AppLocalizations.of(context).plannerChangeViewTooltip,
              icon: const Icon(Icons.calendar_month_outlined),
              style: IconButton.styleFrom(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                minimumSize: Size(
                  PlannerDateNavigator.headerButtonSize(context),
                  PlannerDateNavigator.headerButtonSize(context),
                ),
                side: BorderSide(color: context.colorScheme.primary),
              ),
            );
          },
        ),
        SizedBox(width: buttonGap),
        Builder(
          builder: (context) {
            final hasFilters =
                PlannerFilterMenuContent.hasCoursesFilter(
                  _plannerItemDataSource,
                ) ||
                PlannerFilterMenuContent.hasStatusFilters(
                  _plannerItemDataSource,
                );
            return IconButton.outlined(
              key: const Key(PlannerScreen.filterButtonKey),
              onPressed: () => _openFilterMenu(context),
              tooltip: AppLocalizations.of(context).plannerFiltersTitle,
              icon: const Icon(Icons.filter_alt_outlined),
              style: IconButton.styleFrom(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                minimumSize: Size(
                  PlannerDateNavigator.headerButtonSize(context),
                  PlannerDateNavigator.headerButtonSize(context),
                ),
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
        if (!hideSearchButton) ...[
          SizedBox(width: buttonGap),
          Builder(
            builder: (context) {
              final hasSearchQuery = _hasSearchQuery();
              return IconButton.outlined(
                key: const Key(PlannerScreen.searchButtonKey),
                onPressed: () {
                  setState(() {
                    _isFilterExpanded = false;
                    _isSearchExpanded = true;
                  });
                },
                icon: Icon(Icons.search, semanticLabel: AppLocalizations.of(context).plannerSearchLabel),
                style: IconButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  minimumSize: Size(
                    PlannerDateNavigator.headerButtonSize(context),
                    PlannerDateNavigator.headerButtonSize(context),
                  ),
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
      ],
    );
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
      firstDate: HeliumDateTime.earliestPickableDate(),
      lastDate: HeliumDateTime.latestPickableDate(),
      confirmText: AppLocalizations.of(context).commonSelectButton,
    );

    if (picked == null || !mounted) return;

    _jumpToDate(picked, setSelectedDate: true);
  }

  void _logViewChange(PlannerView view) {
    unawaited(
      AnalyticsService().logEvent(
        name: AnalyticsEvent.plannerViewChange,
        parameters: {
          'category': AnalyticsCategory.featureInteraction.value,
          'view': view.name,
        },
      ),
    );
  }

  void _changeView(PlannerView newView) {
    _log.info('View changed: $_currentView --> $newView');
    final isEnteringNonCalendarView = (newView == PlannerView.todos);
    final wasInNonCalendarView =
        _previousView != null && _previousView == PlannerView.todos;
    final isEnteringCalendarView =
        (newView == PlannerView.month ||
        newView == PlannerView.week ||
        newView == PlannerView.threeDay ||
        newView == PlannerView.day);
    final isLeavingMonthView = _currentView == PlannerView.month;

    // Clear auto-select tracking when leaving month view on mobile.
    // Note: we intentionally do NOT restore selectedDate to null here.
    // Syncfusion's _SelectionPainter crashes (NoSuchMethodError on null check)
    // if selectedDate is nullified while a repaint is already pending. The
    // auto-selected date simply remains selected when leaving month view.
    if (isLeavingMonthView && _mobileMonthAutoSelectApplied) {
      _mobileMonthAutoSelectApplied = false;
    }

    // Store/restore calendar state when entering/leaving Todos view
    if (isEnteringNonCalendarView && !wasInNonCalendarView) {
      _storedSelectedDate = _calendarController.selectedDate;
      _storedDisplayDate = _calendarController.displayDate;
      _todosDataGridKey.currentState?.resetForViewChange();
    }

    if (isEnteringCalendarView && wasInNonCalendarView) {
      if (_storedSelectedDate != null) {
        _calendarController.selectedDate = _storedSelectedDate;
      }
      if (_storedDisplayDate != null) {
        _calendarController.displayDate = _storedDisplayDate;
      }
    }

    // Sync displayDate to selectedDate when switching calendar views
    if (isEnteringCalendarView &&
        !wasInNonCalendarView &&
        _calendarController.selectedDate != null) {
      _calendarController.displayDate = _calendarController.selectedDate;
    }

    _previousView = _currentView;
    _currentView = newView;

    _plannerItemDataSource?.isMonthView = newView == PlannerView.month;

    // Todos is a custom view, not an SfCalendar view
    if (newView != PlannerView.todos) {
      _calendarController.view = PlannerHelper.mapHeliumViewToSfCalendarView(
        newView,
      );
    }

    // On mobile month view, auto-select a date so the agenda is always shown
    if (Responsive.isMobile(context) &&
        newView == PlannerView.month &&
        _calendarController.selectedDate == null) {
      _mobileMonthAutoSelectApplied = true;
      final now = DateTime.now();
      _calendarController.selectedDate = PlannerHelper.selectionWithCurrentHour(
        date: now,
        now: now,
        timeZone: userSettings.timeZone,
      );
    }
  }

  void _calendarViewChanged() {
    final sfView = _calendarController.view!;

    // Several PlannerViews share CalendarView.day, so a controller already showing the
    // view we are on carries no new information — only a genuine change does.
    if (PlannerHelper.mapHeliumViewToSfCalendarView(_currentView) == sfView) {
      return;
    }

    final newView = PlannerHelper.mapSfCalendarViewToHeliumView(sfView);
    if (newView != _currentView) {
      _logViewChange(newView);
      setState(() {
        _changeView(newView);
      });
    }
  }

  void _onCalendarTap(CalendarTapDetails details) {
    if (details.targetElement != CalendarElement.allDayPanel) return;
    if (details.date == null) return;

    _log.info('All-day panel tapped: ${details.date}');

    _calendarController.selectedDate = PlannerHelper.selectionWithCurrentHour(
      date: details.date!,
      now: DateTime.now(),
      timeZone: userSettings.timeZone,
    );
  }

  void _onCalendarSelectionChanged(CalendarSelectionDetails details) {
    if (details.date == null) return;

    _log.info('Selection changed: ${details.date}');

    if (_mobileMonthAutoSelectApplied) {
      _mobileMonthAutoSelectApplied = false;
    }

    if (_currentView == PlannerView.month) {
      _calendarController.selectedDate = PlannerHelper.selectionWithCurrentHour(
        date: details.date!,
        now: DateTime.now(),
        timeZone: userSettings.timeZone,
      );
    }
  }

  FutureBuilder<void> _loadMoreWidgetBuilder(
    BuildContext context,
    LoadMoreCallback loadMorePlannerItems,
  ) {
    return FutureBuilder<void>(
      future: loadMorePlannerItems(),
      builder: (context, snapShot) {
        // Stop the spinner on error, else SfCalendar hangs on it indefinitely.
        if (snapShot.hasError) {
          final error = snapShot.error;
          final message = error is HeliumException
              ? error.displayMessage
              : HeliumException.unexpectedErrorMessage;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) showSnackBar(context, message, type: SnackType.error);
          });
          return const SizedBox.shrink();
        }
        return const Center(child: LoadingIndicator(expanded: false));
      },
    );
  }

  void _onSearchTextFieldChanged(String value) {
    if (value.isEmpty) {
      _searchLogged = false;
    } else if (!_searchLogged) {
      _searchLogged = true;
      final termWeek = CourseGroupHelpers.currentTermWeek(
        _courseGroups,
        userSettings.timeZone,
      );
      unawaited(
        AnalyticsService().logEvent(
          name: AnalyticsEvent.search,
          parameters: {
            'category': AnalyticsCategory.featureInteraction.value,
            'screen': AppRoute.plannerScreen,
            'term_week': ?termWeek,
          },
        ),
      );
    }
    _plannerItemDataSource!.setSearchQuery(value);
  }

  void _onFilterApplied(String filter) {
    if (!_loggedFilterKinds.add(filter)) return;
    final termWeek = CourseGroupHelpers.currentTermWeek(
      _courseGroups,
      userSettings.timeZone,
    );
    unawaited(
      AnalyticsService().logEvent(
        name: AnalyticsEvent.filterApply,
        parameters: {
          'category': AnalyticsCategory.featureInteraction.value,
          'screen': AppRoute.plannerScreen,
          'filter': filter,
          'term_week': ?termWeek,
        },
      ),
    );
  }

  String? _termWeekOf(HomeworkModel homework) {
    final group = _courseGroupsById[homework.courseGroup];
    return group == null
        ? null
        : CourseGroupHelpers.termWeekOf(group, userSettings.timeZone);
  }

  void _dropCalendarItem(AppointmentDragEndDetails dropDetails) {
    _setCalendarInteractionInProgress(false);

    if (_dragRejected) {
      _dragRejected = false;
      _plannerItemDataSource!.resetAppointments();
      return;
    }

    if (dropDetails.appointment == null) {
      return;
    }

    final PlannerItemBaseModel plannerItem =
        dropDetails.appointment as PlannerItemBaseModel;

    // Reset SfCalendar's internal list unconditionally for locked items —
    // including cancelled drags where droppingTime is null. SfCalendar inserts
    // a rogue copy of the recurring appointment into its internal list on every
    // drag-end, so the reset must fire regardless of whether the drop landed on
    // a valid time slot.
    if (_isLockedCalendarInteractionItem(plannerItem)) {
      _plannerItemDataSource!.resetAppointments();
      if (dropDetails.droppingTime != null) {
        _showLockedItemActions(
          plannerItem,
          _pointerDownItem?.start ?? dropDetails.droppingTime!,
          hideWebsiteLink: false,
        );
      }
      return;
    }

    if (PlannerHelper.isRepeatingItem(plannerItem)) {
      _plannerItemDataSource!.resetAppointments();
    }

    if (dropDetails.droppingTime == null) {
      return;
    }

    if (plannerItem is HomeworkModel || plannerItem is EventModel) {
      final (currentStart, currentEnd) = _plannerItemDataSource!.currentTimesOf(plannerItem);
      final (start, end) = PlannerHelper.droppedTimeRange(
        plannerItem: plannerItem,
        currentStart: currentStart,
        currentEnd: currentEnd,
        dropDetails: dropDetails,
        userSettings: userSettings,
        currentView: _currentView,
      );

      unawaited(_applyMove(plannerItem, start, end, action: RecurrenceScopeAction.move));
    }
  }

  void _onCalendarDragStart(AppointmentDragStartDetails dragDetails) {
    _plannerItemDataSource?.thawChangeNotifications();
    _dragRejected = false;
    if (dragDetails.appointment is PlannerItemBaseModel) {
      final item = dragDetails.appointment as PlannerItemBaseModel;
      final hovered = _pointerDownHoveredItem;
      final isMismatch = hovered != null && hovered != item;

      if (isMismatch) {
        _log.warning(
          'Calendar drag mismatch — rejecting: '
          'sf=${item.id} hover=${hovered.id}',
        );
        _dragRejected = true;
        _plannerItemDataSource!.resetAppointments();
        return;
      } else if (hovered == null) {
        _log.warning('Calendar drag no hover — sf=${item.id}');
      }
      if (_isLockedCalendarInteractionItem(item)) {
        // Locked items are not draggable; triggering a rebuild mid-drag corrupts
        // SfCalendar's internal gesture state.
        return;
      }
    }
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
      final (start, end) = PlannerHelper.resizedTimeRange(
        plannerItem: plannerItem,
        resizeDetails: resizeDetails,
        userSettings: userSettings,
      );

      if (PlannerHelper.isRepeatingItem(plannerItem)) {
        _plannerItemDataSource!.resetAppointments();
      }

      unawaited(_applyMove(plannerItem, start, end, showEndTime: true, action: RecurrenceScopeAction.edit));
    } else if (_isLockedCalendarInteractionItem(plannerItem)) {
      _plannerItemDataSource!.resetAppointments();
      _showLockedItemActions(
        plannerItem,
        _pointerDownItem?.start ?? resizeDetails.startTime!,
        hideWebsiteLink: false,
      );
    }
  }

  void _showDetachedOccurrence(
    PlannerItemBaseModel detached, {
    required int seriesId,
    required PlannerItemBaseModel? series,
  }) {
    _updateOrRemove(detached.plannerItemType, seriesId, series: series);
    _plannerItemDataSource!.addPlannerItem(detached);
  }

  void _updateOrRemove(PlannerItemType type, int id, {required PlannerItemBaseModel? series}) {
    if (series != null) {
      _plannerItemDataSource!.updatePlannerItem(series);
    } else {
      _plannerItemDataSource!.removePlannerItem(type, id);
    }
  }

  Future<void> _applyMove(
    PlannerItemBaseModel plannerItem,
    DateTime start,
    DateTime end, {
    required RecurrenceScopeAction action,
    bool? showEndTime,
  }) async {
    if (PlannerHelper.isRepeatingItem(plannerItem)) {
      await _applyRecurringMove(plannerItem, start, end, action: action, showEndTime: showEndTime);
      return;
    }

    _plannerItemDataSource!.setTimeOverride(
      plannerItem,
      start.toIso8601String(),
      end.toIso8601String(),
    );

    if (plannerItem is HomeworkModel) {
      _warnIfHomeworkOutsideDateRange(plannerItem, start, end);

      context.read<PlannerItemBloc>().add(
        UpdateHomeworkEvent(
          origin: EventOrigin.screen,
          courseGroupId: plannerItem.courseGroup,
          courseId: plannerItem.course.id,
          homeworkId: plannerItem.id,
          request: HomeworkRequestModel(
            start: start.toIso8601String(),
            end: end.toIso8601String(),
            showEndTime: showEndTime,
          ),
        ),
      );
    } else if (plannerItem is EventModel) {
      context.read<PlannerItemBloc>().add(
        UpdateEventEvent(
          origin: EventOrigin.screen,
          id: plannerItem.id,
          request: EventRequestModel(
            start: start.toIso8601String(),
            end: end.toIso8601String(),
            showEndTime: showEndTime,
          ),
        ),
      );
    }
  }

  Future<void> _applyRecurringMove(
    PlannerItemBaseModel plannerItem,
    DateTime start,
    DateTime end, {
    required RecurrenceScopeAction action,
    bool? showEndTime,
  }) async {
    final pressed = _pointerDownItem;
    final occurrence = pressed != null && pressed == plannerItem ? pressed : plannerItem;
    final scope = await showRecurrenceScopeDialog(
      context: context,
      action: action,
      isEvent: plannerItem is EventModel,
      thisDetail: AppLocalizations.of(context).plannerKeepsRemindersDetail,
    );
    if (scope == null || !mounted) return;

    final onlyThisOccurrence = scope == RecurrenceScope.thisOccurrence;
    if (plannerItem is HomeworkModel) {
      _warnIfHomeworkOutsideDateRange(plannerItem, start, end);

      context.read<PlannerItemBloc>().add(
        UpdateHomeworkEvent(
          origin: EventOrigin.screen,
          courseGroupId: plannerItem.courseGroup,
          courseId: plannerItem.course.id,
          homeworkId: plannerItem.id,
          request: HomeworkRequestModel(
            start: start.toIso8601String(),
            end: end.toIso8601String(),
            showEndTime: showEndTime,
          ),
          occurrenceStart: occurrence.start,
          onlyThisOccurrence: onlyThisOccurrence,
        ),
      );
    } else if (plannerItem is EventModel) {
      context.read<PlannerItemBloc>().add(
        UpdateEventEvent(
          origin: EventOrigin.screen,
          id: plannerItem.id,
          request: EventRequestModel(
            start: start.toIso8601String(),
            end: end.toIso8601String(),
            showEndTime: showEndTime,
          ),
          occurrenceStart: occurrence.start,
          onlyThisOccurrence: onlyThisOccurrence,
        ),
      );
    }
  }

  Future<bool> _deleteSeriesItem(PlannerItemBaseModel plannerItem) async {
    final scope = await showRecurrenceScopeDialog(
      context: context,
      action: RecurrenceScopeAction.delete,
      isEvent: plannerItem is EventModel,
      allDetail: AppLocalizations.of(context).plannerDeletesAttachmentsNoteDetail,
    );
    if (scope == null || !mounted) return false;

    final occurrenceStart = scope == RecurrenceScope.all ? null : plannerItem.start;
    if (plannerItem is HomeworkModel) {
      context.read<PlannerItemBloc>().add(
        DeleteHomeworkEvent(
          origin: EventOrigin.screen,
          courseGroupId: plannerItem.courseGroup,
          courseId: plannerItem.course.id,
          homeworkId: plannerItem.id,
          occurrenceStart: occurrenceStart,
        ),
      );
    } else if (plannerItem is EventModel) {
      context.read<PlannerItemBloc>().add(
        DeleteEventEvent(
          origin: EventOrigin.screen,
          id: plannerItem.id,
          occurrenceStart: occurrenceStart,
        ),
      );
    }
    return true;
  }

  Future<bool> _deletePlannerItem(
    BuildContext context,
    PlannerItemBaseModel plannerItem,
  ) async {
    if (PlannerHelper.isRepeatingItem(plannerItem)) {
      return _deleteSeriesItem(plannerItem);
    }

    final Function(PlannerItemBaseModel) onDelete;
    if (plannerItem is HomeworkModel) {
      onDelete = (h) {
        context.read<PlannerItemBloc>().add(
          DeleteHomeworkEvent(
            origin: EventOrigin.screen,
            courseGroupId: plannerItem.courseGroup,
            courseId: plannerItem.course.id,
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
      return false;
    }

    return showConfirmDeleteDialog(
      parentContext: context,
      item: plannerItem,
      label: plannerItem.title,
      additionalWarning: AppLocalizations.of(context).plannerDeletesAttachmentsNoteDetail,
      onDelete: onDelete,
    );
  }

  Widget _buildMobileMonthCell(BuildContext context, MonthCellDetails details) {
    return PlannerMobileMonthCell(details: details, userSettings: userSettings);
  }

  Widget _buildCalendarItem(
    BuildContext context,
    CalendarAppointmentDetails details,
  ) {
    if (details.isMoreAppointmentRegion) {
      return PlannerMoreIndicator(
        details: details,
        displayCount: _calendarItemsDisplayCount,
        onOpenDay: _openDayPopOutDialog,
      );
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
      // In month view (non-agenda), pass null so the timeline Container has no
      // fixed height — the outer SizedBox below enforces the correct height.
      height: (_currentView == PlannerView.month && !isInAgenda)
          ? null
          : details.bounds.height,
      isInAgenda: isInAgenda,
      completedOverride: homeworkId != null
          ? _plannerItemDataSource!.completedOverrides[homeworkId]
          : null,
      occurrenceDate: details.date,
    );
    // In month view (non-agenda), force a fixed item height. SfCalendar
    // stretches bounds to fill the cell when few items are present (too tall)
    // and may also compress bounds when many items are stacked (too short).
    // ClipRect + UnconstrainedBox lets the SizedBox win in both directions.
    if (_currentView == PlannerView.month && !isInAgenda) {
      calendarItemWidget = UnconstrainedBox(
        alignment: Alignment.topLeft,
        constrainedAxis: Axis.horizontal,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          height: PlannerMonthLayout.monthCalendarItemHeight,
          child: calendarItemWidget,
        ),
      );
    }
    // On touch devices, SfCalendar incorrectly reports calendarCell instead of
    // appointment for taps and long-presses on month-view calendar items. Handle
    // both directly on the widget to bypass this quirk (the same hit-test bug
    // also prevents SfCalendar from initiating drag-and-drop in month view on
    // touch, so consuming the long-press has no functional cost).
    // https://github.com/syncfusion/flutter-widgets/issues/2519
    // Skip for agenda-style items which handle taps internally via column zones.
    if (_currentView == PlannerView.month &&
        PlatformBehavior.usesTouchInteractions &&
        !isInAgenda) {
      calendarItemWidget = GestureDetector(
        onTap: () {
          Feedback.forTap(context);
          _openPlannerItem(plannerItem, occurrenceDate: details.date);
        },
        onLongPress: () {},
        child: calendarItemWidget,
      );
    }

    // Hover tracking for drag mismatch detection — see _onCalendarDragStart.
    // https://github.com/syncfusion/flutter-widgets/issues/2523
    calendarItemWidget = Listener(
      onPointerDown: (_) =>
          _pointerDownItem = _occurrenceOf(plannerItem, details.date),
      child: MouseRegion(
        onEnter: (_) => _lastHoveredItem = plannerItem,
        onExit: (_) {
          if (_lastHoveredItem == plannerItem) {
            _lastHoveredItem = null;
          }
        },
        child: calendarItemWidget,
      ),
    );

    return KeyedSubtree(
      key: ValueKey(
        'planner_item_${plannerItem.plannerItemType.name}_${plannerItem.id}${PlannerHelper.isRepeatingItem(plannerItem) ? '_${HeliumDateTime.formatDateForApi(details.date)}' : ''}',
      ),
      child: _buildPlannerItemTooltip(
        plannerItem: PlannerItemCalendarTile.isRecurring(plannerItem) ? _occurrenceOf(plannerItem, details.date) : plannerItem,
        isInAgendaStyle: isInAgenda,
        child: calendarItemWidget,
      ),
    );
  }

  void _showLockedItemActions(
    PlannerItemBaseModel plannerItem,
    DateTime occurrenceDate, {
    bool? hideWebsiteLink,
  }) {
    final whenLabel = _occurrenceWhenLabel(plannerItem, occurrenceDate);
    if (plannerItem is CourseScheduleEventModel) {
      final shouldHideWebsiteLink =
          hideWebsiteLink ??
          (_currentView == PlannerView.agenda ||
              (_currentView == PlannerView.month &&
                  Responsive.isMobile(context)));
      _showCourseScheduleEventDialog(
        plannerItem,
        occurrenceDate,
        whenLabel,
        hideWebsiteLink: shouldHideWebsiteLink,
      );
    } else if (plannerItem is ExternalCalendarEventModel) {
      _showExternalCalendarEventDialog(plannerItem, whenLabel);
    }
  }

  String _occurrenceWhenLabel(
    PlannerItemBaseModel item,
    DateTime occurrenceDate,
  ) {
    final occurrence = _occurrenceOf(item, occurrenceDate);
    return PlannerHelper.occurrenceWhenLabel(
      occurrence: occurrence,
      occurrenceDate: occurrenceDate,
      userSettings: userSettings,
    );
  }

  Widget _buildCalendarItemWidget({
    required PlannerItemBaseModel plannerItem,
    required double width,
    double? height,
    required bool isInAgenda,
    bool? completedOverride,
    DateTime? occurrenceDate,
  }) {
    return PlannerItemCalendarTile(
      plannerItem: plannerItem,
      width: width,
      height: height,
      isInAgenda: isInAgenda,
      completedOverride: completedOverride,
      occurrenceDate: occurrenceDate,
      plannerItemDataSource: _plannerItemDataSource,
      currentView: _currentView,
      timeZone: userSettings.timeZone,
      courses: _courses,
      onOpenPlannerItem: _openPlannerItem,
      onToggleCompleted: _onToggleCompleted,
    );
  }

  PlannerItemBaseModel _occurrenceOf(PlannerItemBaseModel item, DateTime date) {
    return _plannerItemDataSource?.occurrenceOn(item, date) ?? item;
  }

  bool _isLockedCalendarInteractionItem(PlannerItemBaseModel item) {
    return item is CourseScheduleEventModel || item is ExternalCalendarEventModel;
  }

  /// Suppresses tooltips for [_tooltipSuppressDelay] after any intentional
  /// user action. Resets the timer on each call so back-to-back actions
  /// (e.g., a drop followed immediately by a click) keep tooltips hidden for
  /// the full delay from the most recent action.
  void _suppressTooltipsTemporarily() {
    _tooltipSuppressTimer?.cancel();
    if (!mounted) return;
    if (!_isCalendarInteractionInProgress) {
      setState(() {
        _isCalendarInteractionInProgress = true;
      });
    }
    _tooltipSuppressTimer = Timer(_tooltipSuppressDelay, () {
      if (!mounted) return;
      setState(() {
        _isCalendarInteractionInProgress = false;
      });
    });
  }

  void _setCalendarInteractionInProgress(bool isInProgress) {
    if (isInProgress) {
      // Cancel any pending restore so the timer can't clear the flag mid-drag.
      _tooltipSuppressTimer?.cancel();
      _tooltipSuppressTimer = null;
      // setState here is safe — onDragStart fires after SfCalendar has already
      // resolved which appointment to drag, so a rebuild at this point won't
      // corrupt the hit-test result. The
      // rebuild causes _buildPlannerItemTooltip to return a bare child,
      // unmounting any visible Tooltip without needing an imperative dismissal.
      setState(() => _isCalendarInteractionInProgress = true);
    } else {
      _suppressTooltipsTemporarily();
    }
  }

  Widget _buildPlannerItemTooltip({
    required PlannerItemBaseModel plannerItem,
    required Widget child,
    bool isInAgendaStyle = false,
  }) {
    return PlannerItemTooltip(
      plannerItem: plannerItem,
      isInAgendaStyle: isInAgendaStyle,
      isSuppressed: _isCalendarInteractionInProgress,
      userSettings: userSettings,
      plannerItemDataSource: _plannerItemDataSource,
      courses: _courses,
      categoriesMap: _categoriesMap,
      externalCalendarsById: _externalCalendarsById,
      child: child,
    );
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

  void _showCourseScheduleEventDialog(
    CourseScheduleEventModel event,
    DateTime occurrenceDate,
    String whenLabel, {
    bool hideWebsiteLink = false,
  }) {
    final courseId = int.tryParse(event.ownerId);
    if (courseId == null) return;

    final course = _courses.firstWhereOrNull((c) => c.id == courseId);
    if (course == null) return;
    final schedule = course.schedules.firstWhere(
      (s) => s.id == event.scheduleId,
    );

    showCourseScheduleEventDialog(
      context: context,
      courseTitle: course.title,
      courseColor: course.color,
      occurrenceDate: occurrenceDate,
      whenLabel: whenLabel,
      actions: CourseScheduleEventActions(
        onSkip: (date) async {
          context.read<PlannerBloc>().add(
            SkipCourseOccurrenceEvent(
              origin: EventOrigin.dialog,
              course: course,
              date: date,
            ),
          );
        },
        onSkipMeeting:
            (_plannerItemDataSource?.courseMeetingCountOn(
                      course,
                      occurrenceDate,
                    ) ??
                    0) >
                1
            ? (date) async {
                context.read<PlannerBloc>().add(
                  SkipCourseScheduleOccurrenceEvent(
                    origin: EventOrigin.dialog,
                    course: course,
                    schedule: schedule,
                    date: date,
                  ),
                );
              }
            : null,
        websiteUrl: (!hideWebsiteLink && course.website != null)
            ? course.website.toString()
            : null,
        onEditSchedule: () {
          if (!mounted) return;
          context.go('${AppRoute.coursesScreen}/${event.ownerId}/schedule');
        },
      ),
    );
  }

  void _showExternalCalendarEventDialog(
    ExternalCalendarEventModel event,
    String whenLabel,
  ) {
    final calendarId = int.tryParse(event.ownerId);
    if (calendarId == null) return;

    final calendar = _externalCalendarsById[calendarId];
    if (calendar == null) return;

    showExternalCalendarEventDialog(
      context: context,
      calendarTitle: calendar.title,
      calendarColor: calendar.color,
      whenLabel: whenLabel,
      actions: ExternalCalendarEventActions(
        onManageCalendars: () {
          if (!mounted) return;
          context.push(
            '${BranchPathScope.of(context)}${AppRoute.settingScreen}/external-calendars',
          );
        },
        eventUrl: event.url?.toString(),
      ),
    );
  }

  /// Shows a warning if homework dates fall outside the course's date range
  void _warnIfHomeworkOutsideDateRange(
    HomeworkModel homework,
    DateTime newStart,
    DateTime newEnd,
  ) {
    if (PlannerHelper.isOutsideTodosWindow(
      HeliumDateTime.dateOnly(newStart),
      HeliumDateTime.lastDayOf(newEnd, allDay: homework.allDay),
      _courseGroups,
    )) {
      showSnackBar(context, AppLocalizations.of(context).plannerAssignmentMovedOutsideTodosMessage);
    }
  }

  void _openDayPopOutDialog(DateTime? date) {
    if (date == null || Responsive.isMobile(context)) return;

    showDialog(
      context: context,
      builder: (_) => PlannerDayPopOutDialog(
        date: date,
        dataSource: _plannerItemDataSource!,
        onPlannerItemTap: (context, plannerItem) {
          if (!PlannerHelper.shouldOpenOnItemTap(context)) {
            return false;
          }
          return _openPlannerItem(plannerItem, hideWebsiteLink: true);
        },
        itemBuilder: (context, plannerItem, completedOverride) {
          return _buildPlannerItemTooltip(
            plannerItem: plannerItem,
            isInAgendaStyle: true,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxHeight: PlannerItemCalendarTile.agendaHeightDesktop,
              ),
              child: _buildCalendarItemWidget(
                plannerItem: plannerItem,
                width: double.infinity,
                isInAgenda: true,
                completedOverride: completedOverride,
                occurrenceDate: date,
              ),
            ),
          );
        },
      ),
    );
  }

  void _populateScreenData(PlannerScreenDataFetched state) {
    _log.info(
      'Planner screen data loaded: ${state.courses.length} courses, '
      '${state.categories.length} categories',
    );
    setState(() {
      _courseGroups = state.courseGroups;
      _courses = state.courses;
      _categoriesMap
        ..clear()
        ..addAll({
          for (final category in state.categories) category.id: category,
        });
      _resourcesMap
        ..clear()
        ..addAll({for (final r in state.resources) r.id: r});
      _attachments
        ..clear()
        ..addAll(state.attachments);

      if (_plannerItemDataSource != null) {
        _applyScreenDataToDataSource();
      }

      _deduplicatedCategories
        ..clear()
        ..addAll(
          PlannerFilterMenuContent.deduplicateCategoriesByTitle(
            state.categories,
          ),
        );

      isLoading = false;
    });
  }

  void _applyScreenDataToDataSource() {
    _plannerItemDataSource!.courses = _courses;
    _plannerItemDataSource!.courseGroupsById = _courseGroupsById;
    _plannerItemDataSource!.categoriesMap = _categoriesMap;
    _plannerItemDataSource!.resourcesMap = _resourcesMap;
    _pushAttachments();
  }

  void _pushAttachments() {
    _plannerItemDataSource?.setAttachments(List.of(_attachments));
  }

  void _goToToday() {
    _log.info('Today button pressed (view: $_currentView)');
    if (_currentView == PlannerView.todos) {
      _todosDataGridKey.currentState?.goToToday();
    } else {
      // Device clock, for the same reason as the today highlight in
      // PlannerMobileMonthCell.
      _jumpToDate(DateTime.now(), offsetForVisibility: true);
    }
  }

  void _jumpToDate(
    DateTime date, {
    bool setSelectedDate = false,
    bool offsetForVisibility = false,
  }) {
    _log.fine('Jumping to date: $date (setSelected: $setSelectedDate)');
    final truncatedDate = DateTime(date.year, date.month, date.day, date.hour);
    final displayDate = offsetForVisibility
        ? HeliumDateTime.visibleAnchorFor(truncatedDate)
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

  void _onToggleCompleted(HomeworkModel homework, bool value, {DateTime? occurrenceDate}) {
    if (PlannerHelper.isRepeatingItem(homework)) {
      _completeOccurrence(
        occurrenceDate == null ? homework : _occurrenceOf(homework, occurrenceDate) as HomeworkModel,
      );
      return;
    }

    Feedback.forTap(context);

    _log.info('Homework ${homework.id} completion toggled: $value');

    _plannerItemDataSource!.setCompletedOverride(homework.id, value);

    _pendingToggleTimers[homework.id]?.cancel();
    _pendingToggleValues[homework.id] = value;
    _pendingToggleTimers[homework.id] = Timer(AppConstants.completionToggleDebounce, () {
      if (!mounted) return;
      final pendingValue = _pendingToggleValues.remove(homework.id);
      _pendingToggleTimers.remove(homework.id);
      if (pendingValue == null) return;

      final request = HomeworkRequestModel(completed: pendingValue);

      _inFlightCompletionCounts.update(
        homework.id,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
      context.read<PlannerItemBloc>().add(
        UpdateHomeworkEvent(
          origin: EventOrigin.screen,
          courseGroupId: homework.courseGroup,
          courseId: homework.course.id,
          homeworkId: homework.id,
          request: request,
        ),
      );
    });
  }

  void _completeOccurrence(HomeworkModel occurrence) {
    if (!_completingOccurrences.add(_occurrenceKey(occurrence))) return;
    Feedback.forTap(context);

    _log.info('Homework ${occurrence.id} occurrence completed');

    context.read<PlannerItemBloc>().add(
      UpdateHomeworkEvent(
        origin: EventOrigin.screen,
        courseGroupId: occurrence.courseGroup,
        courseId: occurrence.course.id,
        homeworkId: occurrence.id,
        request: HomeworkRequestModel(completed: true),
        previousHomework: occurrence,
        occurrenceStart: occurrence.start,
        onlyThisOccurrence: true,
      ),
    );
  }

  (int, int) _occurrenceKey(HomeworkModel occurrence) =>
      (occurrence.id, occurrence.start.millisecondsSinceEpoch);

  bool _isAwaitingConflictResolution(HomeworkUpdated state) =>
      state.linkedNoteSave?.isConflict ?? false;

  bool _hasPendingCompletionWrite(int homeworkId) =>
      _pendingToggleTimers.containsKey(homeworkId) ||
      _inFlightCompletionCounts.containsKey(homeworkId);

  void _decrementInFlightCompletion(int homeworkId) {
    final remaining = (_inFlightCompletionCounts[homeworkId] ?? 0) - 1;
    if (remaining > 0) {
      _inFlightCompletionCounts[homeworkId] = remaining;
    } else {
      _inFlightCompletionCounts.remove(homeworkId);
    }
  }

  void _executeDeferredOpen(PlannerItemBaseModel plannerItem) {
    if (_deferredOpenItem != plannerItem) return;
    final action = _deferredOpenAction;
    _deferredOpenItem = null;
    _deferredOpenAction = null;
    if (action == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => action());
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

  void _updatePlannerItemReminders(
    int itemId,
    dynamic reminderData, {
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

    final updatedReminders = List<IdOrEntity<ReminderModel>>.from(
      plannerItem.reminders,
    );

    if (isAdd) {
      final reminder = reminderData as ReminderModel;
      final entry = IdOrEntity<ReminderModel>(
        id: reminder.id,
        entity: reminder,
      );
      final existingIdx = updatedReminders.indexWhere(
        (r) => r.id == reminder.id,
      );
      if (existingIdx >= 0) {
        updatedReminders[existingIdx] = entry;
      } else {
        updatedReminders.add(entry);
      }
    } else {
      final reminderId = reminderData as int;
      updatedReminders.removeWhere((r) => r.id == reminderId);
    }

    final PlannerItemBaseModel updatedItem = isHomework
        ? (plannerItem as HomeworkModel).copyWith(reminders: updatedReminders)
        : (plannerItem as EventModel).copyWith(reminders: updatedReminders);

    _plannerItemDataSource!.updatePlannerItem(updatedItem);
  }

  PlannerItemBaseModel? _findReminderOwner(int reminderId) {
    return _plannerItemDataSource!.allHomeworks.firstWhereOrNull(
          (h) => h.reminders.any((r) => r.id == reminderId),
        ) ??
        _plannerItemDataSource!.allEvents.firstWhereOrNull(
          (e) => e.reminders.any((r) => r.id == reminderId),
        );
  }

  void _openFilterMenu(BuildContext context) {
    final List<CourseModel> displayCourses =
        PlannerHelper.sortByGroupStartThenByTitle(_courses, _courseGroups);

    final isMobile = Responsive.isMobile(context);

    showHeliumMenu(
      context: context,
      anchorContext: context,
      builder: (context, setSheetState) => PlannerFilterMenuContent(
        plannerItemDataSource: _plannerItemDataSource,
        currentView: _currentView,
        userSettings: userSettings,
        displayCourses: displayCourses,
        isMobile: isMobile,
        deduplicatedCategories: _deduplicatedCategories,
        categoriesMap: _categoriesMap,
        externalCalendarsById: _externalCalendarsById,
        setSheetState: setSheetState,
        onFilterApplied: _onFilterApplied,
      ),
    );
  }

  Widget _buildViewMenuContent(
    BuildContext menuContext,
    StateSetter setMenuState, {
    required bool isMobile,
  }) {
    return HeliumMenuContent(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          RadioGroup<PlannerView>(
            groupValue: _currentView,
            onChanged: (value) {
              if (value != _currentView) _logViewChange(value!);
              setState(() {
                _changeView(value!);
              });

              Navigator.pop(menuContext);

              if (isMobile) {
                setState(() {
                  _isFilterExpanded = false;
                });
              }
            },
            child: Column(
              children: List.generate(PlannerView.values.length, (index) {
                return RadioListTile<PlannerView>(
                  key: Key(
                    PlannerScreen.viewOptionKey(PlannerView.values[index]),
                  ),
                  title: Text(
                    PlannerView.values[index].label,
                    style: AppStyles.formText(menuContext),
                  ),
                  value: PlannerView.values[index],
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                  contentPadding: const EdgeInsets.only(left: 4),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  void _openViewMenu(BuildContext buttonContext) {
    final isMobile = Responsive.isMobile(context);

    showHeliumMenu(
      context: context,
      anchorContext: buttonContext,
      builder: (ctx, ss) => _buildViewMenuContent(ctx, ss, isMobile: isMobile),
    );
  }

  Widget _buildTodosView() {
    return TodosDataGrid(
      key: _todosDataGridKey,
      dataSource: _plannerItemDataSource!,
      onTap: _openPlannerItem,
      onToggleCompleted: _onToggleCompleted,
      onDelete: _deletePlannerItem,
    );
  }

}
