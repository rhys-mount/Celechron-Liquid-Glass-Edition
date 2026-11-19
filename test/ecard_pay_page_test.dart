import 'package:celechron/page/option/ecard_pay_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';

void main() {
  for (final auth in <String?>[null, '3200000000']) {
    testWidgets('无真实认证时不显示付款码（${auth == null ? '未登录' : '测试账号'}）',
        (tester) async {
      FlutterSecureStorage.setMockInitialValues({
        if (auth != null) 'synjonesAuth': auth,
      });
      await tester.pumpWidget(const CupertinoApp(home: ECardPayPage()));
      await tester.pumpAndSettle();

      expect(find.text('校园卡未登录或登录已过期'), findsOneWidget);
      expect(find.byType(QrImageView), findsNothing);
      expect(find.textContaining('付款码：'), findsNothing);
    });
  }
}
