import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:heliumapp/core/motion_service.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/presentation/ui/components/helium_quill_editor.dart';
import 'package:heliumapp/presentation/ui/components/helium_quill_toolbar.dart';
import 'package:heliumapp/presentation/ui/components/quill_search_bar.dart';
import 'package:heliumapp/presentation/ui/layout/helium_full_screen_scroll_view.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';

enum NotesEditorLayout {
  /// In a form, under a "Notes" label, with a bounded height.
  embedded,

  /// Fills its page, with find and print.
  page,
}

class NotesEditor extends StatefulWidget {
  /// Toolbar buttons in priority order; each set keeps [_pageFullButtons]'s.
  static const _embeddedMinimalButtons = [
    [
      HeliumToolbarButton.undo,
      HeliumToolbarButton.bold,
      HeliumToolbarButton.italic,
      HeliumToolbarButton.bulletedList,
      HeliumToolbarButton.numberedList,
      HeliumToolbarButton.checklist,
      HeliumToolbarButton.link,
    ],
  ];
  static const _embeddedFullButtons = [
    [
      HeliumToolbarButton.undo,
      HeliumToolbarButton.redo,
      HeliumToolbarButton.bold,
      HeliumToolbarButton.italic,
      HeliumToolbarButton.underline,
      HeliumToolbarButton.strikeThrough,
      HeliumToolbarButton.color,
      HeliumToolbarButton.clearFormat,
    ],
    [
      HeliumToolbarButton.bulletedList,
      HeliumToolbarButton.numberedList,
      HeliumToolbarButton.checklist,
      HeliumToolbarButton.indentIncrease,
      HeliumToolbarButton.indentDecrease,
    ],
    [HeliumToolbarButton.fontFamily],
    [HeliumToolbarButton.quote, HeliumToolbarButton.link],
  ];
  static const _pageCompactButtons = [
    [
      HeliumToolbarButton.undo,
      HeliumToolbarButton.bold,
      HeliumToolbarButton.italic,
      HeliumToolbarButton.backgroundColor,
      HeliumToolbarButton.bulletedList,
      HeliumToolbarButton.numberedList,
      HeliumToolbarButton.checklist,
      HeliumToolbarButton.headerStyle,
      HeliumToolbarButton.quote,
      HeliumToolbarButton.link,
      HeliumToolbarButton.print,
      HeliumToolbarButton.search,
    ],
  ];
  static const _pageFullButtons = [
    [
      HeliumToolbarButton.undo,
      HeliumToolbarButton.redo,
      HeliumToolbarButton.bold,
      HeliumToolbarButton.italic,
      HeliumToolbarButton.underline,
      HeliumToolbarButton.strikeThrough,
      HeliumToolbarButton.inlineCode,
      HeliumToolbarButton.subscript,
      HeliumToolbarButton.superscript,
      HeliumToolbarButton.color,
      HeliumToolbarButton.backgroundColor,
      HeliumToolbarButton.clearFormat,
    ],
    [
      HeliumToolbarButton.bulletedList,
      HeliumToolbarButton.numberedList,
      HeliumToolbarButton.checklist,
      HeliumToolbarButton.indentIncrease,
      HeliumToolbarButton.indentDecrease,
    ],
    [
      HeliumToolbarButton.headerStyle,
      HeliumToolbarButton.fontFamily,
      HeliumToolbarButton.fontSize,
    ],
    [
      HeliumToolbarButton.quote,
      HeliumToolbarButton.codeBlock,
      HeliumToolbarButton.link,
    ],
    [HeliumToolbarButton.alignment],
    [HeliumToolbarButton.print, HeliumToolbarButton.search],
  ];

  final QuillController controller;
  final FocusNode? focusNode;
  final NotesEditorLayout layout;

  /// Embedded: opens the note in the Notebook.
  final VoidCallback? onOpenInNotebook;

  /// Page: prints the note.
  final VoidCallback? onPrint;

  const NotesEditor({
    super.key,
    required this.controller,
    this.focusNode,
    this.layout = NotesEditorLayout.embedded,
    this.onOpenInNotebook,
    this.onPrint,
  });

  /// Builds theme-aware default styles for Quill editors.
  ///
  /// Flutter Quill's default strikethrough/underline styles don't set
  /// decorationColor, causing black decorations in dark mode.
  static DefaultStyles buildDefaultStyles(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return DefaultStyles(
      strikeThrough: TextStyle(
        decoration: TextDecoration.lineThrough,
        decorationColor: onSurface,
      ),
      underline: TextStyle(
        decoration: TextDecoration.underline,
        decorationColor: onSurface,
      ),
    );
  }

  @override
  State<NotesEditor> createState() => _NotesEditorState();
}

class _NotesEditorState extends State<NotesEditor> with WidgetsBindingObserver {
  final _editorKey = GlobalKey();
  bool _pendingScrollOnKeyboard = false;
  bool _showSearch = false;

  bool get _isEmbedded => widget.layout == NotesEditorLayout.embedded;

  void _toggleSearch() {
    setState(() => _showSearch = !_showSearch);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.focusNode?.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant NotesEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode?.removeListener(_onFocusChange);
      widget.focusNode?.addListener(_onFocusChange);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.focusNode?.removeListener(_onFocusChange);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    if (!_pendingScrollOnKeyboard || !mounted) return;

    final viewInsets = WidgetsBinding
        .instance.platformDispatcher.views.first.viewInsets.bottom;

    // Keyboard starting to appear - wait for animation to complete
    if (viewInsets > 0) {
      _pendingScrollOnKeyboard = false;
      // Keyboard animation is ~250-300ms; wait for it to finish
      Future.delayed(const Duration(milliseconds: 150), _scrollToEditor);
    }
  }

  void _scrollToEditor() {
    if (!mounted) return;
    // Defer scroll until after the keyboard-triggered layout pass so the
    // editor's final position is known before calling ensureVisible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctx = _editorKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: MotionService().effectiveDuration(const Duration(milliseconds: 200)),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onFocusChange() {
    if (_isEmbedded && (widget.focusNode?.hasFocus ?? false)) {
      final viewInsets = WidgetsBinding
          .instance.platformDispatcher.views.first.viewInsets.bottom;

      // If keyboard is already visible, scroll immediately
      if (viewInsets > 0) {
        _scrollToEditor();
      } else {
        // Wait for keyboard to appear via didChangeMetrics
        _pendingScrollOnKeyboard = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = Responsive.useCompactLayout(context);
    return _isEmbedded
        ? _buildEmbedded(context, isCompact)
        : _buildPage(context, isCompact);
  }

  Widget _buildEmbedded(BuildContext context, bool isCompact) {
    return Column(
      key: _editorKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ExcludeSemantics(
              child: Text('Notes', style: AppStyles.formLabel(context)),
            ),
            const Spacer(),
            if (widget.onOpenInNotebook != null)
              TextButton.icon(
                onPressed: widget.onOpenInNotebook,
                icon: Icon(
                  Icons.library_books,
                  size: 16.0,
                  color: context.colorScheme.primary,
                ),
                label: Text(
                  'Open in Notebook',
                  style: AppStyles.smallSecondaryText(context).copyWith(color: context.colorScheme.primary),
                ),
              ),
          ],
        ),
        const SizedBox(height: 9),
        Container(
          decoration: BoxDecoration(
            color: context.colorScheme.surface,
            border: Border.all(
              color: context.colorScheme.outline.withValues(alpha: 0.2),
            ),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                HeliumQuillToolbar(
                  controller: widget.controller,
                  density: isCompact
                      ? HeliumToolbarDensity.minimal
                      : HeliumToolbarDensity.full,
                  groups: isCompact
                      ? NotesEditor._embeddedMinimalButtons
                      : NotesEditor._embeddedFullButtons,
                ),
                const Divider(height: 1),
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: 125.0,
                    maxHeight: 300.0,
                  ),
                  child: HeliumQuillEditor(
                    controller: widget.controller,
                    semanticsLabel: 'Notes',
                    focusNode: widget.focusNode,
                    config: QuillEditorConfig(
                      padding: const EdgeInsets.all(12.0),
                      autoFocus: false,
                      customStyles: NotesEditor.buildDefaultStyles(context),
                      customShortcuts: const <ShortcutActivator, Intent>{
                        SingleActivator(LogicalKeyboardKey.keyF, control: true):
                            DoNothingIntent(),
                        SingleActivator(LogicalKeyboardKey.keyF, meta: true):
                            DoNothingIntent(),
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Edge to edge on phones, with the safe-area inset as end padding so text
  /// scrolls under the home indicator; elsewhere a box that runs to the bottom
  /// of the window.
  Widget _buildPage(BuildContext context, bool isCompact) {
    final outline = context.colorScheme.outline.withValues(alpha: 0.2);
    final radius = isCompact
        ? BorderRadius.zero
        : const BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8),
          );
    final bottomInset = isCompact
        ? HeliumFullScreenScrollView.insetOf(context)
        : 0.0;
    final canSearch = !Responsive.isPhoneLandscape(context);
    final buttons = isCompact
        ? NotesEditor._pageCompactButtons
        : NotesEditor._pageFullButtons;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Container(
        decoration: BoxDecoration(
          color: context.colorScheme.surface,
          border: isCompact
              ? Border(top: BorderSide(color: outline))
              : Border.all(color: outline),
          borderRadius: isCompact ? null : radius,
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? AppConstants.pageEdgeInset : 0,
                ),
                child: HeliumQuillToolbar(
                  controller: widget.controller,
                  density: isCompact
                      ? HeliumToolbarDensity.compact
                      : HeliumToolbarDensity.full,
                  groups: [
                    for (final group in buttons)
                      [
                        for (final button in group)
                          if (canSearch || button != HeliumToolbarButton.search)
                            button,
                      ],
                  ],
                  onSearch: _toggleSearch,
                  onPrint: widget.onPrint,
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: HeliumQuillEditor(
                  controller: widget.controller,
                  semanticsLabel: 'Note',
                  focusNode: widget.focusNode,
                  config: QuillEditorConfig(
                    padding: isCompact
                        ? EdgeInsets.fromLTRB(
                            AppConstants.unboxedContentInset,
                            12,
                            AppConstants.unboxedContentInset,
                            12 + bottomInset,
                          )
                        : const EdgeInsets.all(
                            AppConstants.containerContentInset,
                          ),
                    autoFocus: false,
                    expands: true,
                    customStyles: NotesEditor.buildDefaultStyles(context),
                    scrollBottomInset: MediaQuery.of(context).viewInsets.bottom,
                    // ignore: experimental_member_use
                    onKeyPressed: (event, node) {
                      final isFindShortcut =
                          event.logicalKey == LogicalKeyboardKey.keyF &&
                          (HardwareKeyboard.instance.isMetaPressed ||
                              HardwareKeyboard.instance.isControlPressed);
                      if (!isFindShortcut) return null;
                      _toggleSearch();
                      return KeyEventResult.handled;
                    },
                  ),
                ),
              ),
              if (_showSearch)
                Padding(
                  padding: EdgeInsets.only(bottom: bottomInset),
                  child: QuillSearchBar(
                    controller: widget.controller,
                    onClose: () => setState(() => _showSearch = false),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
