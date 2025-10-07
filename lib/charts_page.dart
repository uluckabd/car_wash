import 'package:car_wash/app_ready_package.dart';
import 'package:car_wash/main.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'database_service.dart';

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
        centerTitle: true,
        backgroundColor: darkBlue,
        title: Text(
          "${widget.currentMonth} Ayı Grafikleri",
          style: AppTextStyles.title,
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  // Koyu mavinin tonlarız
                  colors: [
                    Color(0xFF1B2A38), // Üst kısım (Daha Koyu Lacivert)
                    Color.fromARGB(
                      255,
                      120,
                      120,
                      120,
                    ), // Alt kısım (Biraz daha açık Lacivert/Mavi)
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),

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
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: SizedBox(
            height: 250,
            child: SfCartesianChart(
              primaryXAxis: NumericAxis(
                labelStyle: const TextStyle(color: Colors.white),
                axisLine: const AxisLine(color: Colors.white70, width: 0.5),
                majorGridLines: const MajorGridLines(color: Colors.white12),
                title: AxisTitle(
                  text: 'Gün',
                  textStyle: TextStyle(color: Colors.white),
                ),
                interval: 4,
                minimum: 0,
              ),
              primaryYAxis: NumericAxis(
                labelStyle: const TextStyle(color: Colors.white),

                majorGridLines: const MajorGridLines(color: Colors.blueGrey),
                title: AxisTitle(
                  text: 'Araç Sayısı',
                  textStyle: TextStyle(color: Colors.white),
                ),
              ),
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
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${d.day} ${d.dayName}\nAraç Sayısı: ${d.carCount}',
                          style: const TextStyle(
                            color: darkBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
              ),
              series: <ColumnSeries<DailyCarData, int>>[
                ColumnSeries<DailyCarData, int>(
                  dataSource: carData,
                  xValueMapper: (d, _) => d.day,
                  yValueMapper: (d, _) => d.carCount,
                  color: Color(0xFFFFA000),
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
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: SizedBox(
            height: 250,
            child: SfCartesianChart(
              primaryXAxis: NumericAxis(
                labelStyle: const TextStyle(color: Colors.white),
                axisLine: const AxisLine(color: Colors.white70, width: 0.5),
                majorGridLines: const MajorGridLines(color: Colors.blueGrey),
                title: AxisTitle(
                  text: 'Gün',
                  textStyle: TextStyle(color: Colors.white),
                ),
                interval: 4,
                minimum: 0,
              ),
              primaryYAxis: NumericAxis(
                labelStyle: const TextStyle(color: Colors.white),

                majorGridLines: const MajorGridLines(color: Colors.white12),
                title: AxisTitle(
                  text: 'Gelir (TL)',
                  textStyle: TextStyle(color: Colors.white),
                ),
              ),
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
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${d.day} ${d.dayName}\nGelir: ${d.carCount} TL',
                          style: const TextStyle(
                            color: darkBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
              ),
              series: <ColumnSeries<DailyCarData, int>>[
                ColumnSeries<DailyCarData, int>(
                  dataSource: incomeData,
                  xValueMapper: (d, _) => d.day,
                  yValueMapper: (d, _) => d.carCount,
                  color: Color(0xFF00BCD4),
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
