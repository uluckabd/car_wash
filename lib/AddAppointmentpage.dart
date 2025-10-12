import 'package:car_wash/app_ready_package.dart';
import 'package:car_wash/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:car_wash/database_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// darkBlue değişkeninin Color(0xFF1B2A38) olduğunu varsayıyoruz.
const darkBlue = Color(0xFF1B2A38);

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
    final hour = 8 + (index ~/ 2); // saat (08:00'dan başlar)
    final minute = (index % 2) * 30; // dakika (00 veya 30)
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
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          // Yüksekliği Tamam butonu için yer açacak şekilde küçülttük
          height: 250,
          child: Column(
            children: [
              // YENİ TAMAM BUTONU KONUMU (Sağ Üst Köşe)
              Row(
                mainAxisAlignment: MainAxisAlignment.end, // Sağa yasla
                children: [
                  CupertinoButton(
                    // Padding'i daha kompakt bir görünüm için ayarladık
                    padding: const EdgeInsets.only(
                      right: 15.0,
                      top: 4.0,
                      bottom: 4.0,
                      left: 8.0,
                    ),
                    child: const Text(
                      'Bitti',
                      // Font boyutunu saat seçici ile uyumlu yaptık
                      style: TextStyle(
                        color: darkBlue,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(tempPickedDate),
                  ),
                ],
              ),

              // TARİH ÇARKI (Kalan alanı doldurması için Expanded ile sardık)
              Expanded(
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

  // >>>>>>>>>>>>>>>>>>>>>>>>>>> DÜZELTİLMİŞ ZAMAN SEÇİCİ FONKSİYONU <<<<<<<<<<<<<<<<<<<<<<<<<<<
  Future<String?> _showTimePicker(
    BuildContext context, {
    String? initial,
    String? minTime,
  }) async {
    final List<int> allHours = List.generate(11, (i) => 8 + i); // 08 - 18
    final List<int> minutes = [0, 30]; // 00, 30

    // State'i yerel olarak yönetmek için geçici değişkenler
    int tempSelectedHour = 8;
    int tempSelectedMinute = 0;

    int minHour = 8;
    int minMinute = 0;
    if (minTime != null) {
      final parts = minTime.split(':');
      if (parts.length == 2) {
        minHour = int.tryParse(parts[0]) ?? 8;
        minMinute = int.tryParse(parts[1]) ?? 0;
      }
    }

    // Initial value set
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
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            // 1. Filtrelenmiş saat listesi
            // minTime'dan büyük saatleri veya minTime'ın saat kısmını alır.
            final List<int> filteredHours = allHours
                .where((h) => h > minHour || (h == minHour && minMinute == 0))
                .toList();

            // 2. Eğer başlangıç saati kısıtlamadan önce seçilmişse ve kısıtlamaya aykırıysa, en küçük geçerli saate ayarla
            if (!filteredHours.contains(tempSelectedHour)) {
              tempSelectedHour = filteredHours.first;
            }

            // 3. Başlangıç indeksi
            int initialHourIndex = filteredHours.indexOf(tempSelectedHour);
            if (initialHourIndex == -1) initialHourIndex = 0;

            // 4. Dakika listesi
            final List<int> filteredMinutes = minutes.where((m) {
              if (tempSelectedHour == minHour) {
                // Eğer seçilen saat, minimum saate eşitse, minimum dakikadan büyük veya eşit dakikaları göster.
                return m >= minMinute;
              }
              // Aksi takdirde (minimum saatten büyükse), tüm dakikaları göster.
              return true;
            }).toList();

            // 5. Dakika başlangıç indeksi
            int initialMinuteIndex = filteredMinutes.indexOf(
              tempSelectedMinute,
            );
            if (initialMinuteIndex == -1) initialMinuteIndex = 0;
            if (initialMinuteIndex < 0) initialMinuteIndex = 0;
            // Not: Bitiş saatini seçerken başlangıç saati ile aynı saati ve dakikayı seçtiğinde initialMinuteIndex'in -1 olmasını önlemek için,
            // başlangıç saatini geçtikten sonra minMinute = 0 yapılır. Ancak mevcut filtreleme doğru.

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              // Yüksekliği Tamam butonu için yer açacak şekilde biraz artırıyoruz
              height: 250,

              child: Column(
                children: [
                  // YENİ BAŞLIK VE TAMAM BUTONU
                  Padding(
                    // Sağ üstte boşluk bırakmak için
                    padding: const EdgeInsets.only(right: 8.0, top: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end, // Sağa yasla
                      children: [
                        CupertinoButton(
                          child: const Text(
                            "Bitti",
                            style: TextStyle(color: darkBlue, fontSize: 20),
                          ),
                          onPressed: () {
                            final formatted =
                                '${tempSelectedHour.toString().padLeft(2, '0')}:${tempSelectedMinute.toString().padLeft(2, '0')}';
                            Navigator.pop(context, formatted);
                          },
                        ),
                      ],
                    ),
                  ),

                  // SAAT VE DAKİKA ÇARKLARI
                  Expanded(
                    // Kalan alanı doldur
                    child: Row(
                      children: [
                        // SAAT ÇARKI
                        Expanded(
                          child: CupertinoPicker(
                            scrollController: FixedExtentScrollController(
                              initialItem: initialHourIndex,
                            ),
                            itemExtent: 32,
                            onSelectedItemChanged: (index) {
                              setState(() {
                                tempSelectedHour = filteredHours[index];

                                // Saat değişince dakika kontrolünü tekrar yap
                                if (tempSelectedHour == minHour &&
                                    tempSelectedMinute < minMinute) {
                                  // Eğer yeni seçilen saat, minimum saate eşitse
                                  // ve seçili dakika hala minimum dakikadan küçükse,
                                  // dakikayı minimum dakikaya sıfırla.
                                  tempSelectedMinute = minMinute;
                                } else if (tempSelectedHour < minHour) {
                                  // Bu kısım teorik olarak filteredHours sayesinde çalışmayacak,
                                  // ancak güvenlik amaçlı burada bırakılabilir.
                                  tempSelectedHour = minHour;
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
                              initialItem: initialMinuteIndex,
                            ),
                            itemExtent: 32,
                            onSelectedItemChanged: (index) {
                              setState(() {
                                // setState içinde çağırmalısın ki, saat çarkı değişince dakika çarkı da güncellensin.
                                tempSelectedMinute = filteredMinutes[index];
                              });
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
                ],
              ),
            );
          },
        );
      },
    );
  }
  // <<<<<<<<<<<<<<<<<<<<<<<<<<< DÜZELTİLMİŞ ZAMAN SEÇİCİ FONKSİYONU SONU >>>>>>>>>>>>>>>>>>>>>>>>>>>

  final phoneMask = MaskTextInputFormatter(
    // 0'dan sonra 3 hane (alan kodu), sonra 3, sonra 2, sonra 2 hane: 0(5XX) XXX XX XX
    mask: '0 (###) ### ## ##',
    filter: {"#": RegExp(r'[0-9]')}, // # yerine sadece rakam girilebilir
  );

  @override
  Widget build(BuildContext context) {
    // Bu kısım randevunun çakışma kontrolü için. Kodu olduğu gibi bıraktık.
    final filteredEndTimes = _startTime == null
        ? _timeSlots
        : _timeSlots.where((t) => t.compareTo(_startTime!) >= 0).toList();

    return Scaffold(
      // Sayfa içeriğinin (gradient'in) alt navigasyon çubuğunun arkasına kadar uzamasını sağlar.
      extendBody: true,
      backgroundColor: darkBlue,

      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        backgroundColor: Colors.transparent,
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
            // Koyu mavinin tonları
            colors: [
              Color(0xFF1B2A38), // Üst kısım (Daha Koyu Lacivert)
              Color(0xFF1F3249), // Alt kısım (Biraz daha açık Lacivert/Mavi)
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),

        // Tüm formu ListView içine alarak kaydırma ve dinamik boşluk yönetimi sağlıyoruz
        child: ListView(
          primary: true,
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(context).viewInsets.bottom +
                MediaQuery.of(context).padding.bottom +
                16,
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
                          // Eğer bitiş saati başlangıç saatinden küçük kalırsa sıfırla
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
                      // minTime: _startTime ile bitiş saatini başlangıç saatine kısıtlıyoruz
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

                        // DatabaseService() kısmını kullanabilmen için DatabaseService sınıfının olması gerekir.
                        // Eğer yoksa bu kısım hata verir.
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
                        // Kaydet butonu için canlı sarı/turuncu rengi kullandık
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
                        style: TextStyle(color: darkBlue, fontSize: 16),
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
