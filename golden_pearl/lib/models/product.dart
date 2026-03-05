class ActiveDiscount {
  final int id;
  final String type;
  final int value;
  final DateTime startsAt;
  final DateTime endsAt;

  ActiveDiscount({
    required this.id,
    required this.type,
    required this.value,
    required this.startsAt,
    required this.endsAt,
  });

  factory ActiveDiscount.fromJson(Map<String, dynamic> json) {
    return ActiveDiscount(
      id: (json['id'] as num).toInt(),
      type: json['type'] ?? 'percent',
      value: (json['value'] as num).toInt(),
      startsAt: DateTime.parse(json['startsAt']),
      endsAt: DateTime.parse(json['endsAt']),
    );
  }
}

class Product {
  final int id;
  final String nameEn;
  final String nameAr;
  final String descriptionEn;
  final String descriptionAr;
  final int price;
  final int? originalPrice;
  final String category;
  final String? subcategory;
  final List<String> images;
  final String? videoUrl;
  final List<String> sizes;
  final List<String> colors;
  final String? fabricEn;
  final String? fabricAr;
  final bool inStock;
  final bool featured;
  final String? badge;
  final double rating;
  final int reviewCount;
  final int stock;
  final ActiveDiscount? activeDiscount;
  final int? priceFinal;
  final String? discountBadgeText;

  Product({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.descriptionEn,
    required this.descriptionAr,
    required this.price,
    this.originalPrice,
    required this.category,
    this.subcategory,
    required this.images,
    this.videoUrl,
    required this.sizes,
    required this.colors,
    this.fabricEn,
    this.fabricAr,
    required this.inStock,
    required this.featured,
    this.badge,
    required this.rating,
    required this.reviewCount,
    this.stock = 100,
    this.activeDiscount,
    this.priceFinal,
    this.discountBadgeText,
  });

  int get effectivePrice => priceFinal ?? price;
  bool get hasActiveDiscount => activeDiscount != null && priceFinal != null && priceFinal! < price;

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      nameEn: json['nameEn'] ?? '',
      nameAr: json['nameAr'] ?? '',
      descriptionEn: json['descriptionEn'] ?? '',
      descriptionAr: json['descriptionAr'] ?? '',
      price: (json['price'] as num).toInt(),
      originalPrice: json['originalPrice'] != null ? (json['originalPrice'] as num).toInt() : null,
      category: json['category'] ?? '',
      subcategory: json['subcategory'],
      images: List<String>.from(json['images'] ?? []),
      videoUrl: json['videoUrl'],
      sizes: List<String>.from(json['sizes'] ?? []),
      colors: List<String>.from(json['colors'] ?? []),
      fabricEn: json['fabricEn'],
      fabricAr: json['fabricAr'],
      inStock: json['inStock'] ?? true,
      featured: json['featured'] ?? false,
      badge: json['badge'],
      rating: (json['rating'] as num?)?.toDouble() ?? 4.5,
      reviewCount: json['reviewCount'] ?? 0,
      stock: (json['stock'] as num?)?.toInt() ?? 100,
      activeDiscount: json['activeDiscount'] != null
          ? ActiveDiscount.fromJson(json['activeDiscount'])
          : null,
      priceFinal: json['priceFinal'] != null ? (json['priceFinal'] as num).toInt() : null,
      discountBadgeText: json['discountBadgeText'],
    );
  }

  String name(String locale) => locale == 'ar' ? nameAr : nameEn;
  String description(String locale) => locale == 'ar' ? descriptionAr : descriptionEn;
  String? fabric(String locale) => locale == 'ar' ? fabricAr : fabricEn;
}
