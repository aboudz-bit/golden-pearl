class Store {
  final int id;
  final String nameEn;
  final String nameAr;
  final String addressEn;
  final String addressAr;
  final String city;
  final String phone;
  final String hoursEn;
  final String hoursAr;
  final String? mapUrl;
  final bool isActive;

  Store({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.addressEn,
    required this.addressAr,
    required this.city,
    required this.phone,
    required this.hoursEn,
    required this.hoursAr,
    this.mapUrl,
    this.isActive = true,
  });

  String name(String locale) => locale == 'ar' ? nameAr : nameEn;
  String address(String locale) => locale == 'ar' ? addressAr : addressEn;
  String hours(String locale) => locale == 'ar' ? hoursAr : hoursEn;

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      id: json['id'],
      nameEn: json['nameEn'] ?? '',
      nameAr: json['nameAr'] ?? '',
      addressEn: json['addressEn'] ?? '',
      addressAr: json['addressAr'] ?? '',
      city: json['city'] ?? '',
      phone: json['phone'] ?? '',
      hoursEn: json['hoursEn'] ?? '',
      hoursAr: json['hoursAr'] ?? '',
      mapUrl: json['mapUrl'],
      isActive: json['isActive'] ?? true,
    );
  }
}
