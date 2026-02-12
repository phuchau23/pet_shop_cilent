import '../../domain/entities/product.dart';
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

  static final List<Product> products = [
    Product(
      productId: 1,
      name: 'Royal Canin Adult Cho Chó Trưởng Thành',
      description:
          'Thức ăn khô cao cấp cho chó trưởng thành, giàu protein và vitamin, giúp chó khỏe mạnh và năng động.',
      price: 450000,
      salePrice: 380000,
      stockQuantity: 50,
      category: categories[0],
      brand: brands[0],
      status: true,
      viewCount: 1250,
      soldCount: 320,
      petType: 'Chó',
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
      updatedAt: DateTime.now().subtract(const Duration(days: 5)),
      images: [
        'https://images.unsplash.com/photo-1589924691995-400dc9ecc119?w=400',
        'https://images.unsplash.com/photo-1601758228041-f3b2795255f1?w=400',
      ],
    ),
    Product(
      productId: 2,
      name: 'Pedigree Dentastix Cho Chó',
      description:
          'Bánh thưởng giúp làm sạch răng, ngăn ngừa cao răng, hơi thở thơm mát.',
      price: 120000,
      stockQuantity: 100,
      category: categories[0],
      brand: brands[1],
      status: true,
      viewCount: 890,
      soldCount: 245,
      petType: 'Chó',
      createdAt: DateTime.now().subtract(const Duration(days: 45)),
      updatedAt: DateTime.now().subtract(const Duration(days: 3)),
      images: [
        'https://images.unsplash.com/photo-1601758228041-f3b2795255f1?w=400',
      ],
    ),
    Product(
      productId: 3,
      name: 'Whiskas Pate Cá Ngừ Cho Mèo',
      description:
          'Pate mềm thơm ngon, giàu dinh dưỡng, phù hợp cho mèo mọi lứa tuổi.',
      price: 25000,
      salePrice: 20000,
      stockQuantity: 200,
      category: categories[1],
      brand: brands[2],
      status: true,
      viewCount: 2100,
      soldCount: 580,
      petType: 'Mèo',
      createdAt: DateTime.now().subtract(const Duration(days: 50)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      images: [
        'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=400',
        'https://images.unsplash.com/photo-1574158622682-e40e69881006?w=400',
      ],
    ),
    Product(
      productId: 4,
      name: 'SmartHeart Premium Cho Chó Con',
      description:
          'Thức ăn khô cho chó con, hỗ trợ phát triển xương và trí não.',
      price: 320000,
      stockQuantity: 75,
      category: categories[0],
      brand: brands[3],
      status: true,
      viewCount: 650,
      soldCount: 120,
      petType: 'Chó',
      createdAt: DateTime.now().subtract(const Duration(days: 40)),
      updatedAt: DateTime.now().subtract(const Duration(days: 7)),
      images: [
        'https://images.unsplash.com/photo-1589924691995-400dc9ecc119?w=400',
      ],
    ),
    Product(
      productId: 5,
      name: 'Bóng Tennis Cho Chó',
      description:
          'Bóng tennis cao cấp, bền, an toàn, kích thích vận động cho chó.',
      price: 45000,
      salePrice: 35000,
      stockQuantity: 150,
      category: categories[2],
      brand: brands[4],
      status: true,
      viewCount: 420,
      soldCount: 95,
      petType: 'Chó',
      createdAt: DateTime.now().subtract(const Duration(days: 35)),
      updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      images: [
        'https://images.unsplash.com/photo-1601758228041-f3b2795255f1?w=400',
      ],
    ),
    Product(
      productId: 6,
      name: 'Vòng Cổ Da Cao Cấp',
      description:
          'Vòng cổ da thật, điều chỉnh được, phù hợp mọi kích cỡ chó mèo.',
      price: 180000,
      stockQuantity: 60,
      category: categories[3],
      brand: brands[4],
      status: true,
      viewCount: 380,
      soldCount: 75,
      petType: 'Chó, Mèo',
      createdAt: DateTime.now().subtract(const Duration(days: 25)),
      updatedAt: DateTime.now().subtract(const Duration(days: 4)),
      images: [
        'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=400',
      ],
    ),
    Product(
      productId: 7,
      name: 'Sữa Bột Cho Mèo Con',
      description:
          'Sữa bột dinh dưỡng cho mèo con, dễ tiêu hóa, giàu protein.',
      price: 280000,
      stockQuantity: 40,
      category: categories[4],
      brand: brands[2],
      status: true,
      viewCount: 520,
      soldCount: 110,
      petType: 'Mèo',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now().subtract(const Duration(days: 6)),
      images: [
        'https://images.unsplash.com/photo-1574158622682-e40e69881006?w=400',
      ],
    ),
    Product(
      productId: 8,
      name: 'Bát Ăn Inox 2 Ngăn',
      description:
          'Bát ăn inox không gỉ, 2 ngăn tiện lợi, dễ vệ sinh, chống trượt.',
      price: 95000,
      salePrice: 75000,
      stockQuantity: 120,
      category: categories[3],
      brand: brands[4],
      status: true,
      viewCount: 680,
      soldCount: 145,
      petType: 'Chó, Mèo',
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      images: [
        'https://images.unsplash.com/photo-1601758228041-f3b2795255f1?w=400',
      ],
    ),
  ];

  static final List<SpecialOffer> specialOffers = [
    SpecialOffer(
      offerId: 1,
      title: 'Today Cat Food Best Offer',
      discountPercent: 30,
      timeRange: 'Today 12:00 AM - 12:00 PM',
      productName: 'Whiskas Pate Cá Ngừ Cho Mèo',
      imageUrl: 'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=400',
    ),
    SpecialOffer(
      offerId: 2,
      title: 'Dog Food Special Deal',
      discountPercent: 25,
      timeRange: 'Today 2:00 PM - 6:00 PM',
      productName: 'Royal Canin Adult Cho Chó Trưởng Thành',
      imageUrl: 'https://images.unsplash.com/photo-1589924691995-400dc9ecc119?w=400',
    ),
    SpecialOffer(
      offerId: 3,
      title: 'Pet Toys Flash Sale',
      discountPercent: 40,
      timeRange: 'Today 8:00 PM - 11:00 PM',
      productName: 'Bóng Tennis Cho Chó',
      imageUrl: 'https://images.unsplash.com/photo-1601758228041-f3b2795255f1?w=400',
    ),
  ];
}
