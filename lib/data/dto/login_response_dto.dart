/// DTO for login API response
/// Maps directly to the API response structure
class LoginResponseDto {
  final int status;
  final String message;
  final LoginDataDto? data;

  LoginResponseDto({
    required this.status,
    required this.message,
    this.data,
  });

  factory LoginResponseDto.fromJson(Map<String, dynamic> json) {
    return LoginResponseDto(
      status: json['status'] as int,
      message: json['message'] as String,
      data: json['data'] != null
          ? LoginDataDto.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'data': data?.toJson(),
    };
  }

  bool get isSuccess => status == 1;
}

class LoginDataDto {
  final String token;
  final UserDataDto userData;

  LoginDataDto({
    required this.token,
    required this.userData,
  });

  factory LoginDataDto.fromJson(Map<String, dynamic> json) {
    return LoginDataDto(
      token: json['token'] as String,
      userData: UserDataDto.fromJson(json['user_data'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'user_data': userData.toJson(),
    };
  }
}

class UserDataDto {
  final String id;
  final String companyId;
  final String email;
  final String groupId;
  final String firstName;
  final String lastName;
  final int salePersonId;
  final String consignment;

  UserDataDto({
    required this.id,
    required this.companyId,
    required this.email,
    required this.groupId,
    required this.firstName,
    required this.lastName,
    required this.salePersonId,
    required this.consignment,
  });

  factory UserDataDto.fromJson(Map<String, dynamic> json) {
    return UserDataDto(
      id: json['id']?.toString() ?? '',
      companyId: json['company_id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      groupId: json['group_id']?.toString() ?? '',
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      salePersonId: json['sale_person_id'] is int
          ? json['sale_person_id']
          : int.tryParse(json['sale_person_id']?.toString() ?? '0') ?? 0,
      consignment: json['consignment']?.toString() ?? 'no',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_id': companyId,
      'email': email,
      'group_id': groupId,
      'first_name': firstName,
      'last_name': lastName,
      'sale_person_id': salePersonId,
      'consignment': consignment,
    };
  }
}
