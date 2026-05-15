import 'dart:convert';

class SignUpBody {
  String? fName;
  String? lName;
  String? phone;
  String? email;
  String? password;
  String? confirmPassword;
  String? address;
  String? identificationType;
  String? identityNumber;
  String? referralCode;
  List<String>? services;
  String? fcmToken;

  String? lokallyZoneId;
  String? lokallyServiceType;
  String? lokallyBillingMode;

  String? addressStreet;
  String? addressNumber;
  String? addressNeighborhood;
  String? addressCity;
  String? addressState;
  String? addressZipCode;

  SignUpBody({
    this.fName,
    this.lName,
    this.phone,
    this.email,
    this.password,
    this.confirmPassword,
    this.address,
    this.identificationType,
    this.identityNumber,
    this.services,
    this.referralCode,
    this.fcmToken,
    this.lokallyZoneId,
    this.lokallyServiceType,
    this.lokallyBillingMode,
    this.addressStreet,
    this.addressNumber,
    this.addressNeighborhood,
    this.addressCity,
    this.addressState,
    this.addressZipCode,
  });

  SignUpBody.fromJson(Map<String, dynamic> json) {
    fName = json['first_name'];
    lName = json['last_name'];
    phone = json['phone'];
    password = json['password'];
    confirmPassword = json['confirm_password'];
    email = json['email'];
    address = json['address'];
    identificationType = json['identification_type'];
    identityNumber = json['identification_number'];
    referralCode = json['referral_code'];
    fcmToken = json['fcm_token'];

    lokallyZoneId = json['lokally_zone_id'];
    lokallyServiceType = json['lokally_service_type'];
    lokallyBillingMode = json['lokally_billing_mode'];

    addressStreet = json['address_street'];
    addressNumber = json['address_number'];
    addressNeighborhood = json['address_neighborhood'];
    addressCity = json['address_city'];
    addressState = json['address_state'];
    addressZipCode = json['address_zip_code'];
  }

  Map<String, String> toJson() {
    final Map<String, String> data = <String, String>{};

    data['first_name'] = fName ?? '';
    data['last_name'] = lName ?? '';
    data['phone'] = phone ?? '';
    data['password'] = password ?? '';
    data['confirm_password'] = confirmPassword ?? '';
    data['email'] = email ?? '';
    data['address'] = address ?? '';
    data['identification_type'] = identificationType ?? '';
    data['identification_number'] = identityNumber ?? '';
    data['service'] = jsonEncode(services);
    data['referral_code'] = referralCode ?? '';
    data['fcm_token'] = fcmToken ?? '';

    data['lokally_zone_id'] = lokallyZoneId ?? '';
    data['lokally_service_type'] = lokallyServiceType ?? '';
    data['lokally_billing_mode'] = lokallyBillingMode ?? '';

    data['address_street'] = addressStreet ?? '';
    data['address_number'] = addressNumber ?? '';
    data['address_neighborhood'] = addressNeighborhood ?? '';
    data['address_city'] = addressCity ?? '';
    data['address_state'] = addressState ?? '';
    data['address_zip_code'] = addressZipCode ?? 'nao_informado';

    return data;
  }
}
