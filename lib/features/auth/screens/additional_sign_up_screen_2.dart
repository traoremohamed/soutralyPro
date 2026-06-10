import 'dart:io';
import 'package:dotted_border/dotted_border.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/features/auth/widgets/signup_appbar_widget.dart';
import 'package:ride_sharing_user_app/features/html/domain/html_enum_types.dart';
import 'package:ride_sharing_user_app/features/html/screens/policy_viewer_screen.dart';
import 'package:ride_sharing_user_app/helper/display_helper.dart';
import 'package:ride_sharing_user_app/helper/email_checker.dart';
import 'package:ride_sharing_user_app/helper/profile_helper.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:ride_sharing_user_app/util/images.dart';
import 'package:ride_sharing_user_app/util/styles.dart';
import 'package:ride_sharing_user_app/features/auth/controllers/auth_controller.dart';
import 'package:ride_sharing_user_app/features/auth/domain/models/signup_body.dart';
import 'package:ride_sharing_user_app/features/auth/widgets/text_field_title_widget.dart';
import 'package:ride_sharing_user_app/common_widgets/button_widget.dart';
import 'package:ride_sharing_user_app/common_widgets/image_widget.dart';
import 'package:ride_sharing_user_app/common_widgets/text_field_widget.dart';

class AdditionalSignUpScreen2 extends StatelessWidget {
  const AdditionalSignUpScreen2({
    super.key,
  });

  String _identityTypeLabel(String value) {
    switch (value) {
      case 'nid':
        return 'identity_type_nid';
      case 'passport':
        return 'identity_type_passport';
      case 'residence_card':
        return 'identity_type_residence_card';
      default:
        return value;
    }
  }

  Future<void> _pickDrivingLicenseExpiryDate(
      BuildContext context, AuthController authController) async {
    final DateTime now = DateTime.now();
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 30),
    );

    if (pickedDate != null) {
      final String month = pickedDate.month.toString().padLeft(2, '0');
      final String day = pickedDate.day.toString().padLeft(2, '0');
      authController.drivingLicenseExpiryController.text =
          '${pickedDate.year}-$month-$day';
      authController.update();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).cardColor,
      body: SafeArea(
        child: GetBuilder<AuthController>(builder: (authController) {
          final bool isPartner = authController.categorieDrivers.any((c) =>
              (c.codeCategDriver ?? '').toUpperCase() == 'PART' &&
              authController.selectedCategorieIds.contains(c.id));
          return Column(children: [
            SignUpAppbarWidget(
                title: 'signup_as_a_driver',
                progressText: '3_of_3',
                enableBackButton: true),
            if (isPartner)
              Expanded(
                  child: SingleChildScrollView(
                      child: Padding(
                padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                          child: Text('Partenaire',
                              style: textBold.copyWith(fontSize: 22))),
                      const SizedBox(height: Dimensions.paddingSizeLarge),
                      // Partner type
                      TextFieldTitleWidget(
                          title:
                              'Choisir entre : Partenaire taxi / Partenaire livreur',
                          isRequired: true),
                      Container(
                        height: 50,
                        padding: const EdgeInsets.symmetric(
                            horizontal: Dimensions.paddingSizeDefault),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(
                              width: .5,
                              color: Theme.of(context)
                                  .hintColor
                                  .withValues(alpha: .7)),
                        ),
                        child: DropdownButton<String>(
                          value: authController.partnerType.isEmpty
                              ? null
                              : authController.partnerType,
                          hint: Text('Choisir le type de partenaire'),
                          items: ['Partenaire taxi', 'Partenaire livreur']
                              .map((String v) {
                            return DropdownMenuItem<String>(
                                value: v, child: Text(v));
                          }).toList(),
                          onChanged: (val) {
                            authController.setPartnerType(val ?? '');
                          },
                        ),
                      ),
                      const SizedBox(height: Dimensions.paddingSizeDefault),
                      TextFieldTitleWidget(
                          title: 'Nom ou raison sociale', isRequired: true),
                      TextFieldWidget(
                          hintText: 'Nom ou raison sociale',
                          controller: authController.fNameController),
                      TextFieldTitleWidget(
                          title: 'Téléphone', isRequired: true),
                      TextFieldWidget(
                          hintText: 'Téléphone',
                          controller: authController.phoneController,
                          countryDialCode: authController.countryDialCode,
                          showCountryCode: true),
                      TextFieldTitleWidget(title: 'Email'),
                      TextFieldWidget(
                          hintText: 'Email',
                          controller: authController.emailController,
                          inputType: TextInputType.emailAddress),
                      TextFieldTitleWidget(title: 'Nombre de véhicules'),
                      TextFieldWidget(
                          hintText: 'Nombre de véhicules',
                          controller:
                              authController.partnerVehicleCountController,
                          inputType: TextInputType.number),
                      const SizedBox(height: Dimensions.paddingSizeDefault),
                      TextFieldTitleWidget(
                          title: 'Type de personne', isRequired: true),
                      Container(
                        height: 50,
                        padding: const EdgeInsets.symmetric(
                            horizontal: Dimensions.paddingSizeDefault),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(
                              width: .5,
                              color: Theme.of(context)
                                  .hintColor
                                  .withValues(alpha: .7)),
                        ),
                        child: DropdownButton<String>(
                          value: authController.partnerPersonType.isEmpty
                              ? null
                              : authController.partnerPersonType,
                          hint: Text('Choisir le type de personne'),
                          items: ['Personne morale', 'Personne physique']
                              .map((String v) {
                            return DropdownMenuItem<String>(
                                value: v == 'Personne morale'
                                    ? 'morale'
                                    : 'physique',
                                child: Text(v));
                          }).toList(),
                          onChanged: (val) {
                            authController.partnerPersonType = val ?? '';
                            authController.update();
                          },
                        ),
                      ),
                      const SizedBox(height: Dimensions.paddingSizeDefault),
                      if (authController.partnerPersonType == 'morale') ...[
                        Text('RCCM', style: textRegular),
                        const SizedBox(height: 8),
                        Row(children: [
                          Expanded(
                            child: ElevatedButton(
                                onPressed: () =>
                                    authController.pickPartnerDocument('rccm'),
                                child: Text(authController.partnerRccmFile ==
                                        null
                                    ? 'Choisir RCCM'
                                    : authController.partnerRccmFile!.name)),
                          ),
                          if (authController.partnerRccmFile != null)
                            IconButton(
                                onPressed: () => authController
                                    .removePartnerDocument('rccm'),
                                icon: const Icon(Icons.delete)),
                        ]),
                        const SizedBox(height: Dimensions.paddingSizeDefault),
                        Text('Carte de transport', style: textRegular),
                        const SizedBox(height: 8),
                        Row(children: [
                          Expanded(
                            child: ElevatedButton(
                                onPressed: () => authController
                                    .pickPartnerDocument('transport'),
                                child: Text(
                                    authController.partnerTransportFile == null
                                        ? 'Choisir Carte de transport'
                                        : authController
                                            .partnerTransportFile!.name)),
                          ),
                          if (authController.partnerTransportFile != null)
                            IconButton(
                                onPressed: () => authController
                                    .removePartnerDocument('transport'),
                                icon: const Icon(Icons.delete)),
                        ]),
                      ] else if (authController.partnerPersonType ==
                          'physique') ...[
                        Text('CNI / Passeport', style: textRegular),
                        const SizedBox(height: 8),
                        Row(children: [
                          Expanded(
                            child: ElevatedButton(
                                onPressed: () =>
                                    authController.pickPartnerDocument('id'),
                                child: Text(authController.partnerIdFile == null
                                    ? 'Choisir CNI/Passeport'
                                    : authController.partnerIdFile!.name)),
                          ),
                          if (authController.partnerIdFile != null)
                            IconButton(
                                onPressed: () =>
                                    authController.removePartnerDocument('id'),
                                icon: const Icon(Icons.delete)),
                        ]),
                      ],
                      const SizedBox(height: Dimensions.paddingSizeDefault),
                      Text('Documents à fournir', style: textBold),
                      const SizedBox(height: 8),
                      Text(
                          '- Pour une personne morale: RCC, Carte de transport'),
                      Text('- Pour une personne physique: CNI, Passeport'),
                    ]),
              )))
            else
              Expanded(
                  child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                          child: Text('provide_your_identity'.tr,
                              style: textBold.copyWith(fontSize: 22))),
                      Center(
                        child: Text('this_information_will_help'.tr,
                            style: textRegular.copyWith(
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.color
                                  ?.withValues(alpha: 0.7),
                              fontSize: Dimensions.fontSizeSmall,
                            )),
                      ),
                      const SizedBox(height: Dimensions.paddingSizeLarge),
                      Padding(
                        padding: const EdgeInsets.only(
                            top: Dimensions.paddingSizeSmall),
                        child: Container(
                          height: 80,
                          width: Get.width,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Theme.of(context).primaryColor,
                                width: 1),
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
                                          height: 76,
                                          width: 76,
                                          placeholder: Images.personPlaceholder,
                                        ),
                                      )
                                    : CircleAvatar(
                                        radius: 40,
                                        backgroundImage: FileImage(File(
                                            authController
                                                .pickedProfileFile!.path)),
                                      ),
                                Positioned(
                                    right: 5,
                                    bottom: -3,
                                    child: InkWell(
                                      onTap: () =>
                                          authController.pickImage(false, true),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).primaryColor,
                                          shape: BoxShape.circle,
                                        ),
                                        padding: const EdgeInsets.all(5),
                                        child: const Icon(
                                            Icons.camera_enhance_rounded,
                                            color: Colors.white,
                                            size: 13),
                                      ),
                                    )),
                              ],
                            ),
                          ),
                        ),
                      ),
                      TextFieldTitleWidget(title: 'email'.tr, isRequired: true),
                      TextFieldWidget(
                        hintText: 'enter_your_email'.tr,
                        inputType: TextInputType.emailAddress,
                        prefixIcon: Images.email,
                        controller: authController.emailController,
                        focusNode: authController.emailNode,
                        nextFocus: authController.addressNode,
                        inputAction: TextInputAction.next,
                        autoFocus: authController.emailController.text.isEmpty,
                      ),
                      TextFieldTitleWidget(
                          title: 'address'.tr, isRequired: true),
                      TextFieldWidget(
                        hintText: 'enter_your_address'.tr,
                        capitalization: TextCapitalization.words,
                        inputType: TextInputType.text,
                        prefixIcon: Images.location,
                        controller: authController.addressController,
                        focusNode: authController.addressNode,
                        nextFocus: authController.identityNumberNode,
                        inputAction: TextInputAction.next,
                      ),
                      TextFieldTitleWidget(
                          title: 'identity_type'.tr, isRequired: true),
                      Container(
                        height: 50,
                        padding: const EdgeInsets.symmetric(
                            horizontal: Dimensions.paddingSizeDefault),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(
                              width: .5,
                              color: Theme.of(context)
                                  .hintColor
                                  .withValues(alpha: .7)),
                        ),
                        child: Row(children: [
                          Image.asset(Images.identityIcon,
                              height: 20, width: 20),
                          const SizedBox(width: Dimensions.paddingSizeLarge),
                          Expanded(
                            child: DropdownButton<String>(
                              hint: authController.identityType == ''
                                  ? Text('select_identity_type'.tr,
                                      style: textRegular.copyWith(
                                          color: Theme.of(context)
                                              .textTheme
                                              .bodyMedium!
                                              .color))
                                  : Text(
                                      _identityTypeLabel(
                                              authController.identityType)
                                          .tr,
                                      style: textRegular.copyWith(
                                          color: Theme.of(context)
                                              .textTheme
                                              .bodyMedium!
                                              .color),
                                    ),
                              items: authController.identityTypeList
                                  .map((String value) {
                                return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(_identityTypeLabel(value).tr,
                                        style: textRegular.copyWith(
                                            color: Theme.of(context)
                                                .textTheme
                                                .bodyMedium!
                                                .color)));
                              }).toList(),
                              onChanged: (val) {
                                authController.setIdentityType(val!);
                              },
                              isExpanded: true,
                              underline: const SizedBox(),
                            ),
                          )
                        ]),
                      ),
                      TextFieldTitleWidget(
                          title: 'document_number'.tr, isRequired: true),
                      TextFieldWidget(
                        hintText: 'enter_document_number'.tr,
                        inputType: TextInputType.text,
                        prefixIcon: Images.identity,
                        controller: authController.identityNumberController,
                        focusNode: authController.identityNumberNode,
                        inputAction: TextInputAction.done,
                      ),
                      const SizedBox(height: Dimensions.paddingSizeDefault),
                      Container(
                        decoration: BoxDecoration(
                            color: Theme.of(context)
                                .hintColor
                                .withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(Dimensions.radiusLarge)),
                        padding: EdgeInsets.all(Dimensions.paddingSizeDefault),
                        child: Column(children: [
                          Row(children: [
                            Text('identity_document_recto_verso'.tr,
                                style: textMedium.copyWith(
                                  fontSize: Dimensions.fontSizeDefault,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyMedium!
                                      .color!,
                                )),
                            Text('*',
                                style: textMedium.copyWith(
                                  fontSize: Dimensions.fontSizeDefault,
                                  color: Theme.of(context).colorScheme.error,
                                )),
                          ]),
                          const SizedBox(height: Dimensions.paddingSizeDefault),
                          ListView.builder(
                            padding: EdgeInsets.symmetric(
                                horizontal: Dimensions.paddingSizeExtraLarge),
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: authController.identityImages.length >= 2
                                ? 2
                                : authController.identityImages.length + 1,
                            itemBuilder: (BuildContext context, index) {
                              return index ==
                                      authController.identityImages.length
                                  ? GestureDetector(
                                      onTap: () => authController.pickImage(
                                          false, false),
                                      child: DottedBorder(
                                        options: RoundedRectDottedBorderOptions(
                                          strokeWidth: 1,
                                          dashPattern: const [5, 5],
                                          color: Theme.of(context).hintColor,
                                          radius: const Radius.circular(
                                              Dimensions.paddingSizeSmall),
                                        ),
                                        child: Container(
                                          decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      Dimensions
                                                          .paddingSizeSmall),
                                              color:
                                                  Theme.of(context).cardColor),
                                          padding: EdgeInsets.symmetric(
                                              vertical: Dimensions
                                                  .paddingSizeDefault),
                                          child: SizedBox(
                                            child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Image.asset(
                                                      Images.galleryIcon,
                                                      scale: 4),
                                                  const SizedBox(
                                                      width: Dimensions
                                                          .paddingSizeSmall),
                                                  Text(
                                                      authController
                                                              .identityImages
                                                              .isEmpty
                                                          ? 'add_front_side'.tr
                                                          : 'add_back_side'.tr,
                                                      style: textRegular.copyWith(
                                                          color: Theme.of(
                                                                  context)
                                                              .colorScheme
                                                              .surfaceContainer)),
                                                ]),
                                          ),
                                        ),
                                      ),
                                    )
                                  : Stack(children: [
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            bottom:
                                                Dimensions.paddingSizeSmall),
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(20)),
                                          ),
                                          child: ClipRRect(
                                            borderRadius:
                                                const BorderRadius.all(
                                              Radius.circular(Dimensions
                                                  .paddingSizeExtraSmall),
                                            ),
                                            child: Image.file(
                                              File(authController
                                                  .identityImages[index].path),
                                              width: MediaQuery.of(context)
                                                  .size
                                                  .width,
                                              height: MediaQuery.of(context)
                                                      .size
                                                      .width /
                                                  4.3,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 0,
                                        right: 0,
                                        child: InkWell(
                                          onTap: () =>
                                              authController.removeImage(index),
                                          child: Container(
                                            decoration: const BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(
                                                Dimensions.paddingSizeDefault,
                                              )),
                                            ),
                                            child: const Padding(
                                              padding: EdgeInsets.all(4.0),
                                              child: Icon(
                                                  Icons.delete_forever_rounded,
                                                  color: Colors.red,
                                                  size: 15),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ]);
                            },
                          ),
                        ]),
                      ),
                      const SizedBox(height: Dimensions.paddingSizeDefault),
                      TextFieldTitleWidget(
                          title: 'driving_license_number'.tr, isRequired: true),
                      TextFieldWidget(
                        hintText: 'enter_driving_license_number'.tr,
                        inputType: TextInputType.text,
                        prefixIcon: Images.identity,
                        controller:
                            authController.drivingLicenseNumberController,
                        focusNode: authController.drivingLicenseNumberNode,
                        nextFocus: authController.drivingLicenseExpiryNode,
                        inputAction: TextInputAction.next,
                      ),
                      TextFieldTitleWidget(
                          title: 'driving_license_expiry_date'.tr,
                          isRequired: true),
                      InkWell(
                        onTap: () => _pickDrivingLicenseExpiryDate(
                            context, authController),
                        child: IgnorePointer(
                          child: TextFieldWidget(
                            hintText: 'select_driving_license_expiry_date'.tr,
                            inputType: TextInputType.datetime,
                            prefixIcon: Images.calender,
                            controller:
                                authController.drivingLicenseExpiryController,
                            focusNode: authController.drivingLicenseExpiryNode,
                            inputAction: TextInputAction.done,
                          ),
                        ),
                      ),
                      const SizedBox(height: Dimensions.paddingSizeDefault),
                      Container(
                        decoration: BoxDecoration(
                            color: Theme.of(context)
                                .hintColor
                                .withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(Dimensions.radiusLarge)),
                        padding: EdgeInsets.all(Dimensions.paddingSizeDefault),
                        child: Column(children: [
                          Row(children: [
                            Text('driving_license_recto_verso'.tr,
                                style: textMedium.copyWith(
                                  fontSize: Dimensions.fontSizeDefault,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyMedium!
                                      .color!,
                                )),
                            Text('*',
                                style: textMedium.copyWith(
                                  fontSize: Dimensions.fontSizeDefault,
                                  color: Theme.of(context).colorScheme.error,
                                )),
                          ]),
                          const SizedBox(height: Dimensions.paddingSizeDefault),
                          ListView.builder(
                            padding: EdgeInsets.symmetric(
                                horizontal: Dimensions.paddingSizeExtraLarge),
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount:
                                authController.drivingLicenseImages.length >= 2
                                    ? 2
                                    : authController
                                            .drivingLicenseImages.length +
                                        1,
                            itemBuilder: (BuildContext context, index) {
                              return index ==
                                      authController.drivingLicenseImages.length
                                  ? GestureDetector(
                                      onTap: () => authController
                                          .pickDrivingLicenseImage(),
                                      child: DottedBorder(
                                        options: RoundedRectDottedBorderOptions(
                                          strokeWidth: 1,
                                          dashPattern: const [5, 5],
                                          color: Theme.of(context).hintColor,
                                          radius: const Radius.circular(
                                              Dimensions.paddingSizeSmall),
                                        ),
                                        child: Container(
                                          decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      Dimensions
                                                          .paddingSizeSmall),
                                              color:
                                                  Theme.of(context).cardColor),
                                          padding: EdgeInsets.symmetric(
                                              vertical: Dimensions
                                                  .paddingSizeDefault),
                                          child: SizedBox(
                                            child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Image.asset(
                                                      Images.galleryIcon,
                                                      scale: 4),
                                                  const SizedBox(
                                                      width: Dimensions
                                                          .paddingSizeSmall),
                                                  Text(
                                                      authController
                                                              .drivingLicenseImages
                                                              .isEmpty
                                                          ? 'add_front_side'.tr
                                                          : 'add_back_side'.tr,
                                                      style: textRegular.copyWith(
                                                          color: Theme.of(
                                                                  context)
                                                              .colorScheme
                                                              .surfaceContainer)),
                                                ]),
                                          ),
                                        ),
                                      ),
                                    )
                                  : Stack(children: [
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            bottom:
                                                Dimensions.paddingSizeSmall),
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(20)),
                                          ),
                                          child: ClipRRect(
                                            borderRadius:
                                                const BorderRadius.all(
                                              Radius.circular(Dimensions
                                                  .paddingSizeExtraSmall),
                                            ),
                                            child: Image.file(
                                              File(authController
                                                  .drivingLicenseImages[index]
                                                  .path),
                                              width: MediaQuery.of(context)
                                                  .size
                                                  .width,
                                              height: MediaQuery.of(context)
                                                      .size
                                                      .width /
                                                  4.3,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 0,
                                        right: 0,
                                        child: InkWell(
                                          onTap: () => authController
                                              .removeDrivingLicenseImage(index),
                                          child: Container(
                                            decoration: const BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(
                                                Dimensions.paddingSizeDefault,
                                              )),
                                            ),
                                            child: const Padding(
                                              padding: EdgeInsets.all(4.0),
                                              child: Icon(
                                                  Icons.delete_forever_rounded,
                                                  color: Colors.red,
                                                  size: 15),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ]);
                            },
                          ),
                        ]),
                      ),
                      const SizedBox(height: Dimensions.paddingSizeSmall),
                      Container(
                        decoration: BoxDecoration(
                            color: Theme.of(context)
                                .hintColor
                                .withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(Dimensions.radiusLarge)),
                        padding: EdgeInsets.all(Dimensions.paddingSizeDefault),
                        child: Column(children: [
                          Row(children: [
                            Text('other_documents'.tr,
                                style: textMedium.copyWith(
                                  fontSize: Dimensions.fontSizeDefault,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyMedium!
                                      .color!,
                                )),
                            Text('*',
                                style: textMedium.copyWith(
                                  fontSize: Dimensions.fontSizeDefault,
                                  color: Theme.of(context).colorScheme.error,
                                )),
                          ]),
                          const SizedBox(height: Dimensions.paddingSizeDefault),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: authController.otherDocuments.length >= 5
                                ? 5
                                : authController.otherDocuments.length + 1,
                            itemBuilder: (BuildContext context, index) {
                              return index ==
                                      authController.otherDocuments.length
                                  ? GestureDetector(
                                      onTap: () =>
                                          authController.pickOtherFile(),
                                      child: Column(children: [
                                        DottedBorder(
                                          options:
                                              RoundedRectDottedBorderOptions(
                                            strokeWidth: 1,
                                            dashPattern: const [5, 5],
                                            color: Theme.of(context).hintColor,
                                            radius: const Radius.circular(
                                                Dimensions.paddingSizeSmall),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                                Dimensions.paddingSizeSmall),
                                            child: SizedBox(
                                              height: MediaQuery.of(context)
                                                      .size
                                                      .width /
                                                  4.3,
                                              width: MediaQuery.of(context)
                                                  .size
                                                  .width,
                                              child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.end,
                                                  children: [
                                                    const SizedBox(
                                                        height: Dimensions
                                                            .paddingSizeExtraSmall),
                                                    Image.asset(
                                                        Images.cloudUploadIcon,
                                                        scale: 3),
                                                    Text('select_a_file'.tr,
                                                        style: textRegular.copyWith(
                                                            color: Theme.of(
                                                                    context)
                                                                .colorScheme
                                                                .surfaceContainer)),
                                                    const SizedBox(
                                                        height: Dimensions
                                                            .paddingSizeSmall)
                                                  ]),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(
                                            height:
                                                Dimensions.paddingSizeSmall),
                                      ]),
                                    )
                                  : Column(children: [
                                      DottedBorder(
                                        options: RoundedRectDottedBorderOptions(
                                          strokeWidth: 1,
                                          dashPattern: const [5, 5],
                                          color: Theme.of(context).hintColor,
                                          radius: const Radius.circular(
                                              Dimensions.paddingSizeSmall),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal:
                                                  Dimensions.paddingSizeDefault,
                                              vertical:
                                                  Dimensions.paddingSizeLarge),
                                          child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Flexible(
                                                    child: Row(
                                                        spacing: Dimensions
                                                            .paddingSizeSmall,
                                                        children: [
                                                      Image.asset(
                                                          ProfileHelper
                                                              .checkImageExtensions(
                                                                  '${authController.otherDocuments[index].file?.name}'),
                                                          height: 30,
                                                          width: 30),
                                                      Flexible(
                                                          child: Text(
                                                              '${authController.otherDocuments[index].file?.name}',
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis)),
                                                    ])),
                                                InkWell(
                                                  onTap: () => authController
                                                      .removeFile(index),
                                                  child: const Padding(
                                                    padding:
                                                        EdgeInsets.all(4.0),
                                                    child: Icon(
                                                        Icons
                                                            .highlight_remove_outlined,
                                                        color: Colors.red,
                                                        size: 24),
                                                  ),
                                                ),
                                              ]),
                                        ),
                                      ),
                                      const SizedBox(
                                          height: Dimensions.paddingSizeSmall),
                                    ]);
                            },
                          ),
                        ]),
                      ),
                    ],
                  ),
                ),
              )),
            Container(
              decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                        color:
                            Theme.of(context).hintColor.withValues(alpha: 0.15),
                        blurRadius: 10,
                        offset: Offset(0, -4))
                  ],
                  borderRadius: BorderRadius.only(
                      topRight: Radius.circular(Dimensions.paddingSizeLarge),
                      topLeft: Radius.circular(Dimensions.paddingSizeLarge)),
                  color: Theme.of(context).cardColor),
              padding: EdgeInsets.symmetric(
                      vertical: Dimensions.paddingSizeSmall,
                      horizontal: Dimensions.paddingSizeDefault)
                  .copyWith(bottom: Dimensions.paddingSizeExtraLarge),
              child: authController.isLoading
                  ? Center(
                      child: SpinKitCircle(
                          color: Theme.of(context).primaryColor, size: 40.0))
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(children: [
                          SizedBox(
                            width: 20.0,
                            child: Checkbox(
                              value: authController.acceptTerms,
                              checkColor: Theme.of(context).primaryColor,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5)),
                              activeColor: Theme.of(context)
                                  .primaryColor
                                  .withValues(alpha: .125),
                              side: BorderSide(
                                  color: Theme.of(context)
                                      .hintColor
                                      .withValues(alpha: 0.5)),
                              onChanged: (bool? v) =>
                                  authController.toggleTerms(),
                            ),
                          ),
                          const SizedBox(
                              width: Dimensions.paddingSizeExtraSmall),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => Get.to(() =>
                                  const PolicyViewerScreen(
                                      htmlType: HtmlType.termsAndConditions)),
                              child: Text(
                                //"J'accepte les conditions générales d'utilisation",
                                "Cochez ici pour accepter les conditions générales d'utilisation et le traitement de vos informations personnelles conformement à la politique de confidentialité.",
                                style: textRegular.copyWith(
                                    fontSize: Dimensions.fontSizeSmall,
                                    decoration: TextDecoration.underline,
                                    color: Theme.of(context).primaryColor),
                              ),
                            ),
                          )
                        ]),
                        const SizedBox(height: Dimensions.paddingSizeDefault),
                        ButtonWidget(
                            buttonText: 'submit'.tr,
                            onPressed: authController.acceptTerms
                                ? () async {
                                    String email =
                                        authController.emailController.text;
                                    String address =
                                        authController.addressController.text;
                                    String identityNumber = authController
                                        .identityNumberController.text;
                                    String drivingLicenseNumber = authController
                                        .drivingLicenseNumberController.text;
                                    String drivingLicenseExpiry = authController
                                        .drivingLicenseExpiryController.text;
                                    if (authController.pickedProfileFile ==
                                        null) {
                                      showCustomSnackBar(
                                          'profile_image_is_required'.tr);
                                    } else if (email.isEmpty) {
                                      showCustomSnackBar(
                                          'email_is_required'.tr);
                                      FocusScope.of(context).requestFocus(
                                          authController.emailNode);
                                    } else if (EmailChecker.isNotValid(email)) {
                                      showCustomSnackBar(
                                          'enter_valid_email_address'.tr);
                                      FocusScope.of(context).requestFocus(
                                          authController.emailNode);
                                    } else if (address.isEmpty) {
                                      showCustomSnackBar(
                                          'address_is_required'.tr);
                                      FocusScope.of(context).requestFocus(
                                          authController.addressNode);
                                    } else if (identityNumber.isEmpty) {
                                      showCustomSnackBar(
                                          'identity_number_is_required'.tr);
                                      FocusScope.of(context).requestFocus(
                                          authController.identityNumberNode);
                                    } else if (authController
                                        .identityImages.isEmpty) {
                                      showCustomSnackBar(
                                          'identity_image_is_required'.tr);
                                    } else if (authController
                                            .identityImages.length <
                                        2) {
                                      showCustomSnackBar(
                                          'identity_recto_verso_required'.tr);
                                    } else if (authController
                                        .identityType.isEmpty) {
                                      showCustomSnackBar(
                                          'identity_type_is_required'.tr);
                                    } else if (drivingLicenseNumber.isEmpty) {
                                      showCustomSnackBar(
                                          'driving_license_number_is_required'
                                              .tr);
                                      FocusScope.of(context).requestFocus(
                                          authController
                                              .drivingLicenseNumberNode);
                                    } else if (drivingLicenseExpiry.isEmpty) {
                                      showCustomSnackBar(
                                          'driving_license_expiry_is_required'
                                              .tr);
                                    } else if (authController
                                            .drivingLicenseImages.length <
                                        2) {
                                      showCustomSnackBar(
                                          'driving_license_recto_verso_required'
                                              .tr);
                                    } else {
                                      // If registering as partner, validate partner-specific documents
                                      if (isPartner) {
                                        if (authController
                                            .partnerPersonType.isEmpty) {
                                          showCustomSnackBar(
                                              'Veuillez choisir le type de personne (morale/physique)');
                                          return;
                                        }
                                        if (authController.partnerPersonType ==
                                            'morale') {
                                          if (authController.partnerRccmFile ==
                                              null) {
                                            showCustomSnackBar(
                                                'RCCM est requis pour une personne morale');
                                            return;
                                          }
                                          if (authController
                                                  .partnerTransportFile ==
                                              null) {
                                            showCustomSnackBar(
                                                'Carte de transport est requise pour une personne morale');
                                            return;
                                          }
                                        } else if (authController
                                                .partnerPersonType ==
                                            'physique') {
                                          if (authController.partnerIdFile ==
                                              null) {
                                            showCustomSnackBar(
                                                'CNI ou passeport est requis pour une personne physique');
                                            return;
                                          }
                                        }
                                      }
                                      List<String> services = [];
                                      if (authController.isRideShare) {
                                        services.add('ride_request');
                                      }
                                      if (authController.isParcelShare) {
                                        services.add('parcel');
                                      }
                                      String? deviceToken;
                                      try {
                                        deviceToken = await FirebaseMessaging
                                            .instance
                                            .getToken();
                                      } catch (_) {
                                        deviceToken =
                                            authController.getDeviceToken();
                                      }
                                      SignUpBody signUpBody = SignUpBody(
                                          email: email,
                                          address: address,
                                          identityNumber: identityNumber,
                                          identificationType:
                                              authController.identityType,
                                          fName: authController
                                              .fNameController.text,
                                          lName: authController
                                              .lNameController.text,
                                          phone:
                                              authController.countryDialCode +
                                                  authController
                                                      .phoneController.text,
                                          // Only provide password fields if they were filled earlier
                                          password: authController
                                                  .passwordController
                                                  .text
                                                  .isEmpty
                                              ? null
                                              : authController
                                                  .passwordController.text,
                                          confirmPassword: authController
                                                  .confirmPasswordController
                                                  .text
                                                  .isEmpty
                                              ? null
                                              : authController
                                                  .confirmPasswordController
                                                  .text,
                                          deviceToken:
                                              authController.getDeviceToken(),
                                          services: services,
                                          categorieDriverIds: authController
                                              .selectedCategorieIds
                                              .toList(),
                                          referralCode: authController
                                              .referralCodeController.text
                                              .trim(),
                                          fcmToken: deviceToken);
                                      // Attach partner-related info into the signUpBody
                                      signUpBody.companyName =
                                          authController.fNameController.text;
                                      signUpBody.partnerType =
                                          authController.partnerType.isEmpty
                                              ? null
                                              : authController.partnerType;
                                      signUpBody
                                          .partnerPersonType = authController
                                              .partnerPersonType.isEmpty
                                          ? null
                                          : authController.partnerPersonType;
                                      signUpBody.partnerVehicleCount =
                                          authController
                                                  .partnerVehicleCountController
                                                  .text
                                                  .isEmpty
                                              ? null
                                              : authController
                                                  .partnerVehicleCountController
                                                  .text;
                                      signUpBody.drivingLicenseNumber =
                                          drivingLicenseNumber;
                                      signUpBody.drivingLicenseExpireDate =
                                          drivingLicenseExpiry;
                                      authController.register(
                                          authController.countryDialCode,
                                          signUpBody);
                                    }
                                  }
                                : null,
                            radius: 50),
                      ],
                    ),
            )
          ]);
        }),
      ),
    );
  }
}
