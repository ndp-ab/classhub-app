class Bank {
  final int id;
  final String bankBin;
  final String code;
  final String name;
  final String shortName;
  final String logo;
  final bool transferSupported;
  final bool lookupSupported;

  const Bank({
    required this.id,
    required this.bankBin,
    required this.code,
    required this.name,
    required this.shortName,
    required this.logo,
    required this.transferSupported,
    required this.lookupSupported,
  });

  String get displayName {
    if (shortName.trim().isNotEmpty) return shortName.trim();
    if (name.trim().isNotEmpty) return name.trim();
    return bankBin.trim();
  }

  factory Bank.fromJson(Map<String, dynamic> json) {
    return Bank(
      id: (json['id'] as num?)?.toInt() ?? 0,
      bankBin: json['bankBin']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      shortName: json['shortName']?.toString() ?? '',
      logo: json['logo']?.toString() ?? '',
      transferSupported: _parseBool(json['transferSupported']),
      lookupSupported: _parseBool(json['lookupSupported']),
    );
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    return value?.toString().toLowerCase() == 'true';
  }
}
