import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/data/models/planner/course_schedule_model.dart';
import 'package:heliumapp/presentation/features/courses/bloc/course_bloc.dart';
import 'package:heliumapp/presentation/features/courses/bloc/course_event.dart';
import 'package:heliumapp/presentation/features/courses/bloc/course_state.dart';
import 'package:heliumapp/presentation/features/courses/constants/schedule_constants.dart';
import 'package:heliumapp/presentation/features/courses/dialogs/course_exceptions_dialog.dart';
import 'package:heliumapp/presentation/features/planner/dialogs/confirm_delete_dialog.dart';
import 'package:heliumapp/presentation/features/courses/widgets/schedule_card.dart';
import 'package:heliumapp/presentation/features/courses/widgets/schedule_editor_screen.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/base_event.dart';
import 'package:heliumapp/presentation/ui/components/helium_elevated_button.dart';
import 'package:heliumapp/presentation/ui/components/helium_icon_button.dart';
import 'package:heliumapp/presentation/ui/feedback/empty_card.dart';
import 'package:heliumapp/presentation/ui/feedback/error_card.dart';
import 'package:heliumapp/presentation/ui/feedback/loading_indicator.dart';
import 'package:heliumapp/presentation/ui/layout/helium_full_screen_scroll_view.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:heliumapp/utils/snack_bar_helpers.dart' show SnackBarHelper;
import 'package:heliumapp/utils/sort_helpers.dart';
import 'package:heliumapp/data/models/auth/user_settings_model.dart';

/// Schedule step of the course add/edit flow: a list of [ScheduleCard]s. Each
/// schedule saves per-item through [CourseBloc], so there's no batched save here.
class CourseSchedule extends StatelessWidget {
  final int courseGroupId;
  final int courseId;
  final bool isEdit;
  final bool isNew;
  final UserSettingsModel userSettings;

  const CourseSchedule({
    super.key,
    required this.courseGroupId,
    required this.courseId,
    required this.isEdit,
    required this.isNew,
    required this.userSettings,
  });

  @override
  Widget build(BuildContext context) {
    return _CourseScheduleContent(
      courseGroupId: courseGroupId,
      courseId: courseId,
      isEdit: isEdit,
      isNew: isNew,
      userSettings: userSettings,
    );
  }
}

class _CourseScheduleContent extends StatefulWidget {
  final int courseGroupId;
  final int courseId;
  final bool isEdit;
  final bool isNew;
  final UserSettingsModel userSettings;

  const _CourseScheduleContent({
    required this.courseGroupId,
    required this.courseId,
    required this.isEdit,
    required this.isNew,
    required this.userSettings,
  });

  @override
  State<_CourseScheduleContent> createState() => _CourseScheduleContentState();
}

class _CourseScheduleContentState extends State<_CourseScheduleContent> {
  bool _isLoading = true;
  String? _error;
  List<CourseScheduleModel> _schedules = [];

  List<DateTime> _courseExceptions = [];
  bool _courseDataLoaded = false;
  List<DateTime> _courseGroupExceptions = [];
  DateTime? _courseStartDate;
  DateTime? _courseEndDate;
  Color? _courseColor;

  @override
  void initState() {
    super.initState();

    if (widget.isEdit) {
      _fetchScreenData();
      context.read<CourseBloc>().add(
        FetchCourseScreenDataEvent(
          origin: EventOrigin.subScreen,
          courseGroupId: widget.courseGroupId,
          courseId: widget.courseId,
          forceRefresh: true,
        ),
      );
    } else {
      _isLoading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CourseBloc, CourseState>(
      listener: (context, state) {
        if (state is CourseSchedulesFetched) {
          setState(() {
            _schedules = state.schedules;
            _isLoading = false;
          });
        } else if (state is CourseScheduleCreated) {
          SnackBarHelper.show(context, 'Schedule saved.');
          setState(() => _schedules = [..._schedules, state.schedule]);
        } else if (state
            case CourseScheduleUpdated(:final schedule) ||
                CourseScheduleExceptionsUpdated(:final schedule) ||
                CourseScheduleConflict(latest: final schedule)) {
          setState(() {
            final index = _schedules.indexWhere((s) => s.id == schedule.id);
            if (index >= 0) _schedules[index] = schedule;
          });
        } else if (state is CourseScheduleDeleted) {
          SnackBarHelper.show(context, 'Schedule deleted.');
          setState(() => _schedules.removeWhere((s) => s.id == state.id));
        } else if (state is CourseExceptionsUpdated &&
            state.course.id == widget.courseId) {
          setState(() => _courseExceptions = state.course.exceptions);
        } else if (state is CourseScreenDataFetched) {
          setState(() {
            _courseExceptions = state.course?.exceptions ?? [];
            _courseDataLoaded = true;
            _courseGroupExceptions = state.courseGroup.exceptions;
            _courseStartDate = state.course?.startDate;
            _courseEndDate = state.course?.endDate;
            _courseColor = state.course?.color;
          });
        } else if (_isFetchFailure(state)) {
          setState(() {
            _error = (state as CoursesError).message ??
                HeliumException.unexpectedError;
            _isLoading = false;
          });
        }
      },
      child: _buildContent(context),
    );
  }

  void _fetchScreenData() {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    context.read<CourseBloc>().add(
      FetchCourseSchedulesEvent(
        origin: EventOrigin.subScreen,
        courseGroupId: widget.courseGroupId,
        courseId: widget.courseId,
        forceRefresh: true,
      ),
    );
  }

  /// A list-load failure, as opposed to a create/delete failure (which must not
  /// discard the loaded list).
  bool _isFetchFailure(CourseState state) =>
      state is CoursesError &&
      state.origin == EventOrigin.subScreen &&
      _isLoading;

  Widget _buildContent(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Schedules', style: AppStyles.featureText(context)),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.isEdit) ...[
                  _buildCancellationsButton(context),
                  const SizedBox(width: 12),
                ],
                HeliumIconButton(
                  onPressed: _onAdd,
                  icon: Icons.add,
                  semanticLabel: 'Add schedule',
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(child: _buildList(context)),
      ],
    );
  }

  Widget _buildList(BuildContext context) {
    if (_isLoading) {
      return const Center(child: LoadingIndicator(expanded: false));
    }

    if (_error != null) {
      return ErrorCard(
        message: _error!,
        source: 'course_schedule',
        expanded: false,
        onReload: _fetchScreenData,
      );
    }

    if (_schedules.isEmpty) {
      return const EmptyCard(
        expanded: false,
        icon: Icons.date_range_outlined,
        message: 'Click "+" to add a schedule',
      );
    }

    final schedules = Sort.courseSchedulesForDisplay(_schedules);

    return ListView.builder(
      padding: EdgeInsets.only(
        bottom: HeliumFullScreenScrollView.insetOf(context),
      ),
      itemCount: schedules.length,
      itemBuilder: (context, index) {
        final schedule = schedules[index];
        return ScheduleCard(
          schedule: schedule,
          color: _courseColor ?? context.colorScheme.primary,
          onEdit: () => _onEdit(schedule),
          onDelete: () => _onDelete(schedule),
        );
      },
    );
  }

  void _onAdd() {
    showScheduleEditor(
      parentContext: context,
      courseGroupId: widget.courseGroupId,
      courseId: widget.courseId,
      courseStartDate: _courseStartDate,
      courseEndDate: _courseEndDate,
    );
  }

  void _onEdit(CourseScheduleModel schedule) {
    showScheduleEditor(
      parentContext: context,
      courseGroupId: widget.courseGroupId,
      courseId: widget.courseId,
      courseStartDate: _courseStartDate,
      courseEndDate: _courseEndDate,
      schedule: schedule,
    );
  }

  void _onDelete(CourseScheduleModel schedule) {
    showConfirmDeleteDialog(
      parentContext: context,
      item: schedule,
      label: '',
      onDelete: (_) {
        context.read<CourseBloc>().add(
          DeleteCourseScheduleEvent(
            origin: EventOrigin.subScreen,
            courseGroupId: widget.courseGroupId,
            courseId: widget.courseId,
            scheduleId: schedule.id,
          ),
        );
      },
    );
  }

  Widget _buildCancellationsButton(BuildContext context) {
    final actionHeight =
        Responsive.getIconSize(context, mobile: 20, tablet: 22, desktop: 24) + 12;
    return HeliumElevatedButton(
      buttonText: 'Cancellations',
      backgroundColor: context.colorScheme.onSurfaceVariant,
      fullWidth: false,
      minHeight: actionHeight,
      visualDensity: VisualDensity.standard,
      enabled: _courseDataLoaded,
      onPressed: _showCancellations,
    );
  }

  Future<void> _showCancellations() {
    final schedules = Sort.courseSchedulesForDisplay(_schedules)
        .where((schedule) => schedule.groupsByTime().isNotEmpty)
        .toList();
    final showsScopes = schedules.length > 1 ||
        schedules.any((schedule) => schedule.exceptions.isNotEmpty);
    final courseStart = _courseStartDate;
    final courseEnd = _courseEndDate;
    return showCourseExceptionsDialog(
      context: context,
      courseExceptions: _courseExceptions,
      onConfirm: _saveCancellations,
      scheduleLabels: showsScopes
          ? {for (final schedule in schedules) schedule.id: _scopeLabel(schedule)}
          : const {},
      scheduleExceptions: {
        for (final schedule in schedules) schedule.id: schedule.exceptions,
      },
      scheduleDateRanges: courseStart == null || courseEnd == null
          ? const {}
          : {
              for (final schedule in schedules)
                schedule.id: _dateRange(schedule, courseStart, courseEnd),
            },
      courseGroupExceptions: _courseGroupExceptions,
      firstDate: _courseStartDate,
      lastDate: _courseEndDate,
    );
  }

  String _scopeLabel(CourseScheduleModel schedule) {
    final rotation = ScheduleTemplate.summaryLabel(schedule);
    final meetings = rotation == null
        ? schedule.meetingsLabel()
        : '$rotation: ${schedule.meetingsLabel()}';
    final dateRange = schedule.overrideDateRangeLabel();
    return dateRange == null ? meetings : '$meetings • $dateRange';
  }

  DateTimeRange _dateRange(
    CourseScheduleModel schedule,
    DateTime courseStart,
    DateTime courseEnd,
  ) {
    final start = schedule.startDate;
    final end = schedule.endDate;
    return DateTimeRange(
      start: start != null && start.isAfter(courseStart) ? start : courseStart,
      end: end != null && end.isBefore(courseEnd) ? end : courseEnd,
    );
  }

  Future<String?> _saveCancellations(
    List<DateTime> exceptions,
    Map<int, List<DateTime>> scheduleExceptions,
  ) async {
    final bloc = context.read<CourseBloc>();
    if (!listEquals(exceptions, _courseExceptions)) {
      final outcome = bloc.stream.firstWhere(
        (state) =>
            (state is CourseExceptionsUpdated &&
                state.course.id == widget.courseId) ||
            (state is CoursesError && state.origin == EventOrigin.dialog),
      );
      bloc.add(
        UpdateCourseExceptionsEvent(
          origin: EventOrigin.dialog,
          courseGroupId: widget.courseGroupId,
          courseId: widget.courseId,
          exceptions: exceptions,
        ),
      );
      if (await outcome case CoursesError(:final message)) return message;
    }

    for (final schedule in _schedules) {
      final edited = scheduleExceptions[schedule.id];
      if (edited == null || listEquals(edited, schedule.exceptions)) continue;

      final outcome = bloc.stream.firstWhere(
        (state) =>
            (state is CourseScheduleExceptionsUpdated &&
                state.schedule.id == schedule.id) ||
            (state is CoursesError && state.origin == EventOrigin.dialog),
      );
      bloc.add(
        UpdateCourseScheduleExceptionsEvent(
          origin: EventOrigin.dialog,
          courseGroupId: widget.courseGroupId,
          courseId: widget.courseId,
          scheduleId: schedule.id,
          exceptions: edited,
        ),
      );
      if (await outcome case CoursesError(:final message)) return message;
    }
    return null;
  }
}
