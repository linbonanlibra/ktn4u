import 'dart:collection';

class Dish {
  final int id;
  final String name;
  final String showPic;
  int categoryId = -1;
  Recipe? recipe;
  List<DishRecord>? records;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'showPic': showPic,
      'categoryId': categoryId
    };
  }

  Dish(this.id, this.name, this.showPic, this.categoryId);
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
  String desc;
  int ordinal;

  DishCategory(this.id, this.desc, this.ordinal);
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
    //FIXME mock

    List<DishCategory> categories = [
      DishCategory(1, "肉类", 1),
      DishCategory(2, "青菜", 2)
    ];
    allCategories = HashMap();
    for (var category in categories) {
      allCategories.update(category.id, (value) => category,
          ifAbsent: () => category);
    }
  }
}
