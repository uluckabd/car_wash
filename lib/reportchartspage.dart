import 'package:car_wash/app_ready_package.dart';
import 'package:car_wash/main.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'charts_page.dart';
import 'database_service.dart';

class MonthCard extends StatefulWidget {
  final String monthName;
  final VoidCallback onTap;

  const MonthCard({super.key, required this.monthName, required this.onTap});

  // Sabit Renk Tanımlamaları
  static const Color appgreycolor = Color.fromARGB(255, 120, 120, 120);
  static const Color appbluecolor = Color(0xFF1B2A38);
  static const Color accentColor = Color(0xFF00BCD4); // Turkuaz
  static const Color cardInternalColor = Color.fromRGBO(
    255,
    105,
    97,
    0.2,
  ); // Şeffaf Kırmızımsı

  @override
  State<MonthCard> createState() => _MonthCardState();
}

class _MonthCardState extends State<MonthCard> {
  // Yükleme durumunu izleyen değişken
  bool _isLoading = false;

  // Tıklama anındaki yükleme ve sayfa geçişi
  void _handleTap() async {
    // Yüklemeyi başlat
    setState(() {
      _isLoading = true;
    });

    // Ana onTap fonksiyonunu çalıştırma fonksiyonu
    widget.onTap();

    // Sayfa geçiş animasyonu başlasın diye kısa bir süre bekle
    // Sayfa geçiş animasyonu başlasın diye kısa bir süre bekleten yapı
    await Future.delayed(const Duration(milliseconds: 100));

    // Yüklemeyi kapat
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
        color: MonthCard.cardInternalColor,
        borderRadius: BorderRadius.circular(12),
        // Işın Efekti (Gölge) ve Kenarlık
        boxShadow: [
          BoxShadow(
            color: MonthCard.accentColor.withOpacity(0.4),
            blurRadius: 6.0,
            spreadRadius: 1.0,
          ),
        ],
        border: Border.all(color: MonthCard.accentColor, width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _handleTap,
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
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                // Yükleme göstergesi veya İkon
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

// --- ReportChartsPage (Aylık Grafik Raporu Ana Sayfası) ---
class ReportChartsPage extends StatefulWidget {
  const ReportChartsPage({super.key});

  @override
  State<ReportChartsPage> createState() => _ReportChartsPageState();
}

class _ReportChartsPageState extends State<ReportChartsPage> {
  List<Map<String, dynamic>> monthlyData = [];
  String selectedSort = "default";

  // Ay Numarası ve İsimleri
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
    _loadMonthlyData(); // Uygulama açılır açılmaz verileri yükle
  }

  // Veritabanından aylık verileri çekme ve ekrana yansıtma fonksiyonu
  Future<void> _loadMonthlyData() async {
    final db = DatabaseService();
    final dbData = await db.getMonthlySummary();

    // Tüm ayları (varsayılan 0 değerleriyle) içeren şablonu oluştur
    final temp = monthNames.entries.map((e) {
      return {"month": e.key, "totalAmount": 0, "vehicleCount": 0};
    }).toList();

    // Veritabanı verilerini şablon üzerine yerleştir (aylık toplamları güncelle)
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

  // Verilere göre sıralama fonksiyonu (popup menüdeki secenekler icin)
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
        // Varsayılan: Ay numarasına göre sırala
        monthlyData.sort(
          (a, b) => int.parse(a['month']).compareTo(int.parse(b['month'])),
        );
      }
    });
  }

  // Grafik analiz sayfası arka plan rengi (Gradient)
  BoxDecoration charts_background_color() {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [MonthCard.appbluecolor, MonthCard.appgreycolor],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    );
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
        decoration: charts_background_color(),
        child: ListView_Card(monthlyData: monthlyData, monthNames: monthNames),
      ),
    );
  }
}

// --- ListView_Card (Kart İçeriklerini Listeleyen ve Animasyonlu Geçişi Yöneten Widget) ---
class ListView_Card extends StatelessWidget {
  const ListView_Card({
    super.key,
    required this.monthlyData,
    required this.monthNames,
  });

  final List<Map<String, dynamic>> monthlyData;
  final Map<String, String> monthNames;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
      child: ListView(
        children: monthlyData.map((month) {
          final name = monthNames[month['month']] ?? month['month'];
          return MonthCard(
            // Kart başlığı içeriği
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
                        const curve = Curves.easeOut; // Yumuşak geçiş eğrisi

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
    );
  }
}

// --- SortMenu (Sağ Üstteki Sıralama Seçenekleri Menüsü) ---
class SortMenu extends StatelessWidget {
  final Function(String) onSelected;

  const SortMenu({super.key, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      color: darkBlue,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      icon: const Icon(Icons.sort, color: Colors.white, size: 30),
      onSelected: onSelected,
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem(
          value: 'default',
          child: Menu_items(itemtext: 'Varsayılan (Aylara göre)'),
        ),
        const PopupMenuItem(
          value: 'amount_desc',
          child: Menu_items(itemtext: "Miktara göre en çok"),
        ),
        const PopupMenuItem(
          value: 'amount_asc',
          child: Menu_items(itemtext: "Miktara göre en az"),
        ),
        const PopupMenuItem(
          value: 'vehicle_desc',
          child: Menu_items(itemtext: "Araç sayısına göre en çok"),
        ),
        const PopupMenuItem(
          value: 'vehicle_asc',
          child: Menu_items(itemtext: "Araç sayısına göre en az"),
        ),
      ],
    );
  }
}

// --- Menu_items (Popup Menü Seçeneği Metin Stili) ---
class Menu_items extends StatelessWidget {
  const Menu_items({super.key, required this.itemtext});

  final String itemtext;

  @override
  Widget build(BuildContext context) {
    return Text(itemtext, style: const TextStyle(color: Colors.white));
  }
}
