class FoodItem{
  final int? id;
  String foodName;
  double foodPrice;

  FoodItem({
   this.id,
   required this.foodName,
   required this.foodPrice
});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'food_name': foodName,
      'food_price': foodPrice
    };
  }

  factory FoodItem.fromMap(Map<String, dynamic> map) {
    return FoodItem(
      id: map['id'],
      foodName: map['food_name'],
      foodPrice: map['food_price']
    );
  }


}