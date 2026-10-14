import 'package:drift/native.dart';
import 'package:fl_clash/database/database.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/views/traffic_stats_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/test_app.dart';

void main() {
  late Database testDatabase;

  setUp(() {
    testDatabase = Database(NativeDatabase.memory());
    database = testDatabase;
  });

  tearDown(() async {
    await testDatabase.close();
  });

  TrafficHourlyData row(DateTime hour, int upBytes, int downBytes) {
    return TrafficHourlyData(
      hour: hour,
      upBytes: upBytes,
      downBytes: downBytes,
    );
  }

  DateTime currentHour() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, now.hour);
  }

  Future<void> pumpView(
    WidgetTester tester, {
    List<TrafficHourlyData> dayRows = const [],
    List<TrafficHourlyData> weekRows = const [],
    List<TrafficHourlyData> monthRows = const [],
  }) async {
    tester.view.physicalSize = const Size(800, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer(
      overrides: [
        viewSizeProvider.overrideWithBuild((_, _) => const Size(800, 2200)),
        trafficHourlyStatsProvider(
          0,
        ).overrideWith((ref) => Stream.value(dayRows)),
        trafficHourlyStatsProvider(
          1,
        ).overrideWith((ref) => Stream.value(weekRows)),
        trafficHourlyStatsProvider(
          2,
        ).overrideWith((ref) => Stream.value(monthRows)),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const TestApp(
          locale: Locale('zh', 'CN'),
          child: TrafficStatsView(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders sections with empty states', (tester) async {
    await pumpView(tester);

    expect(find.text('流量统计'), findsWidgets);
    expect(find.text('日'), findsOneWidget);
    expect(find.text('周'), findsOneWidget);
    expect(find.text('月'), findsOneWidget);
    expect(find.text('下行'), findsWidgets);
    expect(find.text('上行'), findsWidgets);
    expect(find.text('0 B'), findsNWidgets(2));
    expect(find.text('暂无应用流量数据'), findsOneWidget);
    expect(find.text('暂无节点流量数据'), findsOneWidget);
    expect(find.text('暂无足迹记录'), findsOneWidget);
  });

  testWidgets('recorded traffic shows up in the totals', (tester) async {
    await pumpView(
      tester,
      dayRows: [row(currentHour(), 2048, 1024)],
    );

    expect(find.text('1 KB'), findsOneWidget);
    expect(find.text('2 KB'), findsOneWidget);
    expect(find.text('0 B'), findsNothing);
  });

  testWidgets('switching range changes the totals', (tester) async {
    final hour = currentHour();
    await pumpView(
      tester,
      dayRows: [row(hour, 2048, 1024)],
      weekRows: [row(hour, 4096, 2048)],
      monthRows: [row(hour, 8192, 4096)],
    );
    expect(find.text('1 KB'), findsOneWidget);
    expect(find.text('2 KB'), findsOneWidget);

    await tester.tap(find.text('周'));
    await tester.pumpAndSettle();
    expect(find.text('2 KB'), findsOneWidget);
    expect(find.text('4 KB'), findsOneWidget);

    await tester.tap(find.text('月'));
    await tester.pumpAndSettle();
    expect(find.text('4 KB'), findsOneWidget);
    expect(find.text('8 KB'), findsOneWidget);
  });

  testWidgets('sort menu lists the options', (tester) async {
    await pumpView(tester);

    await tester.tap(find.byTooltip('排序'));
    await tester.pumpAndSettle();

    expect(find.text('应用名称 ↑'), findsOneWidget);
    expect(find.text('流量'), findsWidgets);
  });

  testWidgets('clear asks for confirmation then clears the records', (
    tester,
  ) async {
    final hour = currentHour();
    await testDatabase.trafficHourlyDao.addToHour(
      hour,
      upBytes: 2048,
      downBytes: 1024,
    );

    await pumpView(tester, dayRows: [row(hour, 2048, 1024)]);
    expect(find.text('1 KB'), findsOneWidget);

    await tester.tap(find.byTooltip('清空记录'));
    await tester.pumpAndSettle();
    expect(find.text('确定清空全部流量统计记录吗？清空后无法恢复。'), findsOneWidget);

    await tester.tap(find.text('清空'));
    await tester.pumpAndSettle();

    final rows = await testDatabase.trafficHourlyDao
        .hourlyInRange(hour, hour.add(const Duration(days: 1)))
        .get();
    expect(rows, isEmpty);
  });
}
