import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/court_session.dart';
import '../services/api_service.dart';

import '../models/district.dart';

final apiServiceProvider = Provider((ref) => ApiService());

final facilityCodeProvider = NotifierProvider<FacilityNotifier, String>(FacilityNotifier.new);
final selectedDateProvider = NotifierProvider<DateNotifier, String>(DateNotifier.new);

final selectedRegionsProvider = NotifierProvider<RegionsNotifier, List<String>>(RegionsNotifier.new);
final selectedDistrictsProvider = NotifierProvider<DistrictsNotifier, List<String>>(DistrictsNotifier.new);

// New Filter Providers
final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

final showOnlyAvailableProvider = NotifierProvider<FilterNotifier, bool>(() => FilterNotifier('show_only_available'));
final showOnlyFavoritesProvider = NotifierProvider<FilterNotifier, bool>(() => FilterNotifier('show_only_favorites'));

enum TimeFilter { all, morning, afternoon, evening }
final timeFilterProvider = NotifierProvider<TimeFilterNotifier, TimeFilter>(TimeFilterNotifier.new);

// Favorites Provider
final favoritesProvider = NotifierProvider<FavoritesNotifier, Set<String>>(FavoritesNotifier.new);

class FavoritesNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    _loadFavorites();
    return {};
  }

  static const _key = 'favorite_venues';

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? favorites = prefs.getStringList(_key);
    if (favorites != null) {
      state = favorites.toSet();
    }
  }

  Future<void> toggleFavorite(String venueId) async {
    final prefs = await SharedPreferences.getInstance();
    final current = {...state};
    if (current.contains(venueId)) {
      current.remove(venueId);
    } else {
      current.add(venueId);
    }
    state = current;
    await prefs.setStringList(_key, current.toList());
  }
}

class FilterNotifier extends Notifier<bool> {
  final String _key;
  FilterNotifier(this._key);

  @override
  bool build() {
    _loadState();
    return false;
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_key) ?? false;
  }

  Future<void> toggle() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, state);
  }

  Future<void> set(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, state);
  }
}

class FacilityNotifier extends Notifier<String> {
  @override
  String build() => 'BADC';
  set state(String value) => super.state = value;
}

class DateNotifier extends Notifier<String> {
  @override
  String build() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }
  set state(String value) => super.state = value;
}

class RegionsNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => [];
  set state(List<String> value) => super.state = value;
}

class DistrictsNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => [];
  set state(List<String> value) => super.state = value;
}

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  set state(String value) => super.state = value;
}

class TimeFilterNotifier extends Notifier<TimeFilter> {
  @override
  TimeFilter build() => TimeFilter.all;
  set state(TimeFilter value) => super.state = value;
}

final districtsProvider = FutureProvider<List<Region>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  final locale = ref.watch(localeProvider);
  apiService.setLocale(locale);
  return apiService.fetchDistricts();
});

// Locale Provider
final localeProvider = NotifierProvider<LocaleNotifier, String>(LocaleNotifier.new);

class LocaleNotifier extends Notifier<String> {
  @override
  String build() {
    _initLocale();
    return 'en';
  }

  static const _key = 'app_locale';

  Future<void> _initLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLocale = prefs.getString(_key);
    
    if (savedLocale != null) {
      state = savedLocale;
    } else {
      final systemLocale = WidgetsBinding.instance.platformDispatcher.locale;
      final languageCode = systemLocale.languageCode.toLowerCase();
      final scriptCode = systemLocale.scriptCode?.toLowerCase();
      final countryCode = systemLocale.countryCode?.toLowerCase();

      if (languageCode == 'zh') {
        if (scriptCode == 'hans' || countryCode == 'cn') {
          state = 'zh-cn';
        } else {
          state = 'zh-hk';
        }
      } else {
        state = 'en';
      }
    }
  }

  Future<void> setLocale(String locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, locale);
  }
}

// Theme Mode Provider
final themeModeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(ThemeNotifier.new);

class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _loadTheme();
    return ThemeMode.dark;
  }

  static const _key = 'app_theme_mode';

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_key);
    if (themeIndex != null) {
      state = ThemeMode.values[themeIndex];
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, mode.index);
  }

  Future<void> toggleTheme() async {
    final current = state;
    final newMode = current == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await setThemeMode(newMode);
  }
}

final sessionsProvider = FutureProvider<List<CourtSession>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  final facilityCode = ref.watch(facilityCodeProvider);
  final date = ref.watch(selectedDateProvider);
  final locale = ref.watch(localeProvider);
  
  apiService.setLocale(locale);
  return apiService.fetchSessions(facilityCode, date);
});

final groupedSessionsProvider = FutureProvider<List<GroupedCourt>>((ref) async {
  // Watch all filters to make the grouping reactive
  ref.watch(selectedRegionsProvider);
  ref.watch(selectedDistrictsProvider);
  ref.watch(searchQueryProvider);
  ref.watch(showOnlyAvailableProvider);
  ref.watch(showOnlyFavoritesProvider);
  ref.watch(timeFilterProvider);
  ref.watch(favoritesProvider);
  
  final sessions = await ref.watch(sessionsProvider.future);
  return _processSessions(sessions, ref);
});

List<GroupedCourt> _processSessions(List<CourtSession> sessions, Ref ref) {
  final selectedRegions = ref.read(selectedRegionsProvider);
  final selectedDistricts = ref.read(selectedDistrictsProvider);
  
  final searchQuery = ref.read(searchQueryProvider).toLowerCase();
  final showOnlyAvailable = ref.read(showOnlyAvailableProvider);
  final showOnlyFavorites = ref.read(showOnlyFavoritesProvider);
  final timeFilter = ref.read(timeFilterProvider);
  final favorites = ref.read(favoritesProvider);

  // Get the effective list of allowed districts
  Set<String>? allowedDistrictCodes;
  
  if (selectedDistricts.isNotEmpty) {
    allowedDistrictCodes = selectedDistricts.toSet();
  } else if (selectedRegions.isNotEmpty) {
    final regionsAsync = ref.read(districtsProvider);
    final allRegions = regionsAsync.value ?? [];
    allowedDistrictCodes = allRegions
        .where((r) => selectedRegions.contains(r.code))
        .expand((r) => r.districts)
        .map((d) => d.code)
        .toSet();
  }

  final Map<String, GroupedCourt> grouped = {};
  
  for (var session in sessions) {
    // 1. Filter by Regions/Districts
    if (allowedDistrictCodes != null && !allowedDistrictCodes.contains(session.distCode)) {
      continue;
    }

    // 2. Filter by Search Query
    if (searchQuery.isNotEmpty && !session.venueName.toLowerCase().contains(searchQuery)) {
      continue;
    }

    // 3. Filter by Time Filter
    if (timeFilter != TimeFilter.all) {
      final hour = int.parse(session.ssnStartTime.split(':')[0]);
      if (timeFilter == TimeFilter.morning && hour >= 12) continue;
      if (timeFilter == TimeFilter.afternoon && (hour < 12 || hour >= 18)) continue;
      if (timeFilter == TimeFilter.evening && hour < 18) continue;
    }

    // 4. Filter by Availability
    if (showOnlyAvailable && !session.available) {
      continue;
    }
    
    // 5. Filter by Favorites
    if (showOnlyFavorites && !favorites.contains(session.venueId)) {
      continue;
    }

    final key = "${session.venueId}_${session.fatId}";
    if (grouped.containsKey(key)) {
      grouped[key]!.sessions.add(session);
    } else {
      grouped[key] = GroupedCourt(
        distName: session.distName,
        venueName: session.venueName,
        venueId: session.venueId,
        fatName: session.fatName,
        fatId: session.fatId,
        sessions: [session],
      );
    }
  }
  
  for (var group in grouped.values) {
    group.sessions.sort((a, b) => a.ssnStartTime.compareTo(b.ssnStartTime));
  }
  
  return grouped.values.toList()
    ..sort((a, b) {
      final aFav = favorites.contains(a.venueId);
      final bFav = favorites.contains(b.venueId);
      if (aFav != bFav) return aFav ? -1 : 1;
      return a.distName.compareTo(b.distName);
    });
}


