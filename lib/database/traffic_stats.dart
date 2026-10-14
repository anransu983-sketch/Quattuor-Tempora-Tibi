part of 'database.dart';

class TrafficHourly extends Table {
  @override
  String get tableName => 'traffic_hourly';

  DateTimeColumn get hour => dateTime()();

  IntColumn get upBytes => integer().withDefault(const Constant(0))();

  IntColumn get downBytes => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {hour};
}

@DriftAccessor(tables: [TrafficHourly])
class TrafficHourlyDao extends DatabaseAccessor<Database>
    with _$TrafficHourlyDaoMixin {
  TrafficHourlyDao(super.attachedDatabase);

  Future<void> addToHour(
    DateTime hour, {
    required int upBytes,
    required int downBytes,
  }) {
    return transaction(
      () => _addToHour(hour, upBytes: upBytes, downBytes: downBytes),
    );
  }

  Future<void> addBuckets(
    Map<DateTime, ({int upBytes, int downBytes})> buckets,
  ) {
    return transaction(() async {
      for (final entry in buckets.entries) {
        await _addToHour(
          entry.key,
          upBytes: entry.value.upBytes,
          downBytes: entry.value.downBytes,
        );
      }
    });
  }

  Future<void> _addToHour(
    DateTime hour, {
    required int upBytes,
    required int downBytes,
  }) async {
    final query = select(trafficHourly)
      ..where((t) => t.hour.equals(hour));
    final existing = await query.getSingleOrNull();
    if (existing == null) {
      await into(trafficHourly).insert(
        TrafficHourlyCompanion.insert(
          hour: hour,
          upBytes: Value(upBytes),
          downBytes: Value(downBytes),
        ),
      );
      return;
    }
    await (update(trafficHourly)..where((t) => t.hour.equals(hour))).write(
      TrafficHourlyCompanion(
        upBytes: Value(existing.upBytes + upBytes),
        downBytes: Value(existing.downBytes + downBytes),
      ),
    );
  }

  SimpleSelectStatement<TrafficHourly, TrafficHourlyData> hourlyInRange(
    DateTime from,
    DateTime to,
  ) {
    final query = select(trafficHourly);
    query.where(
      (t) => t.hour.isBiggerOrEqualValue(from) & t.hour.isSmallerThanValue(to),
    );
    query.orderBy([(t) => OrderingTerm.asc(t.hour)]);
    return query;
  }

  Future<void> clear() {
    return delete(trafficHourly).go();
  }
}
