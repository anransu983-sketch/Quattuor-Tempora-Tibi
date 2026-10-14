import 'package:drift/native.dart';
import 'package:fl_clash/database/database.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Database testDatabase;
  late ProviderContainer container;

  setUp(() {
    testDatabase = Database(NativeDatabase.memory());
    database = testDatabase;
    container = ProviderContainer();
  });

  tearDown(() async {
    container.dispose();
    await testDatabase.close();
  });

  DateTime currentHour() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, now.hour);
  }

  Future<List<TrafficHourlyData>> readRange(int rangeIndex) {
    final subscription = container.listen(
      trafficHourlyStatsProvider(rangeIndex),
      (_, _) {},
    );
    addTearDown(subscription.close);
    return container.read(trafficHourlyStatsProvider(rangeIndex).future);
  }

  test('day range holds the current hour but not eight days ago', () async {
    final hour = currentHour();
    final eightDaysAgo = hour.subtract(const Duration(days: 8));
    await testDatabase.trafficHourlyDao.addToHour(
      hour,
      upBytes: 1,
      downBytes: 2,
    );
    await testDatabase.trafficHourlyDao.addToHour(
      eightDaysAgo,
      upBytes: 3,
      downBytes: 4,
    );

    final rows = await readRange(0);

    expect(rows.map((row) => row.hour), [hour]);
  });

  test('week range holds the current hour but not eight days ago', () async {
    final hour = currentHour();
    final eightDaysAgo = hour.subtract(const Duration(days: 8));
    await testDatabase.trafficHourlyDao.addToHour(
      hour,
      upBytes: 1,
      downBytes: 2,
    );
    await testDatabase.trafficHourlyDao.addToHour(
      eightDaysAgo,
      upBytes: 3,
      downBytes: 4,
    );

    final rows = await readRange(1);

    expect(rows.map((row) => row.hour), [hour]);
  });

  test('month range holds the current hour', () async {
    final hour = currentHour();
    await testDatabase.trafficHourlyDao.addToHour(
      hour,
      upBytes: 1,
      downBytes: 2,
    );

    final rows = await readRange(2);

    expect(rows.map((row) => row.hour), [hour]);
  });
}
