import 'package:car_wash/app_ready_package.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'database_service.dart';

const Color primaryColor = Color.fromRGBO(255, 1, 1, 1);
const Color secondaryColor = Color(0xFF90CAF9);

class ChartsPage extends StatefulWidget {
  final String currentMonth;

  const ChartsPage({super.key, required this.currentMonth});

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

      // Gün adı hesaplama
      final now = DateTime.now();
      final year = now.year;
      final date = DateTime(year, monthNumber, day);
      final gunAdi = [
        'Pazartesi',
        'Salı',
        'Çarşamba',
        'Perşembe',
        'Cuma',
        'Cumartesi',
        'Pazar',
      ][date.weekday - 1];

      tempCarData.add(
        DailyCarData(day: day, carCount: appointments.length, dayName: gunAdi),
      );
      tempIncomeData.add(
        DailyCarData(day: day, carCount: totalIncome, dayName: gunAdi),
      );
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
      appBar: AppBar(
        title: Text(
          "${widget.currentMonth} Ayı Grafikleri",
          style: AppTextStyles.title,
        ),
        flexibleSpace: Appcolor(),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GunAracGrafik(carData: carData),
                  GunGelirGrafik(incomeData: incomeData),
                ],
              ),
            ),
    );
  }
}

class GunAracGrafik extends StatelessWidget {
  const GunAracGrafik({super.key, required this.carData});

  final List<DailyCarData> carData;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 40, bottom: 25),
          child: const Text(
            textAlign: TextAlign.center,
            "Günlük Araç Sayısı grafiği",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: SizedBox(
            height: 250,
            child: SfCartesianChart(
              primaryXAxis: NumericAxis(
                title: AxisTitle(text: 'Gün'),
                interval: 4,
                minimum: 0,
              ),
              primaryYAxis: NumericAxis(title: AxisTitle(text: 'Araç Sayısı')),
              tooltipBehavior: TooltipBehavior(
                enable: true,
                builder:
                    (
                      dynamic data,
                      dynamic point,
                      dynamic series,
                      int pointIndex,
                      int seriesIndex,
                    ) {
                      final DailyCarData d = data;
                      return Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${d.day} ${d.dayName}\nAraç Sayısı: ${d.carCount}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    },
              ),
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
        ),
      ],
    );
  }
}

class GunGelirGrafik extends StatelessWidget {
  const GunGelirGrafik({super.key, required this.incomeData});

  final List<DailyCarData> incomeData;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 40, bottom: 25),
          child: const Text(
            textAlign: TextAlign.center,
            "Günlük Gelir Miktarı Grafiği",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: SizedBox(
            height: 250,
            child: SfCartesianChart(
              primaryXAxis: NumericAxis(
                title: AxisTitle(text: 'Gün'),
                interval: 4,
                minimum: 0,
              ),
              primaryYAxis: NumericAxis(title: AxisTitle(text: 'Gelir (TL)')),
              tooltipBehavior: TooltipBehavior(
                enable: true,
                builder:
                    (
                      dynamic data,
                      dynamic point,
                      dynamic series,
                      int pointIndex,
                      int seriesIndex,
                    ) {
                      final DailyCarData d = data;
                      return Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${d.day} ${d.dayName}\nGelir: ${d.carCount} TL',
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    },
              ),
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
        ),
      ],
    );
  }
}

class DailyCarData {
  final int day;
  final int carCount;
  final String dayName;
  DailyCarData({
    required this.day,
    required this.carCount,
    required this.dayName,
  });
}
