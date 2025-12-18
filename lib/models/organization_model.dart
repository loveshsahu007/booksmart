class OrganizationModel {
  final String? id;
  final String name;
  final String? website;
  final String einTin;
  final String orgType;
  final String industry;
  final String state;
  final String street;
  final String city;
  final String zip;
  final String? phone;
  final String? email;
  final String ownerId;

  OrganizationModel({
    this.id,
    required this.name,
    this.website,
    required this.einTin,
    required this.orgType,
    required this.industry,
    required this.state,
    required this.street,
    required this.city,
    required this.zip,
    this.phone,
    this.email,
    required this.ownerId,
  });

  factory OrganizationModel.fromJson(Map<String, dynamic> json) {
    return OrganizationModel(
      id: json['id'],
      name: json['name'],
      website: json['website'],
      einTin: json['ein_tin'],
      orgType: json['org_type'],
      industry: json['industry'],
      state: json['state'],
      street: json['street'],
      city: json['city'],
      zip: json['zip'],
      phone: json['phone'],
      email: json['email'],
      ownerId: json['owner_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'website': website,
      'ein_tin': einTin,
      'org_type': orgType,
      'industry': industry,
      'state': state,
      'street': street,
      'city': city,
      'zip': zip,
      'phone': phone,
      'email': email,
      'owner_id': ownerId,
    };
  }
}
