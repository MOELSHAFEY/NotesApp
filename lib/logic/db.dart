import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sql/models/note.dart';

class DatabaseHelper {
  static const String _databaseName = 'my_database1.db';
  static const int _databaseVersion = 1;
  static const String _tableName = 'notes';
  
  // Singleton pattern implementation
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final String databasesPath = await getDatabasesPath();
    return await openDatabase(
      join(databasesPath, _databaseName),
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
    CREATE TABLE $_tableName (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      content TEXT NOT NULL
    )
    ''');
  }

  // Add note
  Future<int> insertNote(Map<String, dynamic> note) async {
    final db = await database;
    return await db.insert(_tableName, note);
  }

  // Get all notes
  Future<List<Note>> getNotes() async {
    final db = await database;
    List<Map<String, dynamic>> maps = await db.query(_tableName);
    return List.generate(maps.length, (index) => Note.fromMap(maps[index]));
  }

  // Delete note
  Future<int> deleteNote(int id) async {
    final db = await database;
    return await db.delete(
      _tableName, 
      where: 'id = ?', 
      whereArgs: [id]
    );
  }

  // Update note 
  Future<int> updateNotes(Note note) async {
    final db = await database;
    return await db.update(
      _tableName,
      note.toMap(),
      where: 'id = ?',         
      whereArgs: [note.id],    
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}