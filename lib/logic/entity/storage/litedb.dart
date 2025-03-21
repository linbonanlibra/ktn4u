import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../core/specialty.dart';

class Storage {
  Future<bool> init() async {
    var dbPath = await getDatabasesPath();
    Database db =
        await openDatabase(join(dbPath, 'lite_db.db'), onCreate: (db, version) {
      return db.execute(
          "CREATE TABLE dish(id integer primary key AUTOINCREMENT,name text,showPic text,categoryId integer, proficiency integer,pics text)");
    }, version: 1);
    return true;
  }

  Future<void> clearAll() async {
    var dbPath = await getDatabasesPath();
    Database db = await openDatabase(join(dbPath, 'lite_db.db'));
    await db.rawDelete('delete from dish');
  }

  Future<void> saveDish(Dish dish) async {
    var dbPath = await getDatabasesPath();
    Database db = await openDatabase(join(dbPath, 'lite_db.db'));

    await db.insert('dish', {
      'name': dish.name,
      'showPic': dish.showPic ?? '',
      'categoryId': dish.categoryId,
      'proficiency': dish.proficiency,
      'pics': dish.pics.isEmpty ? '' : dish.pics.join(','),
    });
  }

  Future<Map<int, int>> countGroupByCate() async {
    var dbPath = await getDatabasesPath();
    Database db = await openDatabase(join(dbPath, 'lite_db.db'));

    List<Map<String, Object?>> result = await db.rawQuery(
        'SELECT categoryId, COUNT(*) as count FROM dish GROUP BY categoryId');

    Map<int, int> countMap = {};
    for (var row in result) {
      countMap[row['categoryId'] as int] = row['count'] as int;
    }
    return countMap;
  }

  Future<List<Dish>> queryDishByCate(int cateId) async {
    var dbPath = await getDatabasesPath();
    Database db = await openDatabase(join(dbPath, 'lite_db.db'));

    List<Map<String, Object?>> records = await db
        .rawQuery('SELECT * FROM dish WHERE categoryId = $cateId order by id');
    List<Dish> result = [];
    for (var record in records) {
      result.add(Dish.parseFromMap(record));
    }
    return result;
  }
}

class DishDO {
  final String name;
  final String description;
  final int categoryId;
  final List<String> images;

  DishDO({
    required this.name,
    required this.description,
    required this.categoryId,
    required this.images,
  });
}
