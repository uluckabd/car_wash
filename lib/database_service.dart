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
    return await openDatabase(path, version: 1, onCreate: _onCreate);
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
        normalizedSearch TEXT
      )
    ''');
  }

  // Randevu ekleme
  Future<int> addAppointment(Map<String, dynamic> appointment) async {
    final db = await database;
    final normalized = _addNormalizedSearchField(appointment);
    return await db.insert('appointments', normalized);
  }

  // Randevu güncelleme
  Future<int> updateAppointment(
    int id,
    Map<String, dynamic> appointment,
  ) async {
    final db = await database;
    final normalized = _addNormalizedSearchField(appointment);
    return await db.update(
      'appointments',
      normalized,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Randevu silme
  Future<int> deleteAppointment(int id) async {
    final db = await database;
    return await db.delete('appointments', where: 'id = ?', whereArgs: [id]);
  }

  // Tüm randevuları çekme
  Future<List<Map<String, dynamic>>> getAppointments() async {
    final db = await database;
    return await db.query('appointments', orderBy: 'tarih ASC');
  }

  // Belirli tarih için randevuları çekme
  Future<List<Map<String, dynamic>>> getAppointmentsByDate(String date) async {
    final db = await database;
    return await db.query(
      'appointments',
      where: 'tarih = ?',
      whereArgs: [date],
    );
  }

  // Belirli ay ve gün için randevuları çekme (DD/MM/YYYY formatına göre)
  Future<List<Map<String, dynamic>>> getAppointmentsByMonthAndDay(
    int month,
    int day,
  ) async {
    final db = await database;
    final monthStr = month.toString().padLeft(2, '0');
    final dayStr = day.toString().padLeft(2, '0');

    return await db.query(
      'appointments',
      where: "substr(tarih,4,2) = ? AND substr(tarih,1,2) = ?",
      whereArgs: [monthStr, dayStr],
    );
  }

  // 🔹 Gelire göre sıralama (artan / azalan)
  Future<List<Map<String, dynamic>>> getAppointmentsSortedByIncome(
    int month,
    bool ascending,
  ) async {
    final db = await database;
    final monthStr = month.toString().padLeft(2, '0');

    return await db.query(
      'appointments',
      where: "substr(tarih,4,2) = ?",
      whereArgs: [monthStr],
      orderBy: "CAST(ucret AS INTEGER) ${ascending ? 'ASC' : 'DESC'}",
    );
  }

  // 🔹 Araç sayısına göre sıralama (Dart tarafında yapılacak)
  Future<List<Map<String, dynamic>>> getAppointmentsGroupedByDay(
    int month,
  ) async {
    final db = await database;
    final monthStr = month.toString().padLeft(2, '0');

    return await db.query(
      'appointments',
      where: "substr(tarih,4,2) = ?",
      whereArgs: [monthStr],
    );
  }

  Future<List<Map<String, dynamic>>> getMonthlySummary() async {
    final db = await database;
    return await db.rawQuery('''
    SELECT 
      substr(tarih, 4, 2) as month, 
      COUNT(arac) as vehicleCount,
      SUM(CAST(ucret AS INTEGER)) as totalAmount
    FROM appointments
    GROUP BY month
    ORDER BY month ASC
  ''');
  }

  // Arama ve normalize alanı
  Map<String, dynamic> _addNormalizedSearchField(
    Map<String, dynamic> appointment,
  ) {
    final normalized = <String, dynamic>{...appointment};
    final combinedText = [
      normalized['isimSoyisim'],
      normalized['arac'],
      normalized['aciklama'],
      normalized['gun'],
    ].where((e) => e != null).join(' ');
    normalized['normalizedSearch'] = combinedText.toLowerCase();
    return normalized;
  }
}
