import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'glass_appearance.dart';

const _tabs = [
  (icon: CupertinoIcons.time, label: '接下来'),
  (icon: CupertinoIcons.calendar, label: '日程'),
  (icon: CupertinoIcons.check_mark, label: '任务'),
  (icon: CupertinoIcons.book, label: '学业'),
  (icon: CupertinoIcons.settings, label: '设置'),
];

double? homeNavigationRailWidth(Size window) {
  if (window.width < 840 ||
      window.height < 480 ||
      window.width <= window.height) {
    return null;
  }
  return window.width >= 1200 ? 176 : 72;
}

PreferredSizeWidget buildHomeTabBar(
  BuildContext context, {
  required bool useGlass,
  required int selectedIndex,
  required ValueChanged<int> onSelected,
}) {
  if (useGlass) {
    final accent = CupertinoTheme.of(context).primaryColor;
    return GlassTabBar.bottom(
      tabs: [
        for (final tab in _tabs)
          GlassTab(icon: Icon(tab.icon), label: tab.label),
      ],
      selectedIndex: selectedIndex,
      onTabSelected: onSelected,
      selectedIconColor: accent,
      selectedLabelColor: accent,
      // The full mask keeps the selected icon and label aligned with their tab.
      // Use the lighter indicator on Android while retaining the glass track.
      backgroundQuality: GlassAppearance.quality,
      quality: defaultTargetPlatform == TargetPlatform.android
          ? GlassQuality.minimal
          : GlassAppearance.quality,
    );
  }
  return CupertinoTabBar(
    iconSize: 26,
    height:
        50 + (MediaQuery.textScalerOf(context).scale(12) - 12).clamp(0.0, 46.0),
    backgroundColor:
        CupertinoColors.secondarySystemBackground.resolveFrom(context),
    items: [
      for (final tab in _tabs)
        BottomNavigationBarItem(icon: Icon(tab.icon), label: tab.label),
    ],
    currentIndex: selectedIndex,
    onTap: onSelected,
  );
}

class GlassHomeNavigationRail extends StatelessWidget {
  const GlassHomeNavigationRail({
    super.key,
    required this.width,
    required this.selectedIndex,
    required this.onSelected,
  });

  final double width;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final accent = CupertinoTheme.of(context).primaryColor;
    final showLabels = width >= 120;
    final unselectedColor = CupertinoColors.label.resolveFrom(context);
    return GlassContainer(
      width: width,
      padding: const EdgeInsets.all(8),
      shape: const LiquidRoundedSuperellipse(borderRadius: 26),
      useOwnLayer: true,
      quality: GlassAppearance.quality,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          for (final (index, tab) in _tabs.indexed)
            Semantics(
              excludeSemantics: true,
              label: tab.label,
              selected: index == selectedIndex,
              button: true,
              onTap: () => onSelected(index),
              child: CupertinoButton(
                minimumSize: const Size(0, 48),
                padding: EdgeInsets.zero,
                color: index == selectedIndex
                    ? accent.withValues(alpha: 0.14)
                    : null,
                borderRadius: BorderRadius.circular(18),
                onPressed: () => onSelected(index),
                child: SizedBox(
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisAlignment: showLabels
                          ? MainAxisAlignment.start
                          : MainAxisAlignment.center,
                      spacing: 10,
                      children: [
                        Icon(
                          tab.icon,
                          size: 24,
                          color:
                              index == selectedIndex ? accent : unselectedColor,
                        ),
                        if (showLabels)
                          Flexible(
                            child: Text(
                              tab.label,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: index == selectedIndex
                                    ? accent
                                    : unselectedColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
