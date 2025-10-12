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
const Color primaryColor = Colors.red;
const Color secondaryColor = Color(0xFF90CAF9);
const Color darkBlue = Color(0xFF1B2A38);
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
        // Buraya diğer diller de eklenebilir
      ],
      title: 'Car_Wash',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        appBarTheme: AppBarTheme(
          color: darkBlue,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 25,
            fontWeight: FontWeight.bold,
            wordSpacing: 2,
            letterSpacing: 1,
          ),
        ),
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

    // Geçici olarak, onDateTimeChanged tetiklenmediğinde veya butona basılmadan önce kullanılacak bir tarih tutarız.
    // baseDate'in tanımlı olduğunu varsayıyoruz.
    DateTime tempPickedDate = baseDate;

    // showCupertinoModalPopup kullanarak alttan açılan bir menü oluşturma
    await showCupertinoModalPopup(
      context: context,
      builder: (BuildContext builder) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          height:
              MediaQuery.of(context).size.height / 3, // Mevcut height'ı koruduk
          // Arka plan rengini belirle
          child: Column(
            children: [
              // !!! SADECE BU KISIM DEĞİŞTİ: TAMAM BUTONUNU SAĞ ÜSTE TAŞIYORUZ !!!
              Row(
                mainAxisAlignment: MainAxisAlignment.end, // Sağa yasla
                children: [
                  CupertinoButton(
                    onPressed: () {
                      // Buradaki mantık, önceki cevaptaki gibi düzeltildi.
                      // Menüyü kapatırken seçilen son tarihi (tempPickedDate) atayıp kapatıyoruz.
                      pickedDate = tempPickedDate;
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Tamam',
                      style: TextStyle(
                        color: darkBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              // TARİH ÇARKI (Kalan alanı doldurması için Expanded ile sardık)
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date, // Sadece tarih seçimi
                  initialDateTime: baseDate,
                  minimumDate: DateTime(2023),
                  maximumDate: DateTime(2030),
                  onDateTimeChanged: (DateTime newDate) {
                    // Tarih değiştikçe tempPickedDate'i güncelle
                    tempPickedDate = newDate;
                  },
                ),
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

  // Yeniden kullanılabilir ve okunabilir bir widget metodu (TASARIM GÜNCELLENDİ!)
  Widget _buildAppointmentListTile(
    Map<String, dynamic> randevuBilgi,
    String start,
    String end,
  ) {
    final bool doluMu = randevuBilgi.isNotEmpty;
    // Renk ve tema ayarları
    // primaryColor ve secondaryColor'ın tanımlı olduğunu varsayıyoruz
    final Color itemColor = doluMu ? primaryColor : secondaryColor;
    final Color iconColor = doluMu
        ? Colors.red.shade700
        : Colors.green.shade600;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Card(
        color: Colors.grey.shade300,
        // Card ile Listeleme öğesine hafif bir gölge ve köşe yuvarlaklığı ekliyoruz.
        elevation: doluMu ? 4 : 1, // Dolu randevulara daha belirgin bir gölge
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            // BOŞ (doluMu == false) ise secondaryColor (yani istenen accentColor) kullanıldı.
            color: doluMu ? itemColor.withOpacity(0.9) : secondaryColor,
            width: 2.0,
          ),
        ),
        child: ListTile(
          // onTap ve diğer işlevsellikler olduğu gibi korunuyor.
          onTap: () {
            if (doluMu) {
              final String telefon = randevuBilgi['telefon'] ?? '';
              final rawPhoneNumber = telefon.replaceAll(RegExp(r'[^\d]'), '');
              _makePhoneCall(rawPhoneNumber);
            } else {
              // Boş randevu için işlem (örn: Ekleme ekranına git)
              // FAB aktif olduğu için bu kısımda bir aksiyon bırakılmadı.
            }
          },

          // ZAMAN DİLİMİ (Leading)
          leading: Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
            child: Icon(Icons.minor_crash_rounded, size: 25, color: iconColor),
          ),

          // ZAMAN ARALIĞI (Title)
          title: Text(
            "$start - $end",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: doluMu ? Colors.black87 : darkBlue,
            ),
          ),

          // RANDEVU BİLGİLERİ (Subtitle)
          subtitle: doluMu
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Araç - İsimSoyisim
                    Text(
                      "${randevuBilgi["arac"]} - ${randevuBilgi["isimSoyisim"]}",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    // Telefon numarası alt satırda, daha az belirgin
                    Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 2.0),
                          child: Text(
                            "${randevuBilgi["telefon"]}  ",
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Colors.grey.shade600,
                                  fontStyle: FontStyle.italic,
                                ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 2.0),
                          child: Icon(
                            Icons.call,
                            size: 15,
                            color: Colors.green[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              : Text(
                  // Bu slot boşsa
                  "Boş",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.green.shade600,
                  ),
                ),

          // AKSİYON BUTONLARI (Trailing)
          trailing: doluMu
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Düzenleme Butonu
                    IconButton(
                      icon: const Icon(
                        Icons.edit,
                        color: Colors.blue,
                        size: 20,
                      ),
                      onPressed: () async {
                        // Randevu düzenleme sayfasına PageRouteBuilder ile Zoom animasyonu uyguluyoruz.
                        final updatedAppointment = await Navigator.push(
                          context,
                          // *** ZOOM (SCALE) ANIMASYONU BAŞLANGICI ***
                          PageRouteBuilder(
                            // Sayfa giriş süresi
                            transitionDuration: const Duration(
                              milliseconds: 500,
                            ),
                            // Sayfa çıkış süresi (geri dönerken)
                            reverseTransitionDuration: const Duration(
                              milliseconds: 400,
                            ),
                            // Gösterilecek olan sayfa (Mevcut randevu bilgisini aktarıyoruz!)
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    AddAppointmentScreen(
                                      appointmentData:
                                          randevuBilgi, // Veri aktarımı burada
                                    ),
                            // Animasyonun kendisi (Fade + Scale)
                            transitionsBuilder:
                                (
                                  context,
                                  animation,
                                  secondaryAnimation,
                                  child,
                                ) {
                                  // Yavaşça Belirme (Fade)
                                  final fadeAnimation =
                                      Tween<double>(
                                        begin: 0.0,
                                        end: 1.0,
                                      ).animate(
                                        CurvedAnimation(
                                          parent: animation,
                                          curve:
                                              Curves.easeOut, // Yumuşak belirme
                                        ),
                                      );

                                  // Küçülüp Büyüme (Scale - Zoom)
                                  final scaleAnimation =
                                      Tween<double>(
                                        begin: 0.8, // %80'den başla
                                        end: 1.0, // %100'e zoom yap
                                      ).animate(
                                        CurvedAnimation(
                                          parent: animation,
                                          curve: Curves
                                              .easeOutBack, // Yaylanmalı zoom efekti
                                        ),
                                      );

                                  return FadeTransition(
                                    opacity: fadeAnimation,
                                    child: ScaleTransition(
                                      scale: scaleAnimation,
                                      child: child,
                                    ),
                                  );
                                },
                          ),
                          // *** ZOOM (SCALE) ANIMASYONU SONU ***
                        );

                        if (updatedAppointment != null) {
                          // Güncelleme başarılıysa, veritabanını güncelle
                          await dbService.updateAppointment(
                            randevuBilgi['id'],
                            updatedAppointment,
                          );
                          // Randevu listesini yenile
                          _loadAppointments();
                        }
                      },
                    ),
                    // Silme Butonu
                    IconButton(
                      icon: const Icon(
                        Icons.delete,
                        color: primaryColor,
                        size: 20,
                      ),
                      onPressed: () async {
                        final confirm = await showGeneralDialog<bool>(
                          context: context,
                          barrierDismissible:
                              true, // Diyalog dışına tıklanırsa kapanabilir
                          barrierLabel: 'Randevu Silme Onayı',
                          barrierColor:
                              Colors.black54, // Arka plan karartma rengi
                          transitionDuration: const Duration(
                            milliseconds: 300,
                          ), // Animasyon süresi
                          // *** ANIMASYON EFEKTİ BURADA TANIMLANIYOR ***
                          transitionBuilder: (context, a1, a2, child) {
                            // a1: Animasyon kontrolcüsü
                            return Transform.scale(
                              scale: a1.value, // 0.0'dan 1.0'a büyütme
                              child: FadeTransition(
                                opacity: a1, // 0.0'dan 1.0'a belirme
                                child: child, // AlertDialog widget'ımız
                              ),
                            );
                          },

                          // *** ANIMASYON EFEKTİ SONU ***
                          pageBuilder: (context, animation, secondaryAnimation) {
                            // AlertDialog içeriği aynı kalıyor
                            return AlertDialog(
                              backgroundColor: darkBlue,
                              title: const Text(
                                "Randevuyu Sil",
                                style: TextStyle(color: Colors.white),
                              ),
                              content: const Text(
                                "Bu randevuyu silmek istediğinize emin misiniz?",
                                style: TextStyle(color: Colors.white),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text(
                                    "Hayır",
                                    style: TextStyle(
                                      color: Colors.white70,
                                    ), // Hafifçe soluk
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text(
                                    "Evet",
                                    // Silme eylemini vurgulamak için Kırmızı renk
                                    style: TextStyle(color: Colors.redAccent),
                                  ),
                                ),
                              ],
                            );
                          },
                        );

                        if (confirm == true) {
                          await dbService.deleteAppointment(randevuBilgi['id']);
                          _loadAppointments();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Randevu silindi"),
                                backgroundColor: darkBlue,
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ],
                )
              // Boş randevu için artık ekleme ikonu yok (istenildiği gibi silindi)
              : null,
        ),
      ),
    );
  }

  // Yeni Randevu Ekleme İşlevi: FAB'a atanacak fonksiyon
  Future<void> _addAppointment() async {
    final yeniRandevu = await Navigator.push(
      context,
      // *** ZOOM (SCALE) ANIMASYONU KODU ***
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        reverseTransitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const AddAppointmentScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Sayfanın yavaşça belirmesi (FadeTransition)
          final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut, // Yumuşak belirme
            ),
          );

          // Sayfanın küçülüp büyümesi (ScaleTransition)
          final scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
            CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack, // Hafif yaylanmalı bir zoom efekti
            ),
          );

          return FadeTransition(
            opacity: fadeAnimation,
            child: ScaleTransition(scale: scaleAnimation, child: child),
          );
        },
      ),
      // *** ZOOM (SCALE) ANIMASYONU KODU SONU ***
    );

    if (yeniRandevu != null) {
      // Veri kaydetme mantığı
      await dbService.addAppointment(yeniRandevu);
      _loadAppointments();
    }
  }

  @override
  Widget build(BuildContext context) {
    // IndexedStack kullanarak sadece aktif olan sayfayı çiziyoruz.
    return Scaffold(
      appBar: AppBar(
        backgroundColor: darkBlue,

        // 1. BAŞLIK (TITLE): selectedIndex'e göre başlık değişir
        title: selectedIndex == 0
            ? Column(
                // Row'dan Column'a çevrildi
                crossAxisAlignment: CrossAxisAlignment.start, // Sola hizalama
                mainAxisSize: MainAxisSize.min, // Alanı minimumda tut
                children: [
                  // ANA SAYFA METNİ (Daha büyük ve kalın)
                  Text(
                    "Ana Sayfa",
                    style: Theme.of(context).appBarTheme.titleTextStyle,
                  ),

                  // TARİH BİLGİSİ (Hemen altına)
                  Text(
                    getFormattedDate(baseDate),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              )
            // selectedIndex 1 ise "Arşiv" başlığını göster
            : selectedIndex == 1
            ? Text("Arşiv", style: Theme.of(context).appBarTheme.titleTextStyle)
            // Başka bir index ise varsayılan başlık
            : Text(
                "Başlık",
                style: Theme.of(context).appBarTheme.titleTextStyle,
              ),

        // 2. EYLEMLER (ACTIONS): selectedIndex'e göre ikonlar değişir (Değişmedi)
        actions: selectedIndex == 0
            ? [
                // Index 0 (Ana Sayfa) için Takvim İkonu
                Padding(
                  padding: const EdgeInsets.only(left: 0, top: 8),
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center, // Ortalamak için
                    crossAxisAlignment: CrossAxisAlignment.end, // Sağa hizalama
                    children: [
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                        onPressed: () => _selectDate(context),
                        icon: Icon(Icons.calendar_month_outlined),
                      ),
                    ],
                  ),
                ),
              ]
            : selectedIndex == 1
            ? [
                // Index 1 (Arşiv) için Arama ve Rapor ikonları
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.white),
                  onPressed: () {
                    showSearch(
                      context: context,
                      // AppointmentSearch sınıfının tanımı burada mevcut değil,
                      // ancak işlevsellik bozulmasın diye tutuyorum.
                      delegate: AppointmentSearch(randevular),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(
                    Icons.analytics_outlined,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    // Sağdan Sola Kayma Animasyonu
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            const ReportChartsPage(), // Hedef sayfa
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                              const begin = Offset(1.0, 0.0); // Sağdan başla
                              const end = Offset.zero; // Ortaya gel
                              const curve = Curves.easeOut; // Yumuşak geçiş

                              var tween = Tween(
                                begin: begin,
                                end: end,
                              ).chain(CurveTween(curve: curve));

                              return SlideTransition(
                                position: animation.drive(tween),
                                child: child,
                              );
                            },
                        transitionDuration: const Duration(milliseconds: 400),
                      ),
                    );
                  },
                ),
              ]
            : null,
      ),
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
        child: IndexedStack(
          index: selectedIndex,
          children: [
            // Ana Sayfa içeriği
            Column(
              children: [
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
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: darkBlue,
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
      // İstenildiği gibi FloatingActionButton aktif edildi ve animasyon eklendi.
      floatingActionButton: FloatingActionButton(
        onPressed: _addAppointment, // Yeni fonksiyonu çağır
        backgroundColor: const Color.fromRGBO(255, 191, 0, 1.0), // Vurgulu renk
        child: const Icon(Icons.add, color: darkBlue),
      ),
      // FAB'ın navigasyon bar'ın ortasına yerleştirilmesi.
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

// Not: `AppointmentSearch` ve `DatabaseService` sınıflarının tanımı bu dosyada mevcut değil, ancak
// import edildikleri varsayılarak kod akışı korunmuştur.
