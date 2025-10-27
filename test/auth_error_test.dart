import 'package:flutter_test/flutter_test.dart';
import 'package:inventario_client/models/auth_error.dart';

void main() {
  group('AuthError', () {
    test('should create user-friendly message with remaining attempts', () {
      final responseData = {
        'success': false,
        'message': 'Invalid username or password',
        'errorCode': 'INVALID_CREDENTIALS',
      };

      final headers = {
        'X-RateLimit-Username-Remaining': ['2'],
        'X-RateLimit-IP-Remaining': ['6'],
        'X-RateLimit-Reset': ['2025-10-27T22:08:19.116Z'],
      };

      final authError = AuthError.fromResponse(responseData, headers);

      expect(authError.message, equals('Usuario o contraseña incorrectos'));
      expect(authError.errorCode, equals('INVALID_CREDENTIALS'));
      expect(authError.attemptsRemaining, equals(2));
      expect(
        authError.userFriendlyMessage,
        equals('Usuario o contraseña incorrectos (Intentos: 3)'),
      );
    });

    test(
      'should show last attempt when 0 attempts remaining with status 401',
      () {
        final responseData = {
          'success': false,
          'message': 'Invalid username or password',
          'errorCode': 'INVALID_CREDENTIALS',
        };

        final headers = {
          'X-RateLimit-Username-Remaining': ['0'],
          'X-RateLimit-Reset': ['2025-10-27T22:08:19.116Z'],
        };

        final authError = AuthError.fromResponse(responseData, headers);

        expect(authError.attemptsRemaining, equals(0));
        expect(
          authError.userFriendlyMessage,
          equals('Usuario o contraseña incorrectos (Último intento)'),
        );
      },
    );

    test('should show blocked account message for status 423', () {
      final resetTime = DateTime.now().add(Duration(minutes: 15));
      final responseData = {
        'success': false,
        'message':
            'Account temporarily locked due to multiple failed login attempts. Please try again later.',
        'error': 'ACCOUNT_LOCKED',
        'lockedUntil': resetTime.toIso8601String(),
        'retryAfter': 900,
      };

      final authError = AuthError.fromBlockedAccount(responseData, null);

      expect(authError.attemptsRemaining, isNull);
      expect(authError.userFriendlyMessage, contains('Cuenta bloqueada por'));
      expect(authError.userFriendlyMessage, contains('min'));
    });

    test('should handle missing headers gracefully', () {
      final responseData = {
        'success': false,
        'message': 'Invalid username or password',
        'errorCode': 'INVALID_CREDENTIALS',
      };

      final authError = AuthError.fromResponse(responseData, null);

      expect(authError.message, equals('Usuario o contraseña incorrectos'));
      expect(authError.attemptsRemaining, isNull);
      expect(
        authError.userFriendlyMessage,
        equals('Usuario o contraseña incorrectos'),
      );
    });

    test(
      'should create blocked account message with time remaining from headers',
      () {
        final responseData = {
          'success': false,
          'message': 'Account locked due to too many failed attempts',
          'errorCode': 'ACCOUNT_LOCKED',
        };

        // Simular un tiempo de reset en 5 minutos
        final resetTime = DateTime.now().add(Duration(minutes: 5));
        final headers = {
          'X-RateLimit-Reset': [resetTime.toIso8601String()],
          'X-RateLimit-Username-Remaining': ['0'],
        };

        final authError = AuthError.fromBlockedAccount(responseData, headers);

        expect(
          authError.attemptsRemaining,
          isNull,
        ); // No debe mostrar intentos para cuenta bloqueada
        expect(
          authError.userFriendlyMessage,
          equals('Cuenta bloqueada por 15 min'),
        );
      },
    );

    test(
      'should create blocked account message with time remaining from JSON lockedUntil',
      () {
        final resetTime = DateTime.now().add(Duration(minutes: 10));
        final responseData = {
          'success': false,
          'message':
              'Account temporarily locked due to multiple failed login attempts. Please try again later.',
          'error': 'ACCOUNT_LOCKED',
          'lockedUntil': resetTime.toIso8601String(),
          'retryAfter': 600,
        };

        final authError = AuthError.fromBlockedAccount(responseData, null);

        expect(authError.attemptsRemaining, isNull);
        expect(
          authError.userFriendlyMessage,
          equals('Cuenta bloqueada por 15 min'),
        );
      },
    );

    test(
      'should handle edge case with 423 status but remaining attempts in headers',
      () {
        final responseData = {
          'success': false,
          'message': 'Invalid username or password', // No contiene "bloqueada"
          'errorCode': 'INVALID_CREDENTIALS',
        };

        final headers = {
          'X-RateLimit-Username-Remaining': ['1'],
          'X-RateLimit-Reset': ['2025-10-27T22:08:19.116Z'],
        };

        final authError = AuthError.fromBlockedAccount(responseData, headers);

        // Como el mensaje no contiene "bloqueada", sí puede mostrar intentos
        expect(authError.attemptsRemaining, equals(1));
        expect(
          authError.userFriendlyMessage,
          equals('Usuario o contraseña incorrectos (Intentos: 2)'),
        );
      },
    );

    test('should show attempts remaining when 1 attempt left', () {
      final responseData = {
        'success': false,
        'message': 'Invalid username or password',
        'errorCode': 'INVALID_CREDENTIALS',
      };

      final headers = {
        'X-RateLimit-Username-Remaining': ['1'],
        'X-RateLimit-Reset': ['2025-10-27T22:08:19.116Z'],
      };

      final authError = AuthError.fromResponse(responseData, headers);

      expect(authError.attemptsRemaining, equals(1));
      expect(
        authError.userFriendlyMessage,
        equals('Usuario o contraseña incorrectos (Intentos: 2)'),
      );
    });

    test(
      'should create generic blocked account message without reset time',
      () {
        final responseData = {
          'success': false,
          'message': 'Account locked due to too many failed attempts',
          'errorCode': 'ACCOUNT_LOCKED',
        };

        final authError = AuthError.fromBlockedAccount(responseData, null);

        expect(authError.attemptsRemaining, isNull);
        expect(
          authError.userFriendlyMessage,
          equals('Cuenta bloqueada temporalmente'),
        );
      },
    );
  });
}
