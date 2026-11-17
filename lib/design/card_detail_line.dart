import 'package:flutter/cupertino.dart';

class CardDetailLine extends StatelessWidget {
  const CardDetailLine(this.icon, this.label,
      {super.key, this.emphasis = false});

  final IconData icon;
  final String label;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final color =
        (emphasis ? CupertinoColors.label : CupertinoColors.secondaryLabel)
            .resolveFrom(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: 6,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 14, color: color),
        ),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: emphasis ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}
