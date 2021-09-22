import 'dart:async';
import 'package:floor/floor.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:tuple/tuple.dart';
import '../devices/device_descriptors/device_descriptor.dart';
import '../devices/device_map.dart';
import '../utils/time_zone.dart';
import 'dao/activity_dao.dart';
import 'dao/calorie_tune_dao.dart';
import 'dao/device_usage_dao.dart';
import 'dao/power_tune_dao.dart';
import 'dao/record_dao.dart';
import 'dao/workout_summary_dao.dart';
import 'models/activity.dart';
import 'models/calorie_tune.dart';
import 'models/device_usage.dart';
import 'models/power_tune.dart';
import 'models/record.dart';
import 'models/workout_summary.dart';

part 'database.g.dart'; // the generated code is in that file

@Database(version: 13, entities: [
  Activity,
  Record,
  DeviceUsage,
  CalorieTune,
  PowerTune,
  WorkoutSummary,
])
abstract class AppDatabase extends FloorDatabase {
  ActivityDao get activityDao;
  RecordDao get recordDao;
  DeviceUsageDao get deviceUsageDao;
  CalorieTuneDao get calorieTuneDao;
  PowerTuneDao get powerTuneDao;
  WorkoutSummaryDao get workoutSummaryDao;

  Future<int> rowCount(String tableName, String deviceId) async {
    final result = await database
        .rawQuery("SELECT COUNT(`id`) AS cnt FROM `$tableName` WHERE `mac` = ?", [deviceId]);

    if (result.isEmpty) {
      return 0;
    }

    return result[0]['cnt'] as int? ?? 0;
  }

  Future<bool> hasDeviceUsage(String deviceId) async {
    return await rowCount(deviceUsageTableName, deviceId) > 0;
  }

  Future<bool> hasPowerTune(String deviceId) async {
    return await rowCount(powerTuneTableName, deviceId) > 0;
  }

  Future<double> powerFactor(String deviceId) async {
    if (!await hasPowerTune(deviceId)) {
      return 1.0;
    }

    final powerTune = await powerTuneDao.findPowerTuneByMac(deviceId).first;

    return powerTune?.powerFactor ?? 1.0;
  }

  Future<bool> hasCalorieTune(String deviceId) async {
    return await rowCount(calorieTuneTableName, deviceId) > 0;
  }

  Future<double> calorieFactor(String deviceId, DeviceDescriptor descriptor) async {
    if (!await hasCalorieTune(deviceId)) {
      return descriptor.calorieFactorDefault;
    }

    final calorieTune = await calorieTuneDao.findCalorieTuneByMac(deviceId).first;

    return calorieTune?.calorieFactor ?? descriptor.calorieFactorDefault;
  }

  Future<bool> hasLeaderboardData() async {
    final result =
        await database.rawQuery("SELECT COUNT(`id`) AS cnt FROM `$workoutSummariesTableName`");

    if (result.isEmpty) {
      return false;
    }

    return (result[0]['cnt'] as int? ?? 0) > 0;
  }

  Future<List<String>> findDistinctWorkoutSummarySports() async {
    final result =
        await database.rawQuery("SELECT DISTINCT `sport` FROM `$workoutSummariesTableName`");

    if (result.isEmpty) {
      return [];
    }

    return result.map((row) => row['sport'].toString()).toList(growable: false);
  }

  Future<List<Tuple2<String, String>>> findDistinctWorkoutSummaryDevices() async {
    final result = await database
        .rawQuery("SELECT DISTINCT `device_id`, `device_name` FROM `$workoutSummariesTableName`");

    if (result.isEmpty) {
      return [];
    }

    return result
        .map((row) =>
            Tuple2<String, String>(row['device_id'] as String, row['device_name'] as String))
        .toList(growable: false);
  }
}

final migration1to2 = Migration(1, 2, (database) async {
  // Cannot add a non null column
  await database.execute("ALTER TABLE `$activitiesTableName` ADD COLUMN `four_cc` TEXT");
});

final migration2to3 = Migration(2, 3, (database) async {
  await database.execute(
      "UPDATE `$activitiesTableName` SET four_cc='$PRECOR_SPINNER_CHRONO_POWER_FOURCC' WHERE 1=1");
});

final migration3to4 = Migration(3, 4, (database) async {
  // Cannot add a non null column
  await database.execute("ALTER TABLE `$activitiesTableName` ADD COLUMN `sport` TEXT");
  await database.execute(
      "UPDATE `$activitiesTableName` SET `sport`='Kayaking' WHERE `four_cc`='$KAYAK_PRO_GENESIS_PORT_FOURCC'");
  await database.execute("UPDATE `$activitiesTableName` SET `sport`='Ride' WHERE `sport` IS NULL");
});

final migration4to5 = Migration(4, 5, (database) async {
  await database.execute("CREATE TABLE IF NOT EXISTS `$deviceUsageTableName` "
      "(`id` INTEGER PRIMARY KEY AUTOINCREMENT, `sport` TEXT NOT NULL, `mac` TEXT NOT NULL, "
      "`name` TEXT NOT NULL, `manufacturer` TEXT NOT NULL, `manufacturer_name` TEXT, "
      "`time` INTEGER NOT NULL)");
});

final migration5to6 = Migration(5, 6, (database) async {
  await database.execute("CREATE TABLE IF NOT EXISTS `$calorieTuneTableName` "
      "(`id` INTEGER PRIMARY KEY AUTOINCREMENT, `mac` TEXT NOT NULL, "
      "`calorie_factor` REAL NOT NULL, `time` INTEGER NOT NULL)");
  await database.execute("CREATE TABLE IF NOT EXISTS `$powerTuneTableName` "
      "(`id` INTEGER PRIMARY KEY AUTOINCREMENT, `mac` TEXT NOT NULL, "
      "`power_factor` REAL NOT NULL, `time` INTEGER NOT NULL)");

  // Cannot add a non null column
  await database.execute("ALTER TABLE `$activitiesTableName` ADD COLUMN `power_factor` FLOAT");
  await database.execute("ALTER TABLE `$activitiesTableName` ADD COLUMN `calorie_factor` FLOAT");

  await database.execute("UPDATE `$activitiesTableName` "
      "SET device_id='$MPOWER_IMPORT_DEVICE_ID' WHERE `device_id`=''");
  await database.execute("UPDATE `$activitiesTableName` SET `power_factor`=1.0");
  await database.execute("UPDATE `$activitiesTableName` SET `calorie_factor`=1.0");
  await database.execute(
      "UPDATE `$activitiesTableName` SET `calorie_factor`=1.4 WHERE `four_cc`='$SCHWINN_IC_BIKE_FOURCC'");
  await database.execute(
      "UPDATE `$activitiesTableName` SET `calorie_factor`=3.9 WHERE `four_cc`='$SCHWINN_AC_PERF_PLUS_FOURCC'");
});

final migration6to7 = Migration(6, 7, (database) async {
  await database.execute("CREATE TABLE IF NOT EXISTS `$workoutSummariesTableName` "
      "(`id` INTEGER PRIMARY KEY AUTOINCREMENT, `device_name` TEXT NOT NULL, "
      "`device_id` TEXT NOT NULL, `manufacturer` TEXT NOT NULL, `start` INTEGER NOT NULL, "
      "`distance` REAL NOT NULL, `elapsed` INTEGER NOT NULL, `speed` REAL NOT NULL, "
      "`sport` TEXT NOT NULL, `power_factor` REAL NOT NULL, `calorie_factor` REAL NOT NULL)");
});

final migration7to8 = Migration(7, 8, (database) async {
  await database
      .execute("UPDATE `$activitiesTableName` SET `strava_id`=0 WHERE `strava_id` IS NULL");
});

final migration8to9 = Migration(8, 9, (database) async {
  await database.execute("ALTER TABLE `$activitiesTableName` ADD COLUMN `time_zone` TEXT");

  final timeZone = await getTimeZone();
  await database.execute(
      "UPDATE `$activitiesTableName` SET `time_zone`='$timeZone' WHERE `time_zone` IS NULL");
});

final migration9to10 = Migration(9, 10, (database) async {
  await database.execute(
      "ALTER TABLE `$activitiesTableName` ADD COLUMN `suunto_uploaded` INTEGER NOT NULL DEFAULT 0");
  await database.execute(
      "ALTER TABLE `$activitiesTableName` ADD COLUMN `suunto_blob_url` TEXT NOT NULL DEFAULT ''");
  await database.execute(
      "ALTER TABLE `$activitiesTableName` ADD COLUMN `under_armour_uploaded` INTEGER NOT NULL DEFAULT 0");
  await database.execute(
      "ALTER TABLE `$activitiesTableName` ADD COLUMN `training_peaks_uploaded` INTEGER NOT NULL DEFAULT 0");
});

final migration10to11 = Migration(10, 11, (database) async {
  await database.execute(
      "ALTER TABLE `$activitiesTableName` ADD COLUMN `ua_workout_id` INTEGER NOT NULL DEFAULT 0");
});

final migration11to12 = Migration(11, 12, (database) async {
  await database.execute(
      "ALTER TABLE `$activitiesTableName` ADD COLUMN `suunto_upload_id` INTEGER NOT NULL DEFAULT 0");
  await database.execute(
      "ALTER TABLE `$activitiesTableName` ADD COLUMN `suunto_workout_url` TEXT NOT NULL DEFAULT ''");
});

final migration12to13 = Migration(12, 13, (database) async {
  await database.execute(
      "ALTER TABLE `$activitiesTableName` ADD COLUMN `suunto_upload_identifier` TEXT NOT NULL DEFAULT ''");
});
