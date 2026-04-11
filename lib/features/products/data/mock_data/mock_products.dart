import '../../domain/entities/category.dart';
import '../../domain/entities/brand.dart';
import '../../domain/entities/special_offer.dart';

class MockProducts {
  static final List<Category> categories = [
    Category(
      categoryId: 1,
      name: 'Thức Ăn Khô',
      description: 'Thức ăn khô cho chó mèo',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    Category(
      categoryId: 2,
      name: 'Thức Ăn Ướt',
      description: 'Pate, thức ăn ướt',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    Category(
      categoryId: 3,
      name: 'Đồ Chơi',
      description: 'Đồ chơi cho thú cưng',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    Category(
      categoryId: 4,
      name: 'Phụ Kiện',
      description: 'Vòng cổ, dây dắt, bát ăn',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    Category(
      categoryId: 5,
      name: 'Sữa & Bổ Sung',
      description: 'Sữa, vitamin, thực phẩm bổ sung',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
  ];

  static final List<Brand> brands = [
    Brand(
      brandId: 1,
      name: 'Royal Canin',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    Brand(
      brandId: 2,
      name: 'Pedigree',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    Brand(
      brandId: 3,
      name: 'Whiskas',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    Brand(
      brandId: 4,
      name: 'SmartHeart',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    Brand(
      brandId: 5,
      name: 'CatEye',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
  ];

  // Products removed - using API calls instead

  static final List<SpecialOffer> specialOffers = [
    SpecialOffer(
      offerId: 1,
      title: 'Today Cat Food Best Offer',
      discountPercent: 30,
      timeRange: 'Today 12:00 AM - 12:00 PM',
      productName: 'Whiskas Pate Cá Ngừ Cho Mèo',
      imageUrl:
          'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=400',
    ),
    SpecialOffer(
      offerId: 2,
      title: 'Dog Food Special Deal',
      discountPercent: 25,
      timeRange: 'Today 2:00 PM - 6:00 PM',
      productName: 'Royal Canin Adult Cho Chó Trưởng Thành',
      imageUrl:
          'https://images.unsplash.com/photo-1589924691995-400dc9ecc119?w=400',
    ),
    SpecialOffer(
      offerId: 3,
      title: 'Pet Toys Flash Sale',
      discountPercent: 40,
      timeRange: 'Today 8:00 PM - 11:00 PM',
      productName: 'Bóng Tennis Cho Chó',
      imageUrl:
          'https://images.unsplash.com/photo-1601758228041-f3b2795255f1?w=400',
    ),
  ];
}
