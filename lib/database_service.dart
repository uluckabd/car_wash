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
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'appointments.db');
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

  Future<int> addAppointment(Map<String, dynamic> appointment) async {
    final db = await database;
    final normalizedAppointment = _addNormalizedSearchField(appointment);
    return await db.insert('appointments', normalizedAppointment);
  }

  Future<int> updateAppointment(
    int id,
    Map<String, dynamic> appointment,
  ) async {
    final db = await database;
    final normalizedAppointment = _addNormalizedSearchField(appointment);
    return await db.update(
      'appointments',
      normalizedAppointment,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> searchAppointments(String query) async {
    final db = await database;
    final normalizedQuery = _normalizeForSearch(query);

    return await db.query(
      'appointments',
      where: 'normalizedSearch LIKE ?',
      whereArgs: ['%$normalizedQuery%'],
    );
  }

  Future<List<Map<String, dynamic>>> getAppointments() async {
    final db = await database;
    return await db.query('appointments', orderBy: 'tarih ASC');
  }

  Future<int> deleteAppointment(int id) async {
    final db = await database;
    return await db.delete('appointments', where: 'id = ?', whereArgs: [id]);
  }

  // Yardımcı Metotlar

  // Türkçe karakterleri arama için normalleştirme
  String _normalizeForSearch(String text) {
    return text
        .toLowerCase()
        .replaceAll('ç', 'c')
        .replaceAll('ğ', 'g')
        .replaceAll('ı', 'i')
        .replaceAll('ö', 'o')
        .replaceAll('ş', 's')
        .replaceAll('ü', 'u');
  }

  // Kaydedilecek veriye normalleştirilmiş arama alanını ekleme
  Map<String, dynamic> _addNormalizedSearchField(
    Map<String, dynamic> appointment,
  ) {
    final normalizedData = <String, dynamic>{...appointment};

    // Aramak istediğin alanları burada birleştir.
    final combinedText = [
      normalizedData['isimSoyisim'],
      normalizedData['arac'],
      normalizedData['aciklama'],
      normalizedData['gun'],
    ].where((e) => e != null).join(' ');

    normalizedData['normalizedSearch'] = _normalizeForSearch(combinedText);
    return normalizedData;
  }
}
