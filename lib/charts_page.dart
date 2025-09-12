import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'database_service.dart'; // Senin DatabaseService dosyan

class ChartsPage extends StatefulWidget {
  final String currentMonth; // <--- Artık parametre var

  const ChartsPage({
    super.key,
    required this.currentMonth,
  }); // <--- required parametre

  @override
  State<ChartsPage> createState() => _ChartsPageState();
}

class _ChartsPageState extends State<ChartsPage> {
  List<DailyCarData> carData = [];
  List<DailyCarData> incomeData = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadMonthlyData();
  }

  Future<void> loadMonthlyData() async {
    final db = DatabaseService();
    final monthNumber = _monthNameToNumber(widget.currentMonth);

    List<DailyCarData> tempCarData = [];
    List<DailyCarData> tempIncomeData = [];

    for (int day = 1; day <= 31; day++) {
      final appointments = await db.getAppointmentsByMonthAndDay(
        monthNumber,
        day,
      );
      int totalIncome = 0;

      for (var appt in appointments) {
        totalIncome += int.tryParse(appt['ucret'] ?? '0') ?? 0;
      }

      tempCarData.add(DailyCarData(day: day, carCount: appointments.length));
      tempIncomeData.add(DailyCarData(day: day, carCount: totalIncome));
    }

    setState(() {
      carData = tempCarData;
      incomeData = tempIncomeData;
      isLoading = false;
    });
  }

  int _monthNameToNumber(String monthName) {
    const months = [
      "Ocak",
      "Şubat",
      "Mart",
      "Nisan",
      "Mayıs",
      "Haziran",
      "Temmuz",
      "Ağustos",
      "Eylül",
      "Ekim",
      "Kasım",
      "Aralık",
    ];
    return months.indexOf(monthName) + 1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${widget.currentMonth} Ayı Grafikleri")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "Günlük Araç Sayısı",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(
                    height: 250,
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
                    "Günlük Gelir",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(
                    height: 250,
                    child: SfCartesianChart(
                      primaryXAxis: NumericAxis(
                        title: AxisTitle(text: 'Gün'),
                        interval: 5,
                        minimum: 0,
                      ),
                      primaryYAxis: NumericAxis(
                        title: AxisTitle(text: 'Gelir (TL)'),
                      ),
                      tooltipBehavior: TooltipBehavior(enable: true),
                      series: <ColumnSeries<DailyCarData, int>>[
                        ColumnSeries<DailyCarData, int>(
                          dataSource: incomeData,
                          xValueMapper: (d, _) => d.day,
                          yValueMapper: (d, _) => d.carCount,
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

class DailyCarData {
  final int day;
  final int carCount;
  DailyCarData({required this.day, required this.carCount});
}
