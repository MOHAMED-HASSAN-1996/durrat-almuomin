/// توحيد عناوين الموقع في كل الشاشات: «المنطقة أو الحي ثم المدينة».
/// مثال: «المعادي، القاهرة» أو «مدينة نصر، القاهرة».
/// يتم استبعاد اسم الدولة ليكون العنوان محلياً ودقيقاً للمستخدم.
String locationLabel({
  required String city,
  String province = '',
  String country = '',
}) {
  final cleanCity = city.trim();
  final cleanProvince = province.trim();

  // لو وُجد حي/منطقة/محافظة مختلفة عن المدينة، نعرضها أولاً ثم المدينة
  if (cleanProvince.isNotEmpty && cleanProvince != cleanCity) {
    if (cleanCity.isNotEmpty && cleanCity != 'موقعي الحالي' && cleanCity != 'Current Location') {
      return '$cleanProvince، $cleanCity';
    }
    return cleanProvince;
  }

  // إذا كانت المدينة متوفرة
  if (cleanCity.isNotEmpty) {
    return cleanCity;
  }

  // في حال تعذر الحصول على الحي والمدينة فقط يرجع الإقليم أو المحافظة
  if (cleanProvince.isNotEmpty) return cleanProvince;
  return country.trim();
}
