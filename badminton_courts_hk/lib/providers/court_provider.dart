import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/court_session.dart';
import '../services/api_service.dart';

import '../models/district.dart';

final apiServiceProvider = Provider((ref) => ApiService());

final facilityCodeProvider = StateProvider<String>((ref) => 'BADC');
final selectedDateProvider = StateProvider<String>((ref) {
  final now = DateTime.now();
  return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
});

final selectedRegionsProvider = StateProvider<List<String>>((ref) => []);
final selectedDistrictsProvider = StateProvider<List<String>>((ref) => []);

// New Filter Providers
final searchQueryProvider = StateProvider<String>((ref) => '');

final showOnlyAvailableProvider = StateNotifierProvider<FilterNotifier, bool>((ref) {
  return FilterNotifier('show_only_available');
});

final showOnlyFavoritesProvider = StateNotifierProvider<FilterNotifier, bool>((ref) {
  return FilterNotifier('show_only_favorites');
});

enum TimeFilter { all, morning, afternoon, evening }
final timeFilterProvider = StateProvider<TimeFilter>((ref) => TimeFilter.all);

// Favorites Provider
final favoritesProvider = StateNotifierProvider<FavoritesNotifier, Set<String>>((ref) {
  return FavoritesNotifier();
});

class FavoritesNotifier extends StateNotifier<Set<String>> {
  FavoritesNotifier() : super({}) {
    _loadFavorites();
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

class FilterNotifier extends StateNotifier<bool> {
  final String _key;
  FilterNotifier(this._key) : super(false) {
    _loadState();
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

final districtsProvider = FutureProvider<List<Region>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  // Ensure we refetch when locale changes, although fetchDistricts might be static data, 
  // keeping it simple. Actually fetchDistricts returns ALL names, so we just need to redisplay.
  // But if we want to change header, we need to make sure ApiService has correct header.
  final locale = ref.watch(localeProvider);
  apiService.setLocale(locale);
  return apiService.fetchDistricts();
});

// Locale Provider
final localeProvider = StateNotifierProvider<LocaleNotifier, String>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<String> {
  LocaleNotifier() : super('en') {
    _initLocale();
  }

  static const _key = 'app_locale';

  Future<void> _initLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLocale = prefs.getString(_key);
    
    if (savedLocale != null) {
      state = savedLocale;
    } else {
      // Use system locale as default
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
final themeModeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.dark) {
    _loadTheme();
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
    final newMode = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
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


