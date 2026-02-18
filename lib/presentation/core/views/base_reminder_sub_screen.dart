// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/data/models/planner/reminder_model.dart';
import 'package:heliumapp/data/models/planner/request/reminder_request_model.dart';
import 'package:heliumapp/data/repositories/reminder_repository_impl.dart';
import 'package:heliumapp/data/sources/reminder_remote_data_source.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/base_event.dart';
import 'package:heliumapp/presentation/features/planner/bloc/reminder_bloc.dart';
import 'package:heliumapp/presentation/features/planner/bloc/reminder_event.dart';
import 'package:heliumapp/presentation/features/planner/bloc/reminder_state.dart';
import 'package:heliumapp/presentation/features/shared/controllers/reminder_form_controller.dart';
import 'package:heliumapp/presentation/features/planner/dialogs/confirm_delete_dialog.dart';
import 'package:heliumapp/presentation/features/planner/dialogs/reminder_dialog.dart';
import 'package:heliumapp/presentation/core/views/base_page_screen_state.dart';
import 'package:heliumapp/presentation/ui/feedback/empty_card.dart';
import 'package:heliumapp/presentation/ui/feedback/error_card.dart';
import 'package:heliumapp/presentation/ui/components/helium_icon_button.dart';
import 'package:heliumapp/presentation/ui/feedback/loading_indicator.dart';
import 'package:heliumapp/presentation/ui/layout/mobile_gesture_detector.dart';
import 'package:heliumapp/presentation/ui/layout/page_header.dart';
import 'package:heliumapp/presentation/features/planner/constants/reminder_constants.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/format_helpers.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:heliumapp/utils/sort_helpers.dart';
import 'package:meta/meta.dart';

abstract class BaseReminderScreen extends StatelessWidget {
  final DioClient _dioClient = DioClient();
  final int entityId;
  final bool isEdit;
  final bool isNew;

  BaseReminderScreen({
    super.key,
    required this.entityId,
    required this.isEdit,
    required this.isNew,
  });

  BaseReminderProvidedScreen buildScreen();

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
      child: buildScreen(),
    );
  }
}

abstract class BaseReminderProvidedScreen extends StatefulWidget {
  final int entityId;
  final bool isEdit;
  final bool isNew;

  const BaseReminderProvidedScreen({
    super.key,
    required this.entityId,
    required this.isEdit,
    required this.isNew,
  });

  @override
  BasePageScreenState<BaseReminderProvidedScreen> createState();
}

abstract class BaseReminderScreenState<T>
    extends BasePageScreenState<BaseReminderProvidedScreen> {
  @override
  ScreenType get screenType => ScreenType.subPage;

  @override
  Function get cancelAction =>
      () => {context.pop()};

  final ReminderFormController _formController = ReminderFormController();

  // State
  List<ReminderModel> _reminders = [];

  @mustBeOverridden
  StatelessWidget buildStepper();

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
    }
  }

  @override
  void dispose() {
    _formController.dispose();

    super.dispose();
  }

  @override
  List<BlocListener<dynamic, dynamic>> buildListeners(BuildContext context) {
    return [
      BlocListener<ReminderBloc, ReminderState>(
        listener: (context, state) {
          if (state is RemindersFetched) {
            setState(() {
              _reminders = state.reminders;
              Sort.byTitle(_reminders);

              isLoading = false;
            });
          } else if (state is ReminderCreated) {
            showSnackBar(context, 'Reminder created');

            setState(() {
              _reminders.add(state.reminder);
              Sort.byTitle(_reminders);
            });
          } else if (state is ReminderUpdated) {
            // No snackbar on updates

            setState(() {
              _reminders[_reminders.indexWhere(
                    (c) => c.id == state.reminder.id,
                  )] =
                  state.reminder;
              Sort.byTitle(_reminders);
            });
          } else if (state is ReminderDeleted) {
            showSnackBar(context, 'Reminder deleted');

            setState(() {
              _reminders.removeWhere((c) => c.id == state.id);
            });
          }
        },
      ),
    ];
  }

  @override
  Widget buildHeaderArea(BuildContext context) {
    return buildStepper();
  }

  @override
  Widget buildMainArea(BuildContext context) {
    return Expanded(
      child: Column(
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
                    userSettings: userSettings!,
                    createReminderRequest: createReminderRequest,
                  );
                },
                icon: Icons.add,
              ),
            ],
          ),

          const SizedBox(height: 12),

          BlocBuilder<ReminderBloc, ReminderState>(
            builder: (context, state) {
              if (state is RemindersLoading) {
                return const LoadingIndicator();
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
                );
              }

              if (_reminders.isEmpty) {
                return const EmptyCard(
                  icon: Icons.notifications_outlined,
                  message: 'Click "+" to add a reminder',
                );
              }

              return _buildRemindersList();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRemindersList() {
    return Expanded(
      child: ListView.builder(
        itemCount: _reminders.length,
        itemBuilder: (context, index) {
          final reminder = _reminders[index];
          return _buildReminderCard(context, reminder);
        },
      ),
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
                      '${ReminderConstants.types[reminder.type]} ${reminderOffset(reminder)} before',
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
      userSettings: userSettings!,
      createReminderRequest: createReminderRequest,
      reminder: reminder,
    );
  }
}
