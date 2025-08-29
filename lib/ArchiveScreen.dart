import 'package:flutter/material.dart';

class ArchiveScreen extends StatelessWidget {
  final List<Map<String, dynamic>> randevular;

  const ArchiveScreen({super.key, required this.randevular});

  String getMonthName(int month) {
    const aylar = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ];
    return aylar[month - 1];
  }

  Map<int, List<Map<String, dynamic>>> groupByMonth() {
    Map<int, List<Map<String, dynamic>>> ayGruplari = {};
    for (var r in randevular) {
      if (r['tarih'] != null) {
        final tarihParcala = r['tarih'].split('/');
        final month = int.parse(tarihParcala[1]);
        if (!ayGruplari.containsKey(month)) {
          ayGruplari[month] = [];
        }
        ayGruplari[month]!.add(r);
      }
    }
    return ayGruplari;
  }

  Map<String, List<Map<String, dynamic>>> groupByDay(
    List<Map<String, dynamic>> ayRandevulari,
  ) {
    Map<String, List<Map<String, dynamic>>> gunGruplari = {};
    for (var r in ayRandevulari) {
      final gun = r['tarih'];
      if (!gunGruplari.containsKey(gun)) {
        gunGruplari[gun] = [];
      }
      gunGruplari[gun]!.add(r);
    }
    return gunGruplari;
  }

  double calculateMonthTotal(List<Map<String, dynamic>> ayRandevulari) {
    double total = 0;
    for (var r in ayRandevulari) {
      if (r['ucret'] != null && r['ucret'].toString().isNotEmpty) {
        total += double.tryParse(r['ucret'].toString()) ?? 0;
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final ayGruplari = groupByMonth();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Arşiv',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 25,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFF0101), Color(0xFF90CAF9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: ListView(
        children: List.generate(12, (index) {
          final monthNumber = index + 1;
          final monthName = getMonthName(monthNumber);
          final ayRandevulari = ayGruplari[monthNumber] ?? [];
          final toplamUcret = calculateMonthTotal(ayRandevulari);

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
            child: ExpansionTile(
              title: Text(
                '$monthName (${ayRandevulari.length} randevu - Toplam: ${toplamUcret.toStringAsFixed(2)}₺)',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              children: ayRandevulari.isEmpty
                  ? [const ListTile(title: Text('Bu ayda randevu yok'))]
                  : groupByDay(ayRandevulari).entries
                        .map(
                          (gunEntry) => ExpansionTile(
                            title: Text(
                              '${gunEntry.key} (${gunEntry.value.length} randevu)',
                              style: const TextStyle(fontSize: 16),
                            ),
                            children: gunEntry.value.map((r) {
                              return ListTile(
                                leading: const Icon(Icons.access_time),
                                title: Text(
                                  '${r['baslangic']} - ${r['bitis']}',
                                ),
                                subtitle: Text(
                                  '${r['isimSoyisim']} - ${r['telefon']} - ${r['arac']}',
                                ),
                                trailing: r['ucret'] != null
                                    ? Text('${r['ucret']}₺')
                                    : null,
                              );
                            }).toList(),
                          ),
                        )
                        .toList(),
            ),
          );
        }),
      ),
    );
  }
}
