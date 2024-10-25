import 'package:flutter/material.dart';
import 'package:getwidget/components/list_tile/gf_list_tile.dart';
import 'package:ktn4u/logic/entity/core/specialty.dart';
import 'package:getwidget/getwidget.dart';

class SpecialtyMenu extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _SpecialtyMenuState();
}

class _SpecialtyMenuState extends State<SpecialtyMenu> {
  late Menu menu;
  late int _chosenCategoryId;

  _refreshMenu() {
    //FIXME mock
    menu = Menu();
    menu.addToMenu(newDish: Dish(1, 'test1', 'pci1', 1));
    menu.addToMenu(newDish: Dish(2, 'test2', 'pci2', 1));
    menu.addToMenu(newDish: Dish(3, 'test3', 'pci3', 2));
  }

  int _categoryCount() {
    int? catCount = menu?.catToDishes?.keys.length;
    if (catCount == null) {
      return 0;
    }
    return catCount;
  }

  @override
  void initState() {
    super.initState();
    _refreshMenu();
    _chosenCategoryId = menu.existedCategoryOf(0)?.id ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        Expanded(
            flex: 2,
            child: ListView.builder(
                itemCount: _categoryCount(),
                itemBuilder: (context, index) {
                  DishCategory? chosenCategory = menu.existedCategoryOf(index);
                  return GFListTile(
                    titleText: chosenCategory?.desc ?? '菜品',
                    // icon: Icon(Icons.account_balance_wallet_rounded),
                    onTap: () {
                      setState(() {
                        this._chosenCategoryId = chosenCategory?.id ?? 0;
                      });
                    },
                  );
                })),
        Expanded(
            flex: 5,
            child: ListView(
              children: <Widget>[
                Container(
                  alignment: Alignment.topLeft,
                  color: Colors.red,
                  child: _generateDishList(_chosenCategoryId),
                )
              ],
            ))
      ],
    );
  }

  Widget _generateDishList(int categoryId) {
    List<Dish> dishes = menu.dishesOf(categoryId) ?? List.empty();
    return Wrap(
        spacing: 10.0,
        direction: Axis.horizontal,
        alignment: WrapAlignment.start,
        children: List<Widget>.generate(
                dishes.length, (int index) => _buildDishRow(dishes[index]))
            .toList());
  }

  Widget _buildDishRow(Dish dish) {
    return GFListTile(
        color: Colors.white,
        titleText: dish.name,
        icon: Icon(Icons.play_circle));
  }
}
