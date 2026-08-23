import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:heliumapp/config/pref_service.dart';
import 'package:heliumapp/core/cache_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

class MockCacheService extends Mock implements CacheService {}

class MockSharedPreferencesWithCache extends Mock
    implements SharedPreferencesWithCache {}

class MockSharedPreferencesAsync extends Mock
    implements SharedPreferencesAsync {}

class MockPrefService extends Mock implements PrefService {}

class MockDio extends Mock implements Dio {}

class MockFirebaseMessaging extends Mock implements FirebaseMessaging {}

class MockFlutterLocalNotificationsPlugin extends Mock
    implements FlutterLocalNotificationsPlugin {}
