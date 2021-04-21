import 'package:flutter_test/flutter_test.dart';
import 'package:track_my_indoor_exercise/export/fit/fit_crc.dart';

class TestPair {
  final List<int> data;
  final int crc;

  TestPair({this.data, this.crc}) {
    data.addAll([0x2E, 0x46, 0x49, 0x54]);
  }
}

void main() {
  group('FIT CRC low level test', () {
    [
      TestPair(data: [0x0E, 0x20, 0x23, 0x08, 0xF1, 0x56, 0x00, 0x00], crc: 0xADF2),
      TestPair(data: [0x0E, 0x10, 0xE9, 0x05, 0xB1, 0x00, 0x00, 0x00], crc: 0x1442),
      TestPair(data: [0x0E, 0x10, 0x5E, 0x06, 0x17, 0x08, 0x00, 0x00], crc: 0xBBE3),
      TestPair(data: [0x0E, 0x10, 0xE9, 0x05, 0xC5, 0x00, 0x00, 0x00], crc: 0xC344),
      TestPair(data: [0x0E, 0x20, 0x68, 0x06, 0xA2, 0x00, 0x00, 0x00], crc: 0xD0BE),
      TestPair(data: [0x0E, 0x10, 0x5E, 0x06, 0x86, 0x00, 0x00, 0x00], crc: 0xDBA2),
      TestPair(data: [0x0E, 0x10, 0xE9, 0x05, 0x9F, 0x00, 0x00, 0x00], crc: 0x80C1),
      TestPair(data: [0x0E, 0x20, 0x12, 0x08, 0x98, 0xAB, 0x03, 0x00], crc: 0x2949),
      TestPair(data: [0x0E, 0x20, 0x12, 0x08, 0x33, 0x2D, 0x01, 0x00], crc: 0xC8E4),
      TestPair(data: [0x0E, 0x20, 0x12, 0x08, 0xAC, 0x4D, 0x01, 0x00], crc: 0xE2CD),
      TestPair(data: [0x0E, 0x20, 0x12, 0x08, 0x3E, 0x5E, 0x00, 0x00], crc: 0x4766),
      TestPair(data: [0x0E, 0x20, 0x12, 0x08, 0x33, 0x2D, 0x01, 0x00], crc: 0xC8E4),
    ].forEach((testPair) {
      final sum = testPair.data.fold(0.0, (a, b) => a + b);
      test("$sum -> ${testPair.crc}", () async {
        expect(crcData(testPair.data), testPair.crc);
      });
    });
  });
}
