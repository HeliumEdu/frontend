import 'package:flutter/material.dart';

/// Theme extension for semantic colors (success, warning, info)
@immutable
class SemanticColors extends ThemeExtension<SemanticColors> {
  final Color success;
  final Color onSuccess;
  final Color warning;
  final Color info;
  final Color onInfo;
  final Color successContainer;
  final Color warningContainer;
  final Color infoContainer;

  const SemanticColors({
    required this.success,
    required this.onSuccess,
    required this.warning,
    required this.info,
    required this.onInfo,
    required this.successContainer,
    required this.warningContainer,
    required this.infoContainer,
  });

  static const light = SemanticColors(
    success: Color(0xff049f71),
    onSuccess: Colors.white,
    warning: Color(0xffc48d3b),
    info: Color(0xff418eb9),
    onInfo: Colors.white,
    successContainer: Color(0xffE8F5E9),
    warningContainer: Color(0xffFFF8E1),
    infoContainer: Color(0xffdff7e7),
  );

  static const dark = SemanticColors(
    success: Color(0xff33fabe),
    onSuccess: Color(0xff002114),
    warning: Color(0xfffbc313),
    info: Color(0xff5aa2c2),
    onInfo: Color(0xff00232e),
    successContainer: Color(0xff1B3D2F),
    warningContainer: Color(0xff3D3520),
    infoContainer: Color(0xff192f37),
  );

  @override
  SemanticColors copyWith({
    Color? success,
    Color? onSuccess,
    Color? warning,
    Color? info,
    Color? onInfo,
    Color? successContainer,
    Color? warningContainer,
    Color? infoContainer,
  }) {
    return SemanticColors(
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      onInfo: onInfo ?? this.onInfo,
      successContainer: successContainer ?? this.successContainer,
      warningContainer: warningContainer ?? this.warningContainer,
      infoContainer: infoContainer ?? this.infoContainer,
    );
  }

  @override
  SemanticColors lerp(SemanticColors? other, double t) {
    if (other is! SemanticColors) return this;
    return SemanticColors(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
      onInfo: Color.lerp(onInfo, other.onInfo, t)!,
      successContainer: Color.lerp(
        successContainer,
        other.successContainer,
        t,
      )!,
      warningContainer: Color.lerp(
        warningContainer,
        other.warningContainer,
        t,
      )!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
    );
  }
}
