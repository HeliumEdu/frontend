import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/config/pref_service.dart';
import 'package:heliumapp/presentation/ui/dialogs/color_picker_dialog.dart';

enum HeliumToolbarDensity {
  /// One fixed row.
  minimal,

  /// The buttons that fit in one row, then a more/less toggle for the rest;
  /// starts folded.
  compact,

  /// Every button, with dividers between groups; folds like [compact] once it
  /// wraps, but starts open.
  full,
}

enum HeliumToolbarButton {
  undo,
  redo,
  fontFamily,
  fontSize,
  bold,
  italic,
  underline,
  strikeThrough,
  inlineCode,
  subscript,
  superscript,
  color,
  backgroundColor,
  clearFormat,
  alignment,
  headerStyle,
  numberedList,
  bulletedList,
  checklist,
  codeBlock,
  quote,
  indentIncrease,
  indentDecrease,
  link,
  search,
  print,
}

/// [groups] lists the buttons in priority order; [HeliumToolbarDensity.full]
/// divides the groups.
class HeliumQuillToolbar extends StatefulWidget {
  static const _buttonSpacing = 8.0;

  static const _expandedKey = 'saved_notebook_toolbar_state';

  final QuillController controller;
  final HeliumToolbarDensity density;
  final List<List<HeliumToolbarButton>> groups;
  final VoidCallback? onSearch;
  final VoidCallback? onPrint;

  const HeliumQuillToolbar({
    super.key,
    required this.controller,
    required this.density,
    required this.groups,
    this.onSearch,
    this.onPrint,
  });

  static QuillSimpleToolbarButtonOptions _defaultButtonOptions(
    BuildContext context,
  ) {
    return QuillSimpleToolbarButtonOptions(
      base: QuillToolbarBaseButtonOptions(
        iconTheme: QuillIconTheme(
          iconButtonSelectedData: IconButtonData(
            style: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(
                context.colorScheme.primary,
              ),
              foregroundColor: WidgetStatePropertyAll(
                context.colorScheme.onPrimary,
              ),
              overlayColor: WidgetStatePropertyAll(
                context.colorScheme.onPrimary.withValues(alpha: 0.1),
              ),
              minimumSize: const WidgetStatePropertyAll(Size.zero),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          iconButtonUnselectedData: IconButtonData(
            style: ButtonStyle(
              backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
              foregroundColor: WidgetStatePropertyAll(
                context.colorScheme.onSurface,
              ),
              minimumSize: const WidgetStatePropertyAll(Size.zero),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
      ),
      color: QuillToolbarColorButtonOptions(
        customOnPressedCallback: (ctrl, isBackground) =>
            _showColorPicker(context, ctrl, isBackground),
      ),
      backgroundColor: QuillToolbarColorButtonOptions(
        customOnPressedCallback: (ctrl, isBackground) =>
            _showColorPicker(context, ctrl, isBackground),
      ),
    );
  }

  /// Applies the picked color to the selection's text or background.
  static Future<void> _showColorPicker(
    BuildContext context,
    QuillController controller,
    bool isBackground,
  ) async {
    final key = isBackground ? 'background' : 'color';
    final stored =
        controller.getSelectionStyle().attributes[key]?.value as String?;

    Color initial = Colors.black;
    if (stored != null) {
      // Quill stores colors as #AARRGGBB; strip # and parse
      final hex = stored.startsWith('#') ? stored.substring(1) : stored;
      final padded = hex.length == 6 ? 'ff$hex' : hex;
      initial = Color(int.tryParse(padded, radix: 16) ?? 0xFF000000);
    }

    await showColorPickerDialog(
      parentContext: context,
      initialColor: initial,
      onSelected: (color) {
        final a = (color.a * 255).round().toRadixString(16).padLeft(2, '0');
        final r = (color.r * 255).round().toRadixString(16).padLeft(2, '0');
        final g = (color.g * 255).round().toRadixString(16).padLeft(2, '0');
        final b = (color.b * 255).round().toRadixString(16).padLeft(2, '0');
        final hex = '#$a$r$g$b'.toUpperCase();
        controller.formatSelection(
          isBackground ? BackgroundAttribute(hex) : ColorAttribute(hex),
        );
      },
    );
  }

  @override
  State<HeliumQuillToolbar> createState() => _HeliumQuillToolbarState();
}

class _HeliumQuillToolbarState extends State<HeliumQuillToolbar> {
  late bool _expanded = _savedExpanded();

  /// Items in the first row before the toggle; null while everything fits.
  int? _fold;

  bool _savedExpanded() =>
      PrefService().getBool(HeliumQuillToolbar._expandedKey) ??
      widget.density == HeliumToolbarDensity.full;

  @override
  void didUpdateWidget(covariant HeliumQuillToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.density != widget.density) _expanded = _savedExpanded();
  }

  void _toggleExpanded() {
    setState(() => _expanded = !_expanded);
    PrefService().setBool(HeliumQuillToolbar._expandedKey, _expanded);
  }

  void _onFold(int? fold) {
    if (fold == _fold) return;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _fold = fold);
    });
  }

  QuillSimpleToolbarButtonOptions _options(BuildContext context) {
    final defaults = HeliumQuillToolbar._defaultButtonOptions(context);
    final onSearch = widget.onSearch;
    return QuillSimpleToolbarButtonOptions(
      base: defaults.base,
      color: defaults.color,
      backgroundColor: defaults.backgroundColor,
      search: onSearch == null
          ? const QuillToolbarSearchButtonOptions()
          : QuillToolbarSearchButtonOptions(
              customOnPressedCallback: (_) async => onSearch(),
            ),
    );
  }

  Widget _buildButton(
    HeliumToolbarButton button,
    QuillSimpleToolbarButtonOptions options,
  ) {
    final controller = widget.controller;
    final base = options.base;
    return switch (button) {
      HeliumToolbarButton.undo => QuillToolbarHistoryButton(
        isUndo: true,
        options: options.undoHistory,
        controller: controller,
        baseOptions: base,
      ),
      HeliumToolbarButton.redo => QuillToolbarHistoryButton(
        isUndo: false,
        options: options.redoHistory,
        controller: controller,
        baseOptions: base,
      ),
      HeliumToolbarButton.fontFamily => QuillToolbarFontFamilyButton(
        options: options.fontFamily,
        controller: controller,
        baseOptions: base,
      ),
      HeliumToolbarButton.fontSize => QuillToolbarFontSizeButton(
        options: options.fontSize,
        controller: controller,
        baseOptions: base,
      ),
      HeliumToolbarButton.bold => _buildStyleToggle(
        Attribute.bold,
        options.bold,
        options,
      ),
      HeliumToolbarButton.italic => _buildStyleToggle(
        Attribute.italic,
        options.italic,
        options,
      ),
      HeliumToolbarButton.underline => _buildStyleToggle(
        Attribute.underline,
        options.underLine,
        options,
      ),
      HeliumToolbarButton.strikeThrough => _buildStyleToggle(
        Attribute.strikeThrough,
        options.strikeThrough,
        options,
      ),
      HeliumToolbarButton.inlineCode => _buildStyleToggle(
        Attribute.inlineCode,
        options.inlineCode,
        options,
      ),
      HeliumToolbarButton.subscript => _buildStyleToggle(
        Attribute.subscript,
        options.subscript,
        options,
      ),
      HeliumToolbarButton.superscript => _buildStyleToggle(
        Attribute.superscript,
        options.superscript,
        options,
      ),
      HeliumToolbarButton.color => QuillToolbarColorButton(
        isBackground: false,
        options: options.color,
        controller: controller,
        baseOptions: base,
      ),
      HeliumToolbarButton.backgroundColor => QuillToolbarColorButton(
        isBackground: true,
        options: options.backgroundColor,
        controller: controller,
        baseOptions: base,
      ),
      HeliumToolbarButton.clearFormat => QuillToolbarClearFormatButton(
        options: options.clearFormat,
        controller: controller,
        baseOptions: base,
      ),
      // Quill doesn't export its alignment group, which is these four toggles
      HeliumToolbarButton.alignment => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final attribute in [
            Attribute.leftAlignment,
            Attribute.centerAlignment,
            Attribute.rightAlignment,
            Attribute.justifyAlignment,
          ])
            _buildStyleToggle(
              attribute,
              const QuillToolbarToggleStyleButtonOptions(),
              options,
            ),
        ],
      ),
      HeliumToolbarButton.headerStyle =>
        QuillToolbarSelectHeaderStyleDropdownButton(
          options: options.selectHeaderStyleDropdownButton,
          controller: controller,
          baseOptions: base,
        ),
      HeliumToolbarButton.numberedList => _buildStyleToggle(
        Attribute.ol,
        options.listNumbers,
        options,
      ),
      HeliumToolbarButton.bulletedList => _buildStyleToggle(
        Attribute.ul,
        options.listBullets,
        options,
      ),
      HeliumToolbarButton.checklist => QuillToolbarToggleCheckListButton(
        options: options.toggleCheckList,
        controller: controller,
        baseOptions: base,
      ),
      HeliumToolbarButton.codeBlock => _buildStyleToggle(
        Attribute.codeBlock,
        options.codeBlock,
        options,
      ),
      HeliumToolbarButton.quote => _buildStyleToggle(
        Attribute.blockQuote,
        options.quote,
        options,
      ),
      HeliumToolbarButton.indentIncrease => QuillToolbarIndentButton(
        isIncrease: true,
        options: options.indentIncrease,
        controller: controller,
        baseOptions: base,
      ),
      HeliumToolbarButton.indentDecrease => QuillToolbarIndentButton(
        isIncrease: false,
        options: options.indentDecrease,
        controller: controller,
        baseOptions: base,
      ),
      HeliumToolbarButton.link => QuillToolbarLinkStyleButton(
        options: options.linkStyle,
        controller: controller,
        baseOptions: base,
      ),
      HeliumToolbarButton.search => QuillToolbarSearchButton(
        options: options.search,
        controller: controller,
        baseOptions: base,
      ),
      HeliumToolbarButton.print => QuillToolbarCustomButton(
        options: QuillToolbarCustomButtonOptions(
          icon: const Icon(Icons.print_outlined),
          tooltip: 'Print',
          onPressed: widget.onPrint,
        ),
        controller: controller,
        baseOptions: base,
      ),
    };
  }

  Widget _buildStyleToggle(
    Attribute<dynamic> attribute,
    QuillToolbarToggleStyleButtonOptions styleOptions,
    QuillSimpleToolbarButtonOptions options,
  ) {
    return QuillToolbarToggleStyleButton(
      attribute: attribute,
      options: styleOptions,
      controller: widget.controller,
      baseOptions: options.base,
    );
  }

  Widget _buildToggle(QuillSimpleToolbarButtonOptions options) {
    return QuillToolbarCustomButton(
      options: QuillToolbarCustomButtonOptions(
        icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
        tooltip: _expanded ? 'Less' : 'More',
        onPressed: _toggleExpanded,
      ),
      controller: widget.controller,
      baseOptions: options.base,
    );
  }

  List<({Widget child, bool isDivider})> _withDividers(
    List<List<Widget>> groups,
  ) {
    // Quill's own divider height
    const divider = SizedBox(
      height: kDefaultToolbarSize * 1.4,
      child: QuillToolbarDivider(Axis.horizontal),
    );
    return [
      for (final (index, group)
          in groups.where((group) => group.isNotEmpty).indexed) ...[
        if (index > 0) (child: divider, isDivider: true),
        for (final button in group) (child: button, isDivider: false),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final options = _options(context);
    final groups = [
      for (final group in widget.groups)
        [for (final button in group) _buildButton(button, options)],
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: switch (widget.density) {
        HeliumToolbarDensity.minimal => _wrap(
          groups.expand((group) => group).toList(),
        ),
        HeliumToolbarDensity.compact => _buildCollapsible([
          for (final button in groups.expand((group) => group))
            (child: button, isDivider: false),
        ], options),
        HeliumToolbarDensity.full => _buildCollapsible(
          _withDividers(groups),
          options,
        ),
      },
    );
  }

  Widget _wrap(List<Widget> children) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: HeliumQuillToolbar._buttonSpacing,
      children: children,
    );
  }

  /// Folded items stay built, so the layout can measure them, but can't take
  /// focus.
  Widget _buildCollapsible(
    List<({Widget child, bool isDivider})> items,
    QuillSimpleToolbarButtonOptions options,
  ) {
    final fold = _fold;
    final shown = fold == null
        ? items.length
        : (_expanded ? items.length : fold);
    return _ToolbarRows(
      expanded: _expanded,
      onFold: _onFold,
      children: [
        for (final (index, item) in items.indexed)
          _ToolbarItem(
            isDivider: item.isDivider,
            child: ExcludeFocus(excluding: index >= shown, child: item.child),
          ),
        ExcludeFocus(excluding: fold == null, child: _buildToggle(options)),
      ],
    );
  }
}

/// Centered rows of toolbar items, placed by [toolbarRows]; the last child is
/// the more/less toggle.
class _ToolbarRows extends MultiChildRenderObjectWidget {
  final bool expanded;
  final ValueChanged<int?> onFold;

  const _ToolbarRows({
    required this.expanded,
    required this.onFold,
    required super.children,
  });

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderToolbarRows(expanded: expanded, onFold: onFold);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderToolbarRows renderObject,
  ) {
    renderObject
      ..expanded = expanded
      ..onFold = onFold;
  }
}

class _ToolbarRowsParentData extends ContainerBoxParentData<RenderBox> {
  bool shown = false;
  bool isDivider = false;
}

class _ToolbarItem extends ParentDataWidget<_ToolbarRowsParentData> {
  final bool isDivider;

  const _ToolbarItem({required this.isDivider, required super.child});

  @override
  void applyParentData(RenderObject renderObject) {
    final parentData = renderObject.parentData! as _ToolbarRowsParentData;
    if (parentData.isDivider == isDivider) return;
    parentData.isDivider = isDivider;
    renderObject.parent?.markNeedsLayout();
  }

  @override
  Type get debugTypicalAncestorWidgetClass => _ToolbarRows;
}

class _RenderToolbarRows extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _ToolbarRowsParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _ToolbarRowsParentData> {
  _RenderToolbarRows({required bool expanded, required this.onFold})
    : _expanded = expanded;

  ValueChanged<int?> onFold;

  bool _expanded;

  set expanded(bool value) {
    if (value == _expanded) return;
    _expanded = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _ToolbarRowsParentData) {
      child.parentData = _ToolbarRowsParentData();
    }
  }

  @override
  void performLayout() {
    const spacing = HeliumQuillToolbar._buttonSpacing;
    final maxWidth = constraints.maxWidth;
    final children = getChildrenAsList();
    for (final child in children) {
      child.layout(BoxConstraints(maxWidth: maxWidth), parentUsesSize: true);
      (child.parentData! as _ToolbarRowsParentData).shown = false;
    }
    final toggle = children.last;
    final items = children.sublist(0, children.length - 1);
    final layout = toolbarRows(
      widths: [for (final item in items) item.size.width],
      dividers: [
        for (final item in items)
          (item.parentData! as _ToolbarRowsParentData).isDivider,
      ],
      toggleWidth: toggle.size.width,
      maxWidth: maxWidth,
      expanded: _expanded,
    );
    final rows = [
      for (final row in layout.rows)
        [for (final index in row) index < 0 ? toggle : items[index]],
    ];

    var y = 0.0;
    for (final row in rows) {
      final height = row.fold(
        0.0,
        (tallest, child) =>
            child.size.height > tallest ? child.size.height : tallest,
      );
      var x = (maxWidth - _widthOf(row)) / 2;
      for (final child in row) {
        (child.parentData! as _ToolbarRowsParentData)
          ..offset = Offset(x, y + (height - child.size.height) / 2)
          ..shown = true;
        x += child.size.width + spacing;
      }
      y += height;
    }
    size = constraints.constrain(Size(maxWidth, y));
    onFold(layout.fold);
  }

  double _widthOf(List<RenderBox> row) =>
      row.fold(0.0, (total, child) => total + child.size.width) +
      HeliumQuillToolbar._buttonSpacing * (row.length - 1);

  bool _isShown(RenderBox child) =>
      (child.parentData! as _ToolbarRowsParentData).shown;

  @override
  void paint(PaintingContext context, Offset offset) {
    for (final child in getChildrenAsList().where(_isShown)) {
      context.paintChild(
        child,
        (child.parentData! as _ToolbarRowsParentData).offset + offset,
      );
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    for (final child in getChildrenAsList().reversed.where(_isShown)) {
      final offset = (child.parentData! as _ToolbarRowsParentData).offset;
      final hit = result.addWithPaintOffset(
        offset: offset,
        position: position,
        hitTest: (result, transformed) =>
            child.hitTest(result, position: transformed),
      );
      if (hit) return true;
    }
    return false;
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    getChildrenAsList().where(_isShown).forEach(visitor);
  }
}

/// The toolbar's rows, as indexes into [widths] (-1 for the toggle), and the
/// fold: how many items the first row holds before the toggle, or null when
/// everything fits in one row. A divider never starts or ends a row.
@visibleForTesting
({List<List<int>> rows, int? fold}) toolbarRows({
  required List<double> widths,
  required List<bool> dividers,
  required double toggleWidth,
  required double maxWidth,
  required bool expanded,
}) {
  const spacing = HeliumQuillToolbar._buttonSpacing;
  final all = [for (var index = 0; index < widths.length; index++) index];
  if (_rowWidth(all, widths) <= maxWidth) return (rows: [all], fold: null);

  var width = toggleWidth;
  var fold = 0;
  while (fold < widths.length && width + spacing + widths[fold] <= maxWidth) {
    width += spacing + widths[fold];
    fold++;
  }
  final rows = [
    [..._withoutEdgeDividers(all.take(fold).toList(), dividers), -1],
  ];
  if (expanded) {
    var row = <int>[];
    for (final index in all.skip(fold)) {
      if (row.isEmpty && dividers[index]) continue;
      if (row.isNotEmpty && _rowWidth([...row, index], widths) > maxWidth) {
        rows.add(_withoutEdgeDividers(row, dividers));
        row = [];
        if (dividers[index]) continue;
      }
      row.add(index);
    }
    final last = _withoutEdgeDividers(row, dividers);
    if (last.isNotEmpty) rows.add(last);
  }
  return (rows: rows, fold: fold);
}

double _rowWidth(Iterable<int> row, List<double> widths) =>
    row.fold(0.0, (total, index) => total + widths[index]) +
    HeliumQuillToolbar._buttonSpacing * (row.length - 1);

List<int> _withoutEdgeDividers(List<int> row, List<bool> dividers) {
  final start = row.indexWhere((index) => !dividers[index]);
  if (start < 0) return [];
  final end = row.lastIndexWhere((index) => !dividers[index]);
  return row.sublist(start, end + 1);
}
