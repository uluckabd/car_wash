import 'package:car_wash/app_ready_package.dart';
import 'package:car_wash/main.dart';
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

  //Belirli bir zaman aralığı içinde, yarım saatlik dilimler halinde sıralı saat listesi oluşturmaya yarar.
  final List<String> _timeSlots = List.generate(21, (index) {
    final hour = 8 + (index ~/ 2); // saat
    final minute = (index % 2) * 30; // dakika
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  });

  //kullanıcıdan girdi alırken tarih formatını zorunlu tutan bir yapı
  final dateMask = MaskTextInputFormatter(
    mask: '##/##/####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  //Günler
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
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          height: 275,

          child: Column(
            children: [
              SizedBox(
                height: 200,
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: tempPickedDate,
                  minimumDate: DateTime(2025),
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
    // Koyu temaya uygun iç dolgu rengi (hafif şeffaf)
    const Color textFieldFillColor = Color.fromRGBO(255, 255, 255, 0.1);
    // Normal durumda kenarlık rengi (hafif şeffaf)
    const Color defaultBorderColor = Color.fromRGBO(255, 191, 0, 0.8);
    // Odaklanıldığında istediğin canlı mavi renk (Focused Color)
    const Color focusedBorderColor = Color(0xFF64B5F6);

    return Container(
      // Form alanları arasındaki dikey boşluk
      margin: const EdgeInsets.symmetric(vertical: 13),
      child: TextField(
        readOnly: readOnly,
        onTap: onTap,
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        maxLines: maxLines,
        // Koyu arka planda okunaklı olması için metin rengi beyaz
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          filled: true,
          fillColor: textFieldFillColor, // Şeffaf iç dolgu
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),

          // NORMAL GÖRÜNÜM: Hafif şeffaf ve yuvarlak kenarlık
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: defaultBorderColor, width: 1.5),
          ),

          // **ODAKLANILMIŞ GÖRÜNÜM:** Canlı Mavi ve Kalın Kenarlık (Focus)
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: focusedBorderColor, width: 2.0),
          ),

          // Varsayılan kenarlık (hata vb.)
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: defaultBorderColor),
          ),
        ),
      ),
    );
  }

  Future<String?> _showTimePicker(
    BuildContext context, {
    String? initial,
    String? minTime,
  }) async {
    final List<int> allHours = List.generate(11, (i) => 8 + i); // 08 - 18
    final List<int> minutes = [0, 30]; // 00, 30

    // State'i yerel olarak yönetmek için final yerine geçici değişken
    int tempSelectedHour = 8;
    int tempSelectedMinute = 0;

    // ... (Initial value set ve MinTime kontrol kısmı aynı kalabilir) ...

    int minHour = 8;
    int minMinute = 0;
    if (minTime != null) {
      final parts = minTime.split(':');
      if (parts.length == 2) {
        minHour = int.tryParse(parts[0]) ?? 8;
        minMinute = int.tryParse(parts[1]) ?? 0;
      }
    }

    // Initial value set (selectedHour ve selectedMinute değerleri minTime kontrolü için önemli)
    if (initial != null) {
      final parts = initial.split(':');
      if (parts.length == 2) {
        tempSelectedHour = int.tryParse(parts[0]) ?? 8;
        tempSelectedMinute = int.tryParse(parts[1]) ?? 0;
      }
    }

    return await showCupertinoModalPopup<String>(
      context: context,
      builder: (BuildContext innerContext) {
        // innerContext kullanımı önemli

        // **StatefulBuilder kullanarak iç durumu yönetelim**
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            // 1. Filtrelenmiş saat listesi
            final List<int> filteredHours = allHours
                .where((h) => h > minHour || (h == minHour && minMinute == 0))
                .toList();

            // 2. Filtreleme sonrası en küçük saatten daha küçük bir saat seçilmişse, onu ayarla
            if (!filteredHours.contains(tempSelectedHour)) {
              // Eğer başlangıç saati minTime'dan küçükse,
              // otomatik olarak izin verilen en küçük saate geç
              tempSelectedHour = filteredHours.first;
            }

            // 3. Başlangıç indeksi, filtrelenmiş listedeki pozisyonuna göre ayarlanmalı
            int initialHourIndex = filteredHours.indexOf(tempSelectedHour);
            if (initialHourIndex == -1) initialHourIndex = 0;

            // 4. Dakika listesi de saat değişimine göre filtrelenecek
            final List<int> filteredMinutes = minutes.where((m) {
              if (tempSelectedHour == minHour) {
                return m >= minMinute;
              }
              return true;
            }).toList();

            // 5. Dakika başlangıç indeksi, filtrelenmiş listedeki pozisyonuna göre ayarlanmalı
            int initialMinuteIndex = filteredMinutes.indexOf(
              tempSelectedMinute,
            );
            if (initialMinuteIndex == -1) initialMinuteIndex = 0;

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              height: 250,

              child: Column(
                children: [
                  SizedBox(
                    height: 180,
                    child: Row(
                      children: [
                        // SAAT ÇARKI
                        Expanded(
                          child: CupertinoPicker(
                            scrollController: FixedExtentScrollController(
                              initialItem:
                                  initialHourIndex, // BURASI DÜZELTİLDİ
                            ),
                            itemExtent: 32,
                            onSelectedItemChanged: (index) {
                              setState(() {
                                tempSelectedHour =
                                    filteredHours[index]; // BURASI DÜZELTİLDİ
                                // Saat değişince dakika kontrolünü tekrar yap
                                if (tempSelectedHour == minHour &&
                                    tempSelectedMinute < minMinute) {
                                  tempSelectedMinute = minMinute;
                                }
                              });
                            },
                            children: filteredHours
                                .map(
                                  (h) => Center(
                                    child: Text(h.toString().padLeft(2, '0')),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                        // DAKİKA ÇARKI
                        Expanded(
                          child: CupertinoPicker(
                            scrollController: FixedExtentScrollController(
                              initialItem:
                                  initialMinuteIndex, // BURASI DÜZELTİLDİ
                            ),
                            itemExtent: 32,
                            onSelectedItemChanged: (index) {
                              tempSelectedMinute =
                                  filteredMinutes[index]; // BURASI DÜZELTİLDİ
                            },
                            children: filteredMinutes
                                .map(
                                  (m) => Center(
                                    child: Text(m.toString().padLeft(2, '0')),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  CupertinoButton(
                    child: const Text("Tamam"),
                    onPressed: () {
                      final formatted =
                          '${tempSelectedHour.toString().padLeft(2, '0')}:${tempSelectedMinute.toString().padLeft(2, '0')}';
                      Navigator.pop(context, formatted);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  final phoneMask = MaskTextInputFormatter(
    // 0'dan sonra 3 hane (alan kodu), sonra 3, sonra 2, sonra 2 hane: 0(5XX) XXX XX XX
    mask: '0 (###) ### ## ##',
    filter: {"#": RegExp(r'[0-9]')}, // # yerine sadece rakam girilebilir
  );

  @override
  Widget build(BuildContext context) {
    final filteredEndTimes = _startTime == null
        ? _timeSlots
        : _timeSlots.where((t) => t.compareTo(_startTime!) >= 0).toList();

    return Scaffold(
      // Sayfa içeriğinin (gradient'in) alt navigasyon çubuğunun arkasına kadar uzamasını sağlar.
      extendBody: true,
      // darkBlue değişkenini Color(0xFF1B2A38) olarak varsaydık
      backgroundColor: const Color(0xFF1B2A38),

      appBar: AppBar(
        centerTitle: true,
        backgroundColor: const Color(0xFF1B2A38),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.appointmentData == null ? 'Yeni Randevu' : 'Randevu Güncelle',
          style: const TextStyle(color: Colors.white),
        ),
      ),

      // body'i Container ile sarıp gradient arka plan ekliyoruz
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF1B2A38), // darkBlue
              Color(0xFF1F3249), // Koyu alt ton
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),

        // Tüm formu ListView içine alarak kaydırma ve dinamik boşluk yönetimi sağlıyoruz
        child: ListView(
          primary: true,
          // Yatay padding'i koruyup, dikeyde dinamik alt boşluk sağlıyoruz
          padding: EdgeInsets.fromLTRB(
            16,
            16, // Üst boşluk
            16,
            // En önemli kısım: Alt sistem çubuğu (navigasyon) boşluğunu ekliyoruz.
            MediaQuery.of(context).viewPadding.bottom + 16,
          ),
          children: [
            // Form alanları (buildTextField metodu eski haliyle kalıyor)
            buildTextField(label: 'İsim Soyisim', controller: isimController),
            buildTextField(
              label: 'Telefon',
              keyboardType: TextInputType.phone,
              controller: telefonController,
              inputFormatters: [phoneMask],
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
                  child: buildTextField(
                    label: "Başlangıç Saati",
                    readOnly: true,
                    controller: TextEditingController(text: _startTime ?? ""),
                    onTap: () async {
                      // Veri mantığı olduğu gibi kalıyor
                      final result = await _showTimePicker(
                        context,
                        initial: _startTime,
                        minTime: '08:00',
                      );
                      if (result != null) {
                        setState(() {
                          _startTime = result;
                          if (_endTime != null &&
                              _endTime!.compareTo(_startTime!) < 0) {
                            _endTime = null;
                          }
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: buildTextField(
                    label: "Bitiş Saati",
                    readOnly: true,
                    controller: TextEditingController(text: _endTime ?? ""),
                    onTap: () async {
                      // Veri mantığı olduğu gibi kalıyor
                      final result = await _showTimePicker(
                        context,
                        initial: _endTime,
                        minTime: _startTime,
                      );
                      if (result != null) {
                        setState(() {
                          _endTime = result;
                        });
                      }
                    },
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

            // Butonlar
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        // Vazgeç butonu rengini temaya uyumlu yaptık
                        backgroundColor: Colors.blueGrey.shade700,
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
                        // darkBlue'ya tezat renk
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        // Kaydetme mantığı olduğu gibi kalıyor
                        if (_startTime == null || _endTime == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Lütfen başlangıç ve bitiş saatini seçin',
                              ),
                              backgroundColor: darkBlue,
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
                                backgroundColor: darkBlue,
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
                        // Kaydet butonu için canlı mavi (önceki odak rengi) kullandık
                        backgroundColor: const Color.fromRGBO(255, 191, 0, 1.0),
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
                        style: TextStyle(
                          color: Color(0xFF1B2A38),
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
