import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/common_widgets/button_widget.dart';
import 'package:ride_sharing_user_app/features/refer_and_earn/controllers/refer_and_earn_controller.dart';
import 'package:ride_sharing_user_app/features/splash/controllers/splash_controller.dart';
import 'package:ride_sharing_user_app/helper/display_helper.dart';
import 'package:ride_sharing_user_app/helper/price_converter.dart';
import 'package:ride_sharing_user_app/util/app_constants.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:ride_sharing_user_app/util/images.dart';
import 'package:ride_sharing_user_app/util/styles.dart';
import 'package:share_plus/share_plus.dart';

class HomeReferralViewWidget extends StatelessWidget {
  const HomeReferralViewWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeDefault,
        vertical: Dimensions.paddingSizeSmall,
      ),
      padding: const EdgeInsets.symmetric(
        vertical: Dimensions.paddingSizeDefault,
        horizontal: Dimensions.paddingSizeDefault,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'invite&getRewards'.tr,
                  style: textSemiBold.copyWith(
                    fontSize: Dimensions.fontSizeDefault,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: Dimensions.paddingSizeSmall),
                Text(
                  'share_code_with_your_friends'.tr,
                  style: textRegular.copyWith(
                    fontSize: Dimensions.fontSizeExtraSmall,
                    color: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withValues(alpha: 0.74),
                  ),
                ),
                const SizedBox(height: Dimensions.paddingSizeSmall),
                GetBuilder<ReferAndEarnController>(
                  builder: (referAndEarnController) {
                    return referAndEarnController.isLoading
                        ? SpinKitCircle(
                            color: Theme.of(context).primaryColor,
                            size: 30.0,
                          )
                        : InkWell(
                            onTap: () {
                              referAndEarnController
                                  .getReferralDetails()
                                  .then((value) {
                                if (!(Get.isBottomSheetOpen ?? false)) {
                                  Get.bottomSheet(
                                    const ReferralViewBottomSheetWidget(),
                                    backgroundColor:
                                        Theme.of(Get.context!).cardColor,
                                    isDismissible: false,
                                  );
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(100),
                            child: Container(
                              height: 34,
                              width: 145,
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(100),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context)
                                        .primaryColor
                                        .withValues(alpha: 0.16),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  'invite_friends'.tr,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: textSemiBold.copyWith(
                                    color: Colors.white,
                                    fontSize: Dimensions.fontSizeSmall,
                                  ),
                                ),
                              ),
                            ),
                          );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Image.asset(
            Images.homeReferralIcon,
            height: 104,
            width: 112,
          ),
        ],
      ),
    );
  }
}

class ReferralViewBottomSheetWidget extends StatelessWidget {
  const ReferralViewBottomSheetWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(
        left: Dimensions.paddingSizeDefault,
        right: Dimensions.paddingSizeDefault,
        top: Dimensions.paddingSizeSmall,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(Dimensions.paddingSizeLarge),
          topLeft: Radius.circular(Dimensions.paddingSizeLarge),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => Get.back(),
            child: Align(
              alignment: Alignment.topRight,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).hintColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(50),
                ),
                padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                child: Image.asset(
                  Images.crossIcon,
                  height: 10,
                  width: 10,
                ),
              ),
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          Image.asset(
            Images.homeReferralIcon,
            height: 120,
            width: 120,
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          Text(
            'invite&getRewards'.tr,
            style: textSemiBold.copyWith(
              fontSize: Dimensions.fontSizeLarge,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeLarge,
            ),
            child: RichText(
              text: TextSpan(
                text: 'referral_bottom_sheet_note'.tr,
                style: textRegular.copyWith(
                  color: Theme.of(context).colorScheme.secondaryFixedDim,
                  fontSize: Dimensions.fontSizeSmall,
                ),
                children: [
                  TextSpan(
                    text:
                        '  ${PriceConverter.convertPrice(context, Get.find<ReferAndEarnController>().referralDetails?.data?.shareCodeEarning ?? 0)}',
                    style: textRobotoBold.copyWith(
                      color: Theme.of(context).colorScheme.secondaryFixedDim,
                      fontSize: Dimensions.fontSizeSmall,
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeLarge),
          Container(
            width: Get.width * 0.72,
            padding: const EdgeInsets.only(left: Dimensions.paddingSizeDefault),
            decoration: BoxDecoration(
              color: Theme.of(context).highlightColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              border: Border.all(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    Get.find<ReferAndEarnController>()
                            .referralDetails
                            ?.data
                            ?.referralCode ??
                        '',
                    overflow: TextOverflow.ellipsis,
                    style: textBold,
                  ),
                ),
                InkWell(
                  onTap: () {
                    Clipboard.setData(
                      ClipboardData(
                        text: Get.find<ReferAndEarnController>()
                                .referralDetails
                                ?.data
                                ?.referralCode ??
                            '',
                      ),
                    ).then((_) {
                      showCustomSnackBar('copied'.tr, isError: false);
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.paddingSizeDefault,
                      vertical: Dimensions.paddingSizeSmall,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .highlightColor
                          .withValues(alpha: 0.2),
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(Dimensions.radiusDefault),
                        bottomRight: Radius.circular(Dimensions.radiusDefault),
                      ),
                    ),
                    child: Icon(
                      Icons.copy_rounded,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeLarge),
          ButtonWidget(
            onPressed: () {
              final params = ShareParams(
                text:
                    'Olá! Conheça a ${Get.find<SplashController>().config?.businessName}, uma plataforma de viagens e entregas. '
                    'Use meu código de indicação "${Get.find<ReferAndEarnController>().referralDetails?.data?.referralCode ?? ''}" ao se cadastrar e aproveite os benefícios.'
                    '\n\n${AppConstants.baseUrl}',
              );

              SharePlus.instance.share(params);
            },
            width: Get.width * 0.62,
            buttonText: 'invite_friends'.tr,
          ),
          const SizedBox(height: Dimensions.paddingSizeLarge),
        ],
      ),
    );
  }
}
