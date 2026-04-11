/// Mock data cho các mục thông tin trong Settings
/// Phù hợp với Pet Shop application

class AppInfoMockData {
  // ========== VỀ ỨNG DỤNG ==========
  static const String aboutApp = '''
# Về Ứng Dụng Pet Shop

## Giới Thiệu

Pet Shop là ứng dụng mua sắm trực tuyến chuyên về thú cưng và các sản phẩm chăm sóc thú cưng. Chúng tôi cam kết mang đến cho bạn và thú cưng của bạn những sản phẩm chất lượng cao với dịch vụ tốt nhất.

## Phiên Bản

**Version:** 1.0.0
**Build:** 2025.01.15
**Platform:** Flutter

## Tính Năng Chính

- 🛒 Mua sắm thú cưng và phụ kiện
- 📦 Đặt hàng và theo dõi đơn hàng
- 💳 Thanh toán an toàn và tiện lợi
- 📱 Quản lý thông tin thú cưng
- 🎁 Chương trình khuyến mãi hấp dẫn
- 📞 Hỗ trợ khách hàng 24/7

## Liên Hệ

**Email:** support@petshop.vn
**Hotline:** 1900 1234
**Website:** www.petshop.vn
**Địa chỉ:** 123 Đường ABC, Quận XYZ, TP.HCM

## Phát Triển Bởi

Pet Shop Development Team
© 2025 Pet Shop. All rights reserved.
''';

  // ========== QUYỀN RIÊNG TƯ ==========
  static const String privacyPolicy = '''
# Chính Sách Bảo Mật Thông Tin

## 1. Thu Thập Thông Tin

Chúng tôi thu thập các thông tin sau khi bạn sử dụng ứng dụng Pet Shop:

### Thông Tin Cá Nhân
- Họ và tên
- Email
- Số điện thoại
- Địa chỉ giao hàng
- Thông tin thanh toán (được mã hóa)

### Thông Tin Sử Dụng
- Lịch sử mua hàng
- Sở thích và hành vi mua sắm
- Thông tin thiết bị và trình duyệt

## 2. Mục Đích Sử Dụng

Chúng tôi sử dụng thông tin của bạn để:
- Xử lý đơn hàng và giao hàng
- Cải thiện trải nghiệm người dùng
- Gửi thông báo về đơn hàng và khuyến mãi
- Hỗ trợ khách hàng
- Phân tích và cải thiện dịch vụ

## 3. Bảo Mật Thông Tin

Chúng tôi cam kết:
- Mã hóa dữ liệu nhạy cảm
- Bảo vệ thông tin khỏi truy cập trái phép
- Không chia sẻ thông tin với bên thứ ba không được phép
- Tuân thủ các quy định về bảo vệ dữ liệu cá nhân

## 4. Quyền Của Người Dùng

Bạn có quyền:
- Truy cập và chỉnh sửa thông tin cá nhân
- Yêu cầu xóa tài khoản
- Từ chối nhận thông tin quảng cáo
- Khiếu nại về việc xử lý dữ liệu

## 5. Cookie và Công Nghệ Theo Dõi

Ứng dụng sử dụng cookie và công nghệ tương tự để:
- Ghi nhớ tùy chọn của bạn
- Phân tích lưu lượng truy cập
- Cải thiện hiệu suất ứng dụng

## 6. Liên Hệ

Nếu có thắc mắc về chính sách bảo mật, vui lòng liên hệ:
**Email:** privacy@petshop.vn
**Hotline:** 1900 1234

**Cập nhật lần cuối:** 15/01/2025
''';

  // ========== BẢO MẬT ==========
  static const String securityInfo = '''
# Thông Tin Bảo Mật

## Bảo Mật Tài Khoản

### Mật Khẩu Mạnh
- Sử dụng ít nhất 8 ký tự
- Kết hợp chữ hoa, chữ thường, số và ký tự đặc biệt
- Không sử dụng thông tin cá nhân dễ đoán
- Thay đổi mật khẩu định kỳ

### Xác Thực Hai Lớp (2FA)
- Bật xác thực hai lớp để tăng cường bảo mật
- Nhận mã OTP qua SMS hoặc Email
- Sử dụng ứng dụng xác thực như Google Authenticator

## Bảo Mật Thanh Toán

### Phương Thức Thanh Toán An Toàn
- ✅ Thanh toán qua ví điện tử (MoMo, ZaloPay)
- ✅ Thẻ tín dụng/ghi nợ (được mã hóa SSL)
- ✅ Thanh toán khi nhận hàng (COD)
- ✅ Chuyển khoản ngân hàng

### Bảo Vệ Thông Tin Thẻ
- Thông tin thẻ được mã hóa end-to-end
- Không lưu trữ số CVV trên hệ thống
- Tuân thủ tiêu chuẩn PCI DSS

## Bảo Mật Dữ Liệu

### Mã Hóa
- Tất cả dữ liệu nhạy cảm được mã hóa AES-256
- Kết nối HTTPS cho mọi giao dịch
- Token JWT cho phiên đăng nhập

### Sao Lưu
- Sao lưu dữ liệu hàng ngày
- Lưu trữ tại nhiều trung tâm dữ liệu
- Khôi phục dữ liệu trong 24 giờ

## Phát Hiện Hoạt Động Bất Thường

Hệ thống sẽ cảnh báo nếu phát hiện:
- Đăng nhập từ thiết bị mới
- Thay đổi thông tin tài khoản
- Giao dịch bất thường
- Nhiều lần nhập sai mật khẩu

## Báo Cáo Vấn Đề

Nếu bạn phát hiện hoạt động đáng ngờ:
- Liên hệ ngay: security@petshop.vn
- Hotline: 1900 1234 (24/7)
- Báo cáo trong ứng dụng: Cài đặt > Báo cáo vấn đề

**Cập nhật lần cuối:** 15/01/2025
''';

  // ========== ĐIỀU KHOẢN SỬ DỤNG ==========
  static const String termsOfService = '''
# Điều Khoản Sử Dụng

## 1. Chấp Nhận Điều Khoản

Bằng việc sử dụng ứng dụng Pet Shop, bạn đồng ý với các điều khoản và điều kiện sau đây. Nếu không đồng ý, vui lòng không sử dụng ứng dụng.

## 2. Đăng Ký Tài Khoản

### Yêu Cầu
- Bạn phải từ 18 tuổi trở lên
- Cung cấp thông tin chính xác và đầy đủ
- Chịu trách nhiệm về mọi hoạt động trên tài khoản
- Bảo mật thông tin đăng nhập

### Quyền Hạn
- Một người chỉ được đăng ký một tài khoản
- Không được chia sẻ tài khoản với người khác
- Chúng tôi có quyền đình chỉ tài khoản vi phạm

## 3. Mua Hàng

### Đơn Hàng
- Đơn hàng có hiệu lực sau khi thanh toán thành công
- Giá sản phẩm có thể thay đổi mà không báo trước
- Chúng tôi có quyền từ chối đơn hàng không hợp lệ

### Thanh Toán
- Thanh toán phải được hoàn tất trong 24 giờ
- Hoàn tiền theo chính sách hoàn trả
- Phí vận chuyển được tính riêng

## 4. Giao Hàng

### Thời Gian Giao Hàng
- Nội thành: 1-2 ngày làm việc
- Ngoại thành: 3-5 ngày làm việc
- Vùng sâu vùng xa: 5-7 ngày làm việc

### Trách Nhiệm
- Kiểm tra hàng hóa trước khi nhận
- Báo ngay nếu có vấn đề
- Chúng tôi không chịu trách nhiệm nếu bạn không kiểm tra

## 5. Đổi Trả và Hoàn Tiền

### Điều Kiện Đổi Trả
- Trong vòng 7 ngày kể từ ngày nhận hàng
- Sản phẩm còn nguyên vẹn, chưa sử dụng
- Có hóa đơn mua hàng

### Quy Trình
- Liên hệ hotline hoặc chat hỗ trợ
- Gửi ảnh sản phẩm và hóa đơn
- Chờ xác nhận và hướng dẫn đổi trả

## 6. Sở Hữu Trí Tuệ

- Tất cả nội dung trong ứng dụng thuộc về Pet Shop
- Không được sao chép, phân phối không được phép
- Vi phạm sẽ bị xử lý theo pháp luật

## 7. Giới Hạn Trách Nhiệm

- Chúng tôi không chịu trách nhiệm về thiệt hại gián tiếp
- Bảo hành theo chính sách của nhà sản xuất
- Thông tin sản phẩm có thể có sai sót

## 8. Thay Đổi Điều Khoản

- Chúng tôi có quyền thay đổi điều khoản bất cứ lúc nào
- Thông báo sẽ được gửi qua email hoặc trong ứng dụng
- Tiếp tục sử dụng đồng nghĩa với việc chấp nhận thay đổi

## 9. Giải Quyết Tranh Chấp

- Ưu tiên giải quyết thông qua thương lượng
- Nếu không thỏa thuận được, sẽ đưa ra Tòa án có thẩm quyền
- Áp dụng pháp luật Việt Nam

## 10. Liên Hệ

**Email:** legal@petshop.vn
**Hotline:** 1900 1234
**Địa chỉ:** 123 Đường ABC, Quận XYZ, TP.HCM

**Cập nhật lần cuối:** 15/01/2025
''';

  // ========== TRỢ GIÚP / FAQ ==========
  static const String helpContent = '''
# Trung Tâm Trợ Giúp

## Câu Hỏi Thường Gặp

### 📦 Về Đơn Hàng

**Q: Làm sao để đặt hàng?**
A: Chọn sản phẩm > Thêm vào giỏ hàng > Thanh toán > Xác nhận đơn hàng

**Q: Tôi có thể hủy đơn hàng không?**
A: Có, bạn có thể hủy đơn hàng trong vòng 2 giờ sau khi đặt. Sau đó vui lòng liên hệ hotline.

**Q: Làm sao để theo dõi đơn hàng?**
A: Vào "Đơn hàng của tôi" > Chọn đơn hàng > Xem chi tiết và trạng thái

**Q: Tôi chưa nhận được hàng, phải làm gì?**
A: Kiểm tra mã vận đơn, liên hệ hotline 1900 1234 hoặc chat hỗ trợ

### 💳 Về Thanh Toán

**Q: Có những phương thức thanh toán nào?**
A: Thẻ tín dụng/ghi nợ, Ví điện tử (MoMo, ZaloPay), COD, Chuyển khoản

**Q: Thanh toán có an toàn không?**
A: Có, chúng tôi sử dụng mã hóa SSL và tuân thủ tiêu chuẩn PCI DSS

**Q: Tôi có thể đổi phương thức thanh toán không?**
A: Có thể, liên hệ hotline trong vòng 2 giờ sau khi đặt hàng

### 🔄 Về Đổi Trả

**Q: Tôi có thể đổi trả sản phẩm không?**
A: Có, trong vòng 7 ngày kể từ ngày nhận hàng, sản phẩm còn nguyên vẹn

**Q: Quy trình đổi trả như thế nào?**
A: Liên hệ hotline > Gửi ảnh sản phẩm và hóa đơn > Chờ xác nhận > Gửi hàng về

**Q: Tôi sẽ được hoàn tiền trong bao lâu?**
A: 3-5 ngày làm việc sau khi chúng tôi nhận được hàng đổi trả

### 🐾 Về Sản Phẩm

**Q: Sản phẩm có đảm bảo chất lượng không?**
A: Có, tất cả sản phẩm đều được kiểm tra kỹ trước khi giao hàng

**Q: Tôi có thể xem sản phẩm trước khi mua không?**
A: Có thể đến cửa hàng của chúng tôi tại 123 Đường ABC, Quận XYZ, TP.HCM

**Q: Sản phẩm có bảo hành không?**
A: Tùy theo sản phẩm, thông tin bảo hành được ghi rõ trên trang sản phẩm

### 📱 Về Ứng Dụng

**Q: Làm sao để cập nhật ứng dụng?**
A: Vào App Store (iOS) hoặc Google Play (Android) > Tìm "Pet Shop" > Cập nhật

**Q: Tôi quên mật khẩu, phải làm gì?**
A: Vào trang đăng nhập > Chọn "Quên mật khẩu" > Nhập email > Làm theo hướng dẫn

**Q: Làm sao để thay đổi thông tin tài khoản?**
A: Vào "Tài khoản" > "Chỉnh sửa thông tin" > Cập nhật > Lưu

## Liên Hệ Hỗ Trợ

### 📞 Hotline
**1900 1234** (24/7)

### 💬 Chat Trực Tuyến
Trong ứng dụng: Menu > Hỗ trợ > Chat với chúng tôi

### 📧 Email
**support@petshop.vn**

### 🏢 Địa Chỉ
123 Đường ABC, Quận XYZ, TP.HCM
Giờ làm việc: 8:00 - 22:00 hàng ngày

### ⏰ Thời Gian Phản Hồi
- Chat: Trong vòng 5 phút
- Email: Trong vòng 24 giờ
- Hotline: Ngay lập tức

## Hướng Dẫn Sử Dụng

### Đăng Ký Tài Khoản
1. Mở ứng dụng
2. Chọn "Đăng ký"
3. Điền thông tin
4. Xác nhận email
5. Hoàn tất

### Đặt Hàng
1. Duyệt sản phẩm
2. Thêm vào giỏ hàng
3. Kiểm tra giỏ hàng
4. Chọn địa chỉ giao hàng
5. Chọn phương thức thanh toán
6. Xác nhận đơn hàng

### Theo Dõi Đơn Hàng
1. Vào "Đơn hàng của tôi"
2. Chọn đơn hàng cần xem
3. Xem chi tiết và trạng thái
4. Liên hệ nếu có vấn đề

**Cập nhật lần cuối:** 15/01/2025
''';

  // ========== Helper Methods ==========
  
  /// Lấy nội dung về ứng dụng
  static String getAboutApp() => aboutApp;
  
  /// Lấy chính sách quyền riêng tư
  static String getPrivacyPolicy() => privacyPolicy;
  
  /// Lấy thông tin bảo mật
  static String getSecurityInfo() => securityInfo;
  
  /// Lấy điều khoản sử dụng
  static String getTermsOfService() => termsOfService;
  
  /// Lấy nội dung trợ giúp
  static String getHelpContent() => helpContent;
}
