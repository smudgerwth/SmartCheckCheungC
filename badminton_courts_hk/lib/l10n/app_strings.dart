class AppStrings {
  static const Map<String, Map<String, String>> _strings = {
    'en': {
      'appTitle': 'Sports Courts HK',
      'bookNow': 'Book now',
      'badminton': 'Badminton',
      'basketball': 'Basketball',
      'pickleball': 'Pickleball',
      'tennis': 'Tennis',
      'volleyball': 'Volleyball',
      'searchHint': 'Search venues...',
      'all': 'All',
      'morning': 'Morning',
      'afternoon': 'Afternoon',
      'evening': 'Evening',
      'available': 'Available ',
      'noCourts': 'No courts found',
      'noCourtsMessage': 'Try adjusting your filters or searching for a different venue',
      'resetFilters': 'Reset Filters',
      'updating': 'Updating...',
      'errorLoading': 'Error loading data',
      'smartPlayUrl': 'https://www.smartplay.lcsd.gov.hk/home?lang=en',
      'smartPlayLabel': 'SmartPlay',
    },
    'zh-hk': {
      'appTitle': '香港羽毛球場',
      'bookNow': '立即預訂',
      'badminton': '羽毛球',
      'basketball': '籃球',
      'pickleball': '匹克球',
      'tennis': '網球',
      'volleyball': '排球',
      'searchHint': '搜尋場地...',
      'all': '全部',
      'morning': '早上',
      'afternoon': '下午',
      'evening': '晚上',
      'available': '可預訂 ',
      'noCourts': '沒有找到場地',
      'noCourtsMessage': '嘗試調整篩選條件或搜尋其他場地',
      'resetFilters': '重置篩選',
      'updating': '更新中...',
      'errorLoading': '載入資料時發生錯誤',
      'smartPlayUrl': 'https://www.smartplay.lcsd.gov.hk/home?lang=tc',
      'smartPlayLabel': 'SmartPLAY',
    },
    'zh-cn': {
      'appTitle': '香港羽毛球场',
      'bookNow': '立即预订',
      'badminton': '羽毛球',
      'basketball': '篮球',
      'pickleball': '匹克球',
      'tennis': '网球',
      'volleyball': '排球',
      'searchHint': '搜索场地...',
      'all': '全部',
      'morning': '早上',
      'afternoon': '下午',
      'evening': '晚上',
      'available': '可预订 ',
      'noCourts': '没有找到场地',
      'noCourtsMessage': '尝试调整筛选条件或搜索其他场地',
      'resetFilters': '重置筛选',
      'updating': '更新中...',
      'errorLoading': '加载数据时发生错误',
      'smartPlayUrl': 'https://www.smartplay.lcsd.gov.hk/home?lang=sc',
      'smartPlayLabel': 'SmartPLAY',
    },
  };

  static String get(String locale, String key) {
    // Normalize locale to ensure we match keys (e.g. en-US -> en)
    String normalizedLocale = locale.toLowerCase();
    if (normalizedLocale.startsWith('zh')) {
        if (normalizedLocale.contains('cn') || normalizedLocale.contains('hans')) {
            normalizedLocale = 'zh-cn';
        } else {
            normalizedLocale = 'zh-hk';
        }
    } else {
        normalizedLocale = 'en';
    }

    return _strings[normalizedLocale]?[key] ?? _strings['en']?[key] ?? key;
  }
}
