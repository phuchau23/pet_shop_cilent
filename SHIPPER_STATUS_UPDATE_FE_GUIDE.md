# Hướng Dẫn FE: Shipper Update Status Đơn Hàng

## Mục đích
Trang dành cho shipper để xem danh sách đơn hàng và cập nhật status (nhận đơn → đang giao → đã giao).

## Luồng hoạt động

### 1. Shipper xem danh sách đơn hàng của mình

#### API Endpoint
```
GET /api/orders/shipper/my-orders?status={status}
```

#### Authentication
- **Required**: JWT Token với role "Shipper" trong Authorization header
- Format: `Authorization: Bearer {token}`
- **Không cần truyền `shipper_id`** - Tự động lấy từ token

#### Query Parameters
- `status` (optional): Lọc theo status ("confirmed", "shipping", "delivered")

#### Example Request
```http
GET /api/orders/shipper/my-orders?status=confirmed
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### 1.1. Shipper xem đơn hàng đang chờ nhận (chưa có shipper)

#### API Endpoint
```
GET /api/orders/shipper/available
```

#### Authentication
- **Required**: JWT Token với role "Shipper" trong Authorization header
- Format: `Authorization: Bearer {token}`

#### Mô tả
Lấy danh sách các đơn hàng đã được shop xác nhận (status = "confirmed") nhưng chưa có shipper nhận (shipperId = null).

#### Example Request
```http
GET /api/orders/shipper/available
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

#### Response Structure
```typescript
interface ApiResponse<T> {
  success: boolean;
  data: T;
  message: string;
  statusCode: number;
}

interface OrderResponse {
  id: number;
  customerName: string;
  customerPhone: string;
  fullAddress: string;
  shopLat: number;
  shopLng: number;
  shopName: string;
  customerLat: number | null;
  customerLng: number | null;
  estimatedDeliveryMinutes: number | null;
  estimatedDistanceMeters: number | null;
  shipperId: number | null;
  status: string;
  totalPrice: number | null;
  voucherDiscount: number | null;
  finalAmount: number | null;
  voucherCode: string | null;
  note: string | null;
  deliveryFee: number | null;
  paymentMethod: "COD" | null;
  createdAt: string;
  updatedAt: string;
  items: OrderItemResponse[];
}
```

### 2. Shipper nhận đơn (Chấp nhận đơn)

#### API Endpoint
```
PATCH /api/orders/{id}/shipper-status
```

#### Authentication
- **Required**: JWT Token với role "Shipper" trong Authorization header
- Format: `Authorization: Bearer {token}`
- **ShipperId trong request phải khớp với userId từ token**

#### Request Body
```typescript
interface UpdateShipperStatusRequest {
  shipperId: number;  // Phải khớp với userId từ token
  status: "shipping" | "delivered";
}
```

#### Example Request
```http
PATCH /api/orders/1/shipper-status
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json

{
  "shipperId": 5,
  "status": "shipping"
}
```

#### Logic
- Khi shipper chấp nhận đơn (confirmed → shipping):
  - Nếu order chưa có `shipperId` → Tự động gán `shipperId` vào order
  - Nếu order đã có `shipperId` khác → Báo lỗi (đơn đã được gán cho shipper khác)
- Status phải là "confirmed" mới có thể chuyển sang "shipping"

#### Example Response (Success)
```json
{
  "success": true,
  "data": {
    "id": 1,
    "status": "shipping",
    "shipperId": 5,
    // ... other fields
  },
  "message": "Order status updated successfully by shipper",
  "statusCode": 200
}
```

#### Error Responses

**401 Unauthorized** - Shipper không có quyền
```json
{
  "success": false,
  "data": null,
  "message": "Unauthorized",
  "statusCode": 401
}
```

**400 Bad Request** - Status transition không hợp lệ
```json
{
  "success": false,
  "data": null,
  "message": "Invalid status transition from confirmed to delivered",
  "statusCode": 400
}
```

### 3. Shipper cập nhật "Đã giao hàng"

#### API Endpoint
```
PATCH /api/orders/{id}/shipper-status
```

#### Authentication
- **Required**: JWT Token với role "Shipper" trong Authorization header
- Format: `Authorization: Bearer {token}`
- **ShipperId trong request phải khớp với userId từ token**

#### Request Body
```json
{
  "shipperId": 5,
  "status": "delivered"
}
```

#### Example Request
```http
PATCH /api/orders/1/shipper-status
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json

{
  "shipperId": 5,
  "status": "delivered"
}
```

#### Logic
- Status phải là "shipping" mới có thể chuyển sang "delivered"
- Phải validate `shipperId` khớp với shipper được gán

## UI/UX Gợi ý

### 1. Danh sách đơn hàng cho shipper

#### Tab/Filter theo status:
- **Chờ nhận đơn** (`status=confirmed`): Đơn hàng đã được shop xác nhận, chưa có shipper
- **Đang giao** (`status=shipping`): Đơn hàng shipper đang giao
- **Đã giao** (`status=delivered`): Đơn hàng đã giao xong

#### Card hiển thị:
- Order ID
- Tên khách hàng
- Địa chỉ giao hàng
- Khoảng cách (nếu có)
- Thời gian dự kiến
- Tổng tiền
- Button "Nhận đơn" (nếu status = confirmed)
- Button "Đã giao hàng" (nếu status = shipping)

### 2. Button Actions

#### Button "Nhận đơn" (status = confirmed)
- Click → Gọi API `PATCH /api/orders/{id}/shipper-status` với `status: "shipping"`
- Show loading state
- Success → Cập nhật UI, chuyển sang tab "Đang giao"
- Error → Show error message

#### Button "Đã giao hàng" (status = shipping)
- Click → Confirm dialog "Xác nhận đã giao hàng?"
- Confirm → Gọi API `PATCH /api/orders/{id}/shipper-status` với `status: "delivered"`
- Success → Cập nhật UI, chuyển sang tab "Đã giao"

### 3. Map View (Optional)
- Nếu có `customerLat` và `customerLng`:
  - Hiển thị map với route từ shop đến customer
  - Có thể dùng OSRM để vẽ route

## Code Example (React/TypeScript)

```typescript
// Fetch orders for shipper (tự động lấy shipperId từ token)
const fetchShipperOrders = async (token: string, status?: string) => {
  const url = `/api/orders/shipper/my-orders${status ? `?status=${status}` : ''}`;
  const response = await fetch(url, {
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    }
  });
  
  const data: ApiResponse<OrderResponse[]> = await response.json();
  
  if (data.success) {
    return data.data;
  } else {
    throw new Error(data.message);
  }
};

// Fetch available orders (chưa có shipper)
const fetchAvailableOrders = async (token: string) => {
  const response = await fetch('/api/orders/shipper/available', {
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    }
  });
  
  const data: ApiResponse<OrderResponse[]> = await response.json();
  
  if (data.success) {
    return data.data;
  } else {
    throw new Error(data.message);
  }
};

// Update shipper status
const updateShipperStatus = async (
  token: string,
  orderId: number, 
  shipperId: number,  // Phải lấy từ token, không phải từ input
  status: "shipping" | "delivered"
) => {
  const response = await fetch(`/api/orders/${orderId}/shipper-status`, {
    method: 'PATCH',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      shipperId,  // Phải khớp với userId từ token
      status,
    }),
  });
  
  const data: ApiResponse<OrderResponse> = await response.json();
  
  if (data.success) {
    return data.data;
  } else {
    throw new Error(data.message);
  }
};

// Component
const ShipperOrdersPage = () => {
  const [orders, setOrders] = useState<OrderResponse[]>([]);
  const [availableOrders, setAvailableOrders] = useState<OrderResponse[]>([]);
  const [selectedStatus, setSelectedStatus] = useState<string>('confirmed');
  const [shipperId, setShipperId] = useState<number | null>(null);
  const token = localStorage.getItem('token'); // hoặc từ context/state
  
  // Lấy shipperId từ token khi component mount
  useEffect(() => {
    if (token) {
      // Decode JWT token để lấy userId (hoặc gọi API /api/auth/profile)
      // Ví dụ đơn giản: parse từ token
      try {
        const payload = JSON.parse(atob(token.split('.')[1]));
        setShipperId(parseInt(payload.UserId || payload.sub));
      } catch (e) {
        console.error('Failed to parse token', e);
      }
    }
  }, [token]);
  
  useEffect(() => {
    if (token && shipperId) {
      fetchShipperOrders(token, selectedStatus).then(setOrders);
      fetchAvailableOrders(token).then(setAvailableOrders);
    }
  }, [token, shipperId, selectedStatus]);
  
  const handleAcceptOrder = async (orderId: number) => {
    if (!token || !shipperId) return;
    
    try {
      await updateShipperStatus(token, orderId, shipperId, 'shipping');
      // Refresh orders
      fetchShipperOrders(token, selectedStatus).then(setOrders);
      fetchAvailableOrders(token).then(setAvailableOrders);
    } catch (error) {
      alert('Lỗi: ' + (error instanceof Error ? error.message : 'Unknown error'));
    }
  };
  
  const handleDeliverOrder = async (orderId: number) => {
    if (!confirm('Xác nhận đã giao hàng?')) return;
    if (!token || !shipperId) return;
    
    try {
      await updateShipperStatus(token, orderId, shipperId, 'delivered');
      // Refresh orders
      fetchShipperOrders(token, selectedStatus).then(setOrders);
    } catch (error) {
      alert('Lỗi: ' + (error instanceof Error ? error.message : 'Unknown error'));
    }
  };
  
  return (
    <div>
      <Tabs>
        <Tab onClick={() => setSelectedStatus('confirmed')}>
          Chờ nhận đơn ({availableOrders.length})
        </Tab>
        <Tab onClick={() => setSelectedStatus('shipping')}>
          Đang giao
        </Tab>
        <Tab onClick={() => setSelectedStatus('delivered')}>
          Đã giao
        </Tab>
      </Tabs>
      
      {/* Tab: Chờ nhận đơn - Hiển thị available orders */}
      {selectedStatus === 'confirmed' && (
        <div>
          <h3>Đơn hàng đang chờ nhận</h3>
          {availableOrders.map(order => (
            <OrderCard key={order.id} order={order}>
              <Button onClick={() => handleAcceptOrder(order.id)}>
                Nhận đơn
              </Button>
            </OrderCard>
          ))}
        </div>
      )}
      
      {/* Tab: Đang giao / Đã giao - Hiển thị orders của shipper */}
      {selectedStatus !== 'confirmed' && (
        <div>
          {orders.map(order => (
            <OrderCard key={order.id} order={order}>
              {order.status === 'shipping' && (
                <Button onClick={() => handleDeliverOrder(order.id)}>
                  Đã giao hàng
                </Button>
              )}
            </OrderCard>
          ))}
        </div>
      )}
    </div>
  );
};
```

## Status Flow

```
confirmed (Đã xác nhận)
    ↓ [Shipper nhận đơn]
shipping (Đang giao hàng)
    ↓ [Shipper giao xong]
delivered (Đã giao hàng)
```

## Lưu ý

1. **Authentication**: Tất cả endpoints đều yêu cầu JWT token với role "Shipper"
2. **Shipper ID**: Tự động lấy từ token, không cần truyền trong query params
3. **Validation**: Backend sẽ validate shipperId trong request phải khớp với userId từ token
4. **Auto Refresh**: Có thể polling để cập nhật danh sách đơn hàng mới
5. **Error Handling**: Luôn handle các error cases:
   - 401 Unauthorized: Token không hợp lệ hoặc thiếu token
   - 403 Forbidden: ShipperId không khớp với token hoặc không có quyền
   - 400 Bad Request: Status transition không hợp lệ
   - 404 Not Found: Order không tồn tại

## API Endpoints Summary

| Endpoint | Method | Auth | Mô tả |
|----------|--------|------|-------|
| `/api/orders/shipper/my-orders` | GET | Shipper | Lấy danh sách đơn hàng của shipper (từ token) |
| `/api/orders/shipper/available` | GET | Shipper | Lấy danh sách đơn hàng đang chờ nhận (chưa có shipper) |
| `/api/orders/{id}/shipper-status` | PATCH | Shipper | Cập nhật status đơn hàng (shipperId phải khớp với token) |
