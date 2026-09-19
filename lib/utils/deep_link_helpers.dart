import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:heliumapp/config/app_router.dart';

extension ActiveLocation on GoRouter {
  Uri get activeLocation {
    final configuration = routerDelegate.currentConfiguration;
    if (configuration.isEmpty) return configuration.uri;
    final tail = _leafMatch(configuration.matches.last);
    return tail is ImperativeRouteMatch ? tail.matches.uri : configuration.uri;
  }

  RouteMatchBase _leafMatch(RouteMatchBase match) {
    if (match is ShellRouteMatch && match.matches.isNotEmpty) {
      return _leafMatch(match.matches.last);
    }
    return match;
  }
}

/// Navigates to [uri] and clears all Navigator-pushed routes from the stack.
///
/// [extra] is forwarded to GoRouter so transient context (e.g. dialog payload
/// like [NoteDialogExtra]) can ride along without polluting the URL.
void navigateAndClearStack(BuildContext context, String uri, {Object? extra}) {
  final navigator = Navigator.of(context);
  // addPostFrameCallback doesn't schedule a frame; on a static screen with
  // nothing to pop, deferring would strand the callback until the next event.
  if (!navigator.canPop()) {
    router.go(uri, extra: extra);
    return;
  }
  // Let popped routes' cleanup callbacks settle before GoRouter redirects.
  navigator.popUntil((route) => route.isFirst);
  WidgetsBinding.instance.addPostFrameCallback((_) {
    router.go(uri, extra: extra);
  });
}
