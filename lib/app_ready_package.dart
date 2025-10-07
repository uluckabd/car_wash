// her yerde kullanacağımız için başlıklara özel style için class olusturup o kullanılacak
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// app bar başlıkları için kullandığımız paket

class AppTextStyles {
  static TextStyle title = GoogleFonts.lato(
    fontSize: 25,
    fontWeight: FontWeight.bold,

    wordSpacing: 2,
    letterSpacing: 1,
  );
}

// Uygulama arka planı için kullandığımız paket
class Appcolor extends StatelessWidget {
  const Appcolor({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white, // Arka planı düz beyaza ayarlandı
      ),
      // Alternatif olarak:
      // color: Colors.white, // Decoration kullanmadan da direkt Container'a renk verebilirsin
    );
  }
}
