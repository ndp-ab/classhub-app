class ClassroomBankAccount {
  final int id;
  final String bankBin;
  final String bankName;
  final String accountNo;
  final String accountName;
  final bool active;
  final String? note;
  final String? createdByName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ClassroomBankAccount({
    required this.id,
    required this.bankBin,
    required this.bankName,
    required this.accountNo,
    required this.accountName,
    required this.active,
    this.note,
    this.createdByName,
    this.createdAt,
    this.updatedAt,
  });

  factory ClassroomBankAccount.fromJson(Map<String, dynamic> json) {
    return ClassroomBankAccount(
      id: (json['id'] as num?)?.toInt() ?? 0,
      bankBin: json['bankBin']?.toString() ?? '',
      bankName: json['bankName']?.toString() ?? '',
      accountNo: json['accountNo']?.toString() ?? '',
      accountName: json['accountName']?.toString() ?? '',
      active: json['active'] == true,
      note: json['note']?.toString(),
      createdByName: json['createdByName']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }
}
