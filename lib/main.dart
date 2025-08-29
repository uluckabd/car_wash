import 'package:flutter/material.dart';
import 'AddAppointmentpage.dart';
import 'ArchiveScreen.dart';

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
  DateTime baseDate = DateTime.now(); // Başlangıç tarihi: bugün

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

  /// Dinamik başlık: "Pazartesi - 01/09/2025"
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
      Column(
        children: [
          // Başlık: gün ve tarih
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            color: Colors.blueAccent,
            child: Text(
              getFormattedDate(baseDate),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // PageView: günleri kaydır
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
                final gun = currentDate.weekday; // 1=Pazartesi ... 7=Pazar
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
                              "${randevuBilgi["isimSoyisim"]} - ${randevuBilgi["telefon"]}",
                            )
                          : const Text("Boş"),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      // Arama placeholder
      Column(
        children: [
          for (int i = 1; i <= 20; i++)
            ListTile(title: Text("Arama İçerik $i")),
        ],
      ),
      // Arşiv placeholder
      Container(),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text(
          "Car_Wash",
          style: TextStyle(
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
            if (index == 2) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ArchiveScreen(randevular: randevular),
                ),
              );
            } else {
              setState(() => selectedIndex = index);
            }
          },
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white70,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Ana Sayfa'),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Arama'),
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
            setState(() => randevular.add(yeniRandevu));
          }
        },
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
