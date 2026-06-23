import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/common_widgets/app_bar_widget.dart';
import 'package:ride_sharing_user_app/common_widgets/button_widget.dart';
import 'package:ride_sharing_user_app/common_widgets/confirmation_dialog_widget.dart';
import 'package:ride_sharing_user_app/common_widgets/payment_item_info_widget.dart';
import 'package:ride_sharing_user_app/features/dashboard/screens/dashboard_screen.dart';
import 'package:ride_sharing_user_app/features/ride/controllers/ride_controller.dart';
import 'package:ride_sharing_user_app/features/trip/controllers/trip_controller.dart';
import 'package:ride_sharing_user_app/features/trip/widgets/customer_details_widget.dart';
import 'package:ride_sharing_user_app/features/trip/widgets/fare_widget.dart';
import 'package:ride_sharing_user_app/features/trip/widgets/trip_route_widget.dart';
import 'package:ride_sharing_user_app/helper/date_converter.dart';
import 'package:ride_sharing_user_app/helper/price_converter.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:ride_sharing_user_app/util/images.dart';
import 'package:ride_sharing_user_app/util/styles.dart';

class PaymentReceivedScreen extends StatefulWidget {
  final bool fromParcel;
  const PaymentReceivedScreen({super.key, this.fromParcel = false});

  @override
  State<PaymentReceivedScreen> createState() => _PaymentReceivedScreenState();
}

class _PaymentReceivedScreenState extends State<PaymentReceivedScreen>
    with WidgetsBindingObserver {
  bool canPop = false;
  Timer? _paymentStatusTimer;
  bool _isCheckingPaymentStatus = false;
  bool _paymentConfirmed = false;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startPaymentStatusWatcher();
    });
    super.initState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      _startPaymentStatusWatcher(checkImmediately: true);
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _stopPaymentStatusWatcher();
    }
  }

  @override
  void dispose() {
    _stopPaymentStatusWatcher();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _startPaymentStatusWatcher({bool checkImmediately = true}) {
    final RideController rideController = Get.find<RideController>();
    final bool isLokallyPayPayment =
        rideController.tripDetail?.isLokallyPayPayment ?? false;

    if (!isLokallyPayPayment || _paymentConfirmed) {
      return;
    }

    if (checkImmediately) {
      _checkPaymentStatus();
    }

    _paymentStatusTimer ??= Timer.periodic(const Duration(seconds: 5), (_) {
      _checkPaymentStatus();
    });
  }

  void _stopPaymentStatusWatcher() {
    _paymentStatusTimer?.cancel();
    _paymentStatusTimer = null;
  }

  Future<void> _checkPaymentStatus() async {
    if (!mounted || _isCheckingPaymentStatus || _paymentConfirmed) {
      return;
    }

    final String? tripId = Get.find<RideController>().tripDetail?.id;
    if (tripId == null || tripId.isEmpty) {
      return;
    }

    _isCheckingPaymentStatus = true;

    try {
      final response = await Get.find<RideController>().getRideDetails(tripId);

      if (!mounted || _paymentConfirmed || response.statusCode != 200) {
        return;
      }

      if (Get.find<RideController>().tripDetail?.paymentStatus == 'paid') {
        _paymentConfirmed = true;
        _stopPaymentStatusWatcher();
        Get.offAll(() => const DashboardScreen());
      }
    } finally {
      _isCheckingPaymentStatus = false;
    }
  }

  double _safeDouble(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0;
  }

  double _safeMetricDouble(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is num) {
      return value.toDouble();
    }

    String normalized =
        value.toString().trim().replaceAll(RegExp(r'[^0-9,.-]'), '');

    if (normalized.isEmpty) {
      return 0;
    }

    if (normalized.contains(',') && normalized.contains('.')) {
      if (normalized.lastIndexOf(',') > normalized.lastIndexOf('.')) {
        normalized = normalized.replaceAll('.', '').replaceAll(',', '.');
      } else {
        normalized = normalized.replaceAll(',', '');
      }
    } else {
      normalized = normalized.replaceAll(',', '.');
    }

    return double.tryParse(normalized) ?? 0;
  }

  String _formatTripDuration(dynamic actualTime) {
    final int totalSeconds = (_safeMetricDouble(actualTime) * 60).round();

    if (totalSeconds <= 0) {
      return '0 min';
    }

    final int minutes = totalSeconds ~/ 60;
    final int seconds = totalSeconds % 60;

    if (minutes == 0) {
      return '$seconds s';
    }

    if (seconds == 0) {
      return '$minutes min';
    }

    return '$minutes min $seconds s';
  }

  String _formatTripDistance(dynamic actualDistance) {
    return _safeMetricDouble(actualDistance)
        .toStringAsFixed(2)
        .replaceAll('.', ',');
  }

  double _originalFareAmount(dynamic finalFare) {
    final double paidFare = _safeDouble(finalFare?.paidFare);
    final double couponAmount = _safeDouble(finalFare?.couponAmount);
    final double discountAmount = _safeDouble(finalFare?.discountAmount);
    final double baseFare = _safeDouble(finalFare?.distanceWiseFare) +
        _safeDouble(finalFare?.idleFee) +
        _safeDouble(finalFare?.delayFee) +
        _safeDouble(finalFare?.cancellationFee) +
        _safeDouble(finalFare?.tips);

    final double discountedOriginal = paidFare + couponAmount + discountAmount;

    if (baseFare > discountedOriginal) {
      return baseFare;
    }

    return discountedOriginal;
  }

  Widget _amountRow({
    required BuildContext context,
    required String title,
    required double amount,
    required Color color,
    bool strikeThrough = false,
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeExtraSmall),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: (bold ? textSemiBold : textRegular).copyWith(
                color: color,
                fontSize: bold
                    ? Dimensions.fontSizeDefault
                    : Dimensions.fontSizeSmall,
              ),
            ),
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Text(
            PriceConverter.convertPrice(context, amount),
            textAlign: TextAlign.end,
            style: textRobotoBold.copyWith(
              color: color,
              fontSize:
                  bold ? Dimensions.fontSizeLarge : Dimensions.fontSizeDefault,
              decoration: strikeThrough
                  ? TextDecoration.lineThrough
                  : TextDecoration.none,
              decorationColor: color,
              decorationThickness: 1.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _finalChargeHighlight({
    required BuildContext context,
    required double originalAmount,
    required double finalAmount,
    required bool isLokallyPayPayment,
  }) {
    final double discountAmount =
        (originalAmount - finalAmount) > 0 ? originalAmount - finalAmount : 0;

    return Container(
      margin: const EdgeInsets.only(
        top: Dimensions.paddingSizeSmall,
        left: Dimensions.paddingSizeSmall,
        right: Dimensions.paddingSizeSmall,
      ),
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        border: Border.all(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        children: [
          _amountRow(
            context: context,
            title: 'Valor da tarifa',
            amount: originalAmount,
            color: Colors.red.shade600,
            strikeThrough: true,
          ),
          if (discountAmount > 0)
            _amountRow(
              context: context,
              title: 'Desconto aplicado',
              amount: discountAmount,
              color: Theme.of(context).colorScheme.error,
            ),
          Divider(
            color: Theme.of(context).hintColor.withValues(alpha: 0.16),
          ),
          _amountRow(
            context: context,
            title: isLokallyPayPayment
                ? 'Valor pago pelo passageiro'
                : 'Valor a cobrar do passageiro',
            amount: finalAmount,
            color: Theme.of(context).primaryColor,
            bold: true,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String displayPaymentMethod =
        Get.find<RideController>().tripDetail?.displayPaymentMethod ??
            'cash'.tr;

    final String submitPaymentMethod =
        Get.find<RideController>().tripDetail?.lokallyPaymentMethod ??
            Get.find<RideController>().tripDetail?.paymentMethod ??
            'cash';

    final bool isLokallyPayPayment =
        Get.find<RideController>().tripDetail?.isLokallyPayPayment ?? false;

    return SafeArea(
      top: false,
      child: PopScope(
        canPop: canPop,
        onPopInvokedWithResult: (willBePop, val) async {
          if (!willBePop) {
            Future.delayed(const Duration(milliseconds: 50)).then((_) {
              Get.offAll(() => const DashboardScreen());
            });
          }
        },
        child: Scaffold(
          body: SingleChildScrollView(
              child: GetBuilder<RideController>(builder: (finalFareController) {
            String firstRoute = '';
            String secondRoute = '';
            List<dynamic> extraRoute = [];
            if (finalFareController.finalFare != null) {
              if (finalFareController.finalFare!.intermediateAddresses !=
                      null &&
                  finalFareController.finalFare!.intermediateAddresses !=
                      '[[, ]]') {
                extraRoute = jsonDecode(
                    finalFareController.finalFare!.intermediateAddresses!);

                if (extraRoute.isNotEmpty) {
                  firstRoute = extraRoute[0];
                }

                if (extraRoute.isNotEmpty && extraRoute.length > 1) {
                  secondRoute = extraRoute[1];
                }
              }
            }

            String? pickUpTime = finalFareController.finalFare?.type == 'parcel'
                ? finalFareController.finalFare?.parcelStartTime
                : finalFareController.finalFare?.rideStartTime;
            String? dropOffTime =
                finalFareController.finalFare?.type == 'parcel'
                    ? finalFareController.finalFare?.parcelCompleteTime
                    : finalFareController.finalFare?.rideCompleteTime;

            final double finalAmount =
                _safeDouble(finalFareController.finalFare?.paidFare);
            final double originalAmount =
                _originalFareAmount(finalFareController.finalFare);
            final bool hasFinalReduction = originalAmount > finalAmount &&
                (originalAmount - finalAmount) > 0.009;

            return (finalFareController.finalFare != null)
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        AppBarWidget(
                          title: 'sub_total'.tr,
                          showBackButton: true,
                          onBackPressed: () =>
                              Get.offAll(() => const DashboardScreen()),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: Dimensions.paddingSizeDefault),
                          child: Container(
                            width: Get.width,
                            transform: Matrix4.translationValues(0, -30, 0),
                            decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(
                                    Dimensions.paddingSizeDefault),
                                border: Border.all(
                                    width: .5,
                                    color: Theme.of(context)
                                        .hintColor
                                        .withValues(alpha: 0.2))),
                            child: Column(children: [
                              if (hasFinalReduction)
                                _finalChargeHighlight(
                                  context: context,
                                  originalAmount: originalAmount,
                                  finalAmount: finalAmount,
                                  isLokallyPayPayment: isLokallyPayPayment,
                                ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(
                                        Dimensions.paddingSizeDefault),
                                    child: Text(
                                      hasFinalReduction
                                          ? (isLokallyPayPayment
                                              ? 'Valor pago pelo passageiro'
                                              : 'Valor a cobrar do passageiro')
                                          : 'total_trip_cost'.tr,
                                      style: textBold.copyWith(
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyMedium!
                                            .color,
                                        fontSize: Dimensions.fontSizeLarge,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(
                                        Dimensions.paddingSizeDefault),
                                    child: Text(
                                      PriceConverter.convertPrice(
                                          context, finalAmount),
                                      style: textRobotoBold.copyWith(
                                        color: Theme.of(context).primaryColor,
                                        fontSize: Dimensions.fontSizeOverLarge,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ]),
                          ),
                        ),
                        if (!widget.fromParcel)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: Dimensions.paddingSizeExtraLarge),
                            child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SummeryItem(
                                    title: _formatTripDuration(
                                        finalFareController
                                            .finalFare!.actualTime),
                                    subTitle: 'time',
                                  ),
                                  SizedBox(width: Get.width * 0.2),
                                  SummeryItem(
                                    title:
                                        '${_formatTripDistance(finalFareController.finalFare!.actualDistance)} km',
                                    subTitle: 'distance',
                                  ),
                                ]),
                          ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: Dimensions.paddingSizeDefault,
                              vertical: Dimensions.paddingSizeSmall),
                          child: Text('trip_details'.tr,
                              style: textRegular.copyWith(
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.color)),
                        ),
                        if (pickUpTime != null || dropOffTime != null)
                          Container(
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(Dimensions.radiusLarge),
                              color: Theme.of(context)
                                  .hintColor
                                  .withValues(alpha: 0.08),
                            ),
                            padding: const EdgeInsets.all(
                                Dimensions.paddingSizeSmall),
                            margin: const EdgeInsets.symmetric(
                                vertical: Dimensions.paddingSizeSmall,
                                horizontal: Dimensions.paddingSizeDefault),
                            child: Column(
                                spacing: Dimensions.paddingSizeExtraSmall,
                                children: [
                                  Center(
                                      child: Text(
                                    DateConverter.stringToLocalDateOnly(
                                        finalFareController
                                            .finalFare!.createdAt!),
                                    style: textRegular.copyWith(
                                      fontSize: Dimensions.fontSizeSmall,
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.color
                                          ?.withValues(alpha: 0.7),
                                    ),
                                  )),
                                  IntrinsicHeight(
                                    child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          if (pickUpTime != null)
                                            FareWidget(
                                                title: 'pickup_time'.tr,
                                                value: DateConverter
                                                    .stringDateTimeToTimeOnly(
                                                        pickUpTime)),
                                          if (dropOffTime != null) ...[
                                            VerticalDivider(
                                                color: Theme.of(context)
                                                    .hintColor
                                                    .withValues(alpha: 0.5)),
                                            FareWidget(
                                                title: 'drop_off_time'.tr,
                                                value: DateConverter
                                                    .stringDateTimeToTimeOnly(
                                                        dropOffTime)),
                                          ]
                                        ]),
                                  ),
                                ]),
                          ),
                        const SizedBox(height: Dimensions.paddingSizeSmall),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: Dimensions.paddingSizeDefault),
                          child: TripRouteWidget(
                            pickupAddress:
                                '${finalFareController.finalFare!.pickupAddress}',
                            destinationAddress:
                                '${finalFareController.finalFare!.destinationAddress}',
                            extraOne: firstRoute,
                            extraTwo: secondRoute,
                            entrance:
                                finalFareController.finalFare?.entrance ?? '',
                          ),
                        ),
                        const SizedBox(height: Dimensions.paddingSizeLarge),
                        CustomerDetailsWidget(
                            rideController: Get.find<RideController>()),
                        Padding(
                          padding: const EdgeInsets.all(
                                  Dimensions.paddingSizeDefault)
                              .copyWith(top: 0),
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(
                              Dimensions.paddingSizeDefault,
                              Dimensions.paddingSizeDefault,
                              Dimensions.paddingSizeDefault,
                              0,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: Theme.of(context)
                                      .hintColor
                                      .withValues(alpha: 0.2),
                                  width: 1),
                              borderRadius: BorderRadius.circular(
                                  Dimensions.paddingSizeSmall),
                            ),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        bottom: Dimensions.paddingSizeDefault),
                                    child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('payment_details'.tr,
                                              style: textSemiBold.copyWith(
                                                color: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.color,
                                              )),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal:
                                                  Dimensions.paddingSizeSmall,
                                              vertical: Dimensions
                                                  .paddingSizeExtraSmall,
                                            ),
                                            decoration: BoxDecoration(
                                                color: Theme.of(context)
                                                    .hintColor
                                                    .withValues(alpha: .1),
                                                borderRadius: BorderRadius
                                                    .circular(Dimensions
                                                        .paddingSizeExtraSmall)),
                                            child: Text(
                                              displayPaymentMethod,
                                              style: textRobotoMedium.copyWith(
                                                color: Get.isDarkMode
                                                    ? Colors.white
                                                    : Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium
                                                        ?.color,
                                              ),
                                            ),
                                          )
                                        ]),
                                  ),
                                  PaymentItemInfoWidget(
                                    icon: Images.farePrice,
                                    title: 'fare_price'.tr,
                                    amount: finalFareController
                                            .finalFare?.distanceWiseFare ??
                                        0,
                                  ),
                                  if (!widget.fromParcel &&
                                      finalFareController
                                              .finalFare!.cancellationFee!
                                              .toDouble() >
                                          0)
                                    PaymentItemInfoWidget(
                                      icon: Images.idleHourIcon,
                                      title: 'cancellation_price'.tr,
                                      amount: finalFareController
                                              .finalFare?.cancellationFee ??
                                          0,
                                    ),
                                  if (!widget.fromParcel &&
                                      finalFareController.finalFare!.idleFee!
                                              .toDouble() >
                                          0)
                                    PaymentItemInfoWidget(
                                      icon: Images.idleHourIcon,
                                      title: 'idle_price'.tr,
                                      amount: finalFareController
                                              .finalFare?.idleFee ??
                                          0,
                                    ),
                                  if (!widget.fromParcel &&
                                      finalFareController.finalFare!.delayFee!
                                              .toDouble() >
                                          0)
                                    PaymentItemInfoWidget(
                                      icon: Images.waitingPrice,
                                      title: 'delay_price'.tr,
                                      amount: finalFareController
                                              .finalFare?.delayFee ??
                                          0,
                                    ),
                                  if (finalFareController
                                          .finalFare!.couponAmount!
                                          .toDouble() >
                                      0)
                                    PaymentItemInfoWidget(
                                      icon: Images.coupon,
                                      title: 'coupon_amount'.tr,
                                      amount: finalFareController
                                              .finalFare?.couponAmount ??
                                          0,
                                      discount: true,
                                      toolTipText:
                                          'customer_applied_coupon_for_this_ride'
                                              .tr,
                                      subTitle:
                                          'later_admin_will_pay_you_this_amount',
                                    ),
                                  if (finalFareController
                                          .finalFare!.discountAmount!
                                          .toDouble() >
                                      0)
                                    PaymentItemInfoWidget(
                                      icon: Images.discountIcon,
                                      title: 'discount_applied'.tr,
                                      amount: finalFareController
                                              .finalFare?.discountAmount ??
                                          0,
                                      discount: true,
                                      toolTipText:
                                          'discount_applied_for_this_ride'.tr,
                                      subTitle:
                                          'later_admin_will_pay_you_this_amount',
                                    ),
                                  if (finalFareController.finalFare!.vatTax!
                                          .toDouble() >
                                      0)
                                    PaymentItemInfoWidget(
                                      icon: Images.farePrice,
                                      title: 'vat_tax'.tr,
                                      amount: finalFareController
                                              .finalFare?.vatTax ??
                                          0,
                                    ),
                                  Divider(
                                      color: Theme.of(context)
                                          .hintColor
                                          .withValues(alpha: 0.2)),
                                  Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                            '${'sub_total'.tr} (${'customer_will_pay'.tr})',
                                            style: textSemiBold.copyWith(
                                              color: Theme.of(context)
                                                  .primaryColor,
                                            )),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal:
                                                Dimensions.paddingSizeSmall,
                                            vertical: Dimensions
                                                .paddingSizeExtraSmall,
                                          ),
                                          decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .primaryColor
                                                  .withValues(alpha: .1),
                                              borderRadius: BorderRadius
                                                  .circular(Dimensions
                                                      .paddingSizeExtraSmall)),
                                          child: Text(
                                            PriceConverter.convertPrice(
                                                context, finalAmount),
                                            style: textRobotoBold.copyWith(
                                              color: Get.isDarkMode
                                                  ? Colors.white
                                                  : Theme.of(context)
                                                      .primaryColor,
                                            ),
                                          ),
                                        )
                                      ]),
                                  const SizedBox(
                                      height: Dimensions.paddingSizeSmall)
                                ]),
                          ),
                        ),
                      ])
                : const SizedBox();
          })),
          bottomNavigationBar:
              GetBuilder<RideController>(builder: (finalFareController) {
            final double finalAmount =
                _safeDouble(finalFareController.finalFare?.paidFare);

            return GetBuilder<TripController>(builder: (tripController) {
              if (isLokallyPayPayment) {
                return Container(
                  height: 128,
                  padding: const EdgeInsets.fromLTRB(
                    Dimensions.paddingSizeDefault,
                    Dimensions.paddingSizeDefault,
                    Dimensions.paddingSizeDefault,
                    Dimensions.paddingSizeLarge,
                  ),
                  color: Theme.of(context).cardColor,
                  child: Container(
                    padding:
                        const EdgeInsets.all(Dimensions.paddingSizeDefault),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .primaryColor
                          .withValues(alpha: 0.10),
                      borderRadius:
                          BorderRadius.circular(Dimensions.radiusLarge),
                    ),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.hourglass_bottom_rounded,
                            color: Theme.of(context).primaryColor,
                            size: 22,
                          ),
                          const SizedBox(width: Dimensions.paddingSizeSmall),
                          Expanded(
                              child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Aguardando o passageiro',
                                style: textSemiBold.copyWith(
                                  color: Theme.of(context).primaryColor,
                                  fontSize: Dimensions.fontSizeDefault,
                                ),
                              ),
                              const SizedBox(
                                  height: Dimensions.paddingSizeExtraSmall),
                              Text(
                                'Valor pago no app: ${PriceConverter.convertPrice(context, finalAmount)} • $displayPaymentMethod.',
                                style: textRegular.copyWith(
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.color,
                                  fontSize: Dimensions.fontSizeSmall,
                                ),
                              ),
                            ],
                          )),
                        ]),
                  ),
                );
              }

              return Container(
                height: 104,
                padding: const EdgeInsets.fromLTRB(
                  Dimensions.paddingSizeDefault,
                  Dimensions.paddingSizeDefault,
                  Dimensions.paddingSizeDefault,
                  Dimensions.paddingSizeLarge,
                ),
                child: tripController.isLoading
                    ? Center(
                        child: SpinKitCircle(
                            color: Theme.of(context).primaryColor, size: 40.0))
                    : ButtonWidget(
                        buttonText: 'payment_received'.tr,
                        onPressed: () {
                          Get.dialog(ConfirmationDialogWidget(
                            icon: Images.paymentIcon,
                            description:
                                'Confirme que recebeu ${PriceConverter.convertPrice(context, finalAmount)} do passageiro via $displayPaymentMethod.',
                            onYesPressed: () {
                              setState(() {
                                canPop = true;
                              });
                              tripController.paymentSubmit(
                                finalFareController.finalFare!.id!,
                                submitPaymentMethod,
                                fromParcel: widget.fromParcel,
                              );
                            },
                          ));
                        },
                      ),
              );
            });
          }),
        ),
      ),
    );
  }
}

class SummeryItem extends StatelessWidget {
  final String title;
  final String subTitle;
  const SummeryItem({super.key, required this.title, required this.subTitle});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Image.asset(
          subTitle == 'time'
              ? Images.circularClockIcon
              : Images.twoPointerMapMarker,
          height: Dimensions.iconSizeSmall,
          width: Dimensions.iconSizeSmall,
          color: Theme.of(context).primaryColor),
      Text(title, style: textMedium),
      Text(subTitle.tr,
          style: textRegular.copyWith(color: Theme.of(context).hintColor)),
    ]);
  }
}
