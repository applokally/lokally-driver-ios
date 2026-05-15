import 'package:ride_sharing_user_app/data/api_client.dart';
import 'package:ride_sharing_user_app/localization/language_model.dart';
import 'package:ride_sharing_user_app/util/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart' as intl;

class LocalizationController extends GetxController implements GetxService {
  final SharedPreferences sharedPreferences;

  LocalizationController({required this.sharedPreferences}) {
    loadCurrentLanguage();
  }

  Locale _locale = Locale(
    AppConstants.languages[0].languageCode,
    AppConstants.languages[0].countryCode,
  );

  bool _isLtr = true;
  int _selectIndex = 0;
  List<LanguageModel> _languages = [];
  bool isLoading = false;

  Locale get locale => _locale;
  bool get isLtr => _isLtr;
  int get selectIndex => _selectIndex;
  List<LanguageModel> get languages => _languages;

  Locale _safeLocale(Locale locale) {
    final bool languageExists = AppConstants.languages.any(
      (language) => language.languageCode == locale.languageCode,
    );

    if (languageExists) {
      return locale;
    }

    return Locale(
      AppConstants.languages[0].languageCode,
      AppConstants.languages[0].countryCode,
    );
  }

  void _syncSelectIndexWithLocale() {
    final int index = AppConstants.languages.indexWhere(
      (language) => language.languageCode == _locale.languageCode,
    );

    _selectIndex = index >= 0 ? index : 0;
  }

  void _updateApiHeader() {
    if (Get.isRegistered<ApiClient>()) {
      Get.find<ApiClient>().updateHeader(
        sharedPreferences.getString(AppConstants.token) ?? '',
        _locale.languageCode,
        'latitude',
        'longitude',
        sharedPreferences.getString(AppConstants.zoneId) ?? '',
      );
    }
  }

  void setLanguage(Locale locale) {
    final Locale safeLocale = _safeLocale(locale);

    _locale = safeLocale;
    _isLtr = !intl.Bidi.isRtlLanguage(_locale.languageCode);

    _syncSelectIndexWithLocale();
    saveLanguage(_locale);
    Get.updateLocale(_locale);
    _updateApiHeader();

    isLoading = true;
    update();

    backendLanguageUpdate();
  }

  void loadCurrentLanguage() async {
    if (sharedPreferences.containsKey(AppConstants.languageCode)) {
      final String languageCode =
          sharedPreferences.getString(AppConstants.languageCode) ??
              AppConstants.languages[0].languageCode;

      final String countryCode =
          sharedPreferences.getString(AppConstants.countryCode) ??
              AppConstants.languages[0].countryCode;

      _locale = _safeLocale(Locale(languageCode, countryCode));
    } else {
      _locale = Locale(
        AppConstants.languages[0].languageCode,
        AppConstants.languages[0].countryCode,
      );

      saveLanguage(_locale);
    }

    _isLtr = !intl.Bidi.isRtlLanguage(_locale.languageCode);
    _syncSelectIndexWithLocale();
    Get.updateLocale(_locale);
    _updateApiHeader();

    update();
  }

  void saveLanguage(Locale locale) async {
    sharedPreferences.setString(AppConstants.languageCode, locale.languageCode);
    sharedPreferences.setString(
      AppConstants.countryCode,
      locale.countryCode ?? AppConstants.languages[0].countryCode,
    );
  }

  void setSelectIndex(int index) {
    if (index < 0 || index >= AppConstants.languages.length) {
      return;
    }

    _selectIndex = index;

    final LanguageModel selectedLanguage = AppConstants.languages[index];

    setLanguage(
      Locale(
        selectedLanguage.languageCode,
        selectedLanguage.countryCode,
      ),
    );
  }

  void searchLanguage(String query, BuildContext context) {
    if (query.isEmpty) {
      _languages.clear();
      _languages = AppConstants.languages;
      update();
    } else {
      _selectIndex = -1;
      _languages = [];

      for (LanguageModel language in AppConstants.languages) {
        if (language.languageName.toLowerCase().contains(query.toLowerCase())) {
          _languages.add(language);
        }
      }

      update();
    }
  }

  void initializeAllLanguages(BuildContext context) {
    if (_languages.isEmpty) {
      _languages.clear();
      _languages = AppConstants.languages;
    }
  }

  void setInitialIndex() {
    _syncSelectIndexWithLocale();
    update();
  }

  void backendLanguageUpdate() {
    if (!Get.isRegistered<ApiClient>()) {
      isLoading = false;
      update();
      return;
    }

    Get.find<ApiClient>().postData(AppConstants.changeLanguage, {}).then(
      (_) {
        isLoading = false;
        update();
      },
    ).catchError(
      (_) {
        isLoading = false;
        update();
      },
    );
  }

  bool haveLocalLanguageCode() {
    if (sharedPreferences.containsKey(AppConstants.languageCode)) {
      return true;
    } else {
      return false;
    }
  }
}
