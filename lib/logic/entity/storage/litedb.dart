import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';

import '../core/specialty.dart';

class Storage {

  Future<bool> init() async {
    var dbPath = await getDatabasesPath();

    Database db = await openDatabase('lite_db.db', onCreate: (db, version) {
      return db.execute("CREATE TABLE dish(id integer primary key,name text,showPic text,categoryId integer)");
    },version: 1);

    List<Map<String, Object?>> records =
        await db.rawQuery("Select * from dish");
    print(records);



    return true;
  }
}
