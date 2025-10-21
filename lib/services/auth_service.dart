import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/user.dart';
import '../models/auth_response.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _apiService;

  AuthService(this._apiService);

  /// Realiza el login del usuario
  Future<AuthResponse> login(String username, String password) async {
    try {
      final loginRequest = LoginRequest(username: username, password: password);

      final response = await _apiService.dio.post(
        '/auth/login',
        data: loginRequest.toJson(),
      );

      if (response.statusCode == 200) {
        // Debug: Imprimir la respuesta del servidor
        print('Respuesta del servidor: ${response.data}');

        try {
          final authResponse = AuthResponse.fromJson(response.data);

          // Guardar tokens y usuario en secure storage
          await _saveAuthData(authResponse);

          return authResponse;
        } catch (e) {
          print('Error al parsear respuesta: $e');
          print('Datos recibidos: ${response.data}');
          throw Exception('Error al procesar respuesta del servidor: $e');
        }
      } else {
        throw Exception('Login fallido: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Credenciales incorrectas');
      } else if (e.response?.statusCode == 400) {
        throw Exception('Datos de login inválidos');
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw Exception('Error de conexión. Verifica tu conexión a internet.');
      } else {
        throw Exception('Error en el servidor: ${e.message}');
      }
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }

  /// Cierra la sesión del usuario
  Future<void> logout() async {
    try {
      // Opcional: llamar endpoint de logout en el servidor
      // await _apiService.dio.post('/auth/logout');

      // Limpiar todos los datos de autenticación
      await _apiService.clearAuthData();
    } catch (e) {
      // Aunque falle la llamada al servidor, limpiar datos locales
      await _apiService.clearAuthData();
      print('Error durante logout: $e');
    }
  }

  /// Verifica si el usuario está autenticado
  Future<bool> isAuthenticated() async {
    try {
      return await _apiService.hasValidTokens();
    } catch (e) {
      return false;
    }
  }

  /// Obtiene el usuario actual desde el storage
  Future<User?> getCurrentUser() async {
    try {
      final userJson = await _apiService.secureStorage.read(key: 'user');
      if (userJson != null) {
        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        return User.fromJson(userMap);
      }
      return null;
    } catch (e) {
      print('Error al obtener usuario actual: $e');
      return null;
    }
  }

  /// Obtiene el token de acceso actual
  Future<String?> getAccessToken() async {
    try {
      return await _apiService.secureStorage.read(key: 'access_token');
    } catch (e) {
      print('Error al obtener access token: $e');
      return null;
    }
  }

  /// Obtiene el token de refresh actual
  Future<String?> getRefreshToken() async {
    try {
      return await _apiService.secureStorage.read(key: 'refresh_token');
    } catch (e) {
      print('Error al obtener refresh token: $e');
      return null;
    }
  }

  /// Refresca los tokens usando el refresh token
  Future<bool> refreshTokens() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) {
        return false;
      }

      final refreshRequest = RefreshTokenRequest(refreshToken: refreshToken);

      final response = await _apiService.dio.post(
        '/auth/refresh',
        data: refreshRequest.toJson(),
      );

      if (response.statusCode == 200) {
        final refreshResponse = RefreshTokenResponse.fromJson(response.data);

        // Actualizar tokens en storage
        await _apiService.secureStorage.write(
          key: 'access_token',
          value: refreshResponse.accessToken,
        );
        await _apiService.secureStorage.write(
          key: 'refresh_token',
          value: refreshResponse.refreshToken,
        );

        return true;
      }
    } catch (e) {
      print('Error al refrescar tokens: $e');
      // Si falla el refresh, limpiar todos los tokens
      await _apiService.clearAuthData();
    }

    return false;
  }

  /// Verifica si el usuario tiene un rol específico
  Future<bool> hasRole(String role) async {
    final user = await getCurrentUser();
    return user?.role == role;
  }

  /// Verifica si el usuario es admin
  Future<bool> isAdmin() async {
    final user = await getCurrentUser();
    return user?.isAdmin ?? false;
  }

  /// Verifica si el usuario es viewer
  Future<bool> isViewer() async {
    final user = await getCurrentUser();
    return user?.isViewer ?? false;
  }

  /// Guarda los datos de autenticación en secure storage
  Future<void> _saveAuthData(AuthResponse authResponse) async {
    await _apiService.secureStorage.write(
      key: 'access_token',
      value: authResponse.accessToken,
    );
    await _apiService.secureStorage.write(
      key: 'refresh_token',
      value: authResponse.refreshToken,
    );
    await _apiService.secureStorage.write(
      key: 'user',
      value: jsonEncode(authResponse.user.toJson()),
    );
  }

  /// Valida los tokens actuales haciendo una petición de prueba
  Future<bool> validateCurrentTokens() async {
    try {
      // Hacer una petición simple para validar el token
      await _apiService.dio.get('/products?limit=1');
      return true;
    } catch (e) {
      return false;
    }
  }
}
