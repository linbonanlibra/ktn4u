import 'package:flutter/material.dart';
import 'package:ktn4u/logic/entity/core/specialty.dart';
import 'package:ktn4u/logic/entity/view/recipe_llist.dart';
import '../view/new_specialty.dart'; // 导入新页面

class SpecialtyBook extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _SpecialtyBookState();
}

class _SpecialtyBookState extends State<SpecialtyBook> {
  List<CategoryStat> categories = [];

  List<CategoryStat> _refreshCategories() {
    List<CategoryStat> result = [];
    DishCategoryManager.getCategoryStat().then((stats) => result.addAll(stats));
    return result;
  }

  @override
  void initState() {
    super.initState();
    categories = _refreshCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('菜谱😄'),
      ),
      body: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 3 / 2,
        ),
        itemCount: categories.length + 1,
        itemBuilder: (context, index) {
          if (index == categories.length) {
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => NewSpecialtyPage()), // 修改跳转页面
                ).then((res) => {
                  setState((){
                    categories = _refreshCategories();
                  })
                });
              },
              child: Card(
                color: Colors.grey[200],
                child: Center(
                  child: Icon(Icons.add, size: 50),
                ),
              ),
            );
          } else {
            final category = categories[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RecipeListPage(categoryId: category.id, categoryName: category.name),
                  ),
                );
              },
              child: Card(
                child: Stack(
                  children: [
                    Center(
                      child: Text(category.name),
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: CircleAvatar(
                        radius: 12,
                        child: Text('${category.recipeCount}'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    throw UnimplementedError();
  }
}


