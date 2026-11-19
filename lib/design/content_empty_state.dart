import 'package:flutter/cupertino.dart';

class ContentEmptyState extends StatelessWidget {
  const ContentEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.verticalPadding = 72,
  });

  final IconData icon;
  final String title;
  final double verticalPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: verticalPadding),
      child: Column(
        spacing: 12,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: CupertinoColors.tertiarySystemFill.resolveFrom(context),
            ),
            child: SizedBox.square(
              dimension: 60,
              child: Icon(
                icon,
                size: 26,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
          ),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
