# 🐾 Pet Shop - Flutter Mobile App

Ứng dụng bán thức ăn và phụ kiện cho thú cưng được xây dựng bằng Flutter.

## 📱 Giới thiệu

Pet Shop là ứng dụng mobile giúp người dùng dễ dàng mua sắm thức ăn, đồ chơi và phụ kiện cho thú cưng. Ứng dụng được phát triển theo kiến trúc Clean Architecture với Flutter.

## ✨ Tính năng

### Phase A - Core Catalog (Hiện tại)
- ✅ **Đăng nhập/Đăng xuất**: Xác thực người dùng với JWT token
- ✅ **Trang chủ**: 
  - Special Offers với discount
  - Danh mục sản phẩm (Cat, Dog, Birds, Fish)
  - Best Selling Items
  - Tìm kiếm sản phẩm
- ✅ **Danh mục**: Xem sản phẩm theo category
- ✅ **Chi tiết sản phẩm**: Thông tin đầy đủ, hình ảnh, giá cả
- ✅ **Giỏ hàng**: Quản lý sản phẩm (client-side)
- ✅ **Tài khoản**: Thông tin người dùng, đăng xuất

### Tính năng sắp tới
- 🔄 Đơn hàng (Phase B)
- 🔄 Thanh toán
- 🔄 Địa chỉ giao hàng
- 🔄 Đánh giá sản phẩm

## 🏗️ Kiến trúc

Dự án sử dụng **Clean Architecture** với các layer:

```
lib/
├── core/                    # Core modules
│   ├── network/            # API client, interceptors
│   ├── storage/            # Token storage
│   ├── theme/              # App colors, theme
│   └── widgets/            # Shared widgets
│
├── features/               # Feature modules
│   ├── auth/              # Authentication
│   │   ├── data/         # Data layer (DTOs, repositories)
│   │   ├── domain/       # Domain layer (entities, use cases)
│   │   └── presentation/ # UI layer (pages, widgets)
│   │
│   ├── products/         # Products feature
│   ├── home/             # Home page
│   ├── categories/       # Categories page
│   ├── cart/             # Shopping cart
│   └── profile/          # User profile
```

## 🚀 Cài đặt và Chạy

### Yêu cầu
- Flutter SDK >= 3.9.2
- Dart SDK >= 3.9.2
- Android Studio / VS Code với Flutter extension

### Các bước

1. **Clone repository**
```bash
git clone <repository-url>
cd pet_shop
```

2. **Cài đặt dependencies**
```bash
flutter pub get
```

3. **Cấu hình API**
- Mở file `lib/core/network/api_client.dart`
- Cập nhật `baseUrl` theo môi trường:
  - Android Emulator: `http://10.0.2.2:5000/api`
  - iOS Simulator: `http://localhost:5000/api`
  - Thiết bị thật: `http://[IP_MÁY_TÍNH]:5000/api`

4. **Chạy ứng dụng**
```bash
flutter run
```

## 📦 Dependencies

- `dio: ^5.4.0` - HTTP client
- `shared_preferences: ^2.2.2` - Local storage
- `flutter` - Flutter SDK

## 🔐 API Endpoints

### Authentication
- `POST /api/auth/login` - Đăng nhập

### Products (Sắp tới)
- `GET /api/products` - Lấy danh sách sản phẩm
- `GET /api/products/{id}` - Chi tiết sản phẩm
- `GET /api/categories` - Danh mục sản phẩm

## 🎨 Theme & Colors

- **Primary Color**: Teal/Cyan (#4FD1C7)
- **Background**: Light Gray (#F7FAFC)
- **Design Style**: iOS-inspired với Material 3

## 📝 Cấu trúc Database (Phase A)

- `users` - Người dùng
- `categories` - Danh mục sản phẩm
- `brands` - Thương hiệu
- `products` - Sản phẩm
- `product_images` - Hình ảnh sản phẩm

## 👥 Đóng góp

1. Fork dự án
2. Tạo feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Mở Pull Request

## 📄 License

Dự án này thuộc về nhóm phát triển Pet Shop.

## 👨‍💻 Team

- **Backend**: .NET 9 Code First
- **Frontend**: Flutter (Clean Architecture)
- **Database**: PostgreSQL

---

Made with ❤️ by Phúc Hậu
