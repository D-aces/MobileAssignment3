import 'package:flutter/material.dart';
import 'database_handler.dart';
import 'order.dart';
import 'fooditem.dart';

class NewOrder extends StatefulWidget {
  final Order? editableOrder;

  const NewOrder({Key? key, this.editableOrder}) : super(key: key);

  @override
  State<NewOrder> createState() => _NewOrderState();
}

class _NewOrderState extends State<NewOrder> {
  late DatabaseHandler _dbHandler;
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();
  List<FoodItem> _foodList = [];
  List<int> _selectedFoodIds = [];

  @override
  void initState() {
    super.initState();
    _dbHandler = DatabaseHandler();
    _loadFoodItems();

    // Populate fields if editing an order
    if (widget.editableOrder != null) {
      _budgetController.text = widget.editableOrder!.budget.toString();
      _dateController.text = widget.editableOrder!.date.toString().split(" ")[0];
      _selectedFoodIds = widget.editableOrder!.foodItems?.map((item) => item.id!).toList() ?? [];
    }
  }

  Future<void> _loadFoodItems() async {
    final foodList = await _dbHandler.getAllFood();
    setState(() {
      _foodList = foodList;
    });
  }

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: widget.editableOrder?.date ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _dateController.text = picked.toString().split(" ")[0];
      });
    }
  }

  Future<void> _saveOrder() async {
    if (_budgetController.text.isEmpty || _dateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out all fields.')),
      );
      return;
    }

    double budget = double.parse(_budgetController.text);
    DateTime date = DateTime.parse(_dateController.text);

    Order newOrder = Order(
      id: widget.editableOrder?.id,
      budget: budget,
      date: date,
    );

    try {
      if (widget.editableOrder == null) {
        // Create a new order
        await _dbHandler.createOrder(newOrder, _selectedFoodIds);
      } else {
        // Update existing order
        await _dbHandler.updateOrder(newOrder, _selectedFoodIds);
      }
      Navigator.pop(context, true); // Return to the main page
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editableOrder == null ? 'Create Order' : 'Edit Order'),
        backgroundColor: const Color.fromARGB(255, 43, 61, 65),
        titleTextStyle: const TextStyle(fontSize: 25, color: Colors.white),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _budgetController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Budget',
                filled: true,
                prefixIcon: Icon(Icons.monetization_on),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
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
            const SizedBox(height: 20),
            const Text(
              'Select Food Items:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _foodList.length,
                itemBuilder: (context, index) {
                  final food = _foodList[index];
                  return CheckboxListTile(
                    title: Text(food.foodName),
                    subtitle: Text('Price: \$${food.foodPrice.toStringAsFixed(2)}'),
                    value: _selectedFoodIds.contains(food.id),
                    onChanged: (selected) {
                      setState(() {
                        if (selected == true) {
                          _selectedFoodIds.add(food.id!);
                        } else {
                          _selectedFoodIds.remove(food.id);
                        }
                      });
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveOrder,
              child: Text(widget.editableOrder == null ? 'Create Order' : 'Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
