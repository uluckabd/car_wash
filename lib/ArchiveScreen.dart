import 'package:car_wash/app_ready_package.dart';
import 'package:car_wash/main.dart';
import 'package:flutter/material.dart';
// import 'package:path/path.dart'; // Bu import kullanılmıyor, kaldırılabilir
import 'charts_page.dart'; // Bu import kullanılmıyor, kaldırılabilir
import 'database_service.dart';
import 'reportchartspage.dart'; // MonthCard renklerine erişim için gerekebilir

// Gerekli renk sabitlerini MonthCard sınıfından alıyoruz.
// Eğer ReportChartsPage dosyasında MonthCard varsa, import edildiyse bu tanımlar gerekmeyebilir,
// ancak bağımsız çalışması için buraya kopyalanması en güvenli yoldur.
class MonthCard {
  // Turkuaz vurgu rengi (Çerçeve)
  static const Color accentColor = Color(0xFF00BCD4); // Turkuaz/Cam Göbeği
  // Kartın içindeki şeffaf arka plan rengi (İç Dolgu)
  static const Color cardInternalColor = Color.fromRGBO(
    255,
    105,
    97,
    0.2,
  ); // Şeffaf Kırmızı/Somon
}

// *** Örnek Detay Sayfası (Animasyonla açılacak) ***
// Bu sayfayı projenizde oluşturmanız veya randevu detayını gösterecek mevcut bir sayfanızla değiştirmeniz gerekebilir.
class AppointmentDetailPage extends StatelessWidget {
  final Map<String, dynamic> appointmentData;
  const AppointmentDetailPage({super.key, required this.appointmentData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${appointmentData['isimSoyisim']} Detayları'),
        backgroundColor: const Color(0xFF1B2A38),
        foregroundColor: Colors.white,
      ),
      body: Container(
        padding: const EdgeInsets.all(20),
        color: const Color(0xFF1F3249),
        child: ListView(
          children: [
            // Örnek detaylar
            _buildDetailTile('Müşteri Adı', appointmentData['isimSoyisim']),
            _buildDetailTile('Araç', appointmentData['arac']),
            _buildDetailTile('Tarih', appointmentData['tarih']),
            _buildDetailTile(
              'Saat',
              '${appointmentData['baslangic']} - ${appointmentData['bitis']}',
            ),
            _buildDetailTile(
              'Ücret',
              '${appointmentData['ucret']}₺',
              isAccent: true,
            ),
            // Diğer detaylar buraya eklenebilir
          ],
        ),
      ),
    );
  }

  Widget _buildDetailTile(
    String title,
    dynamic value, {
    bool isAccent = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            value?.toString() ?? 'Bilinmiyor',
            style: TextStyle(
              color: isAccent ? MonthCard.accentColor : Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(color: Colors.white10),
        ],
      ),
    );
  }
}
// *************************************************

class ArchiveScreen extends StatelessWidget {
  final List<Map<String, dynamic>> randevular;

  const ArchiveScreen({super.key, required this.randevular});

  // ... (getMonthName, groupByMonth, groupByDay, calculateMonthTotal metotları aynı kalır)
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
        // Varsayalım tarih formatı DD/MM/YYYY şeklindedir
        final month = int.tryParse(tarihParcala[1]) ?? 0;
        if (month >= 1 && month <= 12) {
          if (!ayGruplari.containsKey(month)) {
            ayGruplari[month] = [];
          }
          ayGruplari[month]!.add(r);
        }
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
      if (gun != null) {
        if (!gunGruplari.containsKey(gun)) {
          gunGruplari[gun] = [];
        }
        gunGruplari[gun]!.add(r);
      }
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
  // ... (Diğer metotlar aynı kalır)

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
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          children: List.generate(12, (index) {
            final monthNumber = index + 1;
            final monthName = getMonthName(monthNumber);
            final ayRandevulari = ayGruplari[monthNumber] ?? [];
            final toplamUcret = calculateMonthTotal(ayRandevulari);

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              // Card yerine Container ile özel stil uyguluyoruz
              child: Container(
                decoration: BoxDecoration(
                  color: MonthCard.cardInternalColor, // Şeffaf Kırmızı/Somon
                  borderRadius: BorderRadius.circular(12),
                  // Işın Efekti (Gölge): Turkuaz
                  boxShadow: [
                    BoxShadow(
                      color: MonthCard.accentColor.withOpacity(0.4),
                      blurRadius: 6.0,
                      spreadRadius: 1.0,
                    ),
                  ],
                  // Kenarlık (Bordür) Rengi: Turkuaz
                  border: Border.all(color: MonthCard.accentColor, width: 1.5),
                ),
                child: Theme(
                  // ExpansionTile içindeki çizgiyi kaldırır
                  data: Theme.of(
                    context,
                  ).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    title: Text(
                      '$monthName (${ayRandevulari.length} randevu - Toplam: ${toplamUcret.toStringAsFixed(2)}₺)',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white, // Beyaz Metin
                      ),
                    ),
                    iconColor: MonthCard.accentColor,
                    collapsedIconColor: Colors.white70,

                    children: ayRandevulari.isEmpty
                        ? [
                            const ListTile(
                              title: Text(
                                'Bu ayda randevu yok',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ),
                          ]
                        : groupByDay(ayRandevulari).entries
                              .map(
                                (gunEntry) => Padding(
                                  padding: const EdgeInsets.only(left: 16.0),
                                  child: ExpansionTile(
                                    title: Text(
                                      '${gunEntry.key} (${gunEntry.value.length} randevu)',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                    iconColor: MonthCard.accentColor,
                                    collapsedIconColor: Colors.white70,

                                    children: gunEntry.value.map((r) {
                                      return ListTile(
                                        // === BURASI GÜNCELLENDİ: Randevu Detayına Tıklama ===
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            PageRouteBuilder(
                                              pageBuilder:
                                                  (
                                                    context,
                                                    animation,
                                                    secondaryAnimation,
                                                  ) => AppointmentDetailPage(
                                                    appointmentData: r,
                                                  ), // Yeni detay sayfası
                                              // Sağdan Sola Kayma Animasyonu
                                              transitionsBuilder:
                                                  (
                                                    context,
                                                    animation,
                                                    secondaryAnimation,
                                                    child,
                                                  ) {
                                                    const begin = Offset(
                                                      1.0,
                                                      0.0,
                                                    ); // Sağdan başla
                                                    const end = Offset
                                                        .zero; // Ortaya gel
                                                    const curve = Curves
                                                        .easeOut; // Yumuşak geçiş eğrisi

                                                    var tween =
                                                        Tween(
                                                          begin: begin,
                                                          end: end,
                                                        ).chain(
                                                          CurveTween(
                                                            curve: curve,
                                                          ),
                                                        );

                                                    return SlideTransition(
                                                      position: animation.drive(
                                                        tween,
                                                      ),
                                                      child: child,
                                                    );
                                                  },
                                              transitionDuration:
                                                  const Duration(
                                                    milliseconds: 400,
                                                  ),
                                            ),
                                          );
                                        },
                                        // ====================================================

                                        // İç listeler şeffaf kalır
                                        leading: const Icon(
                                          Icons.access_time,
                                          color: MonthCard.accentColor,
                                        ),
                                        title: Text(
                                          '${r['baslangic']} - ${r['bitis']}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                        subtitle: Text(
                                          '${r['isimSoyisim']} - ${r['telefon']} - ${r['arac']}',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                          ),
                                        ),
                                        trailing: r['ucret'] != null
                                            ? Text(
                                                '${r['ucret']}₺',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: MonthCard.accentColor,
                                                ),
                                              )
                                            : null,
                                      );
                                    }).toList(),
                                  ),
                                ),
                              )
                              .toList(),
                  ),
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
// Search Delegate Sınıfı (Aynı kalır)
// ---------------------
class AppointmentSearch extends SearchDelegate<Map<String, dynamic>> {
  final List<Map<String, dynamic>> randevular;

  AppointmentSearch(this.randevular);

  @override
  ThemeData appBarTheme(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: AppBarTheme(
        color: const Color(0xFF1B2A38), // AppBar arka plan rengi
        foregroundColor: Colors.white, // İkon ve metin rengi
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.white70),
        labelStyle: TextStyle(color: Colors.white),
      ),
      scaffoldBackgroundColor: const Color(
        0xFF1B2A38,
      ), // Arama sonuçları ekranının arka planı
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          close(context, {});
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
          title: Text(
            r['arac'] ?? 'Araç Bilgisi Yok',
            style: const TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            "${r['isimSoyisim'] ?? 'İsim Yok'} - ${r['tarih'] ?? 'Tarih Yok'}",
            style: const TextStyle(color: Colors.white70),
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
          title: Text(
            r['arac'] ?? 'Araç Bilgisi Yok',
            style: const TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            "${r['isimSoyisim'] ?? 'İsim Yok'} - ${r['tarih'] ?? 'Tarih Yok'}",
            style: const TextStyle(color: Colors.white70),
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
