import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/utils/app_style.dart';

final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

enum SnackType {
  success,
  info,
  error;

  Color backgroundColor(BuildContext context) {
    return switch (this) {
      SnackType.success => context.semanticColors.success,
      SnackType.info => context.semanticColors.info,
      SnackType.error => context.colorScheme.error,
    };
  }

  Color foregroundColor(BuildContext context) {
    return switch (this) {
      SnackType.success => context.semanticColors.onSuccess,
      SnackType.info => context.semanticColors.onInfo,
      SnackType.error => context.colorScheme.onError,
    };
  }
}

class SnackBarHelper {
  static const int _minSeconds = 2;
  static const int _maxSeconds = 7;

  /// An action has to outlive reading — the user still has to reach the button.
  static const int _actionMinSeconds = 6;

  /// Reading time at ~22 characters/second, plus a beat to notice the snack bar,
  /// so no caller has to predict the length of server-supplied text.
  static int durationFor(String message, {bool hasAction = false}) {
    final computed = (1.2 + message.length / 22).round().clamp(
      _minSeconds,
      _maxSeconds,
    );

    return hasAction && computed < _actionMinSeconds
        ? _actionMinSeconds
        : computed;
  }

  /// [seconds] is a floor, not a replacement — it can only lengthen the wait.
  static void show(
    BuildContext context,
    String message, {
    int? seconds,
    SnackType type = SnackType.success,
    bool clearSnackBar = true,
    SnackBarAction? action,
    bool useRootMessenger = false,
  }) {
    final messenger = _resolveMessenger(
      context,
      useRootMessenger: useRootMessenger,
    );
    if (messenger == null) return;

    if (clearSnackBar) {
      messenger.clearSnackBars();
    }

    final effectiveSeconds = math.max(
      durationFor(message, hasAction: action != null),
      seconds ?? 0,
    );

    final controller = messenger.showSnackBar(
      SnackBar(
        content: _CopyableSnackBarContent(
          message: message,
          foregroundColor: type.foregroundColor(context),
        ),
        backgroundColor: type.backgroundColor(context),
        duration: Duration(seconds: effectiveSeconds),
        behavior: SnackBarBehavior.floating,
        action: action,
      ),
    );

    // SnackBar won't automatically close with an action, so set a callback.
    if (action != null) {
      Future.delayed(Duration(seconds: effectiveSeconds), () {
        try {
          controller.close();
        } catch (_) {
          // SnackBar may have already been dismissed.
        }
      });
    }
  }

  static ScaffoldMessengerState? _resolveMessenger(
    BuildContext context, {
    required bool useRootMessenger,
  }) {
    if (!useRootMessenger) {
      final local = ScaffoldMessenger.maybeOf(context);
      if (local != null) return local;
    }
    return rootScaffoldMessengerKey.currentState;
  }
}

/// Snack bar text that copies itself to the clipboard when tapped — a
/// drag-select can't outlast a deliberately short timer.
///
/// Display is clipped so a long server response can't grow over the screen; the
/// clipboard still receives all of [message], and repeat taps are idempotent.
class _CopyableSnackBarContent extends StatefulWidget {
  final String message;
  final Color foregroundColor;

  const _CopyableSnackBarContent({
    required this.message,
    required this.foregroundColor,
  });

  @override
  State<_CopyableSnackBarContent> createState() =>
      _CopyableSnackBarContentState();
}

class _CopyableSnackBarContentState extends State<_CopyableSnackBarContent> {
  static const int _maxLines = 4;

  bool _copied = false;

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: widget.message));

    if (!mounted || _copied) return;

    setState(() {
      _copied = true;
    });
  }

  bool _exceedsMaxLines(TextStyle style, double maxWidth) {
    final painter = TextPainter(
      text: TextSpan(text: widget.message, style: style),
      maxLines: _maxLines,
      textDirection: Directionality.of(context),
    )..layout(maxWidth: maxWidth);

    return painter.didExceedMaxLines;
  }

  @override
  Widget build(BuildContext context) {
    final style = AppStyles.standardBodyText(
      context,
    ).copyWith(color: widget.foregroundColor);

    return GestureDetector(
      onTap: _copyToClipboard,
      behavior: HitTestBehavior.opaque,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final truncated = _exceedsMaxLines(style, constraints.maxWidth);

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      widget.message,
                      style: style,
                      maxLines: _maxLines,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_copied)
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Icon(
                        Icons.assignment_turned_in,
                        size: 18,
                        color: widget.foregroundColor,
                        semanticLabel: 'Copied to clipboard',
                      ),
                    ),
                ],
              ),
              if (truncated && !_copied)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Tap to copy',
                    style: style.copyWith(
                      fontSize: (style.fontSize ?? 14) - 2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
