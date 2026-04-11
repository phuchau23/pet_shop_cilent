// /// Mock voucher / promo codes for the "Khám phá ngay" flow (replace with API later).
// class PromoCodeItem {
//   const PromoCodeItem({
//     required this.code,
//     required this.title,
//     required this.description,
//     required this.discountPercent,
//     required this.validUntil,
//     this.minOrderLabel,
//     this.featured = false,
//   });

//   final String code;
//   final String title;
//   final String description;
//   final int discountPercent;
//   final DateTime validUntil;
//   final String? minOrderLabel;
//   final bool featured;
// }

// class PromoCodesMockData {
//   PromoCodesMockData._();

//   static List<PromoCodeItem> get items => const [
//         PromoCodeItem(
//           code: 'PETLOVE25',
//           title: 'Tuần lễ thú cưng',
//           description: 'Áp dụng thức ăn, đồ chơi và phụ kiện cho chó mèo.',
//           discountPercent: 25,
//           validUntil: _d(2025, 12, 31),
//           minOrderLabel: 'Đơn từ 399.000đ',
//           featured: true,
//         ),
//         PromoCodeItem(
//           code: 'NEWBIE15',
//           title: 'Chào thành viên mới',
//           description: 'Dành cho đơn hàng đầu tiên trên Pet Shop.',
//           discountPercent: 15,
//           validUntil: _d(2025, 6, 30),
//           minOrderLabel: 'Tối đa 100.000đ',
//         ),
//         PromoCodeItem(
//           code: 'FREESHIP',
//           title: 'Miễn phí giao hàng',
//           description: 'Không giảm giá sản phẩm — freeship toàn quốc.',
//           discountPercent: 0,
//           validUntil: _d(2025, 4, 15),
//           minOrderLabel: 'Đơn từ 250.000đ',
//         ),
//         PromoCodeItem(
//           code: 'CATDAY20',
//           title: 'Ngày hội mèo cưng',
//           description: 'Cát vệ sinh, pate và snack chỉ trong tuần này.',
//           discountPercent: 20,
//           validUntil: _d(2025, 5, 10),
//           minOrderLabel: 'Đơn từ 199.000đ',
//         ),
//         PromoCodeItem(
//           code: 'BULK10',
//           title: 'Mua số lượng lớn',
//           description: 'Giảm thêm khi mua từ 3 sản phẩm cùng loại.',
//           discountPercent: 10,
//           validUntil: _d(2025, 8, 1),
//           minOrderLabel: 'Không giới hạn đơn',
//         ),
//       ];

//   static DateTime _d(int y, int m, int d) => DateTime(y, m, d);
// }
