import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyApp();
}

var address;
var date;
var jsonData_category;
var jsonData_dishes;
bool categoryGetState = false;

_getDate() {
  DateTime now = DateTime.now();

  List<String> dateMonth = [
    'Январь',
    'Февраль',
    'Март',
    'Апрель',
    'Май',
    'Июнь',
    'Июль',
    'Август',
    'Сентябрь',
    'Октярь',
    'Ноябрь',
    'Декарь'
  ];

  date = "${now.day} ${dateMonth[now.month]}, ${now.year}";
}

_determinePosition() async {
  bool serviceEnabled;
  LocationPermission permission;

  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return Future.error('Location services are disabled.');
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return Future.error('Location permissions are denied');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.');
  }

  Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high);
  List<Placemark> placemarks =
      await placemarkFromCoordinates(position.latitude, position.longitude);
  address = placemarks[0].locality;
}

getDataFromAPI() async {
  var responceDishes = await http.get(Uri.parse(
      'https://run.mocky.io/v3/aba7ecaa-0a70-453b-b62d-0e326c859b3b'));
  jsonData_dishes = jsonDecode(responceDishes.body);
}

class _MyApp extends State<MyApp> {
  var _currentPage = 0;

  final _pages = [
    _Categories(),
    const Text('Поиск'),
    Basket(),
    const Text('Аккаунт'),
  ];

  @override
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _determinePosition();
      getDataFromAPI();
      _getDate();
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TestApp',
      theme: ThemeData(),
      home: Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: _pages.elementAt(_currentPage),
          ),
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _currentPage,
            onTap: (int intIndex) {
              setState(() {
                _currentPage = intIndex;
              });
            },
            selectedIconTheme: const IconThemeData(color: Colors.blue),
            selectedItemColor: Colors.blue,
            selectedLabelStyle: const TextStyle(fontFamily: 'SF Pro Display Medium', fontSize: 11, color: Colors.blue),
            unselectedIconTheme: const IconThemeData(color: Colors.grey),
            unselectedItemColor: Colors.grey,
            unselectedLabelStyle: const TextStyle(fontFamily: 'SF Pro Display Medium', fontSize: 11, color: Colors.grey),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Главная',),
              BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Поиск'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.shopping_basket), label: 'Корзина'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.account_circle_outlined), label: 'Аккаунт'),
            ],
          )),
    );
  }
}

List<Category_item> categories = [];

class _Categories extends StatefulWidget {
  @override
  _CategoriesState createState() => _CategoriesState();
}

class _CategoriesState extends State<_Categories> {
  getCategories() async {
    if (categoryGetState == false) {
      var responceCategory = await http.get(Uri.parse(
          'https://run.mocky.io/v3/058729bd-1402-4578-88de-265481fd7d54'));
      jsonData_category = jsonDecode(responceCategory.body);
    }
    categories = [];
    for (var c in jsonData_category["сategories"]) {
      Category_item category =
          Category_item(c["id"], c["name"], c["image_url"]);
      categories.add(category);
    }
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    getCategories();
    Timer(
        (const Duration(seconds: 7)),
        () => setState(() {
              _determinePosition();
            }));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          extendBodyBehindAppBar: true,
          backgroundColor: Colors.white,
          appBar: AppBar(
            leading: Container(
              child: const Icon(Icons.location_on_outlined,
                  color: Colors.black, size: 30),
            ),
            titleSpacing: -10,
            title: Container(
              margin: EdgeInsets.only(top: 3),
              child: Column(
                children: [
                  Text(
                    address.toString(),
                    style: const TextStyle(
                      color: Colors.black,
                      fontFamily: 'SF Pro Display Medium',
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    date.toString(),
                    style: const TextStyle(
                      color: Color.fromRGBO(0, 0, 0, 0.5),
                      fontFamily: 'SF Pro Display',
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              Container(
                margin: EdgeInsets.only(right: 10),
                child: Icon(Icons.account_circle_outlined,
                    color: Colors.black, size: 40),
              )
            ],
            elevation: 0,
            backgroundColor: Colors.white,
            shadowColor: Colors.white,
            surfaceTintColor: Colors.white,
          ),
          body: ListView.builder(
              itemCount: categories.length,
              itemBuilder: (BuildContext context, int index) {
                return Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  clipBehavior: Clip.hardEdge,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (BuildContext context) =>
                                  Category(categories[index].name)));
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Ink.image(
                            image: NetworkImage(categories[index].imageUrl),
                            height: 148,
                            fit: BoxFit.cover,
                            alignment: Alignment.topLeft,
                            width: 1000,
                            child: Container(
                                alignment: const Alignment(-0.84, -0.88),
                                width: 191,
                                height: 50,
                                child: Text(
                                  categories[index].name,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'SF Pro Display',
                                    fontStyle: FontStyle.normal,
                                  ),
                                ))),
                      ],
                    ),
                  ),
                );
              })),
    );
  }
}

class Category_item {
  final int id;
  final String name, imageUrl;

  Category_item(this.id, this.name, this.imageUrl);
}

List<Dishes_item> dishes = [];

class Category extends StatefulWidget {
  final String titleName;

  Category(this.titleName);

  @override
  _Category createState() => _Category(titleName);
}

bool filterStateAll = true;
bool filterStateSalad = false;
bool filterStateRice = false;
bool filterStateFish = false;

class _Category extends State<Category> {
  final String titleName;

  _Category(this.titleName);

  getDishes() async {
    dishes = [];

    for (var i in jsonData_dishes["dishes"]) {
      if (filterStateAll == true) {
        Dishes_item dish = Dishes_item(i["id"], i["name"], i["price"],
            i["weight"], i["description"], i["image_url"], i["tegs"]);
        dishes.add(dish);
      } else if (filterStateSalad == true) {
        if (i["tegs"].contains('Салаты')) {
          Dishes_item dish = Dishes_item(i["id"], i["name"], i["price"],
              i["weight"], i["description"], i["image_url"], i["tegs"]);
          dishes.add(dish);
        }
      } else if (filterStateRice == true) {
        if (i["tegs"].contains("С рисом")) {
          Dishes_item dish = Dishes_item(i["id"], i["name"], i["price"],
              i["weight"], i["description"], i["image_url"], i["tegs"]);
          dishes.add(dish);
        }
      } else if (filterStateFish == true) {
        if (i["tegs"].contains("С рыбой")) {
          Dishes_item dish = Dishes_item(i["id"], i["name"], i["price"],
              i["weight"], i["description"], i["image_url"], i["tegs"]);
          dishes.add(dish);
        }
      }
    }
    setState(() {});
  }

  alertDialogDishe(Dishes_item item) {}

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => getDishes());
  }

  List<Container> _buildGridTileList(int count) => List.generate(
      count,
      (i) => Container(
            height: 140,
            width: 109,
            child: Column(
              verticalDirection: VerticalDirection.down,
              children: [
                Expanded(
                  child: Container(
                    height: 110,
                    width: 110,
                    decoration: BoxDecoration(
                        border: Border.all(
                            color: const Color.fromRGBO(248, 247, 245, 1)),
                        color: const Color.fromRGBO(248, 247, 245, 1),
                        borderRadius: BorderRadius.circular(10),
                        image: DecorationImage(
                          image: NetworkImage(dishes[i].imageUrl),
                          fit: BoxFit.scaleDown,
                        )),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15)),
                                  content: Container(
                                      child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Card(
                                          shadowColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10)),
                                          child: Container(
                                              padding: const EdgeInsets.only(
                                                  top: 8, left: 8, right: 8),
                                              height: 232,
                                              width: 311,
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                    color: const Color.fromRGBO(
                                                        248, 247, 245, 1)),
                                                color: const Color.fromRGBO(
                                                    248, 247, 245, 1),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                image: DecorationImage(
                                                  image: NetworkImage(
                                                      dishes[i].imageUrl),
                                                  fit: BoxFit.scaleDown,
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  Container(
                                                      height: 40,
                                                      width: 40,
                                                      margin:
                                                          const EdgeInsets.only(
                                                              bottom: 181,
                                                              left: 150),
                                                      decoration: BoxDecoration(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                          color: Colors.white),
                                                      child: IconButton(
                                                        onPressed: () {},
                                                        icon: const Icon(
                                                          Icons.favorite_border,
                                                          color: Colors.black,
                                                        ),
                                                      )),
                                                  Container(
                                                      height: 40,
                                                      width: 40,
                                                      margin:
                                                          const EdgeInsets.only(
                                                              bottom: 181,
                                                              left: 8),
                                                      decoration: BoxDecoration(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                          color: Colors.white),
                                                      child: IconButton(
                                                        onPressed: () {
                                                          Navigator.pop(
                                                              context);
                                                        },
                                                        icon: const Icon(
                                                          Icons.close_outlined,
                                                          color: Colors.black,
                                                        ),
                                                      )),
                                                ],
                                              ))),
                                      Container(
                                          padding:
                                              const EdgeInsets.only(top: 8),
                                          alignment: const Alignment(-0.95, 0),
                                          child: Text(
                                            dishes[i].name,
                                            style: const TextStyle(
                                                fontFamily:
                                                    'SF Pro Display Medium',
                                                fontSize: 16,
                                                fontStyle: FontStyle.normal),
                                          )),
                                      Row(
                                        children: [
                                          Container(
                                              padding:
                                                  const EdgeInsets.only(top: 8),
                                              alignment:
                                                  const Alignment(-0.96, 0),
                                              child: Text(
                                                "${dishes[i].price}₽",
                                                style: const TextStyle(
                                                    fontFamily:
                                                        'SF Pro Display',
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.black),
                                              )),
                                          Opacity(
                                            opacity: 0.50,
                                            child: Container(
                                                padding: const EdgeInsets.only(
                                                    top: 8),
                                                alignment:
                                                    const Alignment(-0.96, 0),
                                                child: Text(
                                                  " • ${dishes[i].weight}г",
                                                  style: const TextStyle(
                                                    fontFamily:
                                                        'SF Pro Display',
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.black,
                                                  ),
                                                )),
                                          )
                                        ],
                                      ),
                                      Opacity(
                                        opacity: 0.65,
                                        child: Container(
                                            width: 311,
                                            padding:
                                                const EdgeInsets.only(top: 8),
                                            alignment:
                                                const Alignment(-0.96, 0),
                                            child: Text(
                                              dishes[i].description,
                                              style: const TextStyle(
                                                fontFamily: 'SF Pro Display',
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.black,
                                              ),
                                            )),
                                      ),
                                      Container(
                                          margin: const EdgeInsets.only(top: 8),
                                          height: 48,
                                          width: 311,
                                          decoration: BoxDecoration(
                                              color: const Color.fromRGBO(
                                                  51, 100, 224, 1),
                                              borderRadius:
                                                  BorderRadius.circular(10)),
                                          child: TextButton(
                                            clipBehavior: Clip.hardEdge,
                                            onPressed: () {
                                              add_purchase(dishes[i]);
                                            },
                                            child: const Text(
                                              "Добавить в корзину",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontFamily:
                                                    'SF Pro Display Medium',
                                                fontSize: 16,
                                              ),
                                            ),
                                          ))
                                    ],
                                  )));
                            });
                      },
                    ),
                  ),
                ),
                SizedBox(
                  height: 30,
                  width: 100,
                  child: Text(
                    dishes[i].name,
                    style: const TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontStyle: FontStyle.normal,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ));

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
            backgroundColor: Colors.white,
            extendBodyBehindAppBar: true,
            resizeToAvoidBottomInset: false,
            appBar: AppBar(
                actions: [
                  Container(
                    margin: EdgeInsets.only(right: 10),
                    child: Icon(Icons.account_circle_outlined,
                        color: Colors.black, size: 40),
                  )
                ],
                elevation: 0,
                backgroundColor: Colors.white,
                shadowColor: Colors.white,
                surfaceTintColor: Colors.white,
                centerTitle: true,
                title: Text(titleName,
                    style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'SF Pro Display',
                        fontSize: 18,
                        fontStyle: FontStyle.normal)),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                )),
            body: Column(mainAxisSize: MainAxisSize.max, children: [
              Expanded(
                flex: 0,
                child: Container(
                  margin: const EdgeInsets.only(top: 90),
                  height: 28,
                  child: SingleChildScrollView(
                    clipBehavior: Clip.hardEdge,
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Container(
                            margin: const EdgeInsets.only(left: 4, right: 4),
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() => {
                                      filterStateAll = true,
                                      filterStateSalad = false,
                                      filterStateRice = false,
                                      filterStateFish = false,
                                    });
                                getDishes();
                              },
                              style: ElevatedButton.styleFrom(
                                minimumSize: Size(50, 35),
                                backgroundColor: filterStateAll
                                    ? const Color.fromRGBO(51, 100, 224, 1)
                                    : const Color.fromRGBO(248, 247, 245, 1),
                              ),
                              child: filterStateAll
                                  ? const Text('Все меню',
                                      style: TextStyle(color: Colors.white))
                                  : const Text('Все меню',
                                      style: TextStyle(color: Colors.black)),
                            )),
                        Container(
                            margin: const EdgeInsets.only(left: 4, right: 4),
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() => {
                                      filterStateAll = false,
                                      filterStateSalad = true,
                                      filterStateRice = false,
                                      filterStateFish = false,
                                    });
                                getDishes();
                              },
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(50, 35),
                                backgroundColor: filterStateSalad
                                    ? const Color.fromRGBO(51, 100, 224, 1)
                                    : const Color.fromRGBO(248, 247, 245, 1),
                              ),
                              child: filterStateSalad
                                  ? const Text('Салаты',
                                      style: TextStyle(color: Colors.white))
                                  : const Text('Салаты',
                                      style: TextStyle(color: Colors.black)),
                            )),
                        Container(
                            margin: const EdgeInsets.only(left: 4, right: 4),
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() => {
                                      filterStateAll = false,
                                      filterStateSalad = false,
                                      filterStateRice = true,
                                      filterStateFish = false,
                                    });
                                getDishes();
                              },
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(50, 35),
                                backgroundColor: filterStateRice
                                    ? const Color.fromRGBO(51, 100, 224, 1)
                                    : const Color.fromRGBO(248, 247, 245, 1),
                              ),
                              child: filterStateRice
                                  ? const Text('С рисом',
                                      style: TextStyle(color: Colors.white))
                                  : const Text('С рисом',
                                      style: TextStyle(color: Colors.black)),
                            )),
                        Container(
                            margin: const EdgeInsets.only(left: 4, right: 4),
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() => {
                                      filterStateAll = false,
                                      filterStateSalad = false,
                                      filterStateRice = false,
                                      filterStateFish = true,
                                    });
                                getDishes();
                              },
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(50, 35),
                                backgroundColor: filterStateFish
                                    ? const Color.fromRGBO(51, 100, 224, 1)
                                    : const Color.fromRGBO(248, 247, 245, 1),
                              ),
                              child: filterStateFish
                                  ? const Text('С рыбой',
                                      style: TextStyle(color: Colors.white))
                                  : const Text('С рыбой',
                                      style: TextStyle(color: Colors.black)),
                            )),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  margin: EdgeInsets.only(top: 15),
                  child: GridView.extent(
                    maxCrossAxisExtent: 170,
                    padding: const EdgeInsets.only(left: 16, right: 16),
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 6,
                    children: _buildGridTileList(dishes.length),
                  ),
                ),
              )
            ])));
  }
}

class Dishes_item {
  final int id, price, weight;
  final String name, description, imageUrl;
  var tegs = [];

  Dishes_item(this.id, this.name, this.price, this.weight, this.description,
      this.imageUrl, this.tegs);
}

List<shop_item> shoppingList = [];

add_purchase(Dishes_item item) {
  for (shop_item i in shoppingList) {
    if (i.dishe_item.name == item.name && i.quantity != 0) {
      i.quantity++;
      return;
    }
  }
  shoppingList.add(shop_item(item, 1));
  updatePurchaseAmount();
}

reduce_purchase(Dishes_item item) {
  for (shop_item i in shoppingList) {
    if (i.dishe_item.name == item.name) {
      i.quantity--;
    }
  }
  updatePurchaseAmount();
}

int purchaseAmount = 0;

updatePurchaseAmount() {
  purchaseAmount = 0;
  for (shop_item i in shoppingList) {
    purchaseAmount += (i.dishe_item.price * i.quantity);
  }
}

class shop_item {
  Dishes_item dishe_item;
  int quantity;

  shop_item(this.dishe_item, this.quantity);
}

class Basket extends StatefulWidget {
  const Basket({Key? key}) : super(key: key);

  @override
  _Basket createState() => _Basket();
}

class _Basket extends State<Basket> {
  updateStatePage() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    updatePurchaseAmount();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
            appBar: AppBar(
              leading: Container(
                child: const Icon(Icons.location_on_outlined,
                    color: Colors.black, size: 30),
              ),
              titleSpacing: -10,
              title: Container(
                margin: EdgeInsets.only(top: 3),
                child: Column(
                  children: [
                    Text(
                      address.toString(),
                      style: const TextStyle(
                        color: Colors.black,
                        fontFamily: 'SF Pro Display Medium',
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      date.toString(),
                      style: const TextStyle(
                        color: Color.fromRGBO(0, 0, 0, 0.5),
                        fontFamily: 'SF Pro Display',
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                Container(
                  margin: EdgeInsets.only(right: 10),
                  child: Icon(Icons.account_circle_outlined,
                      color: Colors.black, size: 40),
                )
              ],
              elevation: 0,
              backgroundColor: Colors.white,
              shadowColor: Colors.white,
              surfaceTintColor: Colors.white,
            ),
            body: Container(
                color: Colors.white,
                margin: EdgeInsets.only(left: 16),
                child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Container(
                          height: 624,
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: shoppingList.length,
                            scrollDirection: Axis.vertical,
                            addAutomaticKeepAlives: true,
                            itemBuilder: (BuildContext context, int index) {
                              return Container(
                                  decoration: BoxDecoration(),
                                  height: 70,
                                  margin: EdgeInsets.only(top: 8),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 64,
                                        height: 64,
                                        decoration: BoxDecoration(
                                            border: Border.all(
                                                color: const Color.fromRGBO(
                                                    248, 247, 245, 1)),
                                            color: const Color.fromRGBO(
                                                248, 247, 245, 1),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            image: DecorationImage(
                                              image: NetworkImage(
                                                  shoppingList[index]
                                                      .dishe_item
                                                      .imageUrl),
                                              fit: BoxFit.scaleDown,
                                            )),
                                      ),
                                      Expanded(
                                          child: Container(
                                              margin: EdgeInsets.only(left: 8),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Container(
                                                    alignment:
                                                        Alignment.topLeft,
                                                    child: Text(
                                                        shoppingList[index]
                                                            .dishe_item
                                                            .name,
                                                        style: const TextStyle(
                                                          color: Colors.black,
                                                          fontFamily:
                                                              'SF Pro Display',
                                                          fontSize: 14,
                                                        )),
                                                  ),
                                                  Container(
                                                      alignment:
                                                          Alignment.topLeft,
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Container(
                                                              padding:
                                                                  const EdgeInsets
                                                                          .only(
                                                                      top: 4),
                                                              alignment:
                                                                  Alignment
                                                                      .topLeft,
                                                              child: Text(
                                                                "${shoppingList[index].dishe_item.price}₽",
                                                                style: const TextStyle(
                                                                    fontFamily:
                                                                        'SF Pro Display',
                                                                    fontSize:
                                                                        14,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500,
                                                                    color: Colors
                                                                        .black),
                                                              )),
                                                          Opacity(
                                                            opacity: 0.50,
                                                            child: Container(
                                                                padding:
                                                                    const EdgeInsets
                                                                            .only(
                                                                        top: 4),
                                                                alignment:
                                                                    Alignment
                                                                        .topLeft,
                                                                child: Text(
                                                                  " • ${shoppingList[index].dishe_item.weight}г",
                                                                  style:
                                                                      const TextStyle(
                                                                    fontFamily:
                                                                        'SF Pro Display',
                                                                    fontSize:
                                                                        14,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500,
                                                                    color: Colors
                                                                        .black,
                                                                  ),
                                                                )),
                                                          )
                                                        ],
                                                      ))
                                                ],
                                              ))),
                                      Container(
                                          margin: EdgeInsets.only(right: 16),
                                          height: 32,
                                          width: 104,
                                          decoration: BoxDecoration(
                                              color: Color.fromRGBO(
                                                  239, 238, 236, 1),
                                              borderRadius:
                                                  BorderRadius.circular(10)),
                                          child: Row(
                                            children: [
                                              IconButton(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  onPressed: () {
                                                    reduce_purchase(
                                                        shoppingList[index]
                                                            .dishe_item);
                                                    updateStatePage();
                                                    if (shoppingList[index]
                                                            .quantity ==
                                                        0) {
                                                      setState(() {
                                                        shoppingList
                                                            .removeAt(index);
                                                      });
                                                    }
                                                  },
                                                  icon: const Icon(
                                                    Icons.arrow_back_ios,
                                                    size: 18,
                                                  )),
                                              Text(
                                                shoppingList[index]
                                                    .quantity
                                                    .toString(),
                                              ),
                                              IconButton(
                                                  alignment:
                                                      Alignment.centerRight,
                                                  onPressed: () {
                                                    add_purchase(
                                                        shoppingList[index]
                                                            .dishe_item);
                                                    updateStatePage();
                                                    setState(() {
                                                      updatePurchaseAmount();
                                                    });
                                                  },
                                                  icon: const Icon(
                                                    Icons.arrow_forward_ios,
                                                    size: 18,
                                                  )),
                                            ],
                                          ))
                                    ],
                                  ));
                            },
                          ),
                        ),
                        Container(
                            margin: const EdgeInsets.only(top: 1),
                            height: 48,
                            width: 343,
                            decoration: BoxDecoration(
                                color: const Color.fromRGBO(51, 100, 224, 1),
                                borderRadius: BorderRadius.circular(10)),
                            child: TextButton(
                              clipBehavior: Clip.hardEdge,
                              onPressed: () {},
                              child: Text(
                                "Оплатить ${purchaseAmount}₽",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'SF Pro Display Medium',
                                  fontSize: 16,
                                ),
                              ),
                            ))
                      ],
                    )))));
  }
}
