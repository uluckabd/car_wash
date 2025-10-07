import 'package:flutter/material.dart';
import 'database_service.dart';

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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            // Koyu mavinin tonları
            colors: [
              Color(0xFF1B2A38), // Üst kısım (Daha Koyu Lacivert)
              Color(0xFF1F3249), // Alt kısım (Biraz daha açık Lacivert/Mavi)
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),

        child: ListView(
          children: List.generate(12, (index) {
            final monthNumber = index + 1;
            final monthName = getMonthName(monthNumber);
            final ayRandevulari = ayGruplari[monthNumber] ?? [];
            final toplamUcret = calculateMonthTotal(ayRandevulari);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Card(
                color: Colors.white,
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
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ---------------------
// Search Delegate Sınıfı
// ---------------------
class AppointmentSearch extends SearchDelegate<Map<String, dynamic>> {
  final List<Map<String, dynamic>> randevular;

  AppointmentSearch(this.randevular);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, {});
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final lowerCaseQuery = query.toLowerCase();
    final results = randevular
        .where(
          (r) =>
              (r['arac']?.toString().toLowerCase().contains(lowerCaseQuery) ??
                  false) ||
              (r['isimSoyisim']?.toString().toLowerCase().contains(
                    lowerCaseQuery,
                  ) ??
                  false),
        )
        .toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final r = results[index];
        return ListTile(
          title: Text(r['arac'] ?? 'Araç Bilgisi Yok'),
          subtitle: Text(
            "${r['isimSoyisim'] ?? 'İsim Yok'} - ${r['tarih'] ?? 'Tarih Yok'}",
          ),
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final lowerCaseQuery = query.toLowerCase();
    final suggestions = randevular
        .where(
          (r) =>
              (r['arac']?.toString().toLowerCase().contains(lowerCaseQuery) ??
                  false) ||
              (r['isimSoyisim']?.toString().toLowerCase().contains(
                    lowerCaseQuery,
                  ) ??
                  false),
        )
        .toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final r = suggestions[index];
        return ListTile(
          title: Text(r['arac'] ?? 'Araç Bilgisi Yok'),
          subtitle: Text(
            "${r['isimSoyisim'] ?? 'İsim Yok'} - ${r['tarih'] ?? 'Tarih Yok'}",
          ),
          onTap: () {
            query = r['isimSoyisim'] ?? '';
            showResults(context);
          },
        );
      },
    );
  }
}
