import '../../utils/constants.dart';
import 'metric_descriptor.dart';

class ShortMetricDescriptor extends MetricDescriptor {
  ShortMetricDescriptor({
    required lsb,
    required msb,
    divider = 1.0,
    optional = false,
  }) : super(lsb: lsb, msb: msb, divider: divider, optional: optional);

  @override
  double? getMeasurementValue(List<int> data) {
    final value = data[lsb] + maxUint8 * data[msb];
    if (optional && value == maxUint16 - 1) {
      return null;
    }

    return value / divider;
  }
}
