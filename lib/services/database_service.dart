import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/document.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('documents.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE documents (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        filePath TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        modifiedAt TEXT,
        category TEXT NOT NULL,
        tags TEXT NOT NULL
      )
    ''');
  }

  Future<String> insertDocument(Document document) async {
    final db = await database;
    await db.insert(
      'documents',
      {
        ...document.toJson(),
        'tags': document.tags.join(','),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return document.id;
  }

  Future<List<Document>> getAllDocuments() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('documents');
    return List.generate(maps.length, (i) {
      final map = maps[i];
      return Document.fromJson({
        ...map,
        'tags': map['tags'].split(','),
      });
    });
  }

  Future<void> updateDocument(Document document) async {
    final db = await database;
    await db.update(
      'documents',
      {
        ...document.toJson(),
        'tags': document.tags.join(','),
      },
      where: 'id = ?',
      whereArgs: [document.id],
    );
  }

  Future<void> deleteDocument(String id) async {
    final db = await database;
    await db.delete(
      'documents',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Document>> searchDocuments(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'documents',
      where: 'title LIKE ? OR description LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
    );
    return List.generate(maps.length, (i) {
      final map = maps[i];
      return Document.fromJson({
        ...map,
        'tags': map['tags'].split(','),
      });
    });
  }

  Future<List<Document>> getDocumentsByCategory(String category) async {
    if (category == 'Tous') return getAllDocuments();
    
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'documents',
      where: 'category = ?',
      whereArgs: [category],
    );
    return List.generate(maps.length, (i) {
      final map = maps[i];
      return Document.fromJson({
        ...map,
        'tags': map['tags'].split(','),
      });
    });
  }
} 