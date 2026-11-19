import 'package:celechron/design/card_detail_line.dart';
import 'package:celechron/design/custom_colors.dart';
import 'package:celechron/design/custom_decoration.dart';
import 'package:celechron/design/round_rectangle_card.dart';
import 'package:celechron/model/period.dart';
import 'package:flutter/cupertino.dart';

class EventListCard extends StatelessWidget {
  const EventListCard({
    super.key,
    required this.period,
    required this.timeLabel,
    this.onTap,
    this.footer,
    this.markerColor,
  });

  final Period period;
  final String timeLabel;
  final VoidCallback? onTap;
  final Widget? footer;
  final Color? markerColor;

  @override
  Widget build(BuildContext context) {
    final color = markerColor ??
        switch (period.type) {
          PeriodType.classes => TimeColors.colorFromHour(period.startTime.hour),
          PeriodType.test => CupertinoColors.systemPink,
          PeriodType.user when period.fromUid != null =>
            UidColors.colorFromUid(period.fromFromUid ?? period.fromUid),
          _ => CupertinoColors.inactiveGray,
        };
    final body = Row(
      spacing: 10,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 5,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 7,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: SizedBox.square(
                      dimension: 11,
                      child: DecoratedBox(
                        decoration: customDecoration(
                          color: color,
                          shape: periodTypeShape[period.type]!,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      period.summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.label.resolveFrom(context),
                      ),
                    ),
                  ),
                ],
              ),
              CardDetailLine(CupertinoIcons.clock, timeLabel, emphasis: true),
              if (period.location.isNotEmpty)
                CardDetailLine(CupertinoIcons.location, period.location),
            ],
          ),
        ),
        if (onTap != null) const CupertinoListTileChevron(),
      ],
    );
    return RoundRectangleCard.content(
      animate: false,
      onTap: onTap,
      child: footer == null
          ? body
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 8,
              children: [body, footer!],
            ),
    );
  }
}
