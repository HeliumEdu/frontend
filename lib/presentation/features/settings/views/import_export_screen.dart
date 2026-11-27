import 'dart:async';
import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heliumapp/config/analytics_event.dart';
import 'package:heliumapp/config/app_route.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/config/locale_notifier.dart';
import 'package:heliumapp/core/analytics_service.dart';
import 'package:heliumapp/core/api_url.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/core/dio_error_mapper.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/data/models/auth/user_settings_model.dart';
import 'package:heliumapp/data/models/planner/course_group_model.dart';
import 'package:heliumapp/data/models/planner/course_model.dart';
import 'package:heliumapp/l10n/app_localizations.dart';
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
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:heliumapp/utils/snack_bar_helpers.dart';
import 'package:heliumapp/utils/storage_helpers.dart';
import 'package:heliumapp/utils/url_helpers.dart';
import 'package:logging/logging.dart';

final _log = Logger('presentation.settings');

class ImportExportScreen extends StatefulWidget {
  final UserSettingsModel userSettings;
  final void Function(String route)? onNavigateRequested;
  final VoidCallback? onActionStarted;
  final VoidCallback? onCompleted;
  final VoidCallback? onFailed;

  const ImportExportScreen({
    super.key,
    required this.userSettings,
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
  String? _importedFileName;
  bool _isImporting = false;
  bool _isExporting = false;
  bool _isImportingExample = false;

  // Populated only while a file is selected — the target picker's options.
  List<CourseGroupModel> _courseGroups = [];
  List<CourseModel> _courses = [];
  _ImportTarget? _selectedTarget;
  bool _isLoadingTargets = false;

  bool get _selectedIsIcs => _isIcsFileName(_importedFileName);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InfoContainer(
              text: AppLocalizations.of(context).importExportInfo,
              trailing: HeliumIconButton(
                icon: Icons.menu_book_outlined,
                backgroundColor: context.colorScheme.onSurfaceVariant,
                label: AppLocalizations.of(context).settingsLearnMoreLabel,
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
        Text(AppLocalizations.of(context).importExportImportTitle, style: AppStyles.featureText(context)),
        const SizedBox(height: 8),
        Text(AppLocalizations.of(context).importExportImportDescription, style: AppStyles.standardBodyTextLight(context)),
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
                          _selectedFileName ?? AppLocalizations.of(context).importExportNoFileSelectedLabel,
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
                buttonText: AppLocalizations.of(context).importExportChooseButton,
                icon: Icons.folder_open_outlined,
                fullWidth: false,
              ),
            ],
          ),
        ),
        if (_selectedFileBytes != null) _buildTargetPicker(context),
        const SizedBox(height: 16),
        HeliumElevatedButton(
          onPressed: _importData,
          buttonText: AppLocalizations.of(context).importExportImportButton,
          icon: Icons.upload_outlined,
          isLoading: _isImporting,
          enabled:
              _selectedFileBytes != null &&
              !_isImporting &&
              !_isLoadingTargets &&
              _selectedTarget != null,
        ),
      ],
    );
  }

  Widget _buildTargetPicker(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(
        color: context.colorScheme.outline.withValues(alpha: 0.2),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppLocalizations.of(context).importExportDestinationLabel, style: AppStyles.formLabel(context)),
          const SizedBox(height: 9),
          // The same field while loading (disabled, a spinner for its arrow), so the
          // layout doesn't shift when the destinations arrive.
          DropdownButtonFormField<_ImportTarget>(
            key: ValueKey((_selectedFileName, _isLoadingTargets)),
            initialValue: _selectedTarget,
            isExpanded: true,
            hint: Text(
              AppLocalizations.of(context).importExportDestinationHint,
              style: AppStyles.formText(context),
            ),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.only(left: 12),
              filled: true,
              fillColor: context.colorScheme.surface,
              enabledBorder: border,
              focusedBorder: border,
              disabledBorder: border,
            ),
            icon: _isLoadingTargets
                ? const SizedBox.square(
                    dimension: 24,
                    child: Padding(
                      padding: EdgeInsets.all(4),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : Icon(
                    Icons.keyboard_arrow_down,
                    color: context.colorScheme.primary,
                  ),
            dropdownColor: context.colorScheme.surface,
            style: AppStyles.formText(context),
            items: _buildTargetItems(context),
            onChanged: _isLoadingTargets
                ? null
                : (target) {
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
    if (!_selectedIsIcs) return _buildCourseGroupTargetItems(context);

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
                Text(AppLocalizations.of(context).importExportCreateClassOption, style: AppStyles.formText(context)),
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
            Text(AppLocalizations.of(context).importExportImportAsEventsOption, style: AppStyles.formText(context)),
          ],
        ),
      ),
    );

    return items;
  }

  List<DropdownMenuItem<_ImportTarget>> _buildCourseGroupTargetItems(
    BuildContext context,
  ) {
    final items = <DropdownMenuItem<_ImportTarget>>[
      DropdownMenuItem(
        value: const _ImportTarget(_TargetKind.newCourseGroups),
        child: Row(
          children: [
            Icon(Icons.add, size: 16, color: context.colorScheme.primary),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context).importExportCreateGroupsOption, style: AppStyles.formText(context)),
          ],
        ),
      ),
    ];

    if (_courseGroups.isNotEmpty) items.add(_dividerItem(context));

    for (final group in _courseGroups) {
      items.add(
        DropdownMenuItem(
          value: _ImportTarget(_TargetKind.existingCourseGroup, group.id),
          child: Text(
            group.title,
            style: AppStyles.formText(context),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }

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
        Text(AppLocalizations.of(context).importExportExportTitle, style: AppStyles.featureText(context)),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.of(context).importExportExportDescription,
          style: AppStyles.standardBodyTextLight(context),
        ),
        const SizedBox(height: 16),
        HeliumElevatedButton(
          onPressed: _exportData,
          buttonText: AppLocalizations.of(context).importExportExportButton,
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
        Text(AppLocalizations.of(context).importExportExampleTitle, style: AppStyles.featureText(context)),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.of(context).importExportExampleDescription,
          style: AppStyles.standardBodyTextLight(context),
        ),
        const SizedBox(height: 16),
        HeliumElevatedButton(
          onPressed: _importExampleSchedule,
          buttonText: AppLocalizations.of(context).importExportReimportExampleButton,
          icon: Icons.restore_outlined,
          isLoading: _isImportingExample,
          enabled:
              !_isImportingExample &&
              !widget.userSettings.showGettingStarted,
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
      SnackBarHelper.show(context, error.displayMessage, type: SnackType.error);
    }

    if (result.cancelled || result.files.isEmpty) return;

    final file = result.files.first;
    final isArchive = file.name.toLowerCase().endsWith('.zip');
    final importedFileName =
        isArchive ? _archivedFileName(file.bytes) : file.name;
    final isIcs = _isIcsFileName(importedFileName);
    final contentError = isArchive
        ? null
        : isIcs
            ? _validateIcsFile(file.bytes)
            : _validateJsonFile(file.bytes);
    if (contentError != null) {
      SnackBarHelper.show(context, contentError, type: SnackType.error);
      return;
    }

    setState(() {
      _selectedFileName = file.name;
      _selectedFileBytes = file.bytes;
      _importedFileName = importedFileName;
      // A JSON file imports its own groups unless another destination is chosen.
      _selectedTarget = isIcs
          ? null
          : const _ImportTarget(_TargetKind.newCourseGroups);
      _courseGroups = [];
      _courses = [];
    });

    await _loadImportTargets();
  }

  bool _isIcsFileName(String? name) =>
      name?.toLowerCase().endsWith('.ics') ?? false;

  String? _archivedFileName(Uint8List bytes) {
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (_) {
      return null;
    }
    final names = archive.files
        .where((entry) => entry.isFile)
        .map((entry) => entry.name)
        .where(
          (name) =>
              !name.startsWith('__MACOSX/') &&
              !name.split('/').last.startsWith('._'),
        )
        .toList();
    return names.length == 1 ? names.single : null;
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
      return AppLocalizations.of(context).importExportInvalidJsonError;
    }
    if (decoded is! Map) {
      return AppLocalizations.of(context).importExportInvalidHeliumFileError;
    }
    return null;
  }

  String? _validateIcsFile(Uint8List bytes) {
    final text = utf8.decode(bytes, allowMalformed: true);
    if (!text.contains('BEGIN:VCALENDAR')) {
      return AppLocalizations.of(context).importExportInvalidCalendarError;
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
      // Only an `.ics` destination can be a class.
      final courses = _selectedIsIcs
          ? await repository.getCourses(shownOnCalendar: true)
          : <CourseModel>[];

      if (!mounted) return;

      setState(() {
        _courseGroups = groups;
        _courses = courses;
        // With no class groups to import into, Events is the only `.ics` destination.
        if (_selectedIsIcs) {
          _selectedTarget = _courseGroups.isEmpty
              ? const _ImportTarget(_TargetKind.events)
              : null;
        }
        _isLoadingTargets = false;
      });
    } on HeliumException catch (e) {
      _log.warning(
        'Failed to load import targets: ${e.runtimeType} code=${e.code}',
      );
      _failImportTargetsLoad();
    } catch (e) {
      _log.severe('Failed to load import targets.', e);
      _failImportTargetsLoad();
    }
  }

  void _failImportTargetsLoad() {
    if (!mounted) return;
    setState(() {
      _isLoadingTargets = false;
    });
    SnackBarHelper.show(
      context,
      AppLocalizations.of(context).importExportLoadClassesFailedMessage,
      type: SnackType.error,
    );
  }

  Future<void> _importData() async {
    if (_selectedFileBytes == null || _selectedFileName == null) return;
    final isIcs = _selectedIsIcs;
    final target = _selectedTarget;
    if (target == null) return;

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
        formMap.addAll(_targetFields(target));
      }

      final response = await _dioClient.dio.post(
        isIcs ? ApiUrl.importExportImportIcsUrl : ApiUrl.importExportImportUrl,
        data: FormData.fromMap(formMap),
        queryParameters: target.kind == _TargetKind.existingCourseGroup
            ? {'course_group': target.id}
            : null,
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final summary = _summarizeImport(
          response.data as Map<String, dynamic>,
        );

        // The API answers 200 with zero counts when it recognized nothing.
        if (summary.importedNothing) {
          SnackBarHelper.show(
            context,
            AppLocalizations.of(context).importExportNothingToImportMessage,
            type: SnackType.error,
          );
          return;
        }

        await _dioClient.cacheService.invalidateAll();

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
            summary.message,
            seconds: 7,
            useRootMessenger: true,
          );
          widget.onNavigateRequested?.call(AppRoute.coursesScreen);
        }
      } else {
        SnackBarHelper.show(context, AppLocalizations.of(context).importExportFailedMessage, type: SnackType.error);
      }
    } on DioException catch (e, s) {
      DioErrorMapper.map(e, s);
      if (mounted) {
        SnackBarHelper.show(
          context,
          DioErrorMapper.clientErrorMessage(e) ?? AppLocalizations.of(context).importExportFileFailedMessage,
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
      case _TargetKind.newCourseGroups:
      case _TargetKind.existingCourseGroup:
        return {};
    }
  }

  _ImportSummary _summarizeImport(Map<String, dynamic> data) {
    final l10n = AppLocalizations.of(context);
    var total = 0;
    final parts = <String>[];

    for (final entity in _ImportedEntity.values) {
      final count = data[entity.key] as int? ?? 0;
      if (count == 0) continue;

      total += count;

      final description = entity.describe(count);
      if (description != null) {
        parts.add(description);
      }
    }

    return _ImportSummary(total: total, description: parts.isEmpty ? '' : parts.reduce(l10n.commonListJoin));
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

        final result = await HeliumStorage.downloadBytes(
          response.data!,
          filename,
        );

        if (mounted && !result.cancelled) {
          if (result.saved) {
            SnackBarHelper.show(context, AppLocalizations.of(context).importExportDownloadedMessage(filename));
          } else {
            SnackBarHelper.show(
              context,
              result.errorMessage ?? AppLocalizations.of(context).importExportNothingExportedMessage,
              type: SnackType.error,
            );
          }
        }
      } else {
        SnackBarHelper.show(context, AppLocalizations.of(context).importExportExportFailedMessage, type: SnackType.error);
      }
    } on DioException catch (e, s) {
      DioErrorMapper.map(e, s);
      if (mounted) {
        SnackBarHelper.show(context, AppLocalizations.of(context).importExportExportFailedMessage, type: SnackType.error);
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
        await _dioClient.getSettings(forceRefresh: true);
        if (!mounted) return;
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
            AppLocalizations.of(context).importExportExampleImportedMessage,
            useRootMessenger: true,
          );
          widget.onNavigateRequested?.call(AppRoute.coursesScreen);
        }
      } else {
        SnackBarHelper.show(
          context,
          AppLocalizations.of(context).importExportExampleFailedMessage,
          type: SnackType.error,
        );
      }
    } on DioException catch (e, s) {
      DioErrorMapper.map(e, s);
      if (mounted) {
        SnackBarHelper.show(
          context,
          DioErrorMapper.clientErrorMessage(e) ?? AppLocalizations.of(context).importExportExampleFailedMessage,
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
}

/// Where an import lands. An `.ics` goes to a class or Events (`header` is a non-selectable
/// group label in the picker); a JSON file's classes go to new groups or an existing one.
enum _TargetKind {
  header,
  newCourse,
  existingCourse,
  events,
  newCourseGroups,
  existingCourseGroup,
}

/// A picker destination. `id` is a course-group id for `newCourse`/`header`/
/// `existingCourseGroup`, a course id for `existingCourse`, and null otherwise.
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

/// Every count the import API returns. Omitting one lets an import that landed
/// rows summarize as empty.
enum _ImportedEntity {
  courseGroups('course_groups'),
  courses('courses'),
  courseSchedules('course_schedules'),
  categories('categories'),
  homework('homework'),
  events('events'),
  resourceGroups('resource_groups'),
  resources('resources'),
  reminders('reminders'),
  notes('notes'),
  externalCalendars('external_calendars');

  final String key;

  const _ImportedEntity(this.key);

  /// The imported [count], or null for one that counts toward the total
  /// without being named.
  String? describe(int count) => switch (this) {
    courseGroups || courseSchedules || resourceGroups => null,
    courses => LocaleNotifier().localizations.importExportImportedClasses(count),
    categories => LocaleNotifier().localizations.importExportImportedCategories(count),
    homework => LocaleNotifier().localizations.importExportImportedAssignments(count),
    events => LocaleNotifier().localizations.importExportImportedEvents(count),
    resources => LocaleNotifier().localizations.importExportImportedResources(count),
    reminders => LocaleNotifier().localizations.importExportImportedReminders(count),
    notes => LocaleNotifier().localizations.importExportImportedNotes(count),
    externalCalendars => LocaleNotifier().localizations.importExportImportedExternalCalendars(count),
  };
}

class _ImportSummary {
  final int total;
  final String description;

  const _ImportSummary({required this.total, required this.description});

  bool get importedNothing => total == 0;

  String get message => description.isEmpty
      ? LocaleNotifier().localizations.importExportImportCompleteMessage
      : LocaleNotifier().localizations.importExportImportedMessage(description);
}
