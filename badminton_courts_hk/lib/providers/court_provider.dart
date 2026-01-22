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

final selectedRegionsProvider = StateProvider<List<String>>((ref) => ['HK']);
final selectedDistrictsProvider = StateProvider<List<String>>((ref) => []);

// New Filter Providers
final searchQueryProvider = StateProvider<String>((ref) => '');
final showOnlyAvailableProvider = StateProvider<bool>((ref) => false);

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

final districtsProvider = FutureProvider<List<Region>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.fetchDistricts();
});

final sessionsProvider = FutureProvider<List<CourtSession>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  final facilityCode = ref.watch(facilityCodeProvider);
  final date = ref.watch(selectedDateProvider);
  
  return apiService.fetchSessions(facilityCode, date);
});

final groupedSessionsProvider = FutureProvider<List<GroupedCourt>>((ref) async {
  // Watch all filters to make the grouping reactive
  ref.watch(selectedRegionsProvider);
  ref.watch(selectedDistrictsProvider);
  ref.watch(searchQueryProvider);
  ref.watch(showOnlyAvailableProvider);
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


