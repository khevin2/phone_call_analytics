import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._(this.db);

  final Database db;

  static Future<AppDatabase> open() async {
    final directory = await getApplicationDocumentsDirectory();
    final dbPath = path.join(directory.path, 'callsense.db');
    final db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (database, version) async {
        await database.execute('''
          CREATE TABLE calls (
            callId INTEGER PRIMARY KEY,
            number TEXT NOT NULL,
            name TEXT,
            type INTEGER NOT NULL,
            timestamp INTEGER NOT NULL,
            durationSec INTEGER NOT NULL,
            simSlot INTEGER NOT NULL,
            subscriptionId INTEGER,
            phoneAccountId TEXT,
            phoneAccountComponentName TEXT,
            createdAt INTEGER NOT NULL
          );
        ''');
        await database.execute(
          'CREATE INDEX idx_calls_timestamp ON calls(timestamp);',
        );
        await database.execute(
          'CREATE INDEX idx_calls_number ON calls(number);',
        );
        await database.execute(
          'CREATE INDEX idx_calls_sim_timestamp ON calls(simSlot, timestamp);',
        );
        await database.execute(
          'CREATE INDEX idx_calls_type ON calls(type);',
        );
      },
    );
    return AppDatabase._(db);
  }
}
