import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:heliumapp/presentation/ui/layout/responsive_center_card.dart';

/// Scaffold for full-page unauthenticated screens (sign in, sign up, account
/// setup). With no bottom navigation, content flows edge-to-edge past the
/// bottom safe area, with bottom padding so the last item rests above the home
/// indicator.
///
/// Deliberately does not wrap in a [Title] widget. Every screen using this
/// scaffold already extends [BasePageScreenState] and sets the browser title
/// through its own direct-DOM mechanism (see navigation_shell_title_web.dart)
/// — a [Title] widget here would compete with that for control of
/// `document.title`, since Flutter's own [Title] tracking doesn't coordinate
/// with it and can win at unpredictable times (e.g. when a dialog opens
/// elsewhere in the app), overwriting the correct title with this screen's,
/// even if this screen is no longer current.
class UnauthenticatedScaffold extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final bool showCard;

  const UnauthenticatedScaffold({
    super.key,
    required this.child,
    this.maxWidth = 450,
    this.showCard = true,
  });

  @override
  Widget build(BuildContext context) {
    final keyboardInset =
        kIsWeb ? 0.0 : MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        bottom: false,
        child: ResponsiveCenterCard(
          flowIntoBottomInset: true,
          keyboardInset: keyboardInset,
          maxWidth: maxWidth,
          showCard: showCard,
          child: child,
        ),
      ),
    );
  }
}
