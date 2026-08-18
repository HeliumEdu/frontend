import 'package:flutter/cupertino.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:heliumapp/presentation/features/shared/controllers/basic_form_controller.dart';
import 'package:heliumapp/utils/quill_helpers.dart';

class ResourceFormController extends BasicFormController {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController urlController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final FocusNode urlFocusNode = FocusNode();
  List<int> selectedCourses = [];
  int selectedStatus = 0;
  int selectedCondition = 0;

  /// Null until the user picks a group; unset when opened from "Show All".
  int? selectedResourceGroupId;
  String initialNotes = '';
  QuillController notesController = heliumQuillController();
  int? linkedNoteId;

  void dispose() {
    titleController.dispose();
    urlController.dispose();
    priceController.dispose();
    urlFocusNode.dispose();
    notesController.dispose();
  }
}
