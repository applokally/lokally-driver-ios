import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:ride_sharing_user_app/common_widgets/expandable_bottom_sheet.dart';
import 'package:ride_sharing_user_app/features/dashboard/screens/dashboard_screen.dart';
import 'package:ride_sharing_user_app/features/location/controllers/location_controller.dart';
import 'package:ride_sharing_user_app/features/map/controllers/map_controller.dart';
import 'package:ride_sharing_user_app/features/map/widgets/custom_icon_card_widget.dart';
import 'package:ride_sharing_user_app/features/map/widgets/driver_header_info_widget.dart';
import 'package:ride_sharing_user_app/features/map/widgets/expendale_bottom_sheet_widget.dart';
import 'package:ride_sharing_user_app/features/profile/screens/profile_screen.dart';
import 'package:ride_sharing_user_app/features/ride/controllers/ride_controller.dart';
import 'package:ride_sharing_user_app/features/ride/domain/models/trip_details_model.dart';
import 'package:ride_sharing_user_app/features/ride/screens/ride_request_list_screen.dart';
import 'package:ride_sharing_user_app/features/safety_setup/controllers/safety_alert_controller.dart';
import 'package:ride_sharing_user_app/features/safety_setup/widgets/safety_alert_bottomsheet_widget.dart';
import 'package:ride_sharing_user_app/features/splash/controllers/splash_controller.dart';
import 'package:ride_sharing_user_app/features/trip/screens/payment_received_screen.dart';
import 'package:ride_sharing_user_app/theme/theme_controller.dart';
import 'package:ride_sharing_user_app/util/app_constants.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:ride_sharing_user_app/util/images.dart';
import 'package:ride_sharing_user_app/util/styles.dart';

import '../widgets/share_location_bottom_sheet.dart';

class MapScreen extends StatefulWidget {
  final String fromScreen;

  const MapScreen({
    super.key,
    this.fromScreen = 'home',
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with WidgetsBindingObserver {
  GoogleMapController? _mapController;
  StreamSubscription<Position>? _locationSubscription;

  final GlobalKey<ExpandableBottomSheetState> key =
      GlobalKey<ExpandableBottomSheetState>();

  Marker? marker;
  LatLng? _driverCurrentLatLng;
  bool _isTryingToLoadLocation = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _findingCurrentRoute();
  }

  void _findingCurrentRoute() {
    Get.find<RideController>().updateRoute(false, notify: false);
    Get.find<RiderMapController>().setSheetHeight(
      Get.find<RiderMapController>().currentRideState == RideState.initial
          ? 300
          : 270,
      false,
    );
    Get.find<RideController>().getPendingRideRequestList(1);
    Get.find<RiderMapController>().setMarkersInitialPosition();
    getCurrentLocation();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed &&
        Get.find<RiderMapController>().currentRideState != RideState.initial) {
      _setMapCurrentRoutes();
    }

    if (state == AppLifecycleState.resumed &&
        Get.find<RiderMapController>().currentRideState == RideState.initial) {
      getCurrentLocation();
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _locationSubscription?.cancel();
    super.dispose();
  }

  Future<Uint8List> getMarker() async {
    ByteData byteData =
        await DefaultAssetBundle.of(context).load(Images.carTop);
    return byteData.buffer.asUint8List();
  }

  LatLng _getInitialCameraTarget(RideController rideController) {
    if (rideController.tripDetail != null &&
        rideController.tripDetail!.pickupCoordinates != null) {
      return LatLng(
        rideController.tripDetail!.pickupCoordinates!.coordinates![1],
        rideController.tripDetail!.pickupCoordinates!.coordinates![0],
      );
    }

    if (_driverCurrentLatLng != null) {
      return _driverCurrentLatLng!;
    }

    final LatLng controllerPosition =
        Get.find<LocationController>().initialPosition;

    if (controllerPosition.latitude != 0 && controllerPosition.longitude != 0) {
      return controllerPosition;
    }

    return const LatLng(-23.55052, -46.633308);
  }

  void updateMarkerAndCircle(Position newLocalData, Uint8List imageData) {
    LatLng latLng = LatLng(newLocalData.latitude, newLocalData.longitude);

    setState(() {
      _driverCurrentLatLng = latLng;
      marker = Marker(
        markerId: const MarkerId("driver_current_location"),
        position: latLng,
        rotation: newLocalData.heading,
        draggable: false,
        zIndexInt: 2,
        flat: true,
        anchor: const Offset(0.5, 0.5),
        icon: BitmapDescriptor.bytes(imageData),
      );
    });
  }

  Future<void> _moveCameraToDriver(Position position) async {
    final GoogleMapController? controller = _mapController;

    if (controller == null) {
      return;
    }

    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 16,
          tilt: 0,
          bearing: position.heading,
        ),
      ),
    );
  }

  Future<void> getCurrentLocation() async {
    if (_isTryingToLoadLocation) {
      return;
    }

    _isTryingToLoadLocation = true;

    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        debugPrint("Permission Denied");
        _isTryingToLoadLocation = false;
        return;
      }

      Uint8List imageData = await getMarker();

      Position location = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      updateMarkerAndCircle(location, imageData);
      await _moveCameraToDriver(location);

      await _locationSubscription?.cancel();

      _locationSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ).listen((newLocalData) {
        updateMarkerAndCircle(newLocalData, imageData);

        if (_mapController != null &&
            Get.find<RiderMapController>().currentRideState ==
                RideState.initial) {
          _mapController!.moveCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                bearing: newLocalData.heading,
                target: LatLng(
                  newLocalData.latitude,
                  newLocalData.longitude,
                ),
                tilt: 0,
                zoom: 16,
              ),
            ),
          );
        }
      });
    } on PlatformException catch (e) {
      if (e.code == 'PERMISSION_DENIED') {
        debugPrint("Permission Denied");
      }
    } catch (e) {
      debugPrint("Erro ao carregar localização do motorista: $e");
    }

    _isTryingToLoadLocation = false;
  }

  Set<Marker> _resolveMarkers(RiderMapController riderMapController) {
    final Set<Marker> markers = Set<Marker>.of(riderMapController.markers);

    if (marker != null) {
      markers.add(marker!);
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: PopScope(
        canPop: Navigator.canPop(context),
        onPopInvokedWithResult: (res, val) {
          if (res) {
            Get.find<RideController>().getOngoingParcelList();
            Get.find<RideController>().ongoingTripList();
            Get.find<RideController>().updateRoute(true, notify: true);
          } else {
            Get.offAll(() => const DashboardScreen());
          }
        },
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          body: GetBuilder<RiderMapController>(
            builder: (riderMapController) {
              return GetBuilder<RideController>(
                builder: (rideController) {
                  return ExpandableBottomSheet(
                    key: key,
                    persistentContentHeight: riderMapController.sheetHeight,
                    background: GetBuilder<RideController>(
                      builder: (rideController) {
                        return Stack(
                          children: [
                            Padding(
                              padding: EdgeInsets.only(
                                bottom: riderMapController.sheetHeight -
                                    (Get.find<RiderMapController>()
                                                .currentRideState ==
                                            RideState.initial
                                        ? 80
                                        : 20),
                              ),
                              child: GoogleMap(
                                style: Get.isDarkMode
                                    ? Get.find<ThemeController>().darkMap
                                    : Get.find<ThemeController>().lightMap,
                                initialCameraPosition: CameraPosition(
                                  target: _getInitialCameraTarget(
                                    rideController,
                                  ),
                                  zoom: 16,
                                ),
                                onMapCreated:
                                    (GoogleMapController controller) async {
                                  riderMapController.mapController = controller;
                                  _mapController = controller;

                                  if (riderMapController
                                          .currentRideState.name !=
                                      'initial') {
                                    if (riderMapController
                                                .currentRideState.name ==
                                            'accepted' ||
                                        riderMapController
                                                .currentRideState.name ==
                                            AppConstants.ongoing) {
                                      Get.find<RideController>()
                                          .remainingDistance(
                                        Get.find<RideController>()
                                            .tripDetail!
                                            .id!,
                                        mapBound: true,
                                      );
                                    } else {
                                      riderMapController
                                          .getPickupToDestinationPolyline();
                                    }
                                  } else {
                                    await getCurrentLocation();
                                  }

                                  if (_driverCurrentLatLng != null) {
                                    await controller.animateCamera(
                                      CameraUpdate.newCameraPosition(
                                        CameraPosition(
                                          target: _driverCurrentLatLng!,
                                          zoom: 16,
                                        ),
                                      ),
                                    );
                                  }
                                },
                                onCameraMove:
                                    (CameraPosition cameraPosition) {},
                                onCameraIdle: () {},
                                minMaxZoomPreference:
                                    const MinMaxZoomPreference(
                                  0,
                                  AppConstants.mapZoom,
                                ),
                                markers: _resolveMarkers(riderMapController),
                                polylines: riderMapController.polylines,
                                zoomControlsEnabled: false,
                                compassEnabled: false,
                                trafficEnabled:
                                    riderMapController.isTrafficEnable,
                                indoorViewEnabled: true,
                                mapToolbarEnabled: true,
                                myLocationEnabled: true,
                                myLocationButtonEnabled: false,
                              ),
                            ),
                            InkWell(
                              onTap: () => Get.to(const ProfileScreen()),
                              child: const DriverHeaderInfoWidget(),
                            ),
                            Positioned(
                              bottom: Get.width * 0.87,
                              right: 0,
                              child: Align(
                                alignment: Alignment.bottomRight,
                                child: GetBuilder<LocationController>(
                                  builder: (locationController) {
                                    return CustomIconCardWidget(
                                      title: '',
                                      icon: riderMapController.isTrafficEnable
                                          ? Images.trafficOnlineIcon
                                          : Images.trafficOfflineIcon,
                                      iconColor:
                                          riderMapController.isTrafficEnable
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .secondaryContainer
                                              : Theme.of(context).hintColor,
                                      onTap: () => riderMapController
                                          .toggleTrafficView(),
                                    );
                                  },
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: Get.width * 0.73,
                              right: 0,
                              child: Align(
                                alignment: Alignment.bottomRight,
                                child: GetBuilder<LocationController>(
                                  builder: (locationController) {
                                    return CustomIconCardWidget(
                                      iconColor: Theme.of(context).primaryColor,
                                      title: '',
                                      icon: Images.currentLocation,
                                      onTap: () async {
                                        await getCurrentLocation();
                                      },
                                    );
                                  },
                                ),
                              ),
                            ),
                            Positioned(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: GestureDetector(
                                  onTap: () {
                                    Get.find<RideController>().updateRoute(
                                      true,
                                      notify: true,
                                    );
                                    Get.off(() => const DashboardScreen());
                                  },
                                  onHorizontalDragEnd:
                                      (DragEndDetails details) {
                                    _onHorizontalDrag(details);
                                    Get.find<RideController>().updateRoute(
                                      true,
                                      notify: true,
                                    );
                                    Get.off(() => const DashboardScreen());
                                  },
                                  child: Stack(
                                    children: [
                                      SizedBox(
                                        width: Dimensions.iconSizeExtraLarge,
                                        child: Image.asset(
                                          Images.mapToHomeIcon,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                      ),
                                      Positioned(
                                        top: 0,
                                        bottom: 0,
                                        left: 5,
                                        right: 5,
                                        child: SizedBox(
                                          width: 15,
                                          child: Image.asset(
                                            Images.homeSmallIcon,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .shadow,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            if (_isLocationShareEnable())
                              Positioned(
                                bottom: Get.height * 0.46,
                                right: 0,
                                child: Align(
                                  alignment: Alignment.bottomRight,
                                  child: CustomIconCardWidget(
                                    icon: Images.shareLocation,
                                    onTap: () {
                                      showModalBottomSheet(
                                        context: context,
                                        backgroundColor:
                                            Theme.of(context).cardColor,
                                        isScrollControlled: true,
                                        builder: (context) =>
                                            const ShareLocationBottomSheet(),
                                      );
                                    },
                                    title: '',
                                  ),
                                ),
                              ),
                            if (_isSafetyFeatureActive())
                              Positioned(
                                bottom: _isLocationShareEnable()
                                    ? Get.height * 0.52
                                    : Get.height * 0.46,
                                right: 0,
                                child: Align(
                                  alignment: Alignment.bottomRight,
                                  child: JustTheTooltip(
                                    backgroundColor: Get.isDarkMode
                                        ? Theme.of(context).primaryColor
                                        : Theme.of(context)
                                            .textTheme
                                            .bodyMedium!
                                            .color,
                                    controller:
                                        rideController.justTheController,
                                    preferredDirection: AxisDirection.right,
                                    tailLength: 10,
                                    tailBaseWidth: 20,
                                    content: Container(
                                      width: 130,
                                      padding: const EdgeInsets.all(
                                        Dimensions.paddingSizeSmall,
                                      ),
                                      child: Text(
                                        'safety_alert_sent'.tr,
                                        style: textRegular.copyWith(
                                          color: Colors.white,
                                          fontSize: Dimensions.fontSizeSmall,
                                        ),
                                      ),
                                    ),
                                    child: GetBuilder<SafetyAlertController>(
                                      builder: (safetyAlertController) {
                                        return CustomIconCardWidget(
                                          title: '',
                                          icon: safetyAlertController
                                                      .currentState ==
                                                  SafetyAlertState
                                                      .afterSendAlert
                                              ? Images.shieldCheckIcon
                                              : Images.safelyShieldIcon2,
                                          backGroundColor: safetyAlertController
                                                      .currentState ==
                                                  SafetyAlertState
                                                      .afterSendAlert
                                              ? Colors.red
                                              : null,
                                          onTap: () {
                                            Get.bottomSheet(
                                              isScrollControlled: true,
                                              const SafetyAlertBottomSheetWidget(),
                                              backgroundColor:
                                                  Theme.of(context).cardColor,
                                              isDismissible: false,
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    persistentHeader: SizedBox(
                      height: 50,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: GetBuilder<RideController>(
                              builder: (rideController) {
                                final int totalRequests = rideController
                                        .pendingRideRequestModel?.totalSize ??
                                    0;

                                return InkWell(
                                  onTap: () =>
                                      Get.to(() => const RideRequestScreen()),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).primaryColor,
                                      borderRadius: BorderRadius.circular(
                                        Dimensions.paddingSizeExtraLarge,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal:
                                            Dimensions.paddingSizeDefault,
                                        vertical: Dimensions.paddingSizeSmall,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SizedBox(
                                            height: Dimensions.iconSizeSmall,
                                            child:
                                                Image.asset(Images.reqListIcon),
                                          ),
                                          const SizedBox(
                                            width: Dimensions.paddingSizeSmall,
                                          ),
                                          Text(
                                            '$totalRequests ${'more_request'.tr}',
                                            style: textRegular.copyWith(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    expandableContent: Builder(
                      builder: (context) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            RiderBottomSheetWidget(expandableKey: key),
                            SizedBox(
                              height: MediaQuery.of(context).viewInsets.bottom,
                            ),
                          ],
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _onHorizontalDrag(DragEndDetails details) {
    if (details.primaryVelocity == 0) {
      return;
    }

    if (details.primaryVelocity!.compareTo(0) == -1) {
    } else {}
  }

  void _setMapCurrentRoutes() async {
    await Get.find<RideController>().getRideDetails(
      Get.find<RideController>().tripDetail?.id ?? '',
    );

    TripDetail? tripDetail = Get.find<RideController>().tripDetail;

    if (tripDetail?.currentStatus == AppConstants.accepted ||
        tripDetail?.currentStatus == AppConstants.outForPickup) {
      if (tripDetail?.currentStatus == AppConstants.outForPickup) {
        Get.find<RiderMapController>().setRideCurrentState(
          RideState.outForPickup,
        );
      } else {
        Get.find<RiderMapController>().setRideCurrentState(
          RideState.accepted,
        );
      }

      Get.find<RideController>().updateRoute(false, notify: true);
      Get.find<RiderMapController>().setMarkersInitialPosition();
    } else if (tripDetail?.currentStatus == AppConstants.ongoing) {
      Get.find<RiderMapController>().setRideCurrentState(RideState.ongoing);
      Get.find<RideController>().updateRoute(false, notify: true);
      Get.find<RiderMapController>().setMarkersInitialPosition();
    } else if (tripDetail?.currentStatus == AppConstants.completed &&
        tripDetail?.paymentStatus == AppConstants.unPaid) {
      Get.find<RideController>().getFinalFare(tripDetail!.id!);
      Get.offAll(() => const PaymentReceivedScreen());
    } else if (tripDetail?.currentStatus == AppConstants.cancelled) {
      Get.offAll(() => const DashboardScreen());
    }
  }

  bool _isSafetyFeatureActive() {
    return (Get.find<SplashController>().config?.safetyFeatureStatus ??
                false) &&
            (Get.find<RiderMapController>().currentRideState.name ==
                AppConstants.ongoing) &&
            Get.find<RideController>().tripDetail?.type != AppConstants.parcel
        ? true
        : false;
  }

  bool _isLocationShareEnable() {
    return Get.find<RideController>().tripDetail?.currentStatus ==
            AppConstants.ongoing &&
        (Get.find<SplashController>().config?.isRealTimeLocationShareEnable ??
            false) &&
        Get.find<RideController>().tripDetail?.driverLocationUrl != null;
  }
}
