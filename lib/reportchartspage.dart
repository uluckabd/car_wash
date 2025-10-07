import 'package:car_wash/app_ready_package.dart';
import 'package:car_wash/main.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'charts_page.dart';
import 'database_service.dart';

// Turkuaz (Cyan) rengi vurgusuyla güncellenmiş MonthCard
// Yükleme durumu eklemek için StatefulWidget'a dönüştürüldü.
class MonthCard extends StatefulWidget {
  final String monthName;
  final VoidCallback onTap;

  const MonthCard({super.key, required this.monthName, required this.onTap});

  // Turkuaz vurgu rengi (önceki Gelir Grafiği rengine benzer)
  static const Color accentColor = Color(0xFF00BCD4); // Turkuaz/Cam Göbeği
  // Kartın içindeki şeffaf arka plan rengi
  static const Color cardInternalColor = Color.fromRGBO(255, 105, 97, 0.2);

  @override
  State<MonthCard> createState() => _MonthCardState();
}

class _MonthCardState extends State<MonthCard> {
  // Yükleme durumunu izlemek için değişken
  bool _isLoading = false;

  void _handleTap() async {
    // Yüklemeyi başlat
    setState(() {
      _isLoading = true;
    });

    // Ana onTap fonksiyonunu çalıştır
    // (Navigator.push işlemi burada gerçekleşir)
    widget.onTap();

    // Sayfa geçiş animasyonu başlasın diye kısa bir süre bekleyip yüklemeyi kapatıyoruz.
    await Future.delayed(const Duration(milliseconds: 400));

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        // Kartın Arka Plan Rengi: Hafif şeffaf gri/beyaz
        color: MonthCard.cardInternalColor,
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap:
              _handleTap, // Kendi yazdığımız handleTap fonksiyonunu kullanıyoruz
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 16.0,
              horizontal: 16.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.monthName,
                    // Metin Rengi: Beyaz
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                // Yükleme durumu kontrolü:
                _isLoading
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            MonthCard.accentColor, // Turkuaz yükleniyor
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 18,
                      ),
              ],
            ),
          ),
        ),
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

    final temp = monthNames.entries.map((e) {
      return {"month": e.key, "totalAmount": 0, "vehicleCount": 0};
    }).toList();

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
        centerTitle: true,
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
                  // Animasyonlu Sayfa Geçişi (Sağdan Sola Kayma)
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          ChartsPage(currentMonth: name),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                            const begin = Offset(1.0, 0.0); // Sağdan başla
                            const end = Offset.zero; // Ortaya gel
                            const curve =
                                Curves.easeOut; // Yumuşak geçiş eğrisi

                            var tween = Tween(
                              begin: begin,
                              end: end,
                            ).chain(CurveTween(curve: curve));

                            return SlideTransition(
                              position: animation.drive(tween),
                              child: child,
                            );
                          },
                      transitionDuration: const Duration(
                        milliseconds: 400,
                      ), // Geçiş süresi
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
      color: darkBlue,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20), // Köşeleri yuvarlak yaptık
      ),
      icon: const Icon(Icons.sort, color: Colors.white, size: 30),
      onSelected: onSelected,
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem(
          value: 'default',
          child: Text(
            'Varsayılan (Aylara göre)',
            style: TextStyle(color: Colors.white),
          ),
        ),
        const PopupMenuItem(
          value: 'amount_desc',
          child: Text(
            'Miktara göre en çok',
            style: TextStyle(color: Colors.white),
          ),
        ),
        const PopupMenuItem(
          value: 'amount_asc',
          child: Text(
            'Miktara göre en az',
            style: TextStyle(color: Colors.white),
          ),
        ),
        const PopupMenuItem(
          value: 'vehicle_desc',
          child: Text(
            'Araç sayısına göre en çok',
            style: TextStyle(color: Colors.white),
          ),
        ),
        const PopupMenuItem(
          value: 'vehicle_asc',
          child: Text(
            'Araç sayısına göre en az',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
