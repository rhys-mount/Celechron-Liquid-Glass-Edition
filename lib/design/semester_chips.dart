import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

class SemesterChips extends StatelessWidget {
  const SemesterChips({
    super.key,
    required this.names,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> names;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    if (names.isEmpty) return const SizedBox.shrink();

    final accent = CupertinoDynamicColor.resolve(
        CupertinoTheme.of(context).primaryColor, context);
    return SizedBox(
      height: math.max(40, MediaQuery.textScalerOf(context).scale(14) + 24),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: names.length,
        separatorBuilder: (_, index) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final selected = index == selectedIndex;
          final name = names[index];
          final label = name.length >= 11
              ? '${name.substring(2, 5)}${name.substring(7, 11)}'
              : name;
          return Center(
            child: Semantics(
              selected: selected,
              child: CupertinoButton(
                minimumSize: const Size(0, 36),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                borderRadius: BorderRadius.circular(12),
                color: selected
                    ? accent.withValues(alpha: 0.14)
                    : CupertinoColors.tertiarySystemFill.resolveFrom(context),
                onPressed: () => onSelected(index),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected
                        ? accent
                        : CupertinoColors.label.resolveFrom(context),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
