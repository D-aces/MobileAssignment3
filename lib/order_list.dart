import 'package:flutter/material.dart';
import 'fooditem.dart';
import 'order.dart';

class OrderList extends StatelessWidget {
  final List<Order> orders;
  final Function(Order) onOrderTap;
  final Function(Order) onDeleteOrder; // Callback for deleting an order

  const OrderList({
    super.key,
    required this.orders,
    required this.onOrderTap,
    required this.onDeleteOrder, // Add the onDeleteOrder callback
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];

        return GestureDetector(
          onTap: () => onOrderTap(order),
          child: Card(
            color: Colors.white,
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Stack(
                children: [
                  // Main content of the order card
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Budget
                      Text(
                        "Budget: \$${order.budget.toStringAsFixed(2)}",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Date
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          "Date: ${_formatDate(order.date)}",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),

                      // Food Items List
                      if (order.foodItems != null && order.foodItems!.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: order.foodItems!.map((food) {
                            return Text(
                              "${food.foodName} - \$${food.foodPrice.toStringAsFixed(2)}",
                              style: const TextStyle(fontSize: 14),
                            );
                          }).toList(),
                        ),

                      // Total Price
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          "Total: \$${_calculateTotalPrice(order.foodItems).toStringAsFixed(2)}",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  // Close button positioned at the top-right corner
                  Positioned(
                    right: 0,
                    top: 0,
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => onDeleteOrder(order), // Handle delete order
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  double _calculateTotalPrice(List<FoodItem>? foodItems) {
    if (foodItems == null) return 0.0;
    return foodItems.fold(0, (sum, food) => sum + food.foodPrice);
  }
}
