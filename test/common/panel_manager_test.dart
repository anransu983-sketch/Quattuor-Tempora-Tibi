import 'package:fl_clash/common/panel_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromValue falls back to zashboard', () {
    expect(DreamPanel.fromValue('zashboard'), DreamPanel.zashboard);
    expect(DreamPanel.fromValue('metacubexd'), DreamPanel.metacubexd);
    expect(DreamPanel.fromValue('yacd'), DreamPanel.yacd);
    expect(DreamPanel.fromValue(null), DreamPanel.zashboard);
    expect(DreamPanel.fromValue('bogus'), DreamPanel.zashboard);
  });

  test('dashboardUrl carries the backend connection params', () {
    expect(
      DreamPanel.zashboard.dashboardUrl('127.0.0.1', '9090', 'secret'),
      'http://127.0.0.1:9090/ui/#/setup?hostname=127.0.0.1&port=9090&secret=secret',
    );
    expect(
      DreamPanel.metacubexd.dashboardUrl('127.0.0.1', '9090', 'secret'),
      'http://127.0.0.1:9090/ui/?hostname=127.0.0.1&port=9090&secret=secret',
    );
    expect(
      DreamPanel.yacd.dashboardUrl('127.0.0.1', '9090', 'secret'),
      'http://127.0.0.1:9090/ui/?hostname=127.0.0.1&port=9090&secret=secret',
    );
  });

  test('dashboardUrl encodes a custom secret', () {
    expect(
      DreamPanel.yacd.dashboardUrl('127.0.0.1', '9090', 'a b+c'),
      'http://127.0.0.1:9090/ui/?hostname=127.0.0.1&port=9090&secret=a+b%2Bc',
    );
  });
}
