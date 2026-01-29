// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:heliumapp/presentation/forms/core/basic_form_controller.dart';

class ReminderFormController extends BasicFormController {
  final TextEditingController messageController = TextEditingController();
  final TextEditingController offsetController = TextEditingController();
  int reminderType = 3;
  int reminderOffsetType = 0;

  void dispose() {
    messageController.dispose();
    offsetController.dispose();
  }
}
