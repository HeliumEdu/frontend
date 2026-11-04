import 'package:flutter/widgets.dart';

/// Rebuilds its subtree from scratch on demand, remounting the screen so it
/// refetches and clears its local state.
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
