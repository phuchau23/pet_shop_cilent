## Phân chia Data Storage: FE vs BE

### Backend (BE) - Lưu trong Database (PostgreSQL)

**Bảng `orders`:**
```sql
- order_id (PK)
- user_id (FK)
- order_status (Pending, Confirmed, Shipping, Delivered, Cancelled)
- total_amount
- created_at
- updated_at
```

**Bảng `order_items`:**
```sql
- order_item_id (PK)
- order_id (FK)
- product_id (FK)
- product_size_id (FK)
- quantity
- unit_price
- subtotal
```

**Bảng `order_addresses` (MỚI):**
```sql
- address_id (PK)
- order_id (FK)
- address_type (Pickup/Store, Delivery)
- address_text (full address string)
- latitude (double)
- longitude (double)
- recipient_name
- recipient_phone
- created_at
```

**Bảng `shippers` (nếu có):**
```sql
- shipper_id (PK)
- user_id (FK) - link với user table
- is_available (boolean)
- current_latitude (double, nullable)
- current_longitude (double, nullable)
- last_location_update (datetime, nullable)
```

**Bảng `order_shippers` (MỚI - link order với shipper):**
```sql
- order_shipper_id (PK)
- order_id (FK)
- shipper_id (FK)
- assigned_at (datetime)
- pickup_latitude (double) - vị trí shipper khi nhận đơn
- pickup_longitude (double)
- delivery_latitude (double) - từ order_addresses
- delivery_longitude (double)
- estimated_distance (double, mét) - tính từ OSRM
- estimated_duration (int, giây)
- route_polyline (text, nullable) - encoded polyline từ OSRM
- status (Assigned, PickingUp, OnTheWay, Delivered)
```

### Frontend (FE) - Lưu Local (Isar + SharedPreferences)

**Isar Database (Local):**
- `CartModel` + `CartItemModel` - Giỏ hàng (đã có)
- **KHÔNG lưu order** - Order chỉ lưu trên BE sau khi submit

**SharedPreferences:**
- User info (đã có)
- Token (đã có)
- **MỚI: Store Location** (cố định):
  ```dart
  static const String _keyStoreLat = 'store_latitude';
  static const String _keyStoreLng = 'store_longitude';
  static const String _keyStoreAddress = 'store_address';
  ```

**In-Memory (State Management - Riverpod):**
- Selected address (tạm thời, chưa submit)
- Route information (distance, duration, polyline)
- Current location (GPS) - không lưu, chỉ dùng khi cần

### API Endpoints cần có

**POST `/api/orders`** - Tạo đơn hàng:
```json
Request:
{
  "userId": 1,
  "items": [
    {
      "productId": 1,
      "productSizeId": 2,
      "quantity": 3
    }
  ],
  "deliveryAddress": {
    "addressText": "123 Đường ABC, Quận 1, HCM",
    "latitude": 10.762622,
    "longitude": 106.660172,
    "recipientName": "Nguyễn Văn A",
    "recipientPhone": "0901234567"
  },
  "voucherCode": "DISCOUNT10" // nullable
}

Response:
{
  "orderId": 123,
  "status": "Pending",
  "totalAmount": 500000,
  "estimatedDeliveryTime": "2024-01-15T14:00:00Z"
}
```

**GET `/api/orders/{orderId}`** - Lấy chi tiết đơn hàng:
```json
Response:
{
  "orderId": 123,
  "status": "Shipping",
  "items": [...],
  "deliveryAddress": {...},
  "shipper": {
    "shipperId": 5,
    "name": "Shipper A",
    "phone": "0912345678",
    "currentLocation": {
      "latitude": 10.770000,
      "longitude": 106.670000
    }
  },
  "route": {
    "distance": 5200, // mét
    "duration": 900, // giây
    "polyline": "encoded_polyline_string"
  }
}
```

**GET `/api/orders`** - Lấy danh sách đơn hàng của user:
```json
Query params: ?userId=1&status=Pending
```

**POST `/api/orders/{orderId}/assign-shipper`** (Admin/System):
```json
Request:
{
  "shipperId": 5
}
```

**PUT `/api/shippers/{shipperId}/location`** (Shipper app):
```json
Request:
{
  "latitude": 10.770000,
  "longitude": 106.670000
}
```

## Cách thức xây dựng

### Phase 1: FE - Location & Address Selection

1. **FE tính toán route** (OSRM) → chỉ để hiển thị cho user
2. **FE lưu tạm** địa chỉ đã chọn trong state (Riverpod)
3. **FE gửi lên BE** khi submit order:
   - Address text + coordinates
   - **KHÔNG gửi route** (BE sẽ tính lại hoặc FE tính và gửi)

### Phase 2: BE - Order Creation

1. **BE nhận order** từ FE
2. **BE lưu vào DB**:
   - Order + OrderItems
   - Delivery Address (từ request)
   - Store Address (hardcode hoặc config)
3. **BE tính route** (có thể dùng OSRM hoặc service khác):
   - Store → Delivery Address
   - Lưu distance, duration, polyline vào `order_shippers`
4. **BE assign shipper** (tự động hoặc manual):
   - Tìm shipper available gần nhất
   - Lưu vào `order_shippers`

### Phase 3: Shipper App (tương lai)

1. **Shipper nhận đơn** → BE gửi thông tin:
   - Order details
   - Delivery address
   - Route (polyline)
2. **Shipper update location** → BE lưu vào `shippers.current_latitude/longitude`
3. **Shipper app hiển thị**:
   - Bản đồ với route
   - Vị trí shipper (real-time)
   - Vị trí delivery

### Data Flow Diagram

```
┌─────────────┐
│   User FE   │
└──────┬──────┘
       │ 1. Chọn địa chỉ
       │ 2. FE tính route (OSRM) - chỉ để hiển thị
       │ 3. Submit order
       ↓
┌─────────────┐
│   Backend   │
└──────┬──────┘
       │ 4. Lưu order + address vào DB
       │ 5. BE tính route (Store → Delivery)
       │ 6. Assign shipper
       ↓
┌─────────────┐
│  Database   │
│ - orders    │
│ - addresses │
│ - route     │
└─────────────┘
```

## Implementation Strategy

### FE Implementation:
1. **Tính route trên FE** (OSRM) → chỉ để preview cho user
2. **Gửi địa chỉ + coordinates** lên BE khi submit
3. **KHÔNG lưu route** vào local DB (chỉ lưu trong state tạm thời)
4. **Lưu store location** trong SharedPreferences (config)

### BE Implementation:
1. **Nhận order** từ FE
2. **Lưu address** vào `order_addresses`
3. **Tính route** (có thể dùng OSRM hoặc service khác)
4. **Lưu route info** vào `order_shippers` (distance, duration, polyline)
5. **Assign shipper** và trả về order details

### Shipper App (tương lai):
1. **Poll hoặc WebSocket** để nhận đơn mới
2. **Update location** định kỳ lên BE
3. **Hiển thị route** từ polyline đã lưu trong DB

## Notes

- OSRM public API có rate limit nhưng đủ cho development/testing
- Production có thể tự host OSRM server hoặc dùng GraphHopper
- `flutter_map` sử dụng tile server của OpenStreetMap (miễn phí)
- Cần xử lý offline fallback (cache bản đồ)
- **Route tính 2 lần**: FE (preview) + BE (lưu vào DB)
- **Polyline có thể lớn** → cân nhắc compression hoặc chỉ lưu khi cần