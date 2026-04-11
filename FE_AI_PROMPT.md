# 🤖 PROMPT CHO AI FRONTEND DEVELOPER

Bạn là AI Frontend Developer. Nhiệm vụ của bạn là implement tính năng đặt hàng cho Food Booking System dựa trên các API đã có sẵn.

## ⚠️ QUY TẮC QUAN TRỌNG

1. **TẤT CẢ LOGIC TÍNH TOÁN ĐỀU Ở BACKEND** - Frontend CHỈ hiển thị và gửi dữ liệu
2. **KHÔNG tự tính toán** - Luôn gọi API để lấy kết quả từ BE
3. **Preview chỉ để hiển thị** - Khi submit order, BE sẽ tính lại tất cả

## 📋 API ENDPOINTS CẦN DÙNG

### 1. Estimate Delivery (Tính phí ship)
```
POST /api/orders/estimate-delivery
Body: { customerLat, customerLng, orderTotal? }
Response: { deliveryFee, estimatedDeliveryMinutes, estimatedDistanceKm, ... }
```

**Logic BE**: 
- Phí ship = 15,000 + (km × 5,000) VNĐ
- Miễn phí nếu orderTotal >= 500,000 VNĐ
- Giới hạn 20km

### 2. Validate Voucher
```
POST /api/vouchers/validate
Body: { code, orderAmount }
Response: { voucher info } hoặc error
```

**Logic BE**: 
- Validate voucher (hết hạn, hết lượt, điều kiện)
- Tính discount tự động

### 3. Create Order
```
POST /api/orders
Body: { customer, deliveryAddress, items, totalPrice, voucherCode?, paymentMethod? }
Response: { order với finalAmount đã được BE tính lại }
```

**Logic BE**: 
- Tính lại totalPrice từ items
- Tính deliveryFee từ khoảng cách
- Tính voucherDiscount
- Tính finalAmount = totalPrice + deliveryFee - voucherDiscount

## 🔄 FLOW ĐẶT HÀNG

1. User chọn sản phẩm → FE tính tổng (chỉ để hiển thị)
2. User chọn địa chỉ → Call `estimate-delivery` → Lấy `deliveryFee`
3. User nhập voucher → Call `validate-voucher` → Lấy `voucherDiscount`
4. FE hiển thị preview: `productTotal + deliveryFee - voucherDiscount`
5. User submit → Call `create-order` → BE tính lại TẤT CẢ và trả về

## 💡 VÍ DỤ CODE

```typescript
// 1. Estimate delivery
const estimateDelivery = async (lat: number, lng: number, orderTotal?: number) => {
  const res = await fetch('/api/orders/estimate-delivery', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ customerLat: lat, customerLng: lng, orderTotal })
  });
  const result = await res.json();
  if (result.success) {
    setDeliveryFee(result.data.deliveryFee); // Sử dụng deliveryFee từ BE
  }
};

// 2. Validate voucher
const validateVoucher = async (code: string, orderAmount: number) => {
  const res = await fetch('/api/vouchers/validate', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ code: code.trim().toUpperCase(), orderAmount })
  });
  const result = await res.json();
  if (result.success) {
    // Tính discount để preview (BE sẽ tính lại khi submit)
    const voucher = result.data;
    let discount = 0;
    if (voucher.discountType === 'percentage') {
      discount = orderAmount * (voucher.discountValue / 100);
      if (voucher.maxDiscountAmount && discount > voucher.maxDiscountAmount) {
        discount = voucher.maxDiscountAmount;
      }
    } else {
      discount = voucher.discountValue;
      if (discount > orderAmount) discount = orderAmount;
    }
    setVoucherDiscount(discount);
  } else {
    alert(result.message); // "Voucher đã hết hạn", etc.
  }
};

// 3. Create order
const createOrder = async (orderData: CreateOrderRequest) => {
  const res = await fetch('/api/orders', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      customer: { name: orderData.name, phone: orderData.phone },
      deliveryAddress: { ...orderData.address, lat: orderData.lat, lng: orderData.lng },
      items: orderData.items.map(item => ({
        productId: item.productId,
        productName: item.productName,
        quantity: item.quantity,
        unitPrice: item.unitPrice,
        subtotal: item.unitPrice * item.quantity
      })),
      totalPrice: orderData.items.reduce((sum, item) => sum + item.subtotal, 0),
      voucherCode: orderData.voucherCode || null,
      paymentMethod: 1 // COD
    })
  });
  const result = await res.json();
  if (result.success) {
    // BE đã tính lại finalAmount, sử dụng result.data.finalAmount
    router.push(`/orders/${result.data.id}`);
  } else {
    alert(result.message);
  }
};
```

## ✅ CHECKLIST

- [ ] Call API estimate-delivery khi user chọn địa chỉ
- [ ] Call API validate-voucher khi user nhập voucher
- [ ] Hiển thị preview: productTotal + deliveryFee - voucherDiscount
- [ ] Call API create-order khi user submit
- [ ] Sử dụng finalAmount từ BE response (KHÔNG tự tính)
- [ ] Handle errors từ API
- [ ] Loading states
- [ ] Success redirect

## 🎯 NHỚ KỸ

- **KHÔNG tự tính deliveryFee** - Luôn lấy từ API estimate-delivery
- **KHÔNG tự validate voucher** - Luôn call API validate-voucher
- **KHÔNG tự tính finalAmount khi submit** - BE sẽ tính và trả về
- **Preview chỉ để UX** - Giá thực tế là giá từ BE response

---

Đọc file `FE_IMPLEMENTATION_GUIDE.md` để xem chi tiết đầy đủ.
