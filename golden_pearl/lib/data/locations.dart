class Country {
  final String code;
  final String nameEn;
  final String nameAr;
  final List<City> cities;

  const Country({
    required this.code,
    required this.nameEn,
    required this.nameAr,
    required this.cities,
  });

  String name(String lang) => lang == 'ar' ? nameAr : nameEn;
}

class City {
  final String nameEn;
  final String nameAr;

  const City({required this.nameEn, required this.nameAr});

  String name(String lang) => lang == 'ar' ? nameAr : nameEn;
}

const List<Country> kCountries = [
  Country(code: 'SA', nameEn: 'Saudi Arabia', nameAr: 'المملكة العربية السعودية', cities: [
    City(nameEn: 'Riyadh', nameAr: 'الرياض'),
    City(nameEn: 'Jeddah', nameAr: 'جدة'),
    City(nameEn: 'Makkah', nameAr: 'مكة المكرمة'),
    City(nameEn: 'Madinah', nameAr: 'المدينة المنورة'),
    City(nameEn: 'Dammam', nameAr: 'الدمام'),
    City(nameEn: 'Khobar', nameAr: 'الخبر'),
    City(nameEn: 'Dhahran', nameAr: 'الظهران'),
    City(nameEn: 'Tabuk', nameAr: 'تبوك'),
    City(nameEn: 'Abha', nameAr: 'أبها'),
    City(nameEn: 'Khamis Mushait', nameAr: 'خميس مشيط'),
    City(nameEn: 'Taif', nameAr: 'الطائف'),
    City(nameEn: 'Buraydah', nameAr: 'بريدة'),
    City(nameEn: 'Hail', nameAr: 'حائل'),
    City(nameEn: 'Najran', nameAr: 'نجران'),
    City(nameEn: 'Jizan', nameAr: 'جازان'),
    City(nameEn: 'Yanbu', nameAr: 'ينبع'),
    City(nameEn: 'Al Ahsa', nameAr: 'الأحساء'),
    City(nameEn: 'Jubail', nameAr: 'الجبيل'),
    City(nameEn: 'Al Qatif', nameAr: 'القطيف'),
    City(nameEn: 'Arar', nameAr: 'عرعر'),
    City(nameEn: 'Sakaka', nameAr: 'سكاكا'),
    City(nameEn: 'Al Baha', nameAr: 'الباحة'),
  ]),
  Country(code: 'AE', nameEn: 'United Arab Emirates', nameAr: 'الإمارات العربية المتحدة', cities: [
    City(nameEn: 'Dubai', nameAr: 'دبي'),
    City(nameEn: 'Abu Dhabi', nameAr: 'أبو ظبي'),
    City(nameEn: 'Sharjah', nameAr: 'الشارقة'),
    City(nameEn: 'Ajman', nameAr: 'عجمان'),
    City(nameEn: 'Ras Al Khaimah', nameAr: 'رأس الخيمة'),
    City(nameEn: 'Fujairah', nameAr: 'الفجيرة'),
    City(nameEn: 'Umm Al Quwain', nameAr: 'أم القيوين'),
    City(nameEn: 'Al Ain', nameAr: 'العين'),
  ]),
  Country(code: 'KW', nameEn: 'Kuwait', nameAr: 'الكويت', cities: [
    City(nameEn: 'Kuwait City', nameAr: 'مدينة الكويت'),
    City(nameEn: 'Hawalli', nameAr: 'حولي'),
    City(nameEn: 'Salmiya', nameAr: 'السالمية'),
    City(nameEn: 'Farwaniya', nameAr: 'الفروانية'),
    City(nameEn: 'Jahra', nameAr: 'الجهراء'),
    City(nameEn: 'Ahmadi', nameAr: 'الأحمدي'),
    City(nameEn: 'Mangaf', nameAr: 'المنقف'),
  ]),
  Country(code: 'BH', nameEn: 'Bahrain', nameAr: 'البحرين', cities: [
    City(nameEn: 'Manama', nameAr: 'المنامة'),
    City(nameEn: 'Muharraq', nameAr: 'المحرق'),
    City(nameEn: 'Riffa', nameAr: 'الرفاع'),
    City(nameEn: 'Hamad Town', nameAr: 'مدينة حمد'),
    City(nameEn: 'Isa Town', nameAr: 'مدينة عيسى'),
  ]),
  Country(code: 'QA', nameEn: 'Qatar', nameAr: 'قطر', cities: [
    City(nameEn: 'Doha', nameAr: 'الدوحة'),
    City(nameEn: 'Al Wakrah', nameAr: 'الوكرة'),
    City(nameEn: 'Al Khor', nameAr: 'الخور'),
    City(nameEn: 'Al Rayyan', nameAr: 'الريان'),
    City(nameEn: 'Lusail', nameAr: 'لوسيل'),
    City(nameEn: 'Umm Salal', nameAr: 'أم صلال'),
  ]),
  Country(code: 'OM', nameEn: 'Oman', nameAr: 'عُمان', cities: [
    City(nameEn: 'Muscat', nameAr: 'مسقط'),
    City(nameEn: 'Salalah', nameAr: 'صلالة'),
    City(nameEn: 'Sohar', nameAr: 'صحار'),
    City(nameEn: 'Nizwa', nameAr: 'نزوى'),
    City(nameEn: 'Sur', nameAr: 'صور'),
    City(nameEn: 'Ibri', nameAr: 'عبري'),
  ]),
];
