import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/common_widgets/expandable_bottom_sheet.dart';
import 'package:ride_sharing_user_app/common_widgets/loader_widget.dart';
import 'package:ride_sharing_user_app/features/dashboard/screens/dashboard_screen.dart';
import 'package:ride_sharing_user_app/features/map/controllers/map_controller.dart';
import 'package:ride_sharing_user_app/features/map/widgets/accepted_ride_widget.dart';
import 'package:ride_sharing_user_app/features/map/widgets/calculating_sub_total_widget.dart';
import 'package:ride_sharing_user_app/features/map/widgets/customer_ride_request_card_widget.dart';
import 'package:ride_sharing_user_app/features/map/widgets/out_for_pickup_widget.dart';
import 'package:ride_sharing_user_app/features/profile/controllers/profile_controller.dart';
import 'package:ride_sharing_user_app/features/ride/controllers/ride_controller.dart';
import 'package:ride_sharing_user_app/features/ride/screens/ride_request_list_screen.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:ride_sharing_user_app/util/images.dart';

import 'ride_ongoing_widget.dart';
import 'stay_online_widget.dart';

class RiderBottomSheetWidget extends StatelessWidget {
  final GlobalKey<ExpandableBottomSheetState> expandableKey;

  const RiderBottomSheetWidget({
    super.key,
    required this.expandableKey,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<RiderMapController>(builder: (mapController) {
      return GetBuilder<RideController>(builder: (rideController) {
        return GetBuilder<ProfileController>(builder: (profileController) {
          return Container(
            width: MediaQuery.of(context).size.width,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(Dimensions.paddingSizeDefault),
                topRight: Radius.circular(Dimensions.paddingSizeDefault),
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).hintColor,
                  blurRadius: 5,
                  spreadRadius: 1,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: Dimensions.paddingSizeDefault,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 5,
                    width: 30,
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).hintColor.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(
                        Dimensions.paddingSizeExtraSmall,
                      ),
                    ),
                  ),
                  if (mapController.currentRideState == RideState.initial)
                    const StayOnlineWidget(),
                  if (mapController.currentRideState == RideState.pending)
                    CustomerRideRequestCardWidget(
                      rideRequest: rideController.tripDetail!,
                    ),
                  if (mapController.currentRideState == RideState.accepted)
                    AcceptedRiderWidget(expandableKey: expandableKey),
                  if (mapController.currentRideState == RideState.outForPickup)
                    OutForPickupWidget(expandableKey: expandableKey),
                  if (mapController.currentRideState == RideState.ongoing)
                    RideOngoingWidget(
                      tripId: rideController.tripDetail?.id ?? '',
                      expandableKey: expandableKey,
                    ),
                  if (mapController.currentRideState == RideState.completed)
                    const CalculatingSubTotalWidget(),
                  if (mapController.currentRideState == RideState.initial)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        Dimensions.paddingSizeDefault,
                        Dimensions.paddingSizeSmall,
                        Dimensions.paddingSizeDefault,
                        Dimensions.paddingSizeDefault,
                      ),
                      child: Row(
                        children: [
                          _MapQuickAction(
                            title: 'Voltar',
                            semanticLabel: 'Voltar',
                            icon: Icon(
                              Icons.arrow_back_rounded,
                              size: 27,
                              color: Theme.of(context).primaryColor,
                            ),
                            onTap: () {
                              Get.find<RideController>().updateRoute(
                                true,
                                notify: true,
                              );
                              Get.off(() => const DashboardScreen());
                            },
                          ),
                          _MapQuickAction(
                            title: 'Atualizar',
                            semanticLabel: 'Atualizar',
                            icon: rideController.isLoading
                                ? const SizedBox(
                                    height: 26,
                                    width: 26,
                                    child: LoaderWidget(),
                                  )
                                : Image.asset(
                                    Images.mIcon3,
                                    width: 27,
                                    height: 27,
                                    fit: BoxFit.contain,
                                  ),
                            onTap: rideController.isLoading
                                ? null
                                : () {
                                    rideController.getPendingRideRequestList(
                                      1,
                                      isUpdate: true,
                                    );
                                  },
                          ),
                          _MapQuickAction(
                            title: 'Solicitação',
                            semanticLabel: 'Solicitação de viagem',
                            icon: Image.asset(
                              Images.mIcon1,
                              width: 27,
                              height: 27,
                              fit: BoxFit.contain,
                            ),
                            onTap: () => Get.to(
                              () => const RideRequestScreen(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                ],
              ),
            ),
          );
        });
      });
    });
  }
}

class _MapQuickAction extends StatelessWidget {
  final String title;
  final String semanticLabel;
  final Widget icon;
  final VoidCallback? onTap;

  const _MapQuickAction({
    required this.title,
    required this.semanticLabel,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color textColor = Theme.of(context)
            .textTheme
            .bodyMedium
            ?.color
            ?.withValues(alpha: 0.78) ??
        Theme.of(context).hintColor;

    return Expanded(
      child: Semantics(
        button: true,
        label: semanticLabel,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            child: SizedBox(
              height: 66,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 30,
                    child: Center(child: icon),
                  ),
                  const SizedBox(height: 9),
                  SizedBox(
                    height: 18,
                    child: Center(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: textColor,
                              fontSize: Dimensions.fontSizeDefault,
                              height: 1,
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
