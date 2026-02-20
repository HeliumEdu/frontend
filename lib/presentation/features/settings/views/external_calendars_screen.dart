// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:heliumapp/config/app_route.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/data/models/planner/external_calendar_model.dart';
import 'package:heliumapp/data/models/planner/request/external_calendar_request_model.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/base_event.dart';
import 'package:heliumapp/presentation/features/planner/bloc/external_calendar_bloc.dart';
import 'package:heliumapp/presentation/features/planner/bloc/external_calendar_event.dart';
import 'package:heliumapp/presentation/features/planner/bloc/external_calendar_state.dart';
import 'package:heliumapp/presentation/features/settings/controllers/external_calendar_form_controller.dart';
import 'package:heliumapp/presentation/features/planner/dialogs/confirm_delete_dialog.dart';
import 'package:heliumapp/presentation/features/settings/dialogs/external_calendar_dialog.dart';
import 'package:heliumapp/presentation/core/views/base_page_screen_state.dart';
import 'package:heliumapp/presentation/ui/feedback/empty_card.dart';
import 'package:heliumapp/presentation/ui/feedback/error_card.dart';
import 'package:heliumapp/presentation/ui/components/helium_icon_button.dart';
import 'package:heliumapp/presentation/ui/feedback/info_container.dart';
import 'package:heliumapp/presentation/ui/feedback/loading_indicator.dart';
import 'package:heliumapp/presentation/ui/layout/mobile_gesture_detector.dart';
import 'package:heliumapp/presentation/ui/layout/page_header.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/color_helpers.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:heliumapp/utils/sort_helpers.dart';

/// Shows as a dialog on desktop, or navigates on mobile.
void showExternalCalendars(BuildContext context) {
  if (Responsive.isMobile(context)) {
    context.push(AppRoute.externalCalendarsScreen);
  } else {
    showScreenAsDialog(
      context,
      child: const ExternalCalendarsScreen(),
      width: AppConstants.leftPanelDialogWidth,
      alignment: Alignment.centerLeft,
      insetPadding: const EdgeInsets.all(0),
    );
  }
}

class ExternalCalendarsScreen extends StatelessWidget {
  const ExternalCalendarsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ExternalCalendarsProvidedScreen();
  }
}

class _ExternalCalendarsProvidedScreen extends StatefulWidget {
  const _ExternalCalendarsProvidedScreen();

  @override
  State<_ExternalCalendarsProvidedScreen> createState() =>
      _ExternalCalendarsProvidedScreenState();
}

class _ExternalCalendarsProvidedScreenState
    extends BasePageScreenState<_ExternalCalendarsProvidedScreen> {
  @override
  String get screenTitle => 'External Calendars';

  @override
  IconData get icon => AppConstants.externalCalendarIcon;

  @override
  ScreenType get screenType => ScreenType.subPage;

  @override
  VoidCallback? get actionButtonCallback => () {
    showExternalCalendarDialog(parentContext: context, isEdit: false);
  };

  @override
  bool get showActionButton => true;

  final ExternalCalendarFormController _formController =
      ExternalCalendarFormController();

  // State
  List<ExternalCalendarModel> _externalCalendars = [];
  final Set<int> _updatingCalendarIds = {};

  @override
  void initState() {
    super.initState();

    context.read<ExternalCalendarBloc>().add(
      FetchExternalCalendarsEvent(origin: EventOrigin.screen),
    );
  }

  @override
  void dispose() {
    _formController.dispose();

    super.dispose();
  }

  @override
  List<BlocListener<dynamic, dynamic>> buildListeners(BuildContext context) {
    return [
      BlocListener<ExternalCalendarBloc, ExternalCalendarState>(
        listener: (context, state) {
          if (state is ExternalCalendarsFetched) {
            _populateInitialStateData(state);
          } else if (state is ExternalCalendarCreated) {
            showSnackBar(context, 'External calendar created');

            setState(() {
              _externalCalendars.add(state.externalCalendar);
              Sort.byTitle(_externalCalendars);
            });
          } else if (state is ExternalCalendarUpdated) {
            // No snackbar on updates

            setState(() {
              _externalCalendars[_externalCalendars.indexWhere(
                    (g) => g.id == state.externalCalendar.id,
                  )] =
                  state.externalCalendar;
              Sort.byTitle(_externalCalendars);
              _updatingCalendarIds.remove(state.externalCalendar.id);
            });
          } else if (state is ExternalCalendarDeleted) {
            showSnackBar(context, 'External calendar deleted');

            setState(() {
              _externalCalendars.removeWhere((g) => g.id == state.id);
            });
          }
        },
      ),
    ];
  }

  @override
  Widget buildHeaderArea(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: InfoContainer(
            text:
                'External calendars allow you to bring other calendars in to Helium',
          ),
        ),
        if (DialogModeProvider.isDialogMode(context))
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                HeliumIconButton(
                  onPressed: () {
                    showExternalCalendarDialog(
                      parentContext: context,
                      isEdit: false,
                    );
                  },
                  icon: Icons.add,
                ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget buildMainArea(BuildContext context) {
    return BlocBuilder<ExternalCalendarBloc, ExternalCalendarState>(
      builder: (context, state) {
        if (state is ExternalCalendarsLoading) {
          return const LoadingIndicator();
        }

        if (state is ExternalCalendarsError &&
            state.origin == EventOrigin.screen) {
          return ErrorCard(
            message: state.message!,
            onReload: () {
              context.read<ExternalCalendarBloc>().add(
                FetchExternalCalendarsEvent(origin: EventOrigin.screen),
              );
            },
          );
        }

        if (_externalCalendars.isEmpty) {
          return EmptyCard(
            icon: icon,
            message: 'Click "+" to add an external calendar',
          );
        }

        return _buildExternalCalendarsList();
      },
    );
  }

  void _populateInitialStateData(ExternalCalendarsFetched state) {
    setState(() {
      _externalCalendars = state.externalCalendars;
      Sort.byTitle(_externalCalendars);
      isLoading = false;
    });
  }

  Widget _buildExternalCalendarsList() {
    return Expanded(
      child: ListView.builder(
        itemCount: _externalCalendars.length,
        itemBuilder: (context, index) {
          return _buildExternalCalendarCard(_externalCalendars[index]);
        },
      ),
    );
  }

  void _toggleShownOnCalendar(
    ExternalCalendarModel externalCalendar,
    bool value,
  ) {
    if (_updatingCalendarIds.contains(externalCalendar.id)) {
      return;
    }

    setState(() {
      _updatingCalendarIds.add(externalCalendar.id);
    });

    final request = ExternalCalendarRequestModel(
      title: externalCalendar.title,
      url: externalCalendar.url,
      color: HeliumColors.colorToHex(externalCalendar.color),
      shownOnCalendar: value,
    );

    context.read<ExternalCalendarBloc>().add(
      UpdateExternalCalendarEvent(
        origin: EventOrigin.screen,
        id: externalCalendar.id,
        request: request,
      ),
    );
  }

  Widget _buildExternalCalendarCard(ExternalCalendarModel externalCalendar) {
    return MobileGestureDetector(
      onTap: () => _onEdit(externalCalendar),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: externalCalendar.color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      externalCalendar.title,
                      style: AppStyles.standardBodyText(context),
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      externalCalendar.url,
                      style: AppStyles.standardBodyTextLight(context).copyWith(
                        color: context.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Switch.adaptive(
                value: externalCalendar.shownOnCalendar!,
                activeTrackColor: context.colorScheme.primary,
                onChanged: _updatingCalendarIds.contains(externalCalendar.id)
                    ? null
                    : (value) {
                        Feedback.forTap(context);
                        _toggleShownOnCalendar(externalCalendar, value);
                      },
              ),
              const SizedBox(width: 8),
              if (!Responsive.isMobile(context)) ...[
                HeliumIconButton(
                  onPressed: () => _onEdit(externalCalendar),
                  icon: Icons.edit_outlined,
                ),
                const SizedBox(width: 8),
              ],
              HeliumIconButton(
                onPressed: () {
                  showConfirmDeleteDialog(
                    parentContext: context,
                    item: externalCalendar,
                    onDelete: (ec) {
                      context.read<ExternalCalendarBloc>().add(
                        DeleteExternalCalendarEvent(
                          origin: EventOrigin.screen,
                          id: ec.id,
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

  void _onEdit(ExternalCalendarModel externalCalendar) {
    showExternalCalendarDialog(
      parentContext: context,
      isEdit: true,
      externalCalendar: externalCalendar,
    );
  }
}
