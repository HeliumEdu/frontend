import 'package:flutter/material.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';

class ResponsiveCenterCard extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final bool showCard;

  /// Pads the scroll extent by [Responsive.bottomSafeAreaInset] so content can
  /// flow edge-to-edge past a disabled bottom `SafeArea` while its last item
  /// rests above the home indicator. Enable only when the enclosing scaffold
  /// uses `SafeArea(bottom: false)`, else the inset double-counts.
  final bool flowIntoBottomInset;

  final double keyboardInset;

  const ResponsiveCenterCard({
    super.key,
    required this.child,
    this.maxWidth = 450,
    this.showCard = true,
    this.flowIntoBottomInset = false,
    this.keyboardInset = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    final content = isMobile
        ? Padding(padding: const EdgeInsets.all(16), child: child)
        : Container(
            constraints: BoxConstraints(maxWidth: maxWidth),
            margin: const EdgeInsets.symmetric(vertical: 25),
            child: showCard
                ? Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: child,
                    ),
                  )
                : Padding(padding: const EdgeInsets.all(16), child: child),
          );

    final inset = flowIntoBottomInset
        ? Responsive.bottomSafeAreaInset(context)
        : 0.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: EdgeInsets.only(bottom: inset + keyboardInset),
              child: Center(child: content),
            ),
          ),
        );
      },
    );
  }
}
