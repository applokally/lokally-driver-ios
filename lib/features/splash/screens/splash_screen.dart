import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/features/trip/controllers/trip_controller.dart';
import 'package:ride_sharing_user_app/features/wallet/controllers/wallet_controller.dart';
import 'package:ride_sharing_user_app/helper/login_helper.dart';
import 'package:ride_sharing_user_app/helper/notification_helper.dart';
import 'package:ride_sharing_user_app/util/images.dart';
import 'package:ride_sharing_user_app/features/auth/controllers/auth_controller.dart';
import 'package:ride_sharing_user_app/features/location/controllers/location_controller.dart';
import 'package:ride_sharing_user_app/features/profile/controllers/profile_controller.dart';
import 'package:ride_sharing_user_app/features/ride/controllers/ride_controller.dart';
import 'package:ride_sharing_user_app/features/splash/controllers/splash_controller.dart';

class SplashScreen extends StatefulWidget {
  final Map<String, dynamic>? notificationData;

  const SplashScreen({super.key, this.notificationData});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  StreamSubscription<List<ConnectivityResult>>? _onConnectivityChanged;
  Timer? _connectionLossDebounce;
  late AnimationController _controller;
  late Animation _animation;
  bool _initialNotificationHandled = false;
  bool? _lastKnownNetworkState;
  bool _offlineSnackBarVisible = false;

  @override
  void initState() {
    super.initState();

    if (!GetPlatform.isIOS) {
      _checkConnectivity();
    }

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _animation = Tween(begin: 0.0, end: 1.0).animate(_controller)
      ..addListener(() {
        setState(() {});
      });

    _controller.forward();

    Get.find<SplashController>().initSharedData();
    Get.find<TripController>().rideCancellationReasonList();
    Get.find<TripController>().parcelCancellationReasonList();
    Get.find<AuthController>().remainingTime();
    Get.find<WalletController>().getPaymentGetWayList();

    LoginHelper().handleIncomingLinks(widget.notificationData);
    _handleInitialNotification();
  }

  void _handleInitialNotification() {
    final Map<String, dynamic>? data = widget.notificationData;
    final String action = data?['action']?.toString().trim() ?? '';

    if (_initialNotificationHandled ||
        data == null ||
        data.isEmpty ||
        action.isEmpty) {
      return;
    }

    _initialNotificationHandled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 350));

      if (!mounted) {
        return;
      }

      await NotificationHelper.notificationToRoute(
        data,
        formSplash: true,
      );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _onConnectivityChanged?.cancel();
    _connectionLossDebounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkConnectivity() async {
    final Connectivity connectivity = Connectivity();

    try {
      final List<ConnectivityResult> initialResult =
          await connectivity.checkConnectivity();
      _lastKnownNetworkState = _hasNetworkTransport(initialResult);
    } catch (_) {
      _lastKnownNetworkState = null;
    }

    if (!mounted) {
      return;
    }

    _onConnectivityChanged = connectivity.onConnectivityChanged.listen(
      _handleConnectivityChange,
    );
  }

  void _handleConnectivityChange(List<ConnectivityResult> result) {
    final bool hasNetworkTransport = _hasNetworkTransport(result);
    final bool? previousNetworkState = _lastKnownNetworkState;

    _lastKnownNetworkState = hasNetworkTransport;

    if (hasNetworkTransport) {
      _connectionLossDebounce?.cancel();

      if (_offlineSnackBarVisible) {
        _offlineSnackBarVisible = false;
        _showConnectivitySnackBar(isConnected: true);
      }

      LoginHelper().handleIncomingLinks(widget.notificationData);
      return;
    }

    if (previousNetworkState == true) {
      _scheduleConnectionLossCheck();
    }
  }

  bool _hasNetworkTransport(List<ConnectivityResult> result) {
    return result.any(
      (ConnectivityResult item) => item != ConnectivityResult.none,
    );
  }

  void _scheduleConnectionLossCheck() {
    _connectionLossDebounce?.cancel();

    _connectionLossDebounce = Timer(
      const Duration(seconds: 3),
      () async {
        try {
          final List<ConnectivityResult> currentResult =
              await Connectivity().checkConnectivity();

          if (_hasNetworkTransport(currentResult)) {
            _lastKnownNetworkState = true;
            return;
          }
        } catch (_) {
          return;
        }

        if (!mounted) {
          return;
        }

        _lastKnownNetworkState = false;
        _offlineSnackBarVisible = true;
        _showConnectivitySnackBar(isConnected: false);
      },
    );
  }

  void _showConnectivitySnackBar({required bool isConnected}) {
    if (!mounted) {
      return;
    }

    final ScaffoldMessengerState? scaffoldMessenger =
        ScaffoldMessenger.maybeOf(context);

    if (scaffoldMessenger == null) {
      return;
    }

    scaffoldMessenger.hideCurrentSnackBar();
    scaffoldMessenger.showSnackBar(
      SnackBar(
        backgroundColor: isConnected ? Colors.green : Colors.red,
        duration: Duration(seconds: isConnected ? 3 : 6),
        content: Text(
          isConnected ? 'connected'.tr : 'no_connection'.tr,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GetBuilder<RideController>(
        builder: (rideController) {
          return GetBuilder<ProfileController>(
            builder: (profileController) {
              return GetBuilder<LocationController>(
                builder: (locationController) {
                  return Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColorDark,
                        ),
                        alignment: Alignment.bottomCenter,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Stack(
                              alignment: AlignmentDirectional.bottomCenter,
                              children: [
                                Container(
                                  transform: Matrix4.translationValues(
                                    0,
                                    320 -
                                        (320 *
                                            double.tryParse(
                                              _animation.value.toString(),
                                            )!),
                                    0,
                                  ),
                                  child: Column(
                                    children: [
                                      Opacity(
                                        opacity: _animation.value,
                                        child: Padding(
                                          padding: EdgeInsets.only(
                                            left: 120 -
                                                (120 *
                                                    double.tryParse(
                                                      _animation.value
                                                          .toString(),
                                                    )!),
                                          ),
                                          child: Image.asset(
                                            Images.splashLogo,
                                            width: 160,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 50),
                                      Image.asset(
                                        Images.splashBackgroundOne,
                                        width: Get.width,
                                        height: Get.height / 2,
                                        fit: BoxFit.cover,
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  transform:
                                      Matrix4.translationValues(0, 20, 0),
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 70 *
                                          double.tryParse(
                                            _animation.value.toString(),
                                          )!,
                                    ),
                                    child: Image.asset(
                                      Images.splashBackgroundTwo,
                                      width: Get.size.width,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
