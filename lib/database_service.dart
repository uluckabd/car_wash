import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'appointments.db');

    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE appointments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        isimSoyisim TEXT,
        telefon TEXT,
        arac TEXT,
        tarih TEXT,
        baslangic TEXT,
        bitis TEXT,
        ucret TEXT,
        aciklama TEXT,
        gun TEXT,
        adres TEXT,
        normalizedSearch TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE appointments ADD COLUMN adres TEXT');
    }
    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE appointments ADD COLUMN normalizedSearch TEXT',
      );
    }
  }

  // 🔹 Türkçe karakterleri UTF-8 olarak encode et
  Map<String, dynamic> _encodeTurkish(Map<String, dynamic> data) {
    final encoded = <String, dynamic>{};
    data.forEach((key, value) {
      if (value is String) {
        encoded[key] = utf8.decode(utf8.encode(value));
      } else {
        encoded[key] = value;
      }
    });
    return encoded;
  }

  // 🔹 Veritabanına kaydederken normalize et + UTF-8 encode et
  Future<int> addAppointment(Map<String, dynamic> appointment) async {
    final db = await database;
    final normalized = _addNormalizedSearchField(_encodeTurkish(appointment));
    return await db.insert('appointments', normalized);
  }

  Future<int> updateAppointment(
    int id,
    Map<String, dynamic> appointment,
  ) async {
    final db = await database;
    final normalized = _addNormalizedSearchField(_encodeTurkish(appointment));
    return await db.update(
      'appointments',
      normalized,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAppointment(int id) async {
    final db = await database;
    return await db.delete('appointments', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getAppointments() async {
    final db = await database;
    final result = await db.query('appointments', orderBy: 'tarih ASC');
    return result.map(_decodeTurkish).toList();
  }

  Future<List<Map<String, dynamic>>> getAppointmentsByDate(String date) async {
    final db = await database;
    final result = await db.query(
      'appointments',
      where: 'tarih = ?',
      whereArgs: [date],
    );
    return result.map(_decodeTurkish).toList();
  }

  Future<List<Map<String, dynamic>>> getAppointmentsByMonthAndDay(
    int month,
    int day,
  ) async {
    final db = await database;
    final monthStr = month.toString().padLeft(2, '0');
    final dayStr = day.toString().padLeft(2, '0');
    final result = await db.query(
      'appointments',
      where: "substr(tarih,4,2) = ? AND substr(tarih,1,2) = ?",
      whereArgs: [monthStr, dayStr],
    );
    return result.map(_decodeTurkish).toList();
  }

  Future<List<Map<String, dynamic>>> getAppointmentsSortedByIncome(
    int month,
    bool ascending,
  ) async {
    final db = await database;
    final monthStr = month.toString().padLeft(2, '0');
    final result = await db.query(
      'appointments',
      where: "substr(tarih,4,2) = ?",
      whereArgs: [monthStr],
      orderBy: "CAST(ucret AS INTEGER) ${ascending ? 'ASC' : 'DESC'}",
    );
    return result.map(_decodeTurkish).toList();
  }

  Future<List<Map<String, dynamic>>> getAppointmentsGroupedByDay(
    int month,
  ) async {
    final db = await database;
    final monthStr = month.toString().padLeft(2, '0');
    final result = await db.query(
      'appointments',
      where: "substr(tarih,4,2) = ?",
      whereArgs: [monthStr],
    );
    return result.map(_decodeTurkish).toList();
  }

  Future<List<Map<String, dynamic>>> getMonthlySummary() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT 
        substr(tarih, 4, 2) as month, 
        COUNT(arac) as vehicleCount,
        SUM(CAST(ucret AS INTEGER)) as totalAmount
      FROM appointments
      GROUP BY month
      ORDER BY month ASC
    ''');
    return result.map(_decodeTurkish).toList();
  }

  // 🔹 Veritabanından çekilen verileri UTF-8 decode et
  Map<String, dynamic> _decodeTurkish(Map<String, dynamic> row) {
    final decoded = <String, dynamic>{};
    row.forEach((key, value) {
      if (value is String) {
        decoded[key] = utf8.decode(utf8.encode(value));
      } else {
        decoded[key] = value;
      }
    });
    return decoded;
  }

  Map<String, dynamic> _addNormalizedSearchField(
    Map<String, dynamic> appointment,
  ) {
    final normalized = <String, dynamic>{...appointment};
    final combinedText = [
      normalized['isimSoyisim'],
      normalized['arac'],
      normalized['aciklama'],
      normalized['gun'],
      normalized['adres'],
    ].where((e) => e != null).join(' ');
    normalized['normalizedSearch'] = combinedText.toLowerCase();
    return normalized;
  }
}
