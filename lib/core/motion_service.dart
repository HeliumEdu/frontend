// Copyright (c) Helium Edu
//
// SPDX-License-Identifier: Apache-2.0

class MotionService {
  static final MotionService _instance = MotionService._internal();

  factory MotionService() => _instance;

  MotionService._internal();

  bool _reduceMotion = false;

  bool get reduceMotion => _reduceMotion;

  void init(bool systemReduceMotion) {
    _reduceMotion = systemReduceMotion;
  }

  Duration effectiveDuration(Duration base) =>
      _reduceMotion ? Duration.zero : base;
}
