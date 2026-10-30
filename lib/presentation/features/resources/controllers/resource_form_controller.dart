import 'package:flutter/cupertino.dart';
import 'package:heliumapp/presentation/features/shared/controllers/basic_form_controller.dart';
import 'package:heliumapp/presentation/features/shared/controllers/linked_note_form_fields.dart';

class ResourceFormController extends BasicFormController
    with LinkedNoteFormFields {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController urlController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final FocusNode urlFocusNode = FocusNode();
  List<int> selectedCourses = [];
  int selectedStatus = 0;
  int selectedCondition = 0;

  /// Null until the user picks a group; unset when opened from "Show All".
  int? selectedResourceGroupId;

  void dispose() {
    titleController.dispose();
    urlController.dispose();
    priceController.dispose();
    urlFocusNode.dispose();
    disposeLinkedNote();
  }
}
