import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';

enum MapLayerType {
  googleRoadmap,
  googleSatellite,
  openStreetMap,
}

class MosqueItem {
  final String id;
  final String name;
  final double lat;
  final double lng;
  final double distanceMeters;
  final String? street;

  MosqueItem({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    required this.distanceMeters,
    this.street,
  });

  String get formattedDistance {
    if (distanceMeters < 1000) {
      return '${distanceMeters.round()} متر';
    } else {
      return '${(distanceMeters / 1000).toStringAsFixed(1)} كم';
    }
  }

  String get walkingTimeEstimate {
    final mins = (distanceMeters / 80).round();
    if (mins <= 1) return 'دقيقة واحدة مشياً';
    if (mins <= 10) return '$mins دقائق مشياً';
    return '$mins دقيقة مشياً';
  }
}

class NearestMosquesScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const NearestMosquesScreen({
    super.key,
    this.initialLat,
    this.initialLng,
  });

  @override
  State<NearestMosquesScreen> createState() => _NearestMosquesScreenState();
}

class _NearestMosquesScreenState extends State<NearestMosquesScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchCtrl = TextEditingController();

  LatLng? _userLocation;
  LatLng? _currentCenter;
  List<MosqueItem> _mosques = [];
  bool _loading = true;
  bool _isMapView = true;
  String? _errorMessage;
  int _searchRadiusKm = 5;
  MosqueItem? _selectedMosque;
  String _searchQuery = '';
  bool _isSearchingAddress = false;
  bool _isLocatingGps = false;
  MapLayerType _layerType = MapLayerType.googleRoadmap;

  List<Map<String, dynamic>> _searchResults = [];
  List<MosqueItem> _nameSearchMosques = [];
  bool _isNameSearching = false;
  bool _showNearbySheet = true;
  Timer? _searchDebounce;
  Timer? _mapDebounce;
  int _searchGen = 0;

  String get _currentTileUrl {
    switch (_layerType) {
      case MapLayerType.googleRoadmap:
        return 'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}';
      case MapLayerType.googleSatellite:
        return 'https://mt1.google.com/vt/lyrs=y&x={x}&y={y}&z={z}';
      case MapLayerType.openStreetMap:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    }
  }

  String _normalizeArabic(String s) {
    return s
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .trim();
  }

  bool _isGenericMosqueQuery(String raw) {
    final n = _normalizeArabic(raw).toLowerCase().replaceFirst('ال', '').trim();
    final stripped = n
        .replaceAll(RegExp('مسجد|جامع|مصلى|زاويه|مساجد|جوامع|mosque|masjid|jami|jamaa'), ' ')
        .trim();
    return stripped.isEmpty;
  }

  bool _nameMatches(String name, String q) {
    final n = name.toLowerCase();
    if (n.contains(q)) return true;
    final nNorm = _normalizeArabic(n);
    final qNorm = _normalizeArabic(q);
    if (nNorm.contains(qNorm)) return true;
    final qNoAl = qNorm.replaceFirst(RegExp('^ال'), '');
    if (qNoAl.isNotEmpty && nNorm.contains(qNoAl)) return true;
    return false;
  }

  List<MosqueItem> _sortedByUserDistance(List<MosqueItem> list) {
    final ref = _userLocation;
    if (ref == null) return list;
    final copy = [...list];
    copy.sort((a, b) {
      final da = _calculateDistanceMeters(ref.latitude, ref.longitude, a.lat, a.lng);
      final db = _calculateDistanceMeters(ref.latitude, ref.longitude, b.lat, b.lng);
      return da.compareTo(db);
    });
    return copy;
  }

  List<MosqueItem> get _filteredMosques {
    final raw = _searchQuery.trim();
    if (raw.isEmpty) return _sortedByUserDistance(_mosques);
    final q = raw.toLowerCase();
    final generic = _isGenericMosqueQuery(raw);

    List<MosqueItem> base;
    if (generic) {
      // "مسجد/جامع" -> show ALL mosques, nearest to user first
      base = [..._mosques];
    } else {
      base = _mosques.where((m) => _nameMatches(m.name, q)).toList();
    }

    if (_nameSearchMosques.isEmpty) return generic ? _sortedByUserDistance(base) : base;
    final seen = base.map((m) => m.id).toSet();
    final extra = _nameSearchMosques.where((m) => !seen.contains(m.id)).toList();
    if (generic) return _sortedByUserDistance([...base, ...extra]);
    return [...base, ...extra];
  }

  List<MosqueItem> get _sheetMosques => _filteredMosques;

  @override
  void initState() {
    super.initState();
    _initLocationAndFetch();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _mapDebounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _initLocationAndFetch() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    double? lat = widget.initialLat;
    double? lng = widget.initialLng;

    // 1. Try GPS location
    if (lat == null || lng == null) {
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        LocationPermission perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied) {
          perm = await Geolocator.requestPermission();
        }

        if ((perm == LocationPermission.always || perm == LocationPermission.whileInUse) && serviceEnabled) {
          try {
            final lastPos = await Geolocator.getLastKnownPosition();
            if (lastPos != null) {
              lat = lastPos.latitude;
              lng = lastPos.longitude;
            }
          } catch (_) {}

          if (lat == null) {
            final pos = await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.medium,
                timeLimit: Duration(seconds: 6),
              ),
            );
            lat = pos.latitude;
            lng = pos.longitude;
          }
        }
      } catch (e) {
        debugPrint('GPS error: $e');
      }
    }

    // 2. Fallback to saved location
    if (lat == null || lng == null) {
      if (mounted) {
        try {
          final state = Provider.of<AppState>(context, listen: false);
          final savedLoc = state.storage.getSavedLocation();
          lat = (savedLoc?['latitude'] as num?)?.toDouble() ?? (savedLoc?['lat'] as num?)?.toDouble();
          lng = (savedLoc?['longitude'] as num?)?.toDouble() ?? (savedLoc?['lng'] as num?)?.toDouble();
        } catch (_) {}
      }
    }

    // 3. Fallback to Baghdad or Mecca
    lat ??= 33.3152;
    lng ??= 44.3661;

    _userLocation = LatLng(lat, lng);
    _currentCenter = _userLocation;

    if (mounted) {
      setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          _mapController.move(_userLocation!, 14.5);
        } catch (_) {}
      });
      // Fire both fetches in parallel: quick radius + broad background,
      // so icons appear as fast as possible with maximum coverage.
      // mergeWithExisting keeps the broad result when both land at once.
      unawaited(_fetchNearbyMosques(lat, lng, _searchRadiusKm * 1000, mergeWithExisting: true));
      unawaited(_prefetchBroadMosques(lat, lng));
    }
  }

  Future<void> _fetchNearbyMosques(
    double lat, double lng, int radiusMeters,
    {bool mergeWithExisting = false}) async {
    setState(() => _loading = true);
    try {
      final overpassQuery = '''
[out:json][timeout:25];
(
  node["amenity"="place_of_worship"]["religion"="muslim"](around:$radiusMeters,$lat,$lng);
  way["amenity"="place_of_worship"]["religion"="muslim"](around:$radiusMeters,$lat,$lng);
  relation["amenity"="place_of_worship"]["religion"="muslim"](around:$radiusMeters,$lat,$lng);
  node["building"="mosque"](around:$radiusMeters,$lat,$lng);
  way["building"="mosque"](around:$radiusMeters,$lat,$lng);
  relation["building"="mosque"](around:$radiusMeters,$lat,$lng);
  node["amenity"="mosque"](around:$radiusMeters,$lat,$lng);
  way["amenity"="mosque"](around:$radiusMeters,$lat,$lng);
  node["name"~"مسجد|جامع|مصلى|زاوية|المسجد|الجامع|المصلى|Masjid|Mosque|مسجد",i](around:$radiusMeters,$lat,$lng);
  way["name"~"مسجد|جامع|مصلى|زاوية|المسجد|الجامع|المصلى|Masjid|Mosque|مسجد",i](around:$radiusMeters,$lat,$lng);
);
out center 400;
''';

      final responseData = await _postOverpass(overpassQuery, timeoutSec: 14);

      if (responseData != null) {
        // Reference point for distance calculation
        final refLat = (_userLocation != null && _calculateDistanceMeters(_userLocation!.latitude, _userLocation!.longitude, lat, lng) < (radiusMeters * 2.5))
            ? _userLocation!.latitude
            : lat;
        final refLng = (_userLocation != null && _calculateDistanceMeters(_userLocation!.latitude, _userLocation!.longitude, lat, lng) < (radiusMeters * 2.5))
            ? _userLocation!.longitude
            : lng;

        final items = _parseOverpassElements(responseData, refLat, refLng);

        // Merge with any already-loaded mosques (e.g. broad fetch landing
        // first), otherwise just use this result.
        final existingId = {for (final m in _mosques) m.id};
        final fresh = mergeWithExisting
            ? items.where((m) => !existingId.contains(m.id)).toList()
            : items;
        final base = mergeWithExisting ? [..._mosques, ...fresh] : items;
        base.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));

        // Progressive reveal: show the closest batch immediately, then fill
        // in the rest in small chunks so markers pop onto the map fast.
        const chunk = 40;
        if (mounted) {
          setState(() {
            _mosques = base.take(chunk).toList();
            _loading = false;
            _errorMessage = null;
            if (_mosques.isNotEmpty) {
              _selectedMosque = _mosques.first;
            }
          });
        }
        for (var i = chunk; i < base.length; i += chunk) {
          if (!mounted) return;
          await Future<void>.delayed(const Duration(milliseconds: 40));
          if (!mounted) return;
          setState(() => _mosques = base.take(i + chunk).toList());
        }
        if (mounted) setState(() => _mosques = base);
      } else {
        throw Exception('All Overpass mirrors failed');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage = 'تعذر جلب المساجد حالياً، يرجى التحقق من الاتصال أو تغيير نطاق البحث';
        });
      }
    }
  }

  double _calculateDistanceMeters(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742000 * asin(sqrt(a));
  }

  void _onSearchChanged(String val) {
    setState(() {
      _searchQuery = val;
      if (val.trim().isEmpty) _nameSearchMosques = [];
    });
    _searchDebounce?.cancel();
    final q = val.trim();
    if (q.length < 2) {
      _searchGen++;
      setState(() {
        _searchResults = [];
        _isSearchingAddress = false;
        _isNameSearching = false;
      });
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 280), () {
      _runRemoteSearch(q);
    });
  }

  Future<dynamic> _postOverpass(String query, {int timeoutSec = 12}) async {
    final endpoints = [
      'https://overpass-api.de/api/interpreter',
      'https://lz4.overpass-api.de/api/interpreter',
      'https://overpass.kumi.systems/api/interpreter',
    ];
    for (final endpoint in endpoints) {
      try {
        final res = await http.post(
          Uri.parse(endpoint),
          headers: {
            'User-Agent': 'DurratAlMuumin/1.0 (Android; Arabic Adhkar App)',
            'Accept': 'application/json',
          },
          body: {'data': query},
        ).timeout(Duration(seconds: timeoutSec));
        if (res.statusCode == 200) {
          return json.decode(utf8.decode(res.bodyBytes));
        }
      } catch (_) {}
    }
    return null;
  }

  String _escRegex(String q) {
    final sb = StringBuffer();
    for (final ch in q.split('')) {
      if ('\\.+*?()|[]{}^\$'.contains(ch)) {
        sb.write('\\');
      }
      sb.write(ch);
    }
    return sb.toString();
  }

  List<MosqueItem> _parseOverpassElements(dynamic responseData, double refLat, double refLng) {
    final List<MosqueItem> items = [];
    final elements = responseData['elements'] as List<dynamic>? ?? [];
    final Set<String> seenIds = {};
    for (final el in elements) {
      final id = el['id'].toString();
      if (seenIds.contains(id)) continue;
      seenIds.add(id);
      try {
        final tags = el['tags'] as Map<String, dynamic>? ?? {};
        final name = tags['name:ar'] ?? tags['name'] ?? '';
        if (name.toString().trim().isEmpty) continue;
        double mLat = 0, mLng = 0;
        if (el['type'] == 'node') {
          mLat = (el['lat'] as num).toDouble();
          mLng = (el['lon'] as num).toDouble();
        } else if (el['center'] != null) {
          mLat = (el['center']['lat'] as num).toDouble();
          mLng = (el['center']['lon'] as num).toDouble();
        } else {
          continue;
        }
        final dist = _calculateDistanceMeters(refLat, refLng, mLat, mLng);
        final isNearbyDup = items.any((existing) =>
            existing.name == name &&
            _calculateDistanceMeters(existing.lat, existing.lng, mLat, mLng) < 25);
        if (isNearbyDup) continue;
        items.add(MosqueItem(
          id: id,
          name: name.toString(),
          lat: mLat,
          lng: mLng,
          distanceMeters: dist,
          street: tags['addr:street'] as String?,
        ));
      } catch (_) {}
    }
    items.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
    return items;
  }

  /// Strong name search straight from Overpass (renamed by user request).
  /// Single query over ~100km radius: fast, comprehensive, returns real mosque
  /// markers that show up immediately on the map. Local matches are already
  /// shown instantly via _filteredMosques; this supplements beyond the radius.
  Future<void> _runRemoteSearch(String q) async {
    final gen = ++_searchGen;
    if (mounted) {
      setState(() {
        _isSearchingAddress = true;
        _isNameSearching = true;
      });
    }

    final center = _currentCenter ?? _userLocation;
    if (center == null) {
      if (mounted) {
        setState(() {
          _isNameSearching = false;
          _isSearchingAddress = false;
        });
      }
      return;
    }
    final pat = _escRegex(q.trim());
    // If the user typed a generic mosque term (مسجد/جامع...) gather ALL mosques.
    final generic = _isGenericMosqueQuery(q.trim());
    final overpassQuery = generic
        ? '''
[out:json][timeout:20];
(
  node["amenity"="place_of_worship"]["religion"="muslim"](around:100000,${center.latitude},${center.longitude});
  way["amenity"="place_of_worship"]["religion"="muslim"](around:100000,${center.latitude},${center.longitude});
  node["building"="mosque"](around:100000,${center.latitude},${center.longitude});
  way["building"="mosque"](around:100000,${center.latitude},${center.longitude});
  node["amenity"="mosque"](around:100000,${center.latitude},${center.longitude});
  way["amenity"="mosque"](around:100000,${center.latitude},${center.longitude});
  node["name"~"^مسجد|^جامع|^مصلى|^زاوية|Masjid|Mosque",i](around:100000,${center.latitude},${center.longitude});
  way["name"~"^مسجد|^جامع|^مصلى|^زاوية|Masjid|Mosque",i](around:100000,${center.latitude},${center.longitude});
);
out center 300;
'''
        : '''
[out:json][timeout:20];
(
  node["amenity"="place_of_worship"]["name"~"$pat",i](around:100000,${center.latitude},${center.longitude});
  way["amenity"="place_of_worship"]["name"~"$pat",i](around:100000,${center.latitude},${center.longitude});
  relation["amenity"="place_of_worship"]["name"~"$pat",i](around:100000,${center.latitude},${center.longitude});
  node["building"="mosque"]["name"~"$pat",i](around:100000,${center.latitude},${center.longitude});
  way["building"="mosque"]["name"~"$pat",i](around:100000,${center.latitude},${center.longitude});
  node["amenity"="mosque"]["name"~"$pat",i](around:100000,${center.latitude},${center.longitude});
  way["amenity"="mosque"]["name"~"$pat",i](around:100000,${center.latitude},${center.longitude});
  node["name"~"^مسجد|^جامع|^مصلى|^زاوية|^Masjid|^Mosque|^Jamia|^Grand",i]["name"~"$pat",i](around:100000,${center.latitude},${center.longitude});
  way["name"~"^مسجد|^جامع|^مصلى|^زاوية|^Masjid|^Mosque|^Jamia|^Grand",i]["name"~"$pat",i](around:100000,${center.latitude},${center.longitude});
);
out center 300;
''';

    final data = await _postOverpass(overpassQuery, timeoutSec: 15);
    if (!mounted || gen != _searchGen) return;

    if (data != null) {
      final refLat = center.latitude;
      final refLng = center.longitude;
      final items = _parseOverpassElements(data, refLat, refLng);
      final seen = _mosques.map((m) => m.id).toSet();
      final extra = items.where((m) => !seen.contains(m.id)).toList();
      setState(() {
        _nameSearchMosques = extra;
        _searchResults = extra
            .map((m) => {
                  'id': m.id,
                  'lat': m.lat.toString(),
                  'lon': m.lng.toString(),
                  'display_name': m.name,
                })
            .toList();
        _isNameSearching = false;
        _isSearchingAddress = false;
      });
    } else {
      if (mounted) {
        setState(() {
          _isNameSearching = false;
          _isSearchingAddress = false;
        });
      }
    }
  }

  /// Broad background fetch around the center to make local filtering instant
  /// and comprehensive without blocking the UI. Merges into _mosques.
  Future<void> _prefetchBroadMosques(double lat, double lng) async {
    final overpassQuery = '''
[out:json][timeout:25];
(
  node["amenity"="place_of_worship"]["religion"="muslim"](around:30000,$lat,$lng);
  way["amenity"="place_of_worship"]["religion"="muslim"](around:30000,$lat,$lng);
  relation["amenity"="place_of_worship"]["religion"="muslim"](around:30000,$lat,$lng);
  node["building"="mosque"](around:30000,$lat,$lng);
  way["building"="mosque"](around:30000,$lat,$lng);
  node["amenity"="mosque"](around:30000,$lat,$lng);
  node["name"~"مسجد|جامع|مصلى|زاوية|المسجد|الجامع|المصلى|Masjid|Mosque",i](around:30000,$lat,$lng);
  way["name"~"مسجد|جامع|مصلى|زاوية|المسجد|الجامع|المصلى|Masjid|Mosque",i](around:30000,$lat,$lng);
);
out center 800;
''';
    final data = await _postOverpass(overpassQuery, timeoutSec: 20);
    if (!mounted || data == null) return;
    final refLat = _userLocation?.latitude ?? lat;
    final refLng = _userLocation?.longitude ?? lng;
    final items = _parseOverpassElements(data, refLat, refLng);
    if (items.isEmpty) return;
    final existing = {for (final m in _mosques) m.id};
    final merged = [..._mosques];
    for (final m in items) {
      if (!existing.contains(m.id)) {
        existing.add(m.id);
        merged.add(m);
      }
    }
    merged.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
    if (mounted) setState(() => _mosques = merged);
  }

  void _selectSearchResult(Map<String, dynamic> item) {
    final lat = double.tryParse(item['lat']?.toString() ?? '');
    final lng = double.tryParse(item['lon']?.toString() ?? '');
    if (lat != null && lng != null) {
      final target = LatLng(lat, lng);
      _currentCenter = target;
      _mapController.move(target, 14.5);
      final id = item['id']?.toString();
      if (id != null) {
        MosqueItem? match;
        for (final m in _mosques) {
          if (m.id == id) {
            match = m;
            break;
          }
        }
        if (match == null) {
          for (final m in _nameSearchMosques) {
            if (m.id == id) {
              match = m;
              break;
            }
          }
        }
        if (match != null) _selectedMosque = match;
      }
      setState(() {
        _searchResults = [];
        _nameSearchMosques = [];
        _searchCtrl.clear();
        _searchQuery = '';
      });
      FocusScope.of(context).unfocus();
      _fetchNearbyMosques(lat, lng, _searchRadiusKm * 1000);
    }
  }

  Future<void> _locateViaGps() async {
    setState(() => _isLocatingGps = true);
    HapticFeedback.lightImpact();

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) _showNotice('يرجى تفعيل خدمة الموقع (GPS) في هاتفك');
        return;
      }

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) {
          if (mounted) _showNotice('تم رفض إذن الوصول للموقع');
          return;
        }
      }

      if (perm == LocationPermission.deniedForever) {
        if (mounted) _showNotice('إذن الموقع مرفوض نهائياً من إعدادات الجهاز');
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 6),
        ),
      );

      final target = LatLng(pos.latitude, pos.longitude);
      _userLocation = target;
      _currentCenter = target;
      _mapController.move(target, 15.0);
      if (mounted) {
        _showNotice('تم التحديد بموقعك الحالي بدقة ✓');
      }
      await _fetchNearbyMosques(pos.latitude, pos.longitude, _searchRadiusKm * 1000);
    } catch (_) {
      if (mounted) _showNotice('تعذر قراءة موقع GPS بدقة');
    } finally {
      if (mounted) setState(() => _isLocatingGps = false);
    }
  }

  void _showNotice(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: DhikrTheme.arabicFont)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showMosqueInApp(MosqueItem item) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedMosque = item;
      _isMapView = true;
    });
    _mapController.move(LatLng(item.lat, item.lng), 16.5);
  }

  void _openDirectionsInApp(MosqueItem item) {
    HapticFeedback.mediumImpact();
    setState(() {
      _selectedMosque = item;
      _isMapView = true;
    });
    if (_userLocation != null) {
      final midLat = (_userLocation!.latitude + item.lat) / 2;
      final midLng = (_userLocation!.longitude + item.lng) / 2;
      _mapController.move(LatLng(midLat, midLng), 15.0);
    } else {
      _mapController.move(LatLng(item.lat, item.lng), 16.0);
    }
  }

  Future<void> _launchExternalGoogleMaps(MosqueItem item) async {
    HapticFeedback.lightImpact();
    final uri = Uri.parse('google.navigation:q=${item.lat},${item.lng}&mode=w');
    final webUri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${item.lat},${item.lng}');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: dark ? const Color(0xFF091410) : const Color(0xFFF6F8F6),
        body: Stack(
          children: [
            // ─────────────────────────────────────────────
            // 1. Map View or List View
            // ─────────────────────────────────────────────
            Positioned.fill(
              child: _isMapView ? _buildInteractiveMap(dark) : _buildListView(dark),
            ),

            // ─────────────────────────────────────────────
            // 2. Floating Top Bar with Search & Controls
            // ─────────────────────────────────────────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHeaderRow(dark),
                      _buildRadiusChips(dark),
                      _buildCityChips(dark),
                      if (_searchResults.isNotEmpty) _buildSearchSuggestions(dark),
                    ],
                  ),
                ),
              ),
            ),

            // ─────────────────────────────────────────────
            // 3. Floating Side Controls (GPS, Zoom, Refresh)
            // ─────────────────────────────────────────────
            if (_isMapView)
              Positioned(
                left: 14,
                bottom: _selectedMosque != null
                    ? 190
                    : (_showNearbySheet && _sheetMosques.isNotEmpty
                        ? (MediaQuery.of(context).size.height * 0.38) + 20
                        : 36),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // GPS Current Location
                    _buildFloatingButton(
                      heroTag: 'mosque_gps',
                      dark: dark,
                      icon: Icons.my_location_rounded,
                      iconColor: const Color(0xFF0F766E),
                      isLoading: _isLocatingGps,
                      onTap: _isLocatingGps ? null : _locateViaGps,
                    ),
                    const SizedBox(height: 8),

                    // Toggle nearby list sheet
                    _buildFloatingButton(
                      heroTag: 'mosque_sheet',
                      dark: dark,
                      icon: _showNearbySheet ? LucideIcons.listX : LucideIcons.list,
                      iconColor: const Color(0xFFC5A059),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _showNearbySheet = !_showNearbySheet);
                      },
                    ),
                    const SizedBox(height: 8),

                    // Refresh Mosques in Area
                    _buildFloatingButton(
                      heroTag: 'mosque_refresh',
                      dark: dark,
                      icon: LucideIcons.refreshCw,
                      iconColor: const Color(0xFFC5A059),
                      isLoading: _loading,
                      onTap: _loading
                          ? null
                          : () {
                              HapticFeedback.lightImpact();
                              final center = _currentCenter ?? _userLocation;
                              if (center != null) {
                                _fetchNearbyMosques(center.latitude, center.longitude, _searchRadiusKm * 1000);
                              }
                            },
                    ),
                    const SizedBox(height: 8),

                    // Zoom In
                    _buildFloatingButton(
                      heroTag: 'mosque_zoom_in',
                      dark: dark,
                      icon: Icons.add,
                      onTap: () {
                        final z = _mapController.camera.zoom;
                        _mapController.move(_mapController.camera.center, (z + 1).clamp(3.0, 18.5));
                      },
                    ),
                    const SizedBox(height: 6),

                    // Zoom Out
                    _buildFloatingButton(
                      heroTag: 'mosque_zoom_out',
                      dark: dark,
                      icon: Icons.remove,
                      onTap: () {
                        final z = _mapController.camera.zoom;
                        _mapController.move(_mapController.camera.center, (z - 1).clamp(3.0, 18.5));
                      },
                    ),
                  ],
                ),
              ),

            // ─────────────────────────────────────────────
            // 4. Nearby mosques bottom sheet + selected card
            // ─────────────────────────────────────────────
            if (_isMapView && _selectedMosque != null)
              Positioned(
                left: 14,
                right: 14,
                bottom: 18,
                child: SafeArea(
                  top: false,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: _buildMosqueBottomCard(_selectedMosque!, dark),
                    ),
                  ),
                ),
              )
            else if (_isMapView && _showNearbySheet && _sheetMosques.isNotEmpty)
              Positioned.fill(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10, right: 10, bottom: 6),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.38,
                      child: _buildNearbyMosquesSheet(dark),
                    ),
                  ),
                ),
              ),

            // ─────────────────────────────────────────────
            // 5. Non-blocking loading pill (map stays visible)
            // ─────────────────────────────────────────────
            if (_loading && _mosques.isEmpty)
              Positioned(
                top: (MediaQuery.of(context).size.height * 0.28),
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: (dark ? const Color(0xFF16231E) : Colors.white).withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0F766E)),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'جارٍ جلب المساجد القريبة...',
                          style: TextStyle(
                            fontFamily: DhikrTheme.arabicFont,
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                            color: dark ? Colors.white : const Color(0xFF0F3B2C),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractiveMap(bool dark) {
    final center = _currentCenter ?? _userLocation ?? const LatLng(33.3152, 44.3661);

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: 14.5,
        minZoom: 3.0,
        maxZoom: 18.5,
        onPositionChanged: (camera, hasGesture) {
          if (hasGesture) {
            _currentCenter = camera.center;
            _mapDebounce?.cancel();
            _mapDebounce = Timer(const Duration(milliseconds: 600), () {
              if (mounted) _searchCurrentMapArea(silent: true);
            });
          }
        },
        onTap: (_, _) {
          // Keep current selection or close
        },
      ),
      children: [
        TileLayer(
          urlTemplate: _currentTileUrl,
          userAgentPackageName: 'com.almuumin.adhkar',
          maxZoom: 19,
        ),

        // Walking route line to selected mosque
        if (_userLocation != null && _selectedMosque != null)
          PolylineLayer(
            polylines: [
              Polyline(
                points: [
                  _userLocation!,
                  LatLng(_selectedMosque!.lat, _selectedMosque!.lng),
                ],
                strokeWidth: 4.0,
                color: const Color(0xFF0F766E),
              ),
            ],
          ),

        MarkerLayer(
          markers: [
            // User Location Marker (Google-style pulsing blue radar)
            if (_userLocation != null)
              Marker(
                point: _userLocation!,
                width: 48,
                height: 48,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.22),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Mosques Markers
            ..._filteredMosques.map((item) {
              final isSelected = _selectedMosque?.id == item.id;
              return Marker(
                point: LatLng(item.lat, item.lng),
                width: isSelected ? 120 : 42,
                height: isSelected ? 76 : 46,
                alignment: Alignment.topCenter,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedMosque = item);
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Selected badge label
                      if (isSelected)
                        Container(
                          margin: const EdgeInsets.only(bottom: 3),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F3B2C),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 1)),
                            ],
                          ),
                          child: Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              fontFamily: DhikrTheme.arabicFont,
                            ),
                          ),
                        ),

                      // Mosque Pin (crisp vector icon)
                      Container(
                        width: isSelected ? 50 : 42,
                        height: isSelected ? 50 : 42,
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFC5A059) : const Color(0xFF0F766E),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: isSelected ? 2.5 : 2.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isSelected
                                  ? const Color(0xFFC5A059).withValues(alpha: 0.5)
                                  : Colors.black.withValues(alpha: 0.3),
                              blurRadius: isSelected ? 8 : 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: CustomPaint(
                            size: Size.square(isSelected ? 34 : 26),
                            painter: _MosqueIconPainter(
                              pinColor: isSelected
                                  ? const Color(0xFFC5A059)
                                  : const Color(0xFF0F766E),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildHeaderRow(bool dark) {
    return Row(
      children: [
        // Back Button
        _buildGlassCircleButton(
          icon: Icons.arrow_back_rounded,
          dark: dark,
          onTap: () => Navigator.of(context).pop(),
        ),
        const SizedBox(width: 8),

        // Modern Search Bar
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: dark
                  ? const Color(0xFF16231E).withValues(alpha: 0.94)
                  : Colors.white.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: (dark ? DhikrColors.sage : DhikrColors.forest).withValues(alpha: 0.25),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.09),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Icon(
                  LucideIcons.search,
                  size: 18,
                  color: dark ? DhikrColors.sage : DhikrColors.forest,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: _onSearchChanged,
                    style: TextStyle(
                      fontFamily: DhikrTheme.arabicFont,
                      fontSize: 13,
                      color: dark ? Colors.white : DhikrColors.charcoal,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'ابحث: جامع مسجد / grand...',
                      hintStyle: TextStyle(
                        fontFamily: DhikrTheme.arabicFont,
                        fontSize: 12.5,
                        color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
                      ),
                    ),
                  ),
                ),
                if (_isSearchingAddress)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0F766E)),
                  )
                else if (_searchCtrl.text.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchDebounce?.cancel();
                      _searchGen++;
                      _searchCtrl.clear();
                      setState(() {
                        _searchQuery = '';
                        _searchResults = [];
                        _nameSearchMosques = [];
                        _isSearchingAddress = false;
                        _isNameSearching = false;
                      });
                    },
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Toggle Map / List
        _buildGlassCircleButton(
          icon: _isMapView ? LucideIcons.list : LucideIcons.map,
          dark: dark,
          tooltip: _isMapView ? 'عرض كقائمة' : 'عرض الخريطة',
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _isMapView = !_isMapView);
          },
        ),
        const SizedBox(width: 6),

        // Layer Switcher Menu (Google Roadmap, Google Satellite, OSM)
        PopupMenuButton<MapLayerType>(
          initialValue: _layerType,
          onSelected: (val) {
            HapticFeedback.selectionClick();
            setState(() => _layerType = val);
          },
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: dark ? const Color(0xFF1E2824) : Colors.white,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: MapLayerType.googleRoadmap,
              child: Row(
                children: [
                  Icon(Icons.map_rounded, size: 18, color: Color(0xFF0F766E)),
                  SizedBox(width: 10),
                  Text('خرائط جوجل (شوارع)', style: TextStyle(fontFamily: DhikrTheme.arabicFont, fontSize: 13)),
                ],
              ),
            ),
            const PopupMenuItem(
              value: MapLayerType.googleSatellite,
              child: Row(
                children: [
                  Icon(Icons.satellite_alt_rounded, size: 18, color: Color(0xFFD97706)),
                  SizedBox(width: 10),
                  Text('قمر صناعي جوجل', style: TextStyle(fontFamily: DhikrTheme.arabicFont, fontSize: 13)),
                ],
              ),
            ),
            const PopupMenuItem(
              value: MapLayerType.openStreetMap,
              child: Row(
                children: [
                  Icon(Icons.layers_rounded, size: 18, color: Color(0xFF4F46E5)),
                  SizedBox(width: 10),
                  Text('خريطة OpenStreetMap', style: TextStyle(fontFamily: DhikrTheme.arabicFont, fontSize: 13)),
                ],
              ),
            ),
          ],
          child: _buildGlassCircleButton(
            icon: Icons.layers_rounded,
            dark: dark,
            tooltip: 'طبقات الخريطة',
            onTap: null,
          ),
        ),
      ],
    );
  }

  Widget _buildRadiusChips(bool dark) {
    final count = _filteredMosques.length;
    final radiuses = [1, 3, 5, 10, 15];

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            // Mosque Count Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              margin: const EdgeInsets.only(left: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF0F3B2C),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1)),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🕌', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 4),
                  Text(
                    '$count مسجد',
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: DhikrTheme.arabicFont,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),

            // Quick Radius Selection
            ...radiuses.map((km) {
              final isSelected = _searchRadiusKm == km;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: ActionChip(
                  label: Text(
                    'في نطاق $km كم',
                    style: TextStyle(
                      fontFamily: DhikrTheme.arabicFont,
                      fontSize: 11.5,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : (dark ? Colors.white70 : const Color(0xFF0F3B2C)),
                    ),
                  ),
                  backgroundColor: isSelected
                      ? const Color(0xFF0F766E)
                      : (dark ? const Color(0xFF16231E).withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.94)),
                  side: BorderSide(
                    color: isSelected
                        ? const Color(0xFF0F766E)
                        : (dark ? Colors.white12 : Colors.black12),
                    width: 1,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
                  onPressed: () {
                    if (_searchRadiusKm != km) {
                      HapticFeedback.selectionClick();
                      setState(() => _searchRadiusKm = km);
                      final center = _currentCenter ?? _userLocation;
                      if (center != null) {
                        _fetchNearbyMosques(center.latitude, center.longitude, km * 1000);
                      }
                    }
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCityChips(bool dark) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            _buildCityChip('مكة المكرمة 🇸🇦', 21.4225, 39.8262, dark),
            _buildCityChip('المدينة المنورة', 24.4672, 39.6111, dark),
            _buildCityChip('بغداد 🇮🇶', 33.3152, 44.3661, dark),
            _buildCityChip('النجف الأشرف', 32.0259, 44.3463, dark),
            _buildCityChip('كربلاء المقدسة', 32.6160, 44.0249, dark),
            _buildCityChip('البصرة', 30.5081, 47.7835, dark),
            _buildCityChip('القاهرة 🇪🇬', 30.0444, 31.2357, dark),
            _buildCityChip('عمان 🇯🇴', 31.9454, 35.9284, dark),
          ],
        ),
      ),
    );
  }

  Widget _buildCityChip(String label, double lat, double lng, bool dark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: ActionChip(
        label: Text(
          label,
          style: TextStyle(
            fontFamily: DhikrTheme.arabicFont,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: dark ? Colors.white70 : const Color(0xFF0F3B2C),
          ),
        ),
        backgroundColor: dark ? const Color(0xFF16231E).withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.9),
        side: BorderSide(
          color: (dark ? DhikrColors.sage : DhikrColors.forest).withValues(alpha: 0.2),
          width: 1,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
        onPressed: () {
          HapticFeedback.selectionClick();
          final target = LatLng(lat, lng);
          _currentCenter = target;
          _mapController.move(target, 14.5);
          _fetchNearbyMosques(lat, lng, _searchRadiusKm * 1000);
        },
      ),
    );
  }

  void _searchCurrentMapArea({bool silent = false}) {
    if (!silent) HapticFeedback.selectionClick();
    final center = _currentCenter ?? _userLocation;
    if (center == null) return;
    final zoom = _mapController.camera.zoom;
    int radius;
    if (zoom >= 17) {
      radius = 800;
    } else if (zoom >= 16) {
      radius = 1500;
    } else if (zoom >= 15) {
      radius = 2500;
    } else if (zoom >= 14) {
      radius = 4000;
    } else {
      radius = _searchRadiusKm * 1000;
    }
    _fetchNearbyMosques(center.latitude, center.longitude, radius);
  }

  Widget _buildSearchSuggestions(bool dark) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF182420) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (dark ? DhikrColors.sage : DhikrColors.forest).withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      constraints: const BoxConstraints(maxHeight: 220),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 6),
        shrinkWrap: true,
        itemCount: _searchResults.length,
        separatorBuilder: (_, _) => Divider(
          height: 1,
          color: dark ? Colors.white10 : Colors.black12,
        ),
        itemBuilder: (context, idx) {
          final item = _searchResults[idx];
          final displayName = item['display_name'] ?? '';
          return Material(
            color: Colors.transparent,
            child: ListTile(
              dense: true,
              leading: const Icon(LucideIcons.mapPin, size: 16, color: Color(0xFF0F766E)),
              title: Text(
                displayName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: DhikrTheme.arabicFont,
                  fontSize: 12.5,
                  color: dark ? Colors.white : DhikrColors.charcoal,
                ),
              ),
              onTap: () => _selectSearchResult(item),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMosqueBottomCard(MosqueItem item, bool dark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark
            ? const Color(0xFF16231E).withValues(alpha: 0.96)
            : Colors.white.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF0F766E).withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F766E).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(child: Text('🕌', style: TextStyle(fontSize: 22))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: DhikrTheme.arabicFont,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: dark ? Colors.white : const Color(0xFF0F3B2C),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(LucideIcons.mapPin, size: 13, color: Color(0xFFC5A059)),
                        const SizedBox(width: 4),
                        Text(
                          item.formattedDistance,
                          style: const TextStyle(
                            fontFamily: DhikrTheme.arabicFont,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            color: Color(0xFFC5A059),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(LucideIcons.footprints, size: 13, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          item.walkingTimeEstimate,
                          style: TextStyle(
                            fontFamily: DhikrTheme.arabicFont,
                            fontSize: 11.5,
                            color: dark ? Colors.white60 : DhikrColors.charcoalSoft,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                color: dark ? Colors.white38 : Colors.black38,
                onPressed: () => setState(() => _selectedMosque = null),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Action Buttons
          Row(
            children: [
              // In-App Directions Zoom
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openDirectionsInApp(item),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F766E),
                    side: const BorderSide(color: Color(0xFF0F766E), width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: const Icon(LucideIcons.compass, size: 16),
                  label: const Text(
                    'مسار المشي',
                    style: TextStyle(fontFamily: DhikrTheme.arabicFont, fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Turn-by-Turn Navigation via Google Maps App
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _launchExternalGoogleMaps(item),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F766E),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: const Icon(LucideIcons.navigation, size: 16),
                  label: const Text(
                    'ملاحة خرائط Google',
                    style: TextStyle(fontFamily: DhikrTheme.arabicFont, fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNearbyMosquesSheet(bool dark) {
    final list = _sheetMosques;
    final count = list.length;

    return Container(
      decoration: BoxDecoration(
        color: dark
            ? const Color(0xFF16231E).withValues(alpha: 0.97)
            : Colors.white.withValues(alpha: 0.98),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        border: Border.all(
          color: const Color(0xFF0F766E).withValues(alpha: 0.3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 4),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: (dark ? Colors.white24 : Colors.black12),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'الماساجد القريبة',
                    style: TextStyle(
                      fontFamily: DhikrTheme.arabicFont,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: dark ? Colors.white : const Color(0xFF0F3B2C),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F766E).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      fontFamily: DhikrTheme.arabicFont,
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                      color: Color(0xFF0F766E),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: dark ? Colors.white38 : Colors.black38,
                  ),
                  onPressed: () => setState(() => _showNearbySheet = false),
                ),
              ],
            ),
          ),
          if (_isNameSearching || _isSearchingAddress)
            const Padding(
              padding: EdgeInsets.only(bottom: 6),
              child: LinearProgressIndicator(
                minHeight: 2,
                color: Color(0xFF0F766E),
                backgroundColor: Colors.transparent,
              ),
            ),
          Divider(height: 1, color: dark ? Colors.white10 : Colors.black12),
          Expanded(
            child: list.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        _searchQuery.trim().isEmpty
                            ? 'لم نجد مساجد في هذا النطاق'
                            : 'لا توجد مساجد مطابقة. جرّب كلمات أكثر مثل «جامع مسجد» أو «grand mosque»',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: DhikrTheme.arabicFont,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: dark ? Colors.white70 : DhikrColors.charcoalSoft,
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
                    itemCount: list.length,
                    separatorBuilder: (_, _) => Divider(
                      height: 1,
                      color: dark ? Colors.white10 : Colors.black12,
                    ),
                    itemBuilder: (ctx, i) {
                      final item = list[i];
                      final isSelected = _selectedMosque?.id == item.id;
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _selectedMosque = item;
                              _showNearbySheet = false;
                            });
                            _mapController.move(LatLng(item.lat, item.lng), 16.5);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF0F766E).withValues(alpha: 0.08)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  icon: const Icon(
                                    LucideIcons.navigation,
                                    size: 18,
                                    color: Color(0xFF0F766E),
                                  ),
                                  onPressed: () => _launchExternalGoogleMaps(item),
                                  tooltip: 'ملاحة',
                                ),
                                const SizedBox(width: 4),
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F766E).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Center(
                                    child: Text('🕌', style: TextStyle(fontSize: 18)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        item.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontFamily: DhikrTheme.arabicFont,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13.5,
                                          color: dark ? Colors.white : DhikrColors.charcoal,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        item.formattedDistance,
                                        style: const TextStyle(
                                          fontFamily: DhikrTheme.arabicFont,
                                          fontSize: 11.5,
                                          color: Color(0xFFC5A059),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_left_rounded,
                                  size: 20,
                                  color: dark ? Colors.white24 : Colors.black26,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(bool dark) {
    final list = _filteredMosques;

    return Column(
      children: [
        // Spacing for top floating bar
        const SizedBox(height: 120),

        Expanded(
          child: list.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.mapPinOff, size: 48, color: Color(0xFF0F766E)),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage ?? 'لم نجد مساجد مسجلة في هذا النطاق حالياً',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: DhikrTheme.arabicFont,
                            fontWeight: FontWeight.w700,
                            fontSize: 14.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _initLocationAndFetch,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F766E),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(LucideIcons.refreshCw, size: 16),
                          label: const Text(
                            'إعادة البحث',
                            style: TextStyle(fontFamily: DhikrTheme.arabicFont, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) {
                    final item = list[i];
                    final isSelected = _selectedMosque?.id == item.id;

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: dark ? const Color(0xFF14241D) : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFC5A059)
                              : (dark ? Colors.white.withValues(alpha: 0.07) : Colors.black.withValues(alpha: 0.05)),
                          width: isSelected ? 1.5 : 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: dark ? 0.2 : 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F766E).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: Text('🕌', style: TextStyle(fontSize: 22)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: TextStyle(
                                        fontFamily: DhikrTheme.arabicFont,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                        color: dark ? Colors.white : const Color(0xFF0F3B2C),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        const Icon(LucideIcons.mapPin, size: 13, color: Color(0xFFC5A059)),
                                        const SizedBox(width: 4),
                                        Text(
                                          item.formattedDistance,
                                          style: const TextStyle(
                                            fontFamily: DhikrTheme.arabicFont,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                            color: Color(0xFFC5A059),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(LucideIcons.footprints, size: 13, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(
                                          item.walkingTimeEstimate,
                                          style: TextStyle(
                                            fontFamily: DhikrTheme.arabicFont,
                                            fontSize: 11.5,
                                            color: dark ? Colors.white60 : DhikrColors.charcoalSoft,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _showMosqueInApp(item),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF0F766E),
                                    side: const BorderSide(color: Color(0xFF0F766E), width: 1),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                  ),
                                  icon: const Icon(LucideIcons.map, size: 14),
                                  label: const Text('على الخريطة', style: TextStyle(fontFamily: DhikrTheme.arabicFont, fontSize: 12)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _launchExternalGoogleMaps(item),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0F766E),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                  ),
                                  icon: const Icon(LucideIcons.navigation, size: 14),
                                  label: const Text('ملاحة Google', style: TextStyle(fontFamily: DhikrTheme.arabicFont, fontSize: 12, fontWeight: FontWeight.w800)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildGlassCircleButton({
    required IconData icon,
    required bool dark,
    required VoidCallback? onTap,
    String? tooltip,
  }) {
    final btn = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: dark
                ? const Color(0xFF16231E).withValues(alpha: 0.94)
                : Colors.white.withValues(alpha: 0.96),
            shape: BoxShape.circle,
            border: Border.all(
              color: (dark ? DhikrColors.sage : DhikrColors.forest).withValues(alpha: 0.25),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 20,
            color: dark ? Colors.white : DhikrColors.charcoal,
          ),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip, child: btn);
    }
    return btn;
  }

  Widget _buildFloatingButton({
    required String heroTag,
    required bool dark,
    required IconData icon,
    Color? iconColor,
    bool isLoading = false,
    required VoidCallback? onTap,
  }) {
    return FloatingActionButton.small(
      heroTag: heroTag,
      backgroundColor: dark ? const Color(0xFF1E2824) : Colors.white,
      foregroundColor: iconColor ?? (dark ? Colors.white : DhikrColors.charcoal),
      elevation: 3,
      onPressed: onTap,
      child: isLoading
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: iconColor ?? const Color(0xFF0F766E),
              ),
            )
          : Icon(icon, size: 20),
    );
  }
}

/// Vector mosque icon: dome + crescent finial + two minarets + base.
/// Painted white on the colored pin circle for a crisp, always-clear marker.
class _MosqueIconPainter extends CustomPainter {
  final Color pinColor;

  _MosqueIconPainter({required this.pinColor});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final cx = w / 2;

    // Central dome (arc shape)
    final domePath = ui.Path()
      ..moveTo(cx - w * 0.34, h * 0.62)
      ..quadraticBezierTo(cx - w * 0.38, h * 0.34, cx, h * 0.30)
      ..quadraticBezierTo(cx + w * 0.38, h * 0.34, cx + w * 0.34, h * 0.62)
      ..close();
    canvas.drawPath(domePath, paint);

    // Base bar
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - w * 0.32, h * 0.62, w * 0.64, h * 0.20),
        Radius.circular(w * 0.04),
      ),
      paint,
    );

    // Crescent finial above dome
    final crescent = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, h * 0.22), w * 0.10, crescent);
    canvas.drawCircle(
      Offset(cx + w * 0.045, h * 0.19),
      w * 0.08,
      Paint()
        ..color = pinColor
        ..style = PaintingStyle.fill,
    );

    // Two minarets
    final minaretPaint = Paint()..color = Colors.white;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - w * 0.42, h * 0.30, w * 0.07, h * 0.32),
        Radius.circular(w * 0.03),
      ),
      minaretPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx + w * 0.35, h * 0.30, w * 0.07, h * 0.32),
        Radius.circular(w * 0.03),
      ),
      minaretPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _MosqueIconPainter oldDelegate) => false;
}
