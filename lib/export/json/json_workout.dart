import '../../devices/device_descriptors/device_descriptor.dart';
import '../export_model.dart';
import 'json_aggregates.dart';

class JsonWorkout {
  JsonWorkout(
    this.startDatetime,
    this.name,
    this.aggregates,
    this.startLocaleTimezone,
    this.activityType,
  );

  String name;
  int activityType;
  DateTime startDatetime;
  String startLocaleTimezone;
  JsonAggregates aggregates;

  String timeSeries(ExportModel exportModel) {
    final sb = StringBuffer();
    sb.write('"distance": [');
    sb.writeAll(
      exportModel.records.map((r) => "[${r.elapsed(exportModel.activity)}, ${r.record.distance}]"),
      ",",
    );
    sb.write('],');
    sb.write('"speed": [');
    sb.writeAll(
      exportModel.records.map((r) =>
          "[${r.elapsed(exportModel.activity)}, ${(r.record.speed ?? 0.0) * DeviceDescriptor.KMH2MS}]"),
      ",",
    );
    sb.write('],');
    sb.write('"power": [');
    sb.writeAll(
      exportModel.records.map((r) => "[${r.elapsed(exportModel.activity)}, ${r.record.power}]"),
      ",",
    );
    sb.write('],');
    // TODO: do we have cadence at all?
    sb.write('"cadence": [');
    sb.writeAll(
      exportModel.records.map((r) => "[${r.elapsed(exportModel.activity)}, ${r.record.cadence}]"),
      ",",
    );
    sb.write('],');
    // TODO: do we have heart rate at all?
    sb.write('"heartrate": [');
    sb.writeAll(
      exportModel.records.map((r) => "[${r.elapsed(exportModel.activity)}, ${r.record.heartRate}]"),
      ",",
    );
    sb.write('],');
    sb.write('"position": [');
    sb.writeAll(
      exportModel.records.map((r) =>
          '[${r.elapsed(exportModel.activity)}, {"lat": ${r.latitude}, "lng": ${r.longitude}, "elevation": ${exportModel.altitude}}]'),
      ",",
    );
    sb.write('],');
    return sb.toString();
  }

  String toJson(ExportModel exportModel) =>
      '{"name": "$name",' +
      '"activity_type": "/v7.1/activity_type/$activityType"},' +
      '"start_datetime": "${startDatetime.toUtc().toIso8601String()}",' +
      '"start_locale_timezone": "$startLocaleTimezone",' +
      '"aggregates": ${aggregates.toJson()},' +
      '"timeSeries": ${timeSeries(exportModel)}';
}
