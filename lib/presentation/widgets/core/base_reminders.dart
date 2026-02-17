// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/data/models/planner/reminder_model.dart';
import 'package:heliumapp/data/models/planner/request/reminder_request_model.dart';
import 'package:heliumapp/data/repositories/reminder_repository_impl.dart';
import 'package:heliumapp/data/sources/reminder_remote_data_source.dart';
import 'package:heliumapp/presentation/bloc/core/base_event.dart';
import 'package:heliumapp/presentation/bloc/reminder/reminder_bloc.dart';
import 'package:heliumapp/presentation/bloc/reminder/reminder_event.dart';
import 'package:heliumapp/presentation/bloc/reminder/reminder_state.dart';
import 'package:heliumapp/presentation/dialogs/confirm_delete_dialog.dart';
import 'package:heliumapp/presentation/dialogs/reminder_dialog.dart';
import 'package:heliumapp/presentation/views/core/base_page_screen_state.dart'
    show SnackBarHelper;
import 'package:heliumapp/presentation/widgets/multi_step_container.dart';
import 'package:heliumapp/presentation/widgets/empty_card.dart';
import 'package:heliumapp/presentation/widgets/error_card.dart';
import 'package:heliumapp/presentation/widgets/helium_icon_button.dart';
import 'package:heliumapp/presentation/widgets/loading_indicator.dart';
import 'package:heliumapp/presentation/widgets/mobile_gesture_detector.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/format_helpers.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:heliumapp/utils/sort_helpers.dart';
import 'package:meta/meta.dart';

abstract class BaseReminders extends StatelessWidget {
  final DioClient _dioClient = DioClient();
  final int entityId;
  final bool isEdit;
  final UserSettingsModel? userSettings;

  BaseReminders({
    super.key,
    required this.entityId,
    required this.isEdit,
    this.userSettings,
  });

  BaseRemindersContent buildContent();

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => ReminderBloc(
            reminderRepository: ReminderRepositoryImpl(
              remoteDataSource: ReminderRemoteDataSourceImpl(
                dioClient: _dioClient,
              ),
            ),
          ),
        ),
      ],
      child: buildContent(),
    );
  }
}

abstract class BaseRemindersContent extends StatefulWidget {
  final int entityId;
  final bool isEdit;
  final UserSettingsModel? userSettings;

  const BaseRemindersContent({
    super.key,
    required this.entityId,
    required this.isEdit,
    this.userSettings,
  });

  @override
  BaseReminderWidgetState createState();
}

abstract class BaseReminderWidgetState<T extends BaseRemindersContent>
    extends State<T> {
  // State
  List<ReminderModel> reminders = [];
  bool isLoading = true;

  @mustBeOverridden
  FetchRemindersEvent createFetchRemindersEvent();

  @mustBeOverridden
  ReminderRequestModel createReminderRequest(
    String message,
    int offset,
    int offsetType,
    int type,
  );

  @override
  void initState() {
    super.initState();

    if (widget.isEdit) {
      context.read<ReminderBloc>().add(createFetchRemindersEvent());
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ReminderBloc, ReminderState>(
      listener: (context, state) {
        if (state is RemindersFetched) {
          setState(() {
            reminders = state.reminders;
            Sort.byTitle(reminders);
            isLoading = false;
          });
        } else if (state is ReminderCreated) {
          SnackBarHelper.show(context, 'Reminder saved');

          setState(() {
            reminders.add(state.reminder);
            Sort.byTitle(reminders);
          });
        } else if (state is ReminderUpdated) {
          SnackBarHelper.show(context, 'Reminder saved');

          setState(() {
            reminders[reminders.indexWhere((c) => c.id == state.reminder.id)] =
                state.reminder;
            Sort.byTitle(reminders);
          });
        } else if (state is ReminderDeleted) {
          SnackBarHelper.show(context, 'Reminder deleted');

          setState(() {
            reminders.removeWhere((c) => c.id == state.id);
          });
        }
      },
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (isLoading || widget.userSettings == null) {
      return const Center(child: LoadingIndicator(expanded: false));
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Reminders', style: AppStyles.featureText(context)),
            HeliumIconButton(
              onPressed: () {
                showReminderDialog(
                  parentContext: context,
                  isEdit: false,
                  userSettings: widget.userSettings!,
                  createReminderRequest: createReminderRequest,
                );
              },
              icon: Icons.add,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: BlocBuilder<ReminderBloc, ReminderState>(
            builder: (context, state) {
              if (state is RemindersLoading) {
                return const Center(child: LoadingIndicator(expanded: false));
              }

              if (state is RemindersError &&
                  state.origin == EventOrigin.subScreen) {
                return ErrorCard(
                  message: state.message!,
                  onReload: () {
                    context.read<ReminderBloc>().add(
                      createFetchRemindersEvent(),
                    );
                  },
                  expanded: false,
                );
              }

              if (reminders.isEmpty) {
                return const EmptyCard(
                  icon: Icons.notifications_active_outlined,
                  message: 'Click "+" to add a reminder',
                  expanded: false,
                );
              }

              return _buildRemindersList();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRemindersList() {
    return ListView.builder(
      itemCount: reminders.length,
      itemBuilder: (context, index) {
        final reminder = reminders[index];
        return _buildReminderCard(context, reminder);
      },
    );
  }

  Widget _buildReminderCard(BuildContext context, ReminderModel reminder) {
    return MobileGestureDetector(
      onTap: () => _onEdit(reminder),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                ReminderConstants.typeItems[reminder.type].iconData!,
                color: context.colorScheme.primary,
                size: Responsive.getIconSize(
                  context,
                  mobile: 20,
                  tablet: 22,
                  desktop: 24,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${ReminderConstants.types[reminder.type]} ${Format.reminderOffset(reminder)} before',
                      style: AppStyles.standardBodyTextLight(context).copyWith(
                        color: context.colorScheme.onSurface.withValues(
                          alpha: 0.9,
                        ),
                      ),
                    ),
                    const SizedBox(width: 40, child: Divider()),
                    Text(
                      reminder.message,
                      style: AppStyles.standardBodyTextLight(context).copyWith(
                        color: context.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (!Responsive.isMobile(context)) ...[
                HeliumIconButton(
                  onPressed: () => _onEdit(reminder),
                  icon: Icons.edit_outlined,
                ),
                const SizedBox(width: 8),
              ],
              HeliumIconButton(
                onPressed: () {
                  showConfirmDeleteDialog(
                    parentContext: context,
                    item: reminder,
                    onDelete: (r) async {
                      context.read<ReminderBloc>().add(
                        DeleteReminderEvent(
                          origin: EventOrigin.subScreen,
                          id: r.id,
                        ),
                      );
                    },
                  );
                },
                icon: Icons.delete_outline,
                color: context.colorScheme.error,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onEdit(ReminderModel reminder) {
    showReminderDialog(
      parentContext: context,
      isEdit: true,
      userSettings: widget.userSettings!,
      createReminderRequest: createReminderRequest,
      reminder: reminder,
    );
  }
}
