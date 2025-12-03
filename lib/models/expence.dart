// Mock data for demonstration
class Expense {
  final String id;
  final String name;
  final String date;
  final String category;
  final double amount;
  final bool isSelected;

  Expense({
    required this.id,
    required this.name,
    required this.date,
    required this.category,
    required this.amount,
    this.isSelected = false,
  });

  Expense copyWith({bool? isSelected}) {
    return Expense(
      id: id,
      name: name,
      date: date,
      category: category,
      amount: amount,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}
