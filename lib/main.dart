import 'package:flutter/material.dart';
import 'database_handler.dart';
import 'fooditem.dart';
import 'new_order.dart';
import 'order.dart';
import 'order_list.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const Order66());
}

class Order66 extends StatelessWidget {
  const Order66({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Order 66',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 43, 61, 65)),
        useMaterial3: true,
      ),
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  MainPageState createState() => MainPageState();
}

class MainPageState extends State<MainPage> {
  late DatabaseHandler _dbHandler;
  final TextEditingController _dateController = TextEditingController();
  List<Order> _orderList = [];

  @override
  void initState() {
    super.initState();
    _dbHandler = DatabaseHandler();
    _loadOrders();
    _addFoodEntries();
  }

  Future<void> _addFoodEntries() async {
    List<FoodItem> foodItems = [
      FoodItem(foodName: 'Chicken Caesar Salad', foodPrice: 12.5),
      FoodItem(foodName: 'Beef Stir-Fry with Rice', foodPrice: 14.0),
      FoodItem(foodName: 'Vegetarian Lasagna', foodPrice: 13.0),
      FoodItem(foodName: 'Grilled Salmon with Asparagus', foodPrice: 18.0),
      FoodItem(foodName: 'Spaghetti Bolognese', foodPrice: 11.5),
      FoodItem(foodName: 'Chicken Alfredo Pasta', foodPrice: 13.5),
      FoodItem(foodName: 'Lamb Chops with Mint Sauce', foodPrice: 20.0),
      FoodItem(foodName: 'Tofu and Vegetable Stir-Fry', foodPrice: 11.0),
      FoodItem(foodName: 'BBQ Pulled Pork Sandwich', foodPrice: 9.5),
      FoodItem(foodName: 'Vegan Buddha Bowl', foodPrice: 10.0),
      FoodItem(foodName: 'Cheeseburger with Fries', foodPrice: 11.0),
      FoodItem(foodName: 'Chicken Tikka Masala with Rice', foodPrice: 15.0),
      FoodItem(foodName: 'Fish and Chips', foodPrice: 12.0),
      FoodItem(foodName: 'Beef Burritos with Guacamole', foodPrice: 12.5),
      FoodItem(foodName: 'Sweet and Sour Chicken', foodPrice: 13.0),
      FoodItem(foodName: 'Pork Schnitzel with Potato Salad', foodPrice: 16.0),
      FoodItem(foodName: 'Quinoa and Chickpea Salad', foodPrice: 9.0),
      FoodItem(foodName: 'Grilled Shrimp Tacos', foodPrice: 14.5),
      FoodItem(foodName: 'Eggplant Parmesan', foodPrice: 12.0),
      FoodItem(foodName: 'Turkey Club Sandwich', foodPrice: 10.0),
    ];

    // Add each food item to the database if it doesn't already exist
    for (var food in foodItems) {
      await _dbHandler.addFoodIfNotExists(food);
    }
  }

  Future<void> _loadOrders({String? date}) async {
    List<Order> orders = [];

    if (date != null) {
      // Parse the string date to a DateTime object
      DateTime selectedDate = DateTime.parse(date);

      // Convert DateTime to Unix timestamp (milliseconds since epoch)
      int timestamp = selectedDate.millisecondsSinceEpoch;

      // Fetch orders for the specific timestamp
      orders = await _dbHandler.getOrdersByDate(timestamp);  // Note that we expect a List<Order> now
    } else {
      // Fetch all orders if no date is provided
      orders = await _dbHandler.getAllOrders();
    }

    setState(() {
      _orderList = orders;
    });
  }

  // Open the date picker
  Future<void> _selectDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      String formattedDate = pickedDate.toString().split(" ")[0]; // Format: yyyy-MM-dd
      setState(() {
        _dateController.text = formattedDate;
        _loadOrders(date: formattedDate); // Fetch orders by date
      });
    }
  }

  // Clear the date and reload all orders
  void _clearDate() {
    setState(() {
      _dateController.clear();
    });
    _loadOrders();
  }

  // Handle order taps (e.g., edit order)
  void _handleOrderTap(Order order) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewOrder(editableOrder: order),
      ),
    );
    _loadOrders();
  }

  // Delete order by Order object
  Future<void> _deleteOrder(Order order) async {
    if (order.id == null) {
      // Throw an exception if the ID is null
      throw ArgumentError('Order ID cannot be null');
    }

    await _dbHandler.deleteOrder(order.id!); // Safe to use `!` since we checked for null
    _loadOrders(); // Reload orders after deletion
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order 66'),
        backgroundColor: const Color.fromARGB(255, 43, 61, 65),
        titleTextStyle: const TextStyle(fontSize: 25, color: Colors.white),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0), // Padding around the entire content
        child: Column(
          children: [
            // Date picker input
            TextField(
              controller: _dateController,
              decoration: const InputDecoration(
                labelText: 'Select Date',
                filled: true,
                prefixIcon: Icon(Icons.calendar_today_rounded),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide.none,
                ),
              ),
              readOnly: true,
              onTap: _selectDate,
            ),
            const SizedBox(height: 10),
            // Clear button
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: _clearDate,
                child: const Text('Clear Date'),
              ),
            ),
            const SizedBox(height: 20),
            // Display the list of orders
            Expanded(
              child: _orderList.isEmpty
                  ? Center(
                child: Text(
                  'No orders',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              )
                  : OrderList(
                orders: _orderList,
                onOrderTap: _handleOrderTap,
                onDeleteOrder: _deleteOrder, // Pass delete callback here
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NewOrder()),
          );
          _loadOrders(); // Refresh orders after adding a new one
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
