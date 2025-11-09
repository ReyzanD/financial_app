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
      id: json['category_id_232143'],
      name: json['name_232143'],
      type: json['type_232143'],
      color: json['color_232143'],
      icon: json['icon_232143'],
      budgetLimit:
          json['budget_limit_232143'] != null
              ? double.parse(json['budget_limit_232143'].toString())
              : null,
      budgetPeriod: json['budget_period_232143'] ?? 'monthly',
      isSystemDefault: json['is_system_default_232143'] == 1,
      displayOrder: json['display_order_232143'] ?? 0,
    );
  }
}
