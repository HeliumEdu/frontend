import 'package:flutter/foundation.dart';

class LabelDeleteAction {
  final VoidCallback onPressed;
  final String label;

  const LabelDeleteAction({required this.onPressed, required this.label});
}
