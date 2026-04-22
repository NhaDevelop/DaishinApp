import 'package:daishin_order_app/data/dto/login_response_dto.dart';
import '../models/user_model.dart';

/// Mapper class to convert DTOs to Domain Models
class AuthMapper {
  /// Convert UserDataDto to UserModel (Domain Model)
  static UserModel userDataDtoToModel(UserDataDto dto, String token) {
    return UserModel(
      id: dto.id,
      email: dto.email,
      name: '${dto.firstName} ${dto.lastName}',
      phone: null, // Not provided in current API
      role: _mapGroupIdToRole(dto.groupId),
      avatar: null, // Not provided in current API
      createdAt: DateTime.now(),
      companyId: dto.companyId,
      groupId: dto.groupId,
      firstName: dto.firstName,
      lastName: dto.lastName,
      salePersonId: dto.salePersonId,
      consignment: dto.consignment,
    );
  }

  /// Map group_id to user role
  static String _mapGroupIdToRole(String groupId) {
    switch (groupId) {
      case '1':
        return 'admin';
      case '2':
        return 'business';
      case '3':
        return 'retail';
      default:
        return 'retail';
    }
  }

  /// Convert LoginResponseDto to UserModel
  /// Returns null if login failed
  static UserModel? loginResponseToUserModel(LoginResponseDto response) {
    if (!response.isSuccess || response.data == null) {
      return null;
    }

    return userDataDtoToModel(
      response.data!.userData,
      response.data!.token,
    );
  }

  /// Extract token from LoginResponseDto
  static String? extractToken(LoginResponseDto response) {
    if (!response.isSuccess || response.data == null) {
      return null;
    }
    return response.data!.token;
  }
}
