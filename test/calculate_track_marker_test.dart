import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/track/constants.dart';
import '../lib/track/tracks.dart';
import '../lib/track/utils.dart';
import '../lib/ui/recording.dart';
import 'utils.dart';

void main() {
  final minPixel = 10;
  final maxPixel = 300;

  test('calculateTrackMarker start point is invariant', () async {
    final rnd = Random();
    final count = rnd.nextInt(99) + 1;
    getRandomDoubles(count, 2, rnd).forEach((lengthFactor) {
      trackMap["Painting"] = TrackDescriptor(
        radiusBoost: 1 + rnd.nextDouble() / 3,
        lengthFactor: lengthFactor,
      );
      final track = trackMap["Painting"];
      final size = Size(minPixel + rnd.nextDouble() * maxPixel,
          minPixel + rnd.nextDouble() * maxPixel);
      RecordingState.trackSize = size;
      final rX = (size.width - 2 * THICK) /
          (2 * track.radiusBoost + pi * track.laneShrink);
      final rY = (size.height - 2 * THICK) / (2 * track.radiusBoost);
      final r = min(rY, rX) * track.radiusBoost;
      RecordingState.trackRadius = r;
      final offset = Offset(
          rX < rY
              ? 0
              : (size.width - 2 * (THICK + r) - pi * r * track.laneShrink) / 2,
          rX > rY ? 0 : (size.height - 2 * (THICK + r)) / 2);
      RecordingState.trackOffset = offset;

      final marker = calculateTrackMarker(size, 0, lengthFactor);

      expect(marker.dx, size.width - THICK - offset.dx - r);
      expect(marker.dy, THICK + offset.dy);
    });
  });

  test('calculateTrackMarker whole laps are at the start point', () async {
    final rnd = Random();
    final count = rnd.nextInt(99) + 1;
    getRandomDoubles(count, 2, rnd).forEach((lengthFactor) {
      trackMap["Painting"] = TrackDescriptor(
        radiusBoost: 1 + rnd.nextDouble() / 3,
        lengthFactor: lengthFactor,
      );
      final track = trackMap["Painting"];
      final size = Size(minPixel + rnd.nextDouble() * maxPixel,
          minPixel + rnd.nextDouble() * maxPixel);
      RecordingState.trackSize = size;
      final rX = (size.width - 2 * THICK) /
          (2 * track.radiusBoost + pi * track.laneShrink);
      final rY = (size.height - 2 * THICK) / (2 * track.radiusBoost);
      final r = min(rY, rX) * track.radiusBoost;
      RecordingState.trackRadius = r;
      final offset = Offset(
          rX < rY
              ? 0
              : (size.width - 2 * (THICK + r) - pi * r * track.laneShrink) / 2,
          rX > rY ? 0 : (size.height - 2 * (THICK + r)) / 2);
      RecordingState.trackOffset = offset;
      final laps = rnd.nextInt(100);

      final marker = calculateTrackMarker(
          size, laps * TRACK_LENGTH * lengthFactor, lengthFactor);

      expect(marker.dx, closeTo(size.width - THICK - offset.dx - r, 1e-6));
      expect(marker.dy, closeTo(THICK + offset.dy, 1e-6));
    });
  });

  test(
      'calculateTrackMarker on the first (top) straight is placed proportionally',
      () async {
    final rnd = Random();
    final count = rnd.nextInt(99) + 1;
    getRandomDoubles(count, 2, rnd).forEach((lengthFactor) {
      trackMap["Painting"] = TrackDescriptor(
        radiusBoost: 1 + rnd.nextDouble() / 3,
        lengthFactor: lengthFactor,
      );
      final track = trackMap["Painting"];
      final size = Size(minPixel + rnd.nextDouble() * maxPixel,
          minPixel + rnd.nextDouble() * maxPixel);
      RecordingState.trackSize = size;
      final rX = (size.width - 2 * THICK) /
          (2 * track.radiusBoost + pi * track.laneShrink);
      final rY = (size.height - 2 * THICK) / (2 * track.radiusBoost);
      final r = min(rY, rX) * track.radiusBoost;
      RecordingState.trackRadius = r;
      final offset = Offset(
          rX < rY
              ? 0
              : (size.width - 2 * (THICK + r) - pi * r * track.laneShrink) / 2,
          rX > rY ? 0 : (size.height - 2 * (THICK + r)) / 2);
      RecordingState.trackOffset = offset;
      final laps = rnd.nextInt(100);
      final positionRatio = rnd.nextDouble();
      final distance =
          laps * TRACK_LENGTH * lengthFactor + positionRatio * track.laneLength;
      final trackLength = TRACK_LENGTH * lengthFactor;
      final d = distance % trackLength;
      final displacement =
          d / track.laneLength * pi * track.laneShrink / track.radiusBoost * r;

      final marker = calculateTrackMarker(size, distance, lengthFactor);

      expect(marker.dx,
          closeTo(size.width - THICK - offset.dx - r - displacement, 1e-6));
      expect(marker.dy, closeTo(THICK + offset.dy, 1e-6));
    });
  });

  test(
      'calculateTrackMarker on the first (left) chicane is placed proportionally',
      () async {
    final rnd = Random();
    final count = rnd.nextInt(99) + 1;
    getRandomDoubles(count, 2, rnd).forEach((lengthFactor) {
      trackMap["Painting"] = TrackDescriptor(
        radiusBoost: 1 + rnd.nextDouble() / 3,
        lengthFactor: lengthFactor,
      );
      final track = trackMap["Painting"];
      final size = Size(minPixel + rnd.nextDouble() * maxPixel,
          minPixel + rnd.nextDouble() * maxPixel);
      RecordingState.trackSize = size;
      final rX = (size.width - 2 * THICK) /
          (2 * track.radiusBoost + pi * track.laneShrink);
      final rY = (size.height - 2 * THICK) / (2 * track.radiusBoost);
      final r = min(rY, rX) * track.radiusBoost;
      RecordingState.trackRadius = r;
      final offset = Offset(
          rX < rY
              ? 0
              : (size.width - 2 * (THICK + r) - pi * r * track.laneShrink) / 2,
          rX > rY ? 0 : (size.height - 2 * (THICK + r)) / 2);
      RecordingState.trackOffset = offset;
      final laps = rnd.nextInt(100);
      final positionRatio = rnd.nextDouble();
      final distance = laps * TRACK_LENGTH * lengthFactor +
          track.laneLength +
          positionRatio * track.halfCircle;
      final trackLength = TRACK_LENGTH * lengthFactor;
      final d = distance % trackLength;
      final rad = (1 - (d - track.laneLength) / track.halfCircle) * pi;

      final marker = calculateTrackMarker(size, distance, lengthFactor);

      expect(marker.dx, closeTo((1 - sin(rad)) * r + THICK + offset.dx, 1e-6));
      expect(marker.dy, closeTo((cos(rad) + 1) * r + THICK + offset.dy, 1e-6));
    });
  });

  test(
      'calculateTrackMarker on the second (bottom) straight is placed proportionally',
      () async {
    final rnd = Random();
    final count = rnd.nextInt(99) + 1;
    getRandomDoubles(count, 2, rnd).forEach((lengthFactor) {
      trackMap["Painting"] = TrackDescriptor(
        radiusBoost: 1 + rnd.nextDouble() / 3,
        lengthFactor: lengthFactor,
      );
      final track = trackMap["Painting"];
      final size = Size(minPixel + rnd.nextDouble() * maxPixel,
          minPixel + rnd.nextDouble() * maxPixel);
      RecordingState.trackSize = size;
      final rX = (size.width - 2 * THICK) /
          (2 * track.radiusBoost + pi * track.laneShrink);
      final rY = (size.height - 2 * THICK) / (2 * track.radiusBoost);
      final r = min(rY, rX) * track.radiusBoost;
      RecordingState.trackRadius = r;
      final offset = Offset(
          rX < rY
              ? 0
              : (size.width - 2 * (THICK + r) - pi * r * track.laneShrink) / 2,
          rX > rY ? 0 : (size.height - 2 * (THICK + r)) / 2);
      RecordingState.trackOffset = offset;
      final laps = rnd.nextInt(100);
      final positionRatio = rnd.nextDouble();
      final distance = (laps + 0.5) * TRACK_LENGTH * lengthFactor +
          positionRatio * track.laneLength;
      final trackLength = TRACK_LENGTH * lengthFactor;
      final d = distance % trackLength;
      final displacement = (d - trackLength / 2) /
          track.laneLength *
          pi *
          track.laneShrink /
          track.radiusBoost *
          r;

      final marker = calculateTrackMarker(size, distance, lengthFactor);

      expect(marker.dx, closeTo(THICK + offset.dx + r + displacement, 1e-6));
      expect(marker.dy, closeTo(size.height - THICK - offset.dy, 1e-6));
    });
  });

  test(
      'calculateTrackMarker on the second (right) chicane is placed proportionally',
      () async {
    final rnd = Random();
    final count = rnd.nextInt(99) + 1;
    getRandomDoubles(count, 2, rnd).forEach((lengthFactor) {
      trackMap["Painting"] = TrackDescriptor(
        radiusBoost: 1 + rnd.nextDouble() / 3,
        lengthFactor: lengthFactor,
      );
      final track = trackMap["Painting"];
      final size = Size(minPixel + rnd.nextDouble() * maxPixel,
          minPixel + rnd.nextDouble() * maxPixel);
      RecordingState.trackSize = size;
      final rX = (size.width - 2 * THICK) /
          (2 * track.radiusBoost + pi * track.laneShrink);
      final rY = (size.height - 2 * THICK) / (2 * track.radiusBoost);
      final r = min(rY, rX) * track.radiusBoost;
      RecordingState.trackRadius = r;
      final offset = Offset(
          rX < rY
              ? 0
              : (size.width - 2 * (THICK + r) - pi * r * track.laneShrink) / 2,
          rX > rY ? 0 : (size.height - 2 * (THICK + r)) / 2);
      RecordingState.trackOffset = offset;
      final laps = rnd.nextInt(100);
      final positionRatio = rnd.nextDouble();
      final distance = (laps + 0.5) * TRACK_LENGTH * lengthFactor +
          track.laneLength +
          positionRatio * track.halfCircle;
      final trackLength = TRACK_LENGTH * lengthFactor;
      final d = distance % trackLength;
      final rad =
          (2 + (d - trackLength / 2 - track.laneLength) / track.halfCircle) *
              pi;

      final marker = calculateTrackMarker(size, distance, lengthFactor);

      expect(marker.dx,
          closeTo(size.width - THICK - offset.dx - (1 - sin(rad)) * r, 1e-6));
      expect(marker.dy, closeTo(r * (cos(rad) + 1) + THICK + offset.dy, 1e-6));
    });
  });
}
