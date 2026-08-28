import 'package:flutter/widgets.dart';

/// Rebuilds its subtree from scratch on demand.
///
/// Discarding the subtree re-runs the screen's own [State.initState], which
/// refetches and clears local state without re-listing that work per screen.
class ReloadScope extends StatefulWidget {
  final Widget child;

  const ReloadScope({super.key, required this.child});

  static ReloadScopeState? maybeOf(BuildContext context) =>
      context.findAncestorStateOfType<ReloadScopeState>();

  @override
  State<ReloadScope> createState() => ReloadScopeState();
}

class ReloadScopeState extends State<ReloadScope> {
  int _generation = 0;

  void reload() => setState(() => _generation++);

  @override
  Widget build(BuildContext context) =>
      KeyedSubtree(key: ValueKey(_generation), child: widget.child);
}
