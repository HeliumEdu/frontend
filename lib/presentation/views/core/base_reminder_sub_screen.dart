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
import 'package:heliumapp/data/models/planner/reminder_request_model.dart';
import 'package:heliumapp/data/repositories/reminder_repository_impl.dart';
import 'package:heliumapp/data/sources/reminder_remote_data_source.dart';
import 'package:heliumapp/presentation/bloc/core/base_event.dart';
import 'package:heliumapp/presentation/bloc/reminder/reminder_bloc.dart';
import 'package:heliumapp/presentation/bloc/reminder/reminder_event.dart';
import 'package:heliumapp/presentation/bloc/reminder/reminder_state.dart';
import 'package:heliumapp/presentation/dialogs/confirm_delete_dialog.dart';
import 'package:heliumapp/presentation/dialogs/reminder_dialog.dart';
import 'package:heliumapp/presentation/forms/core/reminder_form_controller.dart';
import 'package:heliumapp/presentation/views/core/base_page_screen_state.dart';
import 'package:heliumapp/presentation/widgets/helium_icon_button.dart';
import 'package:heliumapp/presentation/widgets/page_header.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/format_helpers.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:heliumapp/utils/sort_helpers.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

final log = Logger('HeliumLogger');

abstract class BaseReminderScreen extends StatelessWidget {
  final DioClient _dioClient = DioClient();
  final int entityId;
  final bool isEdit;

  BaseReminderScreen({super.key, required this.entityId, required this.isEdit});

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

  const BaseReminderProvidedScreen({
    super.key,
    required this.entityId,
    required this.isEdit,
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

  @override
  Function get saveAction =>
      () => {};

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
            showSnackBar(context, 'Reminder saved');

            setState(() {
              _reminders.add(state.reminder);
              Sort.byTitle(_reminders);
            });
          } else if (state is ReminderUpdated) {
            showSnackBar(context, 'Reminder saved');

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
              Text('Reminders', style: context.sectionHeading),
              HeliumIconButton(
                onPressed: () {
                  showReminderDialog(
                    parentContext: context,
                    isEdit: false,
                    userSettings: userSettings,
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
                return buildLoading();
              }

              if (state is RemindersError &&
                  state.origin == EventOrigin.subScreen) {
                return buildReload(state.message!, () {
                  context.read<ReminderBloc>().add(createFetchRemindersEvent());
                });
              }

              if (_reminders.isEmpty) {
                return buildEmptyPage(
                  icon: Icons.notifications_active_outlined,
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              ReminderConstants.typeItems[reminder.type].icon!,
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
                    reminder.message,
                    style: context.cTextStyle.copyWith(
                      color: context.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Format.reminderOffset(reminder),
                    style: context.iTextStyle.copyWith(
                      color: context.colorScheme.onSurface.withValues(
                        alpha: 0.7,
                      ),
                      fontSize: Responsive.getFontSize(
                        context,
                        mobile: 12,
                        tablet: 13,
                        desktop: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ReminderConstants.types[reminder.type],
                    style: context.iTextStyle.copyWith(
                      color: context.colorScheme.onSurface.withValues(
                        alpha: 0.7,
                      ),
                      fontSize: Responsive.getFontSize(
                        context,
                        mobile: 12,
                        tablet: 13,
                        desktop: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: Responsive.isMobile(context) ? 0 : 8),
            HeliumIconButton(
              onPressed: () {
                showReminderDialog(
                  parentContext: context,
                  isEdit: true,
                  userSettings: userSettings,
                  createReminderRequest: createReminderRequest,
                  reminder: reminder,
                );
              },
              icon: Icons.edit_outlined,
            ),
            SizedBox(width: Responsive.isMobile(context) ? 0 : 8),
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
    );
  }
}
