import 'package:sqflite/sqflite.dart';

/// AUTODOC yerel SQLite veritabanı.
///
/// Windows ve Android aynı şemayı kullanır fakat her cihazın veritabanı
/// tamamen bağımsızdır; senkronizasyon, yedekleme veya dışa aktarma yoktur.
class AppDatabase {
  AppDatabase._(this.db, this.path);

  final Database db;
  final String path;

  static const int schemaVersion = 1;

  /// [factory] null ise sqflite'ın varsayılan (Android) uygulaması kullanılır.
  static Future<AppDatabase> open({
    DatabaseFactory? factory,
    required String path,
  }) async {
    final Database db;
    if (factory != null) {
      db = await factory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: schemaVersion,
          onConfigure: _onConfigure,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
        ),
      );
    } else {
      db = await openDatabase(
        path,
        version: schemaVersion,
        onConfigure: _onConfigure,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    }
    return AppDatabase._(db, path);
  }

  static Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  static Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();
    for (final statement in _schemaV1) {
      batch.execute(statement);
    }
    await batch.commit(noResult: true);
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // İleride şema değişikliklerinde sürüm sürüm göç adımları buraya eklenir.
  }

  Future<void> close() => db.close();

  static const List<String> _schemaV1 = [
    '''
    CREATE TABLE vehicles (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      category TEXT NOT NULL,
      make TEXT NOT NULL,
      model TEXT NOT NULL,
      model_year INTEGER,
      plate TEXT,
      fuel_type TEXT NOT NULL,
      engine TEXT,
      vin TEXT,
      nickname TEXT,
      color TEXT,
      initial_mileage INTEGER CHECK (initial_mileage IS NULL OR initial_mileage >= 0),
      insurance_expiry TEXT,
      inspection_date TEXT,
      photo_path TEXT,
      notes TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
    ''',
    '''
    CREATE TABLE fuel_records (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      vehicle_id INTEGER NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
      date TEXT NOT NULL,
      mileage INTEGER NOT NULL CHECK (mileage >= 0),
      fuel_type TEXT NOT NULL,
      quantity REAL NOT NULL CHECK (quantity > 0),
      unit_price REAL CHECK (unit_price IS NULL OR unit_price >= 0),
      total_cost REAL CHECK (total_cost IS NULL OR total_cost >= 0),
      full_tank INTEGER NOT NULL DEFAULT 0,
      station TEXT,
      note TEXT,
      mileage_source TEXT NOT NULL DEFAULT 'manual',
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
    ''',
    '''
    CREATE TABLE service_records (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      vehicle_id INTEGER NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
      kind TEXT NOT NULL CHECK (kind IN ('maintenance', 'service')),
      date TEXT NOT NULL,
      mileage INTEGER NOT NULL CHECK (mileage >= 0),
      description TEXT NOT NULL,
      workshop TEXT,
      cost REAL CHECK (cost IS NULL OR cost >= 0),
      note TEXT,
      mileage_source TEXT NOT NULL DEFAULT 'manual',
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
    ''',
    '''
    CREATE TABLE settings (
      key TEXT PRIMARY KEY,
      value TEXT
    )
    ''',
    'CREATE INDEX idx_fuel_vehicle_date ON fuel_records(vehicle_id, date)',
    'CREATE INDEX idx_service_vehicle_date ON service_records(vehicle_id, date)',
  ];
}
