import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heliumapp/config/analytics_event.dart';
import 'package:heliumapp/config/app_route.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/core/analytics_service.dart';
import 'package:heliumapp/core/api_error_parser.dart';
import 'package:heliumapp/core/api_url.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/core/notification_count_service.dart';
import 'package:heliumapp/data/models/auth/user_settings_model.dart';
import 'package:heliumapp/data/models/planner/course_group_model.dart';
import 'package:heliumapp/data/models/planner/course_model.dart';
import 'package:heliumapp/presentation/features/auth/bloc/auth_bloc.dart';
import 'package:heliumapp/presentation/features/auth/bloc/auth_event.dart';
import 'package:heliumapp/presentation/features/courses/bloc/course_bloc.dart';
import 'package:heliumapp/presentation/features/shared/bloc/info/info_bloc.dart';
import 'package:heliumapp/presentation/features/shared/bloc/info/info_state.dart';
import 'package:heliumapp/presentation/ui/components/helium_elevated_button.dart';
import 'package:heliumapp/presentation/ui/components/helium_icon_button.dart';
import 'package:heliumapp/presentation/ui/feedback/info_container.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/format_helpers.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:heliumapp/utils/snack_bar_helpers.dart';
import 'package:heliumapp/utils/storage_helpers.dart';
import 'package:heliumapp/utils/url_helpers.dart';
import 'package:logging/logging.dart';

final _log = Logger('presentation.settings');

/// Where an imported `.ics` lands. `header` is a non-selectable group label in the picker.
enum _TargetKind { header, newCourse, existingCourse, events }

/// A picker destination. `id` is a course-group id for `newCourse`/`header`, a course
/// id for `existingCourse`, and null for `events`.
class _ImportTarget {
  final _TargetKind kind;
  final int? id;

  const _ImportTarget(this.kind, [this.id]);

  @override
  bool operator ==(Object other) =>
      other is _ImportTarget && other.kind == kind && other.id == id;

  @override
  int get hashCode => Object.hash(kind, id);
}

class ImportExportScreen extends StatefulWidget {
  final UserSettingsModel? userSettings;
  final void Function(String route)? onNavigateRequested;
  final VoidCallback? onActionStarted;
  final VoidCallback? onCompleted;
  final VoidCallback? onFailed;

  const ImportExportScreen({
    super.key,
    this.userSettings,
    this.onNavigateRequested,
    this.onActionStarted,
    this.onCompleted,
    this.onFailed,
  });

  @override
  State<ImportExportScreen> createState() => _ImportExportScreenState();
}

class _ImportExportScreenState extends State<ImportExportScreen> {
  final DioClient _dioClient = DioClient();

  String? _selectedFileName;
  Uint8List? _selectedFileBytes;
  bool _isImporting = false;
  bool _isExporting = false;
  bool _isImportingExample = false;

  // Populated only while an `.ics` file is selected — the target picker's options.
  List<CourseGroupModel> _courseGroups = [];
  List<CourseModel> _courses = [];
  _ImportTarget? _selectedTarget;
  bool _isLoadingTargets = false;

  bool get _selectedIsIcs =>
      _selectedFileName?.toLowerCase().endsWith('.ics') ?? false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InfoContainer(
              text:
                  'Backup, restore, or import data from an automated tool or shared schedule.',
              trailing: HeliumIconButton(
                icon: Icons.menu_book_outlined,
                backgroundColor: context.colorScheme.onSurfaceVariant,
                tooltip: 'Learn more',
                onPressed: () => UrlHelpers.launchWebUrl(
                  AppConstants.supportImportExportUrl,
                ),
              ),
            ),
          ),
          _buildImportSection(context),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),
          _buildExportSection(context),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),
          _buildExampleScheduleSection(context),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildImportSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Import', style: AppStyles.featureText(context)),
        const SizedBox(height: 8),
        Text('Import a file', style: AppStyles.standardBodyTextLight(context)),
        const SizedBox(height: 16),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  decoration: BoxDecoration(
                    color: context.colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(
                      color: context.colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.insert_drive_file_outlined,
                        color: context.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                        size: Responsive.getIconSize(
                          context,
                          mobile: 18,
                          tablet: 20,
                          desktop: 22,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedFileName ?? 'No file selected',
                          style: AppStyles.standardBodyTextLight(context)
                              .copyWith(
                                color: _selectedFileName != null
                                    ? context.colorScheme.onSurface
                                    : context.colorScheme.onSurface.withValues(
                                        alpha: 0.5,
                                      ),
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              HeliumElevatedButton(
                onPressed: _openFileChooser,
                buttonText: 'Choose',
                icon: Icons.folder_open_outlined,
                fullWidth: false,
              ),
            ],
          ),
        ),
        if (_selectedIsIcs) _buildTargetPicker(context),
        const SizedBox(height: 16),
        HeliumElevatedButton(
          onPressed: _importData,
          buttonText: 'Import',
          icon: Icons.upload_outlined,
          isLoading: _isImporting,
          enabled:
              _selectedFileBytes != null &&
              !_isImporting &&
              !_isLoadingTargets &&
              !(_selectedIsIcs && _selectedTarget == null),
        ),
      ],
    );
  }

  Widget _buildTargetPicker(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Import into', style: AppStyles.formLabel(context)),
          const SizedBox(height: 9),
          if (_isLoadingTargets)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            DropdownButtonFormField<_ImportTarget>(
              key: ValueKey(_selectedFileName),
              initialValue: _selectedTarget,
              isExpanded: true,
              hint: Text(
                'Select a destination',
                style: AppStyles.formText(context),
              ),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.only(left: 12),
                filled: true,
                fillColor: context.colorScheme.surface,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: context.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: context.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
              ),
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: context.colorScheme.primary,
              ),
              dropdownColor: context.colorScheme.surface,
              style: AppStyles.formText(context),
              items: _buildTargetItems(context),
              onChanged: (target) {
                if (target == null) return;
                setState(() => _selectedTarget = target);
              },
            ),
        ],
      ),
    );
  }

  List<DropdownMenuItem<_ImportTarget>> _buildTargetItems(
    BuildContext context,
  ) {
    final items = <DropdownMenuItem<_ImportTarget>>[];

    for (var i = 0; i < _courseGroups.length; i++) {
      final group = _courseGroups[i];
      if (i > 0) items.add(_dividerItem(context));
      items.add(
        DropdownMenuItem(
          enabled: false,
          value: _ImportTarget(_TargetKind.header, group.id),
          child: Text(group.title, style: AppStyles.formLabel(context)),
        ),
      );
      items.add(
        DropdownMenuItem(
          value: _ImportTarget(_TargetKind.newCourse, group.id),
          child: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Row(
              children: [
                Icon(Icons.add, size: 16, color: context.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Create a new class', style: AppStyles.formText(context)),
              ],
            ),
          ),
        ),
      );
      for (final course in _courses.where((c) => c.courseGroup == group.id)) {
        items.add(
          DropdownMenuItem(
            value: _ImportTarget(_TargetKind.existingCourse, course.id),
            child: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(
                course.title,
                style: AppStyles.formText(context),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        );
      }
    }

    // Offset "Import as Events" from the class groups above.
    if (_courseGroups.isNotEmpty) items.add(_dividerItem(context));

    items.add(
      DropdownMenuItem(
        value: const _ImportTarget(_TargetKind.events),
        child: Row(
          children: [
            Icon(
              AppConstants.eventIcon,
              size: 16,
              color: context.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text('Import as Events', style: AppStyles.formText(context)),
          ],
        ),
      ),
    );

    return items;
  }

  DropdownMenuItem<_ImportTarget> _dividerItem(BuildContext context) {
    return DropdownMenuItem<_ImportTarget>(
      enabled: false,
      child: Divider(
        height: 1,
        color: context.colorScheme.outline.withValues(alpha: 0.2),
      ),
    );
  }

  Widget _buildExportSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Export', style: AppStyles.featureText(context)),
        const SizedBox(height: 8),
        Text(
          'Export your data to a Helium file (no attachments)',
          style: AppStyles.standardBodyTextLight(context),
        ),
        const SizedBox(height: 16),
        HeliumElevatedButton(
          onPressed: _exportData,
          buttonText: 'Export',
          icon: Icons.download_outlined,
          isLoading: _isExporting,
          enabled: !_isExporting,
        ),
      ],
    );
  }

  Widget _buildExampleScheduleSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Example Schedule', style: AppStyles.featureText(context)),
        const SizedBox(height: 8),
        Text(
          'Restore demo data to explore Helium',
          style: AppStyles.standardBodyTextLight(context),
        ),
        const SizedBox(height: 16),
        HeliumElevatedButton(
          onPressed: _importExampleSchedule,
          buttonText: 'Re-Import Example Schedule',
          icon: Icons.restore_outlined,
          isLoading: _isImportingExample,
          enabled:
              !_isImportingExample &&
              !(widget.userSettings?.showGettingStarted ?? false),
        ),
      ],
    );
  }

  Future<void> _openFileChooser() async {
    // BasePageScreenState gates render on InfoLoaded, so this read is safe.
    final info = (context.read<InfoBloc>().state as InfoLoaded).info;
    final result = await HeliumStorage.pickFiles(
      maxUploadSize: info.maxUploadSize,
      allowMultiple: false,
      allowedExtensions: info.importFileTypes,
    );

    if (!mounted) return;

    for (final error in result.errors) {
      SnackBarHelper.show(context, error.userMessage, type: SnackType.error);
    }

    if (result.cancelled || result.files.isEmpty) return;

    final file = result.files.first;
    final isIcs = file.name.toLowerCase().endsWith('.ics');
    final contentError = isIcs
        ? _validateIcsFile(file.bytes)
        : _validateJsonFile(file.bytes);
    if (contentError != null) {
      SnackBarHelper.show(context, contentError, type: SnackType.error);
      return;
    }

    setState(() {
      _selectedFileName = file.name;
      _selectedFileBytes = file.bytes;
      _selectedTarget = null;
      _courseGroups = [];
      _courses = [];
    });

    // Only an ICS import needs a destination; JSON keeps its no-target flow.
    if (_selectedIsIcs) {
      await _loadImportTargets();
    }
  }

  String? _validateJsonFile(Uint8List bytes) {
    final Object? decoded;
    try {
      var text = utf8.decode(bytes);
      if (text.isNotEmpty && text.codeUnitAt(0) == 0xFEFF) {
        text = text.substring(1);
      }
      decoded = jsonDecode(text);
    } catch (_) {
      return 'This file isn\'t valid JSON.';
    }
    if (decoded is! Map) {
      return 'This doesn\'t look like a Helium export file.';
    }
    return null;
  }

  String? _validateIcsFile(Uint8List bytes) {
    final text = utf8.decode(bytes, allowMalformed: true);
    if (!text.contains('BEGIN:VCALENDAR')) {
      return 'This doesn\'t look like a valid calendar file.';
    }
    return null;
  }

  Future<void> _loadImportTargets() async {
    setState(() {
      _isLoadingTargets = true;
    });

    try {
      final repository = context.read<CourseBloc>().courseRepository;
      final groups = await repository.getCourseGroups(shownOnCalendar: true);
      final courses = await repository.getCourses(shownOnCalendar: true);

      if (!mounted) return;

      setState(() {
        _courseGroups = groups;
        _courses = courses;
        // With no class groups to import into, Events is the only destination.
        _selectedTarget = _courseGroups.isEmpty
            ? const _ImportTarget(_TargetKind.events)
            : null;
        _isLoadingTargets = false;
      });
    } catch (e) {
      _log.severe('Failed to load import targets.', e);
      if (!mounted) return;
      setState(() {
        _isLoadingTargets = false;
      });
      SnackBarHelper.show(
        context,
        'Could not load your classes.',
        type: SnackType.error,
      );
    }
  }

  Future<void> _importData() async {
    if (_selectedFileBytes == null || _selectedFileName == null) return;
    final isIcs = _selectedIsIcs;
    if (isIcs && _selectedTarget == null) return;

    setState(() {
      _isImporting = true;
    });
    widget.onActionStarted?.call();

    try {
      final formMap = <String, dynamic>{
        'file[]': MultipartFile.fromBytes(
          _selectedFileBytes!,
          filename: _selectedFileName!,
        ),
      };
      if (isIcs) {
        formMap.addAll(_targetFields(_selectedTarget!));
      }

      final response = await _dioClient.dio.post(
        isIcs ? ApiUrl.importExportImportIcsUrl : ApiUrl.importExportImportUrl,
        data: FormData.fromMap(formMap),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        await _dioClient.cacheService.invalidateAll();
        unawaited(NotificationCountService().refresh());

        final data = response.data as Map<String, dynamic>;
        final counts = _formatImportCounts(data);

        if (mounted) {
          context.read<AuthBloc>().add(RefreshScheduleDataEvent());
          unawaited(
            AnalyticsService().logEvent(
              name: AnalyticsEvent.importComplete,
              parameters: {
                'category': AnalyticsCategory.featureInteraction.value,
              },
            ),
          );
          SnackBarHelper.show(
            context,
            'Imported: $counts.',
            seconds: counts == 'nothing' ? 2 : 7,
            useRootMessenger: true,
          );
          widget.onNavigateRequested?.call(AppRoute.coursesScreen);
        }
      } else {
        SnackBarHelper.show(context, 'Import failed.', type: SnackType.error);
      }
    } on DioException catch (e) {
      final parsedError = ApiErrorParser.parse(e.response?.data);
      final message = parsedError.displayMessage.isNotEmpty
          ? parsedError.displayMessage
          : null;
      if (e.response?.statusCode == 400 && message != null) {
        _log.info('Import rejected: $message');
      } else {
        _log.severe('Import failed.', e);
      }
      if (mounted) {
        SnackBarHelper.show(
          context,
          message ?? 'Failed to import file.',
          type: SnackType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
        widget.onCompleted?.call();
      }
    }
  }

  Map<String, dynamic> _targetFields(_ImportTarget target) {
    switch (target.kind) {
      case _TargetKind.newCourse:
        return {'target_type': 'new_course', 'course_group': target.id};
      case _TargetKind.existingCourse:
        return {'target_type': 'course', 'course': target.id};
      case _TargetKind.events:
      case _TargetKind.header:
        return {'target_type': 'events'};
    }
  }

  String _formatImportCounts(Map<String, dynamic> data) {
    final parts = <String>[];

    final courses = data['courses'] as int? ?? 0;
    if (courses > 0) {
      parts.add('$courses ${courses.plural('class', 'classes')}');
    }

    final categories = data['categories'] as int? ?? 0;
    if (categories > 0) {
      parts.add('$categories ${categories.plural('category', 'categories')}');
    }

    final homework = data['homework'] as int? ?? 0;
    if (homework > 0) {
      parts.add('$homework ${homework.plural('assignment')}');
    }

    final events = data['events'] as int? ?? 0;
    if (events > 0) {
      parts.add('$events ${events.plural('event')}');
    }

    final materials = data['materials'] as int? ?? 0;
    if (materials > 0) {
      parts.add('$materials ${materials.plural('resource')}');
    }

    final reminders = data['reminders'] as int? ?? 0;
    if (reminders > 0) {
      parts.add('$reminders ${reminders.plural('reminder')}');
    }

    final externalCalendars = data['external_calendars'] as int? ?? 0;
    if (externalCalendars > 0) {
      parts.add(
        '$externalCalendars ${externalCalendars.plural('external calendar')}',
      );
    }

    if (parts.isEmpty) {
      return 'nothing';
    }

    return parts.join(', ');
  }

  Future<void> _exportData() async {
    setState(() {
      _isExporting = true;
    });
    widget.onActionStarted?.call();

    try {
      final response = await _dioClient.dio.get<Uint8List>(
        ApiUrl.importExportExportUrl,
        options: _dioClient.cacheService.forceRefreshOptions().copyWith(
          responseType: ResponseType.bytes,
        ),
      );

      if (!mounted) return;

      if (response.statusCode == 200 && response.data != null) {
        unawaited(
          AnalyticsService().logEvent(
            name: AnalyticsEvent.exportTrigger,
            parameters: {
              'category': AnalyticsCategory.featureInteraction.value,
            },
          ),
        );
        final contentDisposition = response.headers.value(
          'content-disposition',
        );
        String filename = 'Helium_backup.json';
        if (contentDisposition != null) {
          final match = RegExp(r'filename=(.+)').firstMatch(contentDisposition);
          if (match != null) {
            filename = match.group(1)!;
          }
        }

        final success = await HeliumStorage.downloadBytes(
          response.data!,
          filename,
        );

        if (mounted) {
          if (success) {
            SnackBarHelper.show(context, '"$filename" downloaded.');
          } else {
            SnackBarHelper.show(
              context,
              'Nothing exported.',
              type: SnackType.error,
            );
          }
        }
      } else {
        SnackBarHelper.show(context, 'Export failed.', type: SnackType.error);
      }
    } on DioException catch (e) {
      _log.severe('Export failed.', e);
      if (mounted) {
        SnackBarHelper.show(context, 'Export failed.', type: SnackType.error);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
        widget.onCompleted?.call();
      }
    }
  }

  Future<void> _importExampleSchedule() async {
    setState(() {
      _isImportingExample = true;
    });
    widget.onActionStarted?.call();

    try {
      final response = await _dioClient.dio.post(
        ApiUrl.importExportExampleScheduleUrl,
      );

      if (!mounted) return;

      if (response.statusCode == 204) {
        await _dioClient.cacheService.invalidateAll();
        // Warm the settings cache so the router's auth-redirect read is a hit,
        // not a post-redirect cold fetch that stalls the outgoing screen.
        await _dioClient.fetchSettings(forceRefresh: true);
        if (!mounted) return;
        unawaited(NotificationCountService().refresh());
        if (mounted) {
          unawaited(
            AnalyticsService().logEvent(
              name: AnalyticsEvent.exampleScheduleImport,
              parameters: {'category': AnalyticsCategory.onboarding.value},
            ),
          );
          unawaited(
            AnalyticsService().setUserProperty(
              name: 'onboarding_complete',
              value: 'false',
            ),
          );
          context.read<AuthBloc>().add(FetchProfileEvent());
          context.read<AuthBloc>().add(RefreshScheduleDataEvent());
          SnackBarHelper.show(
            context,
            'Example schedule re-imported.',
            useRootMessenger: true,
          );
          widget.onNavigateRequested?.call(AppRoute.coursesScreen);
        }
      } else {
        SnackBarHelper.show(
          context,
          'Failed to import example schedule.',
          type: SnackType.error,
        );
      }
    } on DioException catch (e) {
      _log.severe('Example schedule import failed', e);
      if (mounted) {
        SnackBarHelper.show(
          context,
          _extractErrorMessage(e) ?? 'Failed to import example schedule.',
          type: SnackType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isImportingExample = false;
        });
        widget.onCompleted?.call();
      }
    }
  }

  String? _extractErrorMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      if (data.containsKey('details')) {
        return data['details'].toString();
      }
      if (data.containsKey('detail')) {
        return data['detail'].toString();
      }
    }
    return null;
  }
}
