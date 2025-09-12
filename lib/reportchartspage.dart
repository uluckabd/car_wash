import 'package:flutter/material.dart';
import 'charts_page.dart';

// Reusable Ay Kartı Widget
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

// Report Charts Page
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
      appBar: AppBar(title: const Text("Aylık Grafikler")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: months
                .map(
                  (month) => MonthCard(
                    monthName: month,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChartsPage(currentMonth: month),
                        ),
                      );
                    },
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}
