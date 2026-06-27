import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/features/wallet/widgets/cash_in_hand_warning_widget.dart';
import 'package:ride_sharing_user_app/features/wallet/widgets/history_list_widget.dart';
import 'package:ride_sharing_user_app/features/wallet/widgets/transaction_card_button_widget.dart';
import 'package:ride_sharing_user_app/localization/localization_controller.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:ride_sharing_user_app/util/styles.dart';
import 'package:ride_sharing_user_app/features/profile/controllers/profile_controller.dart';
import 'package:ride_sharing_user_app/features/profile/screens/profile_menu_screen.dart';
import 'package:ride_sharing_user_app/features/wallet/controllers/wallet_controller.dart';
import 'package:ride_sharing_user_app/features/wallet/widgets/wallet_money_amount_widget.dart';
import 'package:ride_sharing_user_app/common_widgets/app_bar_widget.dart';
import 'package:ride_sharing_user_app/common_widgets/zoom_drawer_context_widget.dart';
import 'package:ride_sharing_user_app/common_widgets/type_button_widget.dart';

class WalletScreenMenu extends GetView<ProfileController> {
  const WalletScreenMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfileController>(
      builder: (controller) => ZoomDrawer(
        controller: controller.zoomDrawerController,
        menuScreen: const ProfileMenuScreen(),
        mainScreen: const WalletScreen(),
        borderRadius: 24.0,
        angle: -5.0,
        isRtl: !Get.find<LocalizationController>().isLtr,
        menuBackgroundColor: Theme.of(context).primaryColor,
        slideWidth: MediaQuery.of(context).size.width * 0.85,
        mainScreenScale: .4,
        mainScreenTapClose: true,
      ),
    );
  }
}

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen>
    with SingleTickerProviderStateMixin {
  ScrollController scrollController = ScrollController();
  late TabController tabController;

  @override
  void initState() {
    Get.find<WalletController>().getWithdrawPendingList(1);
    Get.find<WalletController>().getPayableHistoryList(1);
    Get.find<WalletController>().getIncomeStatement(1);
    Get.find<ProfileController>().getProfileInfo();
    Get.find<WalletController>().setWalletTypeIndex(0);
    Get.find<WalletController>().getWithdrawMethodInfoList(1);
    Get.find<WalletController>().setSelectedHistoryIndex(1, false);
    Get.find<WalletController>().getPaymentGetWayList();

    tabController = TabController(length: 3, vsync: this);
    tabController.addListener(() {
      if (!tabController.indexIsChanging) {
        if (tabController.index == 1) {
          Get.find<WalletController>().setPayableTypeIndex(1, notify: false);
        } else if (tabController.index == 2) {
          Get.find<WalletController>().getLokallyBillingOverview();
        } else if (tabController.index == 0) {
          Get.find<WalletController>().setSelectedHistoryIndex(1, false);
        }
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Stack(
        children: [
          Scaffold(
            resizeToAvoidBottomInset: false,
            body: CustomScrollView(
              controller: scrollController,
              slivers: [
                SliverAppBar(
                  pinned: true,
                  elevation: 0,
                  centerTitle: false,
                  toolbarHeight: 80,
                  automaticallyImplyLeading: false,
                  backgroundColor: Theme.of(context).highlightColor,
                  flexibleSpace:
                      GetBuilder<WalletController>(builder: (walletController) {
                    return AppBarWidget(
                      title: 'Minha carteira',
                      showBackButton: false,
                      onTap: () {
                        Get.find<ProfileController>().toggleDrawer();
                      },
                    );
                  }),
                ),
                SliverToBoxAdapter(
                  child: GetBuilder<WalletController>(
                    builder: (walletController) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              Dimensions.paddingSizeDefault,
                              Dimensions.paddingSizeLarge,
                              Dimensions.paddingSizeDefault,
                              0,
                            ),
                            child: SizedBox(
                              height: 45,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TypeButtonWidget(
                                      index: 0,
                                      name: 'Saldo da carteira',
                                      selectedIndex:
                                          walletController.walletTypeIndex,
                                      onTap: () => walletController
                                                  .walletTypeIndex ==
                                              0
                                          ? null
                                          : walletController.setWalletTypeIndex(
                                              0,
                                              isUpdate: true,
                                            ),
                                    ),
                                  ),
                                  const SizedBox(
                                    width: Dimensions.paddingSizeSmall,
                                  ),
                                  Expanded(
                                    child: TypeButtonWidget(
                                      index: 2,
                                      name: 'Extrato de ganhos',
                                      selectedIndex:
                                          walletController.walletTypeIndex,
                                      onTap: () => walletController
                                                  .walletTypeIndex ==
                                              2
                                          ? null
                                          : walletController.setWalletTypeIndex(
                                              2,
                                              isUpdate: true,
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: Dimensions.paddingSizeDefault,
                          ),
                          walletController.walletTypeIndex != 2
                              ? const WalletMoneyAmountWidget()
                              : Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: Dimensions.paddingSizeDefault,
                                  ),
                                  child: Text(
                                    'Extrato de ganhos',
                                    style: textBold.copyWith(
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodyMedium!
                                          .color,
                                      fontSize: Dimensions.fontSizeExtraLarge,
                                    ),
                                  ),
                                ),
                          if (walletController.walletTypeIndex == 0)
                            TabBar(
                              controller: tabController,
                              unselectedLabelColor: Colors.grey,
                              tabAlignment: TabAlignment.start,
                              isScrollable: true,
                              labelColor: Get.isDarkMode
                                  ? Colors.white
                                  : Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.color,
                              labelStyle: textSemiBold.copyWith(),
                              indicator: UnderlineTabIndicator(
                                borderSide: BorderSide(
                                  color: Theme.of(context).primaryColor,
                                  width: 2,
                                ),
                              ),
                              dividerHeight: 1,
                              dividerColor: Theme.of(context)
                                  .primaryColor
                                  .withValues(alpha: 0.15),
                              tabs: const [
                                Tab(text: 'Solicitações de saque'),
                                Tab(text: 'Histórico de dinheiro recebido'),
                                Tab(text: 'Pagar à Lokally'),
                              ],
                            ),
                          if (walletController.walletTypeIndex != 1 &&
                              !(walletController.walletTypeIndex == 0 &&
                                  tabController.index == 2))
                            TransactionCardButtonWidget(
                              tabIndex: tabController.index,
                            ),
                          HistoryListWidget(
                            scrollController: scrollController,
                            tabIndex: tabController.index,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          GetBuilder<ProfileController>(
            builder: (profileController) {
              return (profileController.isCashInHandHoldAccount ||
                      profileController.isCashInHandWarningShow)
                  ? CashInHandWarningWidget()
                  : const SizedBox();
            },
          ),
        ],
      ),
    );
  }
}

class SliverDelegate extends SliverPersistentHeaderDelegate {
  Widget child;
  double height;

  SliverDelegate({required this.child, this.height = 70});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(SliverDelegate oldDelegate) {
    return oldDelegate.maxExtent != height ||
        oldDelegate.minExtent != height ||
        child != oldDelegate.child;
  }
}
