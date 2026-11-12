import 'package:flutter/material.dart';
import 'package:heliumapp/data/models/planner/grade_scale_band_model.dart';
import 'package:heliumapp/presentation/features/shared/controllers/basic_form_controller.dart';
import 'package:heliumapp/utils/grade_scale_constants.dart';

class CourseGroupFormController extends BasicFormController {
  final TextEditingController titleController = TextEditingController();
  bool shownOnCalendar = true;
  DateTime? startDate;
  DateTime? endDate;

  int gradeScaleTemplate = GradeScaleTemplate.none;
  List<GradeScaleBandModel> customGradeScale = const [];

  void dispose() {
    titleController.dispose();
  }
}
