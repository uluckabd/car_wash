import 'package:car_wash/database_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class AddAppointmentScreen extends StatefulWidget {
  final Map<String, dynamic>? appointmentData;

  const AddAppointmentScreen({super.key, this.appointmentData});

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
  final notController = TextEditingController();

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

  final TextEditingController dateController = TextEditingController();
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
  void initState() {
    super.initState();

    if (widget.appointmentData != null) {
      final data = widget.appointmentData!;
      isimController.text = data['isimSoyisim'] ?? '';
      telefonController.text = data['telefon'] ?? '';
      aracController.text = data['arac'] ?? '';
      ucretController.text = data['ucret'] ?? '';
      notController.text = data['aciklama'] ?? '';
      dateController.text = data['tarih'] ?? '';
      _startTime = data['baslangic'];
      _endTime = data['bitis'];
    } else {
      final today = DateTime.now();
      dateController.text =
          '${today.day.toString().padLeft(2, '0')}/${today.month.toString().padLeft(2, '0')}/${today.year}';
    }
  }

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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFF0101),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null) {
      setState(() {
        dateController.text =
            '${pickedDate.day.toString().padLeft(2, '0')}/${pickedDate.month.toString().padLeft(2, '0')}/${pickedDate.year}';
      });
    }
  }

  Widget buildTextField({
    required String label,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    TextEditingController? controller,
    int maxLines = 1,
    bool readOnly = false,
    Function()? onTap,
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
        readOnly: readOnly,
        onTap: onTap,
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
    final _filteredEndTimes = _startTime == null
        ? _timeSlots
        : _timeSlots.where((time) => time.compareTo(_startTime!) >= 0).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      appBar: AppBar(
        title: Text(
          widget.appointmentData == null ? 'Yeni Randevu' : 'Randevu Güncelle',
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
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              buildTextField(label: 'İsim-soyisim', controller: isimController),
              const SizedBox(height: 20),
              buildTextField(
                label: 'Telefon',
                keyboardType: TextInputType.phone,
                controller: telefonController,
              ),
              const SizedBox(height: 20),
              buildTextField(label: 'Araç Bilgisi', controller: aracController),
              const SizedBox(height: 20),
              buildTextField(
                label: 'Tarih',
                controller: dateController,
                readOnly: true,
                onTap: () => _selectDate(context),
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
                    onPressed: () async {
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

                      final tarihParts = dateController.text.split('/');
                      final gunTarihi = DateTime(
                        int.parse(tarihParts[2]),
                        int.parse(tarihParts[1]),
                        int.parse(tarihParts[0]),
                      );
                      final gunAdi = gunler[gunTarihi.weekday - 1];

                      // Yeni randevu saatlerini DateTime nesnesine dönüştür
                      final newStart = DateTime(
                        gunTarihi.year,
                        gunTarihi.month,
                        gunTarihi.day,
                        int.parse(_startTime!.split(':')[0]),
                        int.parse(_startTime!.split(':')[1]),
                      );

                      final newEnd = DateTime(
                        gunTarihi.year,
                        gunTarihi.month,
                        gunTarihi.day,
                        int.parse(_endTime!.split(':')[0]),
                        int.parse(_endTime!.split(':')[1]),
                      );

                      // O günkü mevcut randevuları çek
                      final existingAppointments = await DatabaseService()
                          .getAppointmentsByDate(dateController.text);

                      // Mevcut randevularla çakışma kontrolü yap
                      for (var appt in existingAppointments) {
                        // Kendi randevumuzu güncelliyorsak kontrol dışında tut
                        if (widget.appointmentData != null &&
                            appt['id'] == widget.appointmentData!['id']) {
                          continue;
                        }

                        final existingStart = DateTime(
                          gunTarihi.year,
                          gunTarihi.month,
                          gunTarihi.day,
                          int.parse(appt['baslangic'].split(':')[0]),
                          int.parse(appt['baslangic'].split(':')[1]),
                        );
                        final existingEnd = DateTime(
                          gunTarihi.year,
                          gunTarihi.month,
                          gunTarihi.day,
                          int.parse(appt['bitis'].split(':')[0]),
                          int.parse(appt['bitis'].split(':')[1]),
                        );

                        // Zaman aralıklarının çakışıp çakışmadığını kontrol et
                        if (newStart.isBefore(existingEnd) &&
                            existingStart.isBefore(newEnd)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Bu saatler arasında başka bir randevu var.',
                              ),
                            ),
                          );
                          return; // Çakışma varsa işlemi durdur
                        }
                      }

                      final appointment = {
                        "isimSoyisim": isimController.text,
                        "telefon": telefonController.text,
                        "arac": aracController.text,
                        "tarih": dateController.text,
                        "baslangic": _startTime,
                        "bitis": _endTime,
                        "ucret": ucretController.text,
                        "aciklama": notController.text,
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
    );
  }
}
