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
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/data/sources/attachment_remote_data_source.dart';
import 'package:heliumapp/data/sources/event_remote_data_source.dart';
import 'package:heliumapp/data/sources/reminder_remote_data_source.dart';
import 'package:heliumapp/data/models/planner/attachment_model.dart';
import 'package:heliumapp/data/models/planner/event_request_model.dart';
import 'package:heliumapp/data/models/planner/reminder_request_model.dart';
import 'package:heliumapp/data/models/planner/reminder_response_model.dart';
import 'package:heliumapp/data/repositories/attachment_repository_impl.dart';
import 'package:heliumapp/data/repositories/event_repository_impl.dart';
import 'package:heliumapp/data/repositories/reminder_repository_impl.dart';
import 'package:heliumapp/utils/app_colors.dart';
import 'package:heliumapp/utils/app_enums.dart';
import 'package:heliumapp/utils/app_size.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/app_helpers.dart';
import 'package:logging/logging.dart';

final log = Logger('HeliumLogger');

class EventAddReminderScreen extends StatefulWidget {
  final EventRequestModel? eventRequest;

  const EventAddReminderScreen({super.key, this.eventRequest});

  @override
  State<EventAddReminderScreen> createState() => _EventAddReminderScreenState();
}

class _EventAddReminderScreenState extends State<EventAddReminderScreen> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _timeValueController = TextEditingController();

  String? uploadedFileName;
  File? _selectedFile;
  bool _isSubmitting = false;
  bool _isLoadingReminders = false;

  // Edit mode variables
  bool isEditMode = false;
  int? eventId;
  List<ReminderResponseModel>? existingReminders;
  List<AttachmentModel>? existingAttachments;
  bool _hasLoadedData = false;

  // Server reminders for this event
  List<ReminderResponseModel> _serverReminders = [];

  // Server attachments for this event
  List<AttachmentModel> _serverAttachments = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Get arguments to check if this is edit mode
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      if (!_hasLoadedData) {
        isEditMode = args['isEditMode'] == true;
        eventId = args['eventId'];
        existingReminders =
            args['existingReminders'] as List<ReminderResponseModel>?;
        existingAttachments =
            args['existingAttachments'] as List<AttachmentModel>?;

        if (eventId != null) {
          _refreshEventReminders();
          _refreshEventAttachments();
        }

        _hasLoadedData = true;
      }
    }
  }

  Future<void> _refreshEventReminders() async {
    if (eventId == null) return;
    setState(() {
      _isLoadingReminders = true;
    });
    try {
      final reminderDataSource = ReminderRemoteDataSourceImpl(
        dioClient: DioClient(),
      );
      final reminderRepo = ReminderRepositoryImpl(
        remoteDataSource: reminderDataSource,
      );
      final reminders = await reminderRepo.getReminders();
      setState(() {
        _serverReminders = reminders
            .where((r) => r.event != null && r.event!['id'] == eventId)
            .toList();
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
          _isLoadingReminders = false;
        });
      }
    }
  }

  void _showAddOrEditReminderDialog({ReminderResponseModel? existing}) {
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
                      style: AppStyle.aTextStyle.copyWith(
                        color: blackColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(height: 20.v),
                  Text(
                    'Message',
                    style: AppStyle.cTextStyle.copyWith(
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
                      style: AppStyle.eTextStyle.copyWith(
                        color: blackColor,
                      ),
                      decoration: InputDecoration(
                        hintText: '',
                        hintStyle: AppStyle.eTextStyle.copyWith(
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
                        style: AppStyle.eTextStyle.copyWith(
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
                                    style: AppStyle.eTextStyle.copyWith(
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
                  SizedBox(height: 16.v),
                  Text(
                    'When',
                    style: AppStyle.cTextStyle.copyWith(
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
                            style: AppStyle.eTextStyle.copyWith(
                              color: blackColor,
                            ),
                            decoration: InputDecoration(
                              hintText: '',
                              hintStyle: AppStyle.eTextStyle.copyWith(
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
                              style: AppStyle.eTextStyle.copyWith(
                                color: blackColor.withValues(alpha: 0.5),
                              ),
                            ),
                            value: reminderOffsetUnit,
                            items: reminderOffsetUnits.map((unit) {
                              return DropdownMenuItem<String>(
                                value: unit,
                                child: Text(
                                  unit,
                                  style: AppStyle.eTextStyle.copyWith(
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
                            style: AppStyle.cTextStyle.copyWith(
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
                              if (eventId == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Missing event ID. Please try again.',
                                    ),
                                    backgroundColor: redColor,
                                  ),
                                );
                                return;
                              }

                              if (existing != null) {
                                final req = ReminderRequestModel(
                                  title: messageCtrl.text.trim(),
                                  message: messageCtrl.text.trim(),
                                  offset: customVal,
                                  offsetType: reminderOffsetUnits.indexOf(
                                    reminderOffsetUnit,
                                  ),
                                  type: reminderTypes.indexOf(reminderType),
                                  sent: false,
                                  event: eventId!,
                                );
                                await reminderRepo.updateReminder(
                                  existing.id,
                                  req,
                                );
                              } else {
                                final req = ReminderRequestModel(
                                  title: messageCtrl.text.trim(),
                                  message: messageCtrl.text.trim(),
                                  offset: customVal,
                                  offsetType: reminderOffsetUnits.indexOf(
                                    reminderOffsetUnit,
                                  ),
                                  type: reminderTypes.indexOf(reminderType),
                                  sent: false,
                                  event: eventId!,
                                );
                                await reminderRepo.createReminder(req);
                              }

                              await _refreshEventReminders();
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
                            style: AppStyle.cTextStyle.copyWith(
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

  Future<void> _confirmDeleteReminder(ReminderResponseModel reminder) async {
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Delete Reminder',
          style: AppStyle.cTextStyle.copyWith(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to delete this reminder?',
          style: AppStyle.eTextStyle,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: AppStyle.eTextStyle.copyWith(color: textColor),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                final ds = ReminderRemoteDataSourceImpl(dioClient: DioClient());
                final repo = ReminderRepositoryImpl(remoteDataSource: ds);
                await repo.deleteReminder(reminder.id);
                await _refreshEventReminders();
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
              style: AppStyle.eTextStyle.copyWith(color: redColor),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshEventAttachments() async {
    if (eventId == null) return;
    try {
      final ds = AttachmentRemoteDataSourceImpl(dioClient: DioClient());
      final atts = await ds.getAttachments();
      setState(() {
        _serverAttachments = atts.where((a) => a.event == eventId).toList();
      });
    } catch (e) {
      // non-blocking
      log.info('Failed to load event attachments: $e');
    }
  }

  Future<void> _confirmDeleteAttachment(AttachmentModel attachment) async {
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Delete Attachment',
          style: AppStyle.cTextStyle.copyWith(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to delete this attachment?',
          style: AppStyle.eTextStyle,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: AppStyle.eTextStyle.copyWith(color: textColor),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                final ds = AttachmentRemoteDataSourceImpl(
                  dioClient: DioClient(),
                );
                await ds.deleteAttachment(attachment.id);
                await _refreshEventAttachments();
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
              style: AppStyle.eTextStyle.copyWith(color: redColor),
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
        type: FileType.any,
      );

      if (result != null) {
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

  Future<void> _handleSubmit() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      int finalEventId = eventId ?? 0;
      // If eventId is not provided, fall back to creating/updating here (legacy)
      if (finalEventId == 0 && widget.eventRequest != null) {
        final eventDataSource = EventRemoteDataSourceImpl(
          dioClient: DioClient(),
        );
        final eventRepo = EventRepositoryImpl(
          remoteDataSource: eventDataSource,
        );

        if (isEditMode && eventId != null) {
          log.info('📝 Updating event with ID: $eventId...');
          final event = await eventRepo.updateEvent(
            eventId: eventId!,
            request: widget.eventRequest!,
          );
          finalEventId = event.id;
          log.info('✅ Event updated successfully with ID: $finalEventId');
        } else {
          log.info('📝 Creating new event...');
          final event = await eventRepo.createEvent(
            request: widget.eventRequest!,
          );
          finalEventId = event.id;
          log.info('✅ Event created with ID: $finalEventId');
        }
      }

      if (finalEventId == 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Please create event first, then add reminders'),
              backgroundColor: redColor,
            ),
          );
        }
        setState(() {
          _isSubmitting = false;
        });
        return;
      }

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
          event: finalEventId,
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
                      ? 'Event updated successfully!'
                      : 'Event created successfully!',
                ),
              ],
            ),
            backgroundColor: greenColor,
          ),
        );
        // Return to home screen: pop Event Reminder -> pop Add Event
        Navigator.of(context)
          ..pop()
          ..pop();
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
                    'Confirm',
                    style: AppStyle.aTextStyle.copyWith(
                      color: blackColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(Icons.notifications_outlined, color: transparentColor),
                ],
              ),
            ),
            SizedBox(height: 16.v),
            // Add Event Reminder button (top-right)
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
                          'Event',
                          style: AppStyle.iTextStyle.copyWith(
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
                          style: AppStyle.iTextStyle.copyWith(
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
                    vertical: 9.v,
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
                        style: AppStyle.cTextStyle.copyWith(
                          color: whiteColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Main Content
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 24.v),

                      // Existing server reminders list
                      if (_isLoadingReminders)
                        Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 16.v),
                            child: CircularProgressIndicator(
                              color: primaryColor,
                              valueColor: AlwaysStoppedAnimation(whiteColor),
                            ),
                          ),
                        )
                      else if (_serverReminders.isNotEmpty) ...[
                        Text(
                          'Reminders',
                          style: AppStyle.cTextStyle.copyWith(
                            color: blackColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 12.v),
                        ..._serverReminders.map((rem) {
                          return Container(
                            margin: EdgeInsets.only(bottom: 12.v),
                            padding: EdgeInsets.all(16.h),
                            decoration: BoxDecoration(
                              color: whiteColor,
                              borderRadius: BorderRadius.circular(10.adaptSize),
                              border: Border.all(color: softGrey, width: 1),
                              boxShadow: [
                                BoxShadow(
                                  color: blackColor.withValues(alpha: 0.04),
                                  blurRadius: 6,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                        style: AppStyle.cTextStyle.copyWith(
                                          color: blackColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(height: 4.v),
                                      Text(
                                        formatReminderOffset(rem),
                                        style: AppStyle.iTextStyle.copyWith(
                                          color: textColor.withValues(
                                            alpha: 0.7,
                                          ),
                                          fontSize: 12,
                                        ),
                                      ),
                                      SizedBox(height: 4.v),
                                      Text(
                                        reminderTypes[rem.type],
                                        style: AppStyle.iTextStyle.copyWith(
                                          color: textColor.withValues(
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
                                  onTap: () => _showAddOrEditReminderDialog(
                                    existing: rem,
                                  ),
                                  child: Icon(
                                    Icons.edit_outlined,
                                    color: primaryColor,
                                    size: 20.adaptSize,
                                  ),
                                ),
                                SizedBox(width: 12.h),
                                GestureDetector(
                                  onTap: () => _confirmDeleteReminder(rem),
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

                      Text(
                        'Attachments',
                        style: AppStyle.cTextStyle.copyWith(
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
                              border: Border.all(color: softGrey, width: 1),
                              borderRadius: BorderRadius.circular(8.adaptSize),
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
                                    style: AppStyle.eTextStyle.copyWith(
                                      color: blackColor,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8.h),
                                GestureDetector(
                                  onTap: () => _confirmDeleteAttachment(att),
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
                                color: blackColor.withValues(alpha: 0.03),
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
                                        borderRadius: BorderRadius.circular(6),
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
                                            style: AppStyle.eTextStyle
                                                .copyWith(
                                                  color: blackColor,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          SizedBox(height: 2.v),
                                          Text(
                                            'Tap to change file',
                                            style: AppStyle.eTextStyle
                                                .copyWith(
                                                  color: blackColor.withValues(
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
                                          _selectedFile = null;
                                        });
                                      },
                                    ),
                                  ],
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.cloud_upload_outlined,
                                      color: primaryColor,
                                      size: 24,
                                    ),
                                    SizedBox(width: 12.h),
                                    Text(
                                      'Choose File',
                                      style: AppStyle.eTextStyle.copyWith(
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
                          onPressed: _isSubmitting ? null : _handleSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            padding: EdgeInsets.symmetric(vertical: 14.v),
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
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      whiteColor,
                                    ),
                                  ),
                                )
                              : Text(
                                  'Save',
                                  style: AppStyle.cTextStyle.copyWith(
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
          ],
        ),
      ),
    );
  }
}
