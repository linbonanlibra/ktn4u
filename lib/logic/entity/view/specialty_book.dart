import 'package:flutter/material.dart';
import 'package:ktn4u/logic/entity/core/specialty.dart';
import '../view/new_specialty.dart'; // 导入新页面

class SpecialtyBook extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _SpecialtyBookState();
}

class _SpecialtyBookState extends State<SpecialtyBook> {
  List<DishCategory> categories = [];

  List<DishCategory> _refreshCategories() {
    List<DishCategory> result = [];
    DishCategoryManager.getCategoryStat().then((stats) => result.addAll(
        stats.map((stat) =>
            DishCategory(name: stat.name, recipeCount: stat.recipeCount))));
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
                    builder: (context) => RecipeListPage(category: category),
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

class DishCategory {
  final String name;
  final int recipeCount;

  DishCategory({required this.name, required this.recipeCount});
}

class RecipeListPage extends StatelessWidget {
  final DishCategory category;

  RecipeListPage({required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${category.name} Recipes'),
      ),
      body: Center(
        child: Text('List of recipes for ${category.name}'),
      ),
    );
  }
}
