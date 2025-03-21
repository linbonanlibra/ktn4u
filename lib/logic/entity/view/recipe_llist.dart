import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../storage/litedb.dart';
import 'package:ktn4u/logic/entity/core/specialty.dart';

class RecipeListPage extends StatefulWidget {
  final int categoryId;
  final String categoryName;

  const RecipeListPage({Key? key, required this.categoryId, required this.categoryName}) : super(key: key);

  @override
  _RecipeListPageState createState() => _RecipeListPageState();
}

class _RecipeListPageState extends State<RecipeListPage> {
  late Future<List<Dish>> _dishes;

  @override
  void initState() {
    super.initState();
    final storage = Storage();
    _dishes = storage.queryDishByCate(widget.categoryId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
      ),
      body: FutureBuilder<List<Dish>>(
        future: _dishes,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            return StaggeredGridView.countBuilder(
              crossAxisCount: 4,
              itemCount: snapshot.data!.length,
              itemBuilder: (BuildContext context, int index) =>
                  _buildDishItem(snapshot.data![index]),
              staggeredTileBuilder: (int index) => StaggeredTile.fit(2),
              mainAxisSpacing: 4.0,
              crossAxisSpacing: 4.0,
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  Widget _buildDishItem(Dish dish) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Image.network(
            dish.showPic ?? Dish.defaultPic(),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                Icon(Icons.broken_image),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(dish.name ?? '无名', style: TextStyle(fontSize: 16.0)),
          ),
          LinearProgressIndicator(
            value: (dish.proficiency ?? 0) / 100,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
          ),
        ],
      ),
    );
  }
}
