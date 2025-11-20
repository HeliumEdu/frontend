// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:heliumedu/data/models/planner/external_calendar_model.dart';
import 'package:heliumedu/data/models/planner/external_calendar_request_model.dart';

class OffsetController extends ChangeNotifier {
  int _offsetValue = 0;
  final TextEditingController textController = TextEditingController(text: '0');

  int get offsetValue => _offsetValue;

  OffsetController() {
    textController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final value = int.tryParse(textController.text);
    if (value != null && value != _offsetValue) {
      _offsetValue = value;
      notifyListeners();
    }
  }

  void increment() {
    _offsetValue++;
    textController.text = _offsetValue.toString();
    notifyListeners();
  }

  void decrement() {
    if (_offsetValue > 0) {
      _offsetValue--;
      textController.text = _offsetValue.toString();
      notifyListeners();
    }
  }

  void setValue(int value) {
    if (value >= 0) {
      _offsetValue = value;
      textController.text = _offsetValue.toString();
      notifyListeners();
    }
  }

  void reset() {
    _offsetValue = 0;
    textController.text = '0';
    notifyListeners();
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }
}

class ExternalCalendarFormController extends ChangeNotifier {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController urlController = TextEditingController();
  Color selectedColor = const Color(0xFF16a765);
  bool shownOnCalendar = true;

  void populateFromModel(ExternalCalendarModel model) {
    titleController.text = model.title;
    urlController.text = model.url;
    selectedColor = _hexToColor(model.color);
    shownOnCalendar = model.shownOnCalendar;
    notifyListeners();
  }

  void reset() {
    titleController.clear();
    urlController.clear();
    selectedColor = const Color(0xFF16a765);
    shownOnCalendar = true;
    notifyListeners();
  }

  void setColor(Color color) {
    selectedColor = color;
    notifyListeners();
  }

  void setShownOnCalendar(bool value) {
    shownOnCalendar = value;
    notifyListeners();
  }

  ExternalCalendarRequestModel toRequest() {
    return ExternalCalendarRequestModel(
      title: titleController.text.trim(),
      url: urlController.text.trim(),
      color: _colorToHex(selectedColor),
      shownOnCalendar: shownOnCalendar,
    );
  }

  Color _hexToColor(String hex) {
    try {
      String value = hex.trim().toLowerCase();
      if (!value.startsWith('#')) {
        value = '#$value';
      }
      if (value.length == 4) {
        final r = value[1], g = value[2], b = value[3];
        value = '#$r$r$g$g$b$b';
      } else if (value.length == 9) {
        value = '#${value.substring(3)}';
      }
      return Color(int.parse(value.substring(1), radix: 16) + 0xFF000000);
    } catch (_) {
      return const Color(0xFF16a765);
    }
  }

  String _colorToHex(Color color) {
    final hex = color.value.toRadixString(16).padLeft(8, '0');
    return '#${hex.substring(2)}';
  }

  @override
  void dispose() {
    titleController.dispose();
    urlController.dispose();
    super.dispose();
  }
}
