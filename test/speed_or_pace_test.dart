import 'package:flutter_test/flutter_test.dart';
import 'package:track_my_indoor_exercise/utils/constants.dart';
import 'package:track_my_indoor_exercise/utils/display.dart';

void main() {
  final speeds = [
    0.0,
    0.2,
    0.3,
    0.5,
    1.0,
    1.2,
    1.3,
    1.5,
    2.0,
    5.0,
    10.0,
    12.0,
    15.0,
    20.0,
  ];
  group("speedOrPace for metric system and riding:", () {
    speeds.forEach((speed) {
      final expected = speed;
      test("$speed (Ride) -> $expected", () async {
        expect(speedOrPace(speed, true, ActivityType.Ride), expected);
      });
    });
  });

  group("speedOrPace for imperial system and riding:", () {
    speeds.forEach((speed) {
      final expected = speed * KM2MI;
      test("$speed (Ride) -> $expected", () async {
        expect(speedOrPace(speed, false, ActivityType.Ride), expected);
      });
    });
  });

  group("speedOrPace for metric system and running:", () {
    speeds.forEach((speed) {
      final expected = speed.abs() < DISPLAY_EPS ? 0.0 : 60.0 / speed;
      test("$speed (Run) -> $expected", () async {
        expect(speedOrPace(speed, true, ActivityType.Run), expected);
      });
    });
  });

  group("speedOrPace for imperial system and running:", () {
    speeds.forEach((speed) {
      final expected = speed.abs() < DISPLAY_EPS ? 0.0 : 60.0 / speed / KM2MI;
      test("$speed (Run) -> $expected", () async {
        expect(speedOrPace(speed, false, ActivityType.Run), expected);
      });
    });
  });

  group("speedOrPace for paddle sports:", () {
    final sports = [ActivityType.Kayaking, ActivityType.Canoeing, ActivityType.Rowing];
    speeds.forEach((speed) {
      sports.forEach((sport) {
        final expected = speed.abs() < DISPLAY_EPS ? 0.0 : 30.0 / speed;
        test("$speed ($sport) -> $expected", () async {
          // There's no imperial for water sports, it's always 500m
          expect(speedOrPace(speed, false, sport), expected);
          expect(speedOrPace(speed, true, sport), expected);
        });
      });
    });
  });

  group("speedOrPace for metric system and swimming:", () {
    speeds.forEach((speed) {
      final expected = speed.abs() < DISPLAY_EPS ? 0.0 : 6.0 / speed;
      test("$speed (Swim) -> $expected", () async {
        expect(speedOrPace(speed, false, ActivityType.Swim), expected);
        expect(speedOrPace(speed, true, ActivityType.Swim), expected);
      });
    });
  });

  group("speedOrPace for elliptical sports:", () {
    speeds.forEach((speed) {
      test("$speed (Elliptical)", () async {
        // There's no imperial for water sports, it's always 500m
        expect(speedOrPace(speed, false, ActivityType.Elliptical), speed);
        expect(speedOrPace(speed, true, ActivityType.Elliptical), speed);
      });
    });
  });
}
