// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

enum EventOrigin { screen, subScreen, dialog, bloc }

abstract class BaseEvent {
  final EventOrigin origin;

  BaseEvent({required this.origin});
}
