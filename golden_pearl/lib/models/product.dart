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
  final List<String> sizes;
  final List<String> colors;
  final String? fabricEn;
  final String? fabricAr;
  final bool inStock;
  final bool featured;
  final String? badge;
  final double rating;
  final int reviewCount;
  final bool arEnabled;
  final String? arAssetType;
  final String? arAssetUrl;
  final double? arScaleHint;
  final String? arPlacementHint;
  final String? videoUrl;

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
    required this.sizes,
    required this.colors,
    this.fabricEn,
    this.fabricAr,
    required this.inStock,
    required this.featured,
    this.badge,
    required this.rating,
    required this.reviewCount,
    this.arEnabled = false,
    this.arAssetType,
    this.arAssetUrl,
    this.arScaleHint,
    this.arPlacementHint,
    this.videoUrl,
  });

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
      sizes: List<String>.from(json['sizes'] ?? []),
      colors: List<String>.from(json['colors'] ?? []),
      fabricEn: json['fabricEn'],
      fabricAr: json['fabricAr'],
      inStock: json['inStock'] ?? true,
      featured: json['featured'] ?? false,
      badge: json['badge'],
      rating: (json['rating'] as num?)?.toDouble() ?? 4.5,
      reviewCount: json['reviewCount'] ?? 0,
      arEnabled: json['arEnabled'] ?? false,
      arAssetType: json['arAssetType'],
      arAssetUrl: json['arAssetUrl'],
      arScaleHint: json['arScaleHint'] != null ? (json['arScaleHint'] as num).toDouble() : null,
      arPlacementHint: json['arPlacementHint'],
      videoUrl: json['videoUrl'],
    );
  }

  String name(String locale) => locale == 'ar' ? nameAr : nameEn;
  String description(String locale) => locale == 'ar' ? descriptionAr : descriptionEn;
  String? fabric(String locale) => locale == 'ar' ? fabricAr : fabricEn;
}
