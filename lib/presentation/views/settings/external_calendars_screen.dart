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
import 'package:heliumapp/data/models/planner/external_calendar_model.dart';
import 'package:heliumapp/data/models/planner/external_calendar_request_model.dart';
import 'package:heliumapp/data/repositories/external_calendar_repository_impl.dart';
import 'package:heliumapp/data/sources/external_calendar_remote_data_source.dart';
import 'package:heliumapp/presentation/bloc/core/base_event.dart';
import 'package:heliumapp/presentation/bloc/externalcalendar/external_calendar_bloc.dart';
import 'package:heliumapp/presentation/bloc/externalcalendar/external_calendar_event.dart';
import 'package:heliumapp/presentation/bloc/externalcalendar/external_calendar_state.dart';
import 'package:heliumapp/presentation/dialogs/confirm_delete_dialog.dart';
import 'package:heliumapp/presentation/dialogs/external_calendar_dialog.dart';
import 'package:heliumapp/presentation/forms/settings/external_calendar_form_controller.dart';
import 'package:heliumapp/presentation/views/core/base_page_screen_state.dart';
import 'package:heliumapp/presentation/widgets/empty_card.dart';
import 'package:heliumapp/presentation/widgets/helium_icon_button.dart';
import 'package:heliumapp/presentation/widgets/info_container.dart';
import 'package:heliumapp/presentation/widgets/loading_indicator.dart';
import 'package:heliumapp/presentation/widgets/mobile_gesture_detector.dart';
import 'package:heliumapp/presentation/widgets/page_header.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/color_helpers.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:heliumapp/utils/sort_helpers.dart';

class ExternalCalendarsScreen extends StatelessWidget {
  final DioClient _dioClient = DioClient();

  ExternalCalendarsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => ExternalCalendarBloc(
            externalCalendarRepository: ExternalCalendarRepositoryImpl(
              remoteDataSource: ExternalCalendarRemoteDataSourceImpl(
                dioClient: _dioClient,
              ),
            ),
          ),
        ),
      ],
      child: const ExternalCalendarsProvidedScreen(),
    );
  }
}

class ExternalCalendarsProvidedScreen extends StatefulWidget {
  const ExternalCalendarsProvidedScreen({super.key});

  @override
  State<ExternalCalendarsProvidedScreen> createState() =>
      _ExternalCalendarsProvidedScreenState();
}

class _ExternalCalendarsProvidedScreenState
    extends BasePageScreenState<ExternalCalendarsProvidedScreen> {
  @override
  String get screenTitle => 'External Calendars';

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
            showSnackBar(context, 'External calendar saved');

            setState(() {
              _externalCalendars.add(state.externalCalendar);
              Sort.byTitle(_externalCalendars);
            });
          } else if (state is ExternalCalendarUpdated) {
            showSnackBar(context, 'External calendar saved');

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
    return const Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: InfoContainer(
        text:
            'External calendars allow you to bring other calendars in to Helium',
      ),
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
          return buildReload(state.message!, () {
            context.read<ExternalCalendarBloc>().add(
              FetchExternalCalendarsEvent(origin: EventOrigin.screen),
            );
          });
        }

        if (_externalCalendars.isEmpty) {
          return const EmptyCard(
            icon: Icons.cloud_download,
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
                      style: context.cTextStyle.copyWith(
                        color: context.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      externalCalendar.url,
                      style: context.iTextStyle.copyWith(
                        color: context.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                        fontSize: Responsive.getFontSize(
                          context,
                          mobile: 12,
                          tablet: 13,
                          desktop: 14,
                        ),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
