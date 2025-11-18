class BottomNavigationState {
  final int selectedIndex;

  const BottomNavigationState({this.selectedIndex = 0});

  BottomNavigationState copyWith({int? selectedIndex}) {
    return BottomNavigationState(
      selectedIndex: selectedIndex ?? this.selectedIndex,
    );
  }
}
