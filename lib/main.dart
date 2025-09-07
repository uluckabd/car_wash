import 'package:flutter/material.dart';
import 'AddAppointmentpage.dart';
import 'ArchiveScreen.dart';
import 'database_service.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Car_Wash',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
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

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    final loadedAppointments = await dbService.getAppointments();
    setState(() {
      randevular.clear();
      randevular.addAll(loadedAppointments);
    });
  }

  // Yeni Fonksiyon: Takvimi Açıp Tarih Seçme
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: baseDate,
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
    );
    if (pickedDate != null && pickedDate != baseDate) {
      // Seçilen tarih ile bugünün arasındaki gün farkını hesapla
      // Saat ve dakika farkını sıfırlayarak sadece gün farkına odaklan.
      final today = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      );
      final pickedDay = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
      );
      final int newPageIndex = pickedDay.difference(today).inDays;

      // PageView'ı seçilen tarihin sayfasına kaydır
      pageController.animateToPage(
        newPageIndex,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
      );

      setState(() {
        baseDate = pickedDate;
      });
    }
  }

  List<String> _generateTimeSlots() {
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

  String getFormattedDate(DateTime date) {
    final weekdays = [
      "Pazartesi",
      "Salı",
      "Çarşamba",
      "Perşembe",
      "Cuma",
      "Cumartesi",
      "Pazar",
    ];
    return "${weekdays[date.weekday - 1]} - ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    final slots = _generateTimeSlots();

    final pages = [
      // Ana Sayfa
      Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
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
                final currentDate = DateTime.now().add(Duration(days: index));
                final randevularBuGun = randevular.where((r) {
                  return r["tarih"] ==
                      "${currentDate.day.toString().padLeft(2, '0')}/${currentDate.month.toString().padLeft(2, '0')}/${currentDate.year}";
                }).toList();

                return ListView.builder(
                  itemCount: slots.length - 1,
                  itemBuilder: (context, i) {
                    final start = slots[i];
                    final end = slots[i + 1];
                    bool doluMu = false;
                    Map<String, dynamic> randevuBilgi = {};
                    for (var r in randevularBuGun) {
                      if (r["baslangic"].compareTo(end) < 0 &&
                          r["bitis"].compareTo(start) > 0) {
                        doluMu = true;
                        randevuBilgi = r;
                        break;
                      }
                    }
                    return ListTile(
                      leading: Icon(
                        Icons.access_time,
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
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.orange,
                                  ),
                                  onPressed: () async {
                                    final updatedAppointment =
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                AddAppointmentScreen(
                                                  appointmentData: randevuBilgi,
                                                ),
                                          ),
                                        );
                                    if (updatedAppointment != null) {
                                      await dbService.updateAppointment(
                                        randevuBilgi['id'],
                                        updatedAppointment,
                                      );
                                      _loadAppointments();
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
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
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: const Text("Hayır"),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: const Text("Evet"),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await dbService.deleteAppointment(
                                        randevuBilgi['id'],
                                      );
                                      _loadAppointments();
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text("Randevu silindi"),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ],
                            )
                          : null,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      // Arşiv sayfası
      ArchiveScreen(randevular: randevular),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(
          selectedIndex == 0 ? "Car_Wash" : "Arşiv",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 25,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color.fromRGBO(255, 1, 1, 1), Color(0xFF90CAF9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: selectedIndex == 1
            ? [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    showSearch(
                      context: context,
                      delegate: AppointmentSearch(randevular),
                    );
                  },
                ),
              ]
            : null,
      ),
      body: pages[selectedIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color.fromRGBO(255, 1, 1, 1), Color(0xFF90CAF9)],
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
