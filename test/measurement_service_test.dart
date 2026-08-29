import 'package:flutter_test/flutter_test.dart';
import 'package:floor_measure/features/rooms/domain/measurement_service.dart';

void main() {
  const svc = MeasurementService();

  test('area is length x width', () => expect(svc.area(5, 4), 20));

  test('order area adds wastage', () => expect(svc.orderArea(20, 10), 22));

  test('packs always round up', () {
    expect(svc.packs(22, 2.5), 9);    // 8.8 -> 9
    expect(svc.packs(27.5, 2.5), 11); // exact -> 11
    expect(svc.packs(27.6, 2.5), 12); // 11.04 -> 12, never 11
  });

  test('zero pack size is safe', () => expect(svc.packs(20, 0), 0));
}