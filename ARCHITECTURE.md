# Kiến trúc dự án Pet Shop

## Tổng quan

Dự án sử dụng kiến trúc **Feature-first (Feature-based/Modular)** kết hợp với **Clean Architecture** (3 lớp: Presentation - Domain - Data). Kiến trúc này giúp:

- **Tách biệt theo tính năng**: Mỗi feature là một module độc lập, dễ bảo trì và mở rộng
- **Tách biệt theo lớp**: Mỗi feature tuân theo Clean Architecture với 3 lớp rõ ràng
- **Tái sử dụng code**: Core module chứa các thành phần dùng chung
- **Dễ test**: Các lớp độc lập, dễ viết unit test và integration test

## Cấu trúc thư mục

```
lib/
├── core/                          # Core module - các thành phần dùng chung
│   ├── network/                   # Network layer (Dio client, interceptors)
│   ├── storage/                   # Storage layer (Secure storage)
│   ├── error/                     # Error handling
│   └── utils/                     # Utilities và helper functions
│
├── features/                      # Features module - các tính năng của app
│   ├── auth/                      # Feature: Xác thực người dùng
│   │   ├── data/                  # Data layer
│   │   ├── domain/                # Domain layer
│   │   └── presentation/          # Presentation layer
│   │
│   ├── products/                  # Feature: Quản lý sản phẩm
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── cart/                      # Feature: Giỏ hàng
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── orders/                    # Feature: Đơn hàng
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   └── shipping/                  # Feature: Vận chuyển
│       ├── data/
│       ├── domain/
│       └── presentation/
│
├── app.dart                       # App configuration và setup
└── main.dart                      # Entry point của ứng dụng
```

## Chi tiết các module

### 1. Core Module (`lib/core/`)

Module này chứa các thành phần được sử dụng chung trong toàn bộ ứng dụng.

#### `core/network/`
- **Dio client**: Cấu hình HTTP client (base URL, timeout, headers)
- **Interceptors**: 
  - Request interceptor (thêm token, logging)
  - Response interceptor (xử lý response, error handling)
  - Error interceptor (xử lý lỗi network)

#### `core/storage/`
- **Secure storage**: Lưu trữ dữ liệu nhạy cảm (token, credentials)
- **Local storage**: Lưu trữ dữ liệu không nhạy cảm (preferences, cache)

#### `core/error/`
- **Error models**: Định nghĩa các loại lỗi (NetworkError, ServerError, etc.)
- **Error handlers**: Xử lý và chuyển đổi lỗi
- **Exception mappers**: Map exception từ các layer thành error models

#### `core/utils/`
- **Constants**: Các hằng số dùng chung
- **Extensions**: Dart extensions (String, DateTime, etc.)
- **Validators**: Validation functions
- **Helpers**: Các hàm tiện ích

### 2. Features Module (`lib/features/`)

Mỗi feature là một module độc lập, tuân theo Clean Architecture với 3 lớp:

#### 2.1. Presentation Layer (`presentation/`)

**Trách nhiệm:**
- UI components (Widgets, Screens, Pages)
- State management (Bloc, Provider, Riverpod, etc.)
- User interactions
- Input validation (UI level)

**Cấu trúc thường có:**
```
presentation/
├── pages/              # Các màn hình chính
├── widgets/            # Các widget tái sử dụng trong feature
├── bloc/               # State management (nếu dùng Bloc)
│   ├── events/
│   ├── states/
│   └── bloc/
└── models/             # UI models (nếu cần)
```

**Dependency rule:** Chỉ phụ thuộc vào Domain layer

#### 2.2. Domain Layer (`domain/`)

**Trách nhiệm:**
- Business logic thuần túy
- Entities (domain models)
- Use cases (business rules)
- Repository interfaces (abstract)

**Cấu trúc thường có:**
```
domain/
├── entities/           # Domain models (business objects)
├── repositories/       # Repository interfaces (abstract)
├── usecases/          # Business logic use cases
└── exceptions/        # Domain-specific exceptions
```

**Dependency rule:** 
- Không phụ thuộc vào bất kỳ layer nào khác
- Pure Dart code, không có Flutter dependencies

#### 2.3. Data Layer (`data/`)

**Trách nhiệm:**
- Implement repository interfaces từ Domain layer
- Data sources (Remote API, Local database)
- Data models (DTOs - Data Transfer Objects)
- Mappers (chuyển đổi giữa DTOs và Entities)

**Cấu trúc thường có:**
```
data/
├── datasources/       # Data sources
│   ├── remote/        # API calls
│   └── local/         # Local database/cache
├── models/            # DTOs (Data Transfer Objects)
├── repositories/      # Repository implementations
└── mappers/           # Mappers (DTO <-> Entity)
```

**Dependency rule:** 
- Phụ thuộc vào Domain layer (implement interfaces)
- Sử dụng Core module (network, storage)

## Luồng dữ liệu (Data Flow)

```
User Action (UI)
    ↓
Presentation Layer (Bloc/Provider)
    ↓
Domain Layer (UseCase)
    ↓
Domain Layer (Repository Interface)
    ↓
Data Layer (Repository Implementation)
    ↓
Data Layer (DataSource - API/Database)
    ↓
Response flows back up through layers
```

### Ví dụ luồng xác thực:

1. **Presentation**: User nhập email/password → Bloc nhận event
2. **Domain**: Bloc gọi `LoginUseCase`
3. **Domain**: `LoginUseCase` gọi `AuthRepository.login()`
4. **Data**: `AuthRepositoryImpl` implement `AuthRepository`
5. **Data**: Gọi `AuthRemoteDataSource.login()` (sử dụng Dio từ core/network)
6. **Data**: Map response DTO → Entity
7. **Domain**: Trả về Entity cho UseCase
8. **Presentation**: Bloc nhận Entity → emit state → UI update

## Dependency Rules (Quy tắc phụ thuộc)

### Nguyên tắc Dependency Inversion:
- **Presentation** → **Domain** (phụ thuộc vào Domain)
- **Data** → **Domain** (implement interfaces từ Domain)
- **Domain** → **Không phụ thuộc gì** (pure business logic)

### Core Module:
- Có thể được sử dụng bởi bất kỳ layer nào
- Không phụ thuộc vào Features

## Ví dụ cấu trúc một Feature hoàn chỉnh

### Feature: Auth

```
features/auth/
├── data/
│   ├── datasources/
│   │   ├── auth_remote_data_source.dart    # API calls
│   │   └── auth_local_data_source.dart     # Local storage
│   ├── models/
│   │   ├── user_dto.dart                   # DTO từ API
│   │   └── login_request_dto.dart
│   ├── repositories/
│   │   └── auth_repository_impl.dart       # Implement AuthRepository
│   └── mappers/
│       └── user_mapper.dart                # DTO <-> Entity
│
├── domain/
│   ├── entities/
│   │   └── user.dart                       # Domain model
│   ├── repositories/
│   │   └── auth_repository.dart            # Interface
│   └── usecases/
│       ├── login_usecase.dart
│       ├── logout_usecase.dart
│       └── get_current_user_usecase.dart
│
└── presentation/
    ├── pages/
    │   ├── login_page.dart
    │   └── register_page.dart
    ├── widgets/
    │   ├── login_form.dart
    │   └── password_field.dart
    └── bloc/
        ├── auth_event.dart
        ├── auth_state.dart
        └── auth_bloc.dart
```

## Best Practices

### 1. Naming Conventions
- **Entities**: `User`, `Product`, `Order` (không có suffix)
- **DTOs**: `UserDto`, `ProductDto` (có suffix `Dto`)
- **UseCases**: `LoginUseCase`, `GetProductsUseCase` (có suffix `UseCase`)
- **Repositories**: `AuthRepository` (interface), `AuthRepositoryImpl` (implementation)
- **DataSources**: `AuthRemoteDataSource`, `ProductLocalDataSource`

### 2. Dependency Injection
- Sử dụng `get_it`, `injectable`, hoặc `riverpod` để quản lý dependencies
- Inject dependencies từ ngoài vào, không tạo instance trực tiếp trong class

### 3. Error Handling
- Domain layer throw domain exceptions
- Data layer catch và map thành domain exceptions
- Presentation layer catch và hiển thị user-friendly messages

### 4. Testing
- **Domain**: Unit tests cho UseCases và Entities
- **Data**: Unit tests cho Repositories và DataSources (mock API)
- **Presentation**: Widget tests và Bloc tests

### 5. Code Organization
- Mỗi file chỉ nên có một class/function chính
- Group related files trong cùng một folder
- Export files thông qua `barrel files` (index.dart) nếu cần

## Lợi ích của kiến trúc này

✅ **Scalability**: Dễ thêm features mới mà không ảnh hưởng features cũ  
✅ **Maintainability**: Code được tổ chức rõ ràng, dễ tìm và sửa  
✅ **Testability**: Các layer độc lập, dễ mock và test  
✅ **Team Collaboration**: Nhiều developer có thể làm việc song song trên các features khác nhau  
✅ **Reusability**: Core module và domain logic có thể tái sử dụng  
✅ **Separation of Concerns**: Mỗi layer có trách nhiệm rõ ràng  

## Tài liệu tham khảo

- [Clean Architecture by Robert C. Martin](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Flutter Clean Architecture](https://resocoder.com/2019/08/27/flutter-tdd-clean-architecture-course-1-explanation-project-structure/)
- [Feature-first Architecture](https://medium.com/flutter-community/flutter-architecture-blueprints-1-1-architecture-overview-2e8a0b0c4e0e)
