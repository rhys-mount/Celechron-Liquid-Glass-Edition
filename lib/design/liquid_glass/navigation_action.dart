import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'glass_appearance.dart';

class NavigationAction extends StatelessWidget {
  const NavigationAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final cupertino = CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Icon(icon, semanticLabel: label),
    );
    if (!Get.isRegistered<GlassAppearance>()) return cupertino;

    final appearance = Get.find<GlassAppearance>();
    if (!appearance.available) return cupertino;

    return Obx(() {
      if (!appearance.enabled.value) return cupertino;
      return GlassIconButton(
        icon: Icon(icon),
        semanticLabel: label,
        onPressed: onPressed,
        useOwnLayer: true,
        quality: GlassAppearance.quality,
      );
    });
  }
}
