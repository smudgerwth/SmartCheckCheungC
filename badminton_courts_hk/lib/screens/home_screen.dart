import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/court_provider.dart';
import '../models/district.dart';
import '../widgets/court_card.dart';
import '../theme/app_theme.dart';
import '../l10n/app_strings.dart';
import '../widgets/ad_banner.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(groupedSessionsProvider);
    final selectedFacility = ref.watch(facilityCodeProvider);
    final locale = ref.watch(localeProvider);

    final isLight = Theme.of(context).brightness == Brightness.light;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isLight 
              ? [AppTheme.lightBackgroundColor, AppTheme.lightBackgroundColor.withBlue(245)]
              : [AppTheme.backgroundColor, AppTheme.backgroundColor.withBlue(40)],
          ),
        ),
        child: SafeArea(
          child: ScrollConfiguration(
            behavior: const ScrollBehavior().copyWith(
              dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
                PointerDeviceKind.trackpad,
              },
            ),
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverToBoxAdapter(child: _buildHeader(context, locale)),
                SliverToBoxAdapter(child: _buildFacilitySwitch(context, ref, selectedFacility, locale)),
                SliverToBoxAdapter(child: _buildDatePicker(context, ref)),
                SliverToBoxAdapter(child: Divider(height: 1, color: isLight ? Colors.black12 : Colors.white10)),
                SliverToBoxAdapter(child: _buildRegionFilter(context, ref)),
                SliverToBoxAdapter(child: _buildDistrictFilter(context, ref)),
                SliverToBoxAdapter(child: _buildSearchAndFilters(context, ref, locale)),
                SliverToBoxAdapter(child: Divider(height: 1, color: isLight ? Colors.black12 : Colors.white10)),
              ],
              body: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(sessionsProvider);
                  await ref.read(sessionsProvider.future);
                },
                backgroundColor: isLight ? Colors.white : AppTheme.cardColor,
                color: AppTheme.primaryColor,
                child: sessionsAsync.when(
                  data: (courts) => Stack(
                    children: [
                      courts.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                SizedBox(
                                  height: MediaQuery.of(context).size.height * 0.6,
                                  child: _buildEmptyState(context, ref, locale),
                                ),
                              ],
                            )
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              itemCount: courts.length,
                              itemBuilder: (context, index) => CourtCard(court: courts[index]),
                            ),
                      if (sessionsAsync.isLoading)
                        Positioned.fill(
                          child: _buildLoadingMask(context, locale),
                        ),
                    ],
                  ),
                  loading: () => _buildShimmerLoading(context),
                  error: (err, stack) => _buildErrorView(context, err.toString(), locale),
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: const AdBanner(),
    );
  }

  Widget _buildHeader(BuildContext context, String locale) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        AppStrings.get(locale, 'appTitle'), 
                        style: Theme.of(context).textTheme.headlineLarge,
                        overflow: TextOverflow.visible,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _launchURL(AppStrings.get(locale, 'smartPlayUrl')),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          AppStrings.get(locale, 'smartPlayLabel'),
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(AppStrings.get(locale, 'availableCourts'), style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          ),
          Row(
            children: [
              Consumer(
                builder: (context, ref, child) {
                  final themeMode = ref.watch(themeModeProvider);
                  return IconButton(
                    icon: Icon(
                      themeMode == ThemeMode.light ? Icons.dark_mode : Icons.light_mode,
                      color: Theme.of(context).brightness == Brightness.light 
                          ? const Color(0xFF0F172A) 
                          : Colors.white,
                    ),
                    onPressed: () => ref.read(themeModeProvider.notifier).toggleTheme(),
                  );
                },
              ),
              Consumer(
                builder: (context, ref, child) {
                  return PopupMenuButton<String>(
                    icon: Icon(
                      Icons.language,
                      color: Theme.of(context).brightness == Brightness.light
                          ? const Color(0xFF0F172A)
                          : Colors.white,
                    ),
                    color: Theme.of(context).brightness == Brightness.light
                        ? Colors.white
                        : AppTheme.cardColor,
                    onSelected: (value) => ref.read(localeProvider.notifier).setLocale(value),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'en',
                        child: Text('English', 
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.light 
                                ? Colors.black87 
                                : Colors.white
                          )
                        ),
                      ),
                      PopupMenuItem(
                        value: 'zh-hk',
                        child: Text('繁體中文', 
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.light 
                                ? Colors.black87 
                                : Colors.white
                          )
                        ),
                      ),
                      PopupMenuItem(
                        value: 'zh-cn',
                        child: Text('简体中文', 
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.light 
                                ? Colors.black87 
                                : Colors.white
                          )
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildFacilitySwitch(BuildContext context, WidgetRef ref, String currentCode, String locale) {
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _facilityButton(context, ref, AppStrings.get(locale, 'badminton'), 'BADC', currentCode == 'BADC'),
          const SizedBox(width: 12),
          _facilityButton(context, ref, AppStrings.get(locale, 'basketball'), 'BASC', currentCode == 'BASC'),
        ],
      ),
    );
  }

  Widget _facilityButton(BuildContext context, WidgetRef ref, String label, String code, bool isSelected) {
    return GestureDetector(
      onTap: () => ref.read(facilityCodeProvider.notifier).state = code,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : (Theme.of(context).brightness == Brightness.light ? Colors.black.withOpacity(0.05) : AppTheme.cardColor),
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))]
              : [],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : (Theme.of(context).brightness == Brightness.light ? Colors.black54 : Colors.white60),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final isLight = Theme.of(context).brightness == Brightness.light;
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: 7, // Next 7 days
        itemBuilder: (context, index) {
          final date = DateTime.now().add(Duration(days: index));
          final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
          final isSelected = dateStr == selectedDate;

          return GestureDetector(
            onTap: () => ref.read(selectedDateProvider.notifier).state = dateStr,
            child: Container(
              width: 80,
              margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.secondaryColor : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: isSelected ? null : Border.all(color: isLight ? Colors.black12 : Colors.white24),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "${date.day}/${date.month}",
                    style: TextStyle(
                      color: isSelected ? Colors.white : (isLight ? Colors.black54 : Colors.white60),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _getLocalizedName(dynamic item, String locale) {
    // Both Region and District have name, enName, tcName, scName (District only currently)
    // Actually Region only has name (which is usually English/Mixed?)
    // Wait, Region.fromJson: name: json['name']
    // Let's check district.dart for Region definition.
    // Region has name but not localized methods.
    // Actually the user request: "use the tcName, scName and enName of district from fetchDistricts"
    // So for District chips, we use localized name.
    
    if (item is District) {
      if (locale == 'zh-hk') return item.tcName;
      if (locale == 'zh-cn' && item.scName.isNotEmpty) return item.scName;
      if (locale == 'en') return item.enName;
      return item.enName.isNotEmpty ? item.enName : item.name;
    }
    // For Region, it seems we only have 'name'. If API returned localized regions, we'd use them.
    // But currently District names are the focus.
    return item.name; 
  }

  Widget _buildRegionFilter(BuildContext context, WidgetRef ref) {
    final regionsAsync = ref.watch(districtsProvider);
    final selectedRegions = ref.watch(selectedRegionsProvider);
    final isLight = Theme.of(context).brightness == Brightness.light;

    return regionsAsync.when(
      data: (regions) => SizedBox(
        height: 50,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          itemCount: regions.length,
          itemBuilder: (context, index) {
            final region = regions[index];
            final isSelected = selectedRegions.contains(region.code);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: FilterChip(
                label: Text(
                  region.name, // Region names might not be localized in model yet
                  style: TextStyle(
                    color: isSelected ? Colors.white : (isLight ? Colors.black54 : Colors.white60),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                selected: isSelected,
                onSelected: (selected) {
                  final current = [...selectedRegions];
                  if (selected) {
                    current.add(region.code);
                  } else {
                    current.remove(region.code);
                  }
                  // Reset district selection whenever region selection changes
                  ref.read(selectedDistrictsProvider.notifier).state = [];
                  ref.read(selectedRegionsProvider.notifier).state = current;
                },
                selectedColor: AppTheme.secondaryColor,
                backgroundColor: isLight ? Colors.black.withOpacity(0.05) : AppTheme.cardColor,
                checkmarkColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            );
          },
        ),
      ),
      loading: () => const SizedBox(height: 50),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildDistrictFilter(BuildContext context, WidgetRef ref) {
    final regionsAsync = ref.watch(districtsProvider);
    final selectedRegions = ref.watch(selectedRegionsProvider);
    final selectedDistricts = ref.watch(selectedDistrictsProvider);
    final locale = ref.watch(localeProvider);
    final isLight = Theme.of(context).brightness == Brightness.light;

    return regionsAsync.when(
      data: (regions) {
        // Only show districts if their region is selected
        // Or show all if NO region is selected
        final List<District> visibleDistricts = selectedRegions.isEmpty
            ? regions.expand((r) => r.districts).toList()
            : regions
                .where((r) => selectedRegions.contains(r.code))
                .expand((r) => r.districts)
                .toList();

        if (visibleDistricts.isEmpty) return const SizedBox.shrink();

        return SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: visibleDistricts.length,
            itemBuilder: (context, index) {
              final district = visibleDistricts[index];
              final isSelected = selectedDistricts.contains(district.code);

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: FilterChip(
                  label: Text(
                    _getLocalizedName(district, locale),
                    style: TextStyle(
                      color: isSelected ? Colors.white : (isLight ? Colors.black54 : Colors.white60),
                      fontSize: 11,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    final current = [...selectedDistricts];
                    if (selected) {
                      current.add(district.code);
                    } else {
                      current.remove(district.code);
                    }
                    ref.read(selectedDistrictsProvider.notifier).state = current;
                  },
                  selectedColor: AppTheme.primaryColor.withOpacity(0.8),
                  backgroundColor: isLight ? Colors.black.withOpacity(0.05) : AppTheme.cardColor.withOpacity(0.5),
                  checkmarkColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const SizedBox(height: 50),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildSearchAndFilters(BuildContext context, WidgetRef ref, String locale) {
    final showOnlyAvailable = ref.watch(showOnlyAvailableProvider);
    final showOnlyFavorites = ref.watch(showOnlyFavoritesProvider);
    final selectedTime = ref.watch(timeFilterProvider);
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: TextField(
            onChanged: (value) => ref.read(searchQueryProvider.notifier).state = value,
            style: TextStyle(color: isLight ? Colors.black87 : Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: AppStrings.get(locale, 'searchHint'),
              hintStyle: TextStyle(color: isLight ? Colors.black38 : Colors.white38),
              prefixIcon: Icon(Icons.search, color: isLight ? Colors.black38 : Colors.white38),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              filled: true,
              fillColor: isLight ? Colors.black.withOpacity(0.05) : AppTheme.cardColor.withOpacity(0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildTimeChip(context, ref, AppStrings.get(locale, 'all'), TimeFilter.all, selectedTime),
                      const SizedBox(width: 8),
                      _buildTimeChip(context, ref, AppStrings.get(locale, 'morning'), TimeFilter.morning, selectedTime),
                      const SizedBox(width: 8),
                      _buildTimeChip(context, ref, AppStrings.get(locale, 'afternoon'), TimeFilter.afternoon, selectedTime),
                      const SizedBox(width: 8),
                      _buildTimeChip(context, ref, AppStrings.get(locale, 'evening'), TimeFilter.evening, selectedTime),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => ref.read(showOnlyFavoritesProvider.notifier).toggle(),
                child: Icon(
                  showOnlyFavorites ? Icons.favorite : Icons.favorite_border, 
                  size: 18, 
                  color: showOnlyFavorites ? Colors.red : (isLight ? Colors.black26 : Colors.white24)
                ),
              ),
              const SizedBox(width: 8),
              Row(
                children: [
                  Text(AppStrings.get(locale, 'available'), style: TextStyle(color: isLight ? Colors.black38 : Colors.white38, fontSize: 10)),
                  SizedBox(
                    height: 24,
                    width: 40,
                    child: Switch(
                      value: showOnlyAvailable,
                      onChanged: (value) => ref.read(showOnlyAvailableProvider.notifier).set(value),
                      activeColor: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeChip(BuildContext context, WidgetRef ref, String label, TimeFilter filter, TimeFilter current) {
    final isSelected = filter == current;
    final isLight = Theme.of(context).brightness == Brightness.light;
    return GestureDetector(
      onTap: () => ref.read(timeFilterProvider.notifier).state = filter,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : (isLight ? Colors.black12 : Colors.white12),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.primaryColor : (isLight ? Colors.black54 : Colors.white60),
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerLoading(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final baseColor = isLight ? Colors.black.withOpacity(0.05) : AppTheme.cardColor;
    final highlightColor = isLight ? Colors.black.withOpacity(0.02) : AppTheme.cardColor.withBlue(60);
    
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 3,
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Container(
          height: 180,
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref, String locale) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Align(
      alignment: const Alignment(0, -0.8),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 80, color: isLight ? Colors.black.withOpacity(0.05) : Colors.white.withOpacity(0.1)),
            const SizedBox(height: 24),
            Text(
              AppStrings.get(locale, 'noCourts'),
              style: TextStyle(
                color: isLight ? Colors.black54 : Colors.white.withOpacity(0.6),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              AppStrings.get(locale, 'noCourtsMessage'),
              textAlign: TextAlign.center,
              style: TextStyle(color: isLight ? Colors.black38 : Colors.white.withOpacity(0.4)),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () {
                ref.read(searchQueryProvider.notifier).state = '';
                ref.read(showOnlyAvailableProvider.notifier).set(false);
                ref.read(showOnlyFavoritesProvider.notifier).set(false);
                ref.read(timeFilterProvider.notifier).state = TimeFilter.all;
              },
              child: Text(AppStrings.get(locale, 'resetFilters'), style: const TextStyle(color: AppTheme.primaryColor)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingMask(BuildContext context, String locale) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          color: isLight ? Colors.white.withOpacity(0.4) : Colors.black.withOpacity(0.4),
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isLight ? Colors.white.withOpacity(0.9) : Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isLight ? 0.1 : 0.5),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    color: AppTheme.primaryColor,
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.get(locale, 'updating'),
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, String error, String locale) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              AppStrings.get(locale, 'errorLoading'),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
    );
  }
}
