import 'fooditem.dart';
class Order{
  final int? id;
  double budget;
  DateTime date;
  List<FoodItem>? foodItems;

  Order({
    this.id,
    required this.budget,
    required this.date,
    this.foodItems
});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'budget': budget,
      'date': date.millisecondsSinceEpoch
    };
  }

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'],
      budget: map['budget'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
    );
  }

}