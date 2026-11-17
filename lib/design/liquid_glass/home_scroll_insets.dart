import 'package:flutter/widgets.dart';

/// Space at the end of a home scroll view for the floating tab bar.
class HomeScrollInsets extends InheritedWidget {
  const HomeScrollInsets({
    super.key,
    required this.bottom,
    required super.child,
  });

  final double bottom;

  static double bottomOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<HomeScrollInsets>()?.bottom ??
      0;

  @override
  bool updateShouldNotify(HomeScrollInsets oldWidget) =>
      bottom != oldWidget.bottom;
}
