import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class AddAppointmentScreen extends StatefulWidget {
  const AddAppointmentScreen({super.key});

  @override
  State<AddAppointmentScreen> createState() => _AddAppointmentScreenState();
}

class _AddAppointmentScreenState extends State<AddAppointmentScreen> {
  String? _startTime;
  String? _endTime;

  final isimController = TextEditingController();
  final telefonController = TextEditingController();
  final aracController = TextEditingController();
  final ucretController = TextEditingController();
  final notController =
      TextEditingController(); // Bu controller'ın adı değişmedi

  final List<String> _timeSlots = List.generate(21, (index) {
    final hour = 8 + (index ~/ 2);
    final minute = (index % 2) * 30;
    final hh = hour.toString().padLeft(2, '0');
    final mm = minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  });

  final dateMask = MaskTextInputFormatter(
    mask: '##/##/####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  final TextEditingController dateController = TextEditingController(
    text: (() {
      final today = DateTime.now();
      return '${today.day.toString().padLeft(2, '0')}/${today.month.toString().padLeft(2, '0')}/${today.year}';
    })(),
  );

  final List<String> gunler = [
    "Pazartesi",
    "Salı",
    "Çarşamba",
    "Perşembe",
    "Cuma",
    "Cumartesi",
    "Pazar",
  ];

  @override
  void dispose() {
    dateController.dispose();
    isimController.dispose();
    telefonController.dispose();
    aracController.dispose();
    ucretController.dispose();
    notController.dispose();
    super.dispose();
  }

  Widget buildTextField({
    required String label,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    TextEditingController? controller,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.25),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.blueGrey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> _filteredEndTimes = _startTime == null
        ? _timeSlots
        : _timeSlots.where((time) => time.compareTo(_startTime!) >= 0).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      appBar: AppBar(
        title: const Text(
          'Yeni Randevu',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 25,
          ),
        ),
        automaticallyImplyLeading: false,
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
      body: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFF0101), Color(0xFF90CAF9)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                buildTextField(
                  label: 'İsim-soyisim',
                  controller: isimController,
                ),
                const SizedBox(height: 20),
                buildTextField(
                  label: 'Telefon',
                  keyboardType: TextInputType.phone,
                  controller: telefonController,
                ),
                const SizedBox(height: 20),
                buildTextField(
                  label: 'Araç Bilgisi',
                  controller: aracController,
                ),
                const SizedBox(height: 20),
                buildTextField(
                  label: 'Tarih',
                  keyboardType: TextInputType.number,
                  controller: dateController,
                  inputFormatters: [dateMask],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Başlangıç Saati',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        value: _startTime,
                        items: _timeSlots
                            .map(
                              (time) => DropdownMenuItem(
                                value: time,
                                child: Text(time),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _startTime = value;
                            if (_endTime != null &&
                                _endTime!.compareTo(_startTime!) < 0) {
                              _endTime = null;
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Bitiş Saati',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        value: _endTime,
                        items: _filteredEndTimes
                            .map(
                              (time) => DropdownMenuItem(
                                value: time,
                                child: Text(time),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => setState(() => _endTime = value),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                buildTextField(label: 'Ücret', controller: ucretController),
                const SizedBox(height: 20),
                buildTextField(
                  label: 'Not',
                  maxLines: 3,
                  controller: notController,
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF90CAF9),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Vazgeç',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (_startTime == null || _endTime == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Lütfen başlangıç ve bitiş saatini seçin',
                              ),
                            ),
                          );
                          return;
                        }

                        // Tarihten gün adını hesapla
                        final tarihParts = dateController.text.split('/');
                        final gunTarihi = DateTime(
                          int.parse(tarihParts[2]),
                          int.parse(tarihParts[1]),
                          int.parse(tarihParts[0]),
                        );
                        final gunAdi = gunler[gunTarihi.weekday - 1];

                        final appointment = {
                          "isimSoyisim": isimController.text,
                          "telefon": telefonController.text,
                          "arac": aracController.text,
                          "tarih": dateController.text,
                          "baslangic": _startTime,
                          "bitis": _endTime,
                          "ucret": ucretController.text,
                          "aciklama": notController
                              .text, // Not alanını aciklama olarak değiştirdik
                          "gun": gunAdi,
                        };

                        Navigator.pop(context, appointment);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF0101),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Kaydet',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
