/// أدوات معالجة النصوص العربية — إزالة التشكيل وعلامات الضبط بدقة
class ArabicTextUtils {
  ArabicTextUtils._();

  /// تعبير نمطي يحذف جميع حركات التشكيل والتنوين والشدة وعلامات الضبط القرآني
  static final RegExp _tashkeelRegex = RegExp(
    r'[\u0617-\u061A\u064B-\u065F\u0670\u06D6-\u06ED]',
    unicode: true,
  );

  /// إزالة التشكيل من النص العربي وإرجاع النص نظيفاً ومريحاً للقراءة
  static String stripTashkeel(String text) {
    if (text.isEmpty) return text;
    return text.replaceAll(_tashkeelRegex, '');
  }
}
