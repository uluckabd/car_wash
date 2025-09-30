import 'package:car_wash/app_ready_package.dart';
import 'package:car_wash/reportchartspage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import 'AddAppointmentpage.dart';
import 'ArchiveScreen.dart';
import 'database_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';

// Uygulama genelinde kullanılacak renkleri ve metinleri sabitler olarak tanımlıyoruz.
const Color primaryColor = Color.fromRGBO(255, 1, 1, 1);
const Color secondaryColor = Color(0xFF90CAF9);
const List<String> weekdays = [
  "Pazartesi",
  "Salı",
  "Çarşamba",
  "Perşembe",
  "Cuma",
  "Cumartesi",
  "Pazar",
];

void main() {
  // 'AppointmentSearch' tanımlı değilse, bu kısım hata verebilir.
  // O sınıfın tanımlı olduğu dosyayı (büyük ihtimalle ArchiveScreen.dart veya ayrı bir dosya) kontrol edin.
  // Bu güncelleme sadece 'MyHomePage' sınıfı içindir.
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('tr', 'TR'), // Türkçe
        // Diğer diller de eklenebilir
      ],
      title: 'Car_Wash',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        primaryColor: primaryColor,
        primaryColorLight: secondaryColor,
      ),
      home: const MyHomePage(title: 'Car_Wash'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int selectedIndex = 0;
  final List<Map<String, dynamic>> randevular = [];
  final PageController pageController = PageController(initialPage: 0);
  DateTime baseDate = DateTime.now();
  final dbService = DatabaseService();

  final List<String> _slots = _generateTimeSlots();

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  static List<String> _generateTimeSlots() {
    List<String> slots = [];
    DateTime start = DateTime(2023, 1, 1, 8, 0);
    DateTime end = DateTime(2023, 1, 1, 18, 0);
    while (start.isBefore(end) || start.isAtSameMomentAs(end)) {
      slots.add(
        "${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}",
      );
      start = start.add(const Duration(minutes: 30));
    }
    return slots;
  }

  Future<void> _loadAppointments() async {
    final loadedAppointments = await dbService.getAppointments();
    setState(() {
      randevular.clear();
      randevular.addAll(loadedAppointments);
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? pickedDate;

    // showCupertinoModalPopup kullanarak alttan açılan bir menü oluşturma
    await showCupertinoModalPopup(
      context: context,
      builder: (BuildContext builder) {
        return Container(
          height:
              MediaQuery.of(context).size.height /
              3, // Ekranın 1/3'ünü kaplasın
          color: Colors.white, // Arka plan rengini belirle
          child: Column(
            children: [
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date, // Sadece tarih seçimi
                  initialDateTime: baseDate,
                  minimumDate: DateTime(2023),
                  maximumDate: DateTime(2030),
                  onDateTimeChanged: (DateTime newDate) {
                    // Tarih değiştikçe pickedDate'i güncelle
                    pickedDate = newDate;
                  },
                ),
              ),
              // Tamam butonu
              CupertinoButton(
                onPressed: () => Navigator.pop(context), // Menüyü kapat
                child: const Text('Tamam'),
              ),
            ],
          ),
        );
      },
    );

    // Eğer bir tarih seçildiyse ve önceki tarihten farklıysa işlemleri yap
    if (pickedDate != null && pickedDate != baseDate) {
      final today = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      );
      final pickedDay = DateTime(
        pickedDate!.year,
        pickedDate!.month,
        pickedDate!.day,
      );
      final int newPageIndex = pickedDay.difference(today).inDays;

      pageController.animateToPage(
        newPageIndex,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
      );

      setState(() {
        baseDate = pickedDate!;
      });
    }
  }

  Future<void> _makePhoneCall(String? telefonNumarasi) async {
    // 1. Gelen numara null veya boş mu?
    if (telefonNumarasi == null || telefonNumarasi.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Arama için telefon numarası boş.')),
        );
      }
      return; // İşlemi sonlandır
    }

    // 2. Maskeleri temizle (Sadece rakamları al)
    final rawPhoneNumber = telefonNumarasi.replaceAll(RegExp(r'[^\d]'), '');

    // 3. Temizlenmiş numara da boş kaldıysa?
    if (rawPhoneNumber.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Arama için geçerli telefon numarası bulunamadı.'),
          ),
        );
      }
      return; // İşlemi sonlandır
    }

    // 4. URI'yi oluştur (Numaranın başına 'tel:' şemasını ekliyoruz)
    final Uri launchUri = Uri(scheme: 'tel', path: rawPhoneNumber);

    // 5. URL'yi başlatmayı dene
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        if (context.mounted) {
          // canLaunchUrl false döndürürse bu hata mesajını ver
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Arama başlatılamadı: Cihaz desteklemiyor.'),
            ),
          );
        }
      }
    } catch (e) {
      // Fırlatılan herhangi bir hatayı yakala
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Arama sırasında hata oluştu: $e')),
        );
      }
    }
  }

  String getFormattedDate(DateTime date) {
    return "${weekdays[date.weekday - 1]} - ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  // Yeniden kullanılabilir ve okunabilir bir widget metodu
  Widget _buildAppointmentListTile(
    Map<String, dynamic> randevuBilgi,
    String start,
    String end,
  ) {
    final bool doluMu = randevuBilgi.isNotEmpty;

    return ListTile(
      // ✅ BURASI GÜNCELLENDİ: ListTile'a tıklandığında arama yapacak.
      onTap: () {
        if (doluMu) {
          final String telefon = randevuBilgi['telefon'] ?? '';

          // Telefon numarasındaki tüm maskeleri (boşluk, parantez, tire vb.) temizle
          final rawPhoneNumber = telefon.replaceAll(RegExp(r'[^\d]'), '');

          _makePhoneCall(rawPhoneNumber);
        } else {
          // Randevu boşsa, yeni randevu ekleme ekranına yönlendirebilirsin.
          // Şimdilik boş bırakıyorum.
        }
      },
      // inputFormatters: [phoneMask], // Gerekirse maskeyi burada tutmaya devam et
      leading: Icon(
        Icons.access_time,
        size: 25,
        color: doluMu ? Colors.red : Colors.green,
      ),
      title: Text("$start - $end"),
      subtitle: doluMu
          ? Text(
              "${randevuBilgi["arac"]} - ${randevuBilgi["isimSoyisim"]} - ${randevuBilgi["telefon"]}",
            )
          : const Text("Boş"),
      trailing: doluMu
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Düzenleme butonu (Arama butonu yerine kullanabilirsin, ama onTap'a ekledik.)
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.orange, size: 25),
                  onPressed: () async {
                    final updatedAppointment = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            AddAppointmentScreen(appointmentData: randevuBilgi),
                      ),
                    );
                    if (updatedAppointment != null) {
                      // Randevu güncelleme mantığı
                      await dbService.updateAppointment(
                        randevuBilgi['id'],
                        updatedAppointment,
                      );
                      _loadAppointments();
                    }
                  },
                ),
                // Silme butonu
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 25),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Randevuyu Sil"),
                        content: const Text(
                          "Bu randevuyu silmek istediğinize emin misiniz?",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text("Hayır"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text("Evet"),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await dbService.deleteAppointment(randevuBilgi['id']);
                      _loadAppointments();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Randevu silindi")),
                        );
                      }
                    }
                  },
                ),
              ],
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    // IndexedStack kullanarak sadece aktif olan sayfayı çiziyoruz.
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          selectedIndex == 0 ? "Ana Sayfa" : "Arşiv",
          style: AppTextStyles.title,
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
        actions: selectedIndex == 1
            ? [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () {
                        // 'AppointmentSearch' sınıfının tanımlı olduğundan emin olun.
                        showSearch(
                          context: context,
                          delegate: AppointmentSearch(randevular),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.analytics_outlined),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ReportChartsPage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ]
            : null,
      ),
      body: IndexedStack(
        index: selectedIndex,
        children: [
          // Ana Sayfa içeriği
          Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 20,
                ),
                color: Colors.blueAccent,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      getFormattedDate(baseDate),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.calendar_month_outlined,
                        color: Colors.white,
                        size: 30,
                      ),
                      onPressed: () => _selectDate(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: pageController,
                  onPageChanged: (index) {
                    setState(() {
                      baseDate = DateTime.now().add(Duration(days: index));
                    });
                  },
                  itemBuilder: (context, index) {
                    final currentDate = DateTime.now().add(
                      Duration(days: index),
                    );
                    final randevularBuGun = randevular.where((r) {
                      final randevuTarihi = DateFormat(
                        'dd/MM/yyyy',
                      ).parse(r["tarih"]);
                      return randevuTarihi.year == currentDate.year &&
                          randevuTarihi.month == currentDate.month &&
                          randevuTarihi.day == currentDate.day;
                    }).toList();

                    return ListView.builder(
                      itemCount: _slots.length - 1,
                      itemBuilder: (context, i) {
                        final start = _slots[i];
                        final end = _slots[i + 1];
                        Map<String, dynamic> randevuBilgi = {};
                        for (var r in randevularBuGun) {
                          if (r["baslangic"].compareTo(end) < 0 &&
                              r["bitis"].compareTo(start) > 0) {
                            randevuBilgi = r;
                            break;
                          }
                        }
                        return _buildAppointmentListTile(
                          randevuBilgi,
                          start,
                          end,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          // Arşiv Sayfası
          ArchiveScreen(randevular: randevular),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryColor, secondaryColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          currentIndex: selectedIndex,
          onTap: (index) {
            setState(() => selectedIndex = index);
          },
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white70,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Ana Sayfa'),

            BottomNavigationBarItem(icon: Icon(Icons.archive), label: 'Arşiv'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final yeniRandevu = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddAppointmentScreen(),
            ),
          );
          if (yeniRandevu != null) {
            await dbService.addAppointment(yeniRandevu);
            _loadAppointments();
          }
        },
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
