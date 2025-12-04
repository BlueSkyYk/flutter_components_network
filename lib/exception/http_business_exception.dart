class HttpBusinessException implements Exception {
  final int code;
  final String message;

  HttpBusinessException({required this.code, required this.message});

  @override
  String toString() => 'HttpBusinessException{code: $code, message: $message}';
}
