class CategoryModel {
  final String id;
  final String name;
  final String type;
  final String color;
  final String icon;
  final double? budgetLimit;
  final String budgetPeriod;
  final bool isSystemDefault;
  final int displayOrder;

  CategoryModel({
    required this.id,
    required this.name,
    required this.type,
    required this.color,
    required this.icon,
    this.budgetLimit,
    required this.budgetPeriod,
    required this.isSystemDefault,
    required this.displayOrder,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id:
          json['category_id_232143']?.toString() ??
          json['id']?.toString() ??
          '',
      name:
          json['name_232143']?.toString() ??
          json['name']?.toString() ??
          'Unknown',
      type:
          json['type_232143']?.toString() ??
          json['type']?.toString() ??
          'expense',
      color:
          json['color_232143']?.toString() ??
          json['color']?.toString() ??
          '#3498db',
      icon:
          json['icon_232143']?.toString() ??
          json['icon']?.toString() ??
          'receipt',
      budgetLimit:
          json['budget_limit_232143'] != null
              ? double.parse(json['budget_limit_232143'].toString())
              : null,
      budgetPeriod:
          json['budget_period_232143']?.toString() ??
          json['budget_period']?.toString() ??
          'monthly',
      isSystemDefault:
          json['is_system_default_232143'] == 1 ||
          json['is_system_default'] == 1,
      displayOrder: json['display_order_232143'] ?? json['display_order'] ?? 0,
    );
  }
}
