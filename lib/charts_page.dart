import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

void main() {
  runApp(const MaterialApp(home: ChartsPage()));
}

class ChartsPage extends StatelessWidget {
  const ChartsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Örnek veri: bir ayın her günü kaç araç geldi
    final List<DailyCarData> carData = List.generate(
      30,
      (index) =>
          DailyCarData(day: index + 1, carCount: (10 + (index * 2) % 20)),
    );

    // Örnek veri: bir ayın her günü ne kadar gelir elde edildi
    final List<DailyRevenueData> revenueData = List.generate(
      30,
      (index) => DailyRevenueData(
        day: index + 1,
        revenue: (carData[index].carCount * 50),
      ), // örn: araç başı 50₺
    );

    return Scaffold(
      appBar: AppBar(title: const Text("Aylık Araç ve Gelir Grafikleri")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "Günlük Araç Sayısı",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: SfCartesianChart(
                primaryXAxis: NumericAxis(
                  title: AxisTitle(text: 'Gün'),
                  interval: 5,
                  minimum: 0,
                ),
                primaryYAxis: NumericAxis(
                  title: AxisTitle(text: 'Araç Sayısı'),
                ),
                tooltipBehavior: TooltipBehavior(enable: true),
                series: <ColumnSeries<DailyCarData, int>>[
                  ColumnSeries<DailyCarData, int>(
                    dataSource: carData,
                    xValueMapper: (d, _) => d.day,
                    yValueMapper: (d, _) => d.carCount,
                    color: Colors.green,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              "Günlük Gelir (₺)",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: SfCartesianChart(
                primaryXAxis: NumericAxis(
                  title: AxisTitle(text: 'Gün'),
                  interval: 5,
                  minimum: 0,
                ),
                primaryYAxis: NumericAxis(title: AxisTitle(text: 'Gelir (₺)')),
                tooltipBehavior: TooltipBehavior(enable: true),
                series: <ColumnSeries<DailyRevenueData, int>>[
                  ColumnSeries<DailyRevenueData, int>(
                    dataSource: revenueData,
                    xValueMapper: (d, _) => d.day,
                    yValueMapper: (d, _) => d.revenue,
                    color: Colors.blue,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Araç sayısı veri modeli
class DailyCarData {
  final int day;
  final int carCount;
  DailyCarData({required this.day, required this.carCount});
}

// Gelir veri modeli
class DailyRevenueData {
  final int day;
  final double revenue;
  DailyRevenueData({required this.day, required this.revenue});
}
