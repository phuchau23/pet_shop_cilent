class Category {
  final int categoryId;
  final String name;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  Category({
    required this.categoryId,
    required this.name,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });
}
