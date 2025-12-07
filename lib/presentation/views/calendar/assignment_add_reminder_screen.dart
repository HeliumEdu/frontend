// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:io';

import 'package:easy_stepper/easy_stepper.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:helium_mobile/core/dio_client.dart';
import 'package:helium_mobile/data/datasources/attachment_remote_data_source.dart';
import 'package:helium_mobile/data/datasources/reminder_remote_data_source.dart';
import 'package:helium_mobile/data/models/auth/user_profile_model.dart';
import 'package:helium_mobile/data/models/planner/attachment_model.dart';
import 'package:helium_mobile/data/models/planner/reminder_request_model.dart';
import 'package:helium_mobile/data/models/planner/reminder_response_model.dart';
import 'package:helium_mobile/data/repositories/attachment_repository_impl.dart';
import 'package:helium_mobile/data/repositories/reminder_repository_impl.dart';
import 'package:helium_mobile/presentation/views/calendar/calendar_screen.dart';
import 'package:helium_mobile/utils/app_colors.dart';
import 'package:helium_mobile/utils/app_enums.dart';
import 'package:helium_mobile/utils/app_helpers.dart';
import 'package:helium_mobile/utils/app_size.dart';
import 'package:helium_mobile/utils/app_text_style.dart';
import 'package:logging/logging.dart';

final log = Logger('HeliumLogger');

class AssignmentAddReminderScreen extends StatefulWidget {
  final int? groupId;
  final int? courseId;
  final int? homeworkId;
  final bool? isEditMode;

  const AssignmentAddReminderScreen({
    super.key,
    this.groupId,
    this.courseId,
    this.homeworkId,
    this.isEditMode,
  });

  @override
  State<AssignmentAddReminderScreen> createState() =>
      _AssignmentAddReminderScreenState();
}

class _AssignmentAddReminderScreenState
    extends State<AssignmentAddReminderScreen> {
  final DioClient _dioClient = DioClient();
  late UserSettings _userSettings;

  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _timeValueController = TextEditingController();

  String? selectedTimeUnit;
  String? uploadedFileName;
  File? _selectedFile;
  bool _isSubmitting = false;
  bool _isLoadingReminder = false;
  bool isEditMode = false;

  final _formKey = GlobalKey<FormState>();

  // Server reminders (fetched via API)
  List<ReminderResponseModel> _serverReminders = [];
  List<AttachmentModel> _serverAttachments = [];

  Future<void> _confirmDeleteReminder(ReminderResponseModel reminder) async {
    await showDialog(
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
              style: AppTextStyle.eTextStyle.copyWith(color: textColor),
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
    loadSettings();
    // Fetch reminder if in edit mode
    if (widget.homeworkId != null) {
      isEditMode = true;
      _refreshServerReminders();
      _refreshAttachments();
    }
  }

  Future<void> loadSettings() async {
    final awaitedSettings = await _dioClient.getSettings();
    setState(() {
      _userSettings = awaitedSettings;
    });
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
          .where(
            (r) => r.homework != null && r.homework!['id'] == widget.homeworkId,
          )
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
      log.info('Failed to load attachments: $e');
    }
  }

  Future<void> _confirmDeleteAttachment(AttachmentModel attachment) async {
    await showDialog(
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
              style: AppTextStyle.eTextStyle.copyWith(color: textColor),
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

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final fileSize = await file.length();

        // Check file size (max 10mb)
        if (fileSize > 10 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('File size exceeds 10mb limit'),
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

  @override
  void dispose() {
    _messageController.dispose();
    _timeValueController.dispose();
    super.dispose();
  }

  void _showAddOrEditReminderDialog({
    ReminderResponseModel? existing,
    int? index,
  }) {
    final TextEditingController messageCtrl = TextEditingController(
      text: existing?.message ?? '',
    );
    final TextEditingController customValueCtrl = TextEditingController();
    customValueCtrl.text = existing != null ? existing.offset.toString() : '';
    String reminderOffsetUnit = existing != null
        ? reminderOffsetUnits[existing.offsetType]
        : 'Minutes';
    String reminderType = existing != null
        ? reminderTypes[existing.type]
        : 'Popup';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => Dialog(
          backgroundColor: transparentColor,
          child: Container(
            padding: EdgeInsets.all(24.h),
            decoration: BoxDecoration(
              color: whiteColor,
              borderRadius: BorderRadius.circular(16.adaptSize),
              boxShadow: [
                BoxShadow(
                  color: blackColor.withValues(alpha: 0.1),
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
                      border: Border.all(
                        color: blackColor.withValues(alpha: 0.15),
                      ),
                      color: whiteColor,
                    ),
                    child: TextField(
                      controller: messageCtrl,
                      maxLines: 3,
                      style: AppTextStyle.eTextStyle.copyWith(
                        color: blackColor,
                      ),
                      decoration: InputDecoration(
                        hintText: '',
                        hintStyle: AppTextStyle.eTextStyle.copyWith(
                          color: blackColor.withValues(alpha: 0.5),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 14.h,
                          vertical: 12.v,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 8.v),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: blackColor.withValues(alpha: 0.15),
                      ),
                      color: whiteColor,
                    ),
                    child: DropdownButton<String>(
                      icon: Icon(
                        Icons.keyboard_arrow_down,
                        color: blackColor.withValues(alpha: 0.6),
                      ),
                      dropdownColor: whiteColor,
                      isExpanded: true,
                      underline: SizedBox(),
                      hint: Text(
                        '',
                        style: AppTextStyle.eTextStyle.copyWith(
                          color: blackColor.withValues(alpha: 0.5),
                        ),
                      ),
                      value: reminderType,
                      items: reminderTypes
                          .where(
                            (type) =>
                                (existing != null && existing.type == 2) ||
                                type != 'Text',
                          )
                          .map((type) {
                            return DropdownMenuItem<String>(
                              value: type,
                              child: Row(
                                children: [
                                  Icon(
                                    type == 'Email'
                                        ? Icons.mail_outline
                                        : type == 'Text'
                                        ? Icons.phone_android
                                        : Icons.notifications_active_outlined,
                                    size: 18,
                                    color: primaryColor,
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    type,
                                    style: AppTextStyle.eTextStyle.copyWith(
                                      color: blackColor,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          })
                          .toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          reminderType = value!;
                        });
                      },
                    ),
                  ),
                  SizedBox(height: 12.v),
                  Text(
                    'When',
                    style: AppTextStyle.cTextStyle.copyWith(
                      color: blackColor,
                      fontWeight: FontWeight.w600,
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
                              color: blackColor.withValues(alpha: 0.15),
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
                              hintText: '',
                              hintStyle: AppTextStyle.eTextStyle.copyWith(
                                color: blackColor.withValues(alpha: 0.5),
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
                              color: blackColor.withValues(alpha: 0.15),
                            ),
                            color: whiteColor,
                          ),
                          child: DropdownButton<String>(
                            icon: Icon(
                              Icons.keyboard_arrow_down,
                              color: blackColor.withValues(alpha: 0.6),
                            ),
                            dropdownColor: whiteColor,
                            isExpanded: true,
                            underline: SizedBox(),
                            hint: Text(
                              '',
                              style: AppTextStyle.eTextStyle.copyWith(
                                color: blackColor.withValues(alpha: 0.5),
                              ),
                            ),
                            value: reminderOffsetUnit,
                            items: reminderOffsetUnits.map((unit) {
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
                                reminderOffsetUnit = value!;
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

                            final customVal =
                                int.tryParse(customValueCtrl.text.trim()) ?? 0;
                            if (customVal <= 0) {
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
                                  title: messageCtrl.text.trim(),
                                  message: messageCtrl.text.trim(),
                                  offset: customVal,
                                  offsetType: reminderOffsetUnits.indexOf(
                                    reminderOffsetUnit,
                                  ),
                                  type: reminderTypes.indexOf(reminderType),
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
                                  title: messageCtrl.text.trim(),
                                  message: messageCtrl.text.trim(),
                                  offset: customVal,
                                  offsetType: reminderOffsetUnits.indexOf(
                                    reminderOffsetUnit,
                                  ),
                                  type: reminderTypes.indexOf(reminderType),
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
                            'Save',
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

      // Upload Attachment (if file is selected)
      if (_selectedFile != null) {
        log.info('📎 Uploading attachment...');
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
        log.info('✅ Attachment uploaded successfully');
      }

      // Success!
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: whiteColor),
                SizedBox(width: 8),
                Text(
                  isEditMode
                      ? 'Assignment updated successfully!'
                      : 'Assignment created successfully!',
                ),
              ],
            ),
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
                    color: blackColor.withValues(alpha: 0.08),
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
                    isEditMode == true ? 'Edit Reminder' : 'Add Reminder',
                    style: AppTextStyle.aTextStyle.copyWith(
                      color: blackColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(Icons.notifications_outlined, color: transparentColor),
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
                      color: blackColor.withValues(alpha: 0.06),
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
                    defaultLineColor: greyColor.withValues(alpha: 0.3),
                    finishedLineColor: primaryColor,
                    activeLineColor: primaryColor,
                  ),
                  activeStepBorderColor: primaryColor,
                  activeStepIconColor: whiteColor,
                  activeStepBackgroundColor: primaryColor,
                  activeStepTextColor: primaryColor,
                  finishedStepBorderColor: primaryColor,
                  finishedStepBackgroundColor: primaryColor.withValues(
                    alpha: 0.1,
                  ),
                  finishedStepIconColor: primaryColor,
                  finishedStepTextColor: blackColor,
                  unreachedStepBorderColor: greyColor.withValues(alpha: 0.3),
                  unreachedStepBackgroundColor: softGrey,
                  unreachedStepIconColor: greyColor,
                  unreachedStepTextColor: textColor.withValues(alpha: 0.5),
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
                          color: primaryColor.withValues(alpha: 0.1),
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
                      placeTitleAtStart: false,
                    ),
                    EasyStep(
                      customStep: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: primaryColor,
                          border: Border.all(color: primaryColor, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.3),
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
                      placeTitleAtStart: false,
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
                        color: primaryColor.withValues(alpha: 0.2),
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
                        'Reminder',
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
                              color: blackColor.withValues(alpha: 0.6),
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
                                          color: blackColor.withValues(
                                            alpha: 0.04,
                                          ),
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
                                                formatReminderOffset(rem),
                                                style: AppTextStyle.iTextStyle
                                                    .copyWith(
                                                      color: textColor
                                                          .withValues(
                                                            alpha: 0.7,
                                                          ),
                                                      fontSize: 12,
                                                    ),
                                              ),
                                              SizedBox(height: 4.v),
                                              Text(
                                                reminderTypes[rem.type],
                                                style: AppTextStyle.iTextStyle
                                                    .copyWith(
                                                      color: textColor
                                                          .withValues(
                                                            alpha: 0.7,
                                                          ),
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
                                  color: greyColor.withValues(alpha: 0.2),
                                  thickness: 1,
                                ),
                                SizedBox(height: 16.v),
                              ],

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
                                          : primaryColor.withValues(alpha: 0.3),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: blackColor.withValues(
                                          alpha: 0.03,
                                        ),
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
                                                color: primaryColor.withValues(
                                                  alpha: 0.1,
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
                                                              .withValues(
                                                                alpha: 0.5,
                                                              ),
                                                          fontSize: 12,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                Icons.close,
                                                color: redColor,
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
      CalendarScreen.triggerRefresh();
      log.info('🔄 Home screen refresh triggered from reminder screen');
    });
  }
}
