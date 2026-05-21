class FundCollection {
  final int id;
  final String title;
  final double amount;
  final DateTime? deadline;
  final String? createdByName;
  final int totalMembers;
  final int paidCount;
  final DateTime? createdAt;

  FundCollection({
    required this.id,
    required this.title,
    required this.amount,
    this.deadline,
    this.createdByName,
    this.totalMembers = 0,
    this.paidCount = 0,
    this.createdAt,
  });

  factory FundCollection.fromJson(Map<String, dynamic> json) {
    return FundCollection(
      id: (json['id'] as num).toInt(),
      title: json['title'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      deadline: json['deadline'] != null ? DateTime.tryParse(json['deadline']) : null,
      createdByName: json['createdByName'],
      totalMembers: (json['totalMembers'] as num?)?.toInt() ?? 0,
      paidCount: (json['paidCount'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
    );
  }
}
