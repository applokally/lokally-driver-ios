import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ride_sharing_user_app/common_widgets/app_bar_widget.dart';
import 'package:ride_sharing_user_app/common_widgets/button_widget.dart';
import 'package:ride_sharing_user_app/features/auth/widgets/text_field_title_widget.dart';
import 'package:ride_sharing_user_app/features/profile/controllers/profile_controller.dart';
import 'package:ride_sharing_user_app/features/profile/domain/models/categoty_model.dart';
import 'package:ride_sharing_user_app/features/profile/domain/models/profile_model.dart';
import 'package:ride_sharing_user_app/features/profile/domain/models/vehicle_body.dart';
import 'package:ride_sharing_user_app/features/profile/domain/models/vehicle_brand_model.dart';
import 'package:ride_sharing_user_app/features/splash/controllers/splash_controller.dart';
import 'package:ride_sharing_user_app/helper/display_helper.dart';
import 'package:ride_sharing_user_app/helper/file_validation_helper.dart';
import 'package:ride_sharing_user_app/util/app_constants.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:ride_sharing_user_app/util/images.dart';
import 'package:ride_sharing_user_app/util/styles.dart';

class VehicleAddScreen extends StatefulWidget {
  final Vehicle? vehicleInfo;

  const VehicleAddScreen({
    super.key,
    this.vehicleInfo,
  });

  @override
  State<VehicleAddScreen> createState() => _VehicleAddScreenState();
}

class _VehicleAddScreenState extends State<VehicleAddScreen> {
  TextEditingController licencePlateNumberController = TextEditingController();
  TextEditingController licenceExpiryDateController = TextEditingController();
  TextEditingController vinNumberController = TextEditingController();
  TextEditingController transmissionController = TextEditingController();
  TextEditingController parcelWeightCapacity = TextEditingController();

  final ScrollController _scrollController = ScrollController();

  FocusNode licencePlateFocus = FocusNode();
  FocusNode licenceExpiryFocus = FocusNode();
  FocusNode vinNumberFocus = FocusNode();
  FocusNode transmissionFocus = FocusNode();
  FocusNode parcelWeightFocus = FocusNode();

  FilePickerResult? _crlvDocument;
  FilePickerResult? _insuranceDocument;

  @override
  void initState() {
    Get.find<ProfileController>().getVehicleBrandList(1);
    Get.find<ProfileController>().clearVehicleData();

    if (widget.vehicleInfo != null) {
      licencePlateNumberController.text =
          widget.vehicleInfo!.licencePlateNumber ?? '';

      licenceExpiryDateController.text = _formatDateForInput(
        widget.vehicleInfo!.licenceExpireDate,
      );

      Get.find<ProfileController>().setFuelType(
        widget.vehicleInfo!.fuelType!,
        false,
      );

      parcelWeightCapacity.text =
          (widget.vehicleInfo?.parcelWeightCapacity ?? '').toString();
    }

    super.initState();
  }

  @override
  void dispose() {
    licencePlateNumberController.dispose();
    licenceExpiryDateController.dispose();
    vinNumberController.dispose();
    transmissionController.dispose();
    parcelWeightCapacity.dispose();

    _scrollController.dispose();

    licencePlateFocus.dispose();
    licenceExpiryFocus.dispose();
    vinNumberFocus.dispose();
    transmissionFocus.dispose();
    parcelWeightFocus.dispose();

    super.dispose();
  }

  void _scrollDown() {
    if (!_scrollController.hasClients) {
      return;
    }

    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent + 50,
      duration: const Duration(milliseconds: 500),
      curve: Curves.fastOutSlowIn,
    );
  }

  String _formatDateForInput(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '';
    }

    final String cleanValue = value.trim();

    if (cleanValue.contains('/')) {
      return cleanValue;
    }

    final DateTime? parsed = DateTime.tryParse(cleanValue);

    if (parsed == null) {
      return cleanValue;
    }

    final String day = parsed.day.toString().padLeft(2, '0');
    final String month = parsed.month.toString().padLeft(2, '0');
    final String year = parsed.year.toString();

    return '$day/$month/$year';
  }

  String? _formatVehicleDocumentDateForApi(String value) {
    final String cleanValue = value.trim();

    if (!RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(cleanValue)) {
      return null;
    }

    final List<String> parts = cleanValue.split('/');
    final int? day = int.tryParse(parts[0]);
    final int? month = int.tryParse(parts[1]);
    final int? year = int.tryParse(parts[2]);

    if (day == null || month == null || year == null) {
      return null;
    }

    if (year < DateTime.now().year || year > 2050) {
      return null;
    }

    final DateTime date = DateTime(year, month, day);

    if (date.day != day || date.month != month || date.year != year) {
      return null;
    }

    final String formattedMonth = month.toString().padLeft(2, '0');
    final String formattedDay = day.toString().padLeft(2, '0');

    return '$year-$formattedMonth-$formattedDay';
  }

  FilePickerResult _platformFileToPickerResult(PlatformFile file) {
    return FilePickerResult(<PlatformFile>[file]);
  }

  void _syncVehicleDocumentsWithController(
      ProfileController profileController) {
    profileController.listOfDocuments.clear();

    if (_crlvDocument != null) {
      profileController.listOfDocuments.add(_crlvDocument!);
    }

    if (_insuranceDocument != null) {
      profileController.listOfDocuments.add(_insuranceDocument!);
    }
  }

  void _setVehicleDocument({
    required ProfileController profileController,
    required int index,
    required FilePickerResult result,
  }) {
    if (index == 1 && _crlvDocument == null) {
      showCustomSnackBar(
        'Envie primeiro o documento do veículo (CRLV).',
      );
      return;
    }

    setState(() {
      if (index == 0) {
        _crlvDocument = result;
      } else {
        _insuranceDocument = result;
      }

      _syncVehicleDocumentsWithController(profileController);
    });

    profileController.update();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollDown();
    });
  }

  void _removeVehicleDocument({
    required ProfileController profileController,
    required int index,
  }) {
    setState(() {
      if (index == 0) {
        _crlvDocument = null;
      } else {
        _insuranceDocument = null;
      }

      _syncVehicleDocumentsWithController(profileController);
    });

    profileController.update();
  }

  Future<void> _pickVehicleDocumentFromUpload({
    required ProfileController profileController,
    required int index,
  }) async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      withReadStream: true,
      allowedExtensions: AppConstants.registrationAllowExtensions,
    );

    if (result == null) {
      return;
    }

    final PlatformFile file = result.files.single;

    if (await FileValidationHelper.validatePlatformFileSizeAsync(file: file)) {
      _setVehicleDocument(
        profileController: profileController,
        index: index,
        result: result,
      );
    }
  }

  Future<void> _pickVehicleDocumentFromCamera({
    required ProfileController profileController,
    required int index,
  }) async {
    final XFile? image = await FileValidationHelper.validateAndPickImage(
      source: ImageSource.camera,
    );

    if (image == null) {
      return;
    }

    final File file = File(image.path);
    final int fileSize = await file.length();

    final PlatformFile platformFile = PlatformFile(
      name: image.name.isNotEmpty
          ? image.name
          : 'documento_veiculo_${DateTime.now().millisecondsSinceEpoch}.jpg',
      path: image.path,
      size: fileSize,
    );

    _setVehicleDocument(
      profileController: profileController,
      index: index,
      result: _platformFileToPickerResult(platformFile),
    );
  }

  void _openDocumentSourceSheet({
    required BuildContext context,
    required String title,
    required VoidCallback onUpload,
    required VoidCallback onCamera,
  }) {
    Get.bottomSheet(
      SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(Dimensions.radiusLarge),
              topRight: Radius.circular(Dimensions.radiusLarge),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 4,
                width: 42,
                decoration: BoxDecoration(
                  color: Theme.of(context).hintColor.withValues(alpha: 0.28),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: textBold.copyWith(
                  fontSize: 18,
                  height: 1.25,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 14),
              _VehicleDocumentActionTile(
                icon: Icons.upload_file_outlined,
                title: 'Enviar arquivo',
                subtitle: 'Selecionar uma imagem ou PDF do dispositivo',
                onTap: () {
                  Get.back();
                  onUpload();
                },
              ),
              const SizedBox(height: 10),
              _VehicleDocumentActionTile(
                icon: Icons.photo_camera_outlined,
                title: 'Tirar foto',
                subtitle: 'Abrir a câmera para fotografar agora',
                onTap: () {
                  Get.back();
                  onCamera();
                },
              ),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
    );
  }

  FilePickerResult? _documentAt(int index) {
    if (index == 0) {
      return _crlvDocument;
    }

    return _insuranceDocument;
  }

  @override
  Widget build(BuildContext context) {
    final Color readableInputColor =
        Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.72) ??
            Theme.of(context).hintColor;

    final TextStyle readableInputTextStyle = textRegular.copyWith(
      color: readableInputColor,
      fontSize: 14.5,
      height: 1.25,
    );

    return SafeArea(
      top: false,
      child: Scaffold(
        backgroundColor: Theme.of(context).cardColor,
        appBar: AppBarWidget(
          title: widget.vehicleInfo == null
              ? 'vehicle_setup'.tr
              : 'update_vehicle'.tr,
          regularAppbar: true,
        ),
        body: GetBuilder<ProfileController>(
          builder: (profileController) {
            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Dimensions.paddingSizeLarge,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: Dimensions.paddingSizeDefault),
                          Center(
                            child: Text(
                              'vehicle_information'.tr,
                              textAlign: TextAlign.center,
                              style: textBold.copyWith(
                                fontSize: 22,
                                height: 1.18,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.color,
                              ),
                            ),
                          ),
                          const SizedBox(height: Dimensions.paddingSizeSmall),
                          Center(
                            child: Text(
                              'Adicionar detalhes do veículo',
                              textAlign: TextAlign.center,
                              style: textRegular.copyWith(
                                fontSize: 14.8,
                                height: 1.4,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color
                                    ?.withValues(alpha: 0.72),
                              ),
                            ),
                          ),
                          const SizedBox(height: Dimensions.paddingSizeLarge),
                          if (widget.vehicleInfo?.vehicleRequestStatus ==
                              'denied')
                            Container(
                              width: Get.width,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(Dimensions.paddingSizeSmall),
                                ),
                                color: Theme.of(context)
                                    .colorScheme
                                    .error
                                    .withValues(alpha: 0.1),
                              ),
                              padding:
                                  EdgeInsets.all(Dimensions.paddingSizeSmall),
                              margin: EdgeInsets.only(
                                  top: Dimensions.paddingSizeSmall),
                              child: RichText(
                                text: TextSpan(
                                  text: 'deny_note'.tr,
                                  style: textRegular.copyWith(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                  children: [
                                    TextSpan(
                                      text:
                                          ' ${profileController.profileInfo?.vehicle?.denyNote}',
                                      style: textRegular.copyWith(
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.color,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          TextFieldTitleWidget(
                            title: 'vehicle_brand'.tr,
                            isRequired: true,
                          ),
                          if (profileController.brandList.isNotEmpty)
                            _VehicleDropdownContainer(
                              child: DropdownButton(
                                items: profileController.brandList.map((item) {
                                  return DropdownMenuItem<Brand>(
                                    value: item,
                                    child: Text(
                                      item.name!.tr,
                                      style: textRegular.copyWith(
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyMedium!
                                            .color,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (newVal) {
                                  profileController.setBrandIndex(
                                      newVal!, true);
                                },
                                isExpanded: true,
                                underline: const SizedBox(),
                                icon: const Icon(Icons.keyboard_arrow_down),
                                value: profileController.selectedBrand ??
                                    Brand(
                                      id: 'abc',
                                      name: 'Select Brand Model',
                                    ),
                              ),
                            ),
                          if (profileController.modelList.isNotEmpty)
                            TextFieldTitleWidget(
                              title: 'vehicle_model'.tr,
                              isRequired: true,
                            ),
                          if (profileController.modelList.isNotEmpty)
                            _VehicleDropdownContainer(
                              child: DropdownButton(
                                items: profileController.modelList.map((item) {
                                  return DropdownMenuItem<VehicleModels>(
                                    value: item,
                                    child: Text(
                                      item.name!.tr,
                                      style: textRegular.copyWith(
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyMedium!
                                            .color,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (newVal) {
                                  profileController.setModelIndex(
                                      newVal!, true);
                                },
                                isExpanded: true,
                                icon: const Icon(Icons.keyboard_arrow_down),
                                underline: const SizedBox(),
                                value: profileController.selectedModel,
                              ),
                            ),
                          TextFieldTitleWidget(
                            title: 'vehicle_category'.tr,
                            isRequired: true,
                          ),
                          if (profileController.categoryList.isNotEmpty)
                            _VehicleDropdownContainer(
                              child: DropdownButton(
                                items:
                                    profileController.categoryList.map((item) {
                                  return DropdownMenuItem<Category>(
                                    value: item,
                                    child: Text(
                                      item.name!.tr,
                                      style: textRegular.copyWith(
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyMedium!
                                            .color,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (newVal) {
                                  profileController.setCategoryIndex(
                                    newVal!,
                                    true,
                                  );
                                },
                                isExpanded: true,
                                icon: const Icon(Icons.keyboard_arrow_down),
                                underline: const SizedBox(),
                                value: profileController.selectedCategory,
                              ),
                            ),
                          TextFieldTitleWidget(
                            title:
                                '${'parcel_weight_capacity'.tr} (${Get.find<SplashController>().config?.parcelWeightUnit})',
                          ),
                          _VehicleTextField(
                            controller: parcelWeightCapacity,
                            focusNode: parcelWeightFocus,
                            style: readableInputTextStyle,
                            hintText: 'enter_max_weight'.tr,
                            keyboardType: TextInputType.number,
                            onSubmitted: (text) => FocusScope.of(context)
                                .requestFocus(licencePlateFocus),
                          ),
                          TextFieldTitleWidget(
                            title: 'licence_plate_number'.tr,
                            isRequired: true,
                          ),
                          _VehicleTextField(
                            controller: licencePlateNumberController,
                            focusNode: licencePlateFocus,
                            style: readableInputTextStyle,
                            hintText: 'EX: DB-3212',
                            keyboardType: TextInputType.name,
                            textCapitalization: TextCapitalization.characters,
                            onSubmitted: (text) => FocusScope.of(context)
                                .requestFocus(licenceExpiryFocus),
                          ),
                          TextFieldTitleWidget(
                            title: 'Validade do documento do veículo',
                            isRequired: true,
                          ),
                          _VehicleTextField(
                            controller: licenceExpiryDateController,
                            focusNode: licenceExpiryFocus,
                            style: readableInputTextStyle,
                            hintText: 'dd/mm/aaaa',
                            keyboardType: TextInputType.number,
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.digitsOnly,
                              _VehicleExpiryDateInputFormatter(),
                            ],
                            suffixIcon: Icons.calendar_month_outlined,
                            onSubmitted: (text) =>
                                FocusScope.of(context).unfocus(),
                          ),
                          TextFieldTitleWidget(
                            title: 'fuel_type'.tr,
                            isRequired: true,
                          ),
                          _VehicleDropdownContainer(
                            child: DropdownButton<String>(
                              value: profileController.selectedFuelType,
                              items: Get.find<SplashController>()
                                  .config
                                  ?.fuelTypes
                                  ?.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(
                                    value.tr,
                                    style: textRegular.copyWith(
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodyMedium!
                                          .color,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                profileController.setFuelType(value!, true);
                              },
                              isExpanded: true,
                              icon: const Icon(Icons.keyboard_arrow_down),
                              underline: const SizedBox(),
                            ),
                          ),
                          if (widget.vehicleInfo == null) ...[
                            const SizedBox(
                                height: Dimensions.paddingSizeDefault),
                            _VehicleDocumentHeader(
                              title: 'Documentos do veículo',
                              subtitle:
                                  'Envie os documentos obrigatórios do veículo. Você pode anexar arquivo ou tirar foto.',
                            ),
                            const SizedBox(
                                height: Dimensions.paddingSizeDefault),
                            _VehicleDocumentUploadCard(
                              title: 'Documento do veículo (CRLV)',
                              subtitle:
                                  'Formatos aceitos: pdf, doc, docx, png, jpg ou jpeg. Tamanho máximo: ${FileValidationHelper.getMaxFileSize(false)}',
                              isRequired: true,
                              document: _documentAt(0),
                              onTap: () {
                                _openDocumentSourceSheet(
                                  context: context,
                                  title: 'Documento do veículo (CRLV)',
                                  onUpload: () =>
                                      _pickVehicleDocumentFromUpload(
                                    profileController: profileController,
                                    index: 0,
                                  ),
                                  onCamera: () =>
                                      _pickVehicleDocumentFromCamera(
                                    profileController: profileController,
                                    index: 0,
                                  ),
                                );
                              },
                              onRemove: _documentAt(0) != null
                                  ? () => _removeVehicleDocument(
                                        profileController: profileController,
                                        index: 0,
                                      )
                                  : null,
                            ),
                            const SizedBox(
                                height: Dimensions.paddingSizeDefault),
                            _VehicleDocumentUploadCard(
                              title: 'Seguro obrigatório',
                              subtitle:
                                  'Formatos aceitos: pdf, doc, docx, png, jpg ou jpeg. Tamanho máximo: ${FileValidationHelper.getMaxFileSize(false)}',
                              isRequired: true,
                              document: _documentAt(1),
                              onTap: () {
                                _openDocumentSourceSheet(
                                  context: context,
                                  title: 'Seguro obrigatório',
                                  onUpload: () =>
                                      _pickVehicleDocumentFromUpload(
                                    profileController: profileController,
                                    index: 1,
                                  ),
                                  onCamera: () =>
                                      _pickVehicleDocumentFromCamera(
                                    profileController: profileController,
                                    index: 1,
                                  ),
                                );
                              },
                              onRemove: _documentAt(1) != null
                                  ? () => _removeVehicleDocument(
                                        profileController: profileController,
                                        index: 1,
                                      )
                                  : null,
                            ),
                          ],
                          const SizedBox(height: Dimensions.paddingSizeLarge),
                          const SizedBox(
                              height: Dimensions.paddingSizeExtraLarge),
                        ],
                      ),
                    ),
                  ),
                ),
                profileController.creating
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SpinKitCircle(
                            color: Theme.of(context).primaryColor,
                            size: 40.0,
                          ),
                        ],
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.only(
                            topLeft:
                                Radius.circular(Dimensions.paddingSizeLarge),
                            topRight:
                                Radius.circular(Dimensions.paddingSizeLarge),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).highlightColor,
                              offset: const Offset(0, 4),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: Dimensions.paddingSizeDefault,
                          vertical: Dimensions.paddingSizeSmall,
                        ).copyWith(
                          bottom: Dimensions.paddingSizeLarge,
                        ),
                        child: ButtonWidget(
                          radius: Dimensions.radiusExtraLarge,
                          buttonText: widget.vehicleInfo == null
                              ? 'send_request'.tr
                              : 'update_and_send_request'.tr,
                          onPressed: () {
                            String brandId =
                                profileController.selectedBrand!.id!;
                            String modelId =
                                profileController.selectedModel.id!;
                            String categoryId =
                                profileController.selectedCategory.id!;
                            String licencePlateNumber =
                                licencePlateNumberController.text.trim();
                            String? expireDate =
                                _formatVehicleDocumentDateForApi(
                              licenceExpiryDateController.text,
                            );
                            String vinNumber = vinNumberController.text.trim();
                            String transmission =
                                transmissionController.text.trim();
                            String fuelType =
                                profileController.selectedFuelType;

                            _syncVehicleDocumentsWithController(
                              profileController,
                            );

                            if (profileController.selectedBrand!.id == 'abc') {
                              showCustomSnackBar('select_vehicle_brand'.tr);
                            } else if (profileController.selectedModel.id ==
                                'abc') {
                              showCustomSnackBar('select_vehicle_model'.tr);
                            } else if (profileController.selectedCategory.id ==
                                'abc') {
                              showCustomSnackBar('select_vehicle_category'.tr);
                            } else if (licencePlateNumber.isEmpty) {
                              showCustomSnackBar(
                                'licence_plate_number_is_required'.tr,
                              );
                            } else if (licenceExpiryDateController.text
                                .trim()
                                .isEmpty) {
                              showCustomSnackBar(
                                'Informe a validade do documento do veículo.',
                              );
                              FocusScope.of(context)
                                  .requestFocus(licenceExpiryFocus);
                            } else if (expireDate == null) {
                              showCustomSnackBar(
                                'Informe uma data válida no formato dd/mm/aaaa, com ano até 2050.',
                              );
                              FocusScope.of(context)
                                  .requestFocus(licenceExpiryFocus);
                            } else if (fuelType == 'Select Fuel type') {
                              showCustomSnackBar('fuel_type_is_required'.tr);
                            } else if (widget.vehicleInfo == null &&
                                (_crlvDocument == null ||
                                    _insuranceDocument == null)) {
                              showCustomSnackBar(
                                'Envie o CRLV e o Seguro obrigatório.',
                              );
                            } else {
                              _syncVehicleDocumentsWithController(
                                profileController,
                              );

                              VehicleBody body = VehicleBody(
                                brandId: brandId,
                                modelId: modelId,
                                categoryId: categoryId,
                                licencePlateNumber: licencePlateNumber,
                                licenceExpireDate: expireDate,
                                vinNumber: vinNumber,
                                transmission: transmission,
                                fuelType: fuelType,
                                driverId: profileController.profileInfo!.id ??
                                    "123456789",
                                ownership: 'driver',
                                parcelCapacityWeight:
                                    parcelWeightCapacity.text.trim(),
                              );

                              if (widget.vehicleInfo == null) {
                                profileController.addNewVehicle(body);
                              } else {
                                profileController
                                    .updateVehicle(
                                  body,
                                  Get.find<ProfileController>().driverId,
                                )
                                    .then((onValue) {
                                  if (onValue.statusCode == 200) {
                                    Get.back();
                                  }
                                });
                              }
                            }
                          },
                        ),
                      ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _VehicleDropdownContainer extends StatelessWidget {
  final Widget child;

  const _VehicleDropdownContainer({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: Get.width,
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeDefault,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border.all(
          width: .5,
          color: Theme.of(context).hintColor.withValues(alpha: .45),
        ),
        borderRadius: BorderRadius.circular(Dimensions.paddingSizeOverLarge),
      ),
      child: child,
    );
  }
}

class _VehicleTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final TextStyle style;
  final String hintText;
  final TextInputType keyboardType;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final IconData? suffixIcon;
  final ValueChanged<String>? onSubmitted;

  const _VehicleTextField({
    required this.controller,
    required this.focusNode,
    required this.style,
    required this.hintText,
    required this.keyboardType,
    this.textCapitalization = TextCapitalization.words,
    this.inputFormatters,
    this.suffixIcon,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      style: style,
      textInputAction: TextInputAction.next,
      keyboardType: keyboardType,
      cursorColor: Theme.of(context).primaryColor,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      autofocus: false,
      decoration: InputDecoration(
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: BorderSide(
            width: 0.5,
            color: Theme.of(context).hintColor.withValues(alpha: 0.5),
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: BorderSide(
            width: 0.5,
            color: Theme.of(context).hintColor.withValues(alpha: 0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: BorderSide(
            width: 0.5,
            color: Theme.of(context).primaryColor,
          ),
        ),
        hintText: hintText,
        fillColor: Theme.of(context).cardColor,
        hintStyle: textRegular.copyWith(
          fontSize: Dimensions.fontSizeSmall,
          color: Theme.of(context)
              .textTheme
              .bodyMedium!
              .color!
              .withValues(alpha: 0.58),
        ),
        suffixIcon: suffixIcon == null
            ? null
            : Icon(
                suffixIcon,
                color: Theme.of(context).hintColor,
              ),
        filled: true,
      ),
      onSubmitted: onSubmitted,
    );
  }
}

class _VehicleDocumentHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _VehicleDocumentHeader({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        color: Theme.of(context).primaryColor.withValues(alpha: 0.045),
        border: Border.all(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.14),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textBold.copyWith(
              fontSize: 15.5,
              height: 1.25,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: textMedium.copyWith(
              fontSize: 13.2,
              height: 1.35,
              color: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.color
                  ?.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }
}

class _VehicleDocumentUploadCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isRequired;
  final FilePickerResult? document;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  const _VehicleDocumentUploadCard({
    required this.title,
    required this.subtitle,
    required this.document,
    required this.onTap,
    this.isRequired = false,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final String? fileName = document?.files.first.name;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).hintColor.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        border: Border.all(
          color: Theme.of(context).hintColor.withValues(alpha: 0.12),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: textBold.copyWith(
                    fontSize: 15,
                    height: 1.25,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),
              if (isRequired)
                Text(
                  '*',
                  style: textBold.copyWith(
                    fontSize: 15,
                    color: Colors.redAccent,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: textMedium.copyWith(
              fontSize: 12.8,
              height: 1.35,
              color: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.color
                  ?.withValues(alpha: 0.68),
            ),
          ),
          const SizedBox(height: 14),
          fileName == null
              ? _VehicleUploadEmptyCard(onTap: onTap)
              : _VehicleUploadedFileCard(
                  fileName: fileName,
                  onReplace: onTap,
                  onRemove: onRemove,
                ),
        ],
      ),
    );
  }
}

class _VehicleUploadEmptyCard extends StatelessWidget {
  final VoidCallback onTap;

  const _VehicleUploadEmptyCard({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: DottedBorder(
        options: RoundedRectDottedBorderOptions(
          strokeWidth: 1,
          dashPattern: const [5, 5],
          color: Theme.of(context).primaryColor.withValues(alpha: 0.55),
          radius: const Radius.circular(Dimensions.paddingSizeSmall),
        ),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
            color: Theme.of(context).cardColor,
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(
            vertical: Dimensions.paddingSizeDefault,
            horizontal: Dimensions.paddingSizeSmall,
          ),
          child: Column(
            children: [
              Icon(
                Icons.add_photo_alternate_outlined,
                color: Theme.of(context).primaryColor,
                size: 30,
              ),
              const SizedBox(height: Dimensions.paddingSizeExtraSmall),
              Text(
                'Enviar arquivo ou tirar foto',
                textAlign: TextAlign.center,
                style: textBold.copyWith(
                  fontSize: 13.8,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VehicleUploadedFileCard extends StatelessWidget {
  final String fileName;
  final VoidCallback onReplace;
  final VoidCallback? onRemove;

  const _VehicleUploadedFileCard({
    required this.fileName,
    required this.onReplace,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onReplace,
      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 13,
          vertical: 13,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          border: Border.all(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.18),
            width: 0.8,
          ),
          color: Theme.of(context).cardColor,
        ),
        child: Row(
          children: [
            Icon(
              Icons.description_outlined,
              color: Theme.of(context).primaryColor,
              size: 24,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                fileName,
                overflow: TextOverflow.ellipsis,
                style: textMedium.copyWith(
                  fontSize: 13.5,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ),
            InkWell(
              onTap: onRemove,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.highlight_remove_outlined,
                  color: Colors.red,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleDocumentActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _VehicleDocumentActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          border: Border.all(
            color: Theme.of(context).hintColor.withValues(alpha: 0.22),
            width: 0.8,
          ),
          color: Theme.of(context).cardColor,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: Theme.of(context).primaryColor,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textBold.copyWith(
                      fontSize: 14.5,
                      height: 1.25,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: textMedium.copyWith(
                      fontSize: 12.5,
                      height: 1.3,
                      color: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.color
                          ?.withValues(alpha: 0.72),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleExpiryDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    final String limitedDigits =
        digitsOnly.length > 8 ? digitsOnly.substring(0, 8) : digitsOnly;

    final StringBuffer buffer = StringBuffer();

    for (int i = 0; i < limitedDigits.length; i++) {
      if (i == 2 || i == 4) {
        buffer.write('/');
      }

      buffer.write(limitedDigits[i]);
    }

    final String formattedText = buffer.toString();

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}
