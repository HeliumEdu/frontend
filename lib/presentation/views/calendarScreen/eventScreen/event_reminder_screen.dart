// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:heliumedu/core/dio_client.dart';
import 'package:heliumedu/data/datasources/event_remote_data_source.dart';
import 'package:heliumedu/data/datasources/reminder_remote_data_source.dart';
import 'package:heliumedu/data/datasources/attachment_remote_data_source.dart';
import 'package:heliumedu/data/models/planner/attachment_model.dart';
import 'package:heliumedu/data/models/planner/event_request_model.dart';
import 'package:heliumedu/data/models/planner/reminder_request_model.dart';
import 'package:heliumedu/data/models/planner/reminder_response_model.dart';
import 'package:heliumedu/data/repositories/event_repository_impl.dart';
import 'package:heliumedu/data/repositories/reminder_repository_impl.dart';
import 'package:heliumedu/data/repositories/attachment_repository_impl.dart';
import 'package:heliumedu/utils/app_colors.dart';
import 'package:heliumedu/utils/app_list.dart';
import 'package:heliumedu/utils/app_size.dart';
import 'package:heliumedu/utils/app_text_style.dart';
import 'package:heliumedu/core/fcm_service.dart';
import 'package:easy_stepper/easy_stepper.dart';

class EventReminderScreen extends StatefulWidget {
  final EventRequestModel? eventRequest;

  const EventReminderScreen({super.key, this.eventRequest});

  @override
  State<EventReminderScreen> createState() => _EventReminderScreenState();
}

class _EventReminderScreenState extends State<EventReminderScreen> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _timeValueController = TextEditingController();

  String? selectedReminderMethod;
  String? selectedTimeUnit;
  String? uploadedFileName;
  File? _selectedFile;
  bool _isSubmitting = false;
  bool _isLoadingReminders = false;

  // Edit mode variables
  bool isEditMode = false;
  int? eventId;
  List<ReminderResponseModel>? existingReminders;
  List<AttachmentModel>? existingAttachments;
  int? existingReminderId;
  bool _hasLoadedData = false;

  // Server reminders for this event
  List<ReminderResponseModel> _serverReminders = [];
  // Server attachments for this event
  List<AttachmentModel> _serverAttachments = [];

  int _mapMethodToType(String? method) {
    method = (method ?? '').toLowerCase();
    if (method == 'email') {
      return 1;
    } else if (method == 'text') {
      return 2;
    } else {
      return 0;
    }
  }

  String _mapTypeToMethod(int type) {
    if (type == 0) {
      return 'Popup';
    } else if (type == 1) {
      return 'Text';
    } else {
      return 'Email';
    }
  }

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
          // We already have an event, just load current server data
          _populateReminderData();
          _refreshEventReminders();
          _refreshEventAttachments();
        }

        _hasLoadedData = true;
      }
    }

    selectedReminderMethod ??= 'Popup';
  }

  void _populateReminderData() {
    if (existingReminders != null && existingReminders!.isNotEmpty) {
      setState(() {
        // Get the first reminder (assuming one reminder per event)
        final reminder = existingReminders!.first;
        selectedReminderMethod = _mapTypeToMethod(reminder.type);
        existingReminderId = reminder.id;

        // Set message
        _messageController.text = reminder.message;

        // Calculate and set time based on offset
        final offsetMinutes = reminder.offset;
        if (offsetMinutes % 1440 == 0) {
          _timeValueController.text = (offsetMinutes ~/ 1440).toString();
          selectedTimeUnit = 'Days';
        } else if (offsetMinutes % 60 == 0) {
          _timeValueController.text = (offsetMinutes ~/ 60).toString();
          selectedTimeUnit = 'Hours';
        } else {
          _timeValueController.text = offsetMinutes.toString();
          selectedTimeUnit = 'Minutes';
        }

        print('✅ Pre-populated reminder data: ${reminder.message}');
        print('⏰ Reminder offset: $offsetMinutes minutes');
      });
    }

    // Pre-populate attachment data if exists
    if (existingAttachments != null && existingAttachments!.isNotEmpty) {
      setState(() {
        final attachment = existingAttachments!.first;
        uploadedFileName = attachment.title;
        print('📎 Existing attachment: ${attachment.title}');
      });
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
        _serverReminders = reminders.where((r) => r.event != null && r.event!['id'] == eventId).toList();
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
    String? unitSelection;
    String? methodSelection = existing != null
        ? _mapTypeToMethod(existing.type)
        : 'Popup';

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
          backgroundColor: transparentColor,
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
                        hintText: 'A friendly reminder',
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
                        '',
                        style: AppTextStyle.eTextStyle.copyWith(
                          color: blackColor.withOpacity(0.5),
                        ),
                      ),
                      value: methodSelection,
                      items: reminderTypes.map((method) {
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
                              '',
                              style: AppTextStyle.eTextStyle.copyWith(
                                color: blackColor.withOpacity(0.5),
                              ),
                            ),
                            value: unitSelection,
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

                            try {
                              final reminderDataSource =
                                  ReminderRemoteDataSourceImpl(
                                    dioClient: DioClient(),
                                  );
                              final reminderRepo = ReminderRepositoryImpl(
                                remoteDataSource: reminderDataSource,
                              );
                              final method = methodSelection ?? 'Popup';
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
                                  offset: computedOffset,
                                  offsetType: 0,
                                  type: _mapMethodToType(method),
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
                                  offset: computedOffset,
                                  offsetType: 0,
                                  type: _mapMethodToType(method),
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
              style: AppTextStyle.eTextStyle.copyWith(color: redColor),
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
      debugPrint('Failed to load event attachments: $e');
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
          type: FileType.any
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

  // Helper to convert time unit and value to offset in minutes
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

  String _formatOffset(int offset) {
    if (offset >= 10080) return '1 week before';
    if (offset >= 2880) return '2 days before';
    if (offset >= 1440) return '1 day before';
    if (offset >= 60 && offset % 60 == 0) {
      final hours = (offset / 60).round();
      return '$hours hour${hours == 1 ? '' : 's'} before';
    }
    return '$offset minute${offset == 1 ? '' : 's'} before';
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
          print('📝 Updating event with ID: $eventId...');
          final event = await eventRepo.updateEvent(
            eventId: eventId!,
            request: widget.eventRequest!,
          );
          finalEventId = event.id;
          print('✅ Event updated successfully with ID: $finalEventId');
        } else {
          print('📝 Creating new event...');
          final event = await eventRepo.createEvent(
            request: widget.eventRequest!,
          );
          finalEventId = event.id;
          print('✅ Event created with ID: $finalEventId');
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

      // Step 2: Create or Update Reminder (if message and time are provided)
      if (_messageController.text.trim().isNotEmpty &&
          _timeValueController.text.trim().isNotEmpty) {
        // Validate custom time has unit selected
        if (selectedTimeUnit == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Please select time unit for custom reminder'),
                backgroundColor: redColor,
              ),
            );
          }
          setState(() {
            _isSubmitting = false;
          });
          return;
        }

        // Calculate offset
        final offset = _calculateOffset();
        final type = _mapMethodToType(selectedReminderMethod ?? 'Popup');

        final reminderRequest = ReminderRequestModel(
          title: widget.eventRequest!.title,
          message: _messageController.text.trim(),
          offset: offset,
          offsetType: 0, // 0 = minutes before
          type: type, // channel based on selection
          sent: false,
          event: finalEventId,
        );

        final reminderDataSource = ReminderRemoteDataSourceImpl(
          dioClient: DioClient(),
        );
        final reminderRepo = ReminderRepositoryImpl(
          remoteDataSource: reminderDataSource,
        );

        if (isEditMode && existingReminderId != null) {
          // Update existing reminder
          print('📝 Updating reminder with ID: $existingReminderId...');
          await reminderRepo.updateReminder(
            existingReminderId!,
            reminderRequest,
          );
          print('✅ Reminder updated successfully');
        } else {
          // Create new reminder
          print('📝 Creating new reminder...');
          await reminderRepo.createReminder(reminderRequest);
          print('✅ Reminder created successfully');

          // Register FCM token with HeliumEdu API
          await _registerFCMToken();
        }
      } else if (isEditMode &&
          existingReminderId != null &&
          _messageController.text.trim().isEmpty) {
        // If in edit mode and reminder was deleted (message cleared), delete the reminder
        print('🗑️ Deleting reminder with ID: $existingReminderId...');
        final reminderDataSource = ReminderRemoteDataSourceImpl(
          dioClient: DioClient(),
        );
        final reminderRepo = ReminderRepositoryImpl(
          remoteDataSource: reminderDataSource,
        );

        try {
          await reminderRepo.deleteReminder(existingReminderId!);
          print('✅ Reminder deleted successfully');
        } catch (e) {
          print('⚠️ Could not delete reminder: $e');
        }
      }

      // Step 3: Upload Attachment (if file is selected)
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
          event: finalEventId,
        );
        print('✅ Attachment uploaded successfully');
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
                    'Confirm',
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
            // Add Event Reminder button (top-right)
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 12.h,
                vertical: 12.v,
              ),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 16.h,
                  vertical: 20.v,
                ),
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
                  padding: EdgeInsets.symmetric(
                    horizontal: 8.h,
                    vertical: 8.v,
                  ),
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
                          'Event',
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
                    vertical: 9.v,
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
                          style: AppTextStyle.cTextStyle.copyWith(
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
                                  color: blackColor.withOpacity(0.04),
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
                                        style: AppTextStyle.cTextStyle.copyWith(
                                          color: blackColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(height: 4.v),
                                      Text(
                                        _formatOffset(rem.offset),
                                        style: AppTextStyle.iTextStyle.copyWith(
                                          color: textColor.withOpacity(0.7),
                                          fontSize: 12,
                                        ),
                                      ),
                                      SizedBox(height: 4.v),
                                      Text(
                                        _mapTypeToMethod(rem.type),
                                        style: AppTextStyle.iTextStyle.copyWith(
                                          color: textColor.withOpacity(0.7),
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
                          color: greyColor.withOpacity(0.2),
                          thickness: 1,
                        ),
                        SizedBox(height: 16.v),
                      ],

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
                                    style: AppTextStyle.eTextStyle.copyWith(
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
                                        color: primaryColor.withOpacity(0.1),
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
                                            style: AppTextStyle.eTextStyle
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
                                            style: AppTextStyle.eTextStyle
                                                .copyWith(
                                                  color: blackColor.withOpacity(
                                                    0.5,
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
                                      style: AppTextStyle.eTextStyle.copyWith(
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
                                  style: AppTextStyle.cTextStyle.copyWith(
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

  // Register FCM token with HeliumEdu API
  Future<void> _registerFCMToken() async {
    try {
      final fcmService = FCMService();
      await fcmService.registerTokenWithHeliumEdu();
      print(
        '✅ FCM token registered with HeliumEdu API after event reminder creation',
      );
    } catch (e) {
      print('❌ Failed to register FCM token: $e');
      // Don't show error to user as this is background operation
    }
  }
}
