import 'package:dio/dio.dart';

Future<Response<ResponseBody?>> sendDataResponseStream({
  required String url,
  Dio? dio,
  Object? data,
  Map<String, dynamic>? queryParameters,
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
  client.options.responseType = ResponseType.stream;
  return client.request<ResponseBody>(
    url,
    options: options,
    queryParameters: queryParameters,
    data: data,
    cancelToken: cancelToken,
  );
}
