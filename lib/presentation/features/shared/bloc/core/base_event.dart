// Copyright (c) Helium Edu
//
// SPDX-License-Identifier: Apache-2.0

enum EventOrigin { screen, subScreen, dialog, bloc }

abstract class BaseEvent {
  final EventOrigin origin;

  BaseEvent({required this.origin});
}
