import 'package:flutter/material.dart';
import 'package:getwidget/components/list_tile/gf_list_tile.dart';
import 'package:ktn4u/logic/entity/core/specialty.dart';
import 'package:getwidget/getwidget.dart';
import 'package:collection/collection.dart';

class SpecialtyBook extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _SpecialtyBookState();
}

class _SpecialtyBookState extends State<SpecialtyBook> {
  @override
  Widget build(BuildContext context) {
    List<Widget> pageElements = List.empty(growable: true);
    pageElements.addAll(_buildRows());
    pageElements.add(const Spacer());
    pageElements.add(Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SizedBox(
          width: 60,
          height: 60,
          child: FloatingActionButton(
            splashColor: Colors.orange,
            onPressed: () {
              setState(() {
                print("add");
              });
            },
            child: Icon(Icons.add),
          ),
        )
      ],
    ));
    return Column(children: pageElements);
  }

  List<Row> _buildRows() {
    List<DishCategory> categories =
        List.from(DishCategoryManager.getAllCategories(), growable: true);
    // categories.add(DishCategory.EMPTY_CATEGORY); // 固定的 “+”
    // if (categories.length % 2 != 0) {
    //   categories.add(DishCategory.PLACE_HOLDER_CATEGORY);
    // }

    categories.sort((a, b) => a.ordinal.compareTo(b.ordinal));

    return ListSlice(categories, 0, categories.length)
        .slices(2)
        .map((e) => _buildRow(e))
        .toList(growable: true);
  }

  Row _buildRow(List<DishCategory> categories) {
    return Row(
        children: List<Widget>.generate(categories.length, (index) {
      if (DishCategory.EMPTY_CATEGORY.id == categories[index].id) {
        return Expanded(
            flex: 1,
            child: GFListTile(
                color: Colors.white,
                titleText: categories[index].desc,
                icon: Icon(Icons.add_circle)));
      } else if (DishCategory.PLACE_HOLDER_CATEGORY.id ==
          categories[index].id) {
        return Spacer(flex: 1);
      } else {
        return Expanded(
            flex: 1,
            child: GFListTile(
                color: Colors.white,
                titleText: categories[index].desc,
                icon: Icon(Icons.play_circle)));
      }
    }));
  }
}
