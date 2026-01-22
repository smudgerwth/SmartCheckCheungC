import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/court_provider.dart';
import '../models/district.dart';
import '../widgets/court_card.dart';
import '../theme/app_theme.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(groupedSessionsProvider);
    final selectedFacility = ref.watch(facilityCodeProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.backgroundColor,
              AppTheme.backgroundColor.withBlue(40),
            ],
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
                SliverToBoxAdapter(child: _buildHeader(context)),
                SliverToBoxAdapter(child: _buildFacilitySwitch(ref, selectedFacility)),
                SliverToBoxAdapter(child: _buildDatePicker(ref)),
                const SliverToBoxAdapter(child: Divider(height: 1, color: Colors.white10)),
                SliverToBoxAdapter(child: _buildRegionFilter(ref)),
                SliverToBoxAdapter(child: _buildDistrictFilter(ref)),
                SliverToBoxAdapter(child: _buildSearchAndFilters(ref)),
                const SliverToBoxAdapter(child: Divider(height: 1, color: Colors.white10)),
              ],
              body: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(sessionsProvider);
                  await ref.read(sessionsProvider.future);
                },
                backgroundColor: AppTheme.cardColor,
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
                                  child: _buildEmptyState(ref),
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
                          child: _buildLoadingMask(),
                        ),
                    ],
                  ),
                  loading: () => _buildShimmerLoading(),
                  error: (err, stack) => _buildErrorView(context, err.toString()),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Available Courts', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 8),
          Text('Badminton Courts HK', style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }

  Widget _buildFacilitySwitch(WidgetRef ref, String currentCode) {
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _facilityButton(ref, 'Badminton', 'BADC', currentCode == 'BADC'),
          const SizedBox(width: 12),
          _facilityButton(ref, 'Basketball', 'BASC', currentCode == 'BASC'),
        ],
      ),
    );
  }

  Widget _facilityButton(WidgetRef ref, String label, String code, bool isSelected) {
    return GestureDetector(
      onTap: () => ref.read(facilityCodeProvider.notifier).state = code,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : AppTheme.cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))]
              : [],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white60,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker(WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
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
                border: isSelected ? null : Border.all(color: Colors.white24),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "${date.day}/${date.month}",
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white60,
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

  Widget _buildRegionFilter(WidgetRef ref) {
    final regionsAsync = ref.watch(districtsProvider);
    final selectedRegions = ref.watch(selectedRegionsProvider);

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
                  region.name,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white60,
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
                    // Also clear districts from this region
                    final selectedDistricts = ref.read(selectedDistrictsProvider);
                    final regionDistCodes = region.districts.map((d) => d.code).toSet();
                    ref.read(selectedDistrictsProvider.notifier).state = 
                        selectedDistricts.where((d) => !regionDistCodes.contains(d)).toList();
                  }
                  ref.read(selectedRegionsProvider.notifier).state = current;
                },
                selectedColor: AppTheme.secondaryColor,
                backgroundColor: AppTheme.cardColor,
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

  Widget _buildDistrictFilter(WidgetRef ref) {
    final regionsAsync = ref.watch(districtsProvider);
    final selectedRegions = ref.watch(selectedRegionsProvider);
    final selectedDistricts = ref.watch(selectedDistrictsProvider);

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
                    district.tcName,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white60,
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
                  backgroundColor: AppTheme.cardColor.withOpacity(0.5),
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

  Widget _buildSearchAndFilters(WidgetRef ref) {
    final showOnlyAvailable = ref.watch(showOnlyAvailableProvider);
    final selectedTime = ref.watch(timeFilterProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: TextField(
            onChanged: (value) => ref.read(searchQueryProvider.notifier).state = value,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search venues...',
              hintStyle: const TextStyle(color: Colors.white38),
              prefixIcon: const Icon(Icons.search, color: Colors.white38),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              filled: true,
              fillColor: AppTheme.cardColor.withOpacity(0.5),
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
                      _buildTimeChip(ref, 'All', TimeFilter.all, selectedTime),
                      const SizedBox(width: 8),
                      _buildTimeChip(ref, 'Morning', TimeFilter.morning, selectedTime),
                      const SizedBox(width: 8),
                      _buildTimeChip(ref, 'Afternoon', TimeFilter.afternoon, selectedTime),
                      const SizedBox(width: 8),
                      _buildTimeChip(ref, 'Evening', TimeFilter.evening, selectedTime),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Row(
                children: [
                  const Text('Available ', style: TextStyle(color: Colors.white38, fontSize: 10)),
                  SizedBox(
                    height: 24,
                    width: 40,
                    child: Switch(
                      value: showOnlyAvailable,
                      onChanged: (value) => ref.read(showOnlyAvailableProvider.notifier).state = value,
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

  Widget _buildTimeChip(WidgetRef ref, String label, TimeFilter filter, TimeFilter current) {
    final isSelected = filter == current;
    return GestureDetector(
      onTap: () => ref.read(timeFilterProvider.notifier).state = filter,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.white12,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.primaryColor : Colors.white60,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 3,
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: AppTheme.cardColor,
        highlightColor: AppTheme.cardColor.withBlue(60),
        child: Container(
          height: 180,
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 80, color: Colors.white.withOpacity(0.1)),
            const SizedBox(height: 24),
            Text(
              'No courts found',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Try adjusting your filters or searching for a different venue.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.4)),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () {
                ref.read(searchQueryProvider.notifier).state = '';
                ref.read(showOnlyAvailableProvider.notifier).state = false;
                ref.read(timeFilterProvider.notifier).state = TimeFilter.all;
              },
              child: const Text('Reset Filters', style: TextStyle(color: AppTheme.primaryColor)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingMask() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          color: Colors.black.withOpacity(0.4),
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    color: AppTheme.primaryColor,
                    strokeWidth: 3,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Updating...',
                    style: TextStyle(
                      color: Colors.white,
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

  Widget _buildErrorView(BuildContext context, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Error loading data',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error.contains('cookies') ? 'Please update cookies using the key button below.' : error,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
