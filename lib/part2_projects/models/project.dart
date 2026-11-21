class Project {
  final String id;
  final String title;
  final String company;
  final int payout;

  const Project({
    required this.id,
    required this.title,
    required this.company,
    required this.payout,
  });
}

class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  @override
  String toString() => 'ApiException: $message';
}
