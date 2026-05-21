/// Payment status 3 trạng thái (GP1):
/// - UNPAID: Member chưa làm gì
/// - PENDING_VERIFICATION: Member đã báo CK, đang chờ Admin xác nhận
/// - CONFIRMED: Admin đã xác nhận
enum PaymentStatus { unpaid, pendingVerification, confirmed }

PaymentStatus _parseStatus(String? s, {required bool markedPaid, required bool confirmed}) {
  // Ưu tiên field status từ BE; fallback từ 2 boolean nếu BE cũ.
  switch (s) {
    case 'CONFIRMED':
      return PaymentStatus.confirmed;
    case 'PENDING_VERIFICATION':
      return PaymentStatus.pendingVerification;
    case 'UNPAID':
      return PaymentStatus.unpaid;
  }
  if (confirmed) return PaymentStatus.confirmed;
  if (markedPaid) return PaymentStatus.pendingVerification;
  return PaymentStatus.unpaid;
}

class Payment {
  final int id;
  final int? userId;
  final String? fullName;
  final String? collectionTitle;
  final double? amount;
  final DateTime? deadline;

  // GP1: Member đã báo CK chưa
  final bool markedPaid;
  final DateTime? markedPaidAt;

  // Admin đã xác nhận
  final bool confirmedByAdmin;
  final DateTime? paidAt;
  final String? confirmedByName;

  final PaymentStatus status;

  Payment({
    required this.id,
    this.userId,
    this.fullName,
    this.collectionTitle,
    this.amount,
    this.deadline,
    this.markedPaid = false,
    this.markedPaidAt,
    this.confirmedByAdmin = false,
    this.paidAt,
    this.confirmedByName,
    required this.status,
  });

  // Convenience getters
  bool get isConfirmed => status == PaymentStatus.confirmed;
  bool get isPending => status == PaymentStatus.pendingVerification;
  bool get isUnpaid => status == PaymentStatus.unpaid;

  factory Payment.fromJson(Map<String, dynamic> json) {
    final markedPaid = json['markedPaid'] ??
        json['isPaid'] ?? // BE cũ: isPaid nghĩa = confirmed; chấp nhận để parse được
        json['paid'] ??
        false;
    final confirmed = json['confirmedByAdmin'] ?? false;
    return Payment(
      id: (json['id'] as num).toInt(),
      userId: (json['userId'] as num?)?.toInt(),
      fullName: json['fullName'],
      collectionTitle: json['collectionTitle'],
      amount: (json['amount'] as num?)?.toDouble(),
      deadline: json['deadline'] != null ? DateTime.tryParse(json['deadline']) : null,
      markedPaid: markedPaid,
      markedPaidAt: json['markedPaidAt'] != null ? DateTime.tryParse(json['markedPaidAt']) : null,
      confirmedByAdmin: confirmed,
      paidAt: json['paidAt'] != null ? DateTime.tryParse(json['paidAt']) : null,
      confirmedByName: json['confirmedByName'],
      status: _parseStatus(json['status'], markedPaid: markedPaid, confirmed: confirmed),
    );
  }
}
