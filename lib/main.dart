import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'devices/company_registry.dart';
import 'track_my_indoor_exercise_app.dart';
import 'ui/models/advertisement_cache.dart';
import 'utils/init_preferences.dart';
import 'utils/logging.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefService = await initPreferences();

  final companyRegistry = CompanyRegistry();
  await companyRegistry.loadCompanyIdentifiers();
  Get.put<CompanyRegistry>(companyRegistry, permanent: true);

  Get.put<AdvertisementCache>(AdvertisementCache(), permanent: true);

  PackageInfo.fromPlatform().then((PackageInfo packageInfo) {
    Get.put<PackageInfo>(packageInfo, permanent: true);
    Logging.logVersion(packageInfo);
  });

  runApp(TrackMyIndoorExerciseApp(prefService: prefService));
}
