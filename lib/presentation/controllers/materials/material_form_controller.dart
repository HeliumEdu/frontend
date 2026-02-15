// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:heliumapp/presentation/controllers/core/basic_form_controller.dart';

class MaterialFormController extends BasicFormController {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController urlController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final FocusNode urlFocusNode = FocusNode();
  List<int> selectedCourses = [];
  int selectedStatus = 0;
  int selectedCondition = 0;
  String initialNotes = '';

  void dispose() {
    titleController.dispose();
    urlController.dispose();
    priceController.dispose();
    urlFocusNode.dispose();
  }
}
