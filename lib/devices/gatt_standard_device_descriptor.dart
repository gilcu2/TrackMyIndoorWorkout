import 'dart:collection';

import '../persistence/models/activity.dart';
import '../persistence/models/record.dart';
import 'device_descriptor.dart';
import 'short_metric_descriptor.dart';
import 'three_byte_metric_descriptor.dart';

class CadenceData {
  final double seconds;
  int revolutions;

  CadenceData({this.seconds, this.revolutions});
}

class GattStandardDeviceDescriptor extends DeviceDescriptor {
  // Primary metrics
  int _featuresFlag;
  ShortMetricDescriptor _speedMetric;
  ShortMetricDescriptor _cadenceMetric;
  ThreeByteMetricDescriptor _distanceMetric;
  ShortMetricDescriptor _powerMetric;
  ShortMetricDescriptor _caloriesMetric;
  ShortMetricDescriptor _timeMetric;

  // Secondary (Crank cadence) metrics
  int _cadenceFlag;
  ShortMetricDescriptor _revolutions;
  ShortMetricDescriptor _revolutionTime;

  ListQueue<CadenceData> _cadenceData;
  static const int REVOLUTION_SLIDING_WINDOW = 15; // Seconds
  static const int EVENT_TIME_OVERFLOW = 64; // Overflows every 64 seconds
  double _residueCalories;

  GattStandardDeviceDescriptor({
    fourCC,
    vendorName,
    modelName,
    fullName = '',
    namePrefix,
    nameStart,
    manufacturer,
    model,
    primaryMeasurementServiceId,
    primaryMeasurementId,
    canPrimaryMeasurementProcessed,
    cadenceMeasurementServiceId,
    cadenceMeasurementId,
    canCadenceMeasurementProcessed,
    heartRate,
  }) : super(
          fourCC: fourCC,
          vendorName: vendorName,
          modelName: modelName,
          fullName: fullName,
          namePrefix: namePrefix,
          nameStart: nameStart,
          manufacturer: manufacturer,
          model: model,
          primaryMeasurementServiceId: primaryMeasurementServiceId,
          primaryMeasurementId: primaryMeasurementId,
          canPrimaryMeasurementProcessed: canPrimaryMeasurementProcessed,
          cadenceMeasurementServiceId: cadenceMeasurementServiceId,
          cadenceMeasurementId: cadenceMeasurementId,
          canCadenceMeasurementProcessed: canCadenceMeasurementProcessed,
          heartRate: heartRate,
        ) {
    _cadenceData = ListQueue<CadenceData>();
    _featuresFlag = 0;
    _cadenceFlag = 0;
    _residueCalories = 0;
  }

  double _getSpeed(List<int> data) {
    return _speedMetric?.getMeasurementValue(data);
  }

  double _getCadence(List<int> data) {
    return _cadenceMetric?.getMeasurementValue(data);
  }

  double _getDistance(List<int> data) {
    return _distanceMetric?.getMeasurementValue(data);
  }

  double _getPower(List<int> data) {
    return _powerMetric?.getMeasurementValue(data);
  }

  double _getCalories(List<int> data) {
    return _caloriesMetric?.getMeasurementValue(data);
  }

  double _getTime(List<int> data) {
    return _timeMetric?.getMeasurementValue(data);
  }

  int _getRevolutions(List<int> data) {
    return _revolutions?.getMeasurementValue(data)?.toInt();
  }

  double _getRevolutionTime(List<int> data) {
    return _revolutionTime?.getMeasurementValue(data);
  }

  double _getHeartRate(List<int> data) {
    return data[heartRate].toDouble();
  }

  _processFlag(int flag) {
    // Schwinn IC4:
    // 68 01000100 avg speed, instant power
    //  2 00000010 heart rate
    // Two flag bytes
    int byteCounter = 2;
    // negated bit!
    final hasInstantSpeed = flag % 2 == 0;
    if (hasInstantSpeed) {
      // UInt16, km/h with 0.01 resolution
      _speedMetric = ShortMetricDescriptor(
          lsb: byteCounter, msb: byteCounter + 1, divider: 100);
      byteCounter += 2;
    }
    flag ~/= 2;
    // Has Average Speed?
    if (flag % 2 == 1) {
      // UInt16, km/h with 0.01 resolution
      if (!hasInstantSpeed) {
        _speedMetric = ShortMetricDescriptor(
            lsb: byteCounter, msb: byteCounter + 1, divider: 100);
      }
      byteCounter += 2;
    }
    flag ~/= 2;
    final hasInstantCadence = flag % 2 == 1;
    if (hasInstantCadence) {
      // UInt16, revolutions / minute with 0.5 resolution
      _cadenceMetric = ShortMetricDescriptor(
          lsb: byteCounter, msb: byteCounter + 1, divider: 2);
      byteCounter += 2;
    }
    flag ~/= 2;
    // Has Average Cadence?
    if (flag % 2 == 1) {
      // Fall back to the less instantaneous average metric
      // UInt16, revolutions / minute with 0.5 resolution
      if (!hasInstantCadence) {
        _cadenceMetric = ShortMetricDescriptor(
            lsb: byteCounter, msb: byteCounter + 1, divider: 2);
      }
      byteCounter += 2;
    }
    flag ~/= 2;
    // Has Total Distance?
    if (flag % 2 == 1) {
      // UInt24, meters
      _distanceMetric = ThreeByteMetricDescriptor(
          lsb: byteCounter, msb: byteCounter + 2, divider: 1);
      byteCounter += 3;
    }
    flag ~/= 2;
    // Has Resistance Level
    if (flag % 2 == 1) {
      // SInt16
      byteCounter += 2;
    }
    flag ~/= 2;
    final hasInstantPower = flag % 2 == 1;
    if (hasInstantPower) {
      // SInt16, Watts
      _powerMetric = ShortMetricDescriptor(
          lsb: byteCounter, msb: byteCounter + 1, divider: 1);
      byteCounter += 2;
    }
    flag ~/= 2;
    // Has Average Power?
    if (flag % 2 == 1) {
      // Fall back to the less instantaneous average metric
      // SInt16, Watts
      if (!hasInstantPower) {
        _powerMetric = ShortMetricDescriptor(
            lsb: byteCounter, msb: byteCounter + 1, divider: 1);
      }
      byteCounter += 2;
    }
    flag ~/= 2;
    // Has Expanded Energy
    if (flag % 2 == 1) {
      // Total Energy: UInt16
      _caloriesMetric = ShortMetricDescriptor(
          lsb: byteCounter, msb: byteCounter + 1, divider: 1);
      // Also skipping Energy / hour UInt16 and Energy / minute UInt8
      byteCounter += 5;
    }
    flag ~/= 2;
    // Has Heart Rate
    if (flag % 2 == 1) {
      // UInt8
      heartRate = byteCounter;
      byteCounter++;
    }
    flag ~/= 2;
    // Has Metabolic Equivalent
    if (flag % 2 == 1) {
      // UInt8
      byteCounter++;
    }
    flag ~/= 2;
    // Has Elapsed Time
    if (flag % 2 == 1) {
      _timeMetric = ShortMetricDescriptor(
          lsb: byteCounter, msb: byteCounter + 1, divider: 1);
      byteCounter += 2;
    }
    flag ~/= 2;
    // Has Remaining Time
    if (flag % 2 == 1) {
      byteCounter += 2;
    }
  }

  @override
  Record processPrimaryMeasurement(
    Activity activity,
    Duration idleDuration,
    Record lastRecord,
    List<int> data,
  ) {
    if (data != null && data.length > 2) {
      var flag = data[0] + 256 * data[1];
      if (flag != _featuresFlag) {
        _featuresFlag = flag;
        _processFlag(flag);
      }
    }

    double elapsed;
    Duration elapsedDuration;
    int elapsedMillis;
    if (data != null && _timeMetric != null) {
      elapsed = _getTime(data);
      elapsedMillis = (elapsed * 1000.0).toInt();
      elapsedDuration = Duration(seconds: lastRecord.elapsed);
    } else {
      elapsedMillis = DateTime.now()
          .subtract(idleDuration)
          .difference(activity.startDateTime)
          .inMilliseconds;
      elapsed = elapsedMillis / 1000.0;
      elapsedDuration = Duration(milliseconds: elapsedMillis);
    }

    double newDistance = 0;
    final dT = (elapsedMillis - lastRecord.elapsedMillis) / 1000.0;
    if (data != null && _distanceMetric != null) {
      newDistance = _getDistance(data);
    } else {
      double dD = 0;
      if (lastRecord.speed > 0) {
        if (dT > 0) {
          dD = lastRecord.speed * DeviceDescriptor.KMH2MS * dT;
        }
      }
      newDistance = lastRecord.distance + dD;
    }
    final timeStamp =
        activity.startDateTime.add(idleDuration).add(elapsedDuration);
    if (data != null) {
      var cadence = lastRecord.cadence;
      if (_cadenceMetric != null) {
        cadence = _getCadence(data).toInt();
      }
      double power = _getPower(data);
      double calories = 0;
      if (_caloriesMetric != null) {
        calories = _getCalories(data);
      } else {
        final deltaCalories = power * dT * DeviceDescriptor.J2KCAL;
        _residueCalories += deltaCalories;
        calories = lastRecord.calories + _residueCalories;
        if (calories.floor() > lastRecord.calories) {
          _residueCalories = calories - calories.floor();
        }
      }
      return Record(
        activityId: activity.id,
        timeStamp: timeStamp.millisecondsSinceEpoch,
        distance: newDistance,
        elapsed: elapsed.toInt(),
        calories: calories.floor(),
        power: power.toInt(),
        speed: _getSpeed(data),
        cadence: cadence,
        heartRate: _getHeartRate(data).toInt(),
        elapsedMillis: elapsedMillis,
      );
    } else {
      return Record(
        activityId: activity.id,
        timeStamp: timeStamp.millisecondsSinceEpoch,
        distance: newDistance,
        elapsed: lastRecord.elapsed,
        calories: lastRecord.calories,
        power: lastRecord.power,
        speed: lastRecord.speed,
        cadence: lastRecord.cadence,
        heartRate: lastRecord.heartRate,
        elapsedMillis: elapsedMillis,
      );
    }
  }

  @override
  int processCadenceMeasurement(List<int> data) {
    if (!canCadenceMeasurementProcessed(data)) return 0;

    var flag = data[0];
    // 16 bit revolution and 16 bit time
    if (_cadenceFlag != flag) {
      var lengthOffset = 1; // The flag itself
      // Has wheel revolution? (first bit)
      if (flag % 2 == 1) {
        // Skip it, we are not interested in wheel revolution
        lengthOffset += 6; // 32 bit revolution and 16 bit time
      }
      flag ~/= 2;
      // Has crank revolution? (second bit)
      if (flag % 2 == 0) {
        return 0;
      }
      _revolutions = ShortMetricDescriptor(
          lsb: lengthOffset, msb: lengthOffset + 1, divider: 1);
      _revolutionTime = ShortMetricDescriptor(
          lsb: lengthOffset + 2, msb: lengthOffset + 3, divider: 1024);
      _cadenceFlag = flag;
    }

    // See https://web.archive.org/web/20170816162607/https://www.bluetooth.com/specifications/gatt/viewer?attributeXmlFile=org.bluetooth.characteristic.csc_measurement.xml
    _cadenceData.add(CadenceData(
      seconds: _getRevolutionTime(data),
      revolutions: _getRevolutions(data),
    ));

    var firstData = _cadenceData.first;
    if (_cadenceData.length == 1) {
      return firstData.revolutions ~/ firstData.seconds;
    }

    var lastData = _cadenceData.last;
    var revDiff = lastData.revolutions - firstData.revolutions;
    // Check overflow
    if (revDiff < 0) {
      revDiff += DeviceDescriptor.MAX_UINT16;
    }
    var secondsDiff = lastData.seconds - firstData.seconds;
    // Check overflow
    if (secondsDiff < 0) {
      secondsDiff += EVENT_TIME_OVERFLOW;
    }

    while (secondsDiff > REVOLUTION_SLIDING_WINDOW && _cadenceData.length > 2) {
      _cadenceData.removeFirst();
      secondsDiff = _cadenceData.last.seconds - _cadenceData.first.seconds;
      // Check overflow
      if (secondsDiff < 0) {
        secondsDiff += EVENT_TIME_OVERFLOW;
      }
    }

    return revDiff ~/ secondsDiff;
  }
}
