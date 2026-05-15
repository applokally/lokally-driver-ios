import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ride_sharing_user_app/data/api_client.dart';
import 'package:ride_sharing_user_app/features/auth/domain/repositories/auth_repository_interface.dart';
import 'package:ride_sharing_user_app/util/app_constants.dart';
import 'package:ride_sharing_user_app/features/auth/domain/models/signup_body.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthRepository implements AuthRepositoryInterface {
  final ApiClient apiClient;
  final SharedPreferences sharedPreferences;
  AuthRepository({required this.apiClient, required this.sharedPreferences});

  @override
  Future<Response?> login({required String phone, required String password}) async {
    return await apiClient.postData(AppConstants.loginUri,
        {"phone_or_email": phone, "password": password});
  }

  @override
  Future<Response?> logOut() async {
    return await apiClient.postData(AppConstants.logout, {});
  }

  @override
  Future<Response> registration({required SignUpBody signUpBody, XFile? profileImage, List<MultipartBody>? identityImage, List<MultipartDocument>? documents}) async {
    return await apiClient.postMultipartData(AppConstants.registration,
      signUpBody.toJson(),
      identityImage!,
      MultipartBody('profile_image', profileImage), documents ?? []);
  }

  @override
  Future<Response> registerWithOtp({
    required SignUpBody signUpBody, XFile? profileImage, List<MultipartBody>? identityImage,
    List<MultipartDocument>? documents, required bool updateFromRegistration
  }) async {
    return await apiClient.postMultipartData(
      updateFromRegistration ?
      AppConstants.otpLoginAfterUpdateData :
      AppConstants.registrationFromOtp,
      signUpBody.toJson(),
      identityImage!,
      MultipartBody('profile_image', profileImage), documents ?? []);
  }


  @override
  Future<Response?> sendOtp({required String phone}) async {
    return await apiClient.postData(AppConstants.sendOtp,
        {"phone_or_email": phone});
  }

  @override
  Future<Response?> verifyOtp({required String phone, required String otp}) async {
    return await apiClient.postData(AppConstants.otpVerification,
        {"phone_or_email": phone,
          "otp": otp
        });
  }

  @override
  Future<Response?> verifyFirebaseOtp({required String phone, required String otp, required String session}) async {
    return await apiClient.postData(AppConstants.otpFirebaseVerification,
        {"phone_or_email": phone,
          "code": otp,
          "session_info": session
        });
  }

  @override
  Future<Response?> resetPassword(String phoneOrEmail, String password) async {
    return await apiClient.postData(AppConstants.resetPassword,
      { "phone_or_email": phoneOrEmail,
        "password": password,},
    );
  }

  @override
  Future<Response?> changePassword(String oldPassword, String password) async {
    return await apiClient.postData(AppConstants.changePassword,
      { "password": oldPassword,
        "new_password": password,
      },
    );
  }



  String? deviceToken;
  StreamSubscription<String>? _tokenRefreshSubscription;

  @override
  Future<Response?> updateToken() async {
    await _prepareFirebaseMessaging();

    deviceToken = await _resolveDeviceToken();
    await saveDeviceToken();

    if (!GetPlatform.isWeb) {
      await FirebaseMessaging.instance.subscribeToTopic(AppConstants.topic);
    }

    _listenTokenRefresh();

    return await apiClient.postData(
      AppConstants.fcmTokenUpdate,
      {
        "_method": "put",
        "fcm_token": _isValidDeviceToken(deviceToken) ? deviceToken : '',
      },
    );
  }

  Future<void> _prepareFirebaseMessaging() async {
    if (GetPlatform.isWeb) {
      return;
    }

    await FirebaseMessaging.instance.setAutoInitEnabled(true);
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
  }

  Future<String?> _resolveDeviceToken() async {
    if (GetPlatform.isIOS) {
      await _waitForApnsToken();
    }

    for (int attempt = 0; attempt < 5; attempt++) {
      try {
        final String? token = await FirebaseMessaging.instance.getToken();

        if (_isValidDeviceToken(token)) {
          if (kDebugMode) {
            print('--------Driver FCM Token---------- $token');
          }

          return token;
        }
      } catch (e) {
        if (kDebugMode) {
          print('Driver FCM token error: $e');
        }
      }

      await Future<void>.delayed(const Duration(seconds: 2));
    }

    return null;
  }

  Future<void> _waitForApnsToken() async {
    for (int attempt = 0; attempt < 8; attempt++) {
      try {
        final String? apnsToken = await FirebaseMessaging.instance.getAPNSToken();

        if (_isValidDeviceToken(apnsToken)) {
          return;
        }
      } catch (e) {
        if (kDebugMode) {
          print('Driver APNs token error: $e');
        }
      }

      await Future<void>.delayed(const Duration(seconds: 2));
    }
  }

  void _listenTokenRefresh() {
    _tokenRefreshSubscription ??= FirebaseMessaging.instance.onTokenRefresh.listen(
      (String refreshedToken) async {
        if (!_isValidDeviceToken(refreshedToken)) {
          return;
        }

        deviceToken = refreshedToken;
        await saveDeviceToken();

        await apiClient.postData(
          AppConstants.fcmTokenUpdate,
          {
            "_method": "put",
            "fcm_token": refreshedToken,
          },
        );
      },
    );
  }

  bool _isValidDeviceToken(String? token) {
    if (token == null) {
      return false;
    }

    final String value = token.trim();

    return value.isNotEmpty && value != '@' && value.toLowerCase() != 'null';
  }

  @override
  Future<Response?> forgetPassword(String? phone) async {
    return await apiClient.postData(AppConstants.configUri, {"phone_or_email": phone});
  }



  @override
  Future<Response?> verifyPhone(String phone, String otp) async {
    return await apiClient.postData(AppConstants.configUri, {"phone": phone, "otp": otp});
  }

  @override
  Future<bool?> saveUserToken(String token, String zoneId) async {
    apiClient.token = token;
    apiClient.updateHeader(token, sharedPreferences.getString(AppConstants.languageCode), "latitude", "longitude", zoneId);
    return await sharedPreferences.setString(AppConstants.token, token);

  }

  @override
  String getUserToken() {
    return sharedPreferences.getString(AppConstants.token) ?? "";
  }

  @override
  bool isLoggedIn() {
    return sharedPreferences.containsKey(AppConstants.token);
  }

  @override
  bool clearSharedData() {
    sharedPreferences.remove(AppConstants.token);
    return true;
  }

  @override
  Future<void> saveUserCredential(String code ,String number, String password) async {
    try {
      await sharedPreferences.setString(AppConstants.userPassword, password);
      await sharedPreferences.setString(AppConstants.userNumber, number);
      await sharedPreferences.setString(AppConstants.loginCountryCode, code);

    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> saveDeviceToken() async {
    try {
      await sharedPreferences.setString(AppConstants.deviceToken, deviceToken??'');
    } catch (e) {
      rethrow;
    }
  }

  @override
  String getDeviceToken() {
    return sharedPreferences.getString(AppConstants.deviceToken) ?? "";
  }
  
  @override
  String getUserNumber() {
   return sharedPreferences.getString(AppConstants.userNumber) ?? "";
  }

  @override
  String getUserCountryCode() {
   // return sharedPreferences.getString(AppConstants.USER_COUNTRY_CODE) ?? "";
    return "";
  }

  @override
  String getUserPassword() {
    return sharedPreferences.getString(AppConstants.userPassword) ?? "";
  }

  @override
  bool isNotificationActive() {
    //return sharedPreferences.getBool(AppConstants.NOTIFICATION) ?? true;
    return true;
  }

  @override
  toggleNotificationSound(bool isNotification){
    //sharedPreferences.setBool(AppConstants.NOTIFICATION, isNotification);
  }

  @override
  Future<bool> clearUserCredential() async {
    await sharedPreferences.remove(AppConstants.userPassword);
    return await sharedPreferences.remove(AppConstants.userNumber);
  }

  @override
  bool clearSharedAddress(){
    //sharedPreferences.remove(AppConstants.USER_ADDRESS);
    return true;
  }
  
  @override
  String getZonId() {
    return sharedPreferences.getString(AppConstants.zoneId) ?? "";

  }
  
  @override
  Future<void> updateZone(String zoneId) async {
    try {
      await sharedPreferences.setString(AppConstants.zoneId, zoneId);
      apiClient.updateHeader(sharedPreferences.getString(AppConstants.token) ?? '', sharedPreferences.getString(AppConstants.languageCode), 'latitude', 'longitude', zoneId);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future add(value) {
    // TODO: implement add
    throw UnimplementedError();
  }

  @override
  Future delete(int id) {
    // TODO: implement delete
    throw UnimplementedError();
  }

  @override
  Future get(String id) {
    // TODO: implement get
    throw UnimplementedError();
  }

  @override
  Future getList({int? offset = 1}) {
    // TODO: implement getList
    throw UnimplementedError();
  }

  @override
  Future update(Map<String, dynamic> body, int id) {
    // TODO: implement update
    throw UnimplementedError();
  }

  @override
  Future<Response?> permanentDelete() async{
    return await apiClient.postData(AppConstants.permanentDelete, {});
  }

  @override
  Future<void> saveRideCreatedTime(DateTime dateTime) async {
     await sharedPreferences.setString('DateTime', dateTime.toString());
  }

  @override
  Future<String> remainingTime() async{
    return  sharedPreferences.getString('DateTime') ?? '';
  }

  @override
  String getLoginCountryCode() {
    return sharedPreferences.getString(AppConstants.loginCountryCode) ?? "";
  }
  @override
  Future<Response?> isUserRegistered({required String phone}) async {
    return await apiClient.postData(AppConstants.checkRegisteredUserUri,
        {"phone_or_email": phone});
  }

}
