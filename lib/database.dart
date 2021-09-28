import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

const String childrenDBFileName = 'children_database.db';
const String childrenDBTableName = 'children';

class Child {
  int? id;
  String name;
  double amountOwed;
  double allowanceAmount;
  String imagePath;

  Child({
    this.id,
    required this.name,
    required this.amountOwed,
    required this.allowanceAmount,
    required this.imagePath,
  });

  Child.fromMap(Map<String, dynamic> res)
      : id = res["id"],
        name = res["name"],
        amountOwed = res["amountOwed"],
        allowanceAmount = res["allowanceAmount"],
        imagePath = res["imageUrl"];

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'amountOwed': amountOwed,
      'allowanceAmount': allowanceAmount,
      'imageUrl': imagePath
    };
  }

  @override
  String toString() {
    return 'Child{id: $id, name: $name, amountOwed: $amountOwed:, imageUrl: $imagePath}';
  }
}

class DBDao {
  // Make it a singleton
  static final DBDao _dbDao = DBDao._internal();
  factory DBDao() {
    return _dbDao;
  }
  DBDao._internal();

  // Make it have a single database instance
  var database;
  _initDatabase() async {
    database = openDatabase(
      join(await getDatabasesPath(), childrenDBFileName),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE children(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, amountOwed FLOAT, allowanceAmount FLOAT, imageUrl TEXT)',
        );
      },
      version: 1,
    );
    return database;
  }

  _getDatabase() async {
    database ??= await _initDatabase();
    return database;
  }

  Future<void> insertChild(Child child) async {
    final db = await _getDatabase();
    await db.insert(
      childrenDBTableName,
      child.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Child>> getChildren() async {
    final db = await _getDatabase();
    final List<Map<String, dynamic>> maps = await db.query(childrenDBTableName);
    return List.generate(maps.length, (i) {
      return Child(
        id: maps[i]['id'],
        name: maps[i]['name'],
        amountOwed: maps[i]['amountOwed'],
        allowanceAmount: maps[i]['allowanceAmount'],
        imagePath: maps[i]['imageUrl'],
      );
    });
  }

  Future<void> updateChild(Child child) async {
    final db = await _getDatabase();
    await db.update(
      childrenDBTableName,
      child.toMap(),
      where: 'id = ?', // Ensure that the Child has a matching id.
      whereArgs: [
        child.id
      ], // Pass the Child's id as a whereArg to prevent SQL injection.
    );
  }

  Future<void> deleteChild(int id) async {
    final db = await _getDatabase();
    await db.delete(
      childrenDBTableName,
      where: 'id = ?', // Use a `where` clause to delete a specific child.
      whereArgs: [id],
    );
  }
}
