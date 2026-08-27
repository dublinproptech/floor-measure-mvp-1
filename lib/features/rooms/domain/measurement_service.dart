class MeasurementService {
  const MeasurementService();

  double area(double length, double width) => length * width;

  double orderArea(double area, double wastagePct) => area + area * (wastagePct / 100);

  int packs(double orderArea, double packSize) => packSize <= 0 ? 0 : (orderArea / packSize).ceil();

}

class ProjectTotals {
  final double totalArea;
  final double totalOrderArea;
  const ProjectTotals(this.totalArea, this.totalOrderArea);
}