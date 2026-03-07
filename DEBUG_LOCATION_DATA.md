# Debug: Location Data vẫn NULL

## Vấn đề
API `/api/orders/{id}/tracking` vẫn trả về `null` cho tất cả location fields:
- `shopLat`, `shopLng` = null
- `customerLat`, `customerLng` = null  
- `shipperCurrentLat`, `shipperCurrentLng` = null

## Các nguyên nhân có thể

### 1. **Backend chưa implement đúng**
Backend có thể đã thêm field vào DTO nhưng chưa populate data trong service.

**Cách kiểm tra:**
- Xem raw response từ API trong console logs (đã thêm debug logs)
- Kiểm tra xem backend có trả về field `shopLat`, `shopLng`, etc. trong JSON không

**Fix:**
- Backend cần implement logic để lấy shop location, customer location, shipper location
- Xem file `BACKEND_ORDER_TRACKING_LOCATION_PROMPT.md` để biết cách implement

### 2. **Shop Location chưa có trong database**
Backend cần có địa chỉ cửa hàng (shop address) với lat/lng.

**Fix:**
- Tạo bảng `Shop` với `latitude`, `longitude`
- Hoặc hardcode shop location trong backend code (ví dụ: Hà Nội: 21.0285, 105.8542)

### 3. **Customer Location chưa được geocode**
Order có `deliveryAddress` nhưng chưa được convert sang lat/lng.

**Fix:**
- Khi tạo order, geocode địa chỉ giao hàng và lưu `deliveryLat`, `deliveryLng` vào Order
- Hoặc geocode realtime khi gọi tracking API (nhưng sẽ chậm hơn)

### 4. **Shipper chưa gửi location**
Shipper chưa bắt đầu tracking hoặc chưa gửi location data lên server.

**Fix:**
- Shipper app cần gọi `POST /api/orders/{id}/shipper-location` với lat/lng
- Backend cần lưu location này vào database
- Tracking API cần lấy location mới nhất của shipper

## Cách debug

### Bước 1: Kiểm tra raw API response
Xem console logs khi gọi tracking API:
```
📥 Order tracking response data (raw): {...}
📥 Location fields in data:
  - shopLat: null (type: Null)
  - shopLng: null (type: Null)
  ...
```

**Nếu tất cả đều null:**
- Backend chưa populate data → Cần fix backend

**Nếu có giá trị nhưng parse ra null:**
- Có thể do type mismatch (ví dụ: backend trả về string "21.0285" thay vì number 21.0285)
- Cần check type trong logs

### Bước 2: Test API trực tiếp
Dùng Postman/Thunder Client để test:
```
GET http://localhost:5000/api/orders/7/tracking
Authorization: Bearer {token}
```

Xem response JSON có các field location không.

### Bước 3: Kiểm tra backend code
1. **Shop Location:**
   - Backend có lấy shop location không?
   - Có hardcode hoặc lấy từ database không?

2. **Customer Location:**
   - Order có field `deliveryLat`, `deliveryLng` không?
   - Có geocode `deliveryAddress` không?

3. **Shipper Location:**
   - Có bảng lưu shipper location không?
   - Có lấy location mới nhất của shipper cho order này không?

## Quick Fix (Tạm thời)

Nếu backend chưa implement, có thể hardcode trong backend để test:

```csharp
// Trong OrderTrackingService
public async Task<OrderTrackingResponseDto> GetOrderTracking(int orderId)
{
    var order = await _orderRepository.GetByIdAsync(orderId);
    
    return new OrderTrackingResponseDto
    {
        OrderId = order.Id,
        CurrentStatus = order.Status,
        // ... other fields ...
        
        // ⭐ HARDCODE để test (sau này sẽ lấy từ database)
        ShopLat = 21.0285,  // Hà Nội
        ShopLng = 105.8542,
        CustomerLat = 21.0300,  // Địa chỉ khách hàng (tạm thời)
        CustomerLng = 105.8600,
        ShipperCurrentLat = null,  // Chưa có shipper location
        ShipperCurrentLng = null,
    };
}
```

## Expected Response Format

Backend cần trả về JSON như sau:

```json
{
  "code": 200,
  "message": "Success",
  "data": {
    "orderId": 7,
    "currentStatus": "shipping",
    "shopLat": 21.0285,        // ⭐ PHẢI CÓ
    "shopLng": 105.8542,       // ⭐ PHẢI CÓ
    "customerLat": 21.0300,    // ⭐ PHẢI CÓ
    "customerLng": 105.8600,   // ⭐ PHẢI CÓ
    "shipperCurrentLat": null, // Có thể null nếu shipper chưa di chuyển
    "shipperCurrentLng": null,
    ...
  }
}
```

## Next Steps

1. **Xem console logs** để xem raw response từ backend
2. **Test API trực tiếp** bằng Postman để xem backend có trả về location không
3. **Nếu backend chưa implement:** Gửi lại file `BACKEND_ORDER_TRACKING_LOCATION_PROMPT.md` cho AI backend
4. **Nếu backend đã implement nhưng vẫn null:** Kiểm tra database có data không, hoặc geocoding có hoạt động không
