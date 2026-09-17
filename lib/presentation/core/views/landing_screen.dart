import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:heliumapp/config/app_route.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/presentation/features/auth/bloc/auth_bloc.dart';
import 'package:heliumapp/presentation/features/auth/bloc/auth_event.dart';
import 'package:heliumapp/presentation/features/auth/bloc/auth_state.dart';
import 'package:logging/logging.dart';

final _log = Logger('presentation.views');

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final DioClient _dioClient = DioClient();
  String? _deepLinkRoute;

  @override
  void initState() {
    super.initState();

    if (kIsWeb) {
      final uri = Uri.base;
      final currentPath = uri.path;
      if (currentPath.isNotEmpty && currentPath != '/') {
        _deepLinkRoute = currentPath;
        _log.info('Deep link detected: $_deepLinkRoute');
      }
    }

    _checkAutoLogin();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (_, current) =>
          current is AuthAuthenticated ||
          current is AuthTokenRefreshed ||
          current is AuthUnauthenticated ||
          current is AuthError,
      listener: (context, state) {
        if (state is AuthAuthenticated || state is AuthTokenRefreshed) {
          _log.info('Access token is valid, navigating to home');
          _navigateToTarget();
        } else {
          _log.info(
            'Access and refresh tokens missing or invalid, navigating to login',
          );
          _navigateToSignin();
        }
      },
      child: const SizedBox.shrink(),
    );
  }

  Future<void> _checkAutoLogin() async {
    final accessToken = await _dioClient.getAccessToken();

    if (mounted && (accessToken?.isNotEmpty ?? false)) {
      _log.info('Token found, checking authentication ...');

      context.read<AuthBloc>().add(CheckAuthEvent());
    } else {
      _log.info('No token found or context not mounted, navigate to login');
      _navigateToSignin();
    }
  }

  void _navigateToTarget() {
    if (!mounted) return;

    final targetRoute = _deepLinkRoute ?? AppRoute.plannerScreen;
    _log.info('Navigating to: $targetRoute');

    context.go(targetRoute);
  }

  void _navigateToSignin() {
    if (!mounted) return;

    context.replace(AppRoute.signinScreen);
  }
}
