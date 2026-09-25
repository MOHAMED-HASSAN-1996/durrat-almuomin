/// توحيد عناوين الموقع في كل الشاشات: «المنطقة ثم المدينة».
///
/// المنطقة = المحافظة/الولاية إن وُجدت وكانت مختلفة عن المدينة،
/// وإلا الدولة. لو المدينة فارغة تُرجع المنطقة فقط، والعكس صحيح.
String locationLabel({
  required String city,
  String province = '',
  String country = '',
}) {
  final String region = province.isNotEmpty && province != city
      ? province
      : (country.isNotEmpty && country != city ? country : '');
  if (region.isEmpty) return city;
  if (city.isEmpty) return region;
  return '$region، $city';
}
