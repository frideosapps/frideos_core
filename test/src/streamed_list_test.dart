import 'dart:async';

import 'package:test/test.dart';

import 'package:frideos_core/frideos_core.dart';

void main() {
  group('StreamedList', () {
    test('addElement', () async {
      final streamedList = StreamedList<int>();

      streamedList.value = [1, 3, 5];
      streamedList..addElement(2)..addElement(4);

      await expectLater(
        streamedList.outStream,
        emits([1, 3, 5, 2, 4]),
      );
    });

    test('addElement with initialData', () async {
      final streamedList = StreamedList<int>(initialData: [33, 66, 99]);

      await expectLater(
        streamedList.outStream,
        emits([33, 66, 99]),
      );

      streamedList..addElement(2)..addElement(4);

      await expectLater(
        streamedList.outStream,
        emits([33, 66, 99, 2, 4]),
      );
    });

    test('addAll', () async {
      final streamedList = StreamedList<int>();
      streamedList.value = List<int>();

      streamedList.addAll([1, 2, 3, 4, 5]);

      await expectLater(
        streamedList.outStream,
        emits([1, 2, 3, 4, 5]),
      );
    });

    test('Clear, removeAt, length', () {
      final streamedList = StreamedList<int>();
      streamedList.value = List<int>();

      streamedList.addElement(99);

      expect(streamedList.value.first, 99);

      expect(streamedList.value.remove(99), true);
      expect(streamedList.value.remove(99), false);

      streamedList
        ..addElement(99)
        ..removeAt(0);
      expect(streamedList.value.length, 0);

      streamedList
        ..addElement(99)
        ..clear();
      expect(streamedList.length, 0);
      expect(streamedList.value.length, 0);
    });
  });
}
