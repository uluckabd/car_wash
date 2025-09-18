// her yerde kullanacağımız için başlıklara özel style için class olusturup o kullanılacak
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  static TextStyle title = GoogleFonts.lato(
    fontSize: 25,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );
}
