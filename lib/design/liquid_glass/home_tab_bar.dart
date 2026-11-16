import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart' show Icons;
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'glass_appearance.dart';

const _tabs = [
  (icon: CupertinoIcons.time, label: '接下来'),
  (icon: CupertinoIcons.calendar, label: '日程'),
  (icon: CupertinoIcons.check_mark, label: '任务'),
  (icon: Icons.school_rounded, label: '学业'),
  (icon: CupertinoIcons.settings, label: '设置'),
];

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
      maskingQuality: defaultTargetPlatform == TargetPlatform.android
          ? MaskingQuality.off
          : MaskingQuality.high,
      quality: GlassAppearance.quality,
    );
  }
  return CupertinoTabBar(
    iconSize: 26,
    backgroundColor: CupertinoDynamicColor.resolve(
            CupertinoColors.secondarySystemBackground, context)
        .withValues(alpha: 0.5),
    items: [
      for (final tab in _tabs)
        BottomNavigationBarItem(icon: Icon(tab.icon), label: tab.label),
    ],
    currentIndex: selectedIndex,
    onTap: onSelected,
  );
}
