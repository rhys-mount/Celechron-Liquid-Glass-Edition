import 'package:flutter/cupertino.dart';

class CardAction extends StatelessWidget {
  const CardAction({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressFeedback = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool pressFeedback;

  @override
  Widget build(BuildContext context) {
    if (onTap == null && onLongPress == null) return child;
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      pressedOpacity:
          pressFeedback && !MediaQuery.disableAnimationsOf(context) ? 0.76 : 1,
      onPressed: onTap,
      onLongPress: onLongPress,
      child: child,
    );
  }
}
