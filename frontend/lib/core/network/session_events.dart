import 'dart:async';

/// Controlador de flujo global para transmitir eventos de cierre de sesión
/// provocados por errores 401 Unauthorized desde el cliente HTTP.
final logoutController = StreamController<void>.broadcast();
