import 'package:dio/dio.dart';

abstract class BaseInterceptor extends Interceptor {
  BaseInterceptor({this.logPrint});

  /// Log printer; defaults print log to console.
  /// In flutter, you'd better use debugPrint.
  /// you can also write log in a file, for example:
  /// ```dart
  ///  final file=File("./log.txt");
  ///  final sink=file.openWrite();
  ///  dio.interceptors.add(LogInterceptor(logPrint: sink.writeln));
  /// ```
  Function(Object? object)? logPrint;

  void printLog(Object? object) {
    logPrint?.call(object);
  }
}
