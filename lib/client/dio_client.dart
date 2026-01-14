import 'package:dio/dio.dart';

import '../configs/extra_keys.dart';
import '../exception/http_business_exception.dart';
import '../interceptors/retry_interceptor.dart';
import '../interceptors/toast_loading_interceptor.dart';

class DioClient {
  late Dio _dio;

  Dio? get dio {
    try {
      return _dio;
    } catch (e) {
      return null;
    }
  }

  HttpBusinessException? Function(Response? response, DioException? err)?
  _onCheckError;

  DioClient({
    String baseUrl = '',
    BaseOptions? options,
    List<Interceptor>? beforeInterceptors,
    List<Interceptor>? afterInterceptors,
    bool enableRetry = true,
    int maxRetries = 3,
    Duration baseDelay = const Duration(seconds: 1),
    List<int> retryableStatusCodes = const [429, 500, 502, 503, 504],
    bool retryNonIdempotent = true,
    bool Function(DioException err)? onCheckBusinessLogicRetry,

    bool showLog = false,
    bool logRequest = true,
    bool logRequestHeader = true,
    bool logRequestBody = true,
    bool logResponseHeader = true,
    bool logResponseBody = true,
    bool logError = true,
    Function(Object? object)? logPrint,

    bool enableErrorToast = false,
    bool enableLoading = false,

    void Function(String? message)? showLoadingCallback,
    void Function()? hideLoadingCallback,
    void Function(String message)? showToastCallback,
    HttpBusinessException? Function(Response? response, DioException? err)?
    onCheckError,
  }) {
    final bsUrl = baseUrl.trim();
    _dio = Dio(
      options ??
          BaseOptions(
            connectTimeout: Duration(seconds: 15),
            receiveTimeout: Duration(seconds: 15),
            sendTimeout: Duration(seconds: 20),
            responseType: ResponseType.json,
            contentType: Headers.jsonContentType,
          ),
    );

    if (bsUrl.isNotEmpty) {
      _dio.options.baseUrl = bsUrl;
    }

    _onCheckError = onCheckError;

    _dio.interceptors.addAll(beforeInterceptors ?? []);

    final logPrinter = showLog ? (logPrint ?? _debugPrint) : null;

    // Log Interceptor（日志拦截器）
    if (showLog) {
      _dio.interceptors.add(
        LogInterceptor(
          request: logRequest,
          requestHeader: logRequestHeader,
          requestBody: logRequestBody,
          responseBody: logResponseBody,
          responseHeader: logResponseHeader,
          error: logError,
          logPrint: logPrinter ?? _debugPrint,
        ),
      );
    }

    _dio.interceptors.addAll([
      ToastLoadingInterceptor(
        logPrint: logPrinter,
        enableErrorToast: enableErrorToast,
        enableLoading: enableLoading,
        showLoadingCallback: showLoadingCallback,
        hideLoadingCallback: hideLoadingCallback,
        showToastCallback: showToastCallback,
        onCheckError: onCheckError,
      ),
    ]);
    _dio.interceptors.addAll(afterInterceptors ?? []);
    if (enableRetry) {
      _dio.interceptors.add(
        RetryInterceptor(
          dio: _dio,
          logPrint: logPrinter,
          maxRetries: maxRetries,
          baseDelay: baseDelay,
          retryableStatusCodes: retryableStatusCodes,
          retryNonIdempotent: retryNonIdempotent,
          onCheckBusinessLogicRetry: onCheckBusinessLogicRetry,
        ),
      );
    }
  }

  Future<Response<T>> get<T>({
    required String url,
    Map<String, String>? query,
    Object? data,
    Options? options,
    bool showLoading = true,
    bool showErrorToast = true,
    String? loadingMessage,
    bool notRetryKey = false,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) {
    return request(
      url: url,
      query: query,
      data: data,
      options: _checkOptions('GET', options),
      showLoading: showLoading,
      showErrorToast: showErrorToast,
      loadingMessage: loadingMessage,
      notRetryKey: notRetryKey,
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response<T>> post<T>({
    required String url,
    Map<String, String>? query,
    Object? data,
    Options? options,
    bool showLoading = true,
    bool showErrorToast = true,
    String? loadingMessage,
    bool notRetryKey = false,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return request(
      url: url,
      query: query,
      data: data,
      options: _checkOptions('POST', options),
      showLoading: showLoading,
      showErrorToast: showErrorToast,
      loadingMessage: loadingMessage,
      notRetryKey: notRetryKey,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response<T>> put<T>({
    required String url,
    Map<String, String>? query,
    Object? data,
    Options? options,
    bool showLoading = true,
    bool showErrorToast = true,
    String? loadingMessage,
    bool notRetryKey = false,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return request(
      url: url,
      query: query,
      data: data,
      options: _checkOptions('PUT', options),
      showLoading: showLoading,
      showErrorToast: showErrorToast,
      loadingMessage: loadingMessage,
      notRetryKey: notRetryKey,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response<T>> delete<T>({
    required String url,
    Map<String, String>? query,
    Object? data,
    Options? options,
    bool showLoading = true,
    bool showErrorToast = true,
    String? loadingMessage,
    bool notRetryKey = false,
    CancelToken? cancelToken,
  }) {
    return request(
      url: url,
      query: query,
      data: data,
      options: _checkOptions('DELETE', options),
      showLoading: showLoading,
      showErrorToast: showErrorToast,
      loadingMessage: loadingMessage,
      notRetryKey: notRetryKey,
      cancelToken: cancelToken,
    );
  }

  Future<Response<T>> head<T>({
    required String url,
    Map<String, String>? query,
    Object? data,
    Options? options,
    bool showLoading = true,
    bool showErrorToast = true,
    String? loadingMessage,
    bool notRetryKey = false,
    CancelToken? cancelToken,
  }) {
    return request(
      url: url,
      query: query,
      data: data,
      options: _checkOptions('HEAD', options),
      showLoading: showLoading,
      showErrorToast: showErrorToast,
      loadingMessage: loadingMessage,
      notRetryKey: notRetryKey,
      cancelToken: cancelToken,
    );
  }

  Future<Response<T>> patch<T>({
    required String url,
    Map<String, String>? query,
    Object? data,
    Options? options,
    bool showLoading = true,
    bool showErrorToast = true,
    String? loadingMessage,
    bool notRetryKey = false,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return request(
      url: url,
      query: query,
      data: data,
      options: _checkOptions('PATCH', options),
      showLoading: showLoading,
      showErrorToast: showErrorToast,
      loadingMessage: loadingMessage,
      notRetryKey: notRetryKey,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response<ResponseBody?>> sendResponseStream({
    required String url,
    Map<String, String>? query,
    Object? data,
    Options? options,
    bool showLoading = true,
    bool showErrorToast = true,
    String? loadingMessage,
    CancelToken? cancelToken,
  }) {
    options ??= Options(method: "GET");
    options.responseType = ResponseType.stream;
    return request(
      url: url,
      query: query,
      data: data,
      options: options,
      showLoading: showLoading,
      showErrorToast: showErrorToast,
      loadingMessage: loadingMessage,
      notRetryKey: true,
      cancelToken: cancelToken,
    );
  }

  Future<Response<T>> request<T>({
    required String url,
    Map<String, String>? query,
    Object? data,
    Options? options,
    bool showLoading = true,
    bool showErrorToast = true,
    String? loadingMessage,
    bool notRetryKey = false,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    options ??= Options();
    options.extra ??= {};
    options.extra![ExtraKeys.showLoadingKey] = showLoading;
    options.extra![ExtraKeys.showErrorToastKey] = showErrorToast;
    options.extra![ExtraKeys.loadingMessageKey] = loadingMessage;
    if (notRetryKey) {
      options.extra![ExtraKeys.notRetryKey] = true;
    }
    final response = await _dio.request<T>(
      url,
      data: data,
      queryParameters: query,
      cancelToken: cancelToken,
      options: options,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
    final error = _onCheckError?.call(response, null);
    if (error != null) {
      throw error;
    }
    return response;
  }

  static Options _checkOptions(String method, Options? options) {
    options ??= Options();
    options.method = method;
    return options;
  }
}

void _debugPrint(Object? object) {
  assert(() {
    print(object);
    return true;
  }());
}
