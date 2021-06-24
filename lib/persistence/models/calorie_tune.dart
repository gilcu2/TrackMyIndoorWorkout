import 'package:floor/floor.dart';

const CALORIE_TUNE_TABLE_NAME = 'calorie_tune';

@Entity(
  tableName: CALORIE_TUNE_TABLE_NAME,
  indices: [
    Index(value: ['mac'])
  ],
)
class CalorieTune {
  @PrimaryKey(autoGenerate: true)
  int? id;
  final String mac;
  @ColumnInfo(name: 'calorie_factor')
  double calorieFactor;

  int time; // ms since epoch

  CalorieTune({
    this.id,
    required this.mac,
    required this.calorieFactor,
    required this.time,
  });

  DateTime get timeStamp => DateTime.fromMillisecondsSinceEpoch(time);
}
