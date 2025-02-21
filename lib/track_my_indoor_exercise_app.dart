import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pref/pref.dart';
import 'ui/find_devices.dart';
import 'utils/theme_manager.dart';

class TrackMyIndoorExerciseApp extends StatefulWidget {
  final BasePrefService prefService;

  const TrackMyIndoorExerciseApp({
    key,
    required this.prefService,
  }) : super(key: key);

  @override
  TrackMyIndoorExerciseAppState createState() => TrackMyIndoorExerciseAppState();
}

class TrackMyIndoorExerciseAppState extends State<TrackMyIndoorExerciseApp> {
  ThemeManager? _themeManager;

  @override
  void initState() {
    super.initState();
    _themeManager = Get.put<ThemeManager>(ThemeManager(), permanent: true);
  }

  @override
  Widget build(BuildContext context) {
    return PrefService(
      service: widget.prefService,
      child: GetMaterialApp(
          debugShowCheckedModeBanner: false,
          color: _themeManager!.getHeaderColor(),
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: _themeManager!.getThemeMode(),
          home: const FindDevicesScreen()),
    );
  }
}
