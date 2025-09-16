import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:car_wash/database_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

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
  final dateController = TextEditingController();

  final List<String> _timeSlots = List.generate(21, (index) {
    final hour = 8 + (index ~/ 2);
    final minute = (index % 2) * 30;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  });

  final dateMask = MaskTextInputFormatter(
    mask: '##/##/####',
    filter: {"#": RegExp(r'[0-9]')},
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
    isimController.dispose();
    telefonController.dispose();
    aracController.dispose();
    ucretController.dispose();
    notController.dispose();
    dateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? pickedDate = await showCupertinoModalPopup<DateTime>(
      context: context,
      builder: (_) {
        DateTime tempPickedDate = DateTime.now();
        // dateController'da bir tarih varsa onu başlangıç tarihi olarak kullan
        if (dateController.text.isNotEmpty) {
          final parts = dateController.text.split('/');
          if (parts.length == 3) {
            final day = int.tryParse(parts[0]);
            final month = int.tryParse(parts[1]);
            final year = int.tryParse(parts[2]);
            if (day != null && month != null && year != null) {
              tempPickedDate = DateTime(year, month, day);
            }
          }
        }

        return Container(
          height: 275,
          color: Colors.white,
          child: Column(
            children: [
              SizedBox(
                height: 200,
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: tempPickedDate,
                  minimumDate: DateTime(2023),
                  maximumDate: DateTime(2030),
                  onDateTimeChanged: (DateTime newDate) {
                    tempPickedDate = newDate;
                  },
                ),
              ),
              CupertinoButton(
                child: const Text('Tamam'),
                onPressed: () => Navigator.of(context).pop(tempPickedDate),
              ),
            ],
          ),
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
    TextEditingController? controller,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    bool readOnly = false,
    Function()? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
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
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
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
    final filteredEndTimes = _startTime == null
        ? _timeSlots
        : _timeSlots.where((t) => t.compareTo(_startTime!) >= 0).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      appBar: AppBar(
        title: Text(
          widget.appointmentData == null ? 'Yeni Randevu' : 'Randevu Güncelle',
          style: const TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFF0101), Color(0xFF90CAF9)],
              begin: Alignment.topLeft,
              end: Alignment.topRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFF0101), Color(0xFF90CAF9)],
            begin: Alignment.topLeft,
            end: Alignment.topRight,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              buildTextField(label: 'İsim Soyisim', controller: isimController),
              buildTextField(
                label: 'Telefon',
                keyboardType: TextInputType.phone,
                controller: telefonController,
              ),
              buildTextField(label: 'Araç Bilgisi', controller: aracController),
              buildTextField(
                label: 'Tarih',
                controller: dateController,
                readOnly: true,
                onTap: () => _selectDate(context),
              ),
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
                      onChanged: (val) {
                        setState(() {
                          _startTime = val;
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
                      items: filteredEndTimes
                          .map(
                            (time) => DropdownMenuItem(
                              value: time,
                              child: Text(time),
                            ),
                          )
                          .toList(),
                      onChanged: (val) => setState(() => _endTime = val),
                    ),
                  ),
                ],
              ),
              buildTextField(
                label: 'Ücret',
                keyboardType: TextInputType.number,
                controller: ucretController,
              ),
              buildTextField(
                label: 'Not',
                maxLines: 3,
                controller: notController,
              ),
              const SizedBox(height: 40),
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

                      final existingAppointments = await DatabaseService()
                          .getAppointmentsByDate(dateController.text);

                      for (var appt in existingAppointments) {
                        if (widget.appointmentData != null &&
                            appt['id'] == widget.appointmentData!['id'])
                          continue;

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

                        if (newStart.isBefore(existingEnd) &&
                            existingStart.isBefore(newEnd)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Bu saatler arasında başka bir randevu var.',
                              ),
                            ),
                          );
                          return;
                        }
                      }

                      // Kaydedilecek randevu
                      final appointment = {
                        "isimSoyisim": isimController.text,
                        "telefon": telefonController.text,
                        "arac": aracController.text,
                        "tarih": dateController.text, // DD/MM/YYYY formatında
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
              SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
