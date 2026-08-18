// Copyright (c) Helium Edu
//
// SPDX-License-Identifier: Apache-2.0

import 'package:heliumapp/presentation/features/shared/bloc/core/base_event.dart';

abstract class BaseState {
  final EventOrigin origin;
  final String? message;

  BaseState({required this.origin, this.message});
}
