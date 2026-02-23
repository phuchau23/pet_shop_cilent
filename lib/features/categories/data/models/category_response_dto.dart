class CategoryResponseDto {
  final List<CategoryDto> data;
  final int totalCount;
  final int pageNumber;
  final int pageSize;
  final int totalPages;
  final bool hasPreviousPage;
  final bool hasNextPage;

  CategoryResponseDto({
    required this.data,
    required this.totalCount,
    required this.pageNumber,
    required this.pageSize,
    required this.totalPages,
    required this.hasPreviousPage,
    required this.hasNextPage,
  });

  factory CategoryResponseDto.fromJson(Map<String, dynamic> json) {
    return CategoryResponseDto(
      data: (json['data'] as List)
          .map((item) => CategoryDto.fromJson(item as Map<String, dynamic>))
          .toList(),
      totalCount: json['totalCount'] as int,
      pageNumber: json['pageNumber'] as int,
      pageSize: json['pageSize'] as int,
      totalPages: json['totalPages'] as int,
      hasPreviousPage: json['hasPreviousPage'] as bool,
      hasNextPage: json['hasNextPage'] as bool,
    );
  }
}

class CategoryDto {
  final int categoryId;
  final String name;
  final String? description;
  final String createdAt;
  final String updatedAt;

  CategoryDto({
    required this.categoryId,
    required this.name,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CategoryDto.fromJson(Map<String, dynamic> json) {
    return CategoryDto(
      categoryId: json['categoryId'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
    );
  }
}
