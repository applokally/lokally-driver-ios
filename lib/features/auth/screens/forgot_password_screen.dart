import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/features/auth/domain/enums/verification_from_enum.dart';
import 'package:ride_sharing_user_app/features/auth/screens/sign_in_screen.dart';
import 'package:ride_sharing_user_app/features/help_and_support/screens/help_and_support_screen.dart';
import 'package:ride_sharing_user_app/features/splash/controllers/splash_controller.dart';
import 'package:ride_sharing_user_app/helper/display_helper.dart';
import 'package:ride_sharing_user_app/helper/svg_image_helper.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:ride_sharing_user_app/util/images.dart';
import 'package:ride_sharing_user_app/util/styles.dart';
import 'package:ride_sharing_user_app/features/auth/controllers/auth_controller.dart';
import 'package:ride_sharing_user_app/features/auth/screens/verification_screen.dart';
import 'package:ride_sharing_user_app/common_widgets/app_bar_widget.dart';
import 'package:ride_sharing_user_app/common_widgets/button_widget.dart';
import 'package:ride_sharing_user_app/common_widgets/text_field_widget.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final String? phoneNumber;
  final VerificationForm from;

  const ForgotPasswordScreen({
    super.key,
    this.phoneNumber,
    required this.from,
  });

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  bool isOtpOptionEnable = true;
  TextEditingController phoneController = TextEditingController();

  @override
  void initState() {
    isOtpOptionEnable =
        ((Get.find<SplashController>().config?.isFirebaseOtpVerification ??
                false) ||
            (Get.find<SplashController>().config?.isSmsGateway ?? false));

    if (widget.phoneNumber != null) {
      phoneController.text = widget.phoneNumber!;
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final Color readableInputColor =
        Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.72) ??
            Theme.of(context).hintColor;

    final TextStyle readableInputTextStyle = textRegular.copyWith(
      color: readableInputColor,
      fontSize: 14.5,
      height: 1.25,
    );

    final ThemeData readableInputTheme = Theme.of(context).copyWith(
      hintColor: readableInputColor,
      inputDecorationTheme: Theme.of(context).inputDecorationTheme.copyWith(
            hintStyle: readableInputTextStyle,
          ),
    );

    return SafeArea(
      top: false,
      child: Scaffold(
        appBar: AppBarWidget(
          title: widget.from == VerificationForm.resetPassword
              ? 'forget_password'.tr
              : 'verify_customer'.tr,
          showBackButton: true,
          regularAppbar: true,
        ),
        body: GetBuilder<AuthController>(
          builder: (authController) {
            if (isOtpOptionEnable) {
              return Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Dimensions.paddingSizeLarge,
                      Dimensions.paddingSizeLarge,
                      Dimensions.paddingSizeLarge,
                      Dimensions.paddingSizeLarge,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: Dimensions.paddingSizeSmall),
                        Center(
                          child: SizedBox(
                            height: 175,
                            child: FutureBuilder<String>(
                              future: loadSvgAndChangeColors(
                                Images.forgetPasswordGraphics,
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
                                  Images.forgetPasswordGraphics,
                                  fit: BoxFit.contain,
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                widget.from == VerificationForm.resetPassword
                                    ? 'forget_your_password'.tr
                                    : 'verify_yourself'.tr,
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
                              Text(
                                'enter_your_phone_to_receive_a_reset_code'.tr,
                                textAlign: TextAlign.center,
                                style: textMedium.copyWith(
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.color
                                      ?.withValues(alpha: 0.82),
                                  fontSize: 14.8,
                                  height: 1.45,
                                ),
                                maxLines: 3,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                        Theme(
                          data: readableInputTheme,
                          child: DefaultTextStyle.merge(
                            style: readableInputTextStyle,
                            child: TextFieldWidget(
                              hintText: 'enter_your_phone'.tr,
                              inputType: TextInputType.number,
                              countryDialCode: authController.countryDialCode,
                              controller: phoneController,
                              onCountryChanged: (CountryCode countryCode) {
                                authController.countryDialCode =
                                    countryCode.dialCode!;
                                authController.setCountryCode(
                                  countryCode.dialCode!,
                                );
                              },
                              autoFocus: phoneController.text.isEmpty,
                            ),
                          ),
                        ),
                        const SizedBox(
                            height: Dimensions.paddingSizeExtraLarge),
                        authController.isOtpSending
                            ? Center(
                                child: SpinKitCircle(
                                  color: Theme.of(context).primaryColor,
                                  size: 40.0,
                                ),
                              )
                            : ButtonWidget(
                                buttonText: 'get_otp'.tr,
                                radius: 50,
                                onPressed: () {
                                  String phoneNumber = phoneController.text;

                                  if (phoneNumber.isEmpty) {
                                    showCustomSnackBar('phone_is_required'.tr);
                                  } else {
                                    if (Get.find<SplashController>()
                                            .config
                                            ?.isFirebaseOtpVerification ??
                                        false) {
                                      authController.firebaseOtpSend(
                                        countryCode:
                                            authController.countryDialCode,
                                        number: phoneNumber,
                                        from: widget.from,
                                      );
                                    } else if (Get.find<SplashController>()
                                            .config
                                            ?.isSmsGateway ??
                                        false) {
                                      authController
                                          .sendOtp(
                                        countryCode:
                                            authController.countryDialCode,
                                        number: phoneNumber,
                                      )
                                          .then((value) {
                                        if (value.statusCode == 200) {
                                          Get.to(
                                            () => VerificationScreen(
                                              countryCode: authController
                                                  .countryDialCode,
                                              number: phoneNumber,
                                              form: widget.from,
                                            ),
                                          );
                                        }
                                      });
                                    } else {
                                      showCustomSnackBar(
                                        'sms_gateway_not_integrate'.tr,
                                      );
                                    }
                                  }
                                },
                              ),
                        const SizedBox(height: 18),
                        if (widget.from == VerificationForm.resetPassword) ...[
                          (Get.find<SplashController>()
                                          .config!
                                          .selfRegistration !=
                                      null &&
                                  Get.find<SplashController>()
                                      .config!
                                      .selfRegistration!)
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${'do_not_have_an_account'.tr} ',
                                      style: textMedium.copyWith(
                                        fontSize: 14,
                                        height: 1.3,
                                        color: Theme.of(context).hintColor,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () => Get.offAll(
                                        () => const SignInScreen(),
                                      ),
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: const Size(50, 30),
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: Text(
                                        'join_as_driver'.tr,
                                        style: textBold.copyWith(
                                          decoration: TextDecoration.underline,
                                          fontSize: 14.5,
                                          height: 1.3,
                                          color: Theme.of(context).primaryColor,
                                          decorationColor:
                                              Theme.of(context).primaryColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "${'to_create_account'.tr} ",
                                      style: textRegular.copyWith(
                                        fontSize: 14,
                                        height: 1.3,
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () => Get.find<SplashController>()
                                          .sendMailOrCall(
                                        "tel:${Get.find<SplashController>().config?.businessContactPhone}",
                                        false,
                                      ),
                                      child: Text(
                                        "${'contact_support'.tr} ",
                                        style: textBold.copyWith(
                                          fontSize: 14,
                                          height: 1.3,
                                          color: Theme.of(context).primaryColor,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                return ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.paddingSizeLarge,
                      vertical: Dimensions.paddingSizeLarge,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(
                            Dimensions.paddingSizeLarge,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(
                              Dimensions.radiusDefault,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context)
                                    .hintColor
                                    .withValues(alpha: 0.1),
                                blurRadius: 10,
                                spreadRadius: 1,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Image.asset(
                                Images.warning,
                                height: 48,
                                width: 48,
                              ),
                              const SizedBox(
                                height: Dimensions.paddingSizeLarge,
                              ),
                              Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text:
                                          'password_recovery_is_temporary_unavailable'
                                              .tr,
                                      style: textSemiBold.copyWith(
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.color,
                                        fontSize: 15,
                                        height: 1.35,
                                      ),
                                    ),
                                    const TextSpan(text: '\n'),
                                    TextSpan(
                                      text: 'please_contact_our'.tr,
                                      style: textMedium.copyWith(
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.color
                                            ?.withValues(alpha: 0.82),
                                        fontSize: 14.5,
                                        height: 1.4,
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'support'.tr,
                                      style: textBold.copyWith(
                                        color: Theme.of(context).primaryColor,
                                        fontSize: 14.5,
                                        height: 1.4,
                                        decoration: TextDecoration.underline,
                                        decorationColor:
                                            Theme.of(context).primaryColor,
                                      ),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () => Get.to(
                                              () =>
                                                  const HelpAndSupportScreen(),
                                            ),
                                    ),
                                    TextSpan(
                                      text: ' ${'team_for_assistance'.tr}',
                                      style: textMedium.copyWith(
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.color
                                            ?.withValues(alpha: 0.82),
                                        fontSize: 14.5,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        ButtonWidget(
                          showBorder: true,
                          borderWidth: 1,
                          buttonText: 'contact_support'.tr,
                          onPressed: () => Get.to(
                            () => const HelpAndSupportScreen(),
                          ),
                          radius: 50,
                        ),
                        const SizedBox(height: Dimensions.paddingSizeDefault),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
