import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../types/adhkar.dart';
import '../widgets/app_toast.dart';

enum MapLayerType {
  googleRoadmap,
  googleSatellite,
  openStreetMap,
}

/// A full-featured, interactive Google Map location picker for Durrat Al-Mu'min.
/// Allows the user to pan, zoom, search, tap anywhere on the map, or use GPS
/// to manually pinpoint their exact location for accurate prayer times.
class LocationMapPickerScreen extends StatefulWidget {
  const LocationMapPickerScreen({
    super.key,
    this.initialLat,
    this.initialLng,
    this.initialCityAr,
    this.initialCountryAr,
  });

  final double? initialLat;
  final double? initialLng;
  final String? initialCityAr;
  final String? initialCountryAr;

  @override
  State<LocationMapPickerScreen> createState() => _LocationMapPickerScreenState();
}

class _LocationMapPickerScreenState extends State<LocationMapPickerScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchCtrl = TextEditingController();

  late LatLng _currentCenter;
  MapLayerType _layerType = MapLayerType.googleRoadmap;

  bool _isGeocoding = false;
  bool _isLocatingGps = false;
  bool _isSearching = false;

  String _detectedCityAr = '';
  String _detectedCityEn = '';
  String _detectedCountryAr = '';
  String _detectedCountryEn = '';
  String _detectedCountryCode = '';

  List<Map<String, dynamic>> _searchResults = [];
  Timer? _debounceTimer;

  // Layer tile URL templates
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

  @override
  void initState() {
    super.initState();
    // Default to Baghdad, Iraq if no coordinates are provided
    final defaultLat = widget.initialLat ?? 33.3152;
    final defaultLng = widget.initialLng ?? 44.3661;
    _currentCenter = LatLng(defaultLat, defaultLng);

    _detectedCityAr = widget.initialCityAr ?? 'بغداد';
    _detectedCityEn = 'Baghdad';
    _detectedCountryAr = widget.initialCountryAr ?? 'العراق';
    _detectedCountryEn = 'Iraq';

    // Reverse geocode initial position
    _reverseGeocodeDebounced(_currentCenter);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onCameraMoved(LatLng newCenter) {
    setState(() {
      _currentCenter = newCenter;
    });
    _reverseGeocodeDebounced(newCenter);
  }

  void _reverseGeocodeDebounced(LatLng target) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 600), () {
      _performReverseGeocode(target.latitude, target.longitude);
    });
  }

  Future<void> _performReverseGeocode(double lat, double lng) async {
    if (!mounted) return;
    setState(() => _isGeocoding = true);

    try {
      // 1. Photon by Komoot (rapid open-source reverse geocoding)
      final url = Uri.parse('https://photon.komoot.io/reverse?lat=$lat&lon=$lng');
      final res = await http.get(url, headers: {
        'Accept': 'application/json',
        'User-Agent': 'durrat-almuumin/1.0',
      }).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final features = data['features'] as List?;
        if (features != null && features.isNotEmpty) {
          final props = features[0]['properties'] as Map<String, dynamic>?;
          if (props != null) {
            final city = props['city'] ??
                props['town'] ??
                props['district'] ??
                props['county'] ??
                props['name'] ??
                '';
            final country = props['country'] ?? '';

            if (city.toString().isNotEmpty) {
              if (mounted) {
                setState(() {
                  _detectedCityAr = _cleanCityName(city.toString());
                  _detectedCityEn = city.toString();
                  _detectedCountryAr = _cleanCountryName(country.toString());
                  _detectedCountryEn = country.toString();
                  _detectedCountryCode =
                      ((props['countrycode'] as String?) ?? '').toString().trim().toUpperCase();
                  _isGeocoding = false;
                });
              }
              return;
            }
          }
        }
      }
    } catch (_) {}

    // 2. OpenStreetMap Nominatim with explicit Arabic headers
    try {
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&accept-language=ar,en');
      final res = await http.get(url, headers: {
        'Accept': 'application/json',
        'User-Agent': 'durrat-almuumin/1.0',
      }).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final addr = data['address'] as Map<String, dynamic>?;
        if (addr != null) {
          final city = addr['city'] ??
              addr['town'] ??
              addr['suburb'] ??
              addr['district'] ??
              addr['county'] ??
              addr['state'] ??
              '';
          final country = addr['country'] ?? '';

          if (mounted) {
            setState(() {
              _detectedCityAr = _cleanCityName(city.toString());
              _detectedCityEn = city.toString();
              _detectedCountryAr = _cleanCountryName(country.toString());
              _detectedCountryEn = country.toString();
              _detectedCountryCode =
                  ((addr['country_code'] as String?) ?? '').toString().trim().toUpperCase();
              _isGeocoding = false;
            });
          }
          return;
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _isGeocoding = false;
      });
    }
  }

  String _cleanCityName(String raw) {
    return raw
        .replaceAll('City', '')
        .replaceAll('Governorate', '')
        .replaceAll('District', '')
        .replaceAll('محافظة', '')
        .replaceAll('مدينة', '')
        .trim();
  }

  String _cleanCountryName(String raw) {
    if (raw.toLowerCase().contains('egypt') || raw.contains('مصر')) return 'مصر';
    if (raw.toLowerCase().contains('iraq') || raw.contains('عراق')) return 'العراق';
    if (raw.toLowerCase().contains('saudi') || raw.contains('سعود')) return 'السعودية';
    if (raw.toLowerCase().contains('jordan') || raw.contains('أردن')) return 'الأردن';
    if (raw.toLowerCase().contains('syria') || raw.contains('سوريا')) return 'سوريا';
    if (raw.toLowerCase().contains('uae') || raw.contains('إمارات')) return 'الإمارات';
    return raw.trim();
  }

  Future<void> _searchPlaces(String query) async {
    final q = query.trim();
    if (q.length < 2) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isSearching = true);
    try {
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(q)}&accept-language=ar,en&limit=6');
      final res = await http.get(url, headers: {
        'Accept': 'application/json',
        'User-Agent': 'durrat-almuumin/1.0',
      }).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final List list = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _searchResults = list.map((e) => e as Map<String, dynamic>).toList();
            _isSearching = false;
          });
        }
        return;
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _isSearching = false);
    }
  }

  void _selectSearchResult(Map<String, dynamic> item) {
    final lat = double.tryParse(item['lat']?.toString() ?? '');
    final lng = double.tryParse(item['lon']?.toString() ?? '');
    if (lat != null && lng != null) {
      final target = LatLng(lat, lng);
      _mapController.move(target, 14.0);
      _onCameraMoved(target);
      setState(() {
        _searchResults = [];
        _searchCtrl.clear();
      });
      FocusScope.of(context).unfocus();
    }
  }

  Future<void> _locateViaGps() async {
    setState(() => _isLocatingGps = true);
    HapticFeedback.lightImpact();

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          _showNotice('يرجى تفعيل خدمة الموقع (GPS) في هاتفك');
        }
        setState(() => _isLocatingGps = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) _showNotice('تم رفض إذن الوصول للموقع');
          setState(() => _isLocatingGps = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) _showNotice('إذن الموقع مرفوض نهائياً من إعدادات الجهاز');
        setState(() => _isLocatingGps = false);
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 6),
        ),
      );

      final target = LatLng(pos.latitude, pos.longitude);
      _mapController.move(target, 15.0);
      _onCameraMoved(target);
      if (mounted) {
        _showNotice('تم تحديد موقعك بدقة عبر GPS ✓');
      }
    } catch (_) {
      if (mounted) {
        _showNotice('تعذر قراءة الموقع الحالي بدقة، يمكنك تحديده بالنقر على الخريطة');
      }
    } finally {
      if (mounted) setState(() => _isLocatingGps = false);
    }
  }

  void _showNotice(String msg) {
    AppToast.show(context, 
      SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: DhikrTheme.arabicFont)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _confirmLocation() async {
    HapticFeedback.mediumImpact();
    final appState = context.read<AppState>();

    final cityAr = _detectedCityAr.isNotEmpty ? _detectedCityAr : 'موقع محدد';
    final cityEn = _detectedCityEn.isNotEmpty ? _detectedCityEn : 'Selected Location';
    final countryAr = _detectedCountryAr.isNotEmpty ? _detectedCountryAr : '';
    final countryEn = _detectedCountryEn.isNotEmpty ? _detectedCountryEn : '';

    await appState.saveLocation(
      lat: _currentCenter.latitude,
      lng: _currentCenter.longitude,
      cityAr: cityAr,
      cityEn: cityEn,
      countryAr: countryAr,
      countryEn: countryEn,
      countryCode: _detectedCountryCode,
    );

    if (!mounted) return;

    Navigator.of(context).pop(true);

    AppToast.show(context, 
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'تم اعتماد الموقع: $cityAr ${countryAr.isNotEmpty ? '($countryAr)' : ''} وتحديث المواقيت بنجاح ✓',
                style: const TextStyle(fontFamily: DhikrTheme.arabicFont, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F766E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final isAr = context.watch<AppState>().language == AppLanguage.arabic;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: dark ? const Color(0xFF0D1B16) : const Color(0xFFF7F5F0),
        body: Stack(
          children: [
            // ─────────────────────────────────────────────
            // 1. Interactive Flutter Map with Google Tiles
            // ─────────────────────────────────────────────
            Positioned.fill(
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _currentCenter,
                  initialZoom: 13.0,
                  minZoom: 3.0,
                  maxZoom: 18.5,
                  onPositionChanged: (camera, hasGesture) {
                    if (hasGesture) {
                      _onCameraMoved(camera.center);
                    }
                  },
                  onTap: (tapPosition, point) {
                    _mapController.move(point, _mapController.camera.zoom);
                    _onCameraMoved(point);
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: _currentTileUrl,
                    userAgentPackageName: 'com.almuumin.adhkar',
                    maxZoom: 19,
                  ),
                ],
              ),
            ),

            // ─────────────────────────────────────────────
            // 2. Fixed Animated Center Pin
            // ─────────────────────────────────────────────
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 38), // Pin tip aligns with center
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F766E).withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        isAr ? 'الموقع المحدد' : 'Selected Point',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          fontFamily: DhikrTheme.arabicFont,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF0F766E).withValues(alpha: 0.25),
                          ),
                        ),
                        const Icon(
                          Icons.location_on_rounded,
                          size: 44,
                          color: Color(0xFF0F766E),
                        ),
                      ],
                    ),
                    Container(
                      width: 8,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ─────────────────────────────────────────────
            // 3. Top Header with Back, Search, and Layer Toggle
            // ─────────────────────────────────────────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // Back Button
                          _buildGlassButton(
                            icon: Icons.arrow_back_rounded,
                            dark: dark,
                            onTap: () => Navigator.of(context).pop(),
                          ),
                          const SizedBox(width: 8),

                          // Search Bar
                          Expanded(
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: dark
                                    ? const Color(0xFF16231E).withValues(alpha: 0.92)
                                    : Colors.white.withValues(alpha: 0.94),
                                borderRadius: BorderRadius.circular(24),
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
                                      onChanged: _searchPlaces,
                                      style: TextStyle(
                                        fontFamily: DhikrTheme.arabicFont,
                                        fontSize: 13.5,
                                        color: dark ? Colors.white : DhikrColors.charcoal,
                                      ),
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        hintText: isAr
                                            ? 'ابحث عن مدينة، حي، أو منطقة...'
                                            : 'Search city or district...',
                                        hintStyle: TextStyle(
                                          fontFamily: DhikrTheme.arabicFont,
                                          fontSize: 13,
                                          color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (_isSearching)
                                    const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  else if (_searchCtrl.text.isNotEmpty)
                                    GestureDetector(
                                      onTap: () {
                                        _searchCtrl.clear();
                                        setState(() => _searchResults = []);
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

                          // Layer Switcher Menu
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
                                    Text('خرائط جوجل (شوارع)', style: TextStyle(fontFamily: DhikrTheme.arabicFont)),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: MapLayerType.googleSatellite,
                                child: Row(
                                  children: [
                                    Icon(Icons.satellite_alt_rounded, size: 18, color: Color(0xFFD97706)),
                                    SizedBox(width: 10),
                                    Text('قمر صناعي جوجل', style: TextStyle(fontFamily: DhikrTheme.arabicFont)),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: MapLayerType.openStreetMap,
                                child: Row(
                                  children: [
                                    Icon(Icons.layers_rounded, size: 18, color: Color(0xFF4F46E5)),
                                    SizedBox(width: 10),
                                    Text('خريطة OpenStreetMap', style: TextStyle(fontFamily: DhikrTheme.arabicFont)),
                                  ],
                                ),
                              ),
                            ],
                            child: _buildGlassButton(
                              icon: Icons.layers_rounded,
                              dark: dark,
                              onTap: null,
                            ),
                          ),
                        ],
                      ),

                      // Search Suggestions Dropdown
                      if (_searchResults.isNotEmpty)
                        Container(
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
                              return ListTile(
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
                              );
                            },
                          ),
                        ),

                      // Quick Jump Chips (Iraq & Arab capitals)
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            _buildQuickChip('بغداد 🇮🇶', 33.3152, 44.3661, dark),
                            _buildQuickChip('النجف الأشرف', 32.0259, 44.3463, dark),
                            _buildQuickChip('كربلاء المقدسة', 32.6160, 44.0249, dark),
                            _buildQuickChip('البصرة', 30.5081, 47.7835, dark),
                            _buildQuickChip('أربيل', 36.1911, 44.0092, dark),
                            _buildQuickChip('ميت غمر 🇪🇬', 30.7192, 31.2618, dark),
                            _buildQuickChip('القاهرة', 30.0444, 31.2357, dark),
                            _buildQuickChip('مكة المكرمة 🇸🇦', 21.3891, 39.8579, dark),
                            _buildQuickChip('المدينة المنورة', 24.5247, 39.5692, dark),
                            _buildQuickChip('عمان 🇯🇴', 31.9454, 35.9284, dark),
                            _buildQuickChip('دمشق 🇸🇾', 33.5138, 36.2765, dark),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ─────────────────────────────────────────────
            // 4. Floating Action Buttons (GPS & Zoom)
            // ─────────────────────────────────────────────
            Positioned(
              right: isAr ? null : 16,
              left: isAr ? 16 : null,
              bottom: 190,
              child: Column(
                children: [
                  // GPS Current Location
                  FloatingActionButton.small(
                    heroTag: 'gps_btn',
                    backgroundColor: dark ? const Color(0xFF1E2824) : Colors.white,
                    foregroundColor: const Color(0xFF0F766E),
                    elevation: 3,
                    onPressed: _isLocatingGps ? null : _locateViaGps,
                    child: _isLocatingGps
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0F766E)),
                          )
                        : const Icon(Icons.my_location_rounded, size: 20),
                  ),
                  const SizedBox(height: 8),

                  // Zoom In
                  FloatingActionButton.small(
                    heroTag: 'zoom_in_btn',
                    backgroundColor: dark ? const Color(0xFF1E2824) : Colors.white,
                    foregroundColor: dark ? Colors.white : DhikrColors.charcoal,
                    elevation: 3,
                    onPressed: () {
                      final z = _mapController.camera.zoom;
                      _mapController.move(_mapController.camera.center, (z + 1).clamp(3.0, 18.5));
                    },
                    child: const Icon(Icons.add, size: 20),
                  ),
                  const SizedBox(height: 6),

                  // Zoom Out
                  FloatingActionButton.small(
                    heroTag: 'zoom_out_btn',
                    backgroundColor: dark ? const Color(0xFF1E2824) : Colors.white,
                    foregroundColor: dark ? Colors.white : DhikrColors.charcoal,
                    elevation: 3,
                    onPressed: () {
                      final z = _mapController.camera.zoom;
                      _mapController.move(_mapController.camera.center, (z - 1).clamp(3.0, 18.5));
                    },
                    child: const Icon(Icons.remove, size: 20),
                  ),
                ],
              ),
            ),

            // ─────────────────────────────────────────────
            // 5. Floating Bottom Confirmation Card
            // ─────────────────────────────────────────────
            Positioned(
              left: 16,
              right: 16,
              bottom: 18,
              child: SafeArea(
                top: false,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: dark
                            ? const Color(0xFF16231E).withValues(alpha: 0.96)
                            : Colors.white.withValues(alpha: 0.96),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: (dark ? DhikrColors.sage : DhikrColors.forest).withValues(alpha: 0.25),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Address Details
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F766E).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: _isGeocoding
                                    ? const Center(
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0F766E)),
                                        ),
                                      )
                                    : const Icon(
                                        LucideIcons.mapPin,
                                        color: Color(0xFF0F766E),
                                        size: 22,
                                      ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _detectedCityAr.isNotEmpty
                                          ? _detectedCityAr
                                          : (isAr ? 'جارِ تحديد المدينة...' : 'Detecting city...'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: DhikrTheme.arabicFont,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                        color: dark ? Colors.white : DhikrColors.charcoal,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${_detectedCountryAr.isNotEmpty ? '$_detectedCountryAr • ' : ''}${_currentCenter.latitude.toStringAsFixed(4)}°, ${_currentCenter.longitude.toStringAsFixed(4)}°',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: DhikrTheme.arabicFont,
                                        fontSize: 12,
                                        color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Confirm Button
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0F766E),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: _confirmLocation,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.check_circle_rounded, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    isAr ? 'تأكيد واختيار هذا الموقع' : 'Confirm & Set Location',
                                    style: const TextStyle(
                                      fontFamily: DhikrTheme.arabicFont,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassButton({
    required IconData icon,
    required bool dark,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: dark
                ? const Color(0xFF16231E).withValues(alpha: 0.92)
                : Colors.white.withValues(alpha: 0.94),
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
  }

  Widget _buildQuickChip(String label, double lat, double lng, bool dark) {
    return Padding(
      padding: const EdgeInsets.only(left: 6, right: 6),
      child: ActionChip(
        label: Text(
          label,
          style: TextStyle(
            fontFamily: DhikrTheme.arabicFont,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: dark ? Colors.white : DhikrColors.charcoal,
          ),
        ),
        backgroundColor: dark
            ? const Color(0xFF182621).withValues(alpha: 0.92)
            : Colors.white.withValues(alpha: 0.94),
        side: BorderSide(
          color: (dark ? DhikrColors.sage : DhikrColors.forest).withValues(alpha: 0.2),
          width: 1,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        onPressed: () {
          HapticFeedback.selectionClick();
          final target = LatLng(lat, lng);
          _mapController.move(target, 13.5);
          _onCameraMoved(target);
        },
      ),
    );
  }
}
