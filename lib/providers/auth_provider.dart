import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService;

  User? _user;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider(this._authService);

  // Getters
  User? get user => _user;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAdmin => _user?.isAdmin ?? false;
  bool get isViewer => _user?.isViewer ?? false;

  /// Inicializa el provider verificando si hay una sesión activa
  Future<void> initialize() async {
    _setLoading(true);

    try {
      if (await _authService.isAuthenticated()) {
        _user = await _authService.getCurrentUser();
        _isAuthenticated = _user != null;

        // Validar tokens actuales
        if (_isAuthenticated) {
          final isValid = await _authService.validateCurrentTokens();
          if (!isValid) {
            await logout();
          }
        }
      }
    } catch (e) {
      _setError('Error al inicializar: $e');
      await _clearAuthState();
    } finally {
      _setLoading(false);
    }
  }

  /// Realiza el login del usuario
  Future<bool> login(String username, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final authResponse = await _authService.login(username, password);

      _user = authResponse.user;
      _isAuthenticated = true;

      notifyListeners();
      return true;
    } catch (e) {
      // Limpiar el mensaje removiendo "Exception: " al inicio
      String cleanMessage = e.toString();
      if (cleanMessage.startsWith('Exception: ')) {
        cleanMessage = cleanMessage.substring('Exception: '.length);
      }

      _setError(cleanMessage);
      await _clearAuthState();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Cierra la sesión del usuario
  Future<void> logout() async {
    _setLoading(true);

    try {
      await _authService.logout();
    } catch (e) {
      print('Error durante logout: $e');
    } finally {
      await _clearAuthState();
      _setLoading(false);
    }
  }

  /// Verifica el estado de autenticación actual
  Future<void> checkAuthStatus() async {
    _setLoading(true);

    try {
      if (await _authService.isAuthenticated()) {
        _user = await _authService.getCurrentUser();
        _isAuthenticated = _user != null;

        if (_isAuthenticated) {
          // Validar que los tokens sean válidos
          final isValid = await _authService.validateCurrentTokens();
          if (!isValid) {
            await _clearAuthState();
          }
        }
      } else {
        await _clearAuthState();
      }
    } catch (e) {
      _setError('Error al verificar autenticación: $e');
      await _clearAuthState();
    } finally {
      _setLoading(false);
    }
  }

  /// Refresca los tokens de autenticación
  Future<bool> refreshTokens() async {
    try {
      final success = await _authService.refreshTokens();
      if (!success) {
        await _clearAuthState();
      }
      return success;
    } catch (e) {
      _setError('Error al refrescar tokens: $e');
      await _clearAuthState();
      return false;
    }
  }

  /// Verifica si el usuario tiene un rol específico
  bool hasRole(String role) {
    return _user?.role == role;
  }

  /// Obtiene el token de acceso actual
  Future<String?> getAccessToken() async {
    return await _authService.getAccessToken();
  }

  /// Limpia el estado de autenticación
  Future<void> _clearAuthState() async {
    _user = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  /// Establece el estado de carga
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Establece un mensaje de error
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  /// Limpia el mensaje de error
  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Limpia el error actual
  void clearError() {
    _clearError();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
