import 'package:flutter/cupertino.dart';

import 'liquid_glass/navigation_action.dart';

class CelechronSliverTextHeader extends StatelessWidget {
  const CelechronSliverTextHeader({
    super.key,
    required this.subtitle,
    this.right,
    this.transitionBetweenRoutes = true,
  });

  final String subtitle;
  final Widget? right;
  final bool transitionBetweenRoutes;

  @override
  Widget build(BuildContext context) {
    void goBack() => Navigator.of(context).maybePop();

    return CupertinoSliverNavigationBar(
      largeTitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      alwaysShowMiddle: false,
      border: null,
      stretch: true,
      transitionBetweenRoutes: transitionBetweenRoutes,
      leading: ModalRoute.of(context)?.canPop == true
          ? NavigationAction(
              icon: CupertinoIcons.back,
              label: '返回',
              onPressed: goBack,
              fallback: CupertinoNavigationBarBackButton(onPressed: goBack),
            )
          : null,
      trailing: right,
    );
  }
}
