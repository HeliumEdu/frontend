// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/data/models/auth/token_response_model.dart';
import 'package:heliumapp/data/models/no_content_response_model.dart';
import 'package:heliumapp/presentation/bloc/auth/auth_bloc.dart';
import 'package:heliumapp/presentation/bloc/auth/auth_event.dart';
import 'package:heliumapp/presentation/bloc/auth/auth_state.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks/mock_models.dart';
import '../../../mocks/mock_repositories.dart';
import '../../../mocks/register_fallbacks.dart';

void main() {
  late MockAuthRepository mockAuthRepository;
  late MockDioClient mockDioClient;
  late AuthBloc authBloc;

  setUpAll(() {
    registerFallbackValues();
  });

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    mockDioClient = MockDioClient();
    authBloc = AuthBloc(
      authRepository: mockAuthRepository,
      dioClient: mockDioClient,
    );
  });

  tearDown(() {
    authBloc.close();
  });

  group('AuthBloc', () {
    test('initial state is AuthInitial', () {
      expect(authBloc.state, isA<AuthInitial>());
    });

    group('RegisterEvent', () {
      const email = 'test@example.com';
      const password = 'password123';
      const timezone = 'America/New_York';

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthRegistered] when registration succeeds',
        build: () {
          when(
            () => mockAuthRepository.register(any()),
          ).thenAnswer(
            (_) async => NoContentResponseModel(
              message: 'Success',
              username: 'testuser',
            ),
          );
          return authBloc;
        },
        act: (bloc) => bloc.add(
          RegisterEvent(
            email: email,
            password: password,
            timezone: timezone,
          ),
        ),
        expect: () => [isA<AuthLoading>(), isA<AuthRegistered>()],
        verify: (_) {
          verify(() => mockAuthRepository.register(any())).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] when registration fails with ValidationException',
        build: () {
          when(
            () => mockAuthRepository.register(any()),
          ).thenThrow(ValidationException(message: 'Username already exists'));
          return authBloc;
        },
        act: (bloc) => bloc.add(
          RegisterEvent(
            email: email,
            password: password,
            timezone: timezone,
          ),
        ),
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthError>().having(
            (e) => e.message,
            'message',
            'Username already exists',
          ),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] when registration fails with unexpected error',
        build: () {
          when(
            () => mockAuthRepository.register(any()),
          ).thenThrow(Exception('Network error'));
          return authBloc;
        },
        act: (bloc) => bloc.add(
          RegisterEvent(
            email: email,
            password: password,
            timezone: timezone,
          ),
        ),
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthError>().having(
            (e) => e.message,
            'message',
            contains('unexpected error'),
          ),
        ],
      );
    });

    group('LoginEvent', () {
      const username = 'testuser';
      const password = 'password123';

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthLoggedIn] when login succeeds',
        build: () {
          when(() => mockAuthRepository.login(any())).thenAnswer(
            (_) async => TokenResponseModel(
              access: 'access_token',
              refresh: 'refresh_token',
            ),
          );
          return authBloc;
        },
        act: (bloc) =>
            bloc.add(LoginEvent(username: username, password: password)),
        expect: () => [isA<AuthLoading>(), isA<AuthLoggedIn>()],
        verify: (_) {
          verify(() => mockAuthRepository.login(any())).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] when login fails with invalid credentials',
        build: () {
          when(
            () => mockAuthRepository.login(any()),
          ).thenThrow(UnauthorizedException(message: 'Invalid credentials'));
          return authBloc;
        },
        act: (bloc) =>
            bloc.add(LoginEvent(username: username, password: password)),
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthError>().having(
            (e) => e.message,
            'message',
            'Invalid credentials',
          ),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] when login fails with network error',
        build: () {
          when(
            () => mockAuthRepository.login(any()),
          ).thenThrow(NetworkException(message: 'Connection timeout'));
          return authBloc;
        },
        act: (bloc) =>
            bloc.add(LoginEvent(username: username, password: password)),
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthError>().having(
            (e) => e.message,
            'message',
            'Connection timeout',
          ),
        ],
      );
    });

    group('LogoutEvent', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthLoggedOut] when logout succeeds',
        build: () {
          when(() => mockAuthRepository.logout()).thenAnswer((_) async {});
          return authBloc;
        },
        act: (bloc) => bloc.add(LogoutEvent()),
        expect: () => [isA<AuthLoading>(), isA<AuthLoggedOut>()],
        verify: (_) {
          verify(() => mockAuthRepository.logout()).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] when logout fails',
        build: () {
          when(
            () => mockAuthRepository.logout(),
          ).thenThrow(ServerException(message: 'Server error'));
          return authBloc;
        },
        act: (bloc) => bloc.add(LogoutEvent()),
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthError>().having((e) => e.message, 'message', 'Server error'),
        ],
      );
    });

    group('CheckAuthEvent', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthAuthenticated] when valid tokens exist and user fetch succeeds',
        build: () {
          when(
            () => mockDioClient.getAccessToken(),
          ).thenAnswer((_) async => 'valid_access_token');
          when(
            () => mockDioClient.getRefreshToken(),
          ).thenAnswer((_) async => 'valid_refresh_token');
          when(
            () => mockDioClient.fetchSettings(),
          ).thenAnswer((_) async => MockModels.createUser().settings);
          return authBloc;
        },
        act: (bloc) => bloc.add(CheckAuthEvent()),
        expect: () => [isA<AuthAuthenticated>()],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthUnauthenticated] when no access token exists',
        build: () {
          when(
            () => mockDioClient.getAccessToken(),
          ).thenAnswer((_) async => null);
          when(
            () => mockDioClient.getRefreshToken(),
          ).thenAnswer((_) async => null);
          return authBloc;
        },
        act: (bloc) => bloc.add(CheckAuthEvent()),
        expect: () => [
          isA<AuthUnauthenticated>().having(
            (e) => e.message,
            'message',
            contains('No access token'),
          ),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthUnauthenticated] when access token is empty',
        build: () {
          when(
            () => mockDioClient.getAccessToken(),
          ).thenAnswer((_) async => '');
          when(
            () => mockDioClient.getRefreshToken(),
          ).thenAnswer((_) async => '');
          return authBloc;
        },
        act: (bloc) => bloc.add(CheckAuthEvent()),
        expect: () => [isA<AuthUnauthenticated>()],
      );
    });

    group('RefreshTokenEvent', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthTokenRefreshed] when token refresh succeeds',
        build: () {
          when(
            () => mockDioClient.getRefreshToken(),
          ).thenAnswer((_) async => 'valid_refresh_token');
          when(() => mockAuthRepository.refreshToken(any())).thenAnswer(
            (_) async => TokenResponseModel(
              access: 'new_access_token',
              refresh: 'new_refresh_token',
            ),
          );
          return authBloc;
        },
        act: (bloc) => bloc.add(RefreshTokenEvent()),
        expect: () => [isA<AuthLoading>(), isA<AuthTokenRefreshed>()],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthUnauthenticated] when no refresh token exists',
        build: () {
          when(
            () => mockDioClient.getRefreshToken(),
          ).thenAnswer((_) async => null);
          return authBloc;
        },
        act: (bloc) => bloc.add(RefreshTokenEvent()),
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthUnauthenticated>().having(
            (e) => e.message,
            'message',
            contains('No refresh token'),
          ),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthUnauthenticated] and clears storage when refresh fails with UnauthorizedException',
        build: () {
          when(
            () => mockDioClient.getRefreshToken(),
          ).thenAnswer((_) async => 'expired_refresh_token');
          when(
            () => mockAuthRepository.refreshToken(any()),
          ).thenThrow(UnauthorizedException(message: 'Refresh token expired'));
          when(() => mockDioClient.clearStorage()).thenAnswer((_) async {
            return null;
          });
          return authBloc;
        },
        act: (bloc) => bloc.add(RefreshTokenEvent()),
        expect: () => [isA<AuthLoading>(), isA<AuthUnauthenticated>()],
        verify: (_) {
          verify(() => mockDioClient.clearStorage()).called(1);
        },
      );
    });

    group('FetchProfileEvent', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthProfileFetched] when profile fetch succeeds',
        build: () {
          final mockUser = MockModels.createUser(
            id: 1,
            username: 'testuser',
            email: 'test@example.com',
          );
          when(
            () => mockAuthRepository.getUser(),
          ).thenAnswer((_) async => mockUser);
          return authBloc;
        },
        act: (bloc) => bloc.add(FetchProfileEvent()),
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthProfileFetched>().having(
            (s) => s.user.username,
            'username',
            'testuser',
          ),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] when profile fetch fails',
        build: () {
          when(
            () => mockAuthRepository.getUser(),
          ).thenThrow(UnauthorizedException(message: 'Session expired'));
          return authBloc;
        },
        act: (bloc) => bloc.add(FetchProfileEvent()),
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthError>().having(
            (e) => e.message,
            'message',
            'Session expired',
          ),
        ],
      );
    });

    group('ChangePasswordEvent', () {
      const oldPassword = 'oldpass123';
      const newPassword = 'newpass456';

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthPasswordChanged] when password change succeeds',
        build: () {
          when(
            () => mockAuthRepository.changePassword(any()),
          ).thenAnswer((_) async => MockModels.createUser());
          return authBloc;
        },
        act: (bloc) => bloc.add(
          ChangePasswordEvent(
            oldPassword: oldPassword,
            newPassword: newPassword,
          ),
        ),
        expect: () => [isA<AuthLoading>(), isA<AuthPasswordChanged>()],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] when old password is incorrect',
        build: () {
          when(() => mockAuthRepository.changePassword(any())).thenThrow(
            ValidationException(message: 'Current password is incorrect'),
          );
          return authBloc;
        },
        act: (bloc) => bloc.add(
          ChangePasswordEvent(
            oldPassword: oldPassword,
            newPassword: newPassword,
          ),
        ),
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthError>().having(
            (e) => e.message,
            'message',
            'Current password is incorrect',
          ),
        ],
      );
    });

    group('ForgotPasswordEvent', () {
      const email = 'test@example.com';

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthPasswordReset] when forgot password succeeds',
        build: () {
          when(() => mockAuthRepository.forgotPassword(any())).thenAnswer(
            (_) async => NoContentResponseModel(message: 'Email sent'),
          );
          return authBloc;
        },
        act: (bloc) => bloc.add(ForgotPasswordEvent(email: email)),
        expect: () => [isA<AuthLoading>(), isA<AuthPasswordReset>()],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] when email not found',
        build: () {
          when(
            () => mockAuthRepository.forgotPassword(any()),
          ).thenThrow(NotFoundException(message: 'Email not registered'));
          return authBloc;
        },
        act: (bloc) => bloc.add(ForgotPasswordEvent(email: email)),
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthError>().having(
            (e) => e.message,
            'message',
            'Email not registered',
          ),
        ],
      );
    });

    group('DeleteAccountEvent', () {
      const password = 'password123';

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthAccountDeleted] when account deletion succeeds',
        build: () {
          when(() => mockAuthRepository.deleteAccount(any())).thenAnswer(
            (_) async => NoContentResponseModel(message: 'Account deleted'),
          );
          return authBloc;
        },
        act: (bloc) => bloc.add(DeleteAccountEvent(password: password)),
        expect: () => [isA<AuthLoading>(), isA<AuthAccountDeleted>()],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] with code when ValidationException is thrown',
        build: () {
          when(() => mockAuthRepository.deleteAccount(any())).thenThrow(
            ValidationException(message: 'Invalid password', code: '400'),
          );
          return authBloc;
        },
        act: (bloc) => bloc.add(DeleteAccountEvent(password: password)),
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthError>()
              .having((e) => e.message, 'message', 'Invalid password')
              .having((e) => e.code, 'code', '400'),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] when network error occurs',
        build: () {
          when(
            () => mockAuthRepository.deleteAccount(any()),
          ).thenThrow(NetworkException(message: 'No internet connection'));
          return authBloc;
        },
        act: (bloc) => bloc.add(DeleteAccountEvent(password: password)),
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthError>().having(
            (e) => e.message,
            'message',
            'No internet connection',
          ),
        ],
      );
    });

    group('EnablePrivateFeedsEvent', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthProfileFetched] when enabling private feeds succeeds',
        build: () {
          when(
            () => mockAuthRepository.enablePrivateFeeds(),
          ).thenAnswer((_) async => MockModels.createPrivateFeed());
          when(
            () => mockAuthRepository.getUser(),
          ).thenAnswer((_) async => MockModels.createUser());
          return authBloc;
        },
        act: (bloc) => bloc.add(EnablePrivateFeedsEvent()),
        expect: () => [isA<AuthLoading>(), isA<AuthProfileFetched>()],
      );
    });

    group('DisablePrivateFeedsEvent', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthProfileFetched] when disabling private feeds succeeds',
        build: () {
          when(
            () => mockAuthRepository.disablePrivateFeeds(),
          ).thenAnswer((_) async {});
          when(
            () => mockAuthRepository.getUser(),
          ).thenAnswer((_) async => MockModels.createUser());
          return authBloc;
        },
        act: (bloc) => bloc.add(DisablePrivateFeedsEvent()),
        expect: () => [isA<AuthLoading>(), isA<AuthProfileFetched>()],
      );
    });
  });
}
