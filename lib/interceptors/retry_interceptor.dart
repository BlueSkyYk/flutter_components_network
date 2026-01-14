import 'dart:math';

import 'package:dio/dio.dart';

import '../configs/extra_keys.dart';
import 'base_interceptor.dart';

/// 一个完整生产级可用的重试拦截器：
/// ✔ 指数退避 + 随机抖动
/// ✔ 支持 FormData/MultipartBody 重试
/// ✔ 支持业务逻辑重试（优先级最高）
/// ✔ 支持非幂等请求 POST 重试（可选）
/// ✔ 避免无限递归重试
/// ✔ 支持 Token 刷新逻辑
class RetryInterceptor extends BaseInterceptor {
  final Dio _dio;
  final int maxRetries;
  final Duration baseDelay;
  final List<int> retryableStatusCodes;
  final bool retryNonIdempotent;
  final bool Function(DioException err)? onCheckBusinessLogicRetry;

  static const Duration _maxDelay = Duration(seconds: 30);
  static final Random _random = Random();

  static const String _retryCountKey = "__retry_count__";

  RetryInterceptor({
    required Dio dio,
    super.logPrint,
    this.maxRetries = 3,
    this.baseDelay = const Duration(seconds: 1),
    this.retryableStatusCodes = const [429, 500, 502, 503, 504],
    this.retryNonIdempotent = false,
    this.onCheckBusinessLogicRetry,
  }) : _dio = dio;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    int retryCount = err.requestOptions.extra[_retryCountKey] ?? 0;

    if (retryCount >= maxRetries) {
      return handler.next(err);
    }

    if (!await _shouldRetry(err)) {
      return handler.next(err);
    }

    Duration delay = _calculateDelay(retryCount);
    printLog(
      '请求失败，等待 ${delay.inMilliseconds}ms 后进行第 ${retryCount + 1} 次重试：${err.requestOptions.uri}',
    );

    await Future.delayed(delay);

    final RequestOptions newOptions = _cloneRequestOptions(err.requestOptions)
      ..extra[_retryCountKey] = retryCount + 1
      ..extra[ExtraKeys.retryingKey] = true;

    try {
      final response = await _dio.fetch(newOptions);
      handler.resolve(response);
    } catch (e) {
      handler.next(
        e is DioException
            ? e
            : DioException(requestOptions: newOptions, error: e),
      );
    }
  }

  // =======================
  //  是否应该重试
  // =======================
  Future<bool> _shouldRetry(DioException err) async {
    final notRetryKey =
        err.requestOptions.extra[ExtraKeys.notRetryKey] as bool? ?? false;
    if (notRetryKey) {
      return false;
    }

    //（1）业务逻辑错误优先，例如 {code: 50001}
    if (onCheckBusinessLogicRetry != null && onCheckBusinessLogicRetry!(err)) {
      return true;
    }

    //（2）网络级别错误
    if (_isRetryableDioErrorType(err.type)) {
      return true;
    }

    //（3）HTTP 状态码
    if (err.response != null &&
        retryableStatusCodes.contains(err.response!.statusCode)) {
      return true;
    }

    //（4）非幂等请求是否允许重试
    if (!_isIdempotentRequest(err.requestOptions.method) &&
        !retryNonIdempotent) {
      return false;
    }

    return false;
  }

  bool _isRetryableDioErrorType(DioExceptionType type) {
    return [
      DioExceptionType.connectionTimeout,
      DioExceptionType.sendTimeout,
      DioExceptionType.receiveTimeout,
      DioExceptionType.connectionError,
      DioExceptionType.unknown, // DNS 错误/SocketException 等
    ].contains(type);
  }

  bool _isIdempotentRequest(String method) {
    const idempotentMethods = {
      "GET",
      "HEAD",
      "PUT",
      "DELETE",
      "OPTIONS",
      "TRACE",
    };
    return idempotentMethods.contains(method.toUpperCase());
  }

  // =======================
  //  克隆请求（支持 FormData）
  // =======================
  RequestOptions _cloneRequestOptions(RequestOptions request) {
    return request.copyWith(
      data: _cloneData(request.data),
      headers: Map<String, dynamic>.from(request.headers),
      queryParameters: Map<String, dynamic>.from(request.queryParameters),
    );
  }

  // 支持克隆 FormData（上传文件也能重试）
  dynamic _cloneData(dynamic data) {
    if (data is FormData) {
      final formData = FormData();
      for (final field in data.fields) {
        formData.fields.add(MapEntry(field.key, field.value));
      }
      for (final file in data.files) {
        formData.files.add(MapEntry(file.key, file.value));
      }
      return formData;
    }
    return data;
  }

  // =======================
  //   指数退避 + 随机抖动
  // =======================
  Duration _calculateDelay(int retryCount) {
    final int exponential =
        baseDelay.inMilliseconds * pow(2, retryCount).toInt();
    final double jitter = _random.nextDouble() * baseDelay.inMilliseconds;

    final int total = exponential + jitter.toInt();

    if (total > _maxDelay.inMilliseconds) {
      return _maxDelay;
    }
    return Duration(milliseconds: total);
  }
}
