import 'dart:io';

import 'package:easy_stepper/easy_stepper.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:heliumedu/core/dio_client.dart';
import 'package:heliumedu/data/datasources/attachment_remote_data_source.dart';
import 'package:heliumedu/data/datasources/reminder_remote_data_source.dart';
import 'package:heliumedu/data/models/planner/attachment_model.dart';
import 'package:heliumedu/data/models/planner/reminder_request_model.dart';
import 'package:heliumedu/data/models/planner/reminder_response_model.dart';
import 'package:heliumedu/data/repositories/attachment_repository_impl.dart';
import 'package:heliumedu/data/repositories/reminder_repository_impl.dart';
import 'package:heliumedu/presentation/views/calendarScreen/calendar_screen.dart';
import 'package:heliumedu/utils/app_colors.dart';
import 'package:heliumedu/utils/app_list.dart';
import 'package:heliumedu/utils/app_size.dart';
import 'package:heliumedu/utils/app_text_style.dart';

// Local model to stage multiple reminders before submitting
class _PendingReminder {
  final String message;
  final int offset; // minutes before
  final int type; // notification channel

  _PendingReminder({
    required this.message,
    required this.offset,
    required this.type,
  });
}

class AssignmentReminderScreen extends StatefulWidget {
  final int? groupId;
  final int? courseId;
  final bool? isEditMode;
  final int? homeworkId;

  const AssignmentReminderScreen({
    super.key,
    this.groupId,
    this.courseId,
    this.isEditMode,
    this.homeworkId,
  });

  @override
  State<AssignmentReminderScreen> createState() => _AssignmentReminderScreenState();
}

class _AssignmentReminderScreenState extends State<AssignmentReminderScreen> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _timeValueController = TextEditingController();

  String? _singleReminderMethod;
  String? selectedTimeUnit;
  String? uploadedFileName;
  File? _selectedFile;
  bool _isSubmitting = false;
  bool _isLoadingReminder = false;

  final _formKey = GlobalKey<FormState>();

  // Edit mode data
  ReminderResponseModel? existingReminder;
  int? reminderId;

  // Multiple reminders support
  final List<_PendingReminder> _pendingReminders = [];

  // Server reminders (fetched via API)
  List<ReminderResponseModel> _serverReminders = [];
  List<AttachmentModel> _serverAttachments = [];

  int _mapMethodToType(String? method) {
    if ((method ?? '').toLowerCase() == 'email') return 0;
    return 3; // default to push
  }

  String _mapTypeToMethod(int type) {
    if (type == 0) return 'Email';
    return 'Push';
  }

  Future<void> _confirmDeleteReminder(ReminderResponseModel reminder) async {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Delete Reminder',
          style: AppTextStyle.cTextStyle.copyWith(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to delete this reminder?',
          style: AppTextStyle.eTextStyle,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: AppTextStyle.eTextStyle.copyWith(color: greyColor),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                final reminderDataSource = ReminderRemoteDataSourceImpl(
                  dioClient: DioClient(),
                );
                final reminderRepo = ReminderRepositoryImpl(
                  remoteDataSource: reminderDataSource,
                );
                await reminderRepo.deleteReminder(reminder.id);
                await _refreshServerReminders();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Reminder deleted'),
                      backgroundColor: greenColor,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete: $e'),
                      backgroundColor: redColor,
                    ),
                  );
                }
              }
            },
            child: Text(
              'Delete',
              style: AppTextStyle.eTextStyle.copyWith(color: redColor),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _singleReminderMethod = 'Push';
    // Fetch reminder if in edit mode
    if (widget.homeworkId != null) {
      _refreshServerReminders();
      _refreshAttachments();
    }
  }

  Future<void> _refreshServerReminders() async {
    if (widget.homeworkId == null) return;
    setState(() {
      _isLoadingReminder = true;
    });

    try {
      final reminderDataSource = ReminderRemoteDataSourceImpl(
        dioClient: DioClient(),
      );
      final reminderRepo = ReminderRepositoryImpl(
        remoteDataSource: reminderDataSource,
      );

      final reminders = await reminderRepo.getReminders();
      final filtered = reminders
          .where((r) => r.homework == widget.homeworkId)
          .toList();

      setState(() {
        _serverReminders = filtered;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load reminders: $e'),
            backgroundColor: redColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingReminder = false;
        });
      }
    }
  }

  Future<void> _refreshAttachments() async {
    if (widget.homeworkId == null) return;
    try {
      final attachmentDataSource = AttachmentRemoteDataSourceImpl(
        dioClient: DioClient(),
      );
      final attachments = await attachmentDataSource.getAttachments();
      setState(() {
        _serverAttachments = attachments
            .where((a) => a.homework == widget.homeworkId)
            .toList();
      });
    } catch (e) {
      // Non-blocking
      debugPrint('Failed to load attachments: $e');
    }
  }

  Future<void> _confirmDeleteAttachment(AttachmentModel attachment) async {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Delete Attachment',
          style: AppTextStyle.cTextStyle.copyWith(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to delete this attachment?',
          style: AppTextStyle.eTextStyle,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: AppTextStyle.eTextStyle.copyWith(color: greyColor),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                final attachmentDataSource = AttachmentRemoteDataSourceImpl(
                  dioClient: DioClient(),
                );
                await attachmentDataSource.deleteAttachment(attachment.id);
                await _refreshAttachments();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Attachment deleted'),
                      backgroundColor: greenColor,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete: $e'),
                      backgroundColor: redColor,
                    ),
                  );
                }
              }
            },
            child: Text(
              'Delete',
              style: AppTextStyle.eTextStyle.copyWith(color: redColor),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _timeValueController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final fileSize = await file.length();

        // Check file size (max 10MB)
        if (fileSize > 10 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('File size exceeds 10MB limit'),
                backgroundColor: redColor,
              ),
            );
          }
          return;
        }

        setState(() {
          _selectedFile = file;
          uploadedFileName = result.files.single.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking file: $e'),
            backgroundColor: redColor,
          ),
        );
      }
    }
  }

  int _calculateOffset() {
    final timeValue = int.tryParse(_timeValueController.text) ?? 0;

    if (selectedTimeUnit == 'Minutes') {
      return timeValue;
    } else if (selectedTimeUnit == 'Hours') {
      return timeValue * 60;
    } else if (selectedTimeUnit == 'Days') {
      return timeValue * 24 * 60;
    }
    return timeValue;
  }

  String _formatOffsetForDisplay(int offset) {
    if (offset >= 10080) return '1 week before';
    if (offset >= 2880) return '2 days before';
    if (offset >= 1440) return '1 day before';
    if (offset >= 60 && offset % 60 == 0) {
      return '${(offset / 60).round()} hour${(offset / 60).round() == 1 ? '' : 's'} before';
    }
    return '$offset minute${offset == 1 ? '' : 's'} before';
  }

  void _showAddOrEditReminderDialog({
    ReminderResponseModel? existing,
    int? index,
  }) {
    final TextEditingController messageCtrl = TextEditingController(
      text: existing?.message ?? '',
    );
    final TextEditingController customValueCtrl = TextEditingController();
    String? unitSelection;
    String? methodSelection = existing != null
        ? _mapTypeToMethod(existing.type)
        : 'Push';

    // If editing and existing offset does not match presets, prefill custom
    if (existing != null) {
      final off = existing.offset;
      if (off % (24 * 60) == 0) {
        unitSelection = 'Days';
        customValueCtrl.text = (off / (24 * 60)).round().toString();
      } else if (off % 60 == 0) {
        unitSelection = 'Hours';
        customValueCtrl.text = (off / 60).round().toString();
      } else {
        unitSelection = 'Minutes';
        customValueCtrl.text = off.toString();
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(24.h),
            decoration: BoxDecoration(
              color: whiteColor,
              borderRadius: BorderRadius.circular(16.adaptSize),
              boxShadow: [
                BoxShadow(
                  color: blackColor.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Text(
                      existing == null ? 'Add Reminder' : 'Edit Reminder',
                      style: AppTextStyle.aTextStyle.copyWith(
                        color: blackColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(height: 20.v),
                  Text(
                    'Message',
                    style: AppTextStyle.cTextStyle.copyWith(
                      color: blackColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8.v),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: blackColor.withOpacity(0.15)),
                      color: whiteColor,
                    ),
                    child: TextField(
                      controller: messageCtrl,
                      maxLines: 3,
                      style: AppTextStyle.eTextStyle.copyWith(
                        color: blackColor,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter reminder message',
                        hintStyle: AppTextStyle.eTextStyle.copyWith(
                          color: blackColor.withOpacity(0.5),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 14.h,
                          vertical: 12.v,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.v),
                  Text(
                    'Notification method',
                    style: AppTextStyle.cTextStyle.copyWith(
                      color: blackColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8.v),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: blackColor.withOpacity(0.15)),
                      color: whiteColor,
                    ),
                    child: DropdownButton<String>(
                      icon: Icon(
                        Icons.keyboard_arrow_down,
                        color: blackColor.withOpacity(0.6),
                      ),
                      dropdownColor: whiteColor,
                      isExpanded: true,
                      underline: SizedBox(),
                      hint: Text(
                        'Select method',
                        style: AppTextStyle.eTextStyle.copyWith(
                          color: blackColor.withOpacity(0.5),
                        ),
                      ),
                      value: methodSelection,
                      items: reminderPreferences.map((method) {
                        return DropdownMenuItem<String>(
                          value: method,
                          child: Row(
                            children: [
                              Icon(
                                method == 'Email'
                                    ? Icons.mail_outline
                                    : Icons.notifications_active_outlined,
                                size: 18,
                                color: primaryColor,
                              ),
                              SizedBox(width: 10),
                              Text(
                                method,
                                style: AppTextStyle.eTextStyle.copyWith(
                                  color: blackColor,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          methodSelection = value;
                        });
                      },
                    ),
                  ),
                  Text(
                    'When to remind?',
                    style: AppTextStyle.cTextStyle.copyWith(
                      color: blackColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8.v),
                  Text(
                    'Or enter custom time',
                    style: AppTextStyle.eTextStyle.copyWith(
                      color: blackColor.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8.v),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: blackColor.withOpacity(0.15),
                            ),
                            color: whiteColor,
                          ),
                          child: TextField(
                            controller: customValueCtrl,
                            keyboardType: TextInputType.number,
                            style: AppTextStyle.eTextStyle.copyWith(
                              color: blackColor,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Enter time',
                              hintStyle: AppTextStyle.eTextStyle.copyWith(
                                color: blackColor.withOpacity(0.5),
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 14.h,
                                vertical: 12.v,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.h),
                      Expanded(
                        flex: 3,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: blackColor.withOpacity(0.15),
                            ),
                            color: whiteColor,
                          ),
                          child: DropdownButton<String>(
                            icon: Icon(
                              Icons.keyboard_arrow_down,
                              color: blackColor.withOpacity(0.6),
                            ),
                            dropdownColor: whiteColor,
                            isExpanded: true,
                            underline: SizedBox(),
                            hint: Text(
                              'Select unit',
                              style: AppTextStyle.eTextStyle.copyWith(
                                color: blackColor.withOpacity(0.5),
                              ),
                            ),
                            value: unitSelection,
                            items: reminderTimeUnits.map((unit) {
                              return DropdownMenuItem<String>(
                                value: unit,
                                child: Text(
                                  unit,
                                  style: AppTextStyle.eTextStyle.copyWith(
                                    color: blackColor,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setDialogState(() {
                                unitSelection = value;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.v),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12.v),
                            side: BorderSide(color: primaryColor, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.adaptSize),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: AppTextStyle.cTextStyle.copyWith(
                              color: primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.h),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            // Validate message
                            if (messageCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Please enter a reminder message',
                                  ),
                                  backgroundColor: redColor,
                                ),
                              );
                              return;
                            }

                            if (methodSelection == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Please select a notification method',
                                  ),
                                  backgroundColor: redColor,
                                ),
                              );
                              return;
                            }

                            final customVal =
                                int.tryParse(customValueCtrl.text.trim()) ?? 0;
                            if (customVal <= 0 || unitSelection == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Please enter a valid custom time and unit',
                                  ),
                                  backgroundColor: redColor,
                                ),
                              );
                              return;
                            }

                            int computedOffset = customVal;
                            if (unitSelection == 'Hours') {
                              computedOffset = customVal * 60;
                            } else if (unitSelection == 'Days') {
                              computedOffset = customVal * 24 * 60;
                            }

                            final method = methodSelection ?? 'Push';
                            try {
                              final reminderDataSource =
                                  ReminderRemoteDataSourceImpl(
                                    dioClient: DioClient(),
                                  );
                              final reminderRepo = ReminderRepositoryImpl(
                                remoteDataSource: reminderDataSource,
                              );

                              if (widget.homeworkId == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Missing homework ID. Please go back and try again.',
                                    ),
                                    backgroundColor: redColor,
                                  ),
                                );
                                return;
                              }

                              if (existing != null && index != null) {
                                // Update existing server reminder
                                final req = ReminderRequestModel(
                                  title: 'Assignment Reminder',
                                  message: messageCtrl.text.trim(),
                                  offset: computedOffset,
                                  offsetType: 0,
                                  type: _mapMethodToType(method),
                                  sent: false,
                                  homework: widget.homeworkId!,
                                );
                                await reminderRepo.updateReminder(
                                  existing.id,
                                  req,
                                );
                              } else {
                                // Create new server reminder immediately
                                final req = ReminderRequestModel(
                                  title: 'Assignment Reminder',
                                  message: messageCtrl.text.trim(),
                                  offset: computedOffset,
                                  offsetType: 0,
                                  type: _mapMethodToType(method),
                                  sent: false,
                                  homework: widget.homeworkId!,
                                );
                                await reminderRepo.createReminder(req);
                              }

                              await _refreshServerReminders();

                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      existing != null
                                          ? 'Reminder updated'
                                          : 'Reminder added',
                                    ),
                                    backgroundColor: greenColor,
                                  ),
                                );
                              }
                              Navigator.pop(dialogContext);
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: $e'),
                                    backgroundColor: redColor,
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            padding: EdgeInsets.symmetric(vertical: 12.v),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.adaptSize),
                            ),
                          ),
                          child: Text(
                            existing == null ? 'Add' : 'Update',
                            style: AppTextStyle.cTextStyle.copyWith(
                              color: whiteColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Dialog for creating/editing pending (local) reminders
  void _showAddOrEditPendingReminderDialog({
    _PendingReminder? existing,
    int? index,
  }) {
    final TextEditingController messageCtrl = TextEditingController(
      text: existing?.message ?? '',
    );
    final TextEditingController customValueCtrl = TextEditingController();
    String? unitSelection;
    String? methodSelection = existing != null
        ? _mapTypeToMethod(existing.type)
        : 'Push';

    if (existing != null) {
      final off = existing.offset;
      if (off % (24 * 60) == 0) {
        unitSelection = 'Days';
        customValueCtrl.text = (off / (24 * 60)).round().toString();
      } else if (off % 60 == 0) {
        unitSelection = 'Hours';
        customValueCtrl.text = (off / 60).round().toString();
      } else {
        unitSelection = 'Minutes';
        customValueCtrl.text = off.toString();
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(24.h),
            decoration: BoxDecoration(
              color: whiteColor,
              borderRadius: BorderRadius.circular(16.adaptSize),
              boxShadow: [
                BoxShadow(
                  color: blackColor.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Text(
                      existing == null ? 'Add Reminder' : 'Edit Reminder',
                      style: AppTextStyle.aTextStyle.copyWith(
                        color: blackColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(height: 20.v),
                  Text(
                    'Message',
                    style: AppTextStyle.cTextStyle.copyWith(
                      color: blackColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8.v),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: blackColor.withOpacity(0.15)),
                      color: whiteColor,
                    ),
                    child: TextField(
                      controller: messageCtrl,
                      maxLines: 3,
                      style: AppTextStyle.eTextStyle.copyWith(
                        color: blackColor,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter reminder message',
                        hintStyle: AppTextStyle.eTextStyle.copyWith(
                          color: blackColor.withOpacity(0.5),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 14.h,
                          vertical: 12.v,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.v),
                  Text(
                    'Notification method',
                    style: AppTextStyle.cTextStyle.copyWith(
                      color: blackColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8.v),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: blackColor.withOpacity(0.15)),
                      color: whiteColor,
                    ),
                    child: DropdownButton<String>(
                      icon: Icon(
                        Icons.keyboard_arrow_down,
                        color: blackColor.withOpacity(0.6),
                      ),
                      dropdownColor: whiteColor,
                      isExpanded: true,
                      underline: SizedBox(),
                      hint: Text(
                        'Select method',
                        style: AppTextStyle.eTextStyle.copyWith(
                          color: blackColor.withOpacity(0.5),
                        ),
                      ),
                      value: methodSelection,
                      items: reminderPreferences.map((method) {
                        return DropdownMenuItem<String>(
                          value: method,
                          child: Row(
                            children: [
                              Icon(
                                method == 'Email'
                                    ? Icons.mail_outline
                                    : Icons.notifications_active_outlined,
                                size: 18,
                                color: primaryColor,
                              ),
                              SizedBox(width: 10),
                              Text(
                                method,
                                style: AppTextStyle.eTextStyle.copyWith(
                                  color: blackColor,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          methodSelection = value;
                        });
                      },
                    ),
                  ),
                  SizedBox(height: 16.v),
                  Text(
                    'When to remind?',
                    style: AppTextStyle.cTextStyle.copyWith(
                      color: blackColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8.v),
                  Text(
                    'Or enter custom time',
                    style: AppTextStyle.eTextStyle.copyWith(
                      color: blackColor.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8.v),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: blackColor.withOpacity(0.15),
                            ),
                            color: whiteColor,
                          ),
                          child: TextField(
                            controller: customValueCtrl,
                            keyboardType: TextInputType.number,
                            style: AppTextStyle.eTextStyle.copyWith(
                              color: blackColor,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Enter time',
                              hintStyle: AppTextStyle.eTextStyle.copyWith(
                                color: blackColor.withOpacity(0.5),
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 14.h,
                                vertical: 12.v,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.h),
                      Expanded(
                        flex: 3,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: blackColor.withOpacity(0.15),
                            ),
                            color: whiteColor,
                          ),
                          child: DropdownButton<String>(
                            icon: Icon(
                              Icons.keyboard_arrow_down,
                              color: blackColor.withOpacity(0.6),
                            ),
                            dropdownColor: whiteColor,
                            isExpanded: true,
                            underline: SizedBox(),
                            hint: Text(
                              'Select unit',
                              style: AppTextStyle.eTextStyle.copyWith(
                                color: blackColor.withOpacity(0.5),
                              ),
                            ),
                            value: unitSelection,
                            items: reminderTimeUnits.map((unit) {
                              return DropdownMenuItem<String>(
                                value: unit,
                                child: Text(
                                  unit,
                                  style: AppTextStyle.eTextStyle.copyWith(
                                    color: blackColor,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setDialogState(() {
                                unitSelection = value;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.v),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12.v),
                            side: BorderSide(color: primaryColor, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.adaptSize),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: AppTextStyle.cTextStyle.copyWith(
                              color: primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.h),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (messageCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Please enter a reminder message',
                                  ),
                                  backgroundColor: redColor,
                                ),
                              );
                              return;
                            }

                            if (methodSelection == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Please select a notification method',
                                  ),
                                  backgroundColor: redColor,
                                ),
                              );
                              return;
                            }

                            final customVal =
                                int.tryParse(customValueCtrl.text.trim()) ?? 0;
                            if (customVal <= 0 || unitSelection == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Please enter a valid custom time and unit',
                                  ),
                                  backgroundColor: redColor,
                                ),
                              );
                              return;
                            }

                            int computedOffset = customVal;
                            if (unitSelection == 'Hours') {
                              computedOffset = customVal * 60;
                            } else if (unitSelection == 'Days') {
                              computedOffset = customVal * 24 * 60;
                            }

                            final method = methodSelection ?? 'Push';
                            final item = _PendingReminder(
                              message: messageCtrl.text.trim(),
                              offset: computedOffset,
                              type: _mapMethodToType(method),
                            );

                            setState(() {
                              if (existing != null && index != null) {
                                _pendingReminders[index] = item;
                              } else {
                                _pendingReminders.add(item);
                              }
                            });

                            Navigator.pop(dialogContext);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            padding: EdgeInsets.symmetric(vertical: 12.v),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.adaptSize),
                            ),
                          ),
                          child: Text(
                            existing == null ? 'Add' : 'Update',
                            style: AppTextStyle.cTextStyle.copyWith(
                              color: whiteColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final homeworkId = widget.homeworkId!;

      final reminderDataSource = ReminderRemoteDataSourceImpl(
        dioClient: DioClient(),
      );
      final reminderRepo = ReminderRepositoryImpl(
        remoteDataSource: reminderDataSource,
      );

      // Step 1: Create or Update Reminders
      if (_pendingReminders.isNotEmpty) {
        for (final pr in _pendingReminders) {
          final req = ReminderRequestModel(
            title: 'Assignment Reminder',
            message: pr.message,
            offset: pr.offset,
            offsetType: 0,
            type: pr.type,
            sent: false,
            homework: homeworkId,
          );
          print('📝 Creating reminder (offset=${pr.offset})...');
          await reminderRepo.createReminder(req);
        }
        print('✅ ${_pendingReminders.length} reminder(s) created');

        // Removed token registration here to avoid duplicate/burst notifications
      } else if (_messageController.text.trim().isNotEmpty) {
        // Backward-compatible single reminder path
        final offset = _calculateOffset();
        final int type = _singleReminderMethod != null
            ? _mapMethodToType(_singleReminderMethod!)
            : 3;

        final reminderRequest = ReminderRequestModel(
          title: 'Assignment Reminder',
          message: _messageController.text.trim(),
          offset: offset,
          offsetType: 0,
          type: type,
          sent: false,
          homework: homeworkId,
        );

        if (widget.isEditMode == true && reminderId != null) {
          print('🔄 Updating reminder ID: $reminderId...');
          await reminderRepo.updateReminder(reminderId!, reminderRequest);
          print('✅ Reminder updated successfully');
        } else {
          print('📝 Creating reminder...');
          await reminderRepo.createReminder(reminderRequest);
          print('✅ Reminder created successfully');
          // Removed token registration here to avoid duplicate/burst notifications
        }
      }

      // Step 2: Upload Attachment (if file is selected)
      if (_selectedFile != null) {
        print('📎 Uploading attachment...');
        final attachmentDataSource = AttachmentRemoteDataSourceImpl(
          dioClient: DioClient(),
        );
        final attachmentRepo = AttachmentRepositoryImpl(
          remoteDataSource: attachmentDataSource,
        );

        await attachmentRepo.createAttachment(
          file: _selectedFile!,
          homework: homeworkId,
        );
        print('✅ Attachment uploaded successfully');
      }

      // Success!
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _pendingReminders.isNotEmpty
                  ? '${_pendingReminders.length} reminder(s) created successfully!'
                  : (widget.isEditMode == true
                        ? 'Reminder updated successfully!'
                        : 'Reminder created successfully!'),
            ),
            backgroundColor: greenColor,
          ),
        );
        // Pop both screens to go back to home and refresh
        Navigator.of(context)
          ..pop() // Pop event reminder screen
          ..pop(); // Pop add assignment screen

        // Trigger immediate refresh of home screen data
        _triggerHomeScreenRefresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: redColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: softGrey,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.symmetric(vertical: 16.v, horizontal: 12.h),
              width: double.infinity,
              decoration: BoxDecoration(
                color: whiteColor,
                boxShadow: [
                  BoxShadow(
                    color: blackColor.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.keyboard_arrow_left,
                      color: blackColor,
                      size: 24,
                    ),
                  ),
                  Text(
                    widget.isEditMode == true
                        ? 'Edit Reminder'
                        : 'Add Reminder',
                    style: AppTextStyle.aTextStyle.copyWith(
                      color: blackColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(Icons.notifications_outlined, color: Colors.transparent),
                ],
              ),
            ),
            SizedBox(height: 16.v),

            // Stepper
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.h, vertical: 12.v),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 20.v),
                decoration: BoxDecoration(
                  color: whiteColor,
                  borderRadius: BorderRadius.circular(16.adaptSize),
                  boxShadow: [
                    BoxShadow(
                      color: blackColor.withOpacity(0.06),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: EasyStepper(
                  activeStep: 1,
                  lineStyle: LineStyle(
                    lineLength: 60.h,
                    lineThickness: 3,
                    lineSpace: 4,
                    lineType: LineType.normal,
                    defaultLineColor: greyColor.withOpacity(0.3),
                    finishedLineColor: primaryColor,
                    activeLineColor: primaryColor,
                  ),
                  activeStepBorderColor: primaryColor,
                  activeStepIconColor: whiteColor,
                  activeStepBackgroundColor: primaryColor,
                  activeStepTextColor: primaryColor,
                  finishedStepBorderColor: primaryColor,
                  finishedStepBackgroundColor: primaryColor.withOpacity(0.1),
                  finishedStepIconColor: primaryColor,
                  finishedStepTextColor: blackColor,
                  unreachedStepBorderColor: greyColor.withOpacity(0.3),
                  unreachedStepBackgroundColor: softGrey,
                  unreachedStepIconColor: greyColor,
                  unreachedStepTextColor: textColor.withOpacity(0.5),
                  borderThickness: 2,
                  internalPadding: 12,
                  showLoadingAnimation: false,
                  stepRadius: 28.adaptSize,
                  showStepBorder: true,
                  padding: EdgeInsets.symmetric(horizontal: 8.h, vertical: 8.v),
                  stepShape: StepShape.circle,
                  stepBorderRadius: 15,
                  steppingEnabled: true,
                  disableScroll: true,
                  onStepReached: (index) {
                    if (index == 0) {
                      Navigator.pop(context);
                    }
                  },
                  steps: [
                    EasyStep(
                      customStep: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: primaryColor.withOpacity(0.1),
                          border: Border.all(color: primaryColor, width: 2),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.edit_outlined,
                            color: primaryColor,
                            size: 20.adaptSize,
                          ),
                        ),
                      ),
                      customTitle: Padding(
                        padding: EdgeInsets.only(top: 8.v),
                        child: Text(
                          'Assignment',
                          style: AppTextStyle.iTextStyle.copyWith(
                            color: blackColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 13.fSize,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      topTitle: false,
                    ),
                    EasyStep(
                      customStep: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: primaryColor,
                          border: Border.all(color: primaryColor, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: Offset(0, 3),
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.notifications_active_outlined,
                            color: whiteColor,
                            size: 20.adaptSize,
                          ),
                        ),
                      ),
                      customTitle: Padding(
                        padding: EdgeInsets.only(top: 8.v),
                        child: Text(
                          'Reminder',
                          style: AppTextStyle.iTextStyle.copyWith(
                            color: primaryColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 13.fSize,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      topTitle: false,
                    ),
                  ],
                ),
              ),
            ),

            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () => _showAddOrEditReminderDialog(),
                child: Container(
                  margin: EdgeInsets.only(right: 16.h),
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.h,
                    vertical: 12.v,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(8.adaptSize),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.2),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, color: whiteColor, size: 20),
                      SizedBox(width: 6.h),
                      Text(
                        'Add Reminder',
                        style: AppTextStyle.cTextStyle.copyWith(
                          color: whiteColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ), // Main Content
            Expanded(
              child: _isLoadingReminder
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: primaryColor,
                            valueColor: AlwaysStoppedAnimation(whiteColor),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Loading reminder data...',
                            style: AppTextStyle.cTextStyle.copyWith(
                              color: blackColor.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.h),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 24.v),

                              // Server reminders list
                              if (_serverReminders.isNotEmpty) ...[
                                Text(
                                  'Reminders',
                                  style: AppTextStyle.cTextStyle.copyWith(
                                    color: blackColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 12.v),
                                ..._serverReminders.asMap().entries.map((
                                  entry,
                                ) {
                                  final idx = entry.key;
                                  final rem = entry.value;
                                  return Container(
                                    margin: EdgeInsets.only(bottom: 12.v),
                                    padding: EdgeInsets.all(16.h),
                                    decoration: BoxDecoration(
                                      color: whiteColor,
                                      borderRadius: BorderRadius.circular(
                                        10.adaptSize,
                                      ),
                                      border: Border.all(
                                        color: softGrey,
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: blackColor.withOpacity(0.04),
                                          blurRadius: 6,
                                          offset: Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          Icons.notifications_active_outlined,
                                          color: primaryColor,
                                          size: 20,
                                        ),
                                        SizedBox(width: 10.h),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                rem.message,
                                                style: AppTextStyle.cTextStyle
                                                    .copyWith(
                                                      color: blackColor,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                              ),
                                              SizedBox(height: 4.v),
                                              Text(
                                                _formatOffsetForDisplay(
                                                  rem.offset,
                                                ),
                                                style: AppTextStyle.iTextStyle
                                                    .copyWith(
                                                      color: textColor
                                                          .withOpacity(0.7),
                                                      fontSize: 12,
                                                    ),
                                              ),
                                              SizedBox(height: 4.v),
                                              Text(
                                                _mapTypeToMethod(rem.type),
                                                style: AppTextStyle.iTextStyle
                                                    .copyWith(
                                                      color: textColor
                                                          .withOpacity(0.7),
                                                      fontSize: 12,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(width: 12.h),
                                        GestureDetector(
                                          onTap: () =>
                                              _showAddOrEditReminderDialog(
                                                existing: rem,
                                                index: idx,
                                              ),
                                          child: Icon(
                                            Icons.edit_outlined,
                                            color: primaryColor,
                                            size: 20.adaptSize,
                                          ),
                                        ),
                                        SizedBox(width: 12.h),
                                        GestureDetector(
                                          onTap: () =>
                                              _confirmDeleteReminder(rem),
                                          child: Icon(
                                            Icons.delete_outline,
                                            color: redColor,
                                            size: 20.adaptSize,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                                SizedBox(height: 8.v),
                                Divider(
                                  color: greyColor.withOpacity(0.2),
                                  thickness: 1,
                                ),
                                SizedBox(height: 16.v),
                              ],

                              // Pending reminders list (if any)
                              if (_pendingReminders.isNotEmpty) ...[
                                Text(
                                  'Reminders',
                                  style: AppTextStyle.cTextStyle.copyWith(
                                    color: blackColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 12.v),
                                ..._pendingReminders.asMap().entries.map((
                                  entry,
                                ) {
                                  final idx = entry.key;
                                  final pr = entry.value;
                                  return Container(
                                    margin: EdgeInsets.only(bottom: 12.v),
                                    padding: EdgeInsets.all(16.h),
                                    decoration: BoxDecoration(
                                      color: whiteColor,
                                      borderRadius: BorderRadius.circular(
                                        10.adaptSize,
                                      ),
                                      border: Border.all(
                                        color: softGrey,
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: blackColor.withOpacity(0.04),
                                          blurRadius: 6,
                                          offset: Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          Icons.notifications_active_outlined,
                                          color: primaryColor,
                                          size: 20,
                                        ),
                                        SizedBox(width: 10.h),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                pr.message,
                                                style: AppTextStyle.cTextStyle
                                                    .copyWith(
                                                      color: blackColor,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                              ),
                                              SizedBox(height: 4.v),
                                              Text(
                                                _formatOffsetForDisplay(
                                                  pr.offset,
                                                ),
                                                style: AppTextStyle.iTextStyle
                                                    .copyWith(
                                                      color: textColor
                                                          .withOpacity(0.7),
                                                      fontSize: 12,
                                                    ),
                                              ),
                                              SizedBox(height: 4.v),
                                              Text(
                                                _mapTypeToMethod(pr.type),
                                                style: AppTextStyle.iTextStyle
                                                    .copyWith(
                                                      color: textColor
                                                          .withOpacity(0.7),
                                                      fontSize: 12,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(width: 12.h),
                                        GestureDetector(
                                          onTap: () =>
                                              _showAddOrEditPendingReminderDialog(
                                                existing: pr,
                                                index: idx,
                                              ),
                                          child: Icon(
                                            Icons.edit_outlined,
                                            color: primaryColor,
                                            size: 20.adaptSize,
                                          ),
                                        ),
                                        SizedBox(width: 12.h),
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _pendingReminders.removeAt(idx);
                                            });
                                          },
                                          child: Icon(
                                            Icons.delete_outline,
                                            color: redColor,
                                            size: 20.adaptSize,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                                SizedBox(height: 8.v),
                                Divider(
                                  color: greyColor.withOpacity(0.2),
                                  thickness: 1,
                                ),
                                SizedBox(height: 16.v),
                              ],

                              // Inline reminder fields removed in favor of dialog-based flow

                              // Attachments Section
                              Text(
                                'Attachments',
                                style: AppTextStyle.cTextStyle.copyWith(
                                  color: blackColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 12.v),
                              if (_serverAttachments.isNotEmpty) ...[
                                ..._serverAttachments.map((att) {
                                  return Container(
                                    margin: EdgeInsets.only(bottom: 10.v),
                                    padding: EdgeInsets.all(12.h),
                                    decoration: BoxDecoration(
                                      color: whiteColor,
                                      border: Border.all(
                                        color: softGrey,
                                        width: 1,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        8.adaptSize,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.insert_drive_file,
                                          color: primaryColor,
                                          size: 20,
                                        ),
                                        SizedBox(width: 8.h),
                                        Expanded(
                                          child: Text(
                                            att.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTextStyle.eTextStyle
                                                .copyWith(color: blackColor),
                                          ),
                                        ),
                                        SizedBox(width: 8.h),
                                        GestureDetector(
                                          onTap: () =>
                                              _confirmDeleteAttachment(att),
                                          child: Icon(
                                            Icons.delete_outline,
                                            color: redColor,
                                            size: 20.adaptSize,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                                SizedBox(height: 12.v),
                              ],
                              Text(
                                'Upload File (Optional)',
                                style: AppTextStyle.eTextStyle.copyWith(
                                  color: blackColor.withOpacity(0.8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 8.v),

                              // File Upload Container
                              GestureDetector(
                                onTap: _pickFile,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 14.h,
                                    vertical: 16.v,
                                  ),
                                  decoration: BoxDecoration(
                                    color: whiteColor,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: uploadedFileName != null
                                          ? primaryColor
                                          : primaryColor.withOpacity(0.3),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: blackColor.withOpacity(0.03),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: uploadedFileName != null
                                      ? Row(
                                          children: [
                                            Container(
                                              padding: EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: primaryColor.withOpacity(
                                                  0.1,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Icon(
                                                Icons.insert_drive_file,
                                                color: primaryColor,
                                                size: 20,
                                              ),
                                            ),
                                            SizedBox(width: 12.h),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    uploadedFileName!,
                                                    style: AppTextStyle
                                                        .eTextStyle
                                                        .copyWith(
                                                          color: blackColor,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  SizedBox(height: 2.v),
                                                  Text(
                                                    'Tap to change file',
                                                    style: AppTextStyle
                                                        .eTextStyle
                                                        .copyWith(
                                                          color: blackColor
                                                              .withOpacity(0.5),
                                                          fontSize: 12,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                Icons.close,
                                                color: Colors.red,
                                                size: 20,
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  uploadedFileName = null;
                                                });
                                              },
                                            ),
                                          ],
                                        )
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.cloud_upload_outlined,
                                              color: primaryColor,
                                              size: 24,
                                            ),
                                            SizedBox(width: 12.h),
                                            Text(
                                              'Choose File',
                                              style: AppTextStyle.eTextStyle
                                                  .copyWith(
                                                    color: primaryColor,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),

                              SizedBox(height: 8.v),
                              Text(
                                'Supported formats: PDF, DOC, DOCX, JPG, PNG',
                                style: AppTextStyle.eTextStyle.copyWith(
                                  color: blackColor.withOpacity(0.5),
                                  fontSize: 12,
                                ),
                              ),

                              SizedBox(height: 32.v),

                              // Submit Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isSubmitting
                                      ? null
                                      : _handleSubmit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    padding: EdgeInsets.symmetric(
                                      vertical: 14.v,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    elevation: 2,
                                  ),
                                  child: _isSubmitting
                                      ? SizedBox(
                                          height: 20.h,
                                          width: 20.h,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  whiteColor,
                                                ),
                                          ),
                                        )
                                      : Text(
                                          'Save',
                                          style: AppTextStyle.cTextStyle
                                              .copyWith(
                                                color: whiteColor,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                ),
                              ),

                              SizedBox(height: 24.v),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _triggerHomeScreenRefresh() {
    Future.delayed(Duration(milliseconds: 500), () {
      HomeScreen.triggerRefresh();
      print('🔄 Home screen refresh triggered from reminder screen');
    });
  }
}
