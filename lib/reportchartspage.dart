import 'package:flutter/material.dart';
import 'charts_page.dart';

const Color primaryColor = Color.fromRGBO(255, 1, 1, 1);
const Color secondaryColor = Color(0xFF90CAF9);

class MonthCard extends StatelessWidget {
  final String monthName;
  final VoidCallback onTap;

  const MonthCard({super.key, required this.monthName, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
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

class ReportChartsPage extends StatelessWidget {
  const ReportChartsPage({super.key});

  @override
  Widget build(BuildContext context) {
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

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Aylık Grafikler",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 25,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, secondaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: months.map((month) {
            return MonthCard(
              monthName: month,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChartsPage(currentMonth: month),
                  ),
                );
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}
