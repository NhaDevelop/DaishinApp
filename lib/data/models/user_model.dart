class UserModel {
  final String id;
  final String email;
  final String name;
  final String? phone;
  final String role; // 'retail' or 'business'
  final String? avatar;
  final DateTime createdAt;

  // New fields from API
  final String companyId;
  final String groupId;
  final String firstName;
  final String lastName;
  final int salePersonId;
  final String consignment;
  final String? address; // User's delivery address

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    required this.role,
    this.avatar,
    required this.createdAt,
    required this.companyId,
    required this.groupId,
    required this.firstName,
    required this.lastName,
    required this.salePersonId,
    required this.consignment,
    this.address,
  });

  /// Check if user can place orders
  /// Users with group_id = "3" OR consignment = "yes" cannot place orders
  bool get canOrder => groupId != "3" && consignment.toLowerCase() != "yes";

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'].toString(),
      email: json['email'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      role: json['role'] as String,
      avatar: json['avatar'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      companyId: json['company_id']?.toString() ?? '',
      groupId: json['group_id']?.toString() ?? '',
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      salePersonId: json['sale_person_id'] is int
          ? json['sale_person_id']
          : int.tryParse(json['sale_person_id']?.toString() ?? '0') ?? 0,
      consignment: json['consignment']?.toString() ?? 'no',
      address: json['address']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'role': role,
      'avatar': avatar,
      'created_at': createdAt.toIso8601String(),
      'company_id': companyId,
      'group_id': groupId,
      'first_name': firstName,
      'last_name': lastName,
      'sale_person_id': salePersonId,
      'consignment': consignment,
      'address': address,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    String? role,
    String? avatar,
    DateTime? createdAt,
    String? companyId,
    String? groupId,
    String? firstName,
    String? lastName,
    int? salePersonId,
    String? consignment,
    String? address,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      avatar: avatar ?? this.avatar,
      createdAt: createdAt ?? this.createdAt,
      companyId: companyId ?? this.companyId,
      groupId: groupId ?? this.groupId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      salePersonId: salePersonId ?? this.salePersonId,
      consignment: consignment ?? this.consignment,
      address: address ?? this.address,
    );
  }
}
