import 'dart:convert';

import 'package:dart_pusher_channels/dart_pusher_channels.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/features/auth/controllers/auth_controller.dart';
import 'package:ride_sharing_user_app/features/dashboard/screens/dashboard_screen.dart';
import 'package:ride_sharing_user_app/features/home/screens/ride_list_screen.dart';
import 'package:ride_sharing_user_app/features/map/controllers/map_controller.dart';
import 'package:ride_sharing_user_app/features/map/screens/map_screen.dart';
import 'package:ride_sharing_user_app/features/ride/controllers/ride_controller.dart';
import 'package:ride_sharing_user_app/features/ride/screens/ride_request_list_screen.dart';
import 'package:ride_sharing_user_app/features/safety_setup/controllers/safety_alert_controller.dart';
import 'package:ride_sharing_user_app/features/splash/controllers/splash_controller.dart';
import 'package:ride_sharing_user_app/features/trip/screens/payment_received_screen.dart';
import 'package:ride_sharing_user_app/features/trip/screens/review_this_customer_screen.dart';
import 'package:ride_sharing_user_app/helper/notification_helper.dart';
import 'package:ride_sharing_user_app/util/app_constants.dart';

class PusherHelper {
  static PusherChannelsClient? pusherClient;

  bool _isPassengerCancellationDialogOpen = false;

  static void initializePusher() async {
    PusherChannelsOptions testOptions = PusherChannelsOptions.fromHost(
      host: Get.find<SplashController>().config!.webSocketUrl ?? '',
      scheme: Get.find<SplashController>().config!.websocketScheme == 'https'
          ? 'wss'
          : 'ws',
      key: Get.find<SplashController>().config!.webSocketKey ?? '',
      port: int.parse(
          Get.find<SplashController>().config?.webSocketPort ?? '6001'),
    );
    pusherClient = PusherChannelsClient.websocket(
      options: testOptions,
      connectionErrorHandler: (exception, trace, refresh) async {
        //log('=================$exception');
        Get.find<SplashController>().setPusherStatus('Disconnected');
        refresh();
      },
    );

    await pusherClient?.connect();

    String? pusherChannelId =
        pusherClient?.channelsManager.channelsConnectionDelegate.socketId;
    if (pusherChannelId != null) {
      Get.find<SplashController>().setPusherStatus('Connected');
    }

    pusherClient?.lifecycleStream.listen((event) {
      Get.find<SplashController>().setPusherStatus('Disconnected');
    });
  }

  late PrivateChannel driverTripSubscribe;
  void driverTripRequestSubscribe(String id) {
    if (Get.find<SplashController>().pusherConnectionStatus != null ||
        Get.find<SplashController>().pusherConnectionStatus == 'Connected') {
      driverTripSubscribe = pusherClient!.privateChannel(
        "private-customer-trip-request.$id",
        authorizationDelegate:
            EndpointAuthorizableChannelTokenAuthorizationDelegate
                .forPrivateChannel(
          authorizationEndpoint: Uri.parse(
              'https://${Get.find<SplashController>().config!.webSocketUrl}/broadcasting/auth'),
          headers: {
            "Accept": "application/json",
            "Authorization":
                "Bearer ${Get.find<AuthController>().getUserToken()}",
            "Access-Control-Allow-Origin": "*",
            'Access-Control-Allow-Methods': "PUT, GET, POST, DELETE, OPTIONS"
          },
        ),
      );

      if (driverTripSubscribe.currentStatus == null) {
        driverTripSubscribe.subscribeIfNotUnsubscribed();
        driverTripSubscribe.bind("customer-trip-request.$id").listen((event) {
          final Map<String, dynamic> eventData = _eventData(event.data);
          final String tripId = eventData['trip_id']?.toString() ?? '';
          Get.find<RideController>().ongoingTripList().then((value) {
            if ((Get.find<RideController>().ongoingTrip ?? []).isEmpty) {
              Get.find<RideController>().getPendingRideRequestList(1);
              Get.find<RideController>().setRideId(tripId);
              Get.find<RideController>()
                  .getRideDetailBeforeAccept(tripId)
                  .then((value) {
                if (value.statusCode == 200) {
                  Get.find<RiderMapController>()
                      .getPickupToDestinationPolyline();
                  Get.find<RiderMapController>()
                      .setRideCurrentState(RideState.pending);
                  Get.find<RideController>().updateRoute(false, notify: true);
                  Get.to(() => const MapScreen());
                }
              });
            } else {
              NotificationHelper.stopRequestSound(requestId: tripId);

              if (Get.currentRoute == '/MapScreen') {
                Get.find<RideController>()
                    .getPendingRideRequestList(1, limit: 100);
              } else {
                Get.to(() => RideRequestScreen());
              }
            }
          });

          if (tripId.isNotEmpty) {
            customerInitialTripCancel(tripId, id);
            anotherDriverAcceptedTrip(tripId, id);
          }
        });
      }
    }
  }

  late PrivateChannel customerInitialTripCancelChannel;

  void customerInitialTripCancel(String tripId, String userId) {
    if (Get.find<SplashController>().pusherConnectionStatus != null ||
        Get.find<SplashController>().pusherConnectionStatus == 'Connected') {
      customerInitialTripCancelChannel = pusherClient!.privateChannel(
        "private-customer-trip-cancelled.$tripId.$userId",
        authorizationDelegate:
            EndpointAuthorizableChannelTokenAuthorizationDelegate
                .forPrivateChannel(
          authorizationEndpoint: Uri.parse(
              'https://${Get.find<SplashController>().config!.webSocketUrl}/broadcasting/auth'),
          headers: {
            "Accept": "application/json",
            "Authorization":
                "Bearer ${Get.find<AuthController>().getUserToken()}",
            "Access-Control-Allow-Origin": "*",
            'Access-Control-Allow-Methods': "PUT, GET, POST, DELETE, OPTIONS"
          },
        ),
      );

      if (customerInitialTripCancelChannel.currentStatus == null) {
        customerInitialTripCancelChannel.subscribe();
        customerInitialTripCancelChannel
            .bind("customer-trip-cancelled.$tripId.$userId")
            .listen((event) async {
          final Map<String, dynamic> eventData = _eventData(event.data);
          final String cancelledTripId = eventData['trip_id']?.toString() ?? '';
          NotificationHelper.stopRequestSound(requestId: cancelledTripId);
          final String cancellationReason =
              _extractCancellationReason(eventData);

          if (Get.find<RideController>().tripDetail?.id == cancelledTripId) {
            Get.find<SafetyAlertController>().cancelDriverNeedSafetyStream();

            await _showPassengerCancellationDialog(cancellationReason);

            Get.find<RideController>()
                .getPendingRideRequestList(1)
                .then((value) {
              if (value.statusCode == 200) {
                Get.find<RiderMapController>()
                    .setRideCurrentState(RideState.initial);
                Get.offAll(() => const DashboardScreen());
              }
            });
          } else {
            Get.find<RideController>().ongoingTripList();
            Get.find<RideController>().getPendingRideRequestList(1, limit: 100);
          }
        });
      }
    }
  }

  late PrivateChannel anotherDriverAcceptedTripChannel;

  void anotherDriverAcceptedTrip(String tripId, String userId) {
    if (Get.find<SplashController>().pusherConnectionStatus != null ||
        Get.find<SplashController>().pusherConnectionStatus == 'Connected') {
      anotherDriverAcceptedTripChannel = pusherClient!.privateChannel(
        "private-another-driver-trip-accepted.$tripId.$userId",
        authorizationDelegate:
            EndpointAuthorizableChannelTokenAuthorizationDelegate
                .forPrivateChannel(
          authorizationEndpoint: Uri.parse(
              'https://${Get.find<SplashController>().config!.webSocketUrl}/broadcasting/auth'),
          headers: {
            "Accept": "application/json",
            "Authorization":
                "Bearer ${Get.find<AuthController>().getUserToken()}",
            "Access-Control-Allow-Origin": "*",
            'Access-Control-Allow-Methods': "PUT, GET, POST, DELETE, OPTIONS"
          },
        ),
      );

      if (anotherDriverAcceptedTripChannel.currentStatus == null) {
        anotherDriverAcceptedTripChannel.subscribe();
        anotherDriverAcceptedTripChannel
            .bind("another-driver-trip-accepted.$tripId.$userId")
            .listen((event) {
          final Map<String, dynamic> eventData = _eventData(event.data);
          final String acceptedTripId = eventData['trip_id']?.toString() ?? '';
          NotificationHelper.stopRequestSound(requestId: acceptedTripId);

          if (Get.find<RideController>().tripDetail?.id == acceptedTripId) {
            Get.find<SafetyAlertController>().cancelDriverNeedSafetyStream();
            Get.find<RideController>()
                .getPendingRideRequestList(1)
                .then((value) {
              if (value.statusCode == 200) {
                Get.find<RiderMapController>()
                    .setRideCurrentState(RideState.initial);
                Get.offAll(() => const DashboardScreen());
              }
            });
          } else {
            Get.find<RideController>().ongoingTripList();
            Get.find<RideController>().getPendingRideRequestList(1, limit: 100);
          }
        });
      }
    }
  }

  late PrivateChannel tripCancelAfterOngoingChannel;

  void tripCancelAfterOngoing(String tripId) {
    if (Get.find<SplashController>().pusherConnectionStatus != null ||
        Get.find<SplashController>().pusherConnectionStatus == 'Connected') {
      tripCancelAfterOngoingChannel = pusherClient!.privateChannel(
        "private-customer-trip-cancelled-after-ongoing.$tripId",
        authorizationDelegate:
            EndpointAuthorizableChannelTokenAuthorizationDelegate
                .forPrivateChannel(
          authorizationEndpoint: Uri.parse(
              'https://${Get.find<SplashController>().config!.webSocketUrl}/broadcasting/auth'),
          headers: {
            "Accept": "application/json",
            "Authorization":
                "Bearer ${Get.find<AuthController>().getUserToken()}",
            "Access-Control-Allow-Origin": "*",
            'Access-Control-Allow-Methods': "PUT, GET, POST, DELETE, OPTIONS"
          },
        ),
      );

      if (tripCancelAfterOngoingChannel.currentStatus == null) {
        tripCancelAfterOngoingChannel.subscribe();
        tripCancelAfterOngoingChannel
            .bind("customer-trip-cancelled-after-ongoing.$tripId")
            .listen((event) async {
          final Map<String, dynamic> eventData = _eventData(event.data);
          final String tripId = eventData['id']?.toString() ?? '';
          NotificationHelper.stopRequestSound(requestId: tripId);
          final String cancellationReason =
              _extractCancellationReason(eventData);

          Get.find<SafetyAlertController>().cancelDriverNeedSafetyStream();

          await _showPassengerCancellationDialog(cancellationReason);

          Get.find<RideController>().getRideDetails(tripId).then((value) {
            if (value.statusCode == 200) {
              if (Get.find<RideController>().tripDetail?.type ==
                  AppConstants.parcel) {
                Get.offAll(() => const DashboardScreen());
              } else {
                Get.find<RideController>().getFinalFare(tripId).then((value) {
                  if (value.statusCode == 200) {
                    Get.find<RiderMapController>()
                        .setRideCurrentState(RideState.initial);
                    Get.to(() => const PaymentReceivedScreen());
                  }
                });
              }
            }
          });
          // pusherClient!.unsubscribe('private-customer-trip-cancelled-after-ongoing.$tripId');
        });
      }
    }
  }

  late PrivateChannel tripPaymentSuccessfulChannel;

  void tripPaymentSuccessful(String tripId) {
    if (Get.find<SplashController>().pusherConnectionStatus != null ||
        Get.find<SplashController>().pusherConnectionStatus == 'Connected') {
      tripPaymentSuccessfulChannel = pusherClient!.privateChannel(
        "private-customer-trip-payment-successful.$tripId",
        authorizationDelegate:
            EndpointAuthorizableChannelTokenAuthorizationDelegate
                .forPrivateChannel(
          authorizationEndpoint: Uri.parse(
              'https://${Get.find<SplashController>().config!.webSocketUrl}/broadcasting/auth'),
          headers: {
            "Accept": "application/json",
            "Authorization":
                "Bearer ${Get.find<AuthController>().getUserToken()}",
            "Access-Control-Allow-Origin": "*",
            'Access-Control-Allow-Methods': "PUT, GET, POST, DELETE, OPTIONS"
          },
        ),
      );

      if (tripPaymentSuccessfulChannel.currentStatus == null) {
        tripPaymentSuccessfulChannel.subscribe();
        tripPaymentSuccessfulChannel
            .bind("customer-trip-payment-successful.$tripId")
            .listen((event) {
          if (jsonDecode(event.data!)['type'] == 'parcel') {
            Get.find<RideController>()
                .getRideDetails(jsonDecode(event.data!)['id'])
                .then((value) {
              if (value.statusCode == 200) {
                Get.find<RideController>().getOngoingParcelList();
                Get.back();
              }
            });
          } else {
            Get.find<RideController>().ongoingTripList().then((value) {
              if ((Get.find<RideController>().ongoingTrip ?? []).isEmpty) {
                Get.find<RideController>()
                    .getRideDetails(jsonDecode(event.data!)['id'])
                    .then((value) {
                  if (value.statusCode == 200) {
                    if (Get.find<SplashController>().config!.reviewStatus!) {
                      Get.offAll(() => ReviewThisCustomerScreen(
                          tripId: jsonDecode(event.data!)['id']));
                    } else {
                      Get.offAll(() => const DashboardScreen());
                    }
                  }
                });
              } else {
                Get.offAll(() => const RideListScreen());
              }
            });
          }
        });
      }
    }
  }

  Map<String, dynamic> _eventData(String? data) {
    if (data == null || data.isEmpty) {
      return <String, dynamic>{};
    }

    try {
      final dynamic decoded = jsonDecode(data);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      return <String, dynamic>{};
    }

    return <String, dynamic>{};
  }

  String _extractCancellationReason(Map<String, dynamic> eventData) {
    const List<String> reasonKeys = <String>[
      'cancellation_reason',
      'cancel_reason',
      'cancellationReason',
      'cancelReason',
      'reason',
      'cause',
    ];

    final dynamic reason = _findValueByKeys(eventData, reasonKeys);

    if (reason == null || reason.toString().trim().isEmpty) {
      return 'Não informado pelo passageiro.';
    }

    return reason.toString().replaceAll('_', ' ').replaceAll('-', ' ').trim();
  }

  dynamic _findValueByKeys(dynamic value, List<String> keys) {
    if (value is Map) {
      for (final String key in keys) {
        if (value.containsKey(key) &&
            value[key] != null &&
            value[key].toString().trim().isNotEmpty) {
          return value[key];
        }
      }

      for (final dynamic nestedValue in value.values) {
        final dynamic found = _findValueByKeys(nestedValue, keys);
        if (found != null) {
          return found;
        }
      }
    }

    if (value is List) {
      for (final dynamic item in value) {
        final dynamic found = _findValueByKeys(item, keys);
        if (found != null) {
          return found;
        }
      }
    }

    return null;
  }

  Future<void> _showPassengerCancellationDialog(String reason) async {
    if (_isPassengerCancellationDialogOpen) {
      return;
    }

    _isPassengerCancellationDialogOpen = true;

    try {
      await Get.dialog<void>(
        AlertDialog(
          title: const Text('Viagem cancelada'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('O passageiro cancelou esta viagem.'),
              const SizedBox(height: 16),
              const Text(
                'Motivo do cancelamento:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(reason),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('OK'),
            ),
          ],
        ),
        barrierDismissible: false,
      );
    } finally {
      _isPassengerCancellationDialogOpen = false;
    }
  }

  void pusherDisconnectPusher() {
    pusherClient!.disconnect();
  }
}
