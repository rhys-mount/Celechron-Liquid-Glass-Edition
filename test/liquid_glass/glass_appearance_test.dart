import 'dart:io';

import 'package:celechron/design/liquid_glass/glass_appearance.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  test('the glass switch defaults to on and persists across launches',
      () async {
    final directory = await Directory.systemTemp.createTemp('celechron_glass_');
    Hive.init(directory.path);
    addTearDown(() async {
      await Hive.close();
      await Hive.deleteBoxFromDisk('options');
      await directory.delete();
    });

    var options = await Hive.openBox('options');
    await options.put('existingSetting', 45);
    final appearance = GlassAppearance(options, available: true);
    expect(appearance.enabled.value, isTrue);
    await appearance.setEnabled(false);
    await options.close();

    options = await Hive.openBox('options');
    final restored = GlassAppearance(options, available: true);
    expect(restored.enabled.value, isFalse);
    expect(options.get('existingSetting'), 45);
    await restored.setEnabled(true);
    expect(GlassAppearance(options, available: true).enabled.value, isTrue);
  });
}
