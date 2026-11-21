class Earning {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  EarningDetail? detail;

  Earning({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    this.detail,
  });

  Earning copyWith({
    String? id,
    String? title,
    double? amount,
    DateTime? date,
    EarningDetail? detail,
  }) {
    return Earning(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      detail: detail ?? this.detail,
    );
  }
}

class EarningDetail {
  final String id;
  final String description;
  final String referenceNumber;
  final String status;

  const EarningDetail({
    required this.id,
    required this.description,
    required this.referenceNumber,
    required this.status,
  });
}

class WalletUpdate {
  final String id;
  final String title;
  final double amount;
  final DateTime timestamp;

  const WalletUpdate({
    required this.id,
    required this.title,
    required this.amount,
    required this.timestamp,
  });

  Earning toEarning() {
    return Earning(
      id: id,
      title: title,
      amount: amount,
      date: timestamp,
    );
  }
}
