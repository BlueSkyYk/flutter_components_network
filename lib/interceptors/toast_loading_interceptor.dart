import 'package:dio/dio.dart';

import '../configs/extra_keys.dart';
import '../exception/http_business_exception.dart';
import 'base_interceptor.dart';

class ToastLoadingInterceptor extends BaseInterceptor {
  bool? _enableErrorToast;
  bool? _enableLoading;
  void Function(String? message)? _showLoadingCallback;
  void Function()? _hideLoadingCallback;
  void Function(String message)? _showToastCallback;
  HttpBusinessException? Function(Response? response, DioException? err)?
  _onCheckError;

  ToastLoadingInterceptor({
    super.logPrint,
    bool enableErrorToast = false,
    bool enableLoading = false,
    void Function(String? message)? showLoadingCallback,
    void Function()? hideLoadingCallback,
    void Function(String message)? showToastCallback,
    HttpBusinessException? Function(Response? response, DioException? err)?
    onCheckError,
  }) {
    _enableErrorToast = enableErrorToast;
    _enableLoading = enableLoading;
    _showLoadingCallback = showLoadingCallback;
    _hideLoadingCallback = hideLoadingCallback;
    _showToastCallback = showToastCallback;
    _onCheckError = onCheckError;
  }

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // ⭐ 重试期间不显示Loading
    if (_isShowLoading(options) && !_isRetrying(options)) {
      final loadingMessage =
          (options.extra[ExtraKeys.loadingMessageKey] as String?)?.trim();
      _showLoadingCallback?.call(loadingMessage);
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    try {
      // printLog(
      //   "isShowErrorToast: ${_isShowErrorToast(response.requestOptions)} - isRetrying: ${_isRetrying(response.requestOptions)}",
      // );
      // ⭐ 重试期间不弹Toast
      if (_isShowErrorToast(response.requestOptions) &&
          !_isRetrying(response.requestOptions)) {
        final error = _onCheckError?.call(response, null);
        if (error != null) {
          _showToastCallback?.call(error.message);
        }
      }
    } catch (_) {}

    try {
      handler.next(response);
    } finally {
      // ⭐ Loading 只在非重试状态下关闭（重试结束后会自动关闭）
      if (_isShowLoading(response.requestOptions) &&
          !_isRetrying(response.requestOptions)) {
        _hideLoadingCallback?.call();
      }
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // 处理 DioError
    if (_isShowErrorToast(err.requestOptions) &&
        !_isRetrying(err.requestOptions)) {
      final error = _onCheckError?.call(err.response, null);
      if (error != null) {
        _showToastCallback?.call(error.message);
      }
    }
    try {
      handler.next(err);
    } finally {
      // ⭐ Loading 只在非重试状态下关闭（重试结束后会自动关闭）
      if (_isShowLoading(err.requestOptions) &&
          !_isRetrying(err.requestOptions)) {
        _hideLoadingCallback?.call();
      }
    }
  }

  // 是否由重试触发
  bool _isRetrying(RequestOptions options) {
    return options.extra[ExtraKeys.retryingKey] == true;
  }

  bool _isShowErrorToast(RequestOptions options) {
    final showErrorToast = options.extra[ExtraKeys.showErrorToastKey];
    return showErrorToast == true && _enableErrorToast == true;
  }

  bool _isShowLoading(RequestOptions options) {
    final showLoading = options.extra[ExtraKeys.showLoadingKey];
    return showLoading == true && _enableLoading == true;
  }
}
