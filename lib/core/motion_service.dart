// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

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
