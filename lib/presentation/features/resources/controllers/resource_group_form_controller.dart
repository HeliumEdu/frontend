// Copyright (c) Helium Edu
//
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/cupertino.dart';
import 'package:heliumapp/presentation/features/shared/controllers/basic_form_controller.dart';

class ResourceGroupFormController extends BasicFormController {
  final TextEditingController titleController = TextEditingController();
  bool shownOnCalendar = true;

  void dispose() {
    titleController.dispose();
  }
}
