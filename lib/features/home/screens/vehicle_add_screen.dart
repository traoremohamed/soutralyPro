import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ride_sharing_user_app/common_widgets/app_bar_widget.dart';
import 'package:ride_sharing_user_app/common_widgets/button_widget.dart';
import 'package:ride_sharing_user_app/common_widgets/date_picker_widget.dart';
import 'package:ride_sharing_user_app/data/api_client.dart';
import 'package:ride_sharing_user_app/features/auth/widgets/text_field_title_widget.dart';
import 'package:ride_sharing_user_app/features/profile/controllers/profile_controller.dart';
import 'package:ride_sharing_user_app/features/profile/domain/models/profile_model.dart';
import 'package:ride_sharing_user_app/features/profile/domain/models/vehicle_body.dart';
import 'package:ride_sharing_user_app/features/profile/domain/models/vehicle_brand_model.dart';
import 'package:ride_sharing_user_app/features/splash/controllers/splash_controller.dart';
import 'package:ride_sharing_user_app/helper/display_helper.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:ride_sharing_user_app/util/images.dart';
import 'package:ride_sharing_user_app/util/styles.dart';

class VehicleAddScreen extends StatefulWidget {
  final Vehicle? vehicleInfo;
  const VehicleAddScreen({super.key, this.vehicleInfo});

  @override
  State<VehicleAddScreen> createState() => _VehicleAddScreenState();
}

class _VehicleAddScreenState extends State<VehicleAddScreen> {
  final TextEditingController licencePlateNumberController =
      TextEditingController();
  final TextEditingController parcelWeightCapacityController =
      TextEditingController();
  final TextEditingController vehicleYearController = TextEditingController();
  final TextEditingController vehicleColorController = TextEditingController();

  final FocusNode licencePlateFocus = FocusNode();
  final FocusNode parcelWeightFocus = FocusNode();
  final FocusNode vehicleYearFocus = FocusNode();
  final FocusNode vehicleColorFocus = FocusNode();

  DateTime? licenceExpireDate;
  DateTime? technicalInspectionExpiryDate;
  DateTime? insuranceExpiryDate;
  DateTime? patenteExpiryDate;

  PlatformFile? registrationCardFile;
  PlatformFile? registrationCardBackFile;
  PlatformFile? technicalInspectionFile;
  PlatformFile? technicalInspectionBackFile;
  PlatformFile? insuranceFile;
  PlatformFile? insuranceBackFile;
  PlatformFile? patenteFile;
  PlatformFile? patenteBackFile;

  XFile? frontPhoto;
  XFile? backPhoto;
  XFile? leftPhoto;
  XFile? rightPhoto;

  String? selectedDocumentType;
  PlatformFile? selectedDocumentRectoFile;
  PlatformFile? selectedDocumentVersoFile;
  DateTime? selectedDocumentExpiryDate;

  final ImagePicker _imagePicker = ImagePicker();

  static const Map<String, String> _documentLabels = {
    'registration_card': 'Carte grise',
    'technical_inspection_document': 'Visite technique',
    'insurance_document': 'Assurance',
    'patente_document': 'Patente',
  };

  bool get _isEditMode => widget.vehicleInfo != null;

  @override
  void initState() {
    super.initState();
    final profileController = Get.find<ProfileController>();
    profileController.getVehicleBrandList(1);
    profileController.getCategoryList(1);
    profileController.clearVehicleData();

    if (widget.vehicleInfo != null) {
      final Vehicle vehicle = widget.vehicleInfo!;
      licencePlateNumberController.text = vehicle.licencePlateNumber ?? '';
      parcelWeightCapacityController.text =
          (vehicle.parcelWeightCapacity ?? '').toString();
      vehicleYearController.text = (vehicle.vehicleYear ?? '').toString();
      vehicleColorController.text = vehicle.vehicleColor ?? '';

      if (vehicle.licenceExpireDate != null &&
          vehicle.licenceExpireDate!.isNotEmpty) {
        licenceExpireDate = DateTime.tryParse(vehicle.licenceExpireDate!);
      }
      if (vehicle.technicalInspectionExpiryDate != null &&
          vehicle.technicalInspectionExpiryDate!.isNotEmpty) {
        technicalInspectionExpiryDate =
            DateTime.tryParse(vehicle.technicalInspectionExpiryDate!);
      }
      if (vehicle.insuranceExpiryDate != null &&
          vehicle.insuranceExpiryDate!.isNotEmpty) {
        insuranceExpiryDate = DateTime.tryParse(vehicle.insuranceExpiryDate!);
      }
      if (vehicle.patenteExpiryDate != null &&
          vehicle.patenteExpiryDate!.isNotEmpty) {
        patenteExpiryDate = DateTime.tryParse(vehicle.patenteExpiryDate!);
      }
    }
  }

  Future<void> _pickFile(void Function(PlatformFile file) onPicked) async {
    final FilePickerResult? result =
        await FilePicker.platform.pickFiles(withReadStream: true);
    if (result != null && result.files.isNotEmpty) {
      onPicked(result.files.first);
      setState(() {});
    }
  }

  Future<void> _takePhoto(void Function(XFile file) onPicked) async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (image != null) {
      onPicked(image);
      setState(() {});
    }
  }

  Widget _dropdownContainer({required Widget child}) {
    return Container(
      width: Get.width,
      padding:
          const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border.all(
          width: .5,
          color: Theme.of(context).hintColor.withValues(alpha: .7),
        ),
        borderRadius: BorderRadius.circular(Dimensions.paddingSizeOverLarge),
      ),
      child: child,
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? formatters,
    TextInputAction action = TextInputAction.next,
    FocusNode? nextFocus,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      style: textRegular.copyWith(
        fontSize: Dimensions.fontSizeDefault,
        color: Theme.of(context).textTheme.bodyMedium?.color,
      ),
      textInputAction: action,
      keyboardType: keyboardType,
      inputFormatters: formatters,
      cursorColor: Theme.of(context).primaryColor,
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
          borderSide:
              BorderSide(width: 0.5, color: Theme.of(context).primaryColor),
        ),
        hintText: hint,
        fillColor: Theme.of(context).cardColor,
        hintStyle: textRegular.copyWith(
          fontSize: Dimensions.fontSizeSmall,
          color: Theme.of(context)
              .textTheme
              .bodyMedium!
              .color!
              .withValues(alpha: 0.5),
        ),
        filled: true,
      ),
      onSubmitted: (_) {
        if (nextFocus != null) {
          FocusScope.of(context).requestFocus(nextFocus);
        }
      },
    );
  }

  Widget _fileTile({
    required String label,
    required PlatformFile? file,
    required VoidCallback onTap,
    bool isRequired = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFieldTitleWidget(title: label, isRequired: isRequired),
        InkWell(
          onTap: onTap,
          child: Container(
            width: Get.width,
            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(Dimensions.paddingSizeDefault),
              border: Border.all(
                color: Theme.of(context).hintColor.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.upload_file, color: Theme.of(context).primaryColor),
                const SizedBox(width: Dimensions.paddingSizeSmall),
                Expanded(
                  child: Text(
                    file?.name ?? 'Selectionner un fichier',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: Dimensions.paddingSizeSmall),
      ],
    );
  }

  Widget _photoTile({
    required String label,
    required XFile? image,
    required VoidCallback onTap,
    bool isRequired = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFieldTitleWidget(title: label, isRequired: isRequired),
        InkWell(
          onTap: onTap,
          child: Container(
            width: Get.width,
            height: 140,
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(Dimensions.paddingSizeDefault),
              border: Border.all(
                color: Theme.of(context).hintColor.withValues(alpha: 0.4),
              ),
              color: Theme.of(context).cardColor,
            ),
            child: image == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.photo_camera_outlined,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(
                        height: Dimensions.paddingSizeExtraSmall,
                      ),
                      const Text('Prendre une photo'),
                    ],
                  )
                : ClipRRect(
                    borderRadius:
                        BorderRadius.circular(Dimensions.paddingSizeDefault),
                    child: Image.file(File(image.path), fit: BoxFit.cover),
                  ),
          ),
        ),
        const SizedBox(height: Dimensions.paddingSizeSmall),
      ],
    );
  }

  Widget _documentSection({
    required String title,
    required PlatformFile? rectoFile,
    required PlatformFile? versoFile,
    required VoidCallback onRectoTap,
    required VoidCallback onVersoTap,
    DateTime? expiryDate,
    VoidCallback? onExpiryTap,
    String? expiryTitle,
    bool requiredField = true,
  }) {
    final profileController = Get.find<ProfileController>();

    return Container(
      margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeLarge),
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).highlightColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textMedium.copyWith(
              color: Theme.of(context).primaryColor,
              fontSize: Dimensions.fontSizeLarge,
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          _fileTile(
            label: '$title - Recto',
            file: rectoFile,
            onTap: onRectoTap,
            isRequired: requiredField,
          ),
          _fileTile(
            label: '$title - Verso',
            file: versoFile,
            onTap: onVersoTap,
            isRequired: requiredField,
          ),
          if (onExpiryTap != null && expiryTitle != null)
            DatePickerWidget(
              title: expiryTitle,
              text: expiryDate != null
                  ? profileController.dateFormat.format(expiryDate).toString()
                  : 'dd-mm-yyyy',
              image: Images.calender,
              requiredField: requiredField,
              selectDate: onExpiryTap,
            ),
        ],
      ),
    );
  }

  Future<void> _pickDate(void Function(DateTime date) setter) async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      setState(() {
        setter(date);
      });
    }
  }

  bool _documentRequiresExpiry(String documentType) {
    return documentType != 'registration_card';
  }

  String _existingDocumentSummary(String documentType) {
    final vehicle = widget.vehicleInfo;
    if (vehicle == null) {
      return '--';
    }

    switch (documentType) {
      case 'registration_card':
        return (vehicle.registrationCard?.isNotEmpty == true ||
                vehicle.registrationCardBack?.isNotEmpty == true)
            ? 'Document existant disponible'
            : '--';
      case 'technical_inspection_document':
        return (vehicle.technicalInspectionDocument?.isNotEmpty == true ||
                vehicle.technicalInspectionDocumentBack?.isNotEmpty == true)
            ? 'Document existant disponible'
            : '--';
      case 'insurance_document':
        return (vehicle.insuranceDocument?.isNotEmpty == true ||
                vehicle.insuranceDocumentBack?.isNotEmpty == true)
            ? 'Document existant disponible'
            : '--';
      case 'patente_document':
        return (vehicle.patenteDocument?.isNotEmpty == true ||
                vehicle.patenteDocumentBack?.isNotEmpty == true)
            ? 'Document existant disponible'
            : '--';
      default:
        return '--';
    }
  }

  DateTime? _existingDocumentExpiry(String documentType) {
    switch (documentType) {
      case 'technical_inspection_document':
        return technicalInspectionExpiryDate;
      case 'insurance_document':
        return insuranceExpiryDate;
      case 'patente_document':
        return patenteExpiryDate;
      default:
        return null;
    }
  }

  void _resetSelectedDocumentDraft() {
    selectedDocumentRectoFile = null;
    selectedDocumentVersoFile = null;
    selectedDocumentExpiryDate = null;
  }

  List<MultipartDocument> _buildCreateDocuments() {
    return [
      MultipartDocument('registration_card', registrationCardFile),
      MultipartDocument('registration_card_back', registrationCardBackFile),
      MultipartDocument(
        'technical_inspection_document',
        technicalInspectionFile,
      ),
      MultipartDocument(
        'technical_inspection_document_back',
        technicalInspectionBackFile,
      ),
      MultipartDocument('insurance_document', insuranceFile),
      MultipartDocument('insurance_document_back', insuranceBackFile),
      MultipartDocument('patente_document', patenteFile),
      MultipartDocument('patente_document_back', patenteBackFile),
    ];
  }

  List<MultipartDocument> _buildUpdateDocuments() {
    if (selectedDocumentType == null) {
      return <MultipartDocument>[];
    }

    return [
      MultipartDocument(selectedDocumentType!, selectedDocumentRectoFile),
      MultipartDocument(
          '${selectedDocumentType!}_back', selectedDocumentVersoFile),
    ];
  }

  List<MultipartBody> _buildImages() {
    final List<MultipartBody> images = [];
    if (frontPhoto != null) {
      images.add(MultipartBody('vehicle_front_image', frontPhoto));
    }
    if (backPhoto != null) {
      images.add(MultipartBody('vehicle_back_image', backPhoto));
    }
    if (leftPhoto != null) {
      images.add(MultipartBody('vehicle_left_image', leftPhoto));
    }
    if (rightPhoto != null) {
      images.add(MultipartBody('vehicle_right_image', rightPhoto));
    }
    return images;
  }

  bool _validateCommonFields(ProfileController profileController) {
    final String brandId = profileController.selectedBrand?.id ?? 'abc';
    final String modelId = profileController.selectedModel.id ?? 'abc';
    final List<String> categoryIds = profileController.selectedCategoryIds;
    final String categoryId =
        categoryIds.isNotEmpty ? categoryIds.first : 'abc';
    final String licencePlateNumber = licencePlateNumberController.text.trim();
    final String vehicleYear = vehicleYearController.text.trim();
    final String vehicleColor = vehicleColorController.text.trim();

    if (brandId == 'abc') {
      showCustomSnackBar('select_vehicle_brand'.tr);
      return false;
    }
    if (modelId == 'abc') {
      showCustomSnackBar('select_vehicle_model'.tr);
      return false;
    }
    if (categoryId == 'abc') {
      showCustomSnackBar('select_vehicle_category'.tr);
      return false;
    }
    if (licencePlateNumber.isEmpty) {
      showCustomSnackBar('L\'immatriculation est obligatoire');
      return false;
    }
    if (licenceExpireDate == null) {
      showCustomSnackBar(
          'La date d\'expiration du permis de conduire est obligatoire');
      return false;
    }
    if (vehicleYear.isEmpty) {
      showCustomSnackBar('L\'annee du vehicule est obligatoire');
      return false;
    }
    if (vehicleColor.isEmpty) {
      showCustomSnackBar('La couleur de la voiture est obligatoire');
      return false;
    }
    return true;
  }

  bool _validateCreateDocuments() {
    if (registrationCardFile == null || registrationCardBackFile == null) {
      showCustomSnackBar('La carte grise recto et verso est obligatoire');
      return false;
    }
    if (technicalInspectionFile == null ||
        technicalInspectionBackFile == null) {
      showCustomSnackBar('La visite technique recto et verso est obligatoire');
      return false;
    }
    if (technicalInspectionExpiryDate == null) {
      showCustomSnackBar(
          'La date d\'expiration de la visite technique est obligatoire');
      return false;
    }
    if (insuranceFile == null || insuranceBackFile == null) {
      showCustomSnackBar('L\'assurance recto et verso est obligatoire');
      return false;
    }
    if (insuranceExpiryDate == null) {
      showCustomSnackBar(
          'La date d\'expiration de l\'assurance est obligatoire');
      return false;
    }
    if (patenteFile == null || patenteBackFile == null) {
      showCustomSnackBar('La patente recto et verso est obligatoire');
      return false;
    }
    if (patenteExpiryDate == null) {
      showCustomSnackBar('La date d\'expiration de la patente est obligatoire');
      return false;
    }
    if (frontPhoto == null ||
        backPhoto == null ||
        leftPhoto == null ||
        rightPhoto == null) {
      showCustomSnackBar(
          'Veuillez prendre les 4 photos du vehicule (avant, arriere, gauche, droite)');
      return false;
    }
    return true;
  }

  bool _validateSelectedDocumentUpdate() {
    if (selectedDocumentType == null) {
      return true;
    }
    if (selectedDocumentRectoFile == null ||
        selectedDocumentVersoFile == null) {
      showCustomSnackBar(
          'Veuillez charger le recto et le verso du document selectionne');
      return false;
    }
    if (_documentRequiresExpiry(selectedDocumentType!) &&
        selectedDocumentExpiryDate == null) {
      showCustomSnackBar(
          'Veuillez renseigner la date d\'expiration du document selectionne');
      return false;
    }
    return true;
  }

  VehicleBody _buildVehicleBody(ProfileController profileController) {
    final List<String> categoryIds = profileController.selectedCategoryIds;

    String? technicalExpiry = technicalInspectionExpiryDate != null
        ? profileController.dateFormat.format(technicalInspectionExpiryDate!)
        : null;
    String? insuranceExpiry = insuranceExpiryDate != null
        ? profileController.dateFormat.format(insuranceExpiryDate!)
        : null;
    String? patenteExpiry = patenteExpiryDate != null
        ? profileController.dateFormat.format(patenteExpiryDate!)
        : null;

    if (_isEditMode && selectedDocumentType != null) {
      if (selectedDocumentType == 'technical_inspection_document' &&
          selectedDocumentExpiryDate != null) {
        technicalExpiry =
            profileController.dateFormat.format(selectedDocumentExpiryDate!);
      }
      if (selectedDocumentType == 'insurance_document' &&
          selectedDocumentExpiryDate != null) {
        insuranceExpiry =
            profileController.dateFormat.format(selectedDocumentExpiryDate!);
      }
      if (selectedDocumentType == 'patente_document' &&
          selectedDocumentExpiryDate != null) {
        patenteExpiry =
            profileController.dateFormat.format(selectedDocumentExpiryDate!);
      }
    }

    return VehicleBody(
      brandId: profileController.selectedBrand?.id ?? 'abc',
      modelId: profileController.selectedModel.id ?? 'abc',
      categoryId: categoryIds.isNotEmpty ? categoryIds.first : 'abc',
      categoryIds: categoryIds,
      licencePlateNumber: licencePlateNumberController.text.trim(),
      licenceExpireDate: licenceExpireDate != null
          ? profileController.dateFormat.format(licenceExpireDate!).toString()
          : null,
      fuelType: 'n/a',
      vehicleYear: vehicleYearController.text.trim(),
      vehicleColor: vehicleColorController.text.trim(),
      technicalInspectionExpiryDate: technicalExpiry,
      insuranceExpiryDate: insuranceExpiry,
      patenteExpiryDate: patenteExpiry,
      driverId: profileController.profileInfo?.id ?? '0',
      ownership: 'driver',
      parcelCapacityWeight: parcelWeightCapacityController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Scaffold(
        appBar: AppBarWidget(
          title: _isEditMode ? 'update_vehicle'.tr : 'vehicle_setup'.tr,
          regularAppbar: true,
        ),
        body: GetBuilder<ProfileController>(
          builder: (profileController) {
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingSizeDefault,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        top: Dimensions.paddingSizeDefault,
                        bottom: Dimensions.paddingSizeDefault,
                      ),
                      child: Text(
                        _isEditMode
                            ? 'Modification du vehicule'
                            : 'vehicle_information'.tr,
                        style: textMedium.copyWith(
                          color: Theme.of(context).primaryColor,
                          fontSize: Dimensions.fontSizeLarge,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFieldTitleWidget(
                              title: 'vehicle_brand'.tr,
                              isRequired: true,
                            ),
                            if (profileController.brandList.isNotEmpty)
                              Container(
                                width: Get.width * 0.45,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: Dimensions.paddingSizeDefault,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  border: Border.all(
                                    width: .5,
                                    color: Theme.of(context)
                                        .hintColor
                                        .withValues(alpha: .7),
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    Dimensions.paddingSizeOverLarge,
                                  ),
                                ),
                                child: DropdownButton(
                                  items:
                                      profileController.brandList.map((item) {
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
                                  onChanged: (newVal) => profileController
                                      .setBrandIndex(newVal!, true),
                                  isExpanded: true,
                                  underline: const SizedBox(),
                                  value: profileController.selectedBrand ??
                                      Brand(
                                        id: 'abc',
                                        name: 'Select Brand Model',
                                      ),
                                ),
                              ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (profileController.modelList.isNotEmpty)
                              TextFieldTitleWidget(
                                title: 'vehicle_model'.tr,
                                isRequired: true,
                              ),
                            if (profileController.modelList.isNotEmpty)
                              Container(
                                width: Get.width * 0.45,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: Dimensions.paddingSizeDefault,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  border: Border.all(
                                    width: .5,
                                    color: Theme.of(context)
                                        .hintColor
                                        .withValues(alpha: .7),
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    Dimensions.paddingSizeOverLarge,
                                  ),
                                ),
                                child: DropdownButton(
                                  items:
                                      profileController.modelList.map((item) {
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
                                  onChanged: (newVal) => profileController
                                      .setModelIndex(newVal!, true),
                                  isExpanded: true,
                                  underline: const SizedBox(),
                                  value: profileController.selectedModel,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    TextFieldTitleWidget(
                      title: 'Categorie (Fariman / Choco / Gbonhi)',
                      isRequired: true,
                    ),
                    if (profileController.categoryList.isNotEmpty)
                      _dropdownContainer(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: Dimensions.paddingSizeSmall,
                              runSpacing: Dimensions.paddingSizeSmall,
                              children: profileController.categoryList
                                  .where((item) => item.id != 'abc')
                                  .map((item) {
                                final bool isSelected = profileController
                                    .selectedCategoryIds
                                    .contains(item.id);
                                return FilterChip(
                                  selected: isSelected,
                                  label: Text(item.name!.tr),
                                  onSelected: (_) => profileController
                                      .setCategoryIndex(item, true),
                                );
                              }).toList(),
                            ),
                            if (profileController
                                .selectedCategoryIds.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: Dimensions.paddingSizeExtraSmall,
                                  bottom: Dimensions.paddingSizeExtraSmall,
                                ),
                                child: Text(
                                  'Choisir Fariman inclut automatiquement Choco et Gbonhi. Choisir Choco inclut Gbonhi.',
                                  style: textRegular.copyWith(
                                    fontSize: Dimensions.fontSizeSmall,
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyMedium!
                                        .color!
                                        .withValues(alpha: 0.55),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    TextFieldTitleWidget(
                      title:
                          "${'parcel_weight_capacity'.tr} (${Get.find<SplashController>().config?.parcelWeightUnit})",
                    ),
                    _textField(
                      controller: parcelWeightCapacityController,
                      focusNode: parcelWeightFocus,
                      hint: 'enter_max_weight'.tr,
                      keyboardType: TextInputType.number,
                      nextFocus: licencePlateFocus,
                    ),
                    TextFieldTitleWidget(
                      title: 'IMMATRICULATION',
                      isRequired: true,
                    ),
                    _textField(
                      controller: licencePlateNumberController,
                      focusNode: licencePlateFocus,
                      hint: 'EX: DB-3212',
                      nextFocus: vehicleYearFocus,
                    ),
                    DatePickerWidget(
                      title: "DATE D'EXPIRATION DU PERMIS DE CONDUIRE",
                      text: licenceExpireDate != null
                          ? profileController.dateFormat
                              .format(licenceExpireDate!)
                              .toString()
                          : 'dd-mm-yyyy',
                      image: Images.calender,
                      requiredField: true,
                      selectDate: () =>
                          _pickDate((date) => licenceExpireDate = date),
                    ),
                    TextFieldTitleWidget(
                      title: 'Annee du vehicule',
                      isRequired: true,
                    ),
                    _textField(
                      controller: vehicleYearController,
                      focusNode: vehicleYearFocus,
                      hint: 'Ex: 2020',
                      keyboardType: TextInputType.number,
                      formatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      nextFocus: vehicleColorFocus,
                    ),
                    TextFieldTitleWidget(
                      title: 'Couleur de la voiture',
                      isRequired: true,
                    ),
                    _textField(
                      controller: vehicleColorController,
                      focusNode: vehicleColorFocus,
                      hint: 'Ex: Blanc',
                      action: TextInputAction.done,
                    ),
                    const SizedBox(height: Dimensions.paddingSizeDefault),
                    if (!_isEditMode) ...[
                      _documentSection(
                        title: 'Carte grise',
                        rectoFile: registrationCardFile,
                        versoFile: registrationCardBackFile,
                        onRectoTap: () =>
                            _pickFile((file) => registrationCardFile = file),
                        onVersoTap: () => _pickFile(
                            (file) => registrationCardBackFile = file),
                      ),
                      _documentSection(
                        title: 'Visite technique',
                        rectoFile: technicalInspectionFile,
                        versoFile: technicalInspectionBackFile,
                        onRectoTap: () =>
                            _pickFile((file) => technicalInspectionFile = file),
                        onVersoTap: () => _pickFile(
                            (file) => technicalInspectionBackFile = file),
                        expiryDate: technicalInspectionExpiryDate,
                        expiryTitle: 'Date expiration visite technique',
                        onExpiryTap: () => _pickDate(
                            (date) => technicalInspectionExpiryDate = date),
                      ),
                      _documentSection(
                        title: 'Assurance',
                        rectoFile: insuranceFile,
                        versoFile: insuranceBackFile,
                        onRectoTap: () =>
                            _pickFile((file) => insuranceFile = file),
                        onVersoTap: () =>
                            _pickFile((file) => insuranceBackFile = file),
                        expiryDate: insuranceExpiryDate,
                        expiryTitle: 'Date expiration assurance',
                        onExpiryTap: () =>
                            _pickDate((date) => insuranceExpiryDate = date),
                      ),
                      _documentSection(
                        title: 'Patente',
                        rectoFile: patenteFile,
                        versoFile: patenteBackFile,
                        onRectoTap: () =>
                            _pickFile((file) => patenteFile = file),
                        onVersoTap: () =>
                            _pickFile((file) => patenteBackFile = file),
                        expiryDate: patenteExpiryDate,
                        expiryTitle: 'Date expiration patente',
                        onExpiryTap: () =>
                            _pickDate((date) => patenteExpiryDate = date),
                      ),
                    ] else ...[
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(
                          bottom: Dimensions.paddingSizeLarge,
                        ),
                        padding: const EdgeInsets.all(
                          Dimensions.paddingSizeDefault,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .highlightColor
                              .withValues(alpha: 0.08),
                          borderRadius:
                              BorderRadius.circular(Dimensions.radiusDefault),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Modification selective des documents',
                              style: textMedium.copyWith(
                                color: Theme.of(context).primaryColor,
                                fontSize: Dimensions.fontSizeLarge,
                              ),
                            ),
                            const SizedBox(height: Dimensions.paddingSizeSmall),
                            Text(
                              'Selectionnez le document a modifier, puis chargez le recto, le verso et la date d\'expiration si necessaire.',
                              style: textRegular.copyWith(
                                color: Theme.of(context).hintColor,
                              ),
                            ),
                            const SizedBox(
                                height: Dimensions.paddingSizeDefault),
                            TextFieldTitleWidget(title: 'Document a modifier'),
                            _dropdownContainer(
                              child: DropdownButton<String>(
                                value: selectedDocumentType,
                                isExpanded: true,
                                underline: const SizedBox(),
                                hint: const Text('Selectionner un document'),
                                items: _documentLabels.entries.map((entry) {
                                  return DropdownMenuItem<String>(
                                    value: entry.key,
                                    child: Text(entry.value),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    selectedDocumentType = value;
                                    _resetSelectedDocumentDraft();
                                  });
                                },
                              ),
                            ),
                            if (selectedDocumentType != null) ...[
                              const SizedBox(
                                height: Dimensions.paddingSizeSmall,
                              ),
                              Text(
                                'Document actuel: ${_existingDocumentSummary(selectedDocumentType!)}',
                                style: textRegular.copyWith(
                                  color: Theme.of(context).hintColor,
                                ),
                              ),
                              if (_documentRequiresExpiry(
                                  selectedDocumentType!))
                                Text(
                                  'Expiration actuelle: ${_existingDocumentExpiry(selectedDocumentType!) != null ? profileController.dateFormat.format(_existingDocumentExpiry(selectedDocumentType!)!).toString() : '--'}',
                                  style: textRegular.copyWith(
                                    color: Theme.of(context).hintColor,
                                  ),
                                ),
                              const SizedBox(
                                height: Dimensions.paddingSizeDefault,
                              ),
                              _documentSection(
                                title: _documentLabels[selectedDocumentType!]!,
                                rectoFile: selectedDocumentRectoFile,
                                versoFile: selectedDocumentVersoFile,
                                onRectoTap: () => _pickFile(
                                    (file) => selectedDocumentRectoFile = file),
                                onVersoTap: () => _pickFile(
                                    (file) => selectedDocumentVersoFile = file),
                                expiryDate: selectedDocumentExpiryDate,
                                expiryTitle: _documentRequiresExpiry(
                                        selectedDocumentType!)
                                    ? 'Date expiration ${_documentLabels[selectedDocumentType!]!.toLowerCase()}'
                                    : null,
                                onExpiryTap: _documentRequiresExpiry(
                                        selectedDocumentType!)
                                    ? () => _pickDate((date) =>
                                        selectedDocumentExpiryDate = date)
                                    : null,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                    _photoTile(
                      label: 'Photo vehicule - Avant (plaque lisible)',
                      image: frontPhoto,
                      onTap: () => _takePhoto((file) => frontPhoto = file),
                      isRequired: !_isEditMode,
                    ),
                    _photoTile(
                      label: 'Photo vehicule - Arriere (plaque lisible)',
                      image: backPhoto,
                      onTap: () => _takePhoto((file) => backPhoto = file),
                      isRequired: !_isEditMode,
                    ),
                    _photoTile(
                      label: 'Photo vehicule - Cote gauche',
                      image: leftPhoto,
                      onTap: () => _takePhoto((file) => leftPhoto = file),
                      isRequired: !_isEditMode,
                    ),
                    _photoTile(
                      label: 'Photo vehicule - Cote droit',
                      image: rightPhoto,
                      onTap: () => _takePhoto((file) => rightPhoto = file),
                      isRequired: !_isEditMode,
                    ),
                    const SizedBox(height: Dimensions.paddingSizeLarge),
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
                        : ButtonWidget(
                            radius: Dimensions.radiusExtraLarge,
                            buttonText: _isEditMode
                                ? 'update_and_send_request'.tr
                                : 'save'.tr,
                            onPressed: () {
                              if (!_validateCommonFields(profileController)) {
                                return;
                              }

                              if (!_isEditMode && !_validateCreateDocuments()) {
                                return;
                              }

                              if (_isEditMode &&
                                  !_validateSelectedDocumentUpdate()) {
                                return;
                              }

                              final VehicleBody body =
                                  _buildVehicleBody(profileController);
                              final List<MultipartBody> images = _buildImages();
                              final List<MultipartDocument> files = _isEditMode
                                  ? _buildUpdateDocuments()
                                  : _buildCreateDocuments();

                              if (_isEditMode) {
                                profileController
                                    .updateVehicle(
                                  body,
                                  Get.find<ProfileController>().driverId,
                                  images,
                                  files,
                                )
                                    .then((response) {
                                  if (response.statusCode == 200) {
                                    Get.back();
                                  }
                                });
                              } else {
                                profileController.addNewVehicle(
                                  body,
                                  images,
                                  files,
                                );
                              }
                            },
                          ),
                    const SizedBox(height: Dimensions.paddingSizeExtraLarge),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
