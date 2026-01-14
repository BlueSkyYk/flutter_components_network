import 'package:dio/dio.dart';

Future<Response<ResponseBody?>> sendDataResponseStream({
  required String url,
  Dio? dio,
  Map<String, dynamic>? queryParameters,
  Object? data,
  Options? options,
  CancelToken? cancelToken,
}) async {
  final client =
      dio ??
      Dio(
        BaseOptions(
          connectTimeout: Duration(seconds: 10),
          sendTimeout: Duration(seconds: 10),
          receiveTimeout: Duration(seconds: 60),
          method: "GET",
        ),
      );
  options ??= Options();
  options.responseType = ResponseType.stream;
  return client.request<ResponseBody>(
    url,
    options: options,
    queryParameters: queryParameters,
    data: data,
    cancelToken: cancelToken,
  );
}
