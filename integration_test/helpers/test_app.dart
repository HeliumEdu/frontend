// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heliumapp/config/app_router.dart';
import 'package:heliumapp/config/pref_service.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/data/repositories/auth_repository_impl.dart';
import 'package:heliumapp/data/sources/auth_remote_data_source.dart';
import 'package:heliumapp/helium_app.dart';
import 'package:heliumapp/presentation/features/auth/bloc/auth_bloc.dart';
import 'package:heliumapp/presentation/features/planner/bloc/external_calendar_bloc.dart';
import 'package:heliumapp/presentation/features/planner/bloc/planneritem_bloc.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/provider_helpers.dart';
import 'package:timezone/data/latest_all.dart' as tz;

bool _initialized = false;

Future<void> initializeTestApp(WidgetTester tester) async {
  if (!_initialized) {
    GoogleFonts.config.allowRuntimeFetching = false;
    tz.initializeTimeZones();

    // Analytics is disabled via ANALYTICS_ENABLED=false dart-define
    await PrefService().init();
    initializeRouter();
    _initialized = true;
  }

  // Clear any stored auth state between tests
  await DioClient().clearStorage();

  final dioClient = DioClient();
  final providerHelpers = ProviderHelpers();

  await tester.pumpWidget(
    MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => AuthBloc(
            authRepository: AuthRepositoryImpl(
              remoteDataSource: AuthRemoteDataSourceImpl(dioClient: dioClient),
            ),
            dioClient: dioClient,
          ),
        ),
        BlocProvider<ExternalCalendarBloc>(
          create: providerHelpers.createExternalCalendarBloc(),
        ),
        BlocProvider<PlannerItemBloc>(
          create: providerHelpers.createPlannerItemBloc(),
        ),
      ],
      child: const HeliumApp(),
    ),
  );

  // Wait for the app to settle
  await tester.pumpAndSettle();
}

/// Helper to enter text into a field by hint text
Future<void> enterTextByHint(
  WidgetTester tester,
  String hintText,
  String text,
) async {
  final field = find.widgetWithText(TextField, hintText);
  await tester.enterText(field, text);
  await tester.pumpAndSettle();
}

/// Helper to tap a button by text
Future<void> tapButtonByText(WidgetTester tester, String buttonText) async {
  final button = find.text(buttonText);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

/// Helper to wait for a widget to appear with timeout
Future<bool> waitForWidget(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final endTime = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(endTime)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) {
      return true;
    }
  }
  return false;
}
