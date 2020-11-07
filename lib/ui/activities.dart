import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:listview_utils/listview_utils.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:share_files_and_screenshot_widgets/share_files_and_screenshot_widgets.dart';
import 'package:url_launcher/url_launcher.dart';
import '../persistence/models/activity.dart';
import '../persistence/database.dart';
import '../strava/error_codes.dart';
import '../strava/strava_service.dart';
import '../tcx/tcx_output.dart';
import 'find_devices.dart';
import 'records.dart';

class ActivitiesScreen extends StatefulWidget {
  ActivitiesScreen({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return ActivitiesScreenState();
  }
}

class ActivitiesScreenState extends State<ActivitiesScreen> {
  AppDatabase _database;
  bool _isLoading;
  int _deletionCount;

  AppDatabase get database => _database;

  @override
  initState() {
    _isLoading = true;
    _deletionCount = 0;
    super.initState();
    $FloorAppDatabase
        .databaseBuilder('app_database.db')
        .addMigrations([migration1to2, migration2to3])
        .build()
        .then((db) {
          setState(() {
            _database = db;
            _isLoading = false;
          });
        });
  }

  @override
  dispose() {
    _database.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Activities'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.help),
            onPressed: () async {
              if (await canLaunch(HELP_URL)) {
                launch(HELP_URL);
              } else {
                Get.snackbar("Attention", "Cannot open URL");
              }
            },
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: _database == null
            ? Container()
            : CustomListView(
                key: Key("CLV$_deletionCount"),
                paginationMode: PaginationMode.page,
                initialOffset: 0,
                loadingBuilder: (BuildContext context) =>
                    Center(child: CircularProgressIndicator()),
                adapter: ListAdapter(
                  fetchItems: (int offset, int limit) async {
                    final data = await _database.activityDao
                        .findActivities(offset, limit);
                    return ListItems(data, reachedToEnd: data.length < limit);
                  },
                ),
                errorBuilder: (context, error, state) {
                  return Column(
                    children: <Widget>[
                      Text(error.toString()),
                      RaisedButton(
                        onPressed: () => state.loadMore(),
                        child: Text('Retry'),
                      ),
                    ],
                  );
                },
                separatorBuilder: (context, _) {
                  return Divider(height: 2);
                },
                empty: Center(
                  child: Text('No activities found'),
                ),
                itemBuilder: (context, _, item) {
                  final activity = item as Activity;
                  final startStamp =
                      DateTime.fromMillisecondsSinceEpoch(activity.start);
                  final dateString = DateFormat.yMd().format(startStamp);
                  final timeString = DateFormat.Hms().format(startStamp);
                  return ListTile(
                    onTap: () async => await Get.to(RecordsScreen(
                        activity: item, size: Get.mediaQuery.size)),
                    title: Text(
                        '$dateString $timeString on ${activity.deviceName}'),
                    subtitle: Text(
                        '${activity.elapsed} s, ${activity.distance.toStringAsFixed(0)} m, ${activity.calories} kCal'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.file_upload,
                              color: activity.uploaded
                                  ? Colors.grey
                                  : Colors.green),
                          onPressed: () async {
                            StravaService stravaService;
                            if (!Get.isRegistered<StravaService>()) {
                              stravaService =
                                  Get.put<StravaService>(StravaService());
                            } else {
                              stravaService = Get.find<StravaService>();
                            }
                            final success = await stravaService.login();
                            if (!success) {
                              Get.snackbar(
                                  "Warning", "Strava login unsuccessful");
                            } else {
                              final records = await _database.recordDao
                                  .findAllActivityRecords(activity.id);
                              setState(() {
                                _isLoading = true;
                              });
                              final statusCode =
                                  await stravaService.upload(activity, records);
                              setState(() {
                                _isLoading = false;
                              });
                              Get.snackbar(
                                  "Upload",
                                  statusCode == statusOk ||
                                          statusCode >= 200 && statusCode < 300
                                      ? "Activity ${activity.id} submitted successfully"
                                      : "Activity ${activity.id} upload failure");
                            }
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.file_download),
                          onPressed: () async {
                            final records = await _database.recordDao
                                .findAllActivityRecords(activity.id);
                            final tcxGzip = await TCXOutput()
                                .getTcxOfActivity(activity, records);
                            final persistenceValues =
                                activity.getPersistenceValues();
                            ShareFilesAndScreenshotWidgets().shareFile(
                                persistenceValues['name'],
                                persistenceValues['fileName'],
                                tcxGzip,
                                TCXOutput.MIME_TYPE,
                                text: 'Share a ride on ${activity.deviceName}');
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () async {
                            Get.defaultDialog(
                              title: 'Warning!!!',
                              middleText:
                                  'Are you sure to delete this Activity?',
                              confirm: FlatButton(
                                child: Text("Yes"),
                                onPressed: () async {
                                  await _database.recordDao
                                      .deleteAllActivityRecords(activity.id);
                                  await _database.activityDao
                                      .deleteActivity(activity);
                                  setState(() {
                                    _deletionCount++;
                                  });
                                  Get.close(1);
                                },
                              ),
                              cancel: FlatButton(
                                child: Text("No"),
                                onPressed: () => Get.close(1),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
