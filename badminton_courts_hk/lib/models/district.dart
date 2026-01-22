class District {
  final int id;
  final String code;
  final String name;
  final String enName;
  final String tcName;
  final String? groupCode;

  District({
    required this.id,
    required this.code,
    required this.name,
    required this.enName,
    required this.tcName,
    this.groupCode,
  });

  factory District.fromJson(Map<String, dynamic> json, {String? groupCode}) {
    return District(
      id: json['id'] as int,
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      enName: json['enName']?.toString() ?? '',
      tcName: json['tcName']?.toString() ?? '',
      groupCode: groupCode,
    );
  }
}

class Region {
  final int id;
  final String code;
  final String name;
  final List<District> districts;

  Region({
    required this.id,
    required this.code,
    required this.name,
    required this.districts,
  });

  factory Region.fromJson(Map<String, dynamic> json) {
    final districts = (json['children'] as List? ?? [])
        .map((d) => District.fromJson(d, groupCode: json['code']))
        .toList();
    return Region(
      id: json['id'] as int,
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      districts: districts,
    );
  }
}
