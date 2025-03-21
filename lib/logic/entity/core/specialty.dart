import 'dart:collection';

import '../storage/litedb.dart';

class Dish {
  int? id;
  String? name;
  String? showPic;
  List<String> pics = [];
  int categoryId = -1;
  Recipe? recipe;
  List<DishRecord>? records;
  int? proficiency;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'showPic': showPic,
      'categoryId': categoryId
    };
  }

  Dish(this.name, this.showPic, this.categoryId);

  Dish.initFromMap(Map<String, Object?> map) {
    name = map['name'] as String;
    showPic = map['showPic'] != null ? map['showPic'] as String : null;
    categoryId = map['categoryId'] as int;
    proficiency = map['proficiency'] != null ? map['proficiency'] as int : 0;
  }

  Dish.parseFromMap(Map<String, Object?> map) {
    id = map['id'] as int;
    name = map['name'] as String;
    showPic = map['showPic'] as String;
    categoryId = map['categoryId'] as int;
    proficiency = map['proficiency'] as int;
    pics = (map['pics'] as String).split(',').toList();
  }

  static String defaultPic() {
    return 'assets/ui/default_dish_pic.png';
  }
}

class Recipe {
  // pic and desc
}

class DishRecord {
  final DateTime date;
  List<String>? pics;
  String? comment;

  DishRecord(this.date);
}

class DishCategory {
  int id;
  String name;
  String desc;
  int ordinal;

  DishCategory(this.id, this.name, this.desc, this.ordinal);
}

class CategoryStat {
  final int id;
  final String name;
  final int ordinal;
  final int recipeCount;

  CategoryStat(this.id, this.name, this.ordinal, this.recipeCount);
}

class DishCategoryManager {
  static List<DishCategory> _allCategories = List.empty();
  static Storage localStorage = Storage();

  static List<DishCategory> getAllCategories() {
    if (_allCategories.isEmpty) {
      loadAllCategories();
    }
    return _allCategories;
  }

  static void loadAllCategories() {
    //FIXME mock
    List<DishCategory> categories = [
      DishCategory(1, "肉类", "", 1),
      DishCategory(2, "青菜", "", 2)
    ];

    List<DishCategory> tmpCategories = List.empty(growable: true);
    for (var category in categories) {
      tmpCategories.add(category);
    }
    _allCategories = tmpCategories;
  }

  static Future<List<CategoryStat>> getCategoryStat() async {
    Map<int, int> countMap = await localStorage.countGroupByCate();
    List<CategoryStat> stats = [];
    for (var category in getAllCategories()) {
      int count = countMap[category.id] ?? 0;
      stats.add(
          CategoryStat(category.id, category.name, category.ordinal, count));
    }
    return stats;
  }
}

class Menu {
  late Map<int, DishCategory> allCategories;
  Map<int, List<Dish>> catToDishes = HashMap();

  Menu() {
    _loadAllCategories();
  }

  Map<int, List<Dish>> dishesGroupedByCategory() => catToDishes;

  void addToMenu({required Dish newDish}) {
    List<Dish>? dishes = catToDishes[newDish.categoryId];
    if (dishes == null) {
      dishes = List.empty(growable: true);
      catToDishes[newDish.categoryId] = dishes;
    }
    dishes.add(newDish);
  }

  int categoryCount() {
    int? catCount = catToDishes?.keys.length;
    return catCount ?? 0;
  }

  DishCategory? existedCategoryOf(int index) {
    if (catToDishes == null || index < 0) {
      return null;
    }

    List<DishCategory> categories = List.empty(growable: true);
    for (var catId in catToDishes.keys) {
      DishCategory? category = allCategories[catId];
      if (category != null) {
        categories.add(category);
      }
    }
    categories.sort((a, b) => a.ordinal.compareTo(b.ordinal));
    return categories.elementAtOrNull(index);
  }

  List<Dish>? dishesOf(int categoryId) {
    return catToDishes[categoryId];
  }

  void _loadAllCategories() {
    allCategories = HashMap();
    for (var category in DishCategoryManager.getAllCategories()) {
      allCategories.update(category.id, (value) => category,
          ifAbsent: () => category);
    }
  }
}
