import 'package:car_wash/app_ready_package.dart';
import 'package:car_wash/main.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'charts_page.dart';
import 'database_service.dart';

class MonthCard extends StatelessWidget {
  final String monthName;
  final VoidCallback onTap;

  const MonthCard({super.key, required this.monthName, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(
          monthName,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}

class ReportChartsPage extends StatefulWidget {
  const ReportChartsPage({super.key});

  @override
  State<ReportChartsPage> createState() => _ReportChartsPageState();
}

class _ReportChartsPageState extends State<ReportChartsPage> {
  List<Map<String, dynamic>> monthlyData = [];
  String selectedSort = "default";

  final monthNames = const {
    "01": "Ocak",
    "02": "Şubat",
    "03": "Mart",
    "04": "Nisan",
    "05": "Mayıs",
    "06": "Haziran",
    "07": "Temmuz",
    "08": "Ağustos",
    "09": "Eylül",
    "10": "Ekim",
    "11": "Kasım",
    "12": "Aralık",
  };

  @override
  void initState() {
    super.initState();
    _loadMonthlyData();
  }

  Future<void> _loadMonthlyData() async {
    final db = DatabaseService();
    final dbData = await db.getMonthlySummary();

    // Başlangıç: 12 ayı default 0 değerlerle doldur
    final temp = monthNames.entries.map((e) {
      return {"month": e.key, "totalAmount": 0, "vehicleCount": 0};
    }).toList();

    // Gelen verilerle güncelle
    for (var item in dbData) {
      final index = temp.indexWhere((m) => m["month"] == item["month"]);
      if (index != -1) {
        temp[index]["totalAmount"] = item["totalAmount"] ?? 0;
        temp[index]["vehicleCount"] = item["vehicleCount"] ?? 0;
      }
    }

    setState(() {
      monthlyData = temp;
    });
  }

  void _sortData(String sortType) {
    setState(() {
      selectedSort = sortType;
      if (sortType == "amount_desc") {
        monthlyData.sort(
          (a, b) => (b['totalAmount'] ?? 0).compareTo(a['totalAmount'] ?? 0),
        );
      } else if (sortType == "amount_asc") {
        monthlyData.sort(
          (a, b) => (a['totalAmount'] ?? 0).compareTo(b['totalAmount'] ?? 0),
        );
      } else if (sortType == "vehicle_desc") {
        monthlyData.sort(
          (a, b) => (b['vehicleCount'] ?? 0).compareTo(a['vehicleCount'] ?? 0),
        );
      } else if (sortType == "vehicle_asc") {
        monthlyData.sort(
          (a, b) => (a['vehicleCount'] ?? 0).compareTo(b['vehicleCount'] ?? 0),
        );
      } else {
        // Varsayılan: Ocak → Aralık
        monthlyData.sort(
          (a, b) => int.parse(a['month']).compareTo(int.parse(b['month'])),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: darkBlue,
        actions: [SortMenu(onSelected: _sortData)],
        title: Text("Aylık Grafikler", style: AppTextStyles.title),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            // Koyu mavinin tonları
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

        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
          child: ListView(
            children: monthlyData.map((month) {
              final name = monthNames[month['month']] ?? month['month'];
              return MonthCard(
                monthName:
                    "$name (Ücret: ${month['totalAmount'] ?? 0}, Araç: ${month['vehicleCount'] ?? 0})",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChartsPage(currentMonth: name),
                    ),
                  );
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class SortMenu extends StatelessWidget {
  final Function(String) onSelected;

  const SortMenu({super.key, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.sort, color: Colors.white, size: 30),
      onSelected: onSelected,
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem(
          value: 'default',
          child: Text('Varsayılan (Aylara göre)'),
        ),
        const PopupMenuItem(
          value: 'amount_desc',
          child: Text('Miktara göre en çok'),
        ),
        const PopupMenuItem(
          value: 'amount_asc',
          child: Text('Miktara göre en az'),
        ),
        const PopupMenuItem(
          value: 'vehicle_desc',
          child: Text('Araç sayısına göre en çok'),
        ),
        const PopupMenuItem(
          value: 'vehicle_asc',
          child: Text('Araç sayısına göre en az'),
        ),
      ],
    );
  }
}
