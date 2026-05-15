import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';
import 'package:ride_sharing_user_app/common_widgets/button_widget.dart';
import 'package:ride_sharing_user_app/common_widgets/text_field_widget.dart';
import 'package:ride_sharing_user_app/features/auth/controllers/auth_controller.dart';
import 'package:ride_sharing_user_app/features/auth/screens/additional_sign_up_screen_2.dart';
import 'package:ride_sharing_user_app/features/auth/widgets/signup_appbar_widget.dart';
import 'package:ride_sharing_user_app/features/splash/controllers/splash_controller.dart';
import 'package:ride_sharing_user_app/helper/display_helper.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:ride_sharing_user_app/util/images.dart';
import 'package:ride_sharing_user_app/util/styles.dart';

class AdditionalSignUpScreen1 extends StatelessWidget {
  const AdditionalSignUpScreen1({super.key});

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

    return Scaffold(
      backgroundColor: Theme.of(context).cardColor,
      body: SafeArea(
        child: GetBuilder<AuthController>(
          builder: (authController) {
            return Column(
              children: [
                const SignUpAppbarWidget(
                  title: 'signup_as_a_driver',
                  progressText: '2_of_3',
                  enableBackButton: true,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        Dimensions.paddingSizeLarge,
                        Dimensions.paddingSizeLarge,
                        Dimensions.paddingSizeLarge,
                        Dimensions.paddingSizeLarge,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 18),
                          Text(
                            'provide_basic_info'.tr,
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
                              'enter_your_information'.tr,
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
                          ),
                          const SizedBox(height: 34),
                          _LokallyFieldTitle(
                            title: 'first_name'.tr,
                            isRequired: true,
                          ),
                          Theme(
                            data: readableInputTheme,
                            child: DefaultTextStyle.merge(
                              style: readableInputTextStyle,
                              child: TextFieldWidget(
                                hintText: 'enter_your_first_name'.tr,
                                capitalization: TextCapitalization.words,
                                inputType: TextInputType.name,
                                prefixIcon: Images.person,
                                controller: authController.fNameController,
                                focusNode: authController.fNameNode,
                                nextFocus: authController.lNameNode,
                                inputAction: TextInputAction.next,
                                autoFocus:
                                    authController.fNameController.text.isEmpty,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          _LokallyFieldTitle(title: 'last_name'.tr),
                          Theme(
                            data: readableInputTheme,
                            child: DefaultTextStyle.merge(
                              style: readableInputTextStyle,
                              child: TextFieldWidget(
                                hintText: 'enter_your_last_name'.tr,
                                capitalization: TextCapitalization.words,
                                inputType: TextInputType.name,
                                prefixIcon: Images.person,
                                controller: authController.lNameController,
                                focusNode: authController.lNameNode,
                                nextFocus: authController.phoneNode,
                                inputAction: TextInputAction.next,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          _LokallyFieldTitle(
                            title: 'phone'.tr,
                            isRequired: true,
                          ),
                          Theme(
                            data: readableInputTheme,
                            child: DefaultTextStyle.merge(
                              style: readableInputTextStyle,
                              child: TextFieldWidget(
                                hintText: 'enter_your_phone'.tr,
                                inputType: TextInputType.number,
                                countryDialCode: authController.countryDialCode,
                                controller: authController.phoneController,
                                focusNode: authController.phoneNode,
                                nextFocus: authController.passwordNode,
                                inputAction: TextInputAction.next,
                                onCountryChanged: (CountryCode countryCode) {
                                  authController.countryDialCode =
                                      countryCode.dialCode!;
                                  authController.setCountryCode(
                                    countryCode.dialCode!,
                                  );
                                  FocusScope.of(context).requestFocus(
                                    authController.phoneNode,
                                  );
                                },
                              ),
                            ),
                          ),
                          if (Get.find<SplashController>()
                                  .config
                                  ?.referralEarningStatus ??
                              false) ...[
                            const SizedBox(height: 18),
                            _LokallyFieldTitle(title: 'referral_code'.tr),
                            Theme(
                              data: readableInputTheme,
                              child: DefaultTextStyle.merge(
                                style: readableInputTextStyle,
                                child: TextFieldWidget(
                                  hintText: 'enter_refer_code'.tr,
                                  capitalization: TextCapitalization.words,
                                  inputType: TextInputType.text,
                                  prefixIcon: Images.referIcon,
                                  controller:
                                      authController.referralCodeController,
                                  focusNode: authController.referralNode,
                                  inputAction: TextInputAction.done,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 18),
                          _LokallyFieldTitle(
                            title: 'password'.tr,
                            isRequired: true,
                          ),
                          Theme(
                            data: readableInputTheme,
                            child: DefaultTextStyle.merge(
                              style: readableInputTextStyle,
                              child: TextFieldWidget(
                                hintText: 'password_hint'.tr,
                                inputType: TextInputType.text,
                                prefixIcon: Images.password,
                                isPassword: true,
                                controller: authController.passwordController,
                                focusNode: authController.passwordNode,
                                nextFocus: authController.confirmPasswordNode,
                                inputAction: TextInputAction.next,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          _LokallyFieldTitle(
                            title: 'confirm_password'.tr,
                            isRequired: true,
                          ),
                          Theme(
                            data: readableInputTheme,
                            child: DefaultTextStyle.merge(
                              style: readableInputTextStyle,
                              child: TextFieldWidget(
                                hintText: 'enter_confirm_password'.tr,
                                inputType: TextInputType.text,
                                prefixIcon: Images.password,
                                controller:
                                    authController.confirmPasswordController,
                                focusNode: authController.confirmPasswordNode,
                                nextFocus: authController.referralNode,
                                inputAction: TextInputAction.next,
                                isPassword: true,
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: Dimensions.paddingSizeExtraLarge,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color:
                            Theme.of(context).hintColor.withValues(alpha: 0.15),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(Dimensions.paddingSizeLarge),
                      topLeft: Radius.circular(Dimensions.paddingSizeLarge),
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
                    onPressed: () {
                      String fName = authController.fNameController.text;
                      String phone = authController.phoneController.text.trim();
                      String password = authController.passwordController.text;
                      String confirmPassword =
                          authController.confirmPasswordController.text;

                      if (fName.isEmpty) {
                        showCustomSnackBar('first_name_is_required'.tr);
                        FocusScope.of(context).requestFocus(
                          authController.fNameNode,
                        );
                      } else if (phone.isEmpty) {
                        showCustomSnackBar('phone_is_required'.tr);
                        FocusScope.of(context).requestFocus(
                          authController.phoneNode,
                        );
                      } else if (!PhoneNumber.parse(
                        authController.countryDialCode + phone,
                      ).isValid(type: PhoneNumberType.mobile)) {
                        showCustomSnackBar('phone_number_is_not_valid'.tr);
                        FocusScope.of(context).requestFocus(
                          authController.phoneNode,
                        );
                      } else if (password.isEmpty) {
                        showCustomSnackBar('password_is_required'.tr);
                        FocusScope.of(context).requestFocus(
                          authController.passwordNode,
                        );
                      } else if (password.length < 8) {
                        showCustomSnackBar(
                          'minimum_password_length_is_8'.tr,
                        );
                        FocusScope.of(context).requestFocus(
                          authController.passwordNode,
                        );
                      } else if (confirmPassword.isEmpty) {
                        showCustomSnackBar(
                          'confirm_password_is_required'.tr,
                        );
                        FocusScope.of(context).requestFocus(
                          authController.confirmPasswordNode,
                        );
                      } else if (password != confirmPassword) {
                        showCustomSnackBar('password_is_mismatch'.tr);
                        FocusScope.of(context).requestFocus(
                          authController.confirmPasswordNode,
                        );
                      } else {
                        Get.to(() => const AdditionalSignUpScreen2());
                      }
                    },
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

class _LokallyFieldTitle extends StatelessWidget {
  final String title;
  final bool isRequired;

  const _LokallyFieldTitle({
    required this.title,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 8,
        left: 2,
      ),
      child: Row(
        children: [
          Text(
            title,
            style: textBold.copyWith(
              fontSize: 15,
              height: 1.25,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          if (isRequired)
            Text(
              '*',
              style: textBold.copyWith(
                fontSize: 15,
                height: 1.25,
                color: Colors.redAccent,
              ),
            ),
        ],
      ),
    );
  }
}
