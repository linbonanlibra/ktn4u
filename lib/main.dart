import 'package:flutter/material.dart';
import 'package:ktn4u/logic/entity/storage/litedb.dart';
import 'package:getwidget/getwidget.dart';
import 'package:ktn4u/logic/entity/view/specialty_menu.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  late TabController _tabController;
  String title = "ktn4u";

  void _changeTab(int index) {
    setState(() {
      Tab currentTab = tabs[_tabController.index];

      if (currentTab.child is Text){
        Text title = currentTab.child as Text;
        this.title = title.data!;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      _changeTab(_tabController.index);
    });
    _changeTab(_tabController.index);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GFAppBar(title: Text(title)),
      body: GFTabBarView(controller: _tabController, children: [
        SpecialtyMenu(),
        Container(
          child: Icon(Icons.directions_bus),
          color: Colors.blue,
        ),
        Container(
          child: Icon(Icons.directions_railway),
          color: Colors.orange,
        )
      ]),
      bottomNavigationBar: GFTabBar(
        length: 3,
        controller: _tabController,
        tabs: tabs,
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: _incrementCounter,
      //   tooltip: 'Increment',
      //   child: const Icon(Icons.add),
      // ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  var tabs = [
    Tab(
      icon: Icon(Icons.directions_bike),
      child: Text(
        "Tab1",
      ),
    ),
    Tab(
      icon: Icon(Icons.directions_bus),
      child: Text(
        "Tab2",
      ),
    ),
    Tab(
      icon: Icon(Icons.directions_railway),
      child: Text(
        "Tab3",
      ),
    )
  ];
}
