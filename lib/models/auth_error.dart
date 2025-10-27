class AuthError {
  final String message;
  final String? errorCode;
  final int? attemptsRemaining;
  final DateTime? resetTime;

  AuthError({
    required this.message,
    this.errorCode,
    this.attemptsRemaining,
    this.resetTime,
  });

  /// Crea un mensaje amigable que incluye los intentos restantes
  String get userFriendlyMessage {
    // Si hay información de intentos restantes
    if (attemptsRemaining != null) {
      if (attemptsRemaining! > 0) {
        // Servidor dice N, mostramos N+1 (porque cuenta desde 3,2,1,0)
        int adjustedAttempts = attemptsRemaining! + 1;
        return '$message (Intentos: $adjustedAttempts)';
      } else if (attemptsRemaining! == 0) {
        // Status 401 con 0 intentos = último intento antes del bloqueo
        return '$message (Último intento)';
      }
    }
    
    // Si llegamos aquí, es porque no hay información de intentos (status 423 o error sin headers)
    // Mostrar mensaje de bloqueo con tiempo si está disponible
    if (resetTime != null) {
      final now = DateTime.now();
      final difference = resetTime!.difference(now);
      
      if (difference.inMinutes > 0) {
        return 'Cuenta bloqueada por ${difference.inMinutes} min';
      } else if (difference.inSeconds > 0) {
        return 'Cuenta bloqueada por ${difference.inSeconds} seg';
      }
    }
    
    // Si es un mensaje de cuenta bloqueada, usar mensaje específico
    if (message.contains('bloqueada') || message.contains('locked')) {
      return 'Cuenta bloqueada temporalmente';
    }
    
    // Para otros casos (sin headers), devolver el mensaje original
    return message;
  }

  factory AuthError.fromResponse(Map<String, dynamic> responseData, Map<String, List<String>>? headers) {
    String message = responseData['message'] ?? 'Error de autenticación';
    String? errorCode = responseData['errorCode'];
    
    // Convertir el mensaje del servidor a algo más amigable
    if (message == 'Invalid username or password') {
      message = 'Usuario o contraseña incorrectos';
    }

    int? attemptsRemaining;
    DateTime? resetTime;

    // Extraer información de rate limiting de los headers
    if (headers != null) {
      final remainingHeader = headers['x-ratelimit-username-remaining']?.first ?? 
                             headers['X-RateLimit-Username-Remaining']?.first;
      if (remainingHeader != null) {
        attemptsRemaining = int.tryParse(remainingHeader);
      }

      final resetHeader = headers['x-ratelimit-reset']?.first ?? 
                         headers['X-RateLimit-Reset']?.first;
      if (resetHeader != null) {
        resetTime = DateTime.tryParse(resetHeader);
      }
    }

    return AuthError(
      message: message,
      errorCode: errorCode,
      attemptsRemaining: attemptsRemaining,
      resetTime: resetTime,
    );
  }

  factory AuthError.fromBlockedAccount(Map<String, dynamic> responseData, Map<String, List<String>>? headers) {
    String message = responseData['message'] ?? 'Cuenta bloqueada';
    String? errorCode = responseData['errorCode'] ?? responseData['error'];
    
    // Convertir el mensaje del servidor para cuenta bloqueada
    if (message.contains('Account locked') || message.contains('Account temporarily locked') || message.contains('Too many attempts')) {
      message = 'Cuenta bloqueada temporalmente';
    } else if (message == 'Invalid username or password') {
      message = 'Usuario o contraseña incorrectos';
    }

    DateTime? resetTime;
    int? attemptsRemaining;

    // Primero intentar obtener el tiempo de reset de los headers
    if (headers != null) {
      final resetHeader = headers['x-ratelimit-reset']?.first ?? 
                         headers['X-RateLimit-Reset']?.first;
      if (resetHeader != null) {
        resetTime = DateTime.tryParse(resetHeader);
      }

      // En status 423 (cuenta bloqueada), NO usamos attemptsRemaining incluso si está en headers
      // porque esto representa un estado de bloqueo, no un estado de "último intento"
      // Solo usar attemptsRemaining si el mensaje no indica bloqueo
      if (!message.contains('Cuenta bloqueada')) {
        final remainingHeader = headers['x-ratelimit-username-remaining']?.first ?? 
                               headers['X-RateLimit-Username-Remaining']?.first;
        if (remainingHeader != null) {
          attemptsRemaining = int.tryParse(remainingHeader);
        }
      }
    }

    // Si no hay headers, intentar obtener información de la respuesta JSON
    if (resetTime == null && responseData['lockedUntil'] != null) {
      resetTime = DateTime.tryParse(responseData['lockedUntil']);
    }

    return AuthError(
      message: message,
      errorCode: errorCode,
      attemptsRemaining: attemptsRemaining, // null indica cuenta bloqueada (status 423)
      resetTime: resetTime,
    );
  }
}