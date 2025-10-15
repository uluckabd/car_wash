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
  // 1. ADIM: FormState'i yönetmek için GlobalKey oluşturuldu.
  final _formKey = GlobalKey<FormState>();

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
    "Perşamba",
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
        // Tarih seçildikten sonra formu yeniden doğrulamak için (opsiyonel)
        _formKey.currentState?.validate();
      });
    }
  }

  // >>>>>>>>>>>>>>>>>>>>>>>>>>> TEXTFORMFIELD WIDGET'I <<<<<<<<<<<<<<<<<<<<<<<<<<<
  Widget buildTextFormField({
    required String label,
    TextInputType keyboardType = TextInputType.text,
    TextEditingController? controller,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    bool readOnly = false,
    Function()? onTap,
    required String? Function(String?)? validator,
    String? hintText,
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
      child: TextFormField(
        autovalidateMode: AutovalidateMode.disabled,
        // <<< TEXTFORMFIELD KULLANILDI
        readOnly: readOnly,
        onTap: onTap,
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        maxLines: maxLines,
        validator: validator, // <<< VALIDATOR ATANDI
        // Koyu arka planda okunaklı olması için metin rengi beyaz
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey),
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          // Hata metni rengini daha belirgin yaptık
          errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 13),
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

          // Varsayılan kenarlık
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: defaultBorderColor),
          ),
          // Hata kenarlığı rengi (validation başarısız olduğunda)
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 2.0),
          ),
        ),
      ),
    );
  }
  // <<<<<<<<<<<<<<<<<<<<<<<<<<< TEXTFORMFIELD WIDGET'I SONU <<<<<<<<<<<<<<<<<<<<<<<<<<<

  // >>>>>>>>>>>>>>>>>>>>>>>>>>> ZAMAN SEÇİCİ FONKSİYONU <<<<<<<<<<<<<<<<<<<<<<<<<<<
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
        return SafeArea(
          top: false,
          bottom: true,
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              // 1. Filtrelenmiş saat listesi
              final List<int> filteredHours = allHours
                  .where(
                    (h) => h > minHour || (h == minHour && minMinute <= 30),
                  ) // minMinute 0 veya 30 olabilir
                  .toList();

              // 2. Eğer başlangıç saati kısıtlamadan önce seçilmişse ve kısıtlamaya aykırıysa, en küçük geçerli saate ayarla
              if (filteredHours.isNotEmpty &&
                  !filteredHours.contains(tempSelectedHour)) {
                tempSelectedHour = filteredHours.first;
                // Saati de güncelleyince dakikayı minimuma çek (ancak o saatteki en küçük geçerli dakikaya)
                if (tempSelectedHour == minHour) {
                  tempSelectedMinute = minMinute;
                } else {
                  tempSelectedMinute = 0;
                }
              } else if (filteredHours.isEmpty) {
                // Eğer seçilebilecek saat yoksa
                // 18:00'dan sonra başlanıyorsa, boş dönmeli.
                return Container();
              }

              // Eğer saat, minimum saate eşitse ve seçili dakika hala kısıtlamanın altındaysa
              if (tempSelectedHour == minHour &&
                  tempSelectedMinute < minMinute) {
                tempSelectedMinute = minMinute;
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
              // Bulamazsa ve liste boş değilse ilk öğeyi seç
              if (initialMinuteIndex == -1 && filteredMinutes.isNotEmpty)
                initialMinuteIndex = 0;
              if (initialMinuteIndex < 0) initialMinuteIndex = 0;

              // Seçilen dakikanın filtreye uymaması durumunda, en yakın geçerli dakikaya zorlama (çarkı kaydırır)
              if (!filteredMinutes.contains(tempSelectedMinute)) {
                if (filteredMinutes.isNotEmpty) {
                  tempSelectedMinute = filteredMinutes.first;
                } else {
                  tempSelectedMinute = 0;
                }
                // initialMinuteIndex'i tekrar hesapla
                initialMinuteIndex = filteredMinutes.indexOf(
                  tempSelectedMinute,
                );
              }
              if (initialMinuteIndex < 0) initialMinuteIndex = 0;

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
                                    // Dakikayı minimum dakikaya sıfırla.
                                    tempSelectedMinute = minMinute;
                                  } else if (tempSelectedHour > minHour) {
                                    // Minimum saatin üzerindeyken dakikayı 0'a çek (opsiyonel ama tutarlılık sağlar)
                                    tempSelectedMinute = 0;
                                  }

                                  // Bitiş saati seçimi için ek kontrol: Eğer başlangıç saati 18:30 ise
                                  // bitiş saati 19:00 olamaz.
                                  // Bu kontrolü burada yapmaya gerek yok, çünkü saat listesi 18:00'da bitiyor (11 element).
                                  // 18:00'da 00 dakika varsa sorun yok.
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
                              // Saat değiştiğinde initialMinuteIndex'i doğru hesaplamak için FixedExtentScrollController'ı
                              // burada kullanmıyoruz. ListView rebuild olduğunda çark otomatik olarak doğru pozisyona gelecektir.
                              itemExtent: 32,
                              // Dakika listesi değişebilir, bu yüzden children'ı filteredMinutes'a bağladık
                              scrollController: FixedExtentScrollController(
                                initialItem: initialMinuteIndex,
                              ),
                              onSelectedItemChanged: (index) {
                                setState(() {
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
          ),
        );
      },
    );
  }
  // <<<<<<<<<<<<<<<<<<<<<<<<<<< ZAMAN SEÇİCİ FONKSİYONU SONU >>>>>>>>>>>>>>>>>>>>>>>>>>>

  final phoneMask = MaskTextInputFormatter(
    // 0'dan sonra 3 hane (alan kodu), sonra 3, sonra 2, sonra 2 hane: 0(5XX) XXX XX XX
    mask: '0 (###) ### ## ##',
    filter: {"#": RegExp(r'[0-9]')}, // # yerine sadece rakam girilebilir
  );

  @override
  Widget build(BuildContext context) {
    // Bu kısım randevunun çakışma kontrolü için.
    final filteredEndTimes = _startTime == null
        ? _timeSlots
        : _timeSlots.where((t) => t.compareTo(_startTime!) >= 0).toList();

    return Scaffold(
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

        // 2. ADIM: Form widget'ı ile sarıldı
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.disabled,
          // GlobalKey atandı
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
              // 3. ADIM: buildTextFormField kullanıldı ve validator'lar eklendi
              buildTextFormField(
                label: 'İsim Soyisim',
                controller: isimController,
                hintText: "Örn: Abdullah ULUCAK",

                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen isim ve soyisim giriniz.';
                  }
                  return null;
                },
              ),
              buildTextFormField(
                label: 'Telefon',
                keyboardType: TextInputType.phone,
                controller: telefonController,
                inputFormatters: [phoneMask],
                hintText: "Örn: (5xx) xxx xx xx",
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen telefon numarasını giriniz.';
                  }

                  // Gelen metinden (value), maske ve formatlama karakterlerini temizle
                  // (parantez, boşluk, tire vb. tüm rakam olmayanları kaldır)
                  final unmaskedValue = value.replaceAll(RegExp(r'\D'), '');

                  if (unmaskedValue.length != 11) {
                    // Artık doğrudan temizlenmiş metnin uzunluğunu kontrol ediyoruz
                    return 'Telefon numarası eksik.  (Şu an ${unmaskedValue.length} hane)';
                  }

                  // NOT: Eğer `phoneMask.getUnmaskedText()` metodu senin için kritikse,
                  // (örneğin kaydederken bunu kullanıyorsan), o metodu çağırıp sonucunu
                  // kontrol etmek yerine, bu RegEx yöntemiyle kontrol etmek validator için daha güvenlidir.

                  // Orijinal maske kontrolünü SİLİYORUZ (ya da yoruma alıyoruz):
                  /*
    if (phoneMask.getUnmaskedText().length != 10) { 
      return 'Telefon numarası eksik.'; 
    }
    */

                  return null;
                },
              ),
              buildTextFormField(
                label: 'Araç Bilgisi',
                controller: aracController,
                hintText: "Örn: BMW",
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen araç bilgisini giriniz.';
                  }
                  return null;
                },
              ),
              buildTextFormField(
                label: 'Tarih',
                controller: dateController,
                readOnly: true,
                onTap: () => _selectDate(context),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen bir tarih seçiniz.';
                  }
                  return null;
                },
              ),
              Row(
                children: [
                  Expanded(
                    child: buildTextFormField(
                      label: "Başlangıç Saati",
                      readOnly: true,
                      // TextEditingController'a _startTime'ı atadık
                      controller: TextEditingController(text: _startTime ?? ""),
                      validator: (value) {
                        if (_startTime == null) {
                          return 'Saat seçin';
                        }
                        return null;
                      },
                      onTap: () async {
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
                          // Saati seçince bitiş saatini de doğrula
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: buildTextFormField(
                      label: "Bitiş Saati",
                      readOnly: true,
                      // TextEditingController'a _endTime'ı atadık
                      controller: TextEditingController(text: _endTime ?? ""),
                      validator: (value) {
                        if (_endTime == null) {
                          return 'Saat seçin';
                        }
                        if (_startTime == null) {
                          return 'Başlangıç saatini seçin';
                        }
                        // Bitiş saati başlangıç saatinden kesinlikle büyük olmalı
                        if (_endTime!.compareTo(_startTime!) <= 0) {
                          return 'Geçersiz saat aralığı.';
                        }
                        return null;
                      },
                      onTap: () async {
                        // minTime: _startTime ile bitiş saatini başlangıç saatine kısıtlıyoruz
                        final result = await _showTimePicker(
                          context,
                          initial: _endTime,
                          minTime:
                              _startTime ??
                              '08:00', // Başlangıç seçilmediyse 08:00 min olsun
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

              buildTextFormField(
                label: 'Ücret',
                keyboardType: TextInputType.number,
                hintText: "Örn: 2500",
                controller: ucretController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return null;
                  }
                  if (double.tryParse(value.replaceAll(',', '.')) == null) {
                    return 'Geçerli bir sayı giriniz.';
                  }
                  return null;
                },
              ),
              buildTextFormField(
                label: 'Not',
                maxLines: 3,
                hintText: "Örn: iç dış yıkama ",
                controller: notController,
                validator: (value) {
                  // Not zorunlu değil
                  return null;
                },
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
                          // 4. ADIM: Kaydetmeden önce tüm formu doğrula
                          if (_formKey.currentState!.validate()) {
                            // Ek olarak saatlerin seçilip seçilmediğini (ve saat validator'larının hata vermediğini) kontrol et
                            if (_startTime == null || _endTime == null) {
                              // Bu kontrol, TextFormField validator'ları sayesinde zaten yakalanmalı, ama ek güvenlik
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

                            // Randevu çakışma kontrolü... (Kodun geri kalanı)
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

                              // Çakışma kontrolü: [newStart, newEnd) ve [existingStart, existingEnd)
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

                            // Doğrulama başarılıysa randevuyu kaydet
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
                          } else {
                            // Doğrulama başarısız olursa kullanıcıya geri bildirim ver
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Lütfen formdaki eksik veya hatalı alanları doldurunuz.',
                                ),
                                backgroundColor: darkBlue,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          // Kaydet butonu için canlı sarı/turuncu rengi kullandık
                          backgroundColor: const Color.fromRGBO(
                            255,
                            191,
                            0,
                            1.0,
                          ),
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
      ),
    );
  }
}
