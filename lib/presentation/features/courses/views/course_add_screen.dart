// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:heliumapp/config/app_route.dart';
import 'package:heliumapp/config/app_router.dart';
import 'package:heliumapp/config/dirty_dialog_registry.dart';
import 'package:heliumapp/presentation/features/courses/bloc/course_bloc.dart';
import 'package:heliumapp/presentation/features/courses/bloc/course_event.dart';
import 'package:heliumapp/presentation/features/courses/bloc/course_state.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/base_event.dart';
import 'package:heliumapp/presentation/ui/feedback/loading_indicator.dart';
import 'package:heliumapp/presentation/features/shared/widgets/flow/multi_step_container.dart';
import 'package:heliumapp/presentation/features/courses/widgets/course_attachments.dart';
import 'package:heliumapp/presentation/features/shared/widgets/core/base_attachments.dart';
import 'package:heliumapp/presentation/features/courses/widgets/course_categories.dart';
import 'package:heliumapp/presentation/features/courses/widgets/course_details.dart';
import 'package:heliumapp/presentation/features/courses/widgets/course_reminders.dart';
import 'package:heliumapp/presentation/features/courses/widgets/course_schedule.dart';
import 'package:heliumapp/utils/snack_bar_helpers.dart';

/// Pushes the course editor route on the current shell.
///
/// Step navigation, sub-screen state, and dialog dismissal are URL-driven;
/// callers only need to specify which course (or 'new') and, for the
/// create flow, which course group to attach it to. The group rides along
/// as GoRouter `extra` so the URL stays focused on the entity, not its
/// containing group.
Future<void> showCourseAdd(
  BuildContext context, {
  required int courseGroupId,
  int? courseId,
  required bool isNew,
  String initialStep = 'details',
}) {
  final id = courseId?.toString() ?? 'new';
  final target = '${AppRoute.coursesScreen}/$id/$initialStep';
  final currentPath =
      router.routerDelegate.currentConfiguration.uri.path;
  if (currentPath == target) {
    // Already on this exact route; avoid duplicate push that would stack
    // a second dialog page with the same shared key.
    return Future.value();
  }
  return context.push<void>(
    target,
    extra: CourseDialogExtra(courseGroupId: courseGroupId),
  );
}

class CourseAddScreen extends MultiStepContainer {
  /// Shell path the dialog is overlaying — used to build sub-step URLs.
  final String shellPath;

  /// Course group containing the course. Required for the create flow and
  /// the multi-step widgets that need it (categories, attachments).
  final int? courseGroupId;

  /// Course primary key. Null when creating a new course (`isNew == true`).
  final int? courseId;

  /// URL step segment to render on initial mount (`details`, `schedule`, etc.).
  final String initialStepName;

  /// Full URL the route was matched at — passed in from the pageBuilder so
  /// the dialog's dirty-guard registration captures the active path without
  /// racing against `routerDelegate.currentConfiguration`, which lags push.
  final String initialFullPath;

  CourseAddScreen({
    super.key,
    required this.shellPath,
    required super.isNew,
    required this.initialFullPath,
    this.courseId,
    this.courseGroupId,
    this.initialStepName = 'details',
  }) : super(
          isEdit: !isNew,
          initialStep: _resolveStepIndex(initialStepName),
        );

  static int _resolveStepIndex(String name) {
    final idx = courseDialogSteps.indexOf(name);
    return idx >= 0 ? idx : 0;
  }

  @override
  State<CourseAddScreen> createState() => _CourseAddScreenState();
}

class _CourseAddScreenState extends MultiStepContainerState<CourseAddScreen> {
  final _detailsKey = GlobalKey<CourseDetailsState>();
  final _scheduleKey = GlobalKey<CourseScheduleState>();
  final _attachmentsKey = GlobalKey<BaseAttachmentsState>();

  int? _currentCourseId;
  int? _currentCourseGroupId;
  int? _targetStep;
  String? _registeredPrefix;

  @override
  void initState() {
    super.initState();
    _currentCourseId = widget.courseId;
    _currentCourseGroupId = widget.courseGroupId;
    _registerDirtyGuard();
    // The modal scope does not rebuild on Page swap, so the URL is the
    // source of truth for the active step.
    router.routerDelegate.addListener(_syncStepFromUrl);

    if (_currentCourseGroupId == null) {
      if (widget.isNew) {
        // Create flow refreshed without the in-app `extra`. We have no
        // group to attach the new course to — drop back to the index.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.go(widget.shellPath);
        });
      } else if (_currentCourseId != null) {
        // Edit flow without a hint — try the BLoC's cache, otherwise
        // request a fetch and wait for the listener below.
        _resolveGroupFromBlocState(context.read<CourseBloc>().state);
        if (_currentCourseGroupId == null) {
          context.read<CourseBloc>().add(
                FetchCoursesScreenDataEvent(origin: EventOrigin.dialog),
              );
        }
      }
    }
  }

  void _resolveGroupFromBlocState(CourseState state) {
    if (state is! CoursesScreenDataFetched) return;
    final match = state.courses
        .firstWhereOrNull((c) => c.id == _currentCourseId);
    if (match != null) {
      _currentCourseGroupId = match.courseGroup;
    }
  }

  @override
  void dispose() {
    router.routerDelegate.removeListener(_syncStepFromUrl);
    if (_registeredPrefix != null) {
      DirtyDialogRegistry.unregister(_registeredPrefix!);
    }
    super.dispose();
  }

  /// Registers (or re-registers, after a new-course save mints a real ID)
  /// this dialog with the dirty-dialog guard so URL-driven dismissals can't
  /// silently lose unsaved changes.
  void _registerDirtyGuard() {
    final prefix =
        '${widget.shellPath}/${_currentCourseId?.toString() ?? 'new'}';
    final routerPath =
        router.routerDelegate.currentConfiguration.uri.path;
    // Prefer the routerDelegate's settled path if it already matches our
    // dialog (e.g. after a new-course save); otherwise fall back to the URL
    // the pageBuilder matched on, which is authoritative for the active
    // route even when the routerDelegate hasn't caught up yet.
    final fullPath = routerPath.startsWith(prefix)
        ? routerPath
        : widget.initialFullPath;
    DirtyDialogRegistry.register(
      prefix: prefix,
      fullPath: fullPath,
      isDirty: () => isDirty,
    );
    _registeredPrefix = prefix;
  }

  void _syncStepFromUrl() {
    if (!mounted) return;
    final path = router.routerDelegate.currentConfiguration.uri.path;
    final prefix = _registeredPrefix;
    if (prefix != null && path.startsWith(prefix)) {
      DirtyDialogRegistry.updateFullPath(prefix: prefix, fullPath: path);
    }
    final segments = path.split('/').where((s) => s.isNotEmpty).toList();
    final classesIdx = segments.indexOf('classes');
    if (classesIdx < 0 || segments.length < classesIdx + 3) return;
    final stepName = segments[classesIdx + 2];
    final newStep = courseDialogSteps.indexOf(stepName);
    if (newStep >= 0 && newStep != currentStep) {
      super.navigateToStep(newStep);
    }
  }

  @override
  void navigateToStep(int step) {
    if (step < 0 || step >= steps.length) return;
    if (!mounted) return;
    final id = _currentCourseId?.toString() ?? 'new';
    final stepName = courseDialogSteps[step];
    final groupId = _currentCourseGroupId;
    context.go(
      '${widget.shellPath}/$id/$stepName',
      extra: groupId != null
          ? CourseDialogExtra(courseGroupId: groupId)
          : null,
    );
  }

  @override
  bool get enableNextSteps => _currentCourseId != null;

  @override
  void onStepRequested(int step) {
    if (step == currentStep) return;

    if (saveAction != null) {
      final changed = currentStep == 0
          ? (_detailsKey.currentState?.formController.isChanged ?? true)
          : (_scheduleKey.currentState?.formController.isChanged ?? true);
      if (!changed) {
        navigateToStep(step);
        return;
      }
      _targetStep = step;
      saveAction!();
      return;
    }

    navigateToStep(step);
  }

  @override
  String get screenTitle => !widget.isNew ? 'Edit Class' : 'Add Class';

  @override
  IconData? get icon => Icons.school;

  @override
  bool get isDirty {
    switch (currentStep) {
      case 0:
        return _detailsKey.currentState?.formController.isUserDirty ?? false;
      case 1:
        return _scheduleKey.currentState?.formController.isUserDirty ?? false;
      case 4:
        return _attachmentsKey.currentState?.hasUnsavedFiles ?? false;
      default:
        return false;
    }
  }

  @override
  Function? get saveAction {
    if (steps[currentStep].stepScreenType != ScreenType.entityPage) {
      return null;
    }
    return () {
      if (isSubmitting) return;
      Function? widgetSubmit;
      bool widgetLoading = false;
      bool widgetChanged = true;
      switch (currentStep) {
        case 0:
          widgetSubmit = _detailsKey.currentState?.onSubmit;
          widgetLoading = _detailsKey.currentState?.isLoading ?? true;
          widgetChanged =
              _detailsKey.currentState?.formController.isChanged ?? true;
          break;
        case 1:
          widgetSubmit = _scheduleKey.currentState?.onSubmit;
          widgetLoading = _scheduleKey.currentState?.isLoading ?? true;
          widgetChanged =
              _scheduleKey.currentState?.formController.isChanged ?? true;
          break;
      }
      if (widgetLoading) return;
      if (!widgetChanged) {
        _navigateAfterSave();
        return;
      }
      if (widgetSubmit != null) {
        widgetSubmit();
      }
    };
  }

  @override
  List<BlocListener<dynamic, dynamic>> buildListeners(BuildContext context) {
    return [
      BlocListener<CourseBloc, CourseState>(
        listener: (context, state) {
          if (state is CoursesError) {
            showSnackBar(context, state.message!, type: SnackType.error);
            _detailsKey.currentState?.resetSubmitting();
            _scheduleKey.currentState?.resetSubmitting();
            setState(() => isSubmitting = false);
          } else if (state is CoursesScreenDataFetched &&
              _currentCourseGroupId == null &&
              _currentCourseId != null) {
            final match = state.courses
                .firstWhereOrNull((c) => c.id == _currentCourseId);
            if (match != null) {
              setState(() => _currentCourseGroupId = match.courseGroup);
            } else {
              // Course not found after fetch; back out to the index.
              context.go(widget.shellPath);
            }
          } else if (state is CourseCreated || state is CourseUpdated) {
            state as CourseEntityState;

            if (state is CourseCreated) {
              final willClose = _willCloseAfterSave();
              showSnackBar(
                context,
                'Class created.',
                useRootMessenger: willClose,
              );
            }

            setState(() {
              _currentCourseId = state.course.id;
              _currentCourseGroupId = state.course.courseGroup;
              isSubmitting = false;
            });

            if (state is CourseCreated) {
              // New course minted its real ID — the URL prefix that the
              // dirty-dialog guard owns has changed (`/classes/new` →
              // `/classes/<id>`), so swap the registration before
              // `_navigateAfterSave` triggers the URL update.
              if (_registeredPrefix != null) {
                DirtyDialogRegistry.unregister(_registeredPrefix!);
              }
              _registerDirtyGuard();
            }

            _navigateAfterSave();
          } else if (state is CourseScheduleUpdated) {
            setState(() => isSubmitting = false);
            _navigateAfterSave();
          }
        },
      ),
    ];
  }

  bool _willCloseAfterSave() {
    if (_targetStep != null) {
      return _targetStep! >= steps.length;
    }
    return !widget.isNew || currentStep + 1 >= steps.length;
  }

  void _navigateAfterSave() {
    if (_targetStep != null) {
      final step = _targetStep!;
      _targetStep = null;
      if (step < steps.length) {
        navigateToStep(step);
      } else {
        closeWithoutPrompt();
      }
    } else if (widget.isNew && currentStep + 1 < steps.length) {
      navigateToStep(currentStep + 1);
    } else {
      closeWithoutPrompt();
    }
  }

  @override
  Widget buildMainArea(BuildContext context) {
    if (_currentCourseGroupId == null) {
      return const Expanded(
        child: Center(child: LoadingIndicator(expanded: false)),
      );
    }
    return super.buildMainArea(context);
  }

  late final List<MultiStepDefinition> _steps = [
    MultiStepDefinition(
      icon: Icons.list,
      tooltip: 'Details',
      stepScreenType: ScreenType.entityPage,
      builder: (context) => CourseDetails(
        key: _detailsKey,
        courseGroupId: _currentCourseGroupId!,
        courseId: _currentCourseId,
        isEdit: widget.isEdit || _currentCourseId != null,
        isNew: widget.isNew,
        userSettings: userSettings,
        onSubmitRequested: () => saveAction?.call(),
        onActionStarted: () => setState(() => isSubmitting = true),
      ),
    ),
    MultiStepDefinition(
      icon: Icons.date_range_outlined,
      tooltip: 'Schedule',
      stepScreenType: ScreenType.entityPage,
      builder: (context) => CourseSchedule(
        key: _scheduleKey,
        courseGroupId: _currentCourseGroupId!,
        courseId: _currentCourseId!,
        isEdit: widget.isEdit || _currentCourseId != null,
        isNew: widget.isNew,
        userSettings: userSettings,
        onActionStarted: () => setState(() => isSubmitting = true),
      ),
    ),
    MultiStepDefinition(
      icon: Icons.notifications_outlined,
      tooltip: 'Schedule Reminders',
      stepScreenType: ScreenType.subPage,
      builder: (context) => CourseReminders(
        entityId: _currentCourseId!,
        isEdit: widget.isEdit || _currentCourseId != null,
        userSettings: userSettings,
        headerTitle: 'Schedule Reminders',
      ),
    ),
    MultiStepDefinition(
      icon: Icons.category_outlined,
      tooltip: 'Categories',
      stepScreenType: ScreenType.subPage,
      builder: (context) => CourseCategories(
        courseGroupId: _currentCourseGroupId!,
        courseId: _currentCourseId!,
        isEdit: widget.isEdit || _currentCourseId != null,
        isNew: widget.isNew,
        userSettings: userSettings,
      ),
    ),
    MultiStepDefinition(
      icon: Icons.attachment,
      tooltip: 'Attachments',
      stepScreenType: ScreenType.subPage,
      builder: (context) => CourseAttachments(
        contentKey: _attachmentsKey,
        courseGroupId: _currentCourseGroupId!,
        entityId: _currentCourseId!,
        isEdit: widget.isEdit || _currentCourseId != null,
        userSettings: userSettings,
      ),
    ),
  ];

  @override
  List<MultiStepDefinition> get steps => _steps;
}
