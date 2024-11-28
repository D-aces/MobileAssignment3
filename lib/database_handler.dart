import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'fooditem.dart';
import 'order.dart';

class DatabaseHandler {
  static const _databaseName = 'order66.db';
  static const _databaseVersion = 1;

  static const tableFood = 'food';
  static const tableOrder = 'orders';
  static const tableOrderFood = 'order_food';

  static final DatabaseHandler _instance = DatabaseHandler._privateConstructor();
  static Database? _database;

  DatabaseHandler._privateConstructor();

  factory DatabaseHandler() => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableFood (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      food_name TEXT NOT NULL,
      food_price REAL NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableOrder (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      budget REAL NOT NULL,
      date INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableOrderFood (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      order_id INTEGER NOT NULL,
      food_id INTEGER NOT NULL,
      FOREIGN KEY(order_id) REFERENCES $tableOrder(id) ON DELETE CASCADE,
      FOREIGN KEY(food_id) REFERENCES $tableFood(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  }

  // CRUD for Food Table
  Future<int> addFood(FoodItem food) async {
    final db = await database;
    return await db.insert(tableFood, food.toMap());
  }

  Future<void> addFoodIfNotExists(FoodItem food) async {
    final db = await database;

    // Check if the food item already exists by food_name or id
    final List<Map<String, dynamic>> existingFood = await db.query(
      tableFood,
      where: 'food_name = ?',
      whereArgs: [food.foodName],
    );

    if (existingFood.isEmpty) {
      // If no matching food item is found, insert the new food item
      await db.insert(tableFood, food.toMap());
    }
  }


  Future<int> updateFood(FoodItem food) async {
    final db = await database;
    return await db.update(
      tableFood,
      food.toMap(),
      where: 'id = ?',
      whereArgs: [food.id],
    );
  }

  Future<int> deleteFood(int id) async {
    final db = await database;
    return await db.delete(
      tableFood,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<FoodItem>> getAllFood() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(tableFood);
    return List.generate(maps.length, (i) => FoodItem.fromMap(maps[i]));
  }

  // CRUD for Orders
  Future<int> createOrder(Order order, List<int> foodIds) async {
    final db = await database;

    // Check budget constraint
    double totalCost = 0.0;
    for (int foodId in foodIds) {
      final food = await getFoodById(foodId);
      totalCost += food.foodPrice;
    }

    if (totalCost > order.budget) {
      throw Exception('Total cost exceeds the budget!');
    }

    // Insert the order
    int orderId = await db.insert(tableOrder, order.toMap());

    // Link food items to the order
    for (int foodId in foodIds) {
      await db.insert(tableOrderFood, {
        'order_id': orderId,
        'food_id': foodId,
      });
    }

    return orderId;
  }

  Future<List<Order>> getAllOrders() async {
    final db = await database;

    // Fetch all orders sorted by date
    final List<Map<String, dynamic>> orderMaps = await db.query(
      tableOrder,
      orderBy: 'date ASC', // Sorting orders by date in ascending order
    );

    List<Order> orders = [];

    for (var orderMap in orderMaps) {
      // Parse the order
      final order = Order.fromMap(orderMap);

      // Fetch associated food items for this order
      final List<Map<String, dynamic>> foodMaps = await db.rawQuery('''
      SELECT f.*
      FROM $tableFood f
      JOIN $tableOrderFood of ON f.id = of.food_id
      WHERE of.order_id = ?
    ''', [order.id]);

      // Add food items to the order
      order.foodItems = List.generate(foodMaps.length, (i) => FoodItem.fromMap(foodMaps[i]));

      orders.add(order);
    }

    return orders;
  }


  Future<List<Order>> getOrdersByDate(int date) async {
    final db = await database;

    // Fetch all orders matching the date
    final List<Map<String, dynamic>> orderMaps = await db.query(
      tableOrder,
      where: 'date = ?',
      whereArgs: [date],
    );

    if (orderMaps.isEmpty) return [];

    List<Order> orders = [];
    for (var orderMap in orderMaps) {
      final order = Order.fromMap(orderMap);

      // Fetch associated food items for each order
      final List<Map<String, dynamic>> foodMaps = await db.rawQuery('''
      SELECT f.*
      FROM $tableFood f
      JOIN $tableOrderFood of ON f.id = of.food_id
      WHERE of.order_id = ?
    ''', [order.id]);

      order.foodItems = List.generate(foodMaps.length, (i) => FoodItem.fromMap(foodMaps[i]));

      orders.add(order);
    }

    return orders;
  }


  Future<int> updateOrder(Order order, List<int> foodIds) async {
    final db = await database;

    // Check budget constraint
    double totalCost = 0.0;
    for (int foodId in foodIds) {
      final food = await getFoodById(foodId);
      totalCost += food.foodPrice;
    }

    if (totalCost > order.budget) {
      throw Exception('Total cost exceeds the budget!');
    }

    // Begin a transaction to ensure data integrity
    await db.transaction((txn) async {
      // Update the order's budget and date
      await txn.update(
        tableOrder,
        order.toMap(),
        where: 'id = ?',
        whereArgs: [order.id],
      );

      // Remove existing food items linked to the order
      await txn.delete(
        tableOrderFood,
        where: 'order_id = ?',
        whereArgs: [order.id],
      );

      // Add new food items to the order
      for (int foodId in foodIds) {
        await txn.insert(tableOrderFood, {
          'order_id': order.id,
          'food_id': foodId,
        });
      }
    });

    return order.id ?? 0;
  }

  Future<int> deleteOrder(int id) async {
    final db = await database;
    return await db.delete(
      tableOrder,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<FoodItem> getFoodById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableFood,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) throw Exception('Food item not found!');
    return FoodItem.fromMap(maps.first);
  }
}
