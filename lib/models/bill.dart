enum BillType {
  electricity,
  water,
  internet,
  phone,
  rent,
  insurance,
  subscription,
  other,
}

class Bill {
  final String id;
  final String name;
  final double amount;
  final DateTime dueDate;
  final BillType type;
  final bool isPaid;

  Bill({
    required this.id,
    required this.name,
    required this.amount,
    required this.dueDate,
    required this.type,
    this.isPaid = false,
  });
}
