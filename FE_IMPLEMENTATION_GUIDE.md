# 🎯 HƯỚNG DẪN IMPLEMENT FRONTEND - FOOD BOOKING SYSTEM

## 📋 TỔNG QUAN

Hệ thống Food Booking có các tính năng chính:
- **Đặt hàng** với tính toán phí ship tự động dựa trên khoảng cách
- **Voucher** với validation và tính discount tự động
- **Payment** hỗ trợ COD (Cash on Delivery)
- **Preview Order** để hiển thị giá trước khi đặt hàng

**QUAN TRỌNG**: TẤT CẢ LOGIC TÍNH TOÁN ĐỀU Ở BACKEND. Frontend CHỈ HIỂN THỊ và GỬI DỮ LIỆU.

---

## 🔗 API ENDPOINTS

### Base URL
```
http://localhost:5000/api
```

### Response Format
Tất cả API đều trả về format:
```typescript
{
  success: boolean;
  message: string;
  data: T; // Generic type
  errors?: string[];
}
```

---

## 📍 1. ESTIMATE DELIVERY (Tính phí ship)

### Endpoint
```
POST /api/orders/estimate-delivery
```

### Request Body
```typescript
{
  customerLat: number;      // Vĩ độ địa chỉ khách hàng
  customerLng: number;      // Kinh độ địa chỉ khách hàng
  orderTotal?: number;      // OPTIONAL: Tổng tiền đơn hàng (để tính free delivery)
}
```

### Response
```typescript
{
  success: true,
  message: "Delivery time estimated successfully",
  data: {
    shopLat: number;
    shopLng: number;
    shopName: string;              // "Đại Học FPT University"
    customerLat: number;
    customerLng: number;
    estimatedDeliveryMinutes: number;  // Thời gian giao hàng (phút)
    estimatedDistanceMeters: number;    // Khoảng cách (mét)
    estimatedDistanceKm: number;        // Khoảng cách (km)
    deliveryFee: number;                // ⭐ PHÍ SHIP (VNĐ) - ĐÃ ĐƯỢC TÍNH TỰ ĐỘNG
    routeCoordinates?: number[][];      // [[lng, lat], ...] để vẽ bản đồ
  }
}
```

### Logic Backend
- **Phí ship = BaseFee (15,000 VNĐ) + (Km × FeePerKm (5,000 VNĐ/km))**
- **Miễn phí ship** nếu `orderTotal >= 500,000 VNĐ`
- **Giới hạn giao hàng**: Tối đa 20km
- Nếu khoảng cách > 20km → API trả về error: "Khoảng cách giao hàng vượt quá giới hạn 20km"

### Ví dụ Code
```typescript
// Khi user chọn địa chỉ giao hàng
const estimateDelivery = async (lat: number, lng: number, orderTotal?: number) => {
  try {
    const response = await fetch('/api/orders/estimate-delivery', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        customerLat: lat,
        customerLng: lng,
        orderTotal: orderTotal // Gửi tổng tiền để tính free delivery
      })
    });
    
    const result = await response.json();
    
    if (result.success) {
      // Sử dụng result.data.deliveryFee
      setDeliveryFee(result.data.deliveryFee);
      setEstimatedTime(result.data.estimatedDeliveryMinutes);
      setDistance(result.data.estimatedDistanceKm);
    } else {
      // Handle error
      alert(result.message);
    }
  } catch (error) {
    console.error('Error estimating delivery:', error);
  }
};
```

---

## 🎫 2. VOUCHER APIs

### 2.1. Lấy danh sách voucher đang hoạt động
```
GET /api/vouchers
```

### Response
```typescript
{
  success: true,
  data: [
    {
      id: number;
      code: string;              // "GIAM10"
      name: string;               // "Giảm 10% cho đơn hàng"
      description: string;
      discountType: "percentage" | "fixed_amount";
      discountValue: number;     // 10 (nếu %) hoặc 50000 (nếu fixed)
      minOrderAmount?: number;   // Đơn hàng tối thiểu
      maxDiscountAmount?: number; // Giảm tối đa (nếu %)
      usageLimit?: number;        // Giới hạn số lần sử dụng
      usedCount: number;
      startDate?: string;         // ISO date
      endDate?: string;           // ISO date
      isActive: boolean;
    }
  ]
}
```

### 2.2. Validate Voucher (Kiểm tra voucher có hợp lệ không)
```
POST /api/vouchers/validate
```

### Request Body
```typescript
{
  code: string;           // Mã voucher
  orderAmount: number;    // Tổng tiền đơn hàng (trước giảm giá)
}
```

### Response
```typescript
{
  success: true,
  data: VoucherResponse  // Cùng format như trên
}
```

### Error Cases
- `400`: Voucher không hợp lệ (hết hạn, hết lượt, không đủ điều kiện)
- `404`: Voucher không tồn tại

### Ví dụ Code
```typescript
const validateVoucher = async (code: string, orderTotal: number) => {
  try {
    const response = await fetch('/api/vouchers/validate', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        code: code.toUpperCase().trim(),
        orderAmount: orderTotal
      })
    });
    
    const result = await response.json();
    
    if (result.success) {
      const voucher = result.data;
      
      // Tính discount (chỉ để hiển thị, BE sẽ tính lại khi đặt hàng)
      let discount = 0;
      if (voucher.discountType === 'percentage') {
        discount = orderTotal * (voucher.discountValue / 100);
        if (voucher.maxDiscountAmount && discount > voucher.maxDiscountAmount) {
          discount = voucher.maxDiscountAmount;
        }
      } else {
        discount = voucher.discountValue;
        if (discount > orderTotal) discount = orderTotal;
      }
      
      setVoucherDiscount(discount);
      setVoucher(voucher);
      return true;
    } else {
      alert(result.message); // "Voucher đã hết hạn", "Đơn hàng tối thiểu 500,000 VNĐ", etc.
      return false;
    }
  } catch (error) {
    console.error('Error validating voucher:', error);
    return false;
  }
};
```

---

## 🛒 3. PREVIEW ORDER (Tính toán giá trước khi đặt hàng)

### Flow Preview Order

**BƯỚC 1**: User chọn sản phẩm → FE tính tổng tiền sản phẩm (chỉ để hiển thị)

**BƯỚC 2**: User chọn địa chỉ → Call `estimate-delivery` để lấy `deliveryFee`

**BƯỚC 3**: User nhập voucher (optional) → Call `validate-voucher` để lấy `voucherDiscount`

**BƯỚC 4**: Tính toán preview (CHỈ ĐỂ HIỂN THỊ):
```typescript
const calculatePreview = () => {
  const productTotal = items.reduce((sum, item) => sum + item.subtotal, 0);
  const deliveryFee = deliveryFeeFromAPI; // Từ estimate-delivery API
  const voucherDiscount = voucherDiscountFromAPI; // Từ validate-voucher API
  
  const totalBeforeDiscount = productTotal + deliveryFee;
  const finalAmount = totalBeforeDiscount - voucherDiscount;
  
  return {
    productTotal,
    deliveryFee,
    voucherDiscount,
    totalBeforeDiscount,
    finalAmount
  };
};
```

**LƯU Ý**: Preview này chỉ để hiển thị. Khi submit order, BE sẽ tính lại TẤT CẢ.

---

## 📦 4. CREATE ORDER (Đặt hàng)

### Endpoint
```
POST /api/orders
```

### Request Body
```typescript
{
  customer: {
    name: string;
    phone: string;
  };
  deliveryAddress: {
    addressDetail: string;      // "123 Đường ABC"
    wardCode?: number;           // Mã phường/xã
    districtCode?: number;       // Mã quận/huyện
    provinceCode?: number;       // Mã tỉnh/thành phố
    fullAddress?: string;        // "123 Đường ABC, Phường 1, Quận 1, TP.HCM"
    lat?: number;                 // Vĩ độ
    lng?: number;                 // Kinh độ
  };
  items: [
    {
      productId: number;
      productName: string;
      quantity: number;
      unitPrice: number;         // Giá từ ProductSize
      subtotal: number;          // unitPrice × quantity
    }
  ];
  totalPrice: number;            // Tổng tiền sản phẩm (items subtotal)
  voucherCode?: string;          // Mã voucher (optional)
  note?: string;                 // Ghi chú đơn hàng
  paymentMethod?: number;        // 1 = COD (Cash on Delivery), null = default COD
}
```

### Response
```typescript
{
  success: true,
  message: "Order created successfully",
  data: {
    id: number;
    customerName: string;
    customerPhone: string;
    fullAddress: string;
    estimatedDeliveryMinutes?: number;
    estimatedDistanceMeters?: number;
    status: "pending" | "confirmed" | "shipping" | "delivered" | "cancelled";
    totalPrice: number;           // Tổng tiền sản phẩm
    voucherDiscount?: number;     // Số tiền giảm từ voucher
    finalAmount: number;          // Tổng tiền cuối cùng (sau giảm giá)
    voucherCode?: string;        // Mã voucher đã áp dụng
    note?: string;
    createdAt: string;           // ISO date
    items: [
      {
        id: number;
        productId: number;
        productName: string;
        unitPrice: number;
        quantity: number;
        subtotal: number;
      }
    ]
  }
}
```

### Logic Backend (QUAN TRỌNG)
1. **BE tính lại `totalPrice`** từ items (validate giá từ DB)
2. **BE tính `deliveryFee`** dựa trên khoảng cách (nếu có lat/lng)
3. **BE validate và tính `voucherDiscount`** nếu có voucherCode
4. **BE tính `finalAmount`** = `totalPrice` + `deliveryFee` - `voucherDiscount`
5. **Payment Method**:
   - `COD (1)`: Thanh toán khi nhận hàng, status = "pending"
   - `null`: Default = COD

### Ví dụ Code
```typescript
const createOrder = async (orderData: CreateOrderRequest) => {
  try {
    const response = await fetch('/api/orders', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        customer: {
          name: orderData.customerName,
          phone: orderData.customerPhone
        },
        deliveryAddress: {
          addressDetail: orderData.addressDetail,
          fullAddress: orderData.fullAddress,
          lat: orderData.lat,
          lng: orderData.lng,
          wardCode: orderData.wardCode,
          districtCode: orderData.districtCode,
          provinceCode: orderData.provinceCode
        },
        items: orderData.items.map(item => ({
          productId: item.productId,
          productName: item.productName,
          quantity: item.quantity,
          unitPrice: item.unitPrice,
          subtotal: item.unitPrice * item.quantity
        })),
        totalPrice: orderData.items.reduce((sum, item) => 
          sum + (item.unitPrice * item.quantity), 0
        ),
        voucherCode: orderData.voucherCode || null,
        note: orderData.note || null,
        paymentMethod: 1 // COD
      })
    });
    
    const result = await response.json();
    
    if (result.success) {
      // Order created successfully
      // Redirect to order detail page
      router.push(`/orders/${result.data.id}`);
    } else {
      // Handle error
      alert(result.message);
    }
  } catch (error) {
    console.error('Error creating order:', error);
    alert('Có lỗi xảy ra khi đặt hàng');
  }
};
```

---

## 💰 5. LOGIC TÍNH TOÁN (Backend tự động)

### 5.1. Delivery Fee
```
Nếu orderTotal >= 500,000 VNĐ:
  deliveryFee = 0 (Miễn phí ship)
Ngược lại:
  deliveryFee = 15,000 + (distanceKm × 5,000)
  
Nếu distanceKm > 20:
  → Error: "Khoảng cách giao hàng vượt quá giới hạn 20km"
```

### 5.2. Voucher Discount
```
Nếu discountType === "percentage":
  discount = orderTotal × (discountValue / 100)
  Nếu maxDiscountAmount có giá trị và discount > maxDiscountAmount:
    discount = maxDiscountAmount
    
Nếu discountType === "fixed_amount":
  discount = discountValue
  Nếu discount > orderTotal:
    discount = orderTotal (không giảm quá tổng tiền)
```

### 5.3. Final Amount
```
finalAmount = totalPrice + deliveryFee - voucherDiscount
```

**LƯU Ý**: Tất cả tính toán này đều ở BE. FE chỉ cần gọi API và hiển thị kết quả.

---

## 🔄 6. FLOW ĐẶT HÀNG HOÀN CHỈNH

```
1. User chọn sản phẩm
   ↓
2. FE tính tổng tiền sản phẩm (chỉ để hiển thị)
   ↓
3. User chọn địa chỉ giao hàng
   ↓
4. FE call: POST /api/orders/estimate-delivery
   - Gửi: { customerLat, customerLng, orderTotal? }
   - Nhận: { deliveryFee, estimatedDeliveryMinutes, ... }
   ↓
5. FE hiển thị preview:
   - Tổng sản phẩm
   - Phí ship (từ deliveryFee)
   - Tổng trước giảm giá
   ↓
6. User nhập voucher (optional)
   ↓
7. FE call: POST /api/vouchers/validate
   - Gửi: { code, orderAmount }
   - Nhận: { voucher info } hoặc error
   ↓
8. FE tính và hiển thị discount (chỉ để preview)
   ↓
9. User xác nhận đặt hàng
   ↓
10. FE call: POST /api/orders
    - Gửi: { customer, deliveryAddress, items, totalPrice, voucherCode?, paymentMethod }
    ↓
11. BE tính lại TẤT CẢ:
    - Validate và tính lại totalPrice từ items
    - Tính deliveryFee từ khoảng cách
    - Validate và tính voucherDiscount
    - Tính finalAmount
    ↓
12. BE trả về OrderResponse với giá đã tính chính xác
    ↓
13. FE hiển thị thông tin đơn hàng đã tạo
```

---

## ⚠️ 7. ERROR HANDLING

### Estimate Delivery Errors
- `400`: "Khoảng cách giao hàng vượt quá giới hạn 20km"

### Voucher Validation Errors
- `400`: "Voucher không còn hoạt động"
- `400`: "Voucher chưa đến thời gian sử dụng"
- `400`: "Voucher đã hết hạn"
- `400`: "Voucher đã hết lượt sử dụng"
- `400`: "Đơn hàng tối thiểu {amount} VNĐ để sử dụng voucher này"
- `404`: "Voucher not found"

### Create Order Errors
- `400`: "Không thể áp dụng voucher: {message}"
- `400`: "Price mismatch for product {id}" (nếu giá sản phẩm thay đổi)

### Ví dụ Error Handling
```typescript
try {
  const response = await fetch('/api/orders', { ... });
  const result = await response.json();
  
  if (!result.success) {
    // Handle specific errors
    if (result.message.includes('voucher')) {
      // Voucher error
      setVoucherError(result.message);
      setVoucherCode('');
    } else if (result.message.includes('khoảng cách')) {
      // Distance error
      alert('Địa chỉ quá xa, vui lòng chọn địa chỉ khác');
    } else {
      // General error
      alert(result.message);
    }
  }
} catch (error) {
  console.error('Network error:', error);
  alert('Lỗi kết nối, vui lòng thử lại');
}
```

---

## 📝 8. TYPE DEFINITIONS (TypeScript)

```typescript
// Estimate Delivery
interface EstimateDeliveryRequest {
  customerLat: number;
  customerLng: number;
  orderTotal?: number;
}

interface EstimateDeliveryResponse {
  shopLat: number;
  shopLng: number;
  shopName: string;
  customerLat: number;
  customerLng: number;
  estimatedDeliveryMinutes: number;
  estimatedDistanceMeters: number;
  estimatedDistanceKm: number;
  deliveryFee: number;
  routeCoordinates?: number[][];
}

// Voucher
interface VoucherResponse {
  id: number;
  code: string;
  name: string;
  description?: string;
  discountType: 'percentage' | 'fixed_amount';
  discountValue: number;
  minOrderAmount?: number;
  maxDiscountAmount?: number;
  usageLimit?: number;
  usedCount: number;
  startDate?: string;
  endDate?: string;
  isActive: boolean;
  createdAt: string;
}

interface ValidateVoucherRequest {
  code: string;
  orderAmount: number;
}

// Order
interface CreateOrderRequest {
  customer: {
    name: string;
    phone: string;
  };
  deliveryAddress: {
    addressDetail: string;
    wardCode?: number;
    districtCode?: number;
    provinceCode?: number;
    fullAddress?: string;
    lat?: number;
    lng?: number;
  };
  items: {
    productId: number;
    productName: string;
    quantity: number;
    unitPrice: number;
    subtotal: number;
  }[];
  totalPrice: number;
  voucherCode?: string;
  note?: string;
  paymentMethod?: number; // 1 = COD
}

interface OrderResponse {
  id: number;
  customerName: string;
  customerPhone: string;
  fullAddress?: string;
  estimatedDeliveryMinutes?: number;
  estimatedDistanceMeters?: number;
  status: 'pending' | 'confirmed' | 'shipping' | 'delivered' | 'cancelled';
  totalPrice: number;
  voucherDiscount?: number;
  finalAmount: number;
  voucherCode?: string;
  note?: string;
  createdAt: string;
  items: {
    id: number;
    productId: number;
    productName: string;
    unitPrice: number;
    quantity: number;
    subtotal: number;
  }[];
}

// API Response Wrapper
interface ApiResponse<T> {
  success: boolean;
  message: string;
  data: T;
  errors?: string[];
}
```

---

## ✅ 9. CHECKLIST IMPLEMENTATION

- [ ] Tạo service/hook để call API `estimate-delivery`
- [ ] Tạo service/hook để call API `validate-voucher`
- [ ] Tạo service/hook để call API `create-order`
- [ ] Implement UI cho preview order (hiển thị productTotal, deliveryFee, voucherDiscount, finalAmount)
- [ ] Implement form đặt hàng với validation
- [ ] Handle errors từ API
- [ ] Loading states khi call API
- [ ] Success state sau khi đặt hàng thành công
- [ ] Redirect đến order detail page sau khi đặt hàng

---

## 🎯 TÓM TẮT QUAN TRỌNG

1. **TẤT CẢ TÍNH TOÁN Ở BACKEND**: FE chỉ hiển thị và gửi dữ liệu
2. **Preview chỉ để hiển thị**: Khi submit order, BE sẽ tính lại tất cả
3. **Delivery Fee**: Tự động tính từ khoảng cách, miễn phí nếu đơn >= 500k
4. **Voucher**: Phải validate trước khi áp dụng
5. **Payment Method**: Default là COD (1), có thể null
6. **Error Handling**: Luôn check `result.success` và hiển thị `result.message`

---

**Chúc bạn code vui vẻ! 🚀**
