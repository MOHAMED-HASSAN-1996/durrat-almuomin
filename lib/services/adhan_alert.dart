/// The prayer information carried by an Android full-screen notification.
class AdhanAlert {
  const AdhanAlert({required this.prayerNameAr, required this.prayerNameEn});

  static const _prefix = 'adhan:';

  final String prayerNameAr;
  final String prayerNameEn;

  String get payload =>
      '$_prefix${Uri.encodeComponent(prayerNameAr)}|${Uri.encodeComponent(prayerNameEn)}';

  static AdhanAlert? fromPayload(String? payload) {
    if (payload == null || !payload.startsWith(_prefix)) return null;
    final parts = payload.substring(_prefix.length).split('|');
    if (parts.length != 2 || parts.any((part) => part.isEmpty)) return null;
    return AdhanAlert(
      prayerNameAr: Uri.decodeComponent(parts[0]),
      prayerNameEn: Uri.decodeComponent(parts[1]),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AdhanAlert &&
      other.prayerNameAr == prayerNameAr &&
      other.prayerNameEn == prayerNameEn;

  @override
  int get hashCode => Object.hash(prayerNameAr, prayerNameEn);
}
