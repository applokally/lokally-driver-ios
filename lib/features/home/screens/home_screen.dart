import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:ride_sharing_user_app/features/face_verification/controllers/face_verification_controller.dart';
import 'package:ride_sharing_user_app/features/face_verification/widgets/home_face_verification_warning_widget.dart';
import 'package:ride_sharing_user_app/features/home/screens/ride_list_screen.dart';
import 'package:ride_sharing_user_app/features/home/widgets/home_referral_view_widget.dart';
import 'package:ride_sharing_user_app/features/home/widgets/refund_alert_bottomsheet.dart';
import 'package:ride_sharing_user_app/features/notification/widgets/notification_shimmer_widget.dart';
import 'package:ride_sharing_user_app/features/out_of_zone/controllers/out_of_zone_controller.dart';
import 'package:ride_sharing_user_app/features/out_of_zone/screens/out_of_zone_map_screen.dart';
import 'package:ride_sharing_user_app/features/profile/controllers/profile_controller.dart';
import 'package:ride_sharing_user_app/features/profile/screens/profile_screen.dart';
import 'package:ride_sharing_user_app/features/splash/controllers/splash_controller.dart';
import 'package:ride_sharing_user_app/features/wallet/widgets/cash_in_hand_warning_widget.dart';
import 'package:ride_sharing_user_app/helper/home_screen_helper.dart';
import 'package:ride_sharing_user_app/localization/localization_controller.dart';
import 'package:ride_sharing_user_app/util/app_constants.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:ride_sharing_user_app/util/images.dart';
import 'package:ride_sharing_user_app/features/home/widgets/add_vehicle_design_widget.dart';
import 'package:ride_sharing_user_app/features/home/widgets/my_activity_list_view_widget.dart';
import 'package:ride_sharing_user_app/features/home/screens/parcel_list_screen.dart';
import 'package:ride_sharing_user_app/features/home/widgets/ongoing_ride_card_widget.dart';
import 'package:ride_sharing_user_app/features/home/widgets/profile_info_card_widget.dart';
import 'package:ride_sharing_user_app/features/home/widgets/vehicle_pending_widget.dart';
import 'package:ride_sharing_user_app/features/profile/screens/profile_menu_screen.dart';
import 'package:ride_sharing_user_app/features/ride/controllers/ride_controller.dart';
import 'package:ride_sharing_user_app/common_widgets/app_bar_widget.dart';
import 'package:ride_sharing_user_app/common_widgets/sliver_delegate.dart';
import 'package:ride_sharing_user_app/common_widgets/zoom_drawer_context_widget.dart';
import 'package:ride_sharing_user_app/util/styles.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeMenu extends GetView<ProfileController> {
  const HomeMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfileController>(
      builder: (controller) => ZoomDrawer(
        controller: controller.zoomDrawerController,
        menuScreen: const ProfileMenuScreen(),
        mainScreen: const HomeScreen(),
        borderRadius: 24.0,
        isRtl: !Get.find<LocalizationController>().isLtr,
        angle: -5.0,
        menuBackgroundColor: Theme.of(context).primaryColor,
        slideWidth: MediaQuery.of(context).size.width * 0.85,
        mainScreenScale: .4,
        mainScreenTapClose: true,
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  JustTheController rideShareToolTip = JustTheController();
  JustTheController parcelDeliveryToolTip = JustTheController();
  final ScrollController _scrollController = ScrollController();
  bool _isShowRideIcon = true;

  @override
  void initState() {
    _scrollController.addListener(() {
      if (_scrollController.offset > 20) {
        setState(() {
          _isShowRideIcon = false;
        });
      } else {
        setState(() {
          _isShowRideIcon = true;
        });
      }
    });

    loadData();

    super.initState();
  }

  @override
  void dispose() {
    rideShareToolTip.dispose();
    parcelDeliveryToolTip.dispose();
    _scrollController.dispose();

    super.dispose();
  }

  Future<void> loadData() async {
    final RideController rideController = Get.find<RideController>();

    Get.find<ProfileController>().getCategoryList(1);
    Get.find<ProfileController>().getProfileInfo();
    Get.find<ProfileController>().getDailyLog();
    rideController.getLastRideDetail();
    HomeScreenHelper().checkAndShowBottomSheets();
    await loadOngoingList();

    Get.find<ProfileController>().getProfileLevelInfo();

    if (rideController.ongoingRideList != null) {
      HomeScreenHelper().ongoingLastRidePusherImplementation();
    }

    if (rideController.parcelListModel?.data != null) {
      HomeScreenHelper().ongoingParcelListPusherImplementation();
    }

    await rideController.getPendingRideRequestList(1, limit: 100);

    if (rideController.getPendingRideRequestModel != null) {
      HomeScreenHelper().pendingListPusherImplementation();
    }

    HomeScreenHelper().checkMaintanenceMode();
  }

  Future loadOngoingList() async {
    final RideController rideController = Get.find<RideController>();
    final SplashController splashController = Get.find<SplashController>();

    await rideController.getOngoingParcelList();
    await rideController.ongoingTripList();

    Map<String, dynamic>? lastRefundData = splashController.getLastRefundData();

    bool isShowBottomSheet =
        ((rideController.ongoingRideList?.length ?? 0) == 0) &&
            ((rideController.parcelListModel?.totalSize ?? 0) == 0) &&
            lastRefundData != null;

    if (isShowBottomSheet) {
      await showModalBottomSheet(
        context: Get.context!,
        builder: (ctx) => RefundAlertBottomSheet(
          title: lastRefundData['title'],
          description: lastRefundData['body'],
          tripId: lastRefundData['ride_request_id'],
        ),
      );

      splashController.addLastReFoundData(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: Theme.of(context).primaryColor,
      onRefresh: () async {
        Get.find<ProfileController>().getProfileInfo();
      },
      child: Scaffold(
        body: Stack(
          children: [
            CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: SliverDelegate(
                    height: GetPlatform.isIOS ? 150 : 120,
                    child: Column(
                      children: [
                        AppBarWidget(
                          title: 'dashboard'.tr,
                          showBackButton: false,
                          onTap: () {
                            Get.find<ProfileController>().toggleDrawer();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: GetBuilder<ProfileController>(
                    builder: (profileController) {
                      return profileController.profileInfo != null
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 60.0),
                                const DriverHomeBannerCarousel(),
                                if (profileController.profileInfo?.vehicle !=
                                        null &&
                                    profileController.profileInfo?.vehicle
                                            ?.vehicleRequestStatus ==
                                        'approved')
                                  GetBuilder<RideController>(
                                    builder: (rideController) {
                                      return const OngoingRideCardWidget();
                                    },
                                  ),
                                if (profileController.profileInfo?.vehicle ==
                                    null)
                                  const AddYourVehicleWidget(),
                                GetBuilder<OutOfZoneController>(
                                  builder: (outOfZoneController) {
                                    return outOfZoneController.isDriverOutOfZone
                                        ? InkWell(
                                            onTap: () => Get.to(
                                              () => const OutOfZoneMapScreen(),
                                            ),
                                            child: Container(
                                              padding: const EdgeInsets.all(
                                                Dimensions.paddingSizeSmall,
                                              ),
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                vertical:
                                                    Dimensions.paddingSizeSmall,
                                                horizontal: Dimensions
                                                    .paddingSizeDefault,
                                              ),
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                  Dimensions.radiusDefault,
                                                ),
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .tertiaryContainer
                                                    .withValues(alpha: 0.1),
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.warning,
                                                        size: 24,
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .error,
                                                      ),
                                                      const SizedBox(
                                                        width: Dimensions
                                                            .paddingSizeDefault,
                                                      ),
                                                      Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            'you_are_out_of_zone'
                                                                .tr,
                                                            style: textBold
                                                                .copyWith(
                                                              fontSize: Dimensions
                                                                  .fontSizeSmall,
                                                            ),
                                                          ),
                                                          Text(
                                                            'to_get_request_must'
                                                                .tr,
                                                            style: textRegular
                                                                .copyWith(
                                                              fontSize: 10,
                                                              color: Theme.of(
                                                                      context)
                                                                  .primaryColor,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                  Image.asset(
                                                    Images.homeOutOfZoneIcon,
                                                    height: 30,
                                                    width: 30,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          )
                                        : const SizedBox();
                                  },
                                ),
                                if (profileController.profileInfo?.vehicle !=
                                        null &&
                                    (profileController.profileInfo?.vehicle
                                                ?.vehicleRequestStatus ==
                                            'pending' ||
                                        profileController.profileInfo?.vehicle
                                                ?.vehicleRequestStatus ==
                                            'denied'))
                                  VehiclePendingWidget(),
                                if ((!(profileController
                                                .profileInfo?.isVerified ??
                                            false) ||
                                        ((profileController
                                                    .profileInfo?.isSuspended ??
                                                false) &&
                                            (profileController.profileInfo
                                                    ?.suspendReason ==
                                                'face_verification')) ||
                                        (profileController.profileInfo
                                                ?.needVerification ??
                                            false)) &&
                                    (Get.find<SplashController>()
                                            .config
                                            ?.verifyDriverIdentity ??
                                        false))
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(
                                        Dimensions.paddingSizeDefault,
                                      ),
                                      color: Theme.of(context).cardColor,
                                    ),
                                    padding: EdgeInsets.all(
                                      Dimensions.paddingSizeSmall,
                                    ),
                                    margin: EdgeInsets.all(
                                      Dimensions.paddingSizeDefault,
                                    ).copyWith(bottom: 0),
                                    child: Row(
                                      children: [
                                        Image.asset(
                                          Images.nonVerificationIcon,
                                          height: 25,
                                          width: 25,
                                        ),
                                        const SizedBox(
                                          width: Dimensions.paddingSizeSmall,
                                        ),
                                        Expanded(
                                          child: Text(
                                            'verify_your_id_to_become_a_driver'
                                                .tr,
                                            style: textRegular.copyWith(
                                              color: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.color
                                                  ?.withValues(alpha: 0.7),
                                            ),
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () => Get.find<
                                                  FaceVerificationController>()
                                              .requestCameraPermission(),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                Dimensions.paddingSizeSmall,
                                              ),
                                              color: Theme.of(context)
                                                  .primaryColor,
                                            ),
                                            padding: EdgeInsets.symmetric(
                                              vertical:
                                                  Dimensions.paddingSizeSmall,
                                              horizontal:
                                                  Dimensions.paddingSizeLarge,
                                            ),
                                            child: Text(
                                              'verify'.tr,
                                              style: textRegular.copyWith(
                                                color:
                                                    Theme.of(context).cardColor,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (Get.find<ProfileController>()
                                        .profileInfo
                                        ?.vehicle !=
                                    null)
                                  const MyActivityListViewWidget(),
                                const SizedBox(
                                  height: Dimensions.paddingSizeDefault,
                                ),
                                if (Get.find<SplashController>()
                                        .config
                                        ?.referralEarningStatus ??
                                    false)
                                  const HomeReferralViewWidget(),
                                const SizedBox(height: 100),
                              ],
                            )
                          : const NotificationShimmerWidget();
                    },
                  ),
                ),
              ],
            ),
            GetBuilder<ProfileController>(
              builder: (profileController) {
                return profileController.isCashInHandHoldAccount
                    ? CashInHandWarningWidget()
                    : (profileController.profileInfo?.isSuspended ?? false)
                        ? HomeFaceVerificationWarningWidget()
                        : const SizedBox();
              },
            ),
            Positioned(
              top: GetPlatform.isIOS ? 120 : 90,
              left: 0,
              right: 0,
              child: GetBuilder<ProfileController>(
                builder: (profileController) {
                  return GestureDetector(
                    onTap: () {
                      Get.to(() => const ProfileScreen());
                    },
                    child: ProfileStatusCardWidget(
                      profileController: profileController,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: GetBuilder<RideController>(
          builder: (rideController) {
            int ridingCount = rideController.ongoingRideList?.length ?? 0;
            int parcelCount = rideController.parcelListModel?.totalSize ?? 0;

            if (Get.find<SplashController>().isShowToolTips) {
              showToolTips(ridingCount, parcelCount);
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                parcelCount > 0 && _isShowRideIcon
                    ? Padding(
                        padding: EdgeInsets.only(
                          bottom: (ridingCount == 0) ? Get.height * 0.08 : 0,
                        ),
                        child: JustTheTooltip(
                          backgroundColor: Get.isDarkMode
                              ? Theme.of(context).primaryColor
                              : Theme.of(context).textTheme.bodyMedium!.color,
                          controller: parcelDeliveryToolTip,
                          preferredDirection: AxisDirection.right,
                          tailLength: 10,
                          tailBaseWidth: 20,
                          content: Container(
                            width: 150,
                            padding: const EdgeInsets.all(
                              Dimensions.paddingSizeSmall,
                            ),
                            child: Text(
                              'parcel_delivery'.tr,
                              style: textRegular.copyWith(
                                color: Colors.white,
                                fontSize: Dimensions.fontSizeDefault,
                              ),
                            ),
                          ),
                          child: InkWell(
                            onTap: () => Get.to(
                              () => const ParcelListScreen(
                                title: 'ongoing_parcel_list',
                              ),
                            ),
                            child: Stack(
                              children: [
                                Container(
                                  height: 38,
                                  width: 38,
                                  padding: EdgeInsets.all(
                                    Dimensions.paddingSizeSmall,
                                  ),
                                  margin: EdgeInsets.all(
                                    Dimensions.paddingSizeExtraSmall,
                                  ),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  child: Image.asset(
                                    Images.parcelDeliveryIcon,
                                  ),
                                ),
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    height: 20,
                                    width: 20,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Theme.of(context).cardColor,
                                    ),
                                    child: Center(
                                      child: Container(
                                        height: 18,
                                        width: 18,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .error,
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${rideController.parcelListModel?.totalSize}',
                                            style: textRegular.copyWith(
                                              color:
                                                  Theme.of(context).cardColor,
                                              fontSize:
                                                  Dimensions.fontSizeSmall,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : const SizedBox(),
                const SizedBox(height: Dimensions.paddingSizeSmall),
                ridingCount > 0 && _isShowRideIcon
                    ? Padding(
                        padding: EdgeInsets.only(bottom: Get.height * 0.08),
                        child: JustTheTooltip(
                          backgroundColor: Get.isDarkMode
                              ? Theme.of(context).primaryColor
                              : Theme.of(context).textTheme.bodyMedium!.color,
                          controller: rideShareToolTip,
                          preferredDirection: AxisDirection.right,
                          tailLength: 10,
                          tailBaseWidth: 20,
                          content: Container(
                            width: 100,
                            padding: const EdgeInsets.all(
                              Dimensions.paddingSizeSmall,
                            ),
                            child: Text(
                              'ride_share'.tr,
                              style: textRegular.copyWith(
                                color: Colors.white,
                                fontSize: Dimensions.fontSizeDefault,
                              ),
                            ),
                          ),
                          child: InkWell(
                            onTap: () => Get.to(() => RideListScreen()),
                            child: Stack(
                              children: [
                                Container(
                                  height: 38,
                                  width: 38,
                                  padding: EdgeInsets.all(
                                    Dimensions.paddingSizeSmall,
                                  ),
                                  margin: EdgeInsets.all(
                                    Dimensions.paddingSizeExtraSmall,
                                  ),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  child: Image.asset(Images.rideShareIcon),
                                ),
                                Positioned(
                                  right: 0,
                                  top: 6,
                                  child: Container(
                                    height: 12,
                                    width: 12,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Theme.of(context).cardColor,
                                    ),
                                    child: Center(
                                      child: Container(
                                        height: 10,
                                        width: 10,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .error,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : const SizedBox(),
              ],
            );
          },
        ),
      ),
    );
  }

  void showToolTips(int ridingCount, int parcelCount) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 1)).then((_) {
        if (ridingCount > 0 && _isShowRideIcon) {
          rideShareToolTip.showTooltip();
          Get.find<SplashController>().hideToolTips();

          Future.delayed(const Duration(seconds: 5)).then((_) {
            rideShareToolTip.hideTooltip();
          });
        }

        if (parcelCount > 0 && _isShowRideIcon) {
          parcelDeliveryToolTip.showTooltip();
          Get.find<SplashController>().hideToolTips();

          Future.delayed(const Duration(seconds: 5)).then((_) {
            parcelDeliveryToolTip.hideTooltip();
          });
        }
      });
    });
  }
}

class DriverHomeBannerCarousel extends StatefulWidget {
  const DriverHomeBannerCarousel({super.key});

  @override
  State<DriverHomeBannerCarousel> createState() =>
      _DriverHomeBannerCarouselState();
}

class _DriverHomeBannerCarouselState extends State<DriverHomeBannerCarousel> {
  final PageController _pageController = PageController();
  List<_DriverBannerItem> _banners = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  Timer? _autoSlideTimer;

  @override
  void initState() {
    super.initState();
    _loadBanners();
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadBanners() async {
    try {
      final String baseUrl = AppConstants.baseUrl.endsWith('/')
          ? AppConstants.baseUrl.substring(0, AppConstants.baseUrl.length - 1)
          : AppConstants.baseUrl;

      final response = await GetConnect().get(
        '$baseUrl/api/driver/banner/list?limit=10&offset=1',
      );

      final dynamic responseBody =
          response.body is String ? jsonDecode(response.body) : response.body;

      final List<dynamic> data =
          responseBody is Map && responseBody['data'] is List
              ? responseBody['data'] as List<dynamic>
              : <dynamic>[];

      final List<_DriverBannerItem> loadedBanners = data
          .whereType<Map>()
          .map(
            (item) => _DriverBannerItem.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .where((banner) => banner.image.trim().isNotEmpty)
          .toList();

      if (!mounted) {
        return;
      }

      setState(() {
        _banners = loadedBanners;
        _isLoading = false;
      });

      _startAutoSlide();
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _banners = [];
        _isLoading = false;
      });
    }
  }

  void _startAutoSlide() {
    _autoSlideTimer?.cancel();

    if (_banners.length <= 1) {
      return;
    }

    _autoSlideTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_pageController.hasClients || _banners.isEmpty) {
        return;
      }

      final int nextIndex = (_currentIndex + 1) % _banners.length;

      _pageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _openBannerLink(_DriverBannerItem banner) async {
    final String redirectLink = banner.redirectLink.trim();

    if (redirectLink.isEmpty) {
      return;
    }

    final String normalizedLink = redirectLink.startsWith('http://') ||
            redirectLink.startsWith('https://')
        ? redirectLink
        : 'https://$redirectLink';

    final Uri? uri = Uri.tryParse(normalizedLink);

    if (uri == null) {
      return;
    }

    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 176,
        margin: const EdgeInsets.fromLTRB(
          Dimensions.paddingSizeDefault,
          0,
          Dimensions.paddingSizeDefault,
          Dimensions.paddingSizeDefault,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).hintColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        ),
      );
    }

    if (_banners.isEmpty) {
      return const SizedBox();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(
        Dimensions.paddingSizeDefault,
        0,
        Dimensions.paddingSizeDefault,
        Dimensions.paddingSizeDefault,
      ),
      child: Column(
        children: [
          SizedBox(
            height: 176,
            child: PageView.builder(
              controller: _pageController,
              itemCount: _banners.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                final _DriverBannerItem banner = _banners[index];

                return GestureDetector(
                  onTap: () => _openBannerLink(banner),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(
                        Dimensions.radiusLarge,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        Dimensions.radiusLarge,
                      ),
                      child: Image.network(
                        banner.imageUrl,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Theme.of(context)
                                .primaryColor
                                .withValues(alpha: 0.08),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              color: Theme.of(context).primaryColor,
                              size: 32,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_banners.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _banners.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    height: 6,
                    width: _currentIndex == index ? 18 : 6,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: _currentIndex == index
                          ? Theme.of(context).primaryColor
                          : Theme.of(context).hintColor.withValues(alpha: 0.28),
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DriverBannerItem {
  final String id;
  final String name;
  final String description;
  final String redirectLink;
  final String displayTo;
  final String image;

  const _DriverBannerItem({
    required this.id,
    required this.name,
    required this.description,
    required this.redirectLink,
    required this.displayTo,
    required this.image,
  });

  factory _DriverBannerItem.fromJson(Map<String, dynamic> json) {
    return _DriverBannerItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      redirectLink: json['redirect_link']?.toString() ?? '',
      displayTo: json['display_to']?.toString() ?? 'driver',
      image: json['image']?.toString() ?? '',
    );
  }

  String get imageUrl {
    final String cleanImage = image.trim();

    if (cleanImage.startsWith('http://') || cleanImage.startsWith('https://')) {
      return cleanImage;
    }

    final String baseUrl = AppConstants.baseUrl.endsWith('/')
        ? AppConstants.baseUrl.substring(0, AppConstants.baseUrl.length - 1)
        : AppConstants.baseUrl;

    return '$baseUrl/storage/promotion/banner/$cleanImage';
  }
}
