import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:get/get_connect/http/src/request/request.dart';
import 'package:ride_sharing_user_app/data/error_response.dart';

import 'package:ride_sharing_user_app/util/app_constants.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:path/path.dart';

class ApiClient extends GetxService {
  final String appBaseUrl;
  final SharedPreferences sharedPreferences;
  static final String noInternetMessage = 'connection_to_api_server_failed'.tr;
  final int timeoutInSeconds = 30;

  late String token;
  late Map<String, String> _mainHeaders;

  ApiClient({
    required this.appBaseUrl,
    required this.sharedPreferences,
  }) {
    token = sharedPreferences.getString(AppConstants.token) ?? '';

    updateHeader(
      token,
      sharedPreferences.getString(AppConstants.languageCode) ?? '',
      '0',
      '0',
      '',
    );
  }

  void updateHeader(
    String token,
    String? languageCode,
    String? latitude,
    String? longitude,
    String zoneId,
  ) {
    Map<String, String> header = {
      'Content-Type': 'application/json; charset=UTF-8',
      'Accept': 'application/json',
      AppConstants.localization:
          languageCode ?? AppConstants.languages[0].languageCode,
      'zoneId': zoneId,
      'Authorization': 'Bearer $token',
    };

    _mainHeaders = header;
  }

  Uri _buildUri(
    String uri, {
    Map<String, dynamic>? query,
  }) {
    final Uri requestUri = Uri.parse(appBaseUrl + uri);

    if (query == null || query.isEmpty) {
      return requestUri;
    }

    final Map<String, String> queryParameters = {
      ...requestUri.queryParameters,
      ...query.map(
        (String key, dynamic value) => MapEntry(key, value.toString()),
      ),
    };

    return requestUri.replace(queryParameters: queryParameters);
  }

  void _logRequestException({
    required String method,
    required Uri requestUri,
    required Object error,
    required StackTrace stackTrace,
  }) {
    if (!kDebugMode) {
      return;
    }

    debugPrint('========== LokallyApiClient ==========');
    debugPrint('====> API REQUEST EXCEPTION');
    debugPrint('Method: $method');
    debugPrint('URL: $requestUri');
    debugPrint('Exception type: ${error.runtimeType}');
    debugPrint('Exception: $error');
    debugPrint('======================================');
  }

  Response _requestExceptionResponse({
    required String method,
    required Uri requestUri,
    required Object error,
    required StackTrace stackTrace,
  }) {
    _logRequestException(
      method: method,
      requestUri: requestUri,
      error: error,
      stackTrace: stackTrace,
    );

    return Response(
      statusCode: 1,
      statusText: noInternetMessage,
    );
  }

  void _logRequest({
    required String method,
    required Uri requestUri,
  }) {
    if (!kDebugMode) {
      return;
    }

    debugPrint('LokallyApiClient | API Call: $method $requestUri');
  }

  Future<Response> getData(
    String uri, {
    Map<String, dynamic>? query,
    Map<String, String>? headers,
  }) async {
    final Uri requestUri = _buildUri(uri, query: query);

    try {
      _logRequest(
        method: 'GET',
        requestUri: requestUri,
      );

      http.Response response = await http
          .get(
            requestUri,
            headers: headers ?? _mainHeaders,
          )
          .timeout(Duration(seconds: timeoutInSeconds));

      return handleResponse(response, uri);
    } catch (error, stackTrace) {
      return _requestExceptionResponse(
        method: 'GET',
        requestUri: requestUri,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<Response> postData(
    String uri,
    dynamic body, {
    Map<String, String>? headers,
  }) async {
    final Uri requestUri = _buildUri(uri);

    try {
      _logRequest(
        method: 'POST',
        requestUri: requestUri,
      );

      http.Response response = await http
          .post(
            requestUri,
            body: jsonEncode(body),
            headers: headers ?? _mainHeaders,
          )
          .timeout(Duration(seconds: timeoutInSeconds));

      return handleResponse(response, uri);
    } catch (error, stackTrace) {
      return _requestExceptionResponse(
        method: 'POST',
        requestUri: requestUri,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<Response> postMultipartData(
    String uri,
    Map<String, String> body,
    List<MultipartBody> multipartBody,
    MultipartBody? logo,
    List<MultipartDocument> otherFile, {
    Map<String, String>? headers,
  }) async {
    final Uri requestUri = _buildUri(uri);

    try {
      _logRequest(
        method: 'POST MULTIPART',
        requestUri: requestUri,
      );

      http.MultipartRequest request = http.MultipartRequest(
        'POST',
        requestUri,
      );
      request.headers.addAll(headers ?? _mainHeaders);

      if (logo != null && logo.file != null) {
        Uint8List list = await logo.file!.readAsBytes();
        request.files.add(
          http.MultipartFile(
            logo.key,
            logo.file!.readAsBytes().asStream(),
            list.length,
            filename: '${DateTime.now()}.png',
          ),
        );
      }

      for (MultipartBody multipart in multipartBody) {
        if (multipart.file != null) {
          Uint8List list = await multipart.file!.readAsBytes();
          request.files.add(
            http.MultipartFile(
              multipart.key,
              multipart.file!.readAsBytes().asStream(),
              list.length,
              filename: '${DateTime.now()}.png',
            ),
          );
        }
      }

      if (otherFile.isNotEmpty) {
        for (MultipartDocument file in otherFile) {
          File selectedFile = File(file.file!.path!);
          Uint8List fileBytes = await selectedFile.readAsBytes();

          request.files.add(
            http.MultipartFile(
              'other_documents[]',
              selectedFile.readAsBytes().asStream(),
              fileBytes.length,
              filename: basename(selectedFile.path),
            ),
          );
        }
      }

      request.fields.addAll(body);

      http.Response response =
          await http.Response.fromStream(await request.send());

      return handleResponse(response, uri);
    } catch (error, stackTrace) {
      return _requestExceptionResponse(
        method: 'POST MULTIPART',
        requestUri: requestUri,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<Response> postMultipartDataConversation(
    String? uri,
    Map<String, String> body,
    List<MultipartBody>? multipartBody, {
    Map<String, String>? headers,
    PlatformFile? otherFile,
  }) async {
    final Uri requestUri = _buildUri(uri ?? '');

    try {
      _logRequest(
        method: 'POST MULTIPART CONVERSATION',
        requestUri: requestUri,
      );

      http.MultipartRequest request = http.MultipartRequest(
        'POST',
        requestUri,
      );
      request.headers.addAll(headers ?? _mainHeaders);

      if (otherFile != null) {
        request.files.add(
          http.MultipartFile(
            'files[${multipartBody!.length}]',
            otherFile.readStream!,
            otherFile.size,
            filename: basename(otherFile.name),
          ),
        );
      }

      if (multipartBody != null) {
        for (MultipartBody multipart in multipartBody) {
          Uint8List list = await multipart.file!.readAsBytes();
          request.files.add(
            http.MultipartFile(
              multipart.key,
              multipart.file!.readAsBytes().asStream(),
              list.length,
              filename: '${DateTime.now()}.png',
            ),
          );
        }
      }

      request.fields.addAll(body);

      http.Response response =
          await http.Response.fromStream(await request.send());

      return handleResponse(response, uri ?? '');
    } catch (error, stackTrace) {
      return _requestExceptionResponse(
        method: 'POST MULTIPART CONVERSATION',
        requestUri: requestUri,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<Response> postMultipartMergeWithImageAndDocument(
    String? uri,
    Map<String, String> body,
    List<MultipartBody>? multipartBody, {
    Map<String, String>? headers,
    List<MultipartDocument>? documents,
  }) async {
    final Uri requestUri = _buildUri(uri ?? '');

    try {
      _logRequest(
        method: 'POST MULTIPART FILES',
        requestUri: requestUri,
      );

      int index = 0;

      http.MultipartRequest request = http.MultipartRequest(
        'POST',
        requestUri,
      );
      request.headers.addAll(headers ?? _mainHeaders);

      if (multipartBody != null) {
        for (MultipartBody multipart in multipartBody) {
          Uint8List list = await multipart.file!.readAsBytes();
          request.files.add(
            http.MultipartFile(
              'files[$index]',
              multipart.file!.readAsBytes().asStream(),
              list.length,
              filename: '${DateTime.now()}.png',
            ),
          );
          index++;
        }
      }

      if (documents != null) {
        for (MultipartDocument document in documents) {
          request.files.add(
            http.MultipartFile(
              'files[$index]',
              document.file!.readStream!,
              document.file!.size,
              filename: basename(document.file!.name),
            ),
          );
          index++;
        }
      }

      request.fields.addAll(body);

      http.Response response =
          await http.Response.fromStream(await request.send());

      return handleResponse(response, uri ?? '');
    } catch (error, stackTrace) {
      return _requestExceptionResponse(
        method: 'POST MULTIPART FILES',
        requestUri: requestUri,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<Response> putData(
    String uri,
    dynamic body, {
    Map<String, String>? headers,
  }) async {
    final Uri requestUri = _buildUri(uri);

    try {
      _logRequest(
        method: 'PUT',
        requestUri: requestUri,
      );

      http.Response response = await http
          .put(
            requestUri,
            body: jsonEncode(body),
            headers: headers ?? _mainHeaders,
          )
          .timeout(Duration(seconds: timeoutInSeconds));

      return handleResponse(response, uri);
    } catch (error, stackTrace) {
      return _requestExceptionResponse(
        method: 'PUT',
        requestUri: requestUri,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<Response> deleteData(
    String uri, {
    Map<String, String>? headers,
  }) async {
    final Uri requestUri = _buildUri(uri);

    try {
      _logRequest(
        method: 'DELETE',
        requestUri: requestUri,
      );

      http.Response response = await http
          .delete(
            requestUri,
            headers: headers ?? _mainHeaders,
          )
          .timeout(Duration(seconds: timeoutInSeconds));

      return handleResponse(response, uri);
    } catch (error, stackTrace) {
      return _requestExceptionResponse(
        method: 'DELETE',
        requestUri: requestUri,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Response handleResponse(http.Response response, String uri) {
    dynamic body;

    try {
      body = jsonDecode(response.body);
      // ignore: empty_catches
    } catch (error) {}

    Response localResponse = Response(
      body: body ?? response.body,
      bodyString: response.body.toString(),
      request: Request(
        headers: response.request!.headers,
        method: response.request!.method,
        url: response.request!.url,
      ),
      headers: response.headers,
      statusCode: response.statusCode,
      statusText: response.reasonPhrase,
    );

    final bool isSuccess = localResponse.statusCode != null &&
        localResponse.statusCode! >= 200 &&
        localResponse.statusCode! < 300;

    if (!isSuccess &&
        localResponse.body != null &&
        localResponse.body is! String) {
      if (localResponse.body.toString().startsWith('{errors: [{code:')) {
        ErrorResponse errorResponse = ErrorResponse.fromJson(
          localResponse.body,
        );

        localResponse = Response(
          statusCode: localResponse.statusCode,
          body: localResponse.body,
          statusText: errorResponse.errors![0].message,
        );
      } else if (localResponse.body.toString().startsWith('{message')) {
        localResponse = Response(
          statusCode: localResponse.statusCode,
          body: localResponse.body,
          statusText: localResponse.body['message'],
        );
      }
    } else if (!isSuccess && localResponse.body == null) {
      localResponse = Response(
        statusCode: 0,
        statusText: noInternetMessage,
      );
    }

    if (kDebugMode) {
      debugPrint(
        'LokallyApiClient | API Response: '
        '[${localResponse.statusCode}] $uri',
      );
    }

    return localResponse;
  }
}

class MultipartBody {
  String key;
  XFile? file;

  MultipartBody(this.key, this.file);
}

class MultipartDocument {
  String key;
  PlatformFile? file;

  MultipartDocument(this.key, this.file);
}
