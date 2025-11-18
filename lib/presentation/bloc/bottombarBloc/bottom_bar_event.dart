abstract class BottomNavigationEvent {}

class NavigationTabChanged extends BottomNavigationEvent {
  final int tabIndex;
  NavigationTabChanged(this.tabIndex);
}
