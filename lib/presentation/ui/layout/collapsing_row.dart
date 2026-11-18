import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// A single-line row that hides lower-priority items as width runs out.
///
/// It lays out the first of its [steps], from 0 (the widest) to `steps - 1` (the narrowest), whose shown items fit the
/// width, and the last step when none fit. Each [CollapsingRowItem] says which steps it shows at.
class CollapsingRow extends MultiChildRenderObjectWidget {
  final int steps;

  const CollapsingRow({
    super.key,
    required this.steps,
    required List<CollapsingRowItem> super.children,
  });

  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderCollapsingRow(steps: steps);

  @override
  void updateRenderObject(
    BuildContext context,
    RenderCollapsingRow renderObject,
  ) {
    renderObject.steps = steps;
  }
}

/// An item in a [CollapsingRow], shown at steps [from] through [through], or through the last step when [through]
/// is null.
class CollapsingRowItem extends ParentDataWidget<CollapsingRowParentData> {
  final int from;
  final int? through;

  const CollapsingRowItem({
    super.key,
    this.from = 0,
    this.through,
    required super.child,
  });

  @override
  void applyParentData(RenderObject renderObject) {
    final parentData = renderObject.parentData! as CollapsingRowParentData;
    if (parentData.from == from && parentData.through == through) return;
    parentData
      ..from = from
      ..through = through;
    renderObject.parent?.markNeedsLayout();
  }

  @override
  Type get debugTypicalAncestorWidgetClass => CollapsingRow;
}

class CollapsingRowParentData extends ContainerBoxParentData<RenderBox> {
  int from = 0;
  int? through;
  bool shown = true;

  bool shownAt(int step) => step >= from && (through == null || step <= through!);
}

class RenderCollapsingRow extends RenderBox
    with ContainerRenderObjectMixin<RenderBox, CollapsingRowParentData> {
  int _steps;

  RenderCollapsingRow({required int steps}) : _steps = steps;

  set steps(int value) {
    if (value == _steps) return;
    _steps = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! CollapsingRowParentData) {
      child.parentData = CollapsingRowParentData();
    }
  }

  @override
  double computeMinIntrinsicWidth(double height) => _widthAt(_steps - 1);

  @override
  double computeMaxIntrinsicWidth(double height) => _widthAt(0);

  @override
  double computeMinIntrinsicHeight(double width) => _children.fold(
    0,
    (tallest, child) => math.max(tallest, child.getMinIntrinsicHeight(width)),
  );

  @override
  double computeMaxIntrinsicHeight(double width) => _children.fold(
    0,
    (tallest, child) => math.max(tallest, child.getMaxIntrinsicHeight(width)),
  );

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final step = _stepFor(constraints.maxWidth);
    var width = 0.0;
    var height = 0.0;
    for (final child in _children.where((child) => _dataOf(child).shownAt(step))) {
      final childSize = child.getDryLayout(
        BoxConstraints(maxHeight: constraints.maxHeight),
      );
      width += childSize.width;
      height = math.max(height, childSize.height);
    }
    return constraints.constrain(Size(width, height));
  }

  @override
  void performLayout() {
    final step = _stepFor(constraints.maxWidth);
    var width = 0.0;
    var height = 0.0;
    for (final child in _children) {
      final parentData = _dataOf(child);
      parentData.shown = parentData.shownAt(step);
      if (!parentData.shown) {
        child.layout(const BoxConstraints());
        continue;
      }
      child.layout(
        BoxConstraints(maxHeight: constraints.maxHeight),
        parentUsesSize: true,
      );
      width += child.size.width;
      height = math.max(height, child.size.height);
    }
    size = constraints.constrain(Size(width, height));

    var x = 0.0;
    for (final child in _children.where((child) => _dataOf(child).shown)) {
      _dataOf(child).offset = Offset(x, (size.height - child.size.height) / 2);
      x += child.size.width;
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    for (final child in _children.where((child) => _dataOf(child).shown)) {
      context.paintChild(child, _dataOf(child).offset + offset);
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    var child = lastChild;
    while (child != null) {
      final parentData = _dataOf(child);
      if (parentData.shown) {
        final current = child;
        final isHit = result.addWithPaintOffset(
          offset: parentData.offset,
          position: position,
          hitTest: (result, transformed) =>
              current.hitTest(result, position: transformed),
        );
        if (isHit) return true;
      }
      child = childBefore(child);
    }
    return false;
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    for (final child in _children.where((child) => _dataOf(child).shown)) {
      visitor(child);
    }
  }

  Iterable<RenderBox> get _children sync* {
    var child = firstChild;
    while (child != null) {
      yield child;
      child = childAfter(child);
    }
  }

  CollapsingRowParentData _dataOf(RenderBox child) =>
      child.parentData! as CollapsingRowParentData;

  double _widthAt(int step) => _children
      .where((child) => _dataOf(child).shownAt(step))
      .fold(0, (sum, child) => sum + child.getMaxIntrinsicWidth(double.infinity));

  int _stepFor(double maxWidth) {
    for (var step = 0; step < _steps - 1; step++) {
      if (_widthAt(step) <= maxWidth) return step;
    }
    return _steps - 1;
  }
}
