import 'package:drift/native.dart';
import 'package:fl_clash/database/database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Database database;

  setUp(() {
    database = Database(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test('hourly buckets accumulate and read back in range', () async {
    final hour = DateTime(2026, 10, 15, 10);
    await database.trafficHourlyDao.addToHour(
      hour,
      upBytes: 100,
      downBytes: 200,
    );
    await database.trafficHourlyDao.addToHour(hour, upBytes: 50, downBytes: 25);
    await database.trafficHourlyDao.addToHour(
      hour.add(const Duration(hours: 1)),
      upBytes: 10,
      downBytes: 20,
    );

    final rows = await database.trafficHourlyDao
        .hourlyInRange(hour, hour.add(const Duration(hours: 2)))
        .get();
    expect(rows, hasLength(2));
    expect(rows[0].hour, hour);
    expect(rows[0].upBytes, 150);
    expect(rows[0].downBytes, 225);
    expect(rows[1].upBytes, 10);

    final outOfRange = await database.trafficHourlyDao
        .hourlyInRange(
          hour.add(const Duration(hours: 2)),
          hour.add(const Duration(hours: 3)),
        )
        .get();
    expect(outOfRange, isEmpty);
  });

  test('addBuckets writes several hours in one transaction', () async {
    final first = DateTime(2026, 10, 15, 10);
    final second = first.add(const Duration(hours: 1));
    await database.trafficHourlyDao.addBuckets({
      first: (upBytes: 7, downBytes: 8),
      second: (upBytes: 9, downBytes: 10),
    });

    final rows = await database.trafficHourlyDao
        .hourlyInRange(first, second.add(const Duration(hours: 1)))
        .get();
    expect(rows, hasLength(2));
    expect(rows[0].upBytes, 7);
    expect(rows[1].downBytes, 10);
  });

  test('clear drops every hourly row', () async {
    final hour = DateTime(2026, 10, 15, 10);
    await database.trafficHourlyDao.addToHour(
      hour,
      upBytes: 100,
      downBytes: 200,
    );
    await database.trafficHourlyDao.clear();

    final rows = await database.trafficHourlyDao
        .hourlyInRange(hour, hour.add(const Duration(hours: 1)))
        .get();
    expect(rows, isEmpty);
  });
}
