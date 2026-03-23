// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heliumapp/config/app_route.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/core/api_url.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/presentation/features/auth/bloc/auth_bloc.dart';
import 'package:heliumapp/presentation/features/auth/bloc/auth_event.dart';
import 'package:heliumapp/presentation/ui/components/helium_elevated_button.dart';
import 'package:heliumapp/presentation/ui/feedback/info_container.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/format_helpers.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:heliumapp/utils/snack_bar_helpers.dart';
import 'package:heliumapp/utils/storage_helpers.dart';
import 'package:logging/logging.dart';

final _log = Logger('presentation.settings');

class ImportExportScreen extends StatefulWidget {
  final void Function(String route)? onNavigateRequested;

  const ImportExportScreen({super.key, this.onNavigateRequested});

  @override
  State<ImportExportScreen> createState() => _ImportExportScreenState();
}

class _ImportExportScreenState extends State<ImportExportScreen> {
  final DioClient _dioClient = DioClient();

  // State
  String? _selectedFileName;
  Uint8List? _selectedFileBytes;
  bool _isImporting = false;
  bool _isExporting = false;
  bool _isImportingExample = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: InfoContainer(text: 'Backup and restore your Helium data'),
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
        Text(
          'Import a Helium backup from a JSON file',
          style: AppStyles.standardBodyTextLight(context),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: context.colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(10),
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
            IntrinsicWidth(
              child: HeliumElevatedButton(
                onPressed: _openFileChooser,
                buttonText: 'Choose',
                icon: Icons.folder_open_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        HeliumElevatedButton(
          onPressed: _importData,
          buttonText: 'Import',
          icon: Icons.upload_outlined,
          isLoading: _isImporting,
          enabled: _selectedFileBytes != null && !_isImporting,
        ),
      ],
    );
  }

  Widget _buildExportSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Export', style: AppStyles.featureText(context)),
        const SizedBox(height: 8),
        Text(
          'Export all data (excluding attachments) to a JSON file',
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
          enabled: !_isImportingExample,
        ),
      ],
    );
  }

  Future<void> _openFileChooser() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        if (file.bytes == null) {
          if (mounted) {
            SnackBarHelper.show(
              context,
              'An error occurred while reading the file',
              type: SnackType.error,
            );
          }
          return;
        }

        if (file.size > 10 * 1024 * 1024) {
          if (mounted) {
            SnackBarHelper.show(
              context,
              'File size cannot exceed 10MB',
              type: SnackType.error,
            );
          }
          return;
        }

        setState(() {
          _selectedFileName = file.name;
          _selectedFileBytes = file.bytes;
        });
      }
    } catch (e) {
      _log.severe('Error picking file', e);
      if (mounted) {
        SnackBarHelper.show(
          context,
          'Error selecting file',
          type: SnackType.error,
        );
      }
    }
  }

  Future<void> _importData() async {
    if (_selectedFileBytes == null || _selectedFileName == null) return;

    setState(() {
      _isImporting = true;
    });

    try {
      final formData = FormData.fromMap({
        'file[]': MultipartFile.fromBytes(
          _selectedFileBytes!,
          filename: _selectedFileName!,
        ),
      });

      final response = await _dioClient.dio.post(
        ApiUrl.importExportImportUrl,
        data: formData,
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        await _dioClient.cacheService.invalidateAll();

        final data = response.data as Map<String, dynamic>;
        final counts = _formatImportCounts(data);

        if (mounted) {
          context.read<AuthBloc>().add(RefreshScheduleDataEvent());
          SnackBarHelper.show(
            context,
            'Imported: $counts',
            seconds: counts == 'nothing' ? 2 : 7,
            useRootMessenger: true,
          );
          widget.onNavigateRequested?.call(AppRoute.coursesScreen);
        }
      } else {
        SnackBarHelper.show(context, 'Import failed', type: SnackType.error);
      }
    } on DioException catch (e) {
      _log.severe('Import failed', e);
      if (mounted) {
        final message = _extractErrorMessage(e) ?? 'Import failed';
        SnackBarHelper.show(context, message, type: SnackType.error);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
      }
    }
  }

  String _formatImportCounts(Map<String, dynamic> data) {
    final parts = <String>[];

    final courses = data['courses'] as int? ?? 0;
    if (courses > 0) {
      parts.add('$courses ${courses.plural('class', 'es')}');
    }

    final categories = data['categories'] as int? ?? 0;
    if (categories > 0) {
      parts.add('$categories ${categories == 1 ? 'category' : 'categories'}');
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

    try {
      final response = await _dioClient.dio.get<Uint8List>(
        ApiUrl.importExportExportUrl,
        options: Options(responseType: ResponseType.bytes),
      );

      if (!mounted) return;

      if (response.statusCode == 200 && response.data != null) {
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
            SnackBarHelper.show(context, '"$filename" downloaded');
          } else {
            SnackBarHelper.show(
              context,
              'Failed to save export file',
              type: SnackType.error,
            );
          }
        }
      } else {
        SnackBarHelper.show(context, 'Export failed', type: SnackType.error);
      }
    } on DioException catch (e) {
      _log.severe('Export failed', e);
      if (mounted) {
        SnackBarHelper.show(context, 'Export failed', type: SnackType.error);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  Future<void> _importExampleSchedule() async {
    setState(() {
      _isImportingExample = true;
    });

    try {
      final response = await _dioClient.dio.post(
        ApiUrl.importExportExampleScheduleUrl,
      );

      if (!mounted) return;

      if (response.statusCode == 204) {
        await _dioClient.cacheService.invalidateAll();
        if (mounted) {
          context.read<AuthBloc>().add(FetchProfileEvent());
          context.read<AuthBloc>().add(RefreshScheduleDataEvent());
          SnackBarHelper.show(
            context,
            'Example schedule imported',
            useRootMessenger: true,
          );
          widget.onNavigateRequested?.call(AppRoute.coursesScreen);
        }
      } else {
        SnackBarHelper.show(
          context,
          'Failed to import example schedule',
          type: SnackType.error,
        );
      }
    } on DioException catch (e) {
      _log.severe('Example schedule import failed', e);
      if (mounted) {
        SnackBarHelper.show(
          context,
          'Failed to import example schedule',
          type: SnackType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isImportingExample = false;
        });
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
