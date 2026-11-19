import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

final _standardSemesterName = RegExp(r'^\d{2}(\d{2})-\d{2}(\d{2})(春夏|秋冬)$');

String shortSemesterLabel(String name) {
  final match = _standardSemesterName.firstMatch(name);
  return match == null ? name : '${match[1]}-${match[2]}${match[3]}';
}

class SemesterChips extends StatelessWidget {
  const SemesterChips({
    super.key,
    required this.names,
    required this.selectedIndex,
    required this.onSelected,
    this.summaries,
    this.onLongPress,
  });

  final List<String> names;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final List<String>? summaries;
  final ValueChanged<int>? onLongPress;

  @override
  Widget build(BuildContext context) {
    if (names.isEmpty) return const SizedBox.shrink();

    final accent = CupertinoDynamicColor.resolve(
        CupertinoTheme.of(context).primaryColor, context);
    final scaler = MediaQuery.textScalerOf(context);
    final height =
        scaler.scale(14) + (summaries == null ? 0 : scaler.scale(12) + 3) + 24;
    return SizedBox(
      height: math.max(44, height),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: names.length,
        separatorBuilder: (_, index) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final selected = index == selectedIndex;
          final name = names[index];
          final label = shortSemesterLabel(name);
          final summary = summaries?[index];
          return Center(
            child: Semantics(
              selected: selected,
              label: summary == null ? name : '$name，$summary',
              child: CupertinoButton(
                minimumSize: const Size(0, 44),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                borderRadius: BorderRadius.circular(12),
                color: selected
                    ? accent.withValues(alpha: 0.14)
                    : CupertinoColors.tertiarySystemFill.resolveFrom(context),
                onPressed: () => onSelected(index),
                onLongPress:
                    onLongPress == null ? null : () => onLongPress!(index),
                child: ExcludeSemantics(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.w500,
                            color: selected
                                ? accent
                                : CupertinoColors.label.resolveFrom(context),
                          )),
                      if (summary != null) ...[
                        const SizedBox(height: 3),
                        Text(summary,
                            style: TextStyle(
                              fontSize: 12,
                              color: CupertinoColors.secondaryLabel
                                  .resolveFrom(context),
                            )),
                      ],
                    ],
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
