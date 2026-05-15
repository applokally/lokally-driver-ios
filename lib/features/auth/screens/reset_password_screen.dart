import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/features/auth/domain/enums/verification_from_enum.dart';
import 'package:ride_sharing_user_app/features/profile/controllers/profile_controller.dart';
import 'package:ride_sharing_user_app/helper/display_helper.dart';
import 'package:ride_sharing_user_app/helper/svg_image_helper.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:ride_sharing_user_app/util/images.dart';
import 'package:ride_sharing_user_app/features/auth/controllers/auth_controller.dart';
import 'package:ride_sharing_user_app/features/auth/screens/forgot_password_screen.dart';
import 'package:ride_sharing_user_app/features/auth/screens/sign_in_screen.dart';
import 'package:ride_sharing_user_app/common_widgets/app_bar_widget.dart';
import 'package:ride_sharing_user_app/common_widgets/button_widget.dart';
import 'package:ride_sharing_user_app/common_widgets/text_field_widget.dart';
import 'package:ride_sharing_user_app/util/styles.dart';

class ResetPasswordScreen extends StatefulWidget {
  final bool fromChangePassword;
  final String phoneNumber;

  const ResetPasswordScreen({
    super.key,
    this.fromChangePassword = false,
    required this.phoneNumber,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  TextEditingController oldPasswordController = TextEditingController();

  FocusNode passwordFocusNode = FocusNode();
  FocusNode confirmPasswordFocusNode = FocusNode();
  FocusNode oldPasswordFocus = FocusNode();

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
          title: Get.find<ProfileController>().profileInfo?.loggedInVia == 'otp'
              ? 'set_password'.tr
              : widget.fromChangePassword
                  ? 'change_password'.tr
                  : 'reset_password'.tr,
          showBackButton: true,
          regularAppbar: true,
          onBackPressed: () {
            if (widget.fromChangePassword) {
              Get.back();
            } else {
              Get.off(
                () => const ForgotPasswordScreen(
                  from: VerificationForm.resetPassword,
                ),
              );
            }
          },
        ),
        body: GetBuilder<AuthController>(
          builder: (authController) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(
                Dimensions.paddingSizeLarge,
                Dimensions.paddingSizeLarge,
                Dimensions.paddingSizeLarge,
                Dimensions.paddingSizeLarge,
              ),
              child: SingleChildScrollView(
                child: Column(
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
                            'set_your_password'.tr,
                            textAlign: TextAlign.center,
                            style: textBold.copyWith(
                              fontSize: 25,
                              height: 1.18,
                              color:
                                  Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'create_a_new_password_to_secure_your_account'.tr,
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
                    if (widget.fromChangePassword &&
                        Get.find<ProfileController>()
                                .profileInfo
                                ?.loggedInVia !=
                            'otp')
                      _LokallyFieldTitle(title: 'old_password'.tr),
                    if (widget.fromChangePassword &&
                        Get.find<ProfileController>()
                                .profileInfo
                                ?.loggedInVia !=
                            'otp')
                      Theme(
                        data: readableInputTheme,
                        child: DefaultTextStyle.merge(
                          style: readableInputTextStyle,
                          child: TextFieldWidget(
                            hintText: 'password_hint'.tr,
                            inputType: TextInputType.text,
                            prefixIcon: Images.password,
                            isPassword: true,
                            controller: oldPasswordController,
                            focusNode: oldPasswordFocus,
                            nextFocus: passwordFocusNode,
                            inputAction: TextInputAction.next,
                          ),
                        ),
                      ),
                    if (widget.fromChangePassword &&
                        Get.find<ProfileController>()
                                .profileInfo
                                ?.loggedInVia !=
                            'otp')
                      const SizedBox(height: 18),
                    _LokallyFieldTitle(title: 'password'.tr),
                    Theme(
                      data: readableInputTheme,
                      child: DefaultTextStyle.merge(
                        style: readableInputTextStyle,
                        child: TextFieldWidget(
                          hintText: 'password_hint'.tr,
                          inputType: TextInputType.text,
                          prefixIcon: Images.password,
                          isPassword: true,
                          controller: passwordController,
                          focusNode: passwordFocusNode,
                          nextFocus: confirmPasswordFocusNode,
                          inputAction: TextInputAction.next,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _LokallyFieldTitle(title: 'confirm_password'.tr),
                    Theme(
                      data: readableInputTheme,
                      child: DefaultTextStyle.merge(
                        style: readableInputTextStyle,
                        child: TextFieldWidget(
                          hintText: '•••••••••••',
                          inputType: TextInputType.text,
                          prefixIcon: Images.password,
                          controller: confirmPasswordController,
                          focusNode: confirmPasswordFocusNode,
                          inputAction: TextInputAction.done,
                          isPassword: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeDefault * 3),
                    authController.isLoading
                        ? Center(
                            child: SpinKitCircle(
                              color: Theme.of(context).primaryColor,
                              size: 40.0,
                            ),
                          )
                        : ButtonWidget(
                            buttonText: widget.fromChangePassword &&
                                    Get.find<ProfileController>()
                                            .profileInfo
                                            ?.loggedInVia !=
                                        'otp'
                                ? 'update'.tr
                                : 'save'.tr,
                            onPressed: () {
                              String oldPassword = oldPasswordController.text;
                              String password = passwordController.text;
                              String confirmPassword =
                                  confirmPasswordController.text;

                              if (password.isEmpty) {
                                showCustomSnackBar('password_is_required'.tr);
                              } else if (password.length < 6) {
                                showCustomSnackBar(
                                  'minimum_password_length_is_8'.tr,
                                );
                              } else if (confirmPassword.isEmpty) {
                                showCustomSnackBar(
                                  'confirm_password_is_required'.tr,
                                );
                              } else if (password != confirmPassword) {
                                showCustomSnackBar('password_is_mismatch'.tr);
                              } else if (oldPassword.isEmpty &&
                                  widget.fromChangePassword &&
                                  Get.find<ProfileController>()
                                          .profileInfo
                                          ?.loggedInVia !=
                                      'otp') {
                                showCustomSnackBar(
                                  'previous_password_is_required'.tr,
                                );
                              } else {
                                if (widget.fromChangePassword) {
                                  authController.changePassword(
                                    Get.find<ProfileController>()
                                                .profileInfo
                                                ?.loggedInVia !=
                                            'otp'
                                        ? oldPassword
                                        : '',
                                    password,
                                  );
                                } else {
                                  authController.resetPassword(
                                    widget.phoneNumber,
                                    password,
                                  );
                                }
                              }
                            },
                            radius: 50,
                          ),
                    if (!widget.fromChangePassword) ...[
                      const SizedBox(height: 18),
                      Center(
                        child: TextButton(
                          onPressed: () => Get.offAll(
                            () => const SignInScreen(),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            minimumSize: const Size(50, 34),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Entrar como motorista',
                            textAlign: TextAlign.center,
                            style: textBold.copyWith(
                              fontSize: 15,
                              height: 1.3,
                              decoration: TextDecoration.underline,
                              color: Theme.of(context).primaryColor,
                              decorationColor: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LokallyFieldTitle extends StatelessWidget {
  final String title;

  const _LokallyFieldTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 8,
        left: 2,
      ),
      child: Text(
        title,
        style: textBold.copyWith(
          fontSize: 14.5,
          height: 1.25,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
    );
  }
}
