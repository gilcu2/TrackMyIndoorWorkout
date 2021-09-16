import 'package:floor/floor.dart';
import '../../persistence/preferences.dart';
import '../../utils/display.dart' as display;
import 'workout_summary.dart';

const activitiesTableName = 'activities';

@Entity(
  tableName: activitiesTableName,
  indices: [
    Index(value: ['start'])
  ],
)
class Activity {
  @PrimaryKey(autoGenerate: true)
  int? id;
  @ColumnInfo(name: 'device_name')
  final String deviceName;
  @ColumnInfo(name: 'device_id')
  final String deviceId;
  int start; // ms since epoch
  int end; // ms since epoch
  double distance; // m
  int elapsed; // s
  int calories; // kCal
  bool uploaded;
  @ColumnInfo(name: 'strava_id')
  int stravaId;
  @ColumnInfo(name: 'four_cc')
  final String fourCC;
  String sport;
  @ColumnInfo(name: 'power_factor')
  final double powerFactor;
  @ColumnInfo(name: 'calorie_factor')
  final double calorieFactor;
  @ColumnInfo(name: 'time_zone')
  final String timeZone;
  @ColumnInfo(name: 'suunto_uploaded')
  bool suuntoUploaded;
  @ColumnInfo(name: 'suunto_blob_url')
  final String suuntoBlobUrl;
  @ColumnInfo(name: 'under_armour_uploaded')
  bool underArmourUploaded;
  @ColumnInfo(name: 'training_peaks_uploaded')
  bool trainingPeaksUploaded;
  @ColumnInfo(name: 'ua_workout_id')
  int uaWorkoutId;

  @ignore
  DateTime? startDateTime;

  String get elapsedString => Duration(seconds: elapsed).toDisplay();

  Activity({
    this.id,
    required this.deviceName,
    required this.deviceId,
    required this.start,
    this.end = 0,
    this.distance = 0.0,
    this.elapsed = 0,
    this.calories = 0,
    this.uploaded = false,
    this.suuntoUploaded = false,
    this.suuntoBlobUrl = "",
    this.underArmourUploaded = false,
    this.trainingPeaksUploaded = false,
    this.stravaId = 0,
    this.uaWorkoutId = 0,
    this.startDateTime,
    required this.fourCC,
    required this.sport,
    required this.powerFactor,
    required this.calorieFactor,
    required this.timeZone,
  });

  void finish(double? distance, int? elapsed, int? calories) {
    end = DateTime.now().millisecondsSinceEpoch;
    this.distance = distance ?? 0.0;
    this.elapsed = elapsed ?? 0;
    this.calories = calories ?? 0;
  }

  void markUploaded(int stravaId) {
    uploaded = true;
    this.stravaId = stravaId;
  }

  void markSuuntoUploaded(int workoutId) {
    suuntoUploaded = true;
    uaWorkoutId = workoutId;
  }

  String distanceString(bool si, bool highRes) {
    return display.distanceString(distance, si, highRes);
  }

  String distanceByUnit(bool si, bool highRes) {
    return display.distanceByUnit(distance, si, highRes);
  }

  Activity hydrate() {
    startDateTime = DateTime.fromMillisecondsSinceEpoch(start);
    return this;
  }

  WorkoutSummary getWorkoutSummary(String manufacturer) {
    return WorkoutSummary(
      deviceName: deviceName,
      deviceId: deviceId,
      manufacturer: manufacturer,
      start: start,
      distance: distance,
      elapsed: elapsed,
      sport: sport,
      powerFactor: powerFactor,
      calorieFactor: calorieFactor,
    );
  }
}
