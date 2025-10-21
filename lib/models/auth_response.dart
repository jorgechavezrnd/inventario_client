import 'package:json_annotation/json_annotation.dart';
import 'user.dart';

part 'auth_response.g.dart';

@JsonSerializable()
class AuthResponse {
  final bool success;
  final User user;
  @JsonKey(name: 'accessToken')
  final String accessToken;
  @JsonKey(name: 'refreshToken')
  final String refreshToken;
  final String? message;

  const AuthResponse({
    required this.success,
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    this.message,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    try {
      print('Parseando AuthResponse: $json');

      // El servidor puede enviar los tokens directamente o dentro de un objeto 'tokens'
      String accessToken = '';
      String refreshToken = '';

      if (json['tokens'] != null) {
        // Tokens dentro del objeto 'tokens'
        final tokens = json['tokens'] as Map<String, dynamic>;
        accessToken = tokens['accessToken']?.toString() ?? '';
        refreshToken = tokens['refreshToken']?.toString() ?? '';
      } else {
        // Tokens directamente en el objeto principal
        accessToken =
            json['accessToken']?.toString() ??
            json['access_token']?.toString() ??
            '';
        refreshToken =
            json['refreshToken']?.toString() ??
            json['refresh_token']?.toString() ??
            '';
      }

      return AuthResponse(
        success: json['success'] == true,
        user: User.fromJson(json['user'] ?? {}),
        accessToken: accessToken,
        refreshToken: refreshToken,
        message: json['message']?.toString(),
      );
    } catch (e) {
      print('Error parseando AuthResponse: $e');
      print('JSON recibido: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() => _$AuthResponseToJson(this);

  @override
  String toString() {
    return 'AuthResponse{success: $success, user: $user, message: $message}';
  }
}

@JsonSerializable()
class LoginRequest {
  final String username;
  final String password;

  const LoginRequest({required this.username, required this.password});

  factory LoginRequest.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestFromJson(json);
  Map<String, dynamic> toJson() => _$LoginRequestToJson(this);
}

@JsonSerializable()
class RefreshTokenRequest {
  @JsonKey(name: 'refreshToken')
  final String refreshToken;

  const RefreshTokenRequest({required this.refreshToken});

  factory RefreshTokenRequest.fromJson(Map<String, dynamic> json) =>
      _$RefreshTokenRequestFromJson(json);
  Map<String, dynamic> toJson() => _$RefreshTokenRequestToJson(this);
}

@JsonSerializable()
class RefreshTokenResponse {
  final bool success;
  @JsonKey(name: 'accessToken')
  final String accessToken;
  @JsonKey(name: 'refreshToken')
  final String refreshToken;
  final String? message;

  const RefreshTokenResponse({
    required this.success,
    required this.accessToken,
    required this.refreshToken,
    this.message,
  });

  factory RefreshTokenResponse.fromJson(Map<String, dynamic> json) {
    try {
      // El servidor puede enviar los tokens directamente o dentro de un objeto 'tokens'
      String accessToken = '';
      String refreshToken = '';

      if (json['tokens'] != null) {
        final tokens = json['tokens'] as Map<String, dynamic>;
        accessToken = tokens['accessToken']?.toString() ?? '';
        refreshToken = tokens['refreshToken']?.toString() ?? '';
      } else {
        accessToken =
            json['accessToken']?.toString() ??
            json['access_token']?.toString() ??
            '';
        refreshToken =
            json['refreshToken']?.toString() ??
            json['refresh_token']?.toString() ??
            '';
      }

      return RefreshTokenResponse(
        success: json['success'] == true,
        accessToken: accessToken,
        refreshToken: refreshToken,
        message: json['message']?.toString(),
      );
    } catch (e) {
      print('Error parseando RefreshTokenResponse: $e');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() => _$RefreshTokenResponseToJson(this);
}
