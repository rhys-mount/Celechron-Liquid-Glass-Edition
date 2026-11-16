import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../services/diagnostic_log_service.dart';

class GlassAppearance {
  GlassAppearance(this._options, {required this.available})
      : enabled = (_options.get(_enabledKey) != false).obs;

  static const _enabledKey = 'liquidGlassEnabled';
  static const theme = bool.fromEnvironment('CELECHRON_GLASS_IOS27')
      ? GlassThemeData.ios27()
      : GlassThemeData.ios26();

  static GlassQuality get quality => ImageFilter.isShaderFilterSupported
      ? GlassQuality.standard
      : GlassQuality.minimal;

  final Box _options;
  final bool available;
  final RxBool enabled;

  static Future<GlassAppearance> load(Box options) async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      return GlassAppearance(options, available: false);
    }
    try {
      await LiquidGlassWidgets.initialize(warmUpMode: GlassWarmUpMode.never);
      return GlassAppearance(options, available: true);
    } on Object catch (error, stackTrace) {
      DiagnosticLogService.instance.record(
        level: CelechronLogLevel.error,
        module: 'appearance',
        operation: 'initializeGlass',
        message: 'Liquid Glass 初始化失败，使用原有导航栏',
        error: error,
        stackTrace: stackTrace,
      );
      return GlassAppearance(options, available: false);
    }
  }

  Future<void> setEnabled(bool value) async {
    await _options.put(_enabledKey, value);
    enabled.value = value;
  }
}
