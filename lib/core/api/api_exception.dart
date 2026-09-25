class ApiException implements Exception {
  final String message;
  final int statusCode;
  final String? code;
  final dynamic errors;

  const ApiException({
    required this.message,
    this.statusCode = 400,
    this.code,
    this.errors,
  });

  @override
  String toString() => message;
}
