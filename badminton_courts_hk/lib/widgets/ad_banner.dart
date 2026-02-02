import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io';

class AdBanner extends StatefulWidget {
  const AdBanner({super.key});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  AdSize? _adSize;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadAd();
  }

  Future<void> _loadAd() async {
    // This check uses the --dart-define=SHOW_ADS=true build flag
    const bool showAds = bool.fromEnvironment('SHOW_ADS', defaultValue: false);
    if (!showAds || kIsWeb) return;

    // Get adaptive size
    final AdSize size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
      MediaQuery.of(context).size.width.truncate(),
    ) ?? AdSize.banner;

    final adUnitId = Platform.isAndroid
        ? 'ca-app-pub-3940256099942544/6300978111' // Android Test Unit ID
        : 'ca-app-pub-3940256099942544/2934735716'; // iOS Test Unit ID

    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _bannerAd = ad as BannerAd;
            _isLoaded = true;
            _adSize = size;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('AdBanner failed to load: $error');
        },
      ),
    );

    return _bannerAd!.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const bool showAds = bool.fromEnvironment('SHOW_ADS', defaultValue: false);
    if (!showAds) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Default placeholder height if ad not loaded yet
    double height = _adSize?.height.toDouble() ?? 60.0;

    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white24 : Colors.black12,
            width: 0.5,
          ),
        ),
      ),
      child: _isLoaded && _bannerAd != null
          ? AdWidget(ad: _bannerAd!)
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    kIsWeb ? 'Google AdSense' : 'Google AdMob (Adaptive)',
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black54,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Banner Ad Area',
                    style: TextStyle(
                      color: isDark ? Colors.white38 : Colors.black38,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
