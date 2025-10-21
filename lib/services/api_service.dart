import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/auth_response.dart';

class TokenInterceptor extends Interceptor {
  final FlutterSecureStorage _secureStorage;
  final Dio _dio;

  TokenInterceptor(this._secureStorage, this._dio);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Agregar Bearer token automáticamente a todas las peticiones
    // excepto login y refresh
    if (!options.path.contains('/auth/login') &&
        !options.path.contains('/auth/refresh')) {
      final accessToken = await _secureStorage.read(key: 'access_token');
      if (accessToken != null) {
        options.headers['Authorization'] = 'Bearer $accessToken';
      }
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Token expirado, intentar renovar
      final success = await _refreshToken();

      if (success) {
        // Reintentar la petición original con el nuevo token
        final accessToken = await _secureStorage.read(key: 'access_token');
        if (accessToken != null) {
          err.requestOptions.headers['Authorization'] = 'Bearer $accessToken';

          try {
            final response = await _dio.fetch(err.requestOptions);
            handler.resolve(response);
            return;
          } catch (e) {
            // Si falla el reintento, continuar con el error original
          }
        }
      }

      // Si no se pudo renovar el token, limpiar el storage y continuar con error
      await _clearTokens();
    }

    handler.next(err);
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _secureStorage.read(key: 'refresh_token');
      if (refreshToken == null) return false;

      final response = await _dio.post(
        '/auth/refresh',
        data: RefreshTokenRequest(refreshToken: refreshToken).toJson(),
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 200) {
        final refreshResponse = RefreshTokenResponse.fromJson(response.data);

        // Guardar los nuevos tokens
        await _secureStorage.write(
          key: 'access_token',
          value: refreshResponse.accessToken,
        );
        await _secureStorage.write(
          key: 'refresh_token',
          value: refreshResponse.refreshToken,
        );

        return true;
      }
    } catch (e) {
      print('Error al renovar token: $e');
    }

    return false;
  }

  Future<void> _clearTokens() async {
    await _secureStorage.delete(key: 'access_token');
    await _secureStorage.delete(key: 'refresh_token');
    await _secureStorage.delete(key: 'user');
  }
}

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:3000';
  late final Dio dio;
  late final FlutterSecureStorage _secureStorage;
  late final TokenInterceptor _tokenInterceptor;

  ApiService() {
    _secureStorage = const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
      ),
      wOptions: WindowsOptions(useBackwardCompatibility: true),
    );

    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(milliseconds: 10000),
        receiveTimeout: const Duration(milliseconds: 10000),
        sendTimeout: const Duration(milliseconds: 10000),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _tokenInterceptor = TokenInterceptor(_secureStorage, dio);
    dio.interceptors.add(_tokenInterceptor);

    // Interceptor para logging en modo debug
    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        requestHeader: false,
        responseHeader: false,
        error: true,
        logPrint: (obj) => print(obj),
      ),
    );
  }

  // Getter para acceder al secure storage desde otros servicios
  FlutterSecureStorage get secureStorage => _secureStorage;

  // Método para limpiar todos los datos de autenticación
  Future<void> clearAuthData() async {
    await _secureStorage.delete(key: 'access_token');
    await _secureStorage.delete(key: 'refresh_token');
    await _secureStorage.delete(key: 'user');
  }

  // Método para verificar si hay tokens válidos
  Future<bool> hasValidTokens() async {
    final accessToken = await _secureStorage.read(key: 'access_token');
    final refreshToken = await _secureStorage.read(key: 'refresh_token');
    return accessToken != null && refreshToken != null;
  }
}
