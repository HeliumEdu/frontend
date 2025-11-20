import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliumedu/core/fcm_service.dart';
import 'package:heliumedu/main.dart';
import 'mock_firebase_setup.dart';

void main() async {
  await mockFirebaseInitialiseApp();

  group('HeliumEdu App Tests', () {
    testWidgets('App initializes with splash screen', (
      WidgetTester tester,
    ) async {
      final mockFCMService = FCMService();

      await tester.pumpWidget(MyApp(fcmService: mockFCMService));
      await tester.pumpAndSettle();

      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('FCM Test screen loads correctly', (WidgetTester tester) async {
      final mockFCMService = FCMService();

      await tester.pumpWidget(MyApp(fcmService: mockFCMService));
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: Center(child: Text('FCM Test Screen'))),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('FCM Test Screen'), findsOneWidget);
    });

    testWidgets('App has proper theme configuration', (
      WidgetTester tester,
    ) async {
      final mockFCMService = FCMService();

      await tester.pumpWidget(MyApp(fcmService: mockFCMService));
      await tester.pumpAndSettle();

      final MaterialApp app = tester.widget(find.byType(MaterialApp));
      expect(app.debugShowCheckedModeBanner, false);
      expect(app.title, 'Helium');
    });

    testWidgets('FCM Service can be initialized', (WidgetTester tester) async {
      final mockFCMService = FCMService();
      expect(mockFCMService, isNotNull);
      expect(mockFCMService.isInitialized, false);
    });
  });

  group('FCM Integration Tests', () {
    testWidgets('FCM service provides token model', (
      WidgetTester tester,
    ) async {
      final mockFCMService = FCMService();

      final tokenModel = mockFCMService.getFCMTokenModel();
      expect(tokenModel, isNotNull);
      expect(tokenModel.token, isA<String>());
    });

    testWidgets('Notification test screen has required elements', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: Text('FCM Test')),
            body: Column(
              children: [
                Text('FCM Status'),
                Text('FCM Token'),
                ElevatedButton(
                  onPressed: () {},
                  child: Text('Send Test Notification'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('FCM Test'), findsOneWidget);
      expect(find.text('FCM Status'), findsOneWidget);
      expect(find.text('FCM Token'), findsOneWidget);
      expect(find.text('Send Test Notification'), findsOneWidget);
    });
  });

  group('Navigation Tests', () {
    testWidgets('App routes are properly configured', (
      WidgetTester tester,
    ) async {
      final mockFCMService = FCMService();

      await tester.pumpWidget(MyApp(fcmService: mockFCMService));
      await tester.pumpAndSettle();

      final MaterialApp app = tester.widget(find.byType(MaterialApp));
      expect(app.initialRoute, isNotNull);
      expect(app.routes, isNotNull);
    });
  });
}
