// Copyright (c) Helium Edu
//
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/material.dart';
import 'package:heliumapp/presentation/features/shared/controllers/basic_form_controller.dart';

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
