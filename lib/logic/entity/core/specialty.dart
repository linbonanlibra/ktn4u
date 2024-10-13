import 'dart:collection';

void main() {

}

class Dish {
  final int id;
  final String name;
  final String showPic;
  int categoryId = -1;
  Recipe? recipe;
  List<DishRecord>? records;

  Dish(this.id, this.name, this.showPic);
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

class Menu {
  Map<int, List<Dish>> catToDishes = HashMap();

  Map<int, List<Dish>> dishesGroupedByCategory() => catToDishes;

  void addToMenu({required Dish newDish}) {
    List<Dish>? dishes = catToDishes[newDish.categoryId];
    dishes ??= List.empty(growable: true);
    dishes.add(newDish);
  }
}
