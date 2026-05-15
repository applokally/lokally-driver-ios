import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ride_sharing_user_app/common_widgets/button_widget.dart';
import 'package:ride_sharing_user_app/common_widgets/image_widget.dart';
import 'package:ride_sharing_user_app/common_widgets/text_field_widget.dart';
import 'package:ride_sharing_user_app/data/api_client.dart';
import 'package:ride_sharing_user_app/features/auth/controllers/auth_controller.dart';
import 'package:ride_sharing_user_app/features/auth/domain/models/signup_body.dart';
import 'package:ride_sharing_user_app/features/auth/widgets/signup_appbar_widget.dart';
import 'package:ride_sharing_user_app/helper/display_helper.dart';
import 'package:ride_sharing_user_app/helper/email_checker.dart';
import 'package:ride_sharing_user_app/helper/file_validation_helper.dart';
import 'package:ride_sharing_user_app/util/app_constants.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:ride_sharing_user_app/util/images.dart';
import 'package:ride_sharing_user_app/util/styles.dart';

class AdditionalSignUpScreen2 extends StatefulWidget {
  const AdditionalSignUpScreen2({super.key});

  @override
  State<AdditionalSignUpScreen2> createState() =>
      _AdditionalSignUpScreen2State();
}

class _AdditionalSignUpScreen2State extends State<AdditionalSignUpScreen2> {
  final TextEditingController streetController = TextEditingController();
  final TextEditingController numberController = TextEditingController();
  final TextEditingController neighborhoodController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController stateController = TextEditingController();

  final FocusNode streetNode = FocusNode();
  final FocusNode numberNode = FocusNode();
  final FocusNode neighborhoodNode = FocusNode();
  final FocusNode cityNode = FocusNode();
  final FocusNode stateNode = FocusNode();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final AuthController authController = Get.find<AuthController>();

      if (authController.identityType != 'driving_license') {
        authController.setIdentityType('driving_license');
      }
    });
  }

  @override
  void dispose() {
    streetController.dispose();
    numberController.dispose();
    neighborhoodController.dispose();
    cityController.dispose();
    stateController.dispose();

    streetNode.dispose();
    numberNode.dispose();
    neighborhoodNode.dispose();
    cityNode.dispose();
    stateNode.dispose();

    super.dispose();
  }

  Future<void> _pickCnhImage({
    required AuthController authController,
    required int index,
    required ImageSource source,
  }) async {
    if (index == 1 && authController.identityImages.isEmpty) {
      showCustomSnackBar('Envie primeiro a foto da frente da CNH.');
      return;
    }

    final XFile? image = await FileValidationHelper.validateAndPickImage(
      source: source,
    );

    if (image == null) {
      return;
    }

    final MultipartBody multipartBody = MultipartBody(
      'identity_images[]',
      image,
    );

    if (authController.identityImages.length > index) {
      authController.identityImages[index] = image;
      authController.multipartList[index] = multipartBody;
    } else {
      authController.identityImages.add(image);
      authController.multipartList.add(multipartBody);
    }

    authController.update();
  }

  Future<void> _pickResidenceProofFromUpload(
    AuthController authController,
  ) async {
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
      authController.otherDocuments.add(
        MultipartDocument('upload_documents[]', file),
      );

      authController.update();
    }
  }

  Future<void> _pickResidenceProofFromCamera(
    AuthController authController,
  ) async {
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
          : 'comprovante_residencia_${DateTime.now().millisecondsSinceEpoch}.jpg',
      path: image.path,
      size: fileSize,
    );

    authController.otherDocuments.add(
      MultipartDocument('upload_documents[]', platformFile),
    );

    authController.update();
  }

  void _openImageSourceSheet({
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
              _LokallyActionTile(
                icon: Icons.upload_file_outlined,
                title: 'Enviar arquivo',
                subtitle: 'Selecionar uma imagem ou arquivo do dispositivo',
                onTap: () {
                  Get.back();
                  onUpload();
                },
              ),
              const SizedBox(height: 10),
              _LokallyActionTile(
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

  String _buildAddressSummary() {
    return 'Logradouro: ${streetController.text.trim()}; '
        'Número: ${numberController.text.trim()}; '
        'Bairro: ${neighborhoodController.text.trim()}; '
        'Cidade: ${cityController.text.trim()}; '
        'UF: ${stateController.text.trim().toUpperCase()}';
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

    final ThemeData readableInputTheme = Theme.of(context).copyWith(
      hintColor: readableInputColor,
      inputDecorationTheme: Theme.of(context).inputDecorationTheme.copyWith(
            hintStyle: readableInputTextStyle,
          ),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).cardColor,
      body: SafeArea(
        child: GetBuilder<AuthController>(
          builder: (authController) {
            return Column(
              children: [
                const SignUpAppbarWidget(
                  title: 'signup_as_a_driver',
                  progressText: '3_of_3',
                  enableBackButton: true,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        Dimensions.paddingSizeLarge,
                        Dimensions.paddingSizeLarge,
                        Dimensions.paddingSizeLarge,
                        Dimensions.paddingSizeLarge,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 18),
                          Text(
                            'provide_your_identity'.tr,
                            textAlign: TextAlign.center,
                            style: textBold.copyWith(
                              fontSize: 25,
                              height: 1.18,
                              color:
                                  Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              'this_information_will_help'.tr,
                              textAlign: TextAlign.center,
                              style: textMedium.copyWith(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color
                                    ?.withValues(alpha: 0.82),
                                fontSize: 14.8,
                                height: 1.45,
                              ),
                              maxLines: 3,
                            ),
                          ),
                          const SizedBox(height: 28),
                          _LokallyProfileImage(authController: authController),
                          const SizedBox(height: 28),
                          _LokallyFieldTitle(
                            title: 'email'.tr,
                            isRequired: true,
                          ),
                          Theme(
                            data: readableInputTheme,
                            child: DefaultTextStyle.merge(
                              style: readableInputTextStyle,
                              child: TextFieldWidget(
                                hintText: 'enter_your_email'.tr,
                                inputType: TextInputType.emailAddress,
                                prefixIcon: Images.email,
                                controller: authController.emailController,
                                focusNode: authController.emailNode,
                                nextFocus: streetNode,
                                inputAction: TextInputAction.next,
                                autoFocus:
                                    authController.emailController.text.isEmpty,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          _LokallySectionTitle(
                            title: 'Endereço',
                            subtitle:
                                'Informe o endereço no formato exigido para cadastro.',
                          ),
                          const SizedBox(height: 14),
                          _LokallyFieldTitle(
                            title: 'Logradouro',
                            isRequired: true,
                          ),
                          Theme(
                            data: readableInputTheme,
                            child: DefaultTextStyle.merge(
                              style: readableInputTextStyle,
                              child: TextFieldWidget(
                                hintText: 'Informe o logradouro',
                                capitalization: TextCapitalization.words,
                                inputType: TextInputType.streetAddress,
                                prefixIcon: Images.location,
                                controller: streetController,
                                focusNode: streetNode,
                                nextFocus: numberNode,
                                inputAction: TextInputAction.next,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          _LokallyFieldTitle(
                            title: 'Número',
                            isRequired: true,
                          ),
                          Theme(
                            data: readableInputTheme,
                            child: DefaultTextStyle.merge(
                              style: readableInputTextStyle,
                              child: TextFieldWidget(
                                hintText: 'Informe o número',
                                inputType: TextInputType.text,
                                prefixIcon: Images.location,
                                controller: numberController,
                                focusNode: numberNode,
                                nextFocus: neighborhoodNode,
                                inputAction: TextInputAction.next,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          _LokallyFieldTitle(
                            title: 'Bairro',
                            isRequired: true,
                          ),
                          Theme(
                            data: readableInputTheme,
                            child: DefaultTextStyle.merge(
                              style: readableInputTextStyle,
                              child: TextFieldWidget(
                                hintText: 'Informe o bairro',
                                capitalization: TextCapitalization.words,
                                inputType: TextInputType.text,
                                prefixIcon: Images.location,
                                controller: neighborhoodController,
                                focusNode: neighborhoodNode,
                                nextFocus: cityNode,
                                inputAction: TextInputAction.next,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          _LokallyFieldTitle(
                            title: 'Cidade',
                            isRequired: true,
                          ),
                          Theme(
                            data: readableInputTheme,
                            child: DefaultTextStyle.merge(
                              style: readableInputTextStyle,
                              child: TextFieldWidget(
                                hintText: 'Informe a cidade',
                                capitalization: TextCapitalization.words,
                                inputType: TextInputType.text,
                                prefixIcon: Images.location,
                                controller: cityController,
                                focusNode: cityNode,
                                nextFocus: stateNode,
                                inputAction: TextInputAction.next,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          _LokallyFieldTitle(
                            title: 'UF',
                            isRequired: true,
                          ),
                          Theme(
                            data: readableInputTheme,
                            child: DefaultTextStyle.merge(
                              style: readableInputTextStyle,
                              child: TextFieldWidget(
                                hintText: 'Ex: MG',
                                capitalization: TextCapitalization.characters,
                                inputType: TextInputType.text,
                                prefixIcon: Images.location,
                                controller: stateController,
                                focusNode: stateNode,
                                nextFocus: authController.identityNumberNode,
                                inputAction: TextInputAction.next,
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          _LokallySectionTitle(
                            title: 'Documento do motorista',
                            subtitle:
                                'Para motoristas, o documento obrigatório é a CNH.',
                          ),
                          const SizedBox(height: 14),
                          _LokallyFixedIdentityCard(),
                          const SizedBox(height: 18),
                          _LokallyFieldTitle(
                            title: 'Número da CNH',
                            isRequired: true,
                          ),
                          Theme(
                            data: readableInputTheme,
                            child: DefaultTextStyle.merge(
                              style: readableInputTextStyle,
                              child: TextFieldWidget(
                                hintText: 'Informe o número da CNH',
                                inputType: TextInputType.text,
                                prefixIcon: Images.identity,
                                controller:
                                    authController.identityNumberController,
                                focusNode: authController.identityNumberNode,
                                inputAction: TextInputAction.done,
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          _LokallyUploadSection(
                            title: 'Enviar foto da CNH — Frente',
                            subtitle:
                                '${AppConstants.allowedImageExtensions.map((e) => e).join(', ')} ${FileValidationHelper.getMaxFileSize(true)}',
                            isRequired: true,
                            previewPath:
                                authController.identityImages.isNotEmpty
                                    ? authController.identityImages[0].path
                                    : null,
                            onRemove: authController.identityImages.isNotEmpty
                                ? () => authController.removeImage(0)
                                : null,
                            onTap: () {
                              _openImageSourceSheet(
                                context: context,
                                title: 'Enviar foto da CNH — Frente',
                                onUpload: () => _pickCnhImage(
                                  authController: authController,
                                  index: 0,
                                  source: ImageSource.gallery,
                                ),
                                onCamera: () => _pickCnhImage(
                                  authController: authController,
                                  index: 0,
                                  source: ImageSource.camera,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          _LokallyUploadSection(
                            title: 'Enviar foto da CNH — Verso',
                            subtitle:
                                '${AppConstants.allowedImageExtensions.map((e) => e).join(', ')} ${FileValidationHelper.getMaxFileSize(true)}',
                            isRequired: true,
                            previewPath:
                                authController.identityImages.length > 1
                                    ? authController.identityImages[1].path
                                    : null,
                            onRemove: authController.identityImages.length > 1
                                ? () => authController.removeImage(1)
                                : null,
                            onTap: () {
                              _openImageSourceSheet(
                                context: context,
                                title: 'Enviar foto da CNH — Verso',
                                onUpload: () => _pickCnhImage(
                                  authController: authController,
                                  index: 1,
                                  source: ImageSource.gallery,
                                ),
                                onCamera: () => _pickCnhImage(
                                  authController: authController,
                                  index: 1,
                                  source: ImageSource.camera,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          _LokallyResidenceProofSection(
                            authController: authController,
                            onTapAdd: () {
                              _openImageSourceSheet(
                                context: context,
                                title: 'Comprovante de residência',
                                onUpload: () => _pickResidenceProofFromUpload(
                                  authController,
                                ),
                                onCamera: () => _pickResidenceProofFromCamera(
                                  authController,
                                ),
                              );
                            },
                          ),
                          const SizedBox(
                            height: Dimensions.paddingSizeExtraLarge,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color:
                            Theme.of(context).hintColor.withValues(alpha: 0.15),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(Dimensions.paddingSizeLarge),
                      topLeft: Radius.circular(Dimensions.paddingSizeLarge),
                    ),
                    color: Theme.of(context).cardColor,
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: Dimensions.paddingSizeSmall,
                    horizontal: Dimensions.paddingSizeDefault,
                  ).copyWith(
                    bottom: Dimensions.paddingSizeExtraLarge,
                  ),
                  child: authController.isLoading
                      ? Center(
                          child: SpinKitCircle(
                            color: Theme.of(context).primaryColor,
                            size: 40.0,
                          ),
                        )
                      : ButtonWidget(
                          buttonText: 'submit'.tr,
                          radius: 50,
                          onPressed: () async {
                            String email = authController.emailController.text;
                            String street = streetController.text.trim();
                            String number = numberController.text.trim();
                            String neighborhood =
                                neighborhoodController.text.trim();
                            String city = cityController.text.trim();
                            String state =
                                stateController.text.trim().toUpperCase();
                            String identityNumber = authController
                                .identityNumberController.text
                                .trim();

                            if (authController.pickedProfileFile == null) {
                              showCustomSnackBar(
                                'profile_image_is_required'.tr,
                              );
                            } else if (email.isEmpty) {
                              showCustomSnackBar('email_is_required'.tr);
                              FocusScope.of(context).requestFocus(
                                authController.emailNode,
                              );
                            } else if (EmailChecker.isNotValid(email)) {
                              showCustomSnackBar(
                                'enter_valid_email_address'.tr,
                              );
                              FocusScope.of(context).requestFocus(
                                authController.emailNode,
                              );
                            } else if (street.isEmpty) {
                              showCustomSnackBar('Informe o logradouro.');
                              FocusScope.of(context).requestFocus(streetNode);
                            } else if (number.isEmpty) {
                              showCustomSnackBar(
                                'Informe o número do endereço.',
                              );
                              FocusScope.of(context).requestFocus(numberNode);
                            } else if (neighborhood.isEmpty) {
                              showCustomSnackBar('Informe o bairro.');
                              FocusScope.of(context).requestFocus(
                                neighborhoodNode,
                              );
                            } else if (city.isEmpty) {
                              showCustomSnackBar('Informe a cidade.');
                              FocusScope.of(context).requestFocus(cityNode);
                            } else if (state.isEmpty) {
                              showCustomSnackBar('Informe a UF.');
                              FocusScope.of(context).requestFocus(stateNode);
                            } else if (state.length < 2) {
                              showCustomSnackBar('Informe uma UF válida.');
                              FocusScope.of(context).requestFocus(stateNode);
                            } else if (identityNumber.isEmpty) {
                              showCustomSnackBar('Informe o número da CNH.');
                              FocusScope.of(context).requestFocus(
                                authController.identityNumberNode,
                              );
                            } else if (authController.identityImages.length <
                                2) {
                              showCustomSnackBar(
                                'Envie a foto da frente e do verso da CNH.',
                              );
                            } else if (authController.otherDocuments.isEmpty) {
                              showCustomSnackBar(
                                'Envie o comprovante de residência.',
                              );
                            } else {
                              authController.addressController.text =
                                  _buildAddressSummary();

                              if (authController.identityType !=
                                  'driving_license') {
                                authController.setIdentityType(
                                  'driving_license',
                                );
                              }

                              List<String> services = [];

                              if (authController.isRideShare) {
                                services.add('ride_request');
                              }

                              if (authController.isParcelShare) {
                                services.add('parcel');
                              }

                              String? deviceToken =
                                  await FirebaseMessaging.instance.getToken();

                              SignUpBody signUpBody = SignUpBody(
                                email: email,
                                address: authController.addressController.text,
                                addressStreet: street,
                                addressNumber: number,
                                addressNeighborhood: neighborhood,
                                addressCity: city,
                                addressState: state,
                                addressZipCode: 'nao_informado',
                                identityNumber: identityNumber,
                                identificationType: 'driving_license',
                                fName: authController.fNameController.text,
                                lName: authController.lNameController.text,
                                phone: authController.countryDialCode +
                                    authController.phoneController.text,
                                password:
                                    authController.passwordController.text,
                                confirmPassword: authController
                                    .confirmPasswordController.text,
                                services: services,
                                referralCode: authController
                                    .referralCodeController.text
                                    .trim(),
                                fcmToken: deviceToken,
                              );

                              authController.register(
                                authController.countryDialCode,
                                signUpBody,
                              );
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

class _LokallyProfileImage extends StatelessWidget {
  final AuthController authController;

  const _LokallyProfileImage({
    required this.authController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Foto do perfil',
          textAlign: TextAlign.center,
          style: textBold.copyWith(
            fontSize: 15,
            height: 1.25,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          height: 90,
          width: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Theme.of(context).primaryColor,
              width: 1.2,
            ),
          ),
          child: Center(
            child: Stack(
              alignment: AlignmentDirectional.center,
              clipBehavior: Clip.none,
              children: [
                authController.pickedProfileFile == null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: const ImageWidget(
                          image: '',
                          height: 84,
                          width: 84,
                          placeholder: Images.personPlaceholder,
                        ),
                      )
                    : CircleAvatar(
                        radius: 42,
                        backgroundImage: FileImage(
                          File(authController.pickedProfileFile!.path),
                        ),
                      ),
                Positioned(
                  right: 2,
                  bottom: -2,
                  child: InkWell(
                    onTap: () => authController.pickImage(false, true),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(7),
                      child: const Icon(
                        Icons.camera_enhance_rounded,
                        color: Colors.white,
                        size: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LokallySectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _LokallySectionTitle({
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

class _LokallyFieldTitle extends StatelessWidget {
  final String title;
  final bool isRequired;

  const _LokallyFieldTitle({
    required this.title,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 8,
        left: 2,
      ),
      child: Row(
        children: [
          Text(
            title,
            style: textBold.copyWith(
              fontSize: 15,
              height: 1.25,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          if (isRequired)
            Text(
              '*',
              style: textBold.copyWith(
                fontSize: 15,
                height: 1.25,
                color: Colors.redAccent,
              ),
            ),
        ],
      ),
    );
  }
}

class _LokallyFixedIdentityCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 15,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        border: Border.all(
          color: Theme.of(context).hintColor.withValues(alpha: 0.28),
          width: 0.8,
        ),
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).hintColor.withValues(alpha: 0.06),
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Image.asset(
            Images.identityIcon,
            height: 22,
            width: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'CNH — Carteira Nacional de Habilitação',
              style: textBold.copyWith(
                fontSize: 14.5,
                height: 1.3,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ),
          Icon(
            Icons.check_circle,
            color: Theme.of(context).primaryColor,
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _LokallyUploadSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isRequired;
  final String? previewPath;
  final VoidCallback? onRemove;
  final VoidCallback onTap;

  const _LokallyUploadSection({
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isRequired = false,
    this.previewPath,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
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
          previewPath == null
              ? _LokallyUploadEmptyCard(onTap: onTap)
              : _LokallyImagePreviewCard(
                  path: previewPath!,
                  onRemove: onRemove,
                  onReplace: onTap,
                ),
        ],
      ),
    );
  }
}

class _LokallyUploadEmptyCard extends StatelessWidget {
  final VoidCallback onTap;

  const _LokallyUploadEmptyCard({
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

class _LokallyImagePreviewCard extends StatelessWidget {
  final String path;
  final VoidCallback? onRemove;
  final VoidCallback onReplace;

  const _LokallyImagePreviewCard({
    required this.path,
    required this.onReplace,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: onReplace,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            child: Image.file(
              File(path),
              width: double.infinity,
              height: 132,
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: InkWell(
            onTap: onRemove,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(6),
              child: const Icon(
                Icons.delete_forever_rounded,
                color: Colors.red,
                size: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LokallyResidenceProofSection extends StatelessWidget {
  final AuthController authController;
  final VoidCallback onTapAdd;

  const _LokallyResidenceProofSection({
    required this.authController,
    required this.onTapAdd,
  });

  @override
  Widget build(BuildContext context) {
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
                  'Comprovante de residência',
                  style: textBold.copyWith(
                    fontSize: 15,
                    height: 1.25,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),
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
            '${AppConstants.registrationAllowExtensions.map((e) => e).join(', ')} ${FileValidationHelper.getMaxFileSize(false)}',
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
          ...authController.otherDocuments.asMap().entries.map(
                (entry) => _LokallyDocumentPreviewCard(
                  fileName: entry.value.file?.name ?? 'Comprovante enviado',
                  onRemove: () => authController.removeFile(entry.key),
                ),
              ),
          _LokallyUploadEmptyCard(onTap: onTapAdd),
        ],
      ),
    );
  }
}

class _LokallyDocumentPreviewCard extends StatelessWidget {
  final String fileName;
  final VoidCallback onRemove;

  const _LokallyDocumentPreviewCard({
    required this.fileName,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
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

class _LokallyActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _LokallyActionTile({
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
