import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/common_widgets/button_widget.dart';
import 'package:ride_sharing_user_app/common_widgets/loader_widget.dart';
import 'package:ride_sharing_user_app/features/auth/controllers/auth_controller.dart';
import 'package:ride_sharing_user_app/features/dashboard/controllers/bottom_menu_controller.dart';
import 'package:ride_sharing_user_app/features/dashboard/screens/dashboard_screen.dart';
import 'package:ride_sharing_user_app/features/location/controllers/location_controller.dart';
import 'package:ride_sharing_user_app/features/out_of_zone/controllers/out_of_zone_controller.dart';
import 'package:ride_sharing_user_app/helper/login_helper.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:ride_sharing_user_app/util/images.dart';
import 'package:ride_sharing_user_app/util/styles.dart';

class AccessLocationScreen extends StatelessWidget {
  const AccessLocationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;
    final Color titleColor =
        Get.isDarkMode ? Theme.of(context).primaryColorLight : primaryColor;
    final Color descriptionColor = Get.isDarkMode
        ? Theme.of(context).primaryColorLight.withValues(alpha: 0.82)
        : Theme.of(context)
                .textTheme
                .bodyMedium
                ?.color
                ?.withValues(alpha: 0.78) ??
            primaryColor;

    return SafeArea(
      top: false,
      child: Scaffold(
        backgroundColor: Theme.of(context).cardColor,
        body: PopScope(
          canPop: false,
          onPopInvokedWithResult: (res, val) async {
            Get.find<BottomMenuController>().exitApp();
            return;
          },
          child: Center(
            child: GetBuilder<LocationController>(
              builder: (locationController) {
                return Column(
                  children: [
                    Expanded(
                      child: SizedBox(
                        width: Dimensions.webMaxWidth,
                        child: Center(
                          child: SizedBox(
                            width: 700,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: Dimensions.paddingSizeLarge,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    Images.mapLocationIcon,
                                    height: 230,
                                    fit: BoxFit.contain,
                                  ),
                                  const SizedBox(height: 22),
                                  Text(
                                    'Ative sua localização',
                                    textAlign: TextAlign.center,
                                    style: textBold.copyWith(
                                      fontSize: 24,
                                      height: 1.18,
                                      color: titleColor,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Use sua localização atual para conectar o app à sua área de atendimento e começar a receber viagens e entregas disponíveis.',
                                    textAlign: TextAlign.center,
                                    style: textMedium.copyWith(
                                      fontSize: 14.8,
                                      height: 1.45,
                                      color: descriptionColor,
                                    ),
                                    maxLines: 4,
                                  ),
                                  const SizedBox(height: 18),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(
                                      Dimensions.paddingSizeDefault,
                                    ),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withValues(
                                        alpha: Get.isDarkMode ? 0.18 : 0.08,
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: primaryColor.withValues(
                                          alpha: Get.isDarkMode ? 0.36 : 0.18,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          Icons.privacy_tip_outlined,
                                          size: 22,
                                          color: primaryColor,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            'Usamos sua localização para receber chamadas, acompanhar viagens e entregas e manter a segurança operacional, mesmo quando o app estiver fechado ou em segundo plano.',
                                            style: textMedium.copyWith(
                                              fontSize: 13.5,
                                              height: 1.42,
                                              color: descriptionColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 28),
                                  const BottomButton(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class BottomButton extends StatelessWidget {
  const BottomButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: MediaQuery.of(context).size.width - 40,
        child: Column(
          children: [
            ButtonWidget(
              buttonText: 'Usar minha localização atual',
              fontSize: 14.5,
              icon: Icons.my_location,
              onPressed: () async {
                Get.find<LocationController>().checkPermission().then(
                  (permission) {
                    if (permission) {
                      Get.dialog(
                        const LoaderWidget(),
                        barrierDismissible: false,
                      );

                      Get.find<LocationController>().getCurrentLocation().then(
                        (value) {
                          Get.back();

                          if (value.latitude != 0 && value.longitude != 0) {
                            if (Get.find<AuthController>().isLoggedIn()) {
                              Get.find<OutOfZoneController>().getZoneList();
                              Get.offAll(() => const DashboardScreen());
                            } else {
                              LoginHelper.checkLoginMedium();
                            }
                          }
                        },
                      );
                    }
                  },
                );
              },
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),
          ],
        ),
      ),
    );
  }
}
