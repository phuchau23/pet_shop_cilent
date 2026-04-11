class ApiResponse<T> {
  final int code;
  final String message;
  final T? data;
  final dynamic errors;

  ApiResponse({
    required this.code,
    required this.message,
    this.data,
    this.errors,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return ApiResponse<T>(
      code: (json['code'] as num?)?.toInt() ?? (json['statusCode'] as num?)?.toInt() ?? 200,
      message: json['message'] as String? ?? '',
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'] as T?,
      errors: json['errors'],
    );
  }
}
