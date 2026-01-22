class CourtSession {
  final String distName;
  final String distCode;
  final String venueName;
  final String venueId;
  final String fatName;
  final String fatId;
  final String ssnStartTime;
  final String ssnStartDate;
  final bool available;
  final int sessionCount;
  final bool peakHour;

  CourtSession({
    required this.distName,
    required this.distCode,
    required this.venueName,
    required this.venueId,
    required this.fatName,
    required this.fatId,
    required this.ssnStartTime,
    required this.ssnStartDate,
    required this.available,
    required this.sessionCount,
    required this.peakHour,
  });

  factory CourtSession.fromJson(Map<String, dynamic> json) {
    return CourtSession(
      distName: json['distName']?.toString() ?? '',
      distCode: json['distCode']?.toString() ?? '',
      venueName: json['venueName']?.toString() ?? '',
      venueId: json['venueId']?.toString() ?? '',
      fatName: json['fatName']?.toString() ?? '',
      fatId: json['fatId']?.toString() ?? '',
      ssnStartTime: json['ssnStartTime']?.toString() ?? '',
      ssnStartDate: json['ssnStartDate']?.toString() ?? '',
      available: json['available'] is bool
          ? json['available']
          : (json['available']?.toString().toLowerCase() == 'true'),
      sessionCount: int.tryParse(json['sessionCount']?.toString() ?? '') ?? 
          (json['sessionCount'] is int ? json['sessionCount'] : 0),
      peakHour: json['peakHour'] is bool
          ? json['peakHour']
          : (json['peakHour']?.toString().toLowerCase() == 'true'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'distName': distName,
      'distCode': distCode,
      'venueName': venueName,
      'venueId': venueId,
      'fatName': fatName,
      'fatId': fatId,
      'ssnStartTime': ssnStartTime,
      'ssnStartDate': ssnStartDate,
      'available': available,
      'sessionCount': sessionCount,
      'peakHour': peakHour,
    };
  }
}

class GroupedCourt {
  final String distName;
  final String venueName;
  final String venueId;
  final String fatName;
  final String fatId;
  final List<CourtSession> sessions;

  GroupedCourt({
    required this.distName,
    required this.venueName,
    required this.venueId,
    required this.fatName,
    required this.fatId,
    required this.sessions,
  });

  bool get hasPeakHour => sessions.any((s) => s.peakHour);
  int get totalAvailableCourts => sessions.fold(0, (sum, s) => sum + s.sessionCount);
}
