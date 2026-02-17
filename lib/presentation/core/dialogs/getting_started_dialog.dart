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
import 'package:heliumapp/presentation/features/auth/bloc/auth_bloc.dart';
import 'package:heliumapp/presentation/features/auth/bloc/auth_event.dart';
import 'package:heliumapp/presentation/features/auth/bloc/auth_state.dart';
import 'package:heliumapp/presentation/ui/components/helium_elevated_button.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';

class _GettingStartedDialogWidget extends StatelessWidget {
  const _GettingStartedDialogWidget();

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthExampleScheduleDeleted) {
          Navigator.pop(context);
          context.go(AppRoute.coursesScreen);
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to delete example schedule: ${state.message}',
              ),
              backgroundColor: context.colorScheme.error,
            ),
          );
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.rocket_launch_outlined,
                  color: context.colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text('Welcome to Helium!', style: AppStyles.pageTitle(context)),
              ],
            ),
            content: SizedBox(
              width: Responsive.getDialogWidth(context),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    "We've preloaded your account with an example schedule so you can see Helium in action. Take your time exploring!",
                    style: AppStyles.standardBodyText(context),
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFeatureItem(
                            context,
                            icon: Icons.calendar_month_outlined,
                            title: 'Your Planner, your way',
                            description:
                                'Switch between time-based views and Todos. Click for details, drag to reschedule, filter and search across everything, and stay in control of your time.',
                          ),
                          const SizedBox(height: 12),
                          _buildFeatureItem(
                            context,
                            icon: Icons.school_outlined,
                            title: 'Organized by class',
                            description:
                                'Visit Classes to see how schedules, categories, and assignments connect—so you can track weeks, deadlines, and grades in one place.',
                          ),
                          const SizedBox(height: 12),
                          _buildFeatureItem(
                            context,
                            icon: Icons.bar_chart_outlined,
                            title: 'Track your grades',
                            description:
                                'Check out Grades to see how your scores break down by class—great for seeing your progress and helping you decide where to focus next.',
                          ),
                          const SizedBox(height: 12),
                          _buildFeatureItem(
                            context,
                            icon: Icons.sync_outlined,
                            title: 'Sync with other calendars',
                            description:
                                'In Settings, use External Calendars to pull in events from Google Calendar, Apple Calendar, or Outlook—and enable Feeds to share your Helium schedule back to those apps.',
                          ),
                          const SizedBox(height: 12),
                          _buildFeatureItem(
                            context,
                            icon: Icons.devices_outlined,
                            title: 'Available everywhere',
                            description:
                                'Helium works seamlessly across web, iOS, and Android. Your schedule stays in sync no matter which device you use.',
                          ),
                          const SizedBox(height: 12),
                          _buildFeatureItem(
                            context,
                            icon: Icons.auto_delete_outlined,
                            title: 'Ready when you are',
                            description:
                                "You'll see this dialog each time you open Helium or return after a break, until you're ready to clear the example data.",
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              Column(
                children: [
                  SizedBox(
                    width: Responsive.getDialogWidth(context),
                    child: HeliumElevatedButton(
                      buttonText: 'Clear Example Data',
                      icon: Icons.delete_outline,
                      isLoading: isLoading,
                      enabled: !isLoading,
                      backgroundColor: context.colorScheme.error,
                      onPressed: () {
                        context.read<AuthBloc>().add(
                          DeleteExampleScheduleEvent(),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: Responsive.getDialogWidth(context),
                    child: TextButton(
                      onPressed: isLoading ? null : () => _handleClose(context),
                      child: Text(
                        "I'll explore first",
                        style: AppStyles.standardBodyText(
                          context,
                        ).copyWith(color: context.colorScheme.primary),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFeatureItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: context.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: context.colorScheme.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectableText(
                title,
                style: AppStyles.headingText(context).copyWith(
                  color: context.colorScheme.onSurface.withValues(alpha: 0.9),
                ),
              ),
              SelectableText(
                description,
                style: AppStyles.smallSecondaryText(context).copyWith(
                  color: context.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _handleClose(BuildContext context) {
    Navigator.pop(context);
  }
}

Future<void> showGettingStartedDialog({required BuildContext context}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return const _GettingStartedDialogWidget();
    },
  );
}

