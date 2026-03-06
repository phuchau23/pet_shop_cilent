/// File config quản lý tất cả các API endpoints
class ApiEndpoints {
  // Base URL
  static const String baseUrl = '/api';

  // Auth endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh-token';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';

  // User endpoints
  static const String getProfile = '/user/profile';
  static const String updateProfile = '/user/profile';
  static const String changePassword = '/user/change-password';
  
  // Auth endpoints - Profile
  static const String getAuthProfile = '/auth/profile'; // ⭐ API mới - lấy từ token

  // Category endpoints
  static const String getCategories = '/categories';

  // Pet endpoints (ví dụ cho Pet Shop)
  static const String getPets = '/pets';
  static const String getPetById = '/pets'; // /pets/{id}
  static const String createPet = '/pets';
  static const String updatePet = '/pets'; // /pets/{id}
  static const String deletePet = '/pets'; // /pets/{id}

  // Product endpoints (ví dụ)
  static const String getProducts = '/products';
  static const String getProductById = '/products'; // /products/{id}
  static const String createProduct = '/products';
  static const String updateProduct = '/products'; // /products/{id}
  static const String deleteProduct = '/products'; // /products/{id}

  // Order endpoints (ví dụ)
  static const String getOrders = '/orders';
  static const String getMyOrders = '/orders/my-orders'; // ⭐ API mới - lấy từ token
  static const String getOrderById = '/orders'; // /orders/{id}
  static const String createOrder = '/orders';
  static const String updateOrder = '/orders'; // /orders/{id}
  static const String cancelOrder = '/orders'; // /orders/{id}/cancel
  static const String estimateDelivery = '/orders/estimate-delivery';
  static const String orderTracking = '/orders'; // /orders/{id}/tracking

  // Voucher endpoints
  static const String getVouchers = '/vouchers';
  static const String validateVoucher = '/vouchers/validate';

  // Location endpoints
  static const String getProvinces = '/locations/provinces';
  static const String getDistricts = '/locations/districts';
  static const String getWards = '/locations/wards';

  // Shipper endpoints
  static const String getShipperOrders = '/orders/shipper/my-orders';
  static const String getAvailableOrders = '/orders/shipper/available';
  static const String updateShipperStatus = '/orders'; // /orders/{id}/shipper-status
  static const String updateShipperLocation = '/orders'; // /orders/{id}/shipper-location

  // Helper method để build URL với path parameters
  static String buildUrl(String endpoint, {Map<String, dynamic>? pathParams}) {
    String url = endpoint;
    if (pathParams != null) {
      pathParams.forEach((key, value) {
        url = url.replaceAll('{$key}', value.toString());
      });
    }
    return url;
  }

  // Helper method để build URL với query parameters
  static String buildUrlWithQuery(
    String endpoint, {
    Map<String, dynamic>? queryParams,
  }) {
    String url = endpoint;
    if (queryParams != null && queryParams.isNotEmpty) {
      final queryString = queryParams.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}')
          .join('&');
      url = '$url?$queryString';
    }
    return url;
  }
}
