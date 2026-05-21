class Expense {
  final int id;
  final String title;
  final double amount;
  final String? reason;
  final String? createdByName;
  final DateTime? createdAt;

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    this.reason,
    this.createdByName,
    this.createdAt,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: (json['id'] as num).toInt(),
      title: json['title'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      reason: json['reason'],
      createdByName: json['createdByName'],
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
    );
  }
}
