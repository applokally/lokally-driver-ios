import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/common_widgets/animated_wifi/animated_wifi_widget.dart';
import 'package:ride_sharing_user_app/features/profile/controllers/profile_controller.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:ride_sharing_user_app/util/styles.dart';

class StayOnlineWidget extends StatelessWidget {
  const StayOnlineWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfileController>(
      initState: (val) {
        Get.find<ProfileController>().getProfileInfo();
      },
      builder: (profileController) {
        log('=online==>${profileController.profileInfo?.details?.isOnline}');

        final bool isOnline =
            profileController.profileInfo?.details?.isOnline == '1';

        final Color statusColor = isOnline
            ? Theme.of(context).primaryColor
            : Colors.redAccent.shade400;

        final Color statusBackgroundColor = isOnline
            ? Theme.of(context).primaryColor.withValues(alpha: 0.08)
            : Colors.redAccent.shade400.withValues(alpha: 0.08);

        final Color descriptionColor = Theme.of(context)
                .textTheme
                .bodyMedium
                ?.color
                ?.withValues(alpha: 0.74) ??
            Theme.of(context).hintColor;

        return Padding(
          padding: const EdgeInsets.only(
            top: Dimensions.paddingSizeSmall,
            bottom: Dimensions.paddingSizeDefault,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Align(
                alignment: Alignment.center,
                child: SizedBox.square(
                  dimension: 76,
                  child: WifiAnimations(
                    size: 76,
                    centered: true,
                  ),
                ),
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingSizeDefault,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: statusBackgroundColor,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.18),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 8,
                      width: 8,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isOnline ? 'Online' : 'Offline',
                      textAlign: TextAlign.center,
                      style: textBold.copyWith(
                        color: statusColor,
                        fontSize: Dimensions.fontSizeLarge,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingSizeOverLarge,
                ),
                child: Text(
                  isOnline
                      ? 'Você está disponível para receber viagens e entregas próximas.'
                      : 'Ative seu status para receber novas solicitações de viagens e entregas.',
                  textAlign: TextAlign.center,
                  style: textMedium.copyWith(
                    color: descriptionColor,
                    fontSize: Dimensions.fontSizeSmall,
                    height: 1.38,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
