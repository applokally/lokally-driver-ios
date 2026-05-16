import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/common_widgets/button_widget.dart';
import 'package:ride_sharing_user_app/features/auth/controllers/auth_controller.dart';
import 'package:ride_sharing_user_app/features/auth/screens/additional_sign_up_screen_1.dart';
import 'package:ride_sharing_user_app/features/auth/widgets/signup_appbar_widget.dart';
import 'package:ride_sharing_user_app/helper/display_helper.dart';
import 'package:ride_sharing_user_app/helper/svg_image_helper.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:ride_sharing_user_app/util/images.dart';
import 'package:ride_sharing_user_app/util/styles.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  static const String _partnershipPerRide = 'per_ride';
  static const String _partnershipMonthly = 'monthly';
  static const String _billingZoneRulesUrl =
      'https://admlokally.online/api/driver/config/lokally-billing-zone-rules';

  final TextEditingController cityController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _cityFocusNode = FocusNode();
  final GlobalKey _citySelectorKey = GlobalKey();
  final GlobalKey _serviceSectionKey = GlobalKey();

  final GetConnect _getConnect =
      GetConnect(timeout: const Duration(seconds: 12));

  bool _isLoadingBillingRules = true;
  bool _hasBillingRulesError = false;
  bool _isRideShareSelected = false;
  bool _isParcelDeliverySelected = false;

  String? _selectedPartnershipModel;
  String _cityQuery = '';

  List<_LokallyBillingZoneRule> _billingZoneRules = [];
  _LokallyBillingZoneRule? _selectedBillingZoneRule;

  @override
  void initState() {
    super.initState();
    _loadBillingZoneRules();
  }

  @override
  void dispose() {
    cityController.dispose();
    _scrollController.dispose();
    _cityFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadBillingZoneRules() async {
    setState(() {
      _isLoadingBillingRules = true;
      _hasBillingRulesError = false;
    });

    try {
      final Response response = await _getConnect.get(_billingZoneRulesUrl);

      if (response.statusCode != 200) {
        throw Exception('Falha ao carregar regras de cidade/zona.');
      }

      final dynamic decodedBody = _decodeResponseBody(response);
      final List<dynamic> data = decodedBody is Map
          ? (decodedBody['data'] as List<dynamic>? ?? <dynamic>[])
          : <dynamic>[];

      final List<_LokallyBillingZoneRule> rules = data
          .whereType<Map>()
          .map((item) => _LokallyBillingZoneRule.fromJson(item))
          .toList();

      rules.sort((a, b) => a.zoneName.compareTo(b.zoneName));

      if (!mounted) return;

      setState(() {
        _billingZoneRules = rules;
        _isLoadingBillingRules = false;
        _hasBillingRulesError = false;
      });

      _syncSelectedCityWithInput();
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _billingZoneRules = [];
        _selectedBillingZoneRule = null;
        _isLoadingBillingRules = false;
        _hasBillingRulesError = true;
      });
    }
  }

  dynamic _decodeResponseBody(Response response) {
    if (response.body is Map || response.body is List) {
      return response.body;
    }

    if (response.body is String) {
      return jsonDecode(response.body);
    }

    final String bodyString = response.bodyString ?? '{}';
    return jsonDecode(bodyString);
  }

  String _normalizeSearch(String value) {
    return value
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[áàãâä]'), 'a')
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[íìîï]'), 'i')
        .replaceAll(RegExp(r'[óòõôö]'), 'o')
        .replaceAll(RegExp(r'[úùûü]'), 'u')
        .replaceAll('ç', 'c');
  }

  List<_LokallyBillingZoneRule> get _filteredCitySuggestions {
    final String query = _normalizeSearch(_cityQuery);

    if (query.isEmpty || _selectedBillingZoneRule != null) {
      return <_LokallyBillingZoneRule>[];
    }

    return _billingZoneRules
        .where((rule) => _normalizeSearch(rule.zoneName).contains(query))
        .take(6)
        .toList();
  }

  bool get _shouldShowUnavailableCityMessage {
    return !_isLoadingBillingRules &&
        !_hasBillingRulesError &&
        _cityQuery.trim().isNotEmpty &&
        _selectedBillingZoneRule == null &&
        _filteredCitySuggestions.isEmpty;
  }

  void _ensureCitySelectorVisible() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final BuildContext? selectorContext = _citySelectorKey.currentContext;

      if (selectorContext == null) {
        return;
      }

      Scrollable.ensureVisible(
        selectorContext,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        alignment: 0.08,
      );
    });
  }

  void _ensureServiceSectionVisible() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 180));

      if (!mounted) return;

      final BuildContext? serviceContext = _serviceSectionKey.currentContext;

      if (serviceContext == null) {
        return;
      }

      Scrollable.ensureVisible(
        serviceContext,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        alignment: 0.08,
      );
    });
  }

  void _syncSelectedCityWithInput() {
    final String normalizedInput = _normalizeSearch(cityController.text);
    _LokallyBillingZoneRule? exactMatch;

    for (final _LokallyBillingZoneRule rule in _billingZoneRules) {
      if (_normalizeSearch(rule.zoneName) == normalizedInput) {
        exactMatch = rule;
        break;
      }
    }

    setState(() {
      _selectedBillingZoneRule = exactMatch;
      _selectedPartnershipModel = null;
      _isRideShareSelected = false;
      _isParcelDeliverySelected = false;
    });

    if (exactMatch != null) {
      _cityFocusNode.unfocus();
      _ensureServiceSectionVisible();
    }
  }

  void _onCityChanged(String value) {
    _cityQuery = value;
    _syncSelectedCityWithInput();

    if (value.trim().isNotEmpty && _selectedBillingZoneRule == null) {
      _ensureCitySelectorVisible();
    }
  }

  void _onCitySubmitted(String value) {
    if (_selectedBillingZoneRule != null) {
      _cityFocusNode.unfocus();
      _ensureServiceSectionVisible();
      return;
    }

    final List<_LokallyBillingZoneRule> suggestions = _filteredCitySuggestions;

    if (suggestions.length == 1) {
      _selectCity(suggestions.first);
      return;
    }

    if (suggestions.isNotEmpty) {
      _ensureCitySelectorVisible();
      showCustomSnackBar('Toque na cidade atendida para selecionar.');
      return;
    }

    if (value.trim().isNotEmpty) {
      showCustomSnackBar('Selecione uma cidade atendida pela Lokally.');
    }
  }

  void _selectCity(_LokallyBillingZoneRule rule) {
    cityController.text = rule.zoneName;
    cityController.selection = TextSelection.collapsed(
      offset: cityController.text.length,
    );

    setState(() {
      _cityQuery = rule.zoneName;
      _selectedBillingZoneRule = rule;
      _selectedPartnershipModel = null;
      _isRideShareSelected = false;
      _isParcelDeliverySelected = false;
    });

    _cityFocusNode.unfocus();
    _ensureServiceSectionVisible();
  }

  void _toggleRideShare() {
    setState(() {
      _isRideShareSelected = !_isRideShareSelected;
      _selectedPartnershipModel = null;
    });
  }

  void _toggleParcelDelivery() {
    setState(() {
      _isParcelDeliverySelected = !_isParcelDeliverySelected;
      _selectedPartnershipModel = null;
    });
  }

  void _syncServiceSelectionWithController(AuthController authController) {
    if (authController.isRideShare != _isRideShareSelected) {
      authController.updateServiceType(true);
    }

    if (authController.isParcelShare != _isParcelDeliverySelected) {
      authController.updateServiceType(false);
    }
  }

  String _resolveLokallyServiceType() {
    if (_isRideShareSelected && _isParcelDeliverySelected) {
      return 'ride_and_parcel';
    }

    if (_isRideShareSelected) {
      return 'ride';
    }

    return 'parcel';
  }

  String _resolveLokallyBillingMode() {
    final bool onlyParcelDelivery =
        !_isRideShareSelected && _isParcelDeliverySelected;

    if (onlyParcelDelivery) {
      return _partnershipMonthly;
    }

    return _selectedPartnershipModel ?? '';
  }

  void _saveLokallyBillingDataToController(AuthController authController) {
    final _LokallyBillingZoneRule? selectedRule = _selectedBillingZoneRule;

    if (selectedRule == null) {
      return;
    }

    authController.setLokallyBillingRegistrationData(
      zoneId: selectedRule.zoneId,
      serviceType: _resolveLokallyServiceType(),
      billingMode: _resolveLokallyBillingMode(),
    );
  }

  void _validateAndContinue(AuthController authController) {
    if (_isLoadingBillingRules) {
      showCustomSnackBar('Aguarde carregar as cidades disponíveis.');
      return;
    }

    if (_selectedBillingZoneRule == null) {
      showCustomSnackBar('Selecione uma cidade atendida pela Lokally.');
      _cityFocusNode.requestFocus();
      _ensureCitySelectorVisible();
      return;
    }

    if (!_isRideShareSelected && !_isParcelDeliverySelected) {
      showCustomSnackBar(
        'Escolha transportar passageiros, entregas ou os dois.',
      );
      _cityFocusNode.unfocus();
      _ensureServiceSectionVisible();
      return;
    }

    final bool onlyParcelDelivery =
        !_isRideShareSelected && _isParcelDeliverySelected;

    if (!onlyParcelDelivery && _selectedPartnershipModel == null) {
      showCustomSnackBar('Selecione o modelo de parceria.');
      _cityFocusNode.unfocus();
      return;
    }

    _syncServiceSelectionWithController(authController);
    _saveLokallyBillingDataToController(authController);

    Get.to(() => const AdditionalSignUpScreen1());
  }

  @override
  Widget build(BuildContext context) {
    final bool keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    final double scrollBottomPadding =
        keyboardVisible ? 210 : Dimensions.paddingSizeLarge;

    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Theme.of(context).cardColor,
        body: GetBuilder<AuthController>(
          builder: (authController) {
            final bool hasSelectedCity = _selectedBillingZoneRule != null;

            final bool showPartnershipSection = hasSelectedCity &&
                (_isRideShareSelected || _isParcelDeliverySelected);

            final bool onlyParcelDelivery =
                !_isRideShareSelected && _isParcelDeliverySelected;

            return Column(
              children: [
                const SignUpAppbarWidget(
                  enableBackButton: true,
                  title: 'signup_as_a_driver',
                  progressText: '1_of_3',
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        Dimensions.paddingSizeLarge,
                        Dimensions.paddingSizeDefault,
                        Dimensions.paddingSizeLarge,
                        scrollBottomPadding,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Center(
                            child: Image.asset(
                              'assets/image/logo_with_name.png',
                              height: 86,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 30),
                          Center(
                            child: SizedBox(
                              height: 165,
                              child: FutureBuilder<String>(
                                future: loadSvgAndChangeColors(
                                  Images.signUpScreenLogoSvg,
                                  Theme.of(context).primaryColor,
                                ),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                          ConnectionState.done &&
                                      snapshot.hasData) {
                                    return SvgPicture.string(
                                      snapshot.data!,
                                      fit: BoxFit.contain,
                                    );
                                  }

                                  return SvgPicture.asset(
                                    Images.signUpScreenLogoSvg,
                                    fit: BoxFit.contain,
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          Text(
                            'Escolha sua cidade',
                            textAlign: TextAlign.center,
                            style: textBold.copyWith(
                              fontSize: 25,
                              height: 1.18,
                              color:
                                  Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              'Digite o nome da cidade onde você pretende rodar com a Lokally.',
                              textAlign: TextAlign.center,
                              style: textMedium.copyWith(
                                fontSize: 14.8,
                                height: 1.45,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color
                                    ?.withValues(alpha: 0.82),
                              ),
                              maxLines: 3,
                            ),
                          ),
                          const SizedBox(height: 22),
                          KeyedSubtree(
                            key: _citySelectorKey,
                            child: _LokallyCitySelector(
                              controller: cityController,
                              focusNode: _cityFocusNode,
                              isLoading: _isLoadingBillingRules,
                              hasError: _hasBillingRulesError,
                              selectedRule: _selectedBillingZoneRule,
                              suggestions: _filteredCitySuggestions,
                              showUnavailableMessage:
                                  _shouldShowUnavailableCityMessage,
                              onChanged: _onCityChanged,
                              onSubmitted: _onCitySubmitted,
                              onRetry: _loadBillingZoneRules,
                              onSelectCity: _selectCity,
                            ),
                          ),
                          if (hasSelectedCity) ...[
                            const SizedBox(height: 30),
                            KeyedSubtree(
                              key: _serviceSectionKey,
                              child: Column(
                                children: [
                                  Text(
                                    'choose_service'.tr,
                                    textAlign: TextAlign.center,
                                    style: textBold.copyWith(
                                      fontSize: 25,
                                      height: 1.18,
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.color,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: Text(
                                      'Escolha transportar passageiros, entregas ou os dois.',
                                      textAlign: TextAlign.center,
                                      style: textMedium.copyWith(
                                        fontSize: 14.8,
                                        height: 1.45,
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.color
                                            ?.withValues(alpha: 0.82),
                                      ),
                                      maxLines: 3,
                                    ),
                                  ),
                                  const SizedBox(height: 30),
                                  _LokallyServiceOptionCard(
                                    title: 'ride_share'.tr,
                                    subtitle: 'service_provide_text1'.tr,
                                    selected: _isRideShareSelected,
                                    onChanged: _toggleRideShare,
                                  ),
                                  const SizedBox(height: 16),
                                  _LokallyServiceOptionCard(
                                    title: 'parcel_delivery'.tr,
                                    subtitle: 'service_provide_text2'.tr,
                                    selected: _isParcelDeliverySelected,
                                    onChanged: _toggleParcelDelivery,
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (showPartnershipSection &&
                              _selectedBillingZoneRule != null) ...[
                            const SizedBox(height: 30),
                            _LokallyPartnershipSection(
                              rule: _selectedBillingZoneRule!,
                              onlyParcelDelivery: onlyParcelDelivery,
                              selectedPartnershipModel:
                                  _selectedPartnershipModel,
                              onSelectPerRide: () {
                                setState(() {
                                  _selectedPartnershipModel =
                                      _partnershipPerRide;
                                });
                              },
                              onSelectMonthly: () {
                                setState(() {
                                  _selectedPartnershipModel =
                                      _partnershipMonthly;
                                });
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: keyboardVisible
                      ? const SizedBox.shrink(
                          key: ValueKey<String>('keyboard-open-no-button'),
                        )
                      : Container(
                          key: const ValueKey<String>('keyboard-closed-button'),
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context)
                                    .hintColor
                                    .withValues(alpha: 0.15),
                                blurRadius: 10,
                                offset: const Offset(0, -4),
                              ),
                            ],
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(
                                Dimensions.paddingSizeLarge,
                              ),
                              topLeft: Radius.circular(
                                Dimensions.paddingSizeLarge,
                              ),
                            ),
                            color: Theme.of(context).cardColor,
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: Dimensions.paddingSizeSmall,
                            horizontal: Dimensions.paddingSizeExtraSmall,
                          ).copyWith(
                            bottom: Dimensions.paddingSizeExtraLarge,
                          ),
                          child: ButtonWidget(
                            margin: const EdgeInsets.symmetric(
                              horizontal: Dimensions.paddingSizeDefault,
                            ),
                            radius: Dimensions.radiusExtraLarge,
                            buttonText: 'next'.tr,
                            onPressed: () =>
                                _validateAndContinue(authController),
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LokallyBillingZoneRule {
  final String zoneId;
  final String zoneName;
  final double perRideFeePercent;
  final bool vatEnabled;
  final double vatPercent;
  final double monthlyAmount;
  final double parcelMonthlyAmount;
  final String messageIfNotAvailable;

  const _LokallyBillingZoneRule({
    required this.zoneId,
    required this.zoneName,
    required this.perRideFeePercent,
    required this.vatEnabled,
    required this.vatPercent,
    required this.monthlyAmount,
    required this.parcelMonthlyAmount,
    required this.messageIfNotAvailable,
  });

  factory _LokallyBillingZoneRule.fromJson(Map<dynamic, dynamic> json) {
    return _LokallyBillingZoneRule(
      zoneId: (json['zone_id'] ?? '').toString(),
      zoneName: (json['zone_name'] ?? '').toString(),
      perRideFeePercent: _toDouble(json['per_ride_fee_percent']),
      vatEnabled: json['vat_enabled'] == true || json['vat_enabled'] == 1,
      vatPercent: _toDouble(json['vat_percent']),
      monthlyAmount: _toDouble(json['monthly_amount']),
      parcelMonthlyAmount: _toDouble(json['parcel_monthly_amount']),
      messageIfNotAvailable: (json['message_if_not_available'] ??
              'Em breve iniciaremos nossas atividades nesta cidade.')
          .toString(),
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString().replaceAll(',', '.')) ?? 0;
  }
}

class _LokallyCitySelector extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLoading;
  final bool hasError;
  final _LokallyBillingZoneRule? selectedRule;
  final List<_LokallyBillingZoneRule> suggestions;
  final bool showUnavailableMessage;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onRetry;
  final ValueChanged<_LokallyBillingZoneRule> onSelectCity;

  const _LokallyCitySelector({
    required this.controller,
    required this.focusNode,
    required this.isLoading,
    required this.hasError,
    required this.selectedRule,
    required this.suggestions,
    required this.showUnavailableMessage,
    required this.onChanged,
    required this.onSubmitted,
    required this.onRetry,
    required this.onSelectCity,
  });

  @override
  Widget build(BuildContext context) {
    final Color readableInputColor =
        Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.78) ??
            Theme.of(context).hintColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          enabled: !isLoading,
          textInputAction: TextInputAction.search,
          style: textMedium.copyWith(
            fontSize: 15,
            height: 1.25,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
          decoration: InputDecoration(
            hintText: isLoading
                ? 'Carregando cidades disponíveis...'
                : 'Digite o nome da cidade',
            hintStyle: textMedium.copyWith(
              fontSize: 14.5,
              color: readableInputColor,
            ),
            prefixIcon: Icon(
              Icons.location_on_outlined,
              color: Theme.of(context).primaryColor,
            ),
            suffixIcon: selectedRule != null
                ? Icon(
                    Icons.check_circle,
                    color: Theme.of(context).primaryColor,
                  )
                : null,
            filled: true,
            fillColor: Theme.of(context).cardColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              borderSide: BorderSide(
                color: Theme.of(context).hintColor.withValues(alpha: 0.35),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              borderSide: BorderSide(
                color: selectedRule != null
                    ? Theme.of(context).primaryColor.withValues(alpha: 0.75)
                    : Theme.of(context).hintColor.withValues(alpha: 0.35),
                width: selectedRule != null ? 1.2 : 0.8,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              borderSide: BorderSide(
                color: Theme.of(context).primaryColor,
                width: 1.2,
              ),
            ),
          ),
        ),
        if (isLoading) ...[
          const SizedBox(height: 14),
          _LokallyStatusMessage(
            message: 'Buscando cidades disponíveis no servidor...',
            icon: Icons.sync,
            strong: false,
          ),
        ],
        if (hasError) ...[
          const SizedBox(height: 14),
          _LokallyErrorMessage(
            message:
                'Não foi possível carregar as cidades disponíveis. Toque para tentar novamente.',
            onTap: onRetry,
          ),
        ],
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: 10),
          _LokallyStatusMessage(
            message: 'Toque em uma cidade abaixo para selecionar.',
            icon: Icons.touch_app_outlined,
            strong: true,
          ),
          const SizedBox(height: 10),
          ...suggestions.map(
            (rule) => _LokallyCitySuggestionCard(
              rule: rule,
              onTap: () => onSelectCity(rule),
            ),
          ),
        ],
        if (showUnavailableMessage) ...[
          const SizedBox(height: 14),
          _LokallyStatusMessage(
            message: 'Em breve iniciaremos nossas atividades nesta cidade.',
            icon: Icons.info_outline,
            strong: true,
          ),
        ],
        if (selectedRule != null) ...[
          const SizedBox(height: 14),
          _LokallyStatusMessage(
            message: '${selectedRule!.zoneName} disponível para cadastro.',
            icon: Icons.check_circle_outline,
            strong: true,
          ),
        ],
      ],
    );
  }
}

class _LokallyCitySuggestionCard extends StatelessWidget {
  final _LokallyBillingZoneRule rule;
  final VoidCallback onTap;

  const _LokallyCitySuggestionCard({
    required this.rule,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            border: Border.all(
              color: Theme.of(context).hintColor.withValues(alpha: 0.26),
              width: 0.8,
            ),
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).hintColor.withValues(alpha: 0.06),
                blurRadius: 8,
                spreadRadius: 1,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.location_city_outlined,
                size: 20,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  rule.zoneName,
                  style: textBold.copyWith(
                    fontSize: 14.5,
                    height: 1.25,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: Theme.of(context).hintColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LokallyStatusMessage extends StatelessWidget {
  final String message;
  final IconData icon;
  final bool strong;

  const _LokallyStatusMessage({
    required this.message,
    required this.icon,
    required this.strong,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        color: Theme.of(context).primaryColor.withValues(alpha: 0.06),
        border: Border.all(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.16),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 19,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: (strong ? textBold : textMedium).copyWith(
                fontSize: 13.8,
                height: 1.35,
                color: strong
                    ? Theme.of(context).primaryColor
                    : Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withValues(alpha: 0.82),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LokallyErrorMessage extends StatelessWidget {
  final String message;
  final VoidCallback onTap;

  const _LokallyErrorMessage({
    required this.message,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          color: Colors.red.withValues(alpha: 0.06),
          border: Border.all(
            color: Colors.red.withValues(alpha: 0.18),
            width: 0.8,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.refresh,
              size: 19,
              color: Colors.red,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: textBold.copyWith(
                  fontSize: 13.8,
                  height: 1.35,
                  color: Colors.red,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LokallyServiceOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onChanged;

  const _LokallyServiceOptionCard({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final Color borderColor = selected
        ? Theme.of(context).primaryColor.withValues(alpha: 0.75)
        : Theme.of(context).hintColor.withValues(alpha: 0.35);

    final Color titleColor = Theme.of(context).textTheme.bodyLarge?.color ??
        Theme.of(context).textTheme.bodyMedium?.color ??
        Colors.black;

    final Color subtitleColor = Theme.of(context)
            .textTheme
            .bodyMedium
            ?.color
            ?.withValues(alpha: selected ? 0.78 : 0.66) ??
        Theme.of(context).hintColor;

    return InkWell(
      onTap: onChanged,
      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 4,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          border: Border.all(
            color: borderColor,
            width: selected ? 1.2 : 0.8,
          ),
          color: selected
              ? Theme.of(context).primaryColor.withValues(alpha: 0.045)
              : Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).hintColor.withValues(alpha: 0.08),
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: CheckboxListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeSmall,
            vertical: 6,
          ),
          title: Text(
            title,
            style: textBold.copyWith(
              fontSize: 15.5,
              height: 1.25,
              color: titleColor,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(
              subtitle,
              style: textMedium.copyWith(
                color: subtitleColor,
                fontSize: 12.5,
                height: 1.35,
              ),
              maxLines: 3,
            ),
          ),
          value: selected,
          onChanged: (value) {
            onChanged();
          },
          activeColor: Theme.of(context).primaryColor,
          checkColor: Colors.white,
          side: BorderSide(
            color: Theme.of(context).hintColor.withValues(alpha: 0.55),
          ),
          controlAffinity: ListTileControlAffinity.trailing,
        ),
      ),
    );
  }
}

class _LokallyPartnershipSection extends StatelessWidget {
  final _LokallyBillingZoneRule rule;
  final bool onlyParcelDelivery;
  final String? selectedPartnershipModel;
  final VoidCallback onSelectPerRide;
  final VoidCallback onSelectMonthly;

  const _LokallyPartnershipSection({
    required this.rule,
    required this.onlyParcelDelivery,
    required this.selectedPartnershipModel,
    required this.onSelectPerRide,
    required this.onSelectMonthly,
  });

  @override
  Widget build(BuildContext context) {
    final String vatText = rule.vatEnabled
        ? '${_LokallyFormat.percent(rule.vatPercent)} por corrida'
        : 'inativo';

    return Column(
      children: [
        Text(
          'Modelo de parceria',
          textAlign: TextAlign.center,
          style: textBold.copyWith(
            fontSize: 22,
            height: 1.2,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 12),
        _LokallyRuleInfoCard(
          message: onlyParcelDelivery
              ? 'Aqui você tem liberdade de escolha. Em ${rule.zoneName}, para Entrega de encomenda, você será cobrado pela mensalidade de ${_LokallyFormat.currency(rule.parcelMonthlyAmount)}. Em ${rule.zoneName}, o imposto municipal é $vatText.'
              : 'Aqui você tem liberdade de escolha. Em ${rule.zoneName}, você pode escolher Taxa por corrida: ${_LokallyFormat.percent(rule.perRideFeePercent)} ou Mensalidade: ${_LokallyFormat.currency(rule.monthlyAmount)}. Em ${rule.zoneName}, o imposto municipal é $vatText.',
        ),
        const SizedBox(height: 18),
        if (onlyParcelDelivery) ...[
          _LokallyMonthlyInfoCard(
            message:
                'Você será cobrado mensalmente ${_LokallyFormat.currency(rule.parcelMonthlyAmount)}',
          ),
        ] else ...[
          _LokallyPartnershipOptionCard(
            title: 'Taxa por corrida',
            subtitle: 'Ative se você quer ser cobrado a cada corrida',
            priceText: _LokallyFormat.percent(rule.perRideFeePercent),
            selected: selectedPartnershipModel == 'per_ride',
            onTap: onSelectPerRide,
          ),
          const SizedBox(height: 16),
          _LokallyPartnershipOptionCard(
            title: 'Mensalidade',
            subtitle: 'Ative se você quer ser cobrado mensalmente',
            priceText: _LokallyFormat.currency(rule.monthlyAmount),
            selected: selectedPartnershipModel == 'monthly',
            onTap: onSelectMonthly,
          ),
        ],
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            color: Theme.of(context).primaryColor.withValues(alpha: 0.06),
            border: Border.all(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.18),
              width: 0.8,
            ),
          ),
          child: Text(
            'Você só será cobrado após 30 dias de uso do APP.',
            textAlign: TextAlign.center,
            style: textBold.copyWith(
              fontSize: 13.8,
              height: 1.35,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _LokallyRuleInfoCard extends StatelessWidget {
  final String message;

  const _LokallyRuleInfoCard({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        color: Theme.of(context).primaryColor.withValues(alpha: 0.04),
        border: Border.all(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.18),
          width: 0.8,
        ),
      ),
      child: Text(
        message,
        textAlign: TextAlign.left,
        style: textMedium.copyWith(
          fontSize: 14.2,
          height: 1.48,
          color: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.color
              ?.withValues(alpha: 0.86),
        ),
      ),
    );
  }
}

class _LokallyPartnershipOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String priceText;
  final bool selected;
  final VoidCallback onTap;

  const _LokallyPartnershipOptionCard({
    required this.title,
    required this.subtitle,
    required this.priceText,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color borderColor = selected
        ? Theme.of(context).primaryColor.withValues(alpha: 0.8)
        : Theme.of(context).hintColor.withValues(alpha: 0.35);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          border: Border.all(
            color: borderColor,
            width: selected ? 1.2 : 0.8,
          ),
          color: selected
              ? Theme.of(context).primaryColor.withValues(alpha: 0.045)
              : Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).hintColor.withValues(alpha: 0.08),
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Radio<String>(
              value: title,
              groupValue: selected ? title : null,
              onChanged: (value) {
                onTap();
              },
              activeColor: Theme.of(context).primaryColor,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textBold.copyWith(
                      fontSize: 15.8,
                      height: 1.25,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: textMedium.copyWith(
                      fontSize: 12.8,
                      height: 1.35,
                      color: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.color
                          ?.withValues(alpha: 0.72),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              priceText,
              textAlign: TextAlign.right,
              style: textBold.copyWith(
                fontSize: 16,
                height: 1.2,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LokallyMonthlyInfoCard extends StatelessWidget {
  final String message;

  const _LokallyMonthlyInfoCard({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 18,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        border: Border.all(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.75),
          width: 1.2,
        ),
        color: Theme.of(context).primaryColor.withValues(alpha: 0.045),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).hintColor.withValues(alpha: 0.08),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: textBold.copyWith(
          fontSize: 15.5,
          height: 1.35,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }
}

class _LokallyFormat {
  static String currency(double value) {
    return 'R\$${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  static String percent(double value) {
    return '${value.toStringAsFixed(2).replaceAll('.', ',')}%';
  }
}
