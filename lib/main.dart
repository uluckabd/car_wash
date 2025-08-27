import 'package:car_wash/AddAppointmentpage.dart';
import 'package:flutter/material.dart';

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
      home: const MyHomePage(title: 'Car_Wash '),
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

  /// 08:00 - 18:00 arası yarım saatlik saat dilimleri
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

  /// sayfalar
  late final List<Widget> _pages = [
    // Ana Sayfa: saat ölçeklendirmesi
    Builder(
      builder: (context) {
        final slots = _generateTimeSlots();
        return ListView.builder(
          itemCount: slots.length,
          itemBuilder: (context, index) {
            final time = slots[index];
            return ListTile(
              leading: const Icon(Icons.access_time),
              title: Text(time),
              subtitle: null, // Randevu eklendiğinde alt satır gösterilecek
            );
          },
        );
      },
    ),
    // Arama
    Column(
      children: [
        for (int i = 1; i <= 20; i++) ListTile(title: Text("Arama İçerik $i")),
      ],
    ),
    // Arşiv (boş sayfa)
    Container(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(
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
      body: _pages[selectedIndex],
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
          onTap: _onItemTapped,
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
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddAppointmentScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
