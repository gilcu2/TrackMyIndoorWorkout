import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:preferences/preferences.dart';
import 'persistence/preferences.dart';
import 'track_my_indoor_exercise_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

  await PrefService.init(prefix: 'pref_');
  Map<String, dynamic> prefDefaults = {
    UNIT_SYSTEM_TAG: UNIT_SYSTEM_DEFAULT,
    INSTANT_SCAN_TAG: INSTANT_SCAN_DEFAULT,
    SCAN_DURATION_TAG: SCAN_DURATION_DEFAULT,
    INSTANT_WORKOUT_TAG: INSTANT_WORKOUT_DEFAULT,
    LAST_EQUIPMENT_ID_TAG: LAST_EQUIPMENT_ID_DEFAULT,
    INSTANT_UPLOAD_TAG: INSTANT_UPLOAD_DEFAULT,
    SIMPLER_UI_TAG: await getSimplerUiDefault(),
    DEVICE_FILTERING_TAG: DEVICE_FILTERING_DEFAULT,
    MEASUREMENT_PANELS_EXPANDED_TAG: MEASUREMENT_PANELS_EXPANDED_DEFAULT,
    MEASUREMENT_DETAIL_SIZE_TAG: MEASUREMENT_DETAIL_SIZE_DEFAULT,
    APP_DEBUG_MODE_TAG: APP_DEBUG_MODE_DEFAULT,
    THROTTLE_POWER_TAG: THROTTLE_POWER_DEFAULT,
    THROTTLE_OTHER_TAG: THROTTLE_OTHER_DEFAULT,
    COMPRESS_DOWNLOAD_TAG: COMPRESS_DOWNLOAD_DEFAULT,
    STROKE_RATE_SMOOTHING_TAG: STROKE_RATE_SMOOTHING_DEFAULT,
  };
  preferencesSpecs.forEach((prefSpec) {
    prefDefaults.addAll({
      prefSpec.thresholdTag: prefSpec.thresholdDefault,
      prefSpec.zonesTag: prefSpec.zonesDefault,
    });
  });
  PrefService.setDefaultValues(prefDefaults);

  runApp(TrackMyIndoorExerciseApp());
}
